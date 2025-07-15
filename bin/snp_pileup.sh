#!/bin/bash

tumour_id="$1"
tumour_bam="$2"
normal_bam="$3"
normal_vcf="$4"
facetsuite="$5"

module load singularity
export SINGULARITY_CACHEDIR=$(dirname $(realpath ${facetsuite}))

currentdir=$(pwd)
tumourbam_dir=$(dirname $(realpath ${normal_bam}))
normalbam_dir=$(dirname $(realpath ${tumour_bam}))
vcf_dir=$(dirname $(realpath ${normal_vcf}))

singularity run -B ${tumourbam_dir} -B ${normalbam_dir} -B ${vcf_dir} -B ${currentdir} \
facets-suite-dev.img snp-pileup-wrapper.R \
--vcf-file ${normal_vcf} \
--normal-bam ${normal_bam} \
--tumor-bam ${tumour_bam} \
--output-prefix ${currentdir}/${tumour_id} 