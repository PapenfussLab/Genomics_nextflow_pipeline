#!/bin/bash

tumour_id="$1"
tumour_bam="$2"
normal_bam="$3"
normal_vcf="$4"
singularity_cacheDir="$5"

module load singularity/4.1.5

cacheDir=$(realpath $singularity_cacheDir)
export SINGULARITY_CACHEDIR="$cacheDir"

singularity pull --name facets-suite-dev.img docker://philipjonsson/facets-suite:dev

currentdir=$(pwd)
tumourbam_dir=$(dirname $(realpath ${tumour_bam}))
normalbam_dir=$(dirname $(realpath ${normal_bam}))
vcf_dir=$(dirname $(realpath ${normal_vcf}))

singularity run -B ${tumourbam_dir} -B ${normalbam_dir} -B ${vcf_dir} -B ${currentdir} \
facets-suite-dev.img snp-pileup-wrapper.R \
--vcf-file ${normal_vcf} \
--normal-bam ${normal_bam} \
--tumor-bam ${tumour_bam} \
--output-prefix ${currentdir}/${tumour_id} 