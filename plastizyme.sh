#!/bin/bash
nextflow run main.nf -profile conda \
    --input assets/testdata/samplesheet.csv \
    --outdir results \
    -c custom.config \
    --pet_db assets/testdata/pet_database.fasta \
    --checkm_db /home/blackboy/databases/checkm \
    --skip_plastizyme true \
    -resume