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
def allowedMode = ['matched', 'unmatched']
if( ! allowedMode.contains(params.mode) ) {
    error "Unsupported mode: '${params.mode}'. Allowed values are: ${allowedMode.join(', ')}"
}

// check input type
def allowedInput = ['fastq', 'bam']
if( ! allowedInput.contains(params.input) ) {
    error "Unsupported mode: '${params.input}'. Allowed values are: ${allowedInput.join(', ')}"
}

include { bwa_mem; markduplicate; QC_metrics; mutect2; haplotypecaller; split_interval; mutect2_split; mutect2_merge_annotate; subset_germline_vcf; snp_pileup; facets } from './modules.nf'

workflow {

    if (params.input == "fastq") {
    // Alignment
    fastq_ch=Channel.fromPath(params.metadata)
      .splitCsv( header:true )
      .map { row -> 
            [row.sample, row.r1, row.r2]
            }
      .groupTuple()

    bwa_ch=bwa_mem(fastq_ch, params.refDir, params.genome)

  } else if (params.input == "bam") {
    // no alignment needed
    bwa_ch = Channel.fromPath(params.metadata)
      .splitCsv(header:true)
      .map { row -> [ row.sample, file(row.bam), file(row.bai) ] }
  }
  
  // Mark duplicate if not performed already
  bam_ch=markduplicate(bwa_ch)

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
  
  // Run mutect2 on tumour-normal pairs
  // speed up mutect2 by splitting and parallelising target intervals
  split_ch=split_interval(paired_bam_ch, params.refDir, params.genome, params.mutect2_job_thread)
    .flatMap { patient, tumourid, tumour_bam, tumour_bai, seq, kit, normalid, normal_bam, normal_bai, interval_files ->
                interval_files.collect { interval ->
                  tuple( patient, tumourid, tumour_bam, tumour_bai, seq, kit, normalid, normal_bam, normal_bai, interval )
          }
      }

  mutect2_raw_vcfs=mutect2_split(split_ch, params.refDir, params.genome, params.keep_germline_var)
    .groupTuple(by: [0,1,2,3,4])
  
  mutect2_ch=mutect2_merge_annotate(mutect2_raw_vcfs, params.refDir, params.genome, params.vcf2maf)

  // Run haplotypecaller for normal samples
  normal_vcf_ch=haplotypecaller(branch_ch.normal, params.refDir, params.genome)
    .groupTuple(by: 0)

  
  normal_vcf_ch=branch_ch.tumour
	.map { tumoursample, patient, condition, tumourseq, tumourkit, tumourbamList, tumourbaiList, markdup_metrics -> 
          [patient, tumoursample, tumourbamList, tumourbaiList, tumourseq, tumourkit] }
    .groupTuple(by: 0)
    .join(normal_vcf_ch)
	.flatMap {patient, tumoursample, tumourbamList, tumourbaiList, tumourseq, tumourkit, normalsample, normalbam, normalbai, normalseq, normalkit, normalvcf ->
			def result = []
				tumourbamList.eachWithIndex { tumourbam, idx -> 
				def normal_index = normalkit.indexOf(tumourkit[idx])
				result << [tumoursample[idx], patient, tumourbam, tumourbaiList[idx], tumourseq[idx], tumourkit[idx], normalsample[normal_index], normalbam[normal_index], normalbai[normal_index], normalvcf[normal_index]] 
				}
			return result
        } 
  
  paired_vcf_ch=normal_vcf_ch
    .join(mutect2_ch)
    .view()

  filtered_germline_vcf_ch=subset_germline_vcf(paired_vcf_ch)

  // Run SNP pileup
  snp_pileup(filtered_germline_vcf_ch)

  // Run facets
  facets(snp_pileup.out, params.facetsR, params.facets_cval_preproc, params.facets_window, params.facets_cval, params.genome, params.mode)
}