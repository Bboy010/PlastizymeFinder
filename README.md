# PlastizymeFinder

> A Nextflow metagenomics pipeline for the discovery and structural validation of plastic-degrading enzymes (plastizymes) from environmental samples.

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg)](https://sylabs.io/docs/)
[![run with conda](https://img.shields.io/badge/run%20with-conda-3EB049?logo=anaconda)](https://docs.conda.io/en/latest/)

---

## Table of contents

- [Introduction](#introduction)
- [Pipeline overview](#pipeline-overview)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Input](#input)
- [Databases](#databases)
- [Parameters](#parameters)
- [Output](#output)
- [Pipeline stages in detail](#pipeline-stages-in-detail)
- [Citation](#citation)

---

## Introduction

**PlastizymeFinder** is a bioinformatics pipeline built with [Nextflow DSL2](https://www.nextflow.io/) that identifies and characterizes plastic-degrading enzymes in metagenomic datasets. Starting from raw sequencing reads, the pipeline performs quality control, taxonomic profiling, metagenomic assembly, genome binning, functional annotation, and targeted plastizyme prediction using [MeTarENZ](https://github.com/Bboy010/MeTarENZ) against a curated PET_DB database. Candidate enzymes are then subjected to 3D structure prediction (AlphaFold2) and structural comparison to known PETase references (TM-Align).

The pipeline was developed as part of the **March 2026 nf-core Hackathon**.

---

## Pipeline overview

```
Raw FASTQ reads
      │
      ▼
┌─────────────────────────────┐
│  Stage 1 — QC & Preprocessing │
│  FastQC → fastp → Bowtie2    │  (host/PhiX removal)
│  → FastQC (trimmed)          │
└──────────────┬──────────────┘
               │
       ┌───────┴────────┐
       ▼                ▼
┌─────────────┐  ┌─────────────────────┐
│  Stage 2    │  │  Stage 3            │
│  Taxonomic  │  │  Assembly &         │
│  Profiling  │  │  Annotation         │
│  Kraken2    │  │  MEGAHIT → QUAST    │
│  MetaPhlAn4 │  │  → Prodigal         │
└─────────────┘  └──────────┬──────────┘
                             │
                      ┌──────▼──────┐
                      │  Stage 4    │
                      │  Binning    │
                      │  MetaBAT2   │
                      └──────┬──────┘
                      bins   │  unbinned
                      ┌──────▼──────┐
                      │  Stage 5    │
                      │  Bin QC     │
                      │  QUAST+dRep │
                      └──────┬──────┘
                      HQ bins│
                      ┌──────▼──────────────────┐
                      │  Stage 6                │
                      │  Bin Classification     │
                      │  Prokka → CD-HIT →      │
                      │  GTDB-tk                │
                      │  eggNOG | dbCAN2 | KEGG │  (parallel)
                      └──────┬──────────────────┘
                             │
              HQ bins + unbinned + PET_DB
                      ┌──────▼──────┐
                      │  Stage 7    │
                      │  Plastizyme │
                      │  Prediction │
                      │  MeTarENZ   │
                      └──────┬──────┘
                      candidates
                      ┌──────▼──────────────────┐
                      │  Stage 8                │
                      │  Structure Prediction   │
                      │  CD-Search ║ AlphaFold2 │  (parallel)
                      │  → TM-Align vs PETase   │
                      └─────────────────────────┘
                             │
                      MultiQC Report
```

---

## Requirements

- [Nextflow](https://www.nextflow.io/) ≥ 23.04.0
- [Docker](https://www.docker.com/), [Singularity](https://sylabs.io/), or [Conda](https://docs.conda.io/)
- Java 11 or later

Install Nextflow:

```bash
curl -s https://get.nextflow.io | bash
mv nextflow ~/bin/
```

---

## Quick start

### 1. Download the PET_DB

The PET_DB is a curated database of plastic-degrading enzyme sequences (PAZy, NCBI, BRENDA, UniProt). It requires manual curation and is **not auto-downloaded**.

Download the pre-built version from the project releases:

```bash
# Download default PET_DB (see releases page)
wget https://github.com/Bboy010/PlastizymeFinder/releases/download/v1.0.0/pet_db.fasta
```

To build your own database, follow the guide: [`docs/pet_db_guide.md`](docs/pet_db_guide.md)

### 2. Prepare a samplesheet

Create a CSV file describing your samples (see [Input](#input)):

```csv
sample,fastq_1,fastq_2
SAMPLE1,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
SAMPLE2,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
SAMPLE3,/path/to/sample3.fastq.gz,
```

### 3. Run the pipeline

**Minimum run** (databases auto-downloaded):

```bash
nextflow run Bboy010/PlastizymeFinder \
    -profile docker \
    --input samplesheet.csv \
    --pet_db /path/to/pet_db.fasta \
    --outdir results
```

**With pre-downloaded databases** (recommended for large runs):

```bash
nextflow run Bboy010/PlastizymeFinder \
    -profile singularity \
    --input samplesheet.csv \
    --pet_db /path/to/pet_db.fasta \
    --kraken2_db /path/to/kraken2_db/ \
    --metaphlan4_db /path/to/metaphlan4_db/ \
    --gtdbtk_db /path/to/gtdbtk_db/ \
    --eggnog_db /path/to/eggnog_db/ \
    --dbcan2_db /path/to/dbcan2_db/ \
    --kofamscan_db /path/to/kofamscan_db/ \
    --outdir results
```

**With a custom PETase reference for TM-Align** (default: 6EQE auto-downloaded):

```bash
nextflow run Bboy010/PlastizymeFinder \
    -profile docker \
    --input samplesheet.csv \
    --pet_db /path/to/pet_db.fasta \
    --petase_ref /path/to/custom_petase.pdb \
    --outdir results
```

**Test run** (minimal dataset, no GPU):

```bash
nextflow run Bboy010/PlastizymeFinder \
    -profile test,docker \
    --outdir results_test
```

---

## Input

### Samplesheet format

The input samplesheet is a comma-separated file with the following columns:

| Column    | Required | Description                                      |
|-----------|----------|--------------------------------------------------|
| `sample`  | Yes      | Unique sample identifier (alphanumeric, `_`, `-`) |
| `fastq_1` | Yes      | Path to forward reads (`.fastq.gz`)               |
| `fastq_2` | No       | Path to reverse reads. Omit for single-end data   |

Example:

```csv
sample,fastq_1,fastq_2
SOIL_A,/data/soil_a_R1.fastq.gz,/data/soil_a_R2.fastq.gz
OCEAN_B,/data/ocean_b_R1.fastq.gz,/data/ocean_b_R2.fastq.gz
COMPOST_C,/data/compost_c.fastq.gz,
```

---

## Databases

| Database     | Parameter        | Auto-download | Size   | Source                                                                 |
|--------------|-----------------|---------------|--------|------------------------------------------------------------------------|
| PET_DB       | `--pet_db`       | No (**required**) | ~10 MB | [GitHub Releases](https://github.com/Bboy010/PlastizymeFinder/releases) |
| Kraken2      | `--kraken2_db`   | Yes           | ~70 GB | Built via `kraken2-build`                                              |
| MetaPhlAn4   | `--metaphlan4_db`| Yes           | ~3 GB  | Downloaded via `metaphlan --install`                                   |
| GTDB-tk      | `--gtdbtk_db`    | Yes           | ~70 GB | [data.gtdb.ecogenomic.org](https://data.gtdb.ecogenomic.org)           |
| eggNOG       | `--eggnog_db`    | Yes           | ~50 GB | Downloaded via `download_eggnog_data.py`                               |
| dbCAN2       | `--dbcan2_db`    | Yes           | ~1 GB  | [pro.unl.edu/dbCAN2](https://pro.unl.edu/dbCAN2/download/Databases/V12/) |
| KofamScan    | `--kofamscan_db` | Yes           | ~30 GB | [ftp.genome.jp/pub/db/kofam](ftp://ftp.genome.jp/pub/db/kofam/)        |
| PETase ref   | `--petase_ref`   | Yes (6EQE)    | <1 MB  | [RCSB PDB 6EQE](https://www.rcsb.org/structure/6EQE)                  |

> **Note on PET_DB:** The PET_DB is built by manually curating sequences from PAZy, NCBI, BRENDA, and UniProt. It cannot be auto-generated because it requires expert domain knowledge. A pre-built version is provided with each pipeline release. To build your own, follow [`docs/pet_db_guide.md`](docs/pet_db_guide.md).

> **Note on PETase reference (TM-Align):** By default, PlastizymeFinder uses **6EQE** (IsPETase from *Ideonella sakaiensis* 201-F6) as the structural reference for TM-Align. You can substitute any PETase PDB structure using `--petase_ref`.

---

## Parameters

### Input / Output

| Parameter         | Default    | Description                                   |
|-------------------|------------|-----------------------------------------------|
| `--input`         | (required) | Path to input samplesheet CSV                 |
| `--outdir`        | `results`  | Output directory                              |
| `--pet_db`        | (required) | Path to PET_DB FASTA                         |

### Databases

| Parameter          | Default | Description                                           |
|--------------------|---------|-------------------------------------------------------|
| `--kraken2_db`     | null    | Kraken2 DB directory. Auto-downloaded if not provided |
| `--metaphlan4_db`  | null    | MetaPhlAn4 DB directory. Auto-downloaded if not provided |
| `--gtdbtk_db`      | null    | GTDB-tk reference directory. Auto-downloaded if not provided |
| `--eggnog_db`      | null    | eggNOG DB directory. Auto-downloaded if not provided  |
| `--dbcan2_db`      | null    | dbCAN2 DB directory. Auto-downloaded if not provided  |
| `--kofamscan_db`   | null    | KofamScan profiles directory. Auto-downloaded if not provided |
| `--petase_ref`     | null    | PETase reference PDB. Downloads 6EQE from RCSB if not provided |
| `--db_cache_dir`   | `./databases` | Directory for auto-downloaded databases         |

### Reference

| Parameter       | Default | Description                                       |
|-----------------|---------|---------------------------------------------------|
| `--host_genome` | null    | Host genome FASTA for decontamination (optional)  |

### Pipeline control

| Parameter           | Default | Description                                            |
|---------------------|---------|--------------------------------------------------------|
| `--skip_taxonomy`   | false   | Skip Stage 2 (Kraken2 + MetaPhlAn4)                   |
| `--skip_annotation` | false   | Skip Stage 6 (eggNOG, dbCAN2, kofamscan)               |
| `--skip_structure`  | false   | Skip Stage 8 (AlphaFold2 + TM-Align)                  |
| `--min_contig_len`  | 1000    | Minimum contig length (bp) after assembly              |
| `--min_bin_size`    | 200000  | Minimum bin size (bp) for MetaBAT2                     |
| `--min_completeness`| 50      | Minimum bin completeness (%) for dRep filtering        |
| `--max_contamination`| 10     | Maximum bin contamination (%) for dRep filtering       |

### Resource limits

| Parameter     | Default  |
|---------------|----------|
| `--max_cpus`  | 16       |
| `--max_memory`| 128.GB   |
| `--max_time`  | 240.h    |

---

## Output

```
results/
├── fastqc/
│   ├── raw/                        # FastQC reports on raw reads
│   └── trimmed/                    # FastQC reports on trimmed reads
├── fastp/                          # fastp trimming reports and logs
├── host_removal/                   # Bowtie2 host removal logs
├── taxonomy/
│   ├── kraken2/                    # Kraken2 classification reports
│   ├── metaphlan4/                 # MetaPhlAn4 species profiles
│   └── gtdbtk/                     # GTDB-tk bin taxonomy
├── assembly/
│   ├── *.contigs.fa.gz             # Assembled contigs
│   ├── quast/                      # Assembly quality report
│   ├── prodigal/                   # Predicted genes (.gff, .faa, .fna)
│   └── coverage/                   # Depth BAMs for MetaBAT2
├── binning/
│   └── metabat2/                   # Bins + unbinned contigs
├── bin_qc/
│   ├── quast/                      # Per-bin QUAST stats
│   └── drep/                       # dRep dereplicated HQ bins
├── annotation/
│   ├── prokka/                     # Gene annotation per bin
│   ├── cdhit/                      # Clustered proteins (all bins)
│   ├── eggnog/                     # Functional annotation (COG, GO)
│   ├── dbcan2/                     # CAZyme annotation
│   └── kofamscan/                  # KEGG KO annotation
├── plastizyme_prediction/
│   └── metatarenz/
│       ├── *_candidates.fasta      # Candidate plastizyme sequences
│       └── *_metatarenz.tsv        # MeTarENZ hit table
├── structure/
│   ├── cdsearch/                   # Conserved domain annotations
│   ├── alphafold2/                 # 3D structure predictions (.pdb)
│   └── tmalign/
│       └── *_tmalign_results.tsv   # TM-score & RMSD vs PETase reference
├── multiqc/
│   └── multiqc_report.html         # Aggregated QC report
└── pipeline_info/
    ├── execution_report_*.html
    ├── execution_timeline_*.html
    ├── execution_trace_*.txt
    └── pipeline_dag_*.html
```

---

## Pipeline stages in detail

### Stage 1 — QC & Preprocessing
Raw reads are quality-assessed with **FastQC**, trimmed and filtered with **fastp** (quality score ≥ 20, minimum length 50 bp). If `--host_genome` is provided, host/PhiX reads are removed using **Bowtie2**. A second FastQC run is performed on clean reads.

### Stage 2 — Taxonomic Profiling *(skippable)*
Community composition is profiled using **Kraken2** (k-mer classification) and **MetaPhlAn4** (species-level marker gene profiling). Runs in parallel with Stage 3.

### Stage 3 — Assembly & Annotation
Clean reads are assembled with **MEGAHIT** (default assembler, metagenomic mode). Assembly quality is evaluated with **QUAST**. Open reading frames are predicted with **Prodigal** (`-p meta`). Reads are mapped back to contigs using **Bowtie2** to generate coverage BAMs for binning.

### Stage 4 — Contig Binning
Coverage-based binning is performed with **MetaBAT2**, producing:
- **Bins** — contigs grouped into metagenome-assembled genomes (MAGs)
- **Unbinned/discarded** — contigs not assigned to any bin

### Stage 5 — Bin Quality Evaluation
Bin assemblies are assessed with **QUAST**. Redundant and low-quality bins are filtered with **dRep** using configurable completeness (`--min_completeness`, default 50%) and contamination (`--max_contamination`, default 10%) thresholds.

### Stage 6 — Bin Classification & Annotation *(skippable)*
High-quality bins are annotated with **Prokka** (gene prediction). All proteins are clustered with **CD-HIT** (95% identity) to remove redundancy. Taxonomic classification is performed with **GTDB-tk**. Functional annotation runs in parallel:
- **eggNOG-mapper** — COG, GO, KEGG functional categories
- **dbCAN2** — CAZyme annotation (carbohydrate-active enzymes)
- **KofamScan** — KEGG Orthology (KO) assignment

### Stage 7 — Plastizyme Prediction
This is the core stage. HQ bins and unbinned/discarded contigs from MetaBAT2 are **concatenated per sample** into a single FASTA query. **MeTarENZ** performs targeted homology search against the **PET_DB** (curated plastic-degrading enzyme sequences). Candidate plastizyme sequences are extracted based on MeTarENZ hits.

### Stage 8 — 3D Structure Prediction & Validation *(skippable)*
Candidate sequences undergo:
1. **CD-Search** (NCBI REST API) — conserved domain annotation to identify PETase-like motifs
2. **AlphaFold2** — 3D structure prediction (GPU recommended)
3. **TM-Align** — structural similarity comparison against the PETase reference (default: 6EQE, *Ideonella sakaiensis* IsPETase)

---

## Citation

If you use PlastizymeFinder in your research, please cite:

> Hongo et al. (2026). *PlastizymeFinder: a Nextflow pipeline for metagenomic discovery of plastic-degrading enzymes.* [GitHub](https://github.com/Bboy010/PlastizymeFinder)

Please also cite the tools used by the pipeline:

- **Nextflow** — Di Tommaso et al., *Nature Biotechnology*, 2017
- **FastQC** — Andrews S., 2010
- **fastp** — Chen et al., *Bioinformatics*, 2018
- **Bowtie2** — Langmead & Salzberg, *Nature Methods*, 2012
- **MEGAHIT** — Li et al., *Bioinformatics*, 2015
- **QUAST** — Gurevich et al., *Bioinformatics*, 2013
- **Prodigal** — Hyatt et al., *BMC Bioinformatics*, 2010
- **MetaBAT2** — Kang et al., *PeerJ*, 2019
- **dRep** — Olm et al., *ISME Journal*, 2017
- **Kraken2** — Wood et al., *Genome Biology*, 2019
- **MetaPhlAn4** — Blanco-Míguez et al., *Nature Methods*, 2023
- **GTDB-tk** — Chaumeil et al., *Bioinformatics*, 2019
- **Prokka** — Seemann, *Bioinformatics*, 2014
- **CD-HIT** — Li & Godzik, *Bioinformatics*, 2006
- **eggNOG-mapper** — Cantalapiedra et al., *Molecular Biology and Evolution*, 2021
- **dbCAN2** — Zhang et al., *Nucleic Acids Research*, 2018
- **KofamScan** — Aramaki et al., *Bioinformatics*, 2020
- **MeTarENZ** — Hongo et al., 2026
- **AlphaFold2** — Jumper et al., *Nature*, 2021
- **TM-Align** — Zhang & Skolnick, *Nucleic Acids Research*, 2005
- **MultiQC** — Ewels et al., *Bioinformatics*, 2016

---

## Contributing

Contributions and bug reports are welcome. Please open an issue or pull request on [GitHub](https://github.com/Bboy010/PlastizymeFinder/issues).

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
