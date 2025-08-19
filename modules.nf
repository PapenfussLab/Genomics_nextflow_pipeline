
process bwa_mem {     
    executor 'slurm'
    cpus = 20
    memory = 64.GB
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

process merge_bam {     
    executor 'slurm'
    cpus = 8
    memory = 32.GB
    time = 48.hour

input:
    tuple val (sample), path (bam)

output:
    tuple val (sample), path("output/${sample}.bam")
    
script:

    def bam_paths = bam.join(',')

	"""
	merge_bam.sh $sample $bam_paths
    """
}

process markduplicate {     
    publishDir path: "${params.outDir}/bam", mode: 'copy'
    executor 'slurm'
    cpus = 2
    memory = 64.GB
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

process QC_metrics_single {     
    publishDir path: "${params.outDir}/QC", mode: 'copy'
    executor 'slurm'
    cpus = 2
    memory = 16.GB
    time = 48.hour

input:
    tuple val (sample), val (patient), val (seq), val (kit), path (bam), path (bai), path(markdup_metrics)
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

process split_interval_single {     
	executor 'slurm'
    cpus = 1
    memory = 8.GB
    time = 48.hour

input:
    tuple val (sample), val (patient), val (seq), val (kit), path (bam), path (bai), path(markdup_metrics)
    path refDir
	val genome
    val mutect2_job_thread

output:
	tuple val (sample), val (patient), val (seq), val (kit), path (bam), path (bai), path ("interval_files/*")
    
script:
	  
	"""
	split_interval.sh $seq $kit $refDir $genome $mutect2_job_thread
    """
}

process split_interval {     
	executor 'slurm'
    cpus = 1
    memory = 8.GB
    time = 48.hour

input:
    tuple val (patient), val (tumourid), path (tumourbam), path (tummourbai), val (seq), val (kit), val (normalid), path (normalbam), path (normalbai)   
    path refDir
	val genome
    val mutect2_job_thread

output:
	tuple val (patient), val (tumourid), path (tumourbam), path (tummourbai), val (seq), val (kit), val (normalid), path (normalbam), path (normalbai), path ("interval_files/*")
    
script:
	  
	"""
	split_interval.sh $seq $kit $refDir $genome $mutect2_job_thread
    """
}

process mutect2_tumour_only_split {     
	executor 'slurm'
    cpus = 4
    memory = 20.GB
    time = 48.hour

input:
    tuple val (sample), val (patient), val (seq), val (kit), path (bam), path (bai), path (interval)
    path refDir
	val genome
    val keep_germline

output:
	tuple val (sample), val (seq), val (kit), path ("*filtered.mutect2.vcf")
    
script:
	  
	"""
	mutect2_tumour_only_split.sh $sample $bam $interval $refDir $genome $keep_germline
    """
}


process mutect2_split {     
	executor 'slurm'
    cpus = 4
    memory = 20.GB
    time = 48.hour

input:
    tuple val (patient), val (tumourid), path (tumourbam), path (tummourbai), val (seq), val (kit), val (normalid), path (normalbam), path (normalbai), path (interval)
    path refDir
	val genome
    val keep_germline

output:
	tuple val (patient), val (tumourid), val (normalid), val (seq), val (kit), path ("*filtered.mutect2.vcf")
    
script:
	  
	"""
	mutect2_tumour_normal_split.sh $tumourid $tumourbam $normalid $normalbam $interval $refDir $genome $keep_germline
    """
}

process mutect2_merge_annotate_single {     
	executor 'slurm'
    publishDir path: "${params.outDir}/mutect2_tumour_only", mode: 'copy'
    cpus = 8
    memory = 16.GB
    time = 48.hour

input:
    tuple val (sample), val (seq), val (kit), path (vcfs)
    path refDir
	val genome
	path vcf2maf

output:
	tuple val (sample), path ("${sample}_mutect2")
    
script:

	def vcf_list = vcfs.join(',')

	"""
	mutect2_merge_annotate.sh $sample $vcf_list $seq $kit $refDir $genome $vcf2maf
    """
}

process mutect2_merge_annotate {     
	executor 'slurm'
    publishDir path: "${params.outDir}/mutect2_tumour_normal", mode: 'copy'
    cpus = 8
    memory = 16.GB
    time = 48.hour

input:
    tuple val (patient), val (tumourid), val (normalid), val (seq), val (kit), path (vcfs)
    path refDir
	val genome
	path vcf2maf

output:
	tuple val (tumourid), path ("${tumourid}_mutect2")
    
script:

	def vcf_list = vcfs.join(',')

	"""
	mutect2_merge_annotate.sh $tumourid $vcf_list $seq $kit $refDir $genome $vcf2maf
    """
}


process haplotypecaller_split {
    executor 'slurm'
    cpus = 8
    memory = 32.GB
    time = 48.hour

input:
    tuple val (sample), val (patient), val (seq), val (kit), path (bam), path (bai), path (interval)
    path refDir
    val genome

output:
    tuple val (sample), val (patient), val (seq), val (kit), path (bam), path (bai), path ("*split.vcf")
        
script:

    """
    haplotypecaller_split.sh $sample $bam $interval $refDir $genome
    """
}

process haplotypecaller_merge {
    executor 'slurm'
    cpus = 2
    memory = 16.GB
    time = 48.hour

input:
    tuple val (sample), val (patient), val (seq), val (kit), path (bam), path (bai), path (vcfs)

output:
    tuple val (patient), val (sample), path (bam), path(bai), val (seq), val(kit), path ("${sample}.vcf")
        
script:

    def vcf_list = vcfs.join(',')

    """
    haplotypecaller_merge.sh $sample $vcf_list
    """
}

process subset_germline_vcf{
    executor 'slurm'
    cpus = 2
    memory = 16.GB
    time = 48.hour


input:
    tuple val (tumourid), val (patient), path (tumourbam), path (tummourbai), val (seq), val (kit), val (normalid), path (normalbam), path (normalbai), path(normalvcf), path(tumourvcfpath)

output:
    tuple val (patient), val (tumourid), path (tumourbam), path (tummourbai), val (seq), val (kit), val (normalid), path (normalbam), path (normalbai), path("${normalid}_filtered.vcf")

script:

	"""
	bedtools_subtract.sh $normalid $tumourid $normalvcf $tumourvcfpath
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
    memory = 32.GB
    time = 48.hour

input:    
    tuple val (tumourid), val (seq), path (snp_pileup)
    path (facetsR)
    val (facets_cval_preproc)
    val (facets_window)
    val (facets_cval)
    val (facets_ndepth)
    val (genome)
    val (mode)

output:
    path ("${tumourid}_facets")
        
script:
    """
    mkdir ${tumourid}_facets
    module unload openjdk
    module load R/4.5.1
    R --file=runFacets.R --args ${tumourid} ${snp_pileup} ${facets_cval_preproc} ${facets_window} ${facets_cval} ${facets_ndepth} ${genome} ${mode}
    """
}