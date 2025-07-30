nextflow.enable.dsl=2

// Import the subworkflow
include { ALIGN_READS_BWAMEM2 } from './workflows/align_reads/main.nf'




// samplesheet loaders

def load_fastq(samplesheet_path) {
    return Channel
        .fromPath(samplesheet_path)
        .splitCsv(header: true)
        .map { row ->
            def patient_id  = row.patient
            def sample_id   = row.sample
            def sample_type = row.condition
            def fq1 = file(row.fq1)
            def fq2 = file(row.fq2)
            def pu = row.PU ?: 'AGRF'
            def pl = row.PL ?: 'ILLUMINA'
            def lb = row.LB ?: params.RG_LB
            tuple(sample_id, fq1, fq2, pu, pl, lb)
        }
}


def load_bam(samplesheet_path) {
    return Channel
        .fromPath(samplesheet_path)
        .splitCsv(header: true)
        .map { row ->
            def patient_id  = row.patient
            def sample_id   = row.sample
            def sample_type = row.condition
            def bam         = file(row.bamfile)
        }
}






workflow {


    // checking required parameters
    def fastq_required_params = [
        "samplesheet", 
        "bwamem2_index",
        "ref_fata",
        "containers_dir"
    ]

    def bam_required_params = [
        "samplesheet", 
    ]

    required_params.each { name ->
        if (!params.get(name))
            error "Missing required parameter: --${name}"
    }

    if (!file(params.samplesheet).exists())
        error "Samplesheet not found: ${params.samplesheet}"

    // need to check multple files for bwamem_index
    // if (!file(params.bwamem2_index).exists())
    //     error "BWA index not found: ${params.bwamem2_index}"



    // 1. Load samplesheet
    if (params.start_from == "fastq") {
    Channel
        .fromPath(params.samplesheet)
        .splitCsv(header:true)
        .map { row ->
            def sample_id = row.sample
            def fq1       = file(row.r1)
            def fq2       = file(row.r2)
            def pu = row.PU ?: 'AGRF'
            def pl = row.PL ?: 'ILLUMINA'
            def lb = row.LB ?: params.RG_LB
            tuple(sample_id, fq1, fq2, pu, pl, lb)
        }
        .set { alignreads_input }

    }





    // 2. Load BWA index directory
    Channel
        .value(file(params.bwa_index))
        .set { index_dir_ch }





    // 3. Provide genome name (optional)
    Channel
        .value(params.genome)
        .set { genome_name_ch }





    // 4. Run the workflow
    ALIGN_READS_BWAMEM2(
        reads        = reads_ch,
        index_dir    = index_dir_ch,
        genome_name  = genome_name_ch
    )

    // 5. Capture output
    aligned_bams = ALIGN_READS_BWAMEM2.out.sorted

    // 6. Save results
    aligned_bams
        .map { sample_id, bam -> tuple(bam, "${sample_id}.bam") }
        .view()
}