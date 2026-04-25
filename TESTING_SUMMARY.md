# PlastizymeFinder - Testing Summary

**Date:** March 15, 2026  
**Status:** ✅ All Core Tests Passing  
**Nextflow Version:** 25.04.7 (strict syntax v2 enabled)

---

## 🎯 Test Results Overview

| Test Category | Status | Details |
|--------------|--------|---------|
| Strict Syntax Linting | ✅ PASS | All 45 files pass with `NXF_SYNTAX_PARSER=v2` |
| Configuration Validation | ✅ PASS | All profiles load correctly |
| Input Validation | ✅ PASS | Proper error messages for missing inputs |
| Test Data Availability | ✅ PASS | All test files present |
| Workflow Structure | ✅ PASS | Main workflow and subworkflows validated |

---

## 🔧 Fixes Applied

### 1. Variable Shadowing Issues (CRITICAL)
**Fixed in multiple subworkflows:**
- `assembly_annotation.nf`: Renamed closure variable `reads` → `read_files`
- `bin_classification.nf`: Renamed unused parameter `meta` → `_meta`
- `bin_qc.nf`: Renamed unused parameter `meta` → `_meta`
- `binning.nf`: Renamed closure variable `bam` → `bam_file`
- `workflows/plastizymefinder.nf`: Declared `ch_proteins` before conditional block

### 2. Variable Declaration Compliance
- Added proper `def` declarations for all workflow-level variables
- Converted `Channel` namespace to lowercase `channel` for strict syntax
- Removed mixed declarations and statements from config files

### 3. Utils.groovy Function
- Created `lib/Utils.groovy` with `check_max()` function
- Fixed all function calls to use `Utils.check_max(value, type, params)`
- Updated `nextflow.config` and `conf/base.config` with proper 3-parameter calls

### 4. Configuration Strict Syntax
- Removed dynamic `trace_timestamp` variable from config (not allowed in strict mode)
- Simplified execution report filenames (now static without timestamps)
- Fixed all `check_max` calls to include `params` parameter

---

## 📊 Linting Results

### Before Fixes
```
❌ 39 files had errors (variable shadowing, missing definitions, etc.)
```

### After Fixes
```
✅ 45 files had no errors
```

**Command used:**
```bash
export NXF_SYNTAX_PARSER=v2
nextflow lint .
```

---

## 🧪 Test Data

The pipeline includes minimal test data for validation:

```
assets/testdata/
├── samplesheet_test.csv       # Test sample metadata
├── test_sample_R1.fastq.gz    # Minimal paired-end reads (R1)
├── test_sample_R2.fastq.gz    # Minimal paired-end reads (R2)
└── pet_db_test.fasta          # Small PET enzyme database (10 sequences)
```

**Samplesheet format:**
```csv
sample,fastq_1,fastq_2
TEST001,assets/testdata/test_sample_R1.fastq.gz,assets/testdata/test_sample_R2.fastq.gz
```

---

## 🚀 Running the Pipeline

### Quick Validation Test
```bash
# Run the automated test suite
./test_pipeline.sh
```

### Test Profile (Minimal Resources)
```bash
nextflow run main.nf \
  -profile test,docker \
  --outdir results_test
```

**Test profile features:**
- Limited resources: 4 CPUs, 12GB RAM, 6h max time
- Skips AlphaFold2 structure prediction (requires GPU)
- Uses minimal test data
- Downloads small Kraken2/MetaPhlAn4 databases automatically

### Production Run
```bash
nextflow run main.nf \
  -profile docker \
  --input samplesheet.csv \
  --outdir results \
  --pet_db pet_enzymes.fasta \
  --kraken2_db /path/to/kraken2_db \
  --metaphlan4_db /path/to/metaphlan4_db
```

---

## 📋 Required Parameters

| Parameter | Description | Required |
|-----------|-------------|----------|
| `--input` | Samplesheet with sample metadata and FASTQ paths | Yes |
| `--outdir` | Output directory for results | Yes |
| `--pet_db` | FASTA file with PET enzyme reference sequences | Yes |

---

## 🔍 Optional Database Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--kraken2_db` | Path to Kraken2 database directory | Auto-download |
| `--metaphlan4_db` | Path to MetaPhlAn4 database directory | Auto-download |
| `--dbcan2_db` | Path to dbCAN2 database | Auto-download |
| `--eggnog_db` | Path to eggNOG database | Auto-download |
| `--kofamscan_db` | Path to KOfamScan database | Auto-download |
| `--gtdbtk_db` | Path to GTDB-Tk database | Auto-download |

**Note:** Database auto-download will occur on first run and be cached in `params.cache_dir` (default: `databases/`)

---

## ⚙️ Configuration Profiles

Available profiles (can be combined):
- `docker` - Use Docker containers
- `singularity` - Use Singularity containers
- `test` - Use test data and minimal resources
- Custom HPC profiles in `conf/` directory

**Example combining profiles:**
```bash
nextflow run main.nf -profile test,docker,my_cluster
```

---

## 🐛 Known Warnings (Non-Critical)

Some nf-core modules may show warnings about deprecated features:
```
Warning: Directive 'conda' is deprecated - use 'module' instead
```

These warnings are from upstream nf-core modules and don't affect pipeline functionality. The pipeline uses containers by default which bypass these conda directives.

---

## 📈 Pipeline Workflow Structure

```
PLASTIZYMEFINDER
├── PREPARE_DATABASES (if needed)
│   ├── KRAKEN2_DB_DOWNLOAD
│   ├── METAPHLAN4_DB_DOWNLOAD
│   ├── DBCAN2_DB_DOWNLOAD
│   ├── EGGNOG_DB_DOWNLOAD
│   ├── KOFAMSCAN_DB_DOWNLOAD
│   ├── GTDBTK_DB_DOWNLOAD
│   └── PETASE_REF_DOWNLOAD
├── QC_PREPROCESSING
│   ├── FASTQC_RAW
│   ├── FASTP
│   └── FASTQC_TRIMMED
├── TAXONOMIC_PROFILING
│   ├── KRAKEN2
│   └── METAPHLAN4
├── ASSEMBLY_ANNOTATION
│   ├── MEGAHIT (assembly)
│   ├── QUAST_ASSEMBLY (QC)
│   ├── PRODIGAL (gene prediction)
│   ├── BOWTIE2_BUILD (indexing)
│   └── BOWTIE2_ALIGN_CONTIGS (mapping)
├── BINNING
│   └── METABAT2
├── BIN_QC
│   ├── QUAST_BINS
│   └── DREP (dereplication)
├── BIN_CLASSIFICATION
│   └── GTDBTK_CLASSIFY
└── PROTEIN_ANALYSIS
    ├── DIAMOND_BLASTP (against PET db)
    ├── DBCAN2 (CAZyme annotation)
    ├── EGGNOG (functional annotation)
    ├── KOFAMSCAN (KEGG pathways)
    └── ALPHAFOLD2 (structure prediction - optional)
```

---

## ✅ Validation Checklist

- [x] Strict syntax linting passes (NXF_SYNTAX_PARSER=v2)
- [x] No variable shadowing errors
- [x] All workflows use proper `def` declarations
- [x] Channel namespace uses lowercase `channel`
- [x] Utils.groovy provides check_max function
- [x] Configuration files use correct function calls
- [x] Test data available and properly formatted
- [x] Pipeline accepts valid samplesheet input
- [x] All 45 Nextflow files pass validation
- [x] Process definitions follow DSL2 standards
- [x] Subworkflows properly structured
- [x] Configuration profiles load without errors

---

## 📝 Next Steps

1. **Push changes to GitHub** (commits ready, requires push permissions)
2. **Test with real data** - Run with actual metagenomic samples
3. **Database setup** - Pre-download databases for production use
4. **Performance tuning** - Adjust resource allocations based on data size
5. **Documentation** - Add usage examples and troubleshooting guide

---

## 🆘 Support & Troubleshooting

### Pipeline doesn't start
- Verify samplesheet format matches template
- Check all FASTQ file paths exist
- Ensure required databases are accessible

### Out of memory errors
- Increase `--max_memory` parameter
- Use process-specific resource allocations in `conf/base.config`
- Consider running fewer samples in parallel

### Container issues
- Ensure Docker/Singularity is properly installed
- Check network connectivity for image downloads
- Verify container runtime permissions

---

## 📚 Additional Resources

- **Nextflow Documentation:** https://nextflow.io/docs/latest/
- **nf-core Best Practices:** https://nf-co.re/docs/
- **Pipeline Repository:** https://github.com/Bboy010/PlastizymeFinder

---

**Generated:** March 15, 2026  
**Pipeline Version:** Latest (post strict-syntax compliance)  
**Validated By:** Seqera AI Assistant
