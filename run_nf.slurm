#!/bin/bash


#SBATCH --job-name=genomics_nf
#SBATCH --ntasks=1
#SBATCH -t 14-00:00:00
#SBATCH --partition=long
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=zhao.p@wehi.edu.au
#SBATCH --mail-type=ALL
#SBATCH -o nf.out
#SBATCH -e nf.err
#SBATCH --mem-per-cpu=4G

module load nextflow/25.04.2

nextflow run genomics_pipeline.nf \
    --metadata "/vast/projects/Fu_HCC_WGS/HCC_WGS_batch2/analysis/metadata/WGS_batch2_meta_tumour_only.csv" \
    --genome "GRCm38" \
    --refDir "/vast/projects/papenfuss_brain_mets/ref/genomics_nf_refdata" \
    --outDir "/vast/projects/Fu_HCC_WGS/HCC_WGS_batch2/results" \
    --input "fastq" --mode "matched" --keep_germline_var "FALSE" --facets_cval_preproc 50 --facets_window 500 --facets_cval 700 \
    --singularity_cacheDir "/vast/projects/papenfuss_brain_mets/zhao.p/singularity_cache" \
    --deepsomatic_containerDir "/vast/projects/papenfuss_brain_mets/multiomics/WGS/analysis/Genomics_nextflow_pipeline/deepsomatic_1.9.0.sif" \
    --run_deepsomatic="FALSE" --mutect2_job_thread 10 -resume
