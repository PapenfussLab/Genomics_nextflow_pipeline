# 1. Clone the private repo to WEHI HPC
* Generate a SSH key `ssh-keygen -t ed25519 -C "<your_email>@wehi.edu.au"`
* `cat ~/.ssh/id_ed25519.pub`, copy the SSH key to clipboard
* Add SSH key. Go to **Settings -> Deploy keys -> Add deploy keys**
* Test SSH connection: `ssh -T git@github.com`. If successful, you will see a message: `Hi PapenfussLab/Genomics_nextflow_pipeline! You've successfully authenticated, but GitHub does not provide shell access.`
* Clone the repo `git clone git@github.com:PapenfussLab/Genomics_nextflow_pipeline`

# 2. Download reference data
The ref data file is in GP_transfer.

`cp /stornext/General/scratch/GP_Transfer/zhao.p/refdata.tar.gz .; tar -xvzf refdata.tar.gz`

Need to find a way for long-term storage and easy access, e.g. AWS bucket. 

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

# 4. Run nf pipeline 

`nextflow run genomics_pipeline.nf --genome "GRCh38" --metadata "<path_to_metadata>" --facetsuite "<path_to_facets-suite-dev.img>" --refDir "<path_to_refdata>" --outDir "<path_to_outputDir>"`

Options:
* --genome: Reference genome build. Currently "GRCh38" and "GRCm38" are supported. Default=`GRCh38`
* --metadata*: Path to metadata file
* --refDir*: Path to reference data directory
* --outDir*: Path to output directory
* --facets_cval_preproc: Default=`25`
* --facets_window: Default=`250`
* --facets_cval: Default=`200`
* --mode: Default=`matched`. Set to `unmatched` if the tumour and normal are not matched. This will impact the HET site calling and logOR calculation by FACETS
* --keep_germline_var: Default=`FALSE`. Set to `TRUE` to keep germline varaints in mutect2 calls at the cost of run time. 

# 5. Mouse samples  
For mouse samples/cell lines without matched germline, you can download publicaly available fastq files of the same mouse strain (and the same sequencing kit for WES).   
Put the mouse strain name (e.g. BALB_cJ) in the "patient" column of the metadata file and set the mode to `unmatched`.
