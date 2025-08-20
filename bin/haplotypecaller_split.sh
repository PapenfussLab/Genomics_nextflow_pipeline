#!/bin/bash

sample="$1"
bam="$2"
interval="$3"
refDir="$4"
genome="$5"

module load gatk/4.6.0.0

# find ref genome
ref=$(find ${refDir}/genome/${genome} -name "*.fa")

index=$(basename ${interval} .interval_list)

gatk HaplotypeCaller --java-options "-Xms30g -Xmx30g" \
    -R ${ref} \
    -L ${interval} \
    -I ${bam} \
    --native-pair-hmm-threads 8 \
    -O ${sample}_${index}_split.vcf