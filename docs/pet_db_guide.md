# PET_DB Construction Guide

> **Note:** The PlastizymeFinder team provides a **default PET_DB** that can be downloaded from the
> [Releases page](https://github.com/Bboy010/PlastizymeFinder/releases). This guide is for users
> who wish to build or extend their own database.

## Overview

The PET_DB is a curated FASTA file containing amino acid sequences of plastic-degrading enzymes,
assembled from four primary sources through **manual literature research**.

## Sources

| Source   | URL | Content |
|----------|-----|---------|
| PAZy     | http://www.cbrc.kaust.edu.sa/pazy/ | Plastic-active enzymes |
| NCBI     | https://www.ncbi.nlm.nih.gov/protein/ | Protein sequences |
| BRENDA   | https://www.brenda-enzymes.org/ | Enzyme function data |
| UniProt  | https://www.uniprot.org/ | Reviewed protein entries |

## Step-by-Step Protocol

### 1. PAZy Database
- Visit http://www.cbrc.kaust.edu.sa/pazy/
- Download all sequences targeting PET, PLA, PUR, PE, PP degradation
- Export as FASTA

### 2. NCBI Protein Search
Search terms to use:
```
PETase OR "PET hydrolase" OR "polyethylene terephthalate hydrolase"
cutinase[Title] AND plastic[Title]
"plastic degrading" AND enzyme
```
- Filter: Reviewed entries, length 150–600 aa
- Download as FASTA

### 3. BRENDA
- Enzyme class: EC 3.1.1.101 (PET hydrolase)
- Download all sequences with confirmed PET activity

### 4. UniProt
```
keyword:"PET hydrolase" AND reviewed:yes
annotation:(type:activity "polyethylene terephthalate")
```
- Export reviewed (Swiss-Prot) entries as FASTA

## Post-Collection Processing

After collecting sequences:

```bash
# 1. Merge all FASTA files
cat pazy.fasta ncbi.fasta brenda.fasta uniprot.fasta > pet_db_raw.fasta

# 2. Rename headers to consistent format: >SOURCE|ACCESSION|DESCRIPTION
# (do manually or with a custom script)

# 3. Remove duplicates with CD-Hit
cd-hit -i pet_db_raw.fasta -o pet_db.fasta -c 0.90 -n 5 -M 0 -T 8

# 4. Verify
grep -c ">" pet_db.fasta
```

## FASTA Header Format

Use this format for consistency with MeTarENZ:
```
>SOURCE|ACCESSION|ORGANISM|ENZYME_NAME
```
Example:
```
>UniProt|A0A0K8P7Q7|Ideonella_sakaiensis|IsPETase
>NCBI|WP_191356907.1|Thermobifida_cellulosilytica|Tccut1
```

## Minimum Recommended Size

- At least **50 sequences** from diverse organisms
- Include both mesophilic (IsPETase) and thermophilic (LCC, ThermoPETase) variants
- Include FAST-PETase and other engineered variants if available

## Reference Structures for TM-Align

The pipeline uses these 4 PDB structures as structural references (bundled in `assets/petase_references/`):

| PDB ID | Enzyme | Organism |
|--------|--------|----------|
| 6EQD | IsPETase | *Ideonella sakaiensis* |
| 4EB0 | LCC | *Leaf-branch compost metagenome* |
| 6KY3 | ThermoPETase | Engineered |
| 7SH6 | FAST-PETase | Engineered |
