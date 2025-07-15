#!/bin/bash

sample="$1"
bam="$2"

module load gatk/4.6.0.0
module load samtools/1.21

mkdir tmp
gatk MarkDuplicates --java-options "-Xmx33G -Xms33G" \
-I ${sample}.bam \
-O ${sample}_mdup.bam \
-TMP_DIR tmp/ \
-M ${sample}_mdup_metrics.txt

samtools index -@ 2 ${sample}_mdup.bam