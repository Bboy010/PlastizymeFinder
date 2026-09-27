# PlastizymeFinder: Usage

## Introduction

PlastizymeFinder finds candidate plastic-degrading enzymes (plastizymes) in
metagenomes and checks their predicted structure against a known PETase. It
has three entry points; choose the one that matches what you already have:

| You have | Entry point | Stages run |
|---|---|---|
| Raw reads (FASTQ) | `--input` | 1–8: QC, taxonomy, assembly, binning, bin QC, annotation, screening, structure |
| Assemblies, and optionally bins, from another pipeline (e.g. nf-core/mag) | `--contigs_input` | 5–8 (5 only if bins are given) |
| Candidate sequences (proteins or contigs) | `--candidates_fasta` | 7–8 |

Provide exactly one. Every entry point also needs `--pet_db`, the curated
database of plastic-degrading enzyme sequences that stage 7 screens against
(see [`pet_db_guide.md`](pet_db_guide.md)).

## Samplesheet input (`--input`)

A comma-separated file with a header row and one row per sample:

```csv title="samplesheet.csv"
sample,fastq_1,fastq_2
SOIL_A,/data/soil_a_R1.fastq.gz,/data/soil_a_R2.fastq.gz
COMPOST_C,/data/compost_c.fastq.gz,
```

| Column | Description |
|---|---|
| `sample` | Sample name. Must be unique; it prefixes every output file of that sample. |
| `fastq_1` | Forward (or single-end) reads, gzipped FASTQ. |
| `fastq_2` | Reverse reads. Leave empty for single-end data. |

Local paths and URLs (`https://`, `s3://`, …) are both accepted.

## Chained input (`--contigs_input`)

Stages 1–4 overlap with [nf-core/mag](https://nf-co.re/mag). If you run mag —
or want its assemblers and binners — run it first and pass its results here:

```csv title="contigs_input.csv"
sample,contigs,bins
SOIL_A,/results_mag/Assembly/MEGAHIT/MEGAHIT-SOIL_A.contigs.fa.gz,/results_mag/GenomeBinning/DASTool/bins/MEGAHIT-*-SOIL_A.*
COMPOST_C,/results_mag/Assembly/MEGAHIT/MEGAHIT-COMPOST_C.contigs.fa.gz,
```

| Column | Description |
|---|---|
| `sample` | Sample (or co-assembly group) name. |
| `contigs` | Assembly FASTA, gzipped or not. |
| `bins` | Optional. A directory or a glob of that sample's bin FASTAs (`.fa`, `.fasta`, `.fna`, gzipped or not). |

With bins, stage 5 re-applies this pipeline's CheckM2 + dRep thresholds, and
every contig no bin claimed is screened as unbinned. Without bins, every
contig of the assembly is screened.

`bin/mag2plastizyme.py` writes this sheet from a mag results directory:

```bash
nextflow run nf-core/mag -r 5.5.0 -profile docker --input mag_samplesheet.csv --outdir results_mag
bin/mag2plastizyme.py --mag_outdir results_mag --assembler MEGAHIT --binner DASTool > contigs_input.csv
nextflow run Bboy010/PlastizymeFinder -profile docker \
    --contigs_input contigs_input.csv --pet_db pet_db.fasta --outdir results
```

`--binner` is any folder under `GenomeBinning/` (`MetaBAT2`, `MaxBin2`,
`CONCOCT`, `DASTool`, …), or `none` for contigs only. mag writes DAS Tool bins
only with `--refine_bins_dastool`.

## Candidate sequences (`--candidates_fasta`)

```bash
nextflow run Bboy010/PlastizymeFinder -profile docker \
    --candidates_fasta my_sequences.fasta --metarenz_mode ps \
    --pet_db pet_db.fasta --outdir results
```

Use `--metarenz_mode ps` for proteins and the default `cs` for nucleotide
contigs.

## Running the pipeline

```bash
nextflow run Bboy010/PlastizymeFinder -profile docker \
    --input samplesheet.csv --pet_db pet_db.fasta --outdir results
```

This launches the pipeline with the `docker` configuration profile. Nextflow
writes to the current directory:

```
work/          # intermediate files, one directory per task
results/       # pipeline outputs, see output.md
.nextflow_log  # log of the run
```

Resume an interrupted run with `-resume`: completed tasks are taken from
`work/` instead of being run again.

### Parameters from a file

Parameters can be kept in a YAML or JSON file and passed with
`-params-file params.yaml`:

```yaml title="params.yaml"
input: 'samplesheet.csv'
pet_db: 'pet_db.fasta'
outdir: 'results'
refine_bins_dastool: false
```

Prefer this over the command line for any boolean set to `false`: since
Nextflow 25, `--refine_bins_dastool false` on the command line arrives as the
String `"false"`, which is truthy, so the option stays on.

### Binning

Stage 4 runs MetaBAT2, MaxBin2 (on MetaBAT2's depths) and CONCOCT, and DAS
Tool keeps the best non-redundant set across them — the binners and
refinement of nf-core/mag.

| Parameter | Default | Effect |
|---|---|---|
| `skip_maxbin2` | `false` | Leave MaxBin2 out of DAS Tool's input |
| `skip_concoct` | `false` | Leave CONCOCT out of DAS Tool's input |
| `refine_bins_dastool` | `true` | `false`: MetaBAT2 alone, the configuration of the study (Hongo *et al.* 2026) |
| `dastool_score_threshold` | `0.5` | Minimum DAS Tool score for a bin to be kept |

A sample where no bin reaches the DAS Tool threshold is not lost: all its
contigs go to stage 7 as unbinned. MaxBin2 stops on samples with too few
marker genes; it is then left out for that sample, as in nf-core/mag.

### Databases

Every reference database except the PET_DB is downloaded on first use into
`--db_cache_dir` and reused afterwards. To use copies already on your
machine, see [`local_databases.md`](local_databases.md).

## Profiles

| Profile | Description |
|---|---|
| `docker`, `singularity`, `conda` | Software packaging. `conda` cannot run stage 7: MeTarEnz has no Bioconda recipe. |
| `gpu` | Folds with ColabFold on the GPU: exposes the host GPUs and switches ColabFold to its authors' CUDA image (the Biocontainers one is CPU-only). Combine with an engine: `-profile docker,gpu`. About 10 min per 250-residue candidate on an RTX 2060, against ~6 h on CPU. |
| `test` | Minimal bundled dataset; a smoke test. |
| `test_all` | `test` with stage 8. |
| `test_mag` | The subsampled gut metagenome nf-core/mag tests on, binned with MetaBAT2, MaxBin2 and DAS Tool. |
| `test_chain_mag` | `--contigs_input` on nf-core/mag's test assemblies. |
| `test_real` | The two published samples, subsampled to 100k read pairs. |
| `local_dbs` | Points every database at a local copy. Put it after another profile. |

Profiles are applied in the order given; later ones override earlier ones.

## Custom configuration

### Resources

Every process has a resource label (`process_single`, `process_low`,
`process_medium`, `process_high`) defined in `conf/base.config`. Cap what any
task may request with `--max_cpus`, `--max_memory` and `--max_time`, or change
one process in a config file passed with `-c`:

```groovy title="custom.config"
process {
    withName: 'MEGAHIT' {
        cpus   = 16
        memory = 64.GB
    }
}
```

### Containers

Change the container of one process the same way:

```groovy
process {
    withName: 'METARENZ' {
        container = '<your-registry>/metarenz:1.0'
    }
}
```

MeTarEnz runs from `ghcr.io/bboy010/plastizymefinder-metarenz:1.0`, the
authors' image `mforooz/metarenz` with `procps` added: Nextflow needs `ps`
to collect task metrics and stops the task without it.

## Running in the background

Nextflow must keep running for the pipeline to progress. Launch it with
`screen`, `tmux`, or Nextflow's own `-bg` flag, which detaches it and writes
its output to `.nextflow.log`.
