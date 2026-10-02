# PlastizymeFinder: Output

## Introduction

This document describes what the pipeline writes to `--outdir`. Directories of
a stage that did not run are absent: with `--contigs_input`, stages 1–4 ran
elsewhere; with `--candidates_fasta`, only stages 7 and 8 run.

```
results/
├── fastqc/  fastp/  host_removal/      Stage 1
├── taxonomy/                           Stages 2 and 6
├── assembly/                           Stage 3
├── binning/                            Stage 4 (and --contigs_input)
├── bin_qc/                             Stage 5
├── annotation/                         Stages 3 and 6
├── plastizyme_prediction/              Stage 7
├── structure/                          Stage 8
├── petase/                             Reference structure used in stage 8
├── figures/  multiqc/                  Reports
└── pipeline_info/                      Execution reports
```

## Stage 1 — Quality control

<details markdown="1">
<summary>Output files</summary>

- `fastqc/raw/`, `fastqc/trimmed/`: FastQC `*.html` report and `*.zip` data, before and after trimming.
- `fastp/`: `*.fastp.html` and `*.fastp.json` trimming reports, and the trimmed reads `*.fastq.gz`.
- `host_removal/`: Bowtie2 alignment and log, only with `--host_genome`.

</details>

## Stage 2 — Taxonomic profiling

<details markdown="1">
<summary>Output files</summary>

- `taxonomy/kraken2/`: `*.kraken2.report.txt`, the Kraken2 classification report.
- `taxonomy/metaphlan4/`: `*_profile.txt`, the MetaPhlAn4 profile.

</details>

## Stage 3 — Assembly and gene prediction

<details markdown="1">
<summary>Output files</summary>

- `assembly/`: `<sample>.contigs.fa.gz`, the MEGAHIT assembly, and its log.
- `assembly/quast/`: QUAST assembly statistics.
- `assembly/coverage/`: reads mapped back to the contigs (sorted BAM), used for binning.
- `annotation/prodigal/megahit/<sample>/`: Prodigal genes (`.gff`) and proteins (`.faa`).

</details>

## Stage 4 — Binning

<details markdown="1">
<summary>Output files</summary>

- `binning/metabat2/`: MetaBAT2 bins (`bins/<sample>.bin.<n>.fa`), contig depths (`*.depth.txt`, and `*.abund.txt` as given to MaxBin2) and the contigs MetaBAT2 left unbinned.
- `binning/maxbin2/`: MaxBin2 bins (`<sample>.maxbin2.<n>.fasta.gz`) and `*.summary`.
- `binning/concoct/`: CONCOCT bins (`<sample>.concoct/*.fa.gz`); `stats/` holds its coverage table and clustering.
- `binning/dastool/`: the DAS Tool refined bins (`<sample>_DASTool_bins/*.fa`), `*_DASTool_summary.tsv` (score, completeness and redundancy of each kept bin), `*_DASTool_contig2bin.tsv` and `*_allBins.eval`.
- `binning/unbinned/`: `<sample>.unbinned.fa`, every contig no refined bin claimed. Stage 7 screens it alongside every bin from this stage - all of them, not only the ones Stage 5 keeps.

</details>

With `refine_bins_dastool = false`, only `binning/metabat2/` is written, and its
unbinned contigs go to stage 7. With `--contigs_input`, only
`binning/unbinned/` is written.

## Stage 5 — Bin quality

<details markdown="1">
<summary>Output files</summary>

- `bin_qc/quast/`: QUAST statistics of every bin.
- `bin_qc/drep/drep_output/`: dRep's tables and figures; `dereplicated_genomes/` holds the bins that passed the completeness, contamination and length thresholds after dereplication across samples.

</details>

## Stage 6 — Bin annotation

<details markdown="1">
<summary>Output files</summary>

- `annotation/prokka/`: Prokka annotation of each high-quality bin.
- `annotation/cdhit/`: proteins of all bins, clustered at 95 % identity.
- `annotation/eggnog/`, `annotation/dbcan2/`, `annotation/kofamscan/`: functional annotation (COG/GO, CAZymes, KEGG orthologs).
- `taxonomy/gtdbtk/`: GTDB-Tk classification of the bins.

</details>

## Stage 7 — Plastizyme prediction

<details markdown="1">
<summary>Output files</summary>

- `plastizyme_prediction/metarenz/<sample>.metarenz.csv`: the MeTarEnz screening table, one row per hit above `--metarenz_bitscore` (query, translated or aligned sequence, PET_DB reference, bit score, e-value).
- `plastizyme_prediction/metarenz/<sample>.candidates.faa`: the candidate sequences, as protein FASTA.

</details>

This is the main result. A sample with no candidate still has a table, with
its header only.

## Stage 8 — Structure

<details markdown="1">
<summary>Output files</summary>

- `structure/cdsearch/`: conserved domains of each candidate (RPS-BLAST against CDD), `*.tsv`.
- `structure/colabfold/`: the best ColabFold model (`*.colabfold.pdb`) and its mean pLDDT (`*.plddt.tsv`).
- `structure/tmalign/<sample>.tmalign.tsv`: TM-score and RMSD of each model against the PETase reference (6EQE by default). A TM-score above 0.5 indicates the same fold.
- `petase/`: the reference structure used.

</details>

## Reports

<details markdown="1">
<summary>Output files</summary>

- `multiqc/multiqc_report.html`: MultiQC report of every stage it can parse, with the software versions of the run.
- `figures/`: figures of read QC, taxonomy, assembly and bins. Not produced with `--contigs_input` or `--candidates_fasta`.
- `pipeline_info/`: Nextflow execution report, timeline, trace and DAG.

</details>
