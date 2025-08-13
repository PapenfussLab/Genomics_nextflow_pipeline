#!/bin/bash

sample="$1"
bam="$2"
interval="$3"
refDir="$4"
genome="$5"
keep_germline="$6"

module load gatk/4.6.0.0
module load samtools/1.21

# find ref genome
ref=$(find ${refDir}/genome/${genome} -name "*.fa")

index=$(basename ${interval} .interval_list)

# mutect call, retain germline variant by --genotype-germline-sites TRUE
gatk --java-options "-Xms30g -Xmx30g" Mutect2 \
    -R ${ref} \
    -I ${bam} \
    -L ${interval} \
    -O ${sample}_${index}.mutect2.vcf \
    --genotype-germline-sites ${keep_germline} \
    --native-pair-hmm-threads 4

gatk --java-options "-Xms30g -Xmx30g" FilterMutectCalls \
    -V ${sample}_${index}.mutect2.vcf \
    -R ${ref} \
    -L ${interval} \
    -O ${sample}_${index}_filtered.mutect2.vcf