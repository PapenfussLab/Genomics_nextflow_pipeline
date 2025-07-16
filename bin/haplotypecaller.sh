#!/bin/bash

sample="$1"
bam="$2"
seq="$3"
kit="$4"
refDir="$5"
genome="$6"

module load gatk/4.6.0.0

# find ref genome
ref=$(find ${refDir}/genome/${genome} -name "*.fa")

# find variant calling target region
if [[ "$seq" == "WGS" ]]
then
    target=$(find ${refDir}/exome/${genome} -name "wgs_calling_regions*")   

elif [[ "$seq" == "WES" ]]
then
    target=$(find ${refDir}/exome/${genome} -name "${kit}*.bed")   

else
    echo "ERROR: Unknown seq type '$seq'. Must be 'WGS' or 'WES'"
    exit 1
fi

gatk HaplotypeCaller --java-options "-Xms60g -Xmx60g" \
    -R ${ref} \
    -L ${target} \
    -I ${bam} \
    --native-pair-hmm-threads 8 \
    -O ${sample}.vcf