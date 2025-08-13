#!/bin/bash

sample="$1"
bam_paths="$2"

module load samtools/1.21

mkdir output

# Merge multiple bams if detected

if [[ "$bam_paths" == *","* ]]
then    
    echo "Merging multiple BAMs"
    bam_list=$(echo "$bam_paths" | tr ',' ' ')
    samtools merge -@ 8 ${sample}_merged.bam $bam_list
    bam_input=${sample}_merged.bam

else
    echo "Single BAM detected"
    bam_input=${bam_paths}
fi

# Replace RG

samtools addreplacerg -@ 8 \
    -m overwrite_all \
    -r ID:${sample} -r SM:${sample} -r PL:ILLUMINA \
    -o output/${sample}.bam ${bam_input}
