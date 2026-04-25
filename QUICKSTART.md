# PlastizymeFinder - Quick Start Guide

## 🚀 Get Started in 3 Steps

### 1️⃣ Validate Installation
```bash
cd PlastizymeFinder
./test_pipeline.sh
```

### 2️⃣ Run Test Data
```bash
nextflow run main.nf -profile test,docker --outdir test_results
```

### 3️⃣ Run Your Data
```bash
nextflow run main.nf -profile docker \
  --input samplesheet.csv \
  --outdir results \
  --pet_db pet_enzymes.fasta
```

---

## 📋 Samplesheet Format

Create `samplesheet.csv`:
```csv
sample,fastq_1,fastq_2
SAMPLE1,path/to/sample1_R1.fastq.gz,path/to/sample1_R2.fastq.gz
SAMPLE2,path/to/sample2_R1.fastq.gz,path/to/sample2_R2.fastq.gz
```

---

## ⚙️ Common Options

```bash
# Resource limits
--max_cpus 16
--max_memory '64.GB'
--max_time '48.h'

# Provide databases (or auto-download)
--kraken2_db /path/to/kraken2
--metaphlan4_db /path/to/metaphlan4

# Skip optional steps
--skip_taxonomy
--skip_structure
```

---

## 📊 Check Results

```bash
ls -lh results/
```

Key outputs:
- `qc/` - Quality control reports
- `taxonomy/` - Taxonomic profiles
- `assembly/` - Assembled contigs
- `binning/` - Metagenomic bins
- `annotation/` - Protein annotations
- `plastizymes/` - **PET enzyme candidates**

---

## 🆘 Need Help?

- **Full documentation:** `TESTING_SUMMARY.md`
- **Changes applied:** `CHANGES_APPLIED.md`
- **Pipeline logs:** `.nextflow.log`
- **Test demo:** `./run_test_demo.sh`

---

Happy PET enzyme hunting! 🧬🔬
