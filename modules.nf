
process bwa_mem {     
    executor 'slurm'
    cpus = 20
    memory = 16.GB
    time = 48.hour

input:
    tuple val (sample), path (r1), path (r2)
	path refDir
    val genome

output:
    tuple val (sample), path("${sample}.bam")
    
script:
    def R1_paths = r1.join(',')
    def R2_paths = r2.join(',')

	"""
	bwa_mem.sh $sample $R1_paths $R2_paths $refDir $genome
    """
}

process markduplicate {     
    publishDir path: "${params.outDir}/bam", mode: 'copy'
    executor 'slurm'
    cpus = 2
    memory = 36.GB
    time = 48.hour

input:
    tuple val (sample), path (bam)

output:
    tuple val (sample), path("${sample}_mdup.bam"), path("${sample}_mdup.bam.bai"), path("${sample}_mdup_metrics.txt")
    
script:

	"""
	markduplicate.sh $sample $bam
    """
}

process QC_metrics {     
    publishDir path: "${params.outDir}/QC", mode: 'copy'
    executor 'slurm'
    cpus = 2
    memory = 8.GB
    time = 48.hour

input:
    tuple val (sample), val (patient), val (condition), val (seq), val (kit), path (bam), path (bai), path(markdup_metrics)
    path (refDir)
    val (genome)
    path (mosdepth)

output:
    path("${sample}_QC_metrics")
    
script:

	"""
	QC_metrics.sh $sample $bam $seq $kit $refDir $genome
    """
}

process mutect2 {     
	publishDir path: "${params.outDir}/mutect2", mode: 'copy'
	executor 'slurm'
    cpus = 8
    memory = 64.GB
    time = 48.hour

input:
    tuple val (patient), val (tumourid), path (tumourbam), path (tummourbai), val (seq), val (kit), val (normalid), path (normalbam), path (normalbai)   
    path refDir
	val genome
	path vcf2maf

output:
	path "${tumourid}_mutect2"
    
script:
	  
	"""
	mutect2_tumour_normal.sh $tumourid $tumourbam $normalid $normalbam $seq $kit $refDir $genome $vcf2maf
    """
}


process haplotypecaller {
    executor 'slurm'
    cpus = 8
    memory = 64.GB
    time = 48.hour

input:
    tuple val (sample), val (patient), val (condition), val (seq), val (kit), path (bam), path (bai), path(markdup_metrics)
	path refDir
    val genome

output:
    tuple val (patient), val (sample), path (bam), path(bai), val (seq), val(kit), path ("${sample}.vcf")
        
script:

    """
    haplotypecaller.sh $sample $bam $seq $kit $refDir $genome
    """
}

process snp_pileup {
    executor 'slurm'
    cpus = 1
    memory = 2.GB
    time = 48.hour

input:
    tuple val (patient), val (tumourid), path (tumourbam), path (tummourbai), val (seq), val (kit), val (normalid), path (normalbam), path (normalbai), path(normalvcf)

output:
    tuple val (tumourid), val (seq), path ("${tumourid}.snp_pileup.gz")
        
script:

    """
    snp_pileup.sh $tumourid $tumourbam $normalbam $normalvcf
    """
}

process facets {
    publishDir path: "${params.outDir}/facets", mode: 'copy'
    executor 'slurm'
    cpus = 1
    memory = 8.GB
    time = 48.hour

input:    
    tuple val (tumourid), val (seq), path (snp_pileup)
    path (facetsR)
    val (facets_cval_preproc)
    val (facets_window)
    val (facets_cval)

output:
    path ("${tumourid}_facets")
        
script:
    """
    mkdir ${tumourid}_facets
    module load R/4.5.1
    R --file=runFacets.R --args ${tumourid} ${snp_pileup} ${facets_cval_preproc} ${facets_window} ${facets_cval}
    """
}
