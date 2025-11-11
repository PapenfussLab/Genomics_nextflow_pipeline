#!/bin/bash

tumourid="$1"
tumourbam="$2"
normalid="$3"
normalbam="$4"
interval="$5"
refDir="$6"
genome="$7"
keep_germline="$8"
singularity_cacheDir=$(realpath ${9})
containerDir=$(realpath ${10})

module load singularity/4.1.5
module load gatk/4.6.0.0
module load bcftools/1.22
export SINGULARITY_CACHEDIR="$singularity_cacheDir"

ref=$(find ${refDir}/genome/${genome} -name "*.fa")
gatk IntervalListToBed -I ${interval} -O target.bed
target="target.bed"
index=$(basename ${interval} .interval_list)
keep_germline=${keep_germline,,}

tumourbam_dir=$(dirname $(realpath ${tumourbam}))
normalbam_dir=$(dirname $(realpath ${normalbam}))
ref_dir=$(dirname $(realpath ${ref}))
currentdir=$(pwd)

if [[ "$keep_germline" == "true" ]]
then
    singularity exec -B ${tumourbam_dir} -B ${normalbam_dir} -B ${ref_dir} -B ${currentdir} "$containerDir" \
    octopus --threads 16 -C cancer -R ${ref} -t ${target} -I ${normalbam} ${tumourbam} --normal-sample ${normalid} -o temp.vcf --ignore-unmapped-contigs --annotations AF DP AD ADP  --very-fast
elif [[ "$keep_germline" == "false" ]]
then
    singularity exec -B ${tumourbam_dir} -B ${normalbam_dir} -B ${ref_dir} -B ${currentdir} "$containerDir" \
    octopus --threads 16 -C cancer -R ${ref} -t ${target} -I ${normalbam} ${tumourbam} --normal-sample ${normalid} -o temp.vcf --ignore-unmapped-contigs --annotations AF DP AD ADP --somatics-only --very-fast
else
    echo "ERROR: Unknown parameter '$keep_germline'; keep_germline must be 'TRUE' or 'FALSE'"
    exit 1
fi

# split multiallelic records and drop duplicate
bcftools norm -m -any -Ou temp.vcf | bcftools norm -d exact -Ov -o ${tumourid}_${index}.filtered.octopus.vcf