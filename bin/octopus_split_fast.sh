#!/bin/bash

tumourid="$1"
tumourbam="$2"
normalid="$3"
normalbam="$4"
interval="$5"
refDir="$6"
genome="$7"
keep_germline="$8"
octopus_conda_path="$9"

module load miniconda3
module load gatk/4.6.0.0
module load bcftools/1.22

ref=$(find ${refDir}/genome/${genome} -name "*.fa")
gatk IntervalListToBed -I ${interval} -O target.bed
target="target.bed"
index=$(basename ${interval} .interval_list)
keep_germline=${keep_germline,,}

CONDA_BASE="$(conda info --base)"

set +u
source "${CONDA_BASE}/etc/profile.d/conda.sh"
set -u

conda activate $octopus_conda_path
octopus --version

if [[ "$keep_germline" == "true" ]]
then
    octopus --threads 16 -C cancer -R ${ref} -t ${target} -I ${normalbam} ${tumourbam} --normal-sample ${normalid} -o temp.vcf --bad-region-tolerance "HIGH" --ignore-unmapped-contigs --annotations AF DP AD ADP  --fast
elif [[ "$keep_germline" == "false" ]]
then
    octopus --threads 16 -C cancer -R ${ref} -t ${target} -I ${normalbam} ${tumourbam} --normal-sample ${normalid} -o temp.vcf --bad-region-tolerance "HIGH" --ignore-unmapped-contigs --annotations AF DP AD ADP --somatics-only --fast
else
    echo "ERROR: Unknown parameter '$keep_germline'; keep_germline must be 'TRUE' or 'FALSE'"
    exit 1
fi

# split multiallelic records and drop duplicate

bcftools norm -m -any -Ou temp.vcf | bcftools norm -d exact -Ov -o ${tumourid}_${index}.filtered.octopus.vcf