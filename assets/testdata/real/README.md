# Real-data test subset

The first 100,000 read pairs of the two samples that the study found PET
hydrolases in, so the smoke test runs on the material the pipeline is meant to
work on:

| Sample | Site | Matrix | PET hydrolases reported |
|---|---|---|---|
| `Bietry_1` | Biétry bay, Ébrié lagoon | sediment | BietPETase1, 3, 4 |
| `Bietry_3` | Biétry bay, Ébrié lagoon | sediment | BietPETase2 |

Source: <https://doi.org/10.5281/zenodo.19146671> (BioProject PRJNA1444035).
R1 and R2 keep the order of the published files, so taking the same prefix from
each preserves pairing. 22 MB in total, against ~26 GB for the full deposit.

## What this subset is for

It runs the real tools on real reads in minutes rather than days. It is a smoke
test, not a reproduction, and it **cannot** recover the published enzymes: at
1/350th of the depth MEGAHIT assembles a handful of contigs and Prodigal calls
about fifteen proteins, while BietPETase1 came from contig `k141_499934` of a
MAG built from the whole sample. The code path is exercised end to end; the
biology is not.

## Testing the screening stage on known enzymes

Stage 7 is validated separately, against the four sequences the study published
(`Table_S4_BietPETase_sequences.fasta`). MeTarEnz in `ps` mode, with the
158-sequence PET_DB and a minimum bit-score of 250, recovers all four and
nothing else out of 204 sequences:

| Enzyme | Best PAZy match | Bit-score |
|---|---|---|
| BietPETase1 | `sp\|P19833\|LIP1_MORS1` | 426 |
| BietPETase2 | `sp\|P19833\|LIP1_MORS1` | 464 |
| BietPETase3 | `sp\|P19833\|LIP1_MORS1` | 443 |
| BietPETase4 | `sp\|P19833\|LIP1_MORS1` | 438 |

None of the 200 decoy proteins passed the threshold.

Reproducing the published results from reads needs the full deposit — see
`docs/usage.md`.
