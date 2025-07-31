#!/bin/bash

sample="$1"
bam="$2"
seq="$3"
kit="$4"
refDir="$5"
genome="$6"

module load gatk/4.6.0.0
module load samtools/1.21

mkdir ${sample}_QC_metrics

## Copy mark duplicate metrics
echo "Copy mark duplicate metrics"
cp ${sample}_mdup_metrics.txt ${sample}_QC_metrics/

## CollectWgsMetrics for WGS
if [[ "$seq" == "WGS" ]]; then
    echo "Running GATK CollectWgsMetrics"
    ref=$(find ${refDir}/genome/${genome} -name "*.fa")

    gatk --java-options "-Xmx12G" CollectWgsMetrics \
        -I $bam \
        -O ${sample}_QC_metrics/${sample}_WGS_metrics.txt \
        -R $ref

## run mosdepth coverage for WGS
elif [[ "$seq" == "WES" ]]; then
    echo "Running mosdepth coverage over WES target regions"
    target=$(find ${refDir}/exome/${genome} -name "${kit}*.bed")
    ./mosdepth -n -t 2 -b ${target} ${sample}_QC_metrics/${sample} $bam

else
    echo "ERROR: Unknown seq type '$seq'. Must be 'WGS' or 'WES'"
    exit 1
fi

## samtools flagstats and stats
echo "Running samtools flagstat"
samtools flagstat $bam > ${sample}_QC_metrics/${sample}.flagstat.txt

echo "Running samtoos stats"
samtools stats $bam > ${sample}_QC_metrics/${sample}.samtools.stats.txt

