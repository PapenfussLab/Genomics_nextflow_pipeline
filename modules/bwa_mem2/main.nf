


BWA_MEM2_ALIGN {
  tag "bwa-mem2 mem $sample_id"
  label 'bwa_mem2_align'
  container params.genomicsGeneralContainer

  input:
    tuple val(sample_id), path(fq1), path(fq2)

  output:
    tuple val(sample_id), path("${sample_id}.sam")

  script:
  """
  bwa mem -t ${task.cpus} ${params.bwa_mem2_index} ${fq1} ${fq2} > ${sample_id}.sam
  """

  stub:
  """
  echo "bwa mem -t ${task.cpus} ${params.bwa_mem2_index} ${fq1} ${fq2} > ${sample_id}.sam" > ${sample_id}.sam
  """
}




