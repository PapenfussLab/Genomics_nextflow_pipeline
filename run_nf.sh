#!/bin/bash

module load nextflow/25.04.2

nextflow run genomics_pipeline.nf \
    --metadata "/vast/ai_projects/melanoma_depigmentation_biomarker_discovery/prachi_mel_WES/analysis/metadata/metadata.tsv" \
    --genome "GRCh38" \
    --refDir "/vast/ai_projects/melanoma_depigmentation_biomarker_discovery/prachi_mel_WES/analysis/refdata" \
    --outDir "/vast/ai_projects/melanoma_depigmentation_biomarker_discovery/prachi_mel_WES/results" -resume
