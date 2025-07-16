# 1. Clone the private repo to WEHI HPC
* Generate a SSH key `ssh-keygen -t ed25519 -C "<your_email>@wehi.edu.au"`
* `cat ~/.ssh/id_ed25519.pub`, copy the SSH key to clipboard
* Add SSH key. Go to **Settings -> Deploy keys -> Add deploy keys**
* Test SSH connection: `ssh -T git@github.com`. If successful, you will see a message: `Hi PapenfussLab/Genomics_nextflow_pipeline! You've successfully authenticated, but GitHub does not provide shell access.`
* Clone the repo `git clone git@github.com:PapenfussLab/Genomics_nextflow_pipeline`

# 2. Pull facet-suite singularity image
`singularity pull --name facets-suite-dev.img docker://philipjonsson/facets-suite:dev`

# 3. Download reference data

# 4. Prepare metadata
A metadata must be a **tsv** file with headings as below: 

| patient | sample | condition | seq | kit | r1 | r2 |
| --- | --- | --- | --- | --- | --- | --- |
| <patient_id> | <sample_id> | <tumour/normal> | <WGS/WES> | <sequencing_kit> | <path_to_fastq_R1> | <path_to_fastq_R2> |
