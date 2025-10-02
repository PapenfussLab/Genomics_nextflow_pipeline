#!/bin/bash

sample="$1"
vcf_list="$2"

module load gatk/4.6.0.0

# merge vcf files
IFS=',' read -r -a vcf_array <<< $vcf_list
gatk MergeVcfs ${vcf_array[@]/#/-I } -O ${sample}.raw.vcf

# apply quality filter on vcf files
gatk VariantFiltration \
  -V ${sample}.raw.vcf \
  --filter-name "QD2"           --filter-expression "QD < 2.0" \
  --filter-name "FS60"          --filter-expression "FS > 60.0" \
  --filter-name "MQ40"          --filter-expression "MQ < 40.0" \
  --filter-name "MQRankSum12.5" --filter-expression "MQRankSum < -12.5" \
  --filter-name "RPRS-8"        --filter-expression "ReadPosRankSum < -8.0" \
  --filter-name "SOR3"          --filter-expression "SOR > 3.0" \
  -O ${sample}.filtered.vcf

awk 'BEGIN {OFS="\t"} /^#/ || $7=="PASS" ' ${sample}.filtered.vcf > ${sample}.vcf