#!/bin/bash

echo "=========================================="
echo "PlastizymeFinder - Test Data Demonstration"
echo "=========================================="
echo ""

# Show test configuration
echo "1. Test Configuration:"
echo "   Profile: test,docker"
echo "   Max CPUs: 4"
echo "   Max Memory: 12GB"
echo "   Max Time: 6 hours"
echo ""

# Show test data
echo "2. Test Data:"
echo "   Sample: TEST001"
cat assets/testdata/samplesheet.csv
echo ""

# Show PET database size
echo "3. PET Enzyme Database:"
grep "^>" assets/testdata/pet_db_test.fasta | wc -l | xargs echo "   Sequences:"
echo ""

# Explain what would run
echo "4. Pipeline Steps (with test profile):"
echo "   ✓ QC & Preprocessing (FastQC, Fastp)"
echo "   ✓ Taxonomic Profiling (Kraken2, MetaPhlAn4)"
echo "   ✓ Assembly (MEGAHIT)"
echo "   ✓ Gene Prediction (Prodigal)"
echo "   ✓ Binning (MetaBAT2)"
echo "   ✓ Bin QC (QUAST, dRep)"
echo "   ✓ Taxonomy (GTDB-Tk)"
echo "   ✓ Protein Analysis (DIAMOND, dbCAN2, eggNOG, KOfamScan)"
echo "   ✗ Structure Prediction (Skipped - requires GPU)"
echo ""

echo "5. To run the actual test:"
echo "   nextflow run main.nf -profile test,docker --outdir test_results"
echo ""
echo "   Note: This requires downloading databases (~5-10GB total)"
echo "   First run will cache databases in ./databases/ directory"
echo ""

echo "6. For quick syntax-only validation (no execution):"
echo "   nextflow run main.nf -profile test,docker -stub-run --outdir stub_test"
echo ""

echo "=========================================="
echo "Ready to test!"
echo "=========================================="
