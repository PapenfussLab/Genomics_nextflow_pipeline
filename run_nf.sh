#!/bin/bash

module load nextflow/25.04.2

nextflow run genomics_pipeline.nf \
    --metadata "<path_to_metadata>" \
    --genome "<GRCh38/GRCm38>" \
    --refDir "<path_to_refdata>" \
    --outDir "<path_to_outDir>" \
    --facets_cval_preproc 50 --facets_window 500 --facets_cval 700 --mode "unmatched" --keep_germline_var "FALSE" -resume