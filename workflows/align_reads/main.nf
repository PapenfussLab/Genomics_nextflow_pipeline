


workflow ALIGN_READS {
  take:
    reads          // expects: tuple val(sample_id), path(r1), path(r2)
    index_prefix
    genome_name
    aligner // e.g. bwamem2

  main:
    if aligner == 'bwamem2' {
      aligned = 
    

  emit:
    aligned
}