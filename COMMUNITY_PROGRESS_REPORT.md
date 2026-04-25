# PlastizymeFinder — Community Progress Report

> **Posted to**: Nextflow Community Forum / nf-core Slack  
> **Date**: April 2026  
> **Repo**: https://github.com/Bboy010/PlastizymeFinder  
> **Author**: Bboy010  

---

## Overview

Hi Nextflow community! I am building **PlastizymeFinder**, a DSL2 metagenomics pipeline for the **discovery and structural validation of plastic-degrading enzymes (plastizymes)** from environmental samples.

The pipeline takes raw paired-end sequencing reads, performs metagenomics analysis from QC to genome binning, then uses a custom tool (**MeTarENZ**) to identify candidate plastizymes against a curated reference database (PET_DB). Candidates are then validated by 3D structure prediction (AlphaFold2) and structural comparison to known PETase references (TM-Align).

I am about **85% complete** but have hit several roadblocks I would love community help with. The full code is available at: https://github.com/Bboy010/PlastizymeFinder

---

## Pipeline Architecture

```
Raw reads (paired-end FASTQ)
    │
    ▼
[Stage 1] QC & Preprocessing ✅
    FastQC → fastp → Bowtie2 (host removal) → FastQC
    │
    ├──► [Stage 2] Taxonomic Profiling ✅ (skippable)
    │        Kraken2 + MetaPhlAn4
    │
    ▼
[Stage 3] Assembly & Gene Prediction ✅
    MEGAHIT → QUAST → Prodigal → Bowtie2 (coverage BAMs)
    │
    ▼
[Stage 4] Genome Binning ✅
    MetaBAT2
    │
    ▼
[Stage 5] Bin QC & Dereplication ✅
    QUAST + dRep
    │
    ├──► [Stage 6] Taxonomic Annotation ✅ (skippable)
    │        Prokka → CD-HIT → GTDB-tk
    │        eggNOG-mapper + dbCAN2 + KofamScan (parallel)
    │
    ▼
[Stage 7] Plastizyme Prediction 🔴 BLOCKED
    MeTarENZ vs PET_DB → candidate FASTA
    │
    ▼
[Stage 8] 3D Structure Validation ✅ (skippable)
    CD-Search → AlphaFold2 → TM-Align vs PETase ref (6EQE)
    │
    ▼
MultiQC report ⚠️ INCOMPLETE
```

**9 subworkflows** — all modular and independently skippable.  
**7 database auto-download modules** — Kraken2, MetaPhlAn4, GTDB-tk, eggNOG, dbCAN2, KofamScan, PETase ref (6EQE).

---

## What Is Working

| Stage | Status | Notes |
|-------|--------|-------|
| QC & Preprocessing | ✅ Complete | fastp, FastQC, Bowtie2 host removal |
| Taxonomic Profiling | ✅ Complete | Kraken2 + MetaPhlAn4, skippable |
| Assembly & Annotation | ✅ Complete | MEGAHIT, QUAST, Prodigal |
| Genome Binning | ✅ Complete | MetaBAT2 |
| Bin QC & Dereplication | ✅ Complete | dRep with completeness/contamination filters |
| Functional Annotation | ✅ Complete | eggNOG, dbCAN2, KofamScan, GTDB-tk |
| Structure Prediction | ✅ Complete | AlphaFold2 + TM-Align vs 6EQE |
| DB auto-download | ✅ Complete | All 7 databases, storeDir caching |
| Samplesheet validation | ✅ Complete | Python script with format checking |
| Configuration | ✅ Complete | base.config, modules.config, test profile |
| Documentation | ✅ Complete | Full README with parameters, outputs, citations |

---

## Blockers — Where I Need Help

### 🔴 BLOCKER #1 — MeTarENZ container not available on Biocontainers

**This is the main issue.** The core step of the pipeline (Stage 7) uses a custom tool called **MeTarENZ** that I developed. I have referenced it in the module as:

```groovy
// modules/local/metatarenz/main.nf
conda "bioconda::metatarenz"
container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/metatarenz:latest' :
    'quay.io/biocontainers/metatarenz:latest' }"
```

**The container does not yet exist on Biocontainers/BioRxiv.** This forces me to set `skip_plastizyme = true` in all test runs, which defeats the purpose of the pipeline.

**Questions:**
- What is the recommended process to submit a tool to Bioconda + Biocontainers for use in a Nextflow module?
- Is there a faster alternative for testing (e.g., building a local Docker image and referencing it in `nextflow.config`)?
- Are there examples of nf-core pipelines using custom local containers before official Bioconda submission?

---

### ⚠️ ISSUE #2 — MultiQC report is incomplete

Currently, MultiQC only collects reports from Stage 1 (FastQC + fastp). Reports from Kraken2, QUAST, Prokka and other tools are not forwarded to MultiQC.

**Current code** in `workflows/plastizymefinder.nf`:
```groovy
MULTIQC(
    ch_qc_reports.map { meta, files -> files }.collect(),
    [],  // config — not used
    [],  // logo — not used
    []   // modules — not used
)
```

`ch_qc_reports` only receives output from `QC_PREPROCESSING`.

**Questions:**
- What is the recommended pattern in DSL2 for mixing outputs from multiple subworkflows into a single `ch_multiqc_files` channel?
- Is `mix()` + `.collect()` the right approach, or should I use a different operator?

---

### ⚠️ ISSUE #3 — Test samplesheet uses hardcoded absolute paths

The test samplesheet references FASTQ files at a machine-specific path:

```
assets/testdata/samplesheet.csv → /mnt/e/Bio-informatics/Hongo/data/...
```

This makes the test profile non-portable.

**Questions:**
- What is the nf-core convention for test FASTQ files? Should I host them on Zenodo or use the nf-core test-datasets repository?
- Is there a minimal synthetic metagenomics dataset I could use for CI testing?

---

### ⚠️ ISSUE #4 — AlphaFold2 GPU configuration

AlphaFold2 requires a GPU but the accelerator configuration is commented out:

```groovy
// conf/base.config — inside withName: ALPHAFOLD2
// accelerator = 1    // uncomment for GPU clusters
time   = 24.h
memory = 60.GB
```

**Questions:**
- What is the correct way to make GPU allocation optional/configurable via profiles in Nextflow?
- Is there a community convention for handling GPU vs CPU fallback in nf-core modules?

---

## Minor Issues I Am Aware Of

- `plastizyme.sh` (convenience wrapper script) incorrectly has `--skip_plastizyme true` — debugging artifact, will fix
- Database downloads do not verify checksums — plan to add MD5 verification
- `params.help`, `params.email`, `params.monochrome_logs` defined but not implemented
- TM-Align output parsing uses fragile `grep` patterns that may not match all TMalign output formats

---

## Relevant Files

```
PlastizymeFinder/
├── main.nf                              # Entry point
├── nextflow.config                      # Profiles: docker, singularity, conda, test
├── nextflow_schema.json                 # Parameter schema
├── conf/
│   ├── base.config                      # Resource labels
│   ├── modules.config                   # Per-tool args & publishDir
│   └── test.config                      # Test profile (skip_plastizyme=true for now)
├── workflows/
│   ├── plastizymefinder.nf              # Main workflow
│   └── subworkflows/
│       ├── qc_preprocessing.nf
│       ├── taxonomic_profiling.nf
│       ├── assembly_annotation.nf
│       ├── binning.nf
│       ├── bin_qc.nf
│       ├── bin_classification.nf
│       ├── plastizyme_prediction.nf     # 🔴 Blocked on MeTarENZ container
│       └── structure_prediction.nf
├── modules/
│   ├── local/
│   │   ├── metatarenz/main.nf           # 🔴 Custom tool — no container yet
│   │   ├── tmalign/main.nf              # Custom TM-Align wrapper
│   │   └── db_download/                 # 7 auto-download modules
│   └── nf-core/                         # Standard nf-core modules
└── assets/testdata/
    ├── samplesheet.csv                  # ⚠️ Hardcoded paths
    └── pet_db_test.fasta                # Minimal PET_DB for testing
```

---

## Technical Stack

| Tool | Version | Purpose |
|------|---------|---------|
| Nextflow | ≥ 23.04.0 | Workflow engine |
| FastQC | Any | Read QC |
| fastp | Any | Trimming & adapter removal |
| Bowtie2 | Any | Host decontamination |
| Kraken2 | Any | k-mer taxonomic classification |
| MetaPhlAn4 | 4.x | Species-level profiling |
| MEGAHIT | Any | Metagenomic assembly |
| QUAST | Any | Assembly QC |
| Prodigal | Any | Gene prediction |
| MetaBAT2 | Any | Genome binning |
| dRep | Any | Bin dereplication |
| Prokka | Any | Genome annotation |
| CD-HIT | Any | Protein clustering |
| GTDB-tk | ≥ 2.0 | Taxonomy classification |
| eggNOG-mapper | Any | Functional annotation |
| dbCAN2 | Any | CAZyme annotation |
| KofamScan | Any | KEGG KO assignment |
| **MeTarENZ** | custom | **Plastizyme prediction** |
| AlphaFold2 | 2.x | 3D structure prediction |
| TM-Align | Any | Structural comparison |
| MultiQC | Any | Report aggregation |

---

## What I Am Looking For

1. **Guidance on MeTarENZ containerization** — how to get a custom tool ready for Biocontainers / Bioconda quickly for pipeline testing
2. **MultiQC channel mixing pattern** — DSL2 best practice for aggregating QC files from many subworkflows
3. **Portable test data** — recommended approach for hosting small metagenomics test FASTQ files
4. **GPU profile pattern** — optional GPU allocation in `base.config`
5. **Any general code review** on the DSL2 structure — happy to get feedback on channel handling, module design, etc.

Any help is greatly appreciated. The pipeline addresses a real scientific need (plastic biodegradation research) and I would love to eventually submit it to nf-core once these issues are resolved.

Thank you!

---

*Pipeline repo: https://github.com/Bboy010/PlastizymeFinder*  
*Built with Nextflow DSL2 — nf-core module conventions followed throughout*
