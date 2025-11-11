#!/bin/bash

tumourid="$1"
vcf_list="$2"
seq="$3"
kit="$4"
refDir="$5"
genome="$6"
vcf2maf="$7"

module load gatk/4.6.0.0
module load samtools/1.21
module load ensembl-vep/112
module load htslib/1.21
module load perl/5.40.0

# find vep path
vep_path=$(dirname "$(command -v vep)")

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

# make output dir
mkdir ${tumourid}_deepsomatic

# merge vcf files
IFS=',' read -r -a vcf_array <<< $vcf_list
gatk MergeVcfs ${vcf_array[@]/#/-I } -O ${tumourid}_deepsomatic/${tumourid}.deepsomatic.vcf

# annotate with Vep 112 and convert to maf format
if [[ "$genome" == "GRCh38" ]]
then
    species="homo_sapiens"
    cache_version="112"
elif [[ "$genome" == "GRCm39" ]]
then
    species="mus_musculus"
    cache_version="112"
elif [[ "$genome" == "GRCm38" ]]
then
    species="mus_musculus"
    cache_version="102"
else
    echo "ERROR: Unknown genome type '$genome'."
    exit 1
fi

perl ${vcf2maf}/vcf2maf.pl \
    --species ${species} \
    --vep-path ${vep_path} \
    --vep-data ${refDir}/vep \
    --input-vcf ${tumourid}_deepsomatic/${tumourid}.deepsomatic.vcf \
    --output-maf ${tumourid}_deepsomatic/${tumourid}.deepsomatic.maf \
    --tmp-dir ${tumourid}_deepsomatic \
    --tumor-id ${tumourid} \
    --ref-fasta  ${ref} \
    --ncbi-build ${genome} \
    --cache-version ${cache_version} \
    --retain-fmt DP,VAF
