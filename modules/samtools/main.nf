

// this is needed before running samtools sort and dedup
process SAMTOOLS_FIXMATE {
  tag "samtools fixmate $sample_id"
  label 'samtools_2'

  input:
    tuple val(sample_id), path(bam)

  output:
    tuple val(sample_id), path("${sample_id}.fixmate.bam")

  script:
  """
  samtools fixmate -@ ${task.cpus} -m ${bam} ${sample_id}.fixmate.bam
  """

  stub:
  """
  echo "samtools fixmate -@ ${task.cpus} -m ${bam} ${sample_id}.fixmate.bam" > ${sample_id}.fixmate.bam
  """

}

// sorting
process SAMTOOLS_SORT {
  tag "samtools sort $sample_id"
  label 'samtools_8'

  input:
    tuple val(sample_id), path(bam)

  output:
    tuple val(sample_id), path("${sample_id}.sorted.bam"), path("${sample_id}.sorted.bam.bai"), path("${sample_id}.sorted.bam.csi")

  script:
  """
  samtools sort -@ ${task.cpus} --write-index -o ${sample_id}.sorted.bam ${bam}
  samtools index -@ ${task.cpus} ${sample_id}.sorted.bam
  """

  stub:
  """
  echo "samtools sort -@ ${task.cpus} -o ${sample_id}.sorted.bam ${bam}" > ${sample_id}.sorted.bam
  echo "${sample_id}.sorted.bam" > ${sample_id}.sorted.bam.bai
  """
}





