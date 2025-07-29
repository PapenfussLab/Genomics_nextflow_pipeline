process SAMTOOLS_SORT {
  tag "samtools sort $sample_id"
  label 'samtools_multi'
  container params.genomicsGeneralContainer

  input:
    tuple val(sample_id), path(bam)

  output:
    tuple val(sample_id), path("${sample_id}.sorted.bam"), path("${sample_id}.sorted.bam.bai"), path("${sample_id}.sorted.bam.csi")


  script:
  """
  samtools sort --write-index -@ ${task.cpus} -o ${sample_id}.sorted.bam ${bam}
  samtools index -@ ${task.cpus} ${sample_id}.sorted.bam
  """

  stub:
  """
  echo "samtools sort --write-index -@ ${task.cpus} -o ${sample_id}.sorted.bam ${bam}" > ${sample_id}.sorted.bam
  echo "${sample_id}.sorted.bam" > ${sample_id}.sorted.bam.bai
  echo "${sample_id}.sorted.bam" > ${sample_id}.sorted.bam.csi
  """
}




