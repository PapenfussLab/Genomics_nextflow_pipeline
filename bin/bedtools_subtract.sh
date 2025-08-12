#!/bin/bash

normalid="$1"
tumourid="$2"

normalvcf="$3"
tumourvcfPath="$4"

tumourvcf=${tumourvcfPath}/${tumourid}.mutect2.filtered.vcf

module load bcftools/1.22
module load bedtools/2.31.1 

awk 'BEGIN {OFS="\t"} /^#/ || $7 !~ /germline/' ${tumourvcf} > ${tumourid}_no_germline.vcf

# Extract header from normal VCF
grep '^#' "${normalvcf}" > "${normalid}_filtered.vcf"

# Subtract somatic mutation regions from normal VCF
bedtools subtract -a ${normalvcf} -b ${tumourid}_no_germline.vcf >> ${normalid}_filtered.vcf