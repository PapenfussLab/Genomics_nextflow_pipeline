#!/bin/bash

sample="$1"
R1_paths="$2"
R2_paths="$3"
refDir="$4"
genome="$5"

module load bwa/0.7.17
module load cutadapt/4.9
module load samtools/1.21
module load gatk/4.6.0.0


R1=$(echo "$R1_paths" | tr ',' ' ')
R2=$(echo "$R2_paths" | tr ',' ' ')
ref=$(find ${refDir}/genome/${genome} -name "*.fa")

paste <(zcat $R1 | paste - - - -) \
<(zcat $R2 | paste - - - -) \
| tr '\t' '\n' \
| cutadapt --interleaved -a AGATCGGAAGAG -A AGATCGGAAGAG -j 4 --quiet - \
| bwa mem -p -t 16 -R "@RG\tID:${sample}\tSM:${sample}\tPL:ILLUMINA" ${ref} - \
| samtools sort -@ 4 -O bam -o ${sample}.bam - 
