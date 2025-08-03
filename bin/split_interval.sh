#!/bin/bash

seq="$1"
kit="$2"
refDir="$3"
genome="$4"
mutect2_job_thread="$5"

module load gatk/4.6.0.0
module load samtools/1.21

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

mkdir interval_files
gatk SplitIntervals \
    -R ${ref} \
    -L ${target} \
    --scatter-count ${mutect2_job_thread} \
    -O interval_files