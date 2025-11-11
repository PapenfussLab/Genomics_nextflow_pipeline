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
seq="${11}"

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

singularity exec -B ${tumourbam_dir} -B ${normalbam_dir} -B ${ref_dir} -B ${currentdir} "$containerDir" \
run_deepsomatic \
--model_type=${seq} \
--ref=${ref} \
--reads_normal=${normalbam} \
--reads_tumor=${tumourbam} \
--output_vcf=${tumourid}_${index}.deepsomatic.vcf.gz \
--sample_name_tumor=${tumourid} \
--sample_name_normal=${normalid} \
--logging_dir="logs" \
--num_shards=8 \
--intermediate_results_dir="intermediate_results_dir" \
--regions=${target}

bcftools view -i 'FILTER="PASS" || FILTER="LowQual"' ${tumourid}_${index}.deepsomatic.vcf.gz -Ov -o ${tumourid}_${index}_filtered.deepsomatic.vcf