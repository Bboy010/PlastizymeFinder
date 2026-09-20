# Deviations from the published method

PlastizymeFinder formalises the method of Hongo *et al.* (2026),
[doi:10.1099/acmi.0.001231.v2](https://doi.org/10.1099/acmi.0.001231.v2), into a
single pipeline. The published analysis was not produced by this pipeline:
stages 1–6 were run with nf-core/mag v5.4.1 and stages 7–8 were carried out
separately. This file records where the pipeline deliberately departs from the
paper, and why.

The project's choice is to improve on the published method rather than
reproduce it exactly. Results from this pipeline are therefore expected to
differ from the paper's, and that difference is intentional.

## Deliberate improvements

| Step | Paper | Pipeline | Why |
|---|---|---|---|
| Conserved domains | NCBI CD-Search (web service) | RPS-BLAST against a local CDD | The web service cannot be cached, is rate-limited, requires sending sequences to NCBI, and makes a run irreproducible. **Bit scores are not identical**, so the 21-of-47 filter of the paper will not reproduce exactly. |
| Structure prediction | ColabFold, run by hand in a notebook | `COLABFOLD` module | Same tool, same MSA server; the manual step becomes part of the pipeline and is recorded in `versions.yml`. |
| Assembly to binning | nf-core/mag v5.4.1, run separately | Reimplemented as stages 1–6 | One pipeline end to end, with a stub path so the whole DAG can be tested without running a tool. |
| PET_DB | Supplied by hand | Fetched from the study's Zenodo DOI | `pet_cdhit95.faa`, 158 sequences, as published. Removes the last manual input. |

## Parameters taken from the paper

| Parameter | Value | Source |
|---|---|---|
| `metarenz_bitscore` | 250 | Methods 2.4.2 |
| `min_contig_len` | 1500 | Methods 2.3 (MetaBAT2 minimum) |
| `min_completeness` / `max_contamination` | 50 / 10 | Methods 2.3 (dRep + CheckM) |
| `metarenz_mode` | `cs` | Bins and unbinned contigs are screened, i.e. nucleotide input |
| TM-Align reference | PDB 6EQE | Methods 2.4.2 |

> **Note on the bit-score.** The manuscript states 250 in both Methods 2.4.2 and
> Results 3.4.1, while the response to reviewers describes an initial MeTarEnz
> screen at 50 followed by a filter at 250. The pipeline uses **250**, the value
> in the manuscript. The three statements should be reconciled before the next
> submission.

## Known gaps

- **DAS Tool** is not implemented. The paper lists its absence as a limitation;
  the pipeline inherits that limitation.
- **A single binner.** MetaBAT2 only, as in the paper. nf-core/mag runs several.
- **CheckM** runs inside dRep and needs its database; `--skip_drep_checkm`
  bypasses the quality filter entirely, which also disables
  `min_completeness` and `max_contamination`. Leave it off for any real run.
