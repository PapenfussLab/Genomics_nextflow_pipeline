#!/usr/bin/env nextflow
params.mosdepth   = "${workflow.projectDir}/bin/mosdepth"
params.vcf2maf    = "${workflow.projectDir}/bin/mskcc-vcf2maf-f6d0c40"
params.facetsR    = "${workflow.projectDir}/bin/runFacets.R"

// check mandatory input
if( ! params.metadata ) {
  error "Please provide a metadata file: --metadata <path/to/file>"
}

if( ! params.outDir ) {
  error "Please provide output directory: --outDir </path/to/your/outDir>"
}

if( ! params.refDir ) {
  error "Please provide refdata directory: --refDir </path/to/your/refDir>"
}


// check input genome
def allowedGenomes = ['GRCh38', 'GRCm38']
if( ! allowedGenomes.contains(params.genome) ) {
    error "Unsupported genome: '${params.genome}'. Allowed values are: ${allowedGenomes.join(', ')}"
}

// check input mode
def allowedMode = ['matched', 'unmatched', 'tumour_only']
if( ! allowedMode.contains(params.mode) ) {
    error "Unsupported mode: '${params.mode}'. Allowed values are: ${allowedMode.join(', ')}"
}

// check input type
def allowedInput = ['fastq', 'bam', 'bam_processed']
if( ! allowedInput.contains(params.input) ) {
    error "Unsupported input: '${params.input}'. Allowed values are: ${allowedInput.join(', ')}"
}

include { bwa_mem; merge_bam; markduplicate; QC_metrics; QC_metrics_single; haplotypecaller_split; haplotypecaller_merge; split_interval; split_interval_single; mutect2_split; mutect2_tumour_only_split; mutect2_merge_annotate; mutect2_merge_annotate_single; deepsomatic_split; deepsomatic_merge_annotate; subset_germline_vcf; snp_pileup; facets } from './modules.nf'

workflow {

    if (params.input == "fastq") {
    // alignment
    fastq_ch=Channel.fromPath(params.metadata)
      .splitCsv( header:true )
      .map { row -> 
            [row.sample, row.r1, row.r2]
            }
      .groupTuple()

    bwa_ch_raw=bwa_mem(fastq_ch, params.refDir, params.genome)
    bam_ch=markduplicate(bwa_ch_raw)

  } else if (params.input == "bam") {
    // No alignment needed. Merge if multiple bam, markduplicate if not performed, and change bam RG ID to sample name
    bwa_ch_raw = Channel.fromPath(params.metadata)
      .splitCsv(header:true)
      .map { row -> [ row.sample, file(row.bam) ] }
      .groupTuple()
    
    bwa_ch_merged=merge_bam(bwa_ch_raw)
    bam_ch=markduplicate(bwa_ch_merged)
  
  } else {
    // Use bam files straight away
    bam_ch=Channel.fromPath(params.metadata)
      .splitCsv( header:true )
      .map { row -> 
            [row.sample, row.bam, row.bai, row.markdup_metrics]
            }
  }
  
  // Tumour only mode
  // Run QC and mutect2 tumour-only call
  if (params.mode == "tumour_only"){
    // Create a channel of bam files
    sample_bam_ch=Channel.fromPath(params.metadata)
      .splitCsv( header:true )
      .map { row -> 
            [row.sample, row.patient, row.seq, row.kit]
            }
      .distinct()
      .join(bam_ch, by: 0)
    
    // QC
    QC_metrics_single(sample_bam_ch, params.refDir, params.genome, params.mosdepth)

    // Run mutect2 on tumour-only mode.
    // speed up mutect2 by splitting and parallelising target intervals
    split_ch=split_interval_single(sample_bam_ch, params.refDir, params.genome, params.mutect2_job_thread)
      .flatMap { sample, patient, seq, kit, bam, bai, interval_files ->
                    interval_files.collect { interval ->
                      tuple( sample, patient, seq, kit, bam, bai, interval ) }
          }

    mutect2_raw_vcfs=mutect2_tumour_only_split(split_ch, params.refDir, params.genome, params.keep_germline_var)
      .groupTuple(by: [0,1,2])
    
    mutect2_merge_annotate_single(mutect2_raw_vcfs, params.refDir, params.genome, params.vcf2maf)
  }

  // Tumour-normal mode
  // Run mutect2 and deepsomatic tumour-normal call and facets
  else {
    // Create a channel of bam files
    sample_bam_ch=Channel.fromPath(params.metadata)
      .splitCsv( header:true )
      .map { row -> 
            [row.sample, row.patient, row.condition, row.seq, row.kit]
            }
      .distinct()
      .join(bam_ch, by: 0)

    // QC
    QC_metrics(sample_bam_ch, params.refDir, params.genome, params.mosdepth)

    // Branch bam channel to normal and tumour
    branch_ch=sample_bam_ch
    .branch {
      normal: it[2] == "normal"
      tumour: it[2] == "tumour"
    }

    // Pair tumour samples with normals of the same patient same sequencing kit
    normal_ch=branch_ch.normal
      .map { normalsample, patient, condition, normalseq, normalkit, normalbam, normalbai, markdup_metrics -> 
            [patient, normalsample, normalbam, normalbai, normalseq, normalkit] }
      .groupTuple(by: 0)

    paired_bam_ch=branch_ch.tumour
      .map { tumoursample, patient, condition, tumourseq, tumourkit, tumourbamList, tumourbaiList, markdup_metrics -> 
            [patient, tumoursample, tumourbamList, tumourbaiList, tumourseq, tumourkit] }
        // paire tumour-normal samples from the sampe patient
        .groupTuple(by: 0)
        .join(normal_ch)
      .flatMap {patient, tumoursample, tumourbamList, tumourbaiList, tumourseq, tumourkit, normalsample, normalbam, normalbai, normalseq, normalkit ->
          def result = []
            tumourbamList.eachWithIndex { tumourbam, idx -> 
            // find tumour-normal paires with matching kit
            def normal_index = normalkit.indexOf(tumourkit[idx])
            result << [patient, tumoursample[idx], tumourbam, tumourbaiList[idx], tumourseq[idx], tumourkit[idx], normalsample[normal_index], normalbam[normal_index], normalbai[normal_index]] 
            }
          return result
          }
    
    // Run mutect2 and deepsomatic on tumour-normal pairs
    // speed up mutect2 and deepsomatic by splitting and parallelising target intervals
    split_ch=split_interval(paired_bam_ch, params.refDir, params.genome, params.mutect2_job_thread)
      .flatMap { patient, tumourid, tumour_bam, tumour_bai, seq, kit, normalid, normal_bam, normal_bai, interval_files ->
                  interval_files.collect { interval ->
                    tuple( patient, tumourid, tumour_bam, tumour_bai, seq, kit, normalid, normal_bam, normal_bai, interval ) }
        }

    mutect2_raw_vcfs=mutect2_split(split_ch, params.refDir, params.genome, params.keep_germline_var)
      .groupTuple(by: [0,1,2,3,4])
    mutect2_ch=mutect2_merge_annotate(mutect2_raw_vcfs, params.refDir, params.genome, params.vcf2maf)

    if(params.run_deepsomatic=="TRUE"){
      deepsomatic_raw_vcfs=deepsomatic_split(split_ch, params.refDir, params.genome, params.keep_germline_var, params.singularity_cacheDir, params.deepsomatic_containerDir)
       .groupTuple(by: [0,1,2,3,4])
      deepsomatic_merge_annotate(deepsomatic_raw_vcfs, params.refDir, params.genome, params.vcf2maf)
    }
    else{}

    // Run haplotypecaller for normal samples
    // speed up haplotypecaller by splitting and parallelising target intervals
    normal_bam_ch=branch_ch.normal
      .map { sample, patient, condition, seq, kit, bam, bai, markdup_metrics -> 
            [sample, patient, seq, kit, bam, bai, markdup_metrics] }
    
    split_normal_ch=split_interval_single(normal_bam_ch, params.refDir, params.genome, params.mutect2_job_thread)
      .flatMap { sample, patient, seq, kit, bam, bai, interval_files ->
                    interval_files.collect { interval ->
                      tuple( sample, patient, seq, kit, bam, bai, interval ) }
          }

    normal_vcf_split=haplotypecaller_split(split_normal_ch, params.refDir, params.genome)
      .groupTuple(by: [0,1])

    normal_vcf_merged=haplotypecaller_merge(normal_vcf_split)
      .map { patient, normalid, normalvcf ->
        tuple( [patient, normalid], normalvcf )}

    normal_vcf_ch=paired_bam_ch
      .map{ patient, tumourid, tumourbam, tumourbai, seq, kit, normalid, normalbam, normalbai  ->
        tuple( [patient, normalid], [tumourid, patient, tumourbam, tumourbai, seq, kit, normalid, normalbam, normalbai] ) }
      .combine(normal_vcf_merged)
      .map { keyPN, leftVals, keyPN2, normalvcf ->
        def (tumourid, patient, tumourbam, tumourbai, seq, kit, normalid, normalbam, normalbai) = leftVals
        [tumourid, patient, tumourbam, tumourbai, seq, kit, normalid, normalbam, normalbai, normalvcf]
      }

    paired_vcf_ch=normal_vcf_ch
      .join(mutect2_ch)

    // subset passed somatic varaints from germline VCF
    filtered_germline_vcf_ch=subset_germline_vcf(paired_vcf_ch)

    // Run SNP pileup
    snp_pileup(filtered_germline_vcf_ch, params.singularity_cacheDir)

    // Run facets
    facets(snp_pileup.out, params.facetsR, params.facets_cval_preproc, params.facets_window, params.facets_cval, params.facets_ndepth, params.genome, params.mode)
  }
}