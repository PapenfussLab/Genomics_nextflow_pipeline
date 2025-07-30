
process BWA_MEM2_ALIGN {
  tag "bwa-mem2 mem $sample_id"
  label 'bwa_mem2_align'

  input:
    tuple val(sample_id), path(fq1), path(fq2), val(rg_pu), val(rg_pl), val(rg_lb)
    path index_prefix 

  output:
    tuple val(sample_id), path("${sample_id}.unsorted.bam")

  script:
  // def rg_line = "ID:${sample_id}\tSM:${sample_id}\tPL:ILLUMINA\tLB:TRACKER\tPU:AGRF"
  // def rg_line = "ID:${sample_id}\\tSM:${sample_id}\\tPL:ILLUMINA\\tPU:AGRF"

  return """
  bwa mem -t ${task.cpus} ${index_prefix} \
    -R 'ID:${sample_id}\\tSM:${sample_id}\\tPL:${rg_pl}\\tPU:${rg_pu}\\tLB:${rg_lb}' \
    ${fq1} ${fq2} \
    | samtools view -@ 2 -b -o ${sample_id}.unsorted.bam
  """

  stub:
  return """
  echo << 'EOF' > ${sample_id}.unsorted.bam
  bwa mem -t ${task.cpus} ${index_prefix} \
    -R 'ID:${sample_id}\\tSM:${sample_id}\\tPL:${rg_pl}\\tPU:${rg_pu}\\tLB:${rg_lb}' \
    ${fq1} ${fq2} \
   | samtools view -@ 2 -b -o ${sample_id}.unsorted.bam
EOF
  """
}
