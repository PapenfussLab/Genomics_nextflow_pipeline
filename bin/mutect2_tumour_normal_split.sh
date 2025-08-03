#!/bin/bash

tumourid="$1"
tumourbam="$2"
normalid="$3"
normalbam="$4"
interval="$5"
refDir="$6"
genome="$7"
keep_germline="$8"

module load gatk/4.6.0.0
module load samtools/1.21

# find ref genome
ref=$(find ${refDir}/genome/${genome} -name "*.fa")

index=$(basename ${interval} .interval_list)

# mutect call, retain germline variant by --genotype-germline-sites TRUE
gatk --java-options "-Xms30g -Xmx30g" Mutect2 \
    -R ${ref} \
    -I ${tumourbam} \
    -I ${normalbam} \
    -L ${interval} \
    -normal ${normalid} \
    -O ${tumourid}_${index}.mutect2.vcf \
    --genotype-germline-sites ${keep_germline} \
    --native-pair-hmm-threads 4

gatk --java-options "-Xms30g -Xmx30g" FilterMutectCalls \
    -V ${tumourid}_${index}.mutect2.vcf \
    -R ${ref} \
    -L ${interval} \
    -O ${tumourid}_${index}_filtered.mutect2.vcf