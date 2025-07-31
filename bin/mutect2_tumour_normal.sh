#!/bin/bash

tumourid="$1"
tumourbam="$2"
normalid="$3"
normalbam="$4"
seq="$5"
kit="$6"
refDir="$7"
genome="$8"
vcf2maf="$9"
keep_germline="${10}"

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

# mutect call, retain germline variant by --genotype-germline-sites TRUE
gatk --java-options "-Xms60g -Xmx60g" Mutect2 \
    -R ${ref} \
    -I ${tumourbam} \
    -I ${normalbam} \
    -L ${target} \
    -normal ${normalid} \
    -O ${tumourid}.mutect2.vcf \
    --genotype-germline-sites ${keep_germline} \
    --native-pair-hmm-threads 8

# filter mutect calls
mkdir ${tumourid}_mutect2

gatk FilterMutectCalls --java-options "-Xms60g -Xmx60g" \
    -V ${tumourid}.mutect2.vcf \
    -R ${ref} \
    -L ${target} \
    -O ${tumourid}_mutect2/${tumourid}.mutect2.filtered.vcf

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
    --input-vcf ${tumourid}_mutect2/${tumourid}.mutect2.filtered.vcf \
    --output-maf ${tumourid}_mutect2/${tumourid}.mutect2.filtered.maf \
    --tmp-dir ${tumourid}_mutect2 \
    --tumor-id ${tumourid} \
    --ref-fasta  ${ref} \
    --ncbi-build ${genome} \
    --cache-version ${cache_version} \
    --retain-fmt AF,DP