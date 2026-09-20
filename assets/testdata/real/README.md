# Real-data test subset

The first 100,000 read pairs of two of the five samples published with
Hongo *et al.* (2026), one per site and both sediment, so the two-site design of
the study is represented:

| Sample | Site | Matrix |
|---|---|---|
| `Bietry_1` | Biétry bay, Ébrié lagoon | sediment |
| `Kassembie_1` | Kassembié lake | sediment |

Source: <https://doi.org/10.5281/zenodo.19146671> (BioProject PRJNA1444035).
R1 and R2 keep the order of the published files, so taking the same prefix from
each preserves pairing. 23 MB in total, against ~26 GB for the full deposit.

## What this subset is for

It runs the real tools on real reads in minutes rather than days. It is a smoke
test, not a reproduction: at this depth MEGAHIT recovers only a handful of
contigs above 1,500 bp, so MetaBAT2 produces no bin and stage 7 screens the
unbinned contigs instead. The code path is exercised end to end; the biology is
not.

Reproducing the published results needs the full deposit — see
`docs/usage.md`.

## Regenerating it

```bash
for s in Bietry_1 Kassembie_1; do
  for r in R1 R2; do
    curl -sL "https://zenodo.org/records/19146671/files/${s}_${r}.fastq.gz?download=1" \
      | zcat | head -n 400000 | gzip -c > "${s}_${r}.fastq.gz"
  done
done
```
