#!/bin/bash

sample="$1"
vcf_list="$2"

module load gatk/4.6.0.0

# merge vcf files
IFS=',' read -r -a vcf_array <<< $vcf_list
gatk MergeVcfs ${vcf_array[@]/#/-I } -O ${sample}.vcf