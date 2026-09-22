# Figures

The pipeline renders its figure set at the end of every run, into
`<outdir>/figures/`. Nothing here is committed: figures describe one dataset,
so shipping a stale set in the repository would misrepresent the next run.

## What is produced

| File | Content |
|---|---|
| `01_taxonomy_kraken2.png` | 15 most abundant species, with the unclassified fraction |
| `02_taxonomic_ranks.png` | How many taxa are resolved at each rank |
| `03_metaphlan_species.png` | MetaPhlAn4 relative abundance profile |
| `04_bin_similarity.png` | MASH similarity heatmap across bins |
| `05_bin_quality.png` | Bin size against contiguity |
| `06_assembly.png` | QUAST contig counts and cumulative length |
| `07_read_quality.png` | fastp metrics before and after filtering |
| `kraken2.krona.txt` | Krona input, ready for an ImportText step |

Every figure is optional: a skipped stage simply drops the figures that depend
on it, and the run continues.

## How it works

`PLOT_REPORT` (`modules/local/plotreport/`) runs `bin/plot_results.py` inside a
matplotlib container. The module reads pipeline **channels**, never the
published results directory, so the figures are reproducible and cacheable by
`-resume`. This mirrors `nf-core/proteinfold`, which drives its own
`GENERATE_REPORT` module from `bin/generate_report.py`.

## Regenerating from an existing results directory

The script also runs standalone against a finished run:

```bash
bin/plot_results.py results docs/figures
```

## The interactive Krona plot

`kraken2.krona.txt` still needs an ImportText step to become the sunburst.
Install the nf-core module rather than writing one:

```bash
nf-core modules install krona/ktimporttext
```

Ad hoc, without the pipeline:

```bash
docker run --rm -v "$PWD":/data -w /data \
    quay.io/biocontainers/krona:2.8.1--pl5321hdfd78af_1 \
    ktImportText -o krona.html results/figures/kraken2.krona.txt
```
