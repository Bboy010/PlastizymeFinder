# Running against local databases

The `local_dbs` profile points every stage at a database already present on
this machine, so no download module runs:

```bash
sudo mount -t drvfs E: /mnt/e            # once per WSL session
nextflow run main.nf -profile test_real,local_dbs,docker --outdir results
```

Put `local_dbs` **after** the other profile so its paths win.

## What each path is, and how it was checked

Every entry below was inspected for the marker files its tool refuses to start
without — not assumed from the directory name.

| Stage | Parameter | Path | Checked |
|---|---|---|---|
| 2 | `kraken2_db` | `/mnt/e/Bio-informatics/db/minikraken2` | `hash.k2d`, `opts.k2d`, `taxo.k2d` |
| 2 | `metaphlan4_db` | `/mnt/e/Bio-informatics/db/mpa_db` | `mpa_vJan25_CHOCOPhlAnSGB_202503` + `.bt2l` + `.pkl` |
| 4 | `checkm_db` | `/mnt/e/Bio-informatics/db/CheckM2_database/CheckM2_database/uniref100.KO.1.dmnd` | 3.08 GB, matches the checksum in `CONTENTS.json` (a second, 761 MB file sits one level up and is not the real database) |
| 5 | `gtdbtk_db` | `/mnt/e/Bio-informatics/db/release226` | `markers`, `pplacer`, `taxonomy`, `skani`, `msa` |
| 6 | `dbcan2_db` | `/mnt/e/Bio-informatics/db/db_can` | `CAZy.dmnd`, `dbCAN-HMMdb-V8.txt` + `.h3[fimp]` |
| 6 | `eggnog_db` | `~/eggnog_data` | `eggnog.db` (41 GB), `eggnog_proteins.dmnd` (9.3 GB) |
| 6 | `kofamscan_db` | `~/kofam_db` | `ko_list`, `profiles/` |
| 7 | `pet_db` | `~/test/metarenz_input/pet_cdhit95.faa` | 158 sequences, as published |
| 8 | `cdd_db` | `databases/cdd/cdd_db` | CDD 3.21, 8 `.rps` volumes, no empty file |

## Why dbCAN is pinned to 3.0.7

The local dbCAN database is the V8 layout: an hmmpress'd HMMdb plus a DIAMOND
database, and nothing else. dbCAN 4 and 5 abort before doing any work:

```
ERROR: No dbCAN_sub HMM database found.
```

They raise this whatever `--tools` is set to, so neither can annotate against
this database. dbCAN 3.0.7 reads it and produces `hmmer.out`, `diamond.out`
and `overview.txt` — verified on image `quay.io/biocontainers/dbcan:3.0.7--pyh5e36f6f_0`
with a two-sequence protein FASTA.

The download module is pinned to the same version, because dbCAN 3 is also the
last line whose container ships `hmmpress`.

## If the external drive is not mounted

`/mnt/e` exists as a directory even when nothing is mounted on it, and reports
`No such device` on access. Two consequences worth knowing:

- `~/kraken/kraken2_db` is a symlink into `/mnt/e` and is dead until the mount.
- A Docker bind mount of an unmounted `/mnt/e/...` path **succeeds**, creating
  the directory inside the Docker VM instead. Writes then go nowhere visible.
  Check `df -h /mnt/e` rather than trusting that a container started.
