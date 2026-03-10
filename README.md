# 1. Download reference data
The ref data file is in GP_transfer.

`cp /stornext/General/scratch/GP_Transfer/zhao.p/refdata.tar.gz .; tar -xvzf refdata.tar.gz`

Need to find a way for long-term storage and easy access, e.g. AWS bucket.   

# 2. Install Deepsomatic via singularity  
`module load singularity/4.1.5`  
`singularity pull docker://google/deepsomatic:1.10.0`  

Provide --deepsomatic_containerDir <path_to_deepsomatic_image> as an input option.

# 3. Prepare metadata
## -input fastq
Start analysis from paired-end fastq files.
A metadata must be a **csv** file with headings as below: 

| patient | sample | condition | seq | kit | r1 | r2 |
| --- | --- | --- | --- | --- | --- | --- |
| <patient_id> | <sample_id> | <tumour/normal> | <WGS/WES> | <sequencing_kit> | <path_to_fastq_R1> | <path_to_fastq_R2> |
* **patient -** Unique identifier for each patient.
* **sample -** Unique identifier for each sample.
* **condition -** Either tumour or normal. Note that each tumour must have **one** matching normal sample with the sampe **patient** and **kit**. One normal sample can be matched to multiple tumour samples.
* **seq -** Either WGS or WES.
* **kit -** Name of the sequencing kit. Note that tumour-normal pairs must be sequenced by the sample kit. For WES, kit information is used to define varaint calling operation intervals. Currently supported kit include:
  * twist2
  * SureSelect_Human_allExons_V5
  * SureSelect_Human_allExons_V6
* **r1** Path to R1 fastq files.
* **r2** Path to R2 fastq files.

## -input bam
Start analysis from unprocessed bam files.
A metadata must be a **csv** file with headings as below: 

| patient | sample | condition | seq | kit | bam |
| --- | --- | --- | --- | --- | --- |
| <patient_id> | <sample_id> | <tumour/normal> | <WGS/WES> | <sequencing_kit> | <path_to_bam> |

* If multiple bam files are listed for one sample, bams will be merged using samtools.  
* Markduplicate will be run on the input/merged bams if not identified in the bam header.  
* ID and SM in the RG will be set to sample_id.

## -input bam_processed
Start analysis from processed bam files.
A metadata must be a **csv** file with headings as below: 

| patient | sample | condition | seq | kit | bam | bai | markdup_metrics |
| --- | --- | --- | --- | --- | --- | --- | --- |
| <patient_id> | <sample_id> | <tumour/normal> | <WGS/WES> | <sequencing_kit> | <path_to_bam> | <path_to_bam_index> | <path_to_markduplicate_metrics> |

* In this mode, only one bam file per sample is allowed.
* bam files must be marked duplicate and indexed. 
* SM in the RG must be the same as sample_id. 

# 4. Modes of analysis
## --mode matched  
Must have one normal sample per patient.   
Mutect2 & Deepsomatic tumour-normal variant calling and Facets CNV profiling will run on all *tumour* samples. 

## --mode tumour_only
Normal samples are not required but can be included.   
Mutect2 tumour-only variant calling will be run on *all* samples individually regardless of the "condition" column.   
Facets CNV will *not* run in tumour_only mode.   

## --mode unmatched
Must have one normal sample per patient.   
Mutect2 & Deepsomatic tumour-normal variant calling will be run on all tumour samples.   
Facets CNV will also run but with "unmatched" mode and different parameters.   
This mode is designed for mouse samples/cell lines whereas the germline samples from the same mice are not sequenced; fastq/bam files of the same strain (and the same sequencing kit for WES) can be used as the "normal" sample.   
Put the mouse strain name (e.g. BALB_cJ) in the "patient" column and set the mode to `unmatched`.

# 5. Run nf pipeline 

`nextflow run genomics_pipeline.nf --genome "GRCh38" --metadata "<path_to_metadata>" --refDir "<path_to_refdata>" --outDir "<path_to_outputDir>" --deepsomatic_containerDir "<path_to_deepsomatic_image>" --input "fastq" --mode "matched"`

Options:
* --genome: Reference genome build. Currently "GRCh38" and "GRCm38" are supported. Default=`GRCh38`
* --metadata*: Path to metadata file
* --refDir*: Path to reference data directory
* --outDir*: Path to output directory
* --deepsomatic_containerDir*: Path to deepsomatic image
* --input: Input file type. Default=`fastq`
* --mode: Mode of analyses. Default=`matched`
* --facets_cval_preproc: Default=`25`
* --facets_window: Default=`250`
* --facets_cval: Default=`200`
* --facets_ndepth: Default=`35`
* --keep_germline_var: Default=`FALSE`. Set to `TRUE` to keep germline varaints in Mutect2 VCF files at the cost of run time
* --mutect2_job_thread: number of parallel intervals for variant calling. Default=`50`
* --singularity_cacheDir: specify the singularity cache path. Default=`~/.singularity/cache`
