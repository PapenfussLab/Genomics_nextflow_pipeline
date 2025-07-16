#!/bin/bash

module load nextflow/25.04.2

nextflow run genomics_pipeline.nf \
    --metadata "<path_to_metadata>" \
    --genome "GRCh38" \
    --facetsuite "<path_to_facets-suite-dev.img>" \
    --refDir "<path_to_refdata>" \
    --outDir "<path_to_outDir>" -resume