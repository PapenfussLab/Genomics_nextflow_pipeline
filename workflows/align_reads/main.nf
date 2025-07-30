include { 
    BWA_MEM2_ALIGN
} from '../../modules/bwa_mem2/main.nf'

include {
    SAMTOOLS_FIXMATE
    SAMTOOLS_SORT
} from '../../modules/samtools/main.nf'








workflow ALIGN_READS_BWAMEM2 {
    take:
        reads          // expects: tuple val(sample_id), path(r1), path(r2)
        index_prefix

    main:
        aligned   = BWA_MEM2_ALIGN(reads, index_prefix)
        matefixed = SAMTOOLS_FIXMATE(aligned)
        sorted    = SAMTOOLS_SORT(matefixed)

    emit:
        sorted
}