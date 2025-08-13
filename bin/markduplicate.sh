#!/bin/bash

sample="$1"
bam="$2"

module load gatk/4.6.0.0
module load samtools/1.21

# Run MarkDuplicates if not detected in bam header
# Also run MarkDuplicates if bam has been merged

if samtools view -H "${bam}" | grep -qi 'MarkDuplicates' && ! samtools view -H "${bam}" | grep -qi 'samtools merge'
then
    echo "MarkDuplicates already in the header, generating duplication metrics"
    cp ${bam} ${sample}_mdup.bam
    gatk CollectDuplicateMetrics \
    -I "${sample}_mdup.bam" \
    -O "${sample}_mdup_metrics.txt"
else
    echo "Running MarkDuplicates"
    mkdir tmp
    gatk MarkDuplicates --java-options "-Xmx60G -Xms60G" \
    -I ${bam} \
    -O ${sample}_mdup.bam \
    -TMP_DIR tmp/ \
    -M ${sample}_mdup_metrics.txt
fi

samtools index -@ 2 ${sample}_mdup.bam