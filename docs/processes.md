# Rapport des process - PlastizymeFinder

> Genere par `bin/gen_process_report.py` depuis les sources des modules et une
> execution reelle du pipeline. A regenerer apres toute modification des modules.

| Element | Valeur |
|---|---|
| Nextflow | 26.04.6 |
| Processus definis | 31 |
| Alias de processus | 6 |
| Modules locaux | 13 |
| Blocs stub | 31/31 |
| meta.yml | 6/31 |
| Suites tests/ | 3/31 |
| Processus executes | 33/33 termines |

## Processus executes

### Etape 0 - Bases de reference

| Process | Conteneur | Ressources | Sortie | Statut |
|---|---|---|---|---|
| `CDD_DB_DOWNLOAD` | `biocontainers/wget:1.21.4` | process_single | `non publie` | OK |
| `DBCAN2_DB_DOWNLOAD` | `quay.io/biocontainers/dbcan:4.0.0--pyhdfd78af_0` | process_single | `non publie` | OK |
| `EGGNOG_DB_DOWNLOAD` | `quay.io/biocontainers/eggnog-mapper:2.1.12--pyhdfd78af_0` | process_single | `non publie` | OK |
| `GTDBTK_DB_DOWNLOAD` | `quay.io/biocontainers/gtdbtk:2.4.0--pyhdfd78af_0` | process_single | `non publie` | OK |
| `KOFAMSCAN_DB_DOWNLOAD` | `quay.io/biocontainers/kofamscan:1.3.0--hdfd78af_2` | process_single | `non publie` | OK |
| `KRAKEN2_DB_DOWNLOAD` | `quay.io/biocontainers/kraken2:2.1.3--pl5321hdcf5f25_0` | process_single | `non publie` | OK |
| `METAPHLAN4_DB_DOWNLOAD` | `quay.io/biocontainers/metaphlan:4.1.0--pyhca03a8a_0` | process_single | `non publie` | OK |
| `PETASE_REF_DOWNLOAD` | `biocontainers/wget:1.21.4` | process_single | `results/petase` | OK |

### Etape 1 - Controle qualite

| Process | Conteneur | Ressources | Sortie | Statut |
|---|---|---|---|---|
| `FASTP` | `biocontainers/fastp:0.23.4--h5f740d0_0` | process_medium | `results/fastp` | OK |
| `FASTQC_RAW`<br><sub>alias de FASTQC</sub> | `biocontainers/fastqc:0.12.1--hdfd78af_0` | process_medium | `results/fastqc/raw` | OK |
| `FASTQC_TRIMMED`<br><sub>alias de FASTQC</sub> | `biocontainers/fastqc:0.12.1--hdfd78af_0` | process_medium | `results/fastqc/trimmed` | OK |

### Etape 2 - Profilage taxonomique

| Process | Conteneur | Ressources | Sortie | Statut |
|---|---|---|---|---|
| `KRAKEN2` | `docker://staphb/kraken2:2.1.3`<br><sub>surcharge config</sub> | process_high | `results/taxonomy/kraken2` | OK |
| `METAPHLAN4` | `biocontainers/metaphlan:4.1.0--pyhca03a8a_0` | process_high | `results/taxonomy/metaphlan4` | OK |

### Etape 3 - Assemblage et prediction de genes

| Process | Conteneur | Ressources | Sortie | Statut |
|---|---|---|---|---|
| `BOWTIE2_ALIGN_CONTIGS`<br><sub>alias de BOWTIE2_ALIGN</sub> | `docker://staphb/bowtie2:2.5.3`<br><sub>surcharge config</sub> | process_high | `results/assembly/coverage` | OK |
| `BOWTIE2_BUILD` | `docker://staphb/bowtie2:2.5.3`<br><sub>surcharge config</sub> | process_medium | `non publie` | OK |
| `MEGAHIT` | `biocontainers/megahit:1.2.9--h5b5514e_2` | process_high | `results/assembly` | OK |
| `PRODIGAL` | `biocontainers/prodigal:2.6.3--hec16e2b_5` | process_medium | `results/annotation/prodigal/${params.assembler}` | OK |
| `QUAST_ASSEMBLY`<br><sub>alias de QUAST</sub> | `biocontainers/quast:5.2.0--py39pl5321h2add14b_1` | process_medium | `results/assembly/quast` | OK |

### Etape 4 - Binning

| Process | Conteneur | Ressources | Sortie | Statut |
|---|---|---|---|---|
| `METABAT2` | `biocontainers/metabat2:2.17--h4da6f23_0` | process_high | `results/binning/metabat2` | OK |

### Etape 5 - QC des bins et dereplication

| Process | Conteneur | Ressources | Sortie | Statut |
|---|---|---|---|---|
| `DREP` | `biocontainers/drep:3.4.5--pyhdfd78af_0` | process_high | `results/bin_qc/drep` | OK |
| `QUAST_BINS`<br><sub>alias de QUAST</sub> | `biocontainers/quast:5.2.0--py39pl5321h2add14b_1` | process_medium | `results/bin_qc/quast` | OK |

### Etape 6 - Annotation fonctionnelle et taxonomique

| Process | Conteneur | Ressources | Sortie | Statut |
|---|---|---|---|---|
| `CDHIT` | `biocontainers/cd-hit:4.8.1--hdbdd923_2` | process_high | `results/annotation/cdhit` | OK |
| `DBCAN2` | `quay.io/biocontainers/dbcan:5.2.9--pyhdfd78af_0` | process_high | `results/annotation/dbcan2` | OK |
| `EGGNOG_MAPPER` | `biocontainers/eggnog-mapper:2.1.12--pyhdfd78af_0` | process_high | `results/annotation/eggnog` | OK |
| `GTDBTK_CLASSIFYWF` | `biocontainers/gtdbtk:2.4.0--pyhdfd78af_1` | process_high | `results/taxonomy/gtdbtk` | OK |
| `KOFAMSCAN` | `biocontainers/kofamscan:1.3.0--hdfd78af_2` | process_high | `results/annotation/kofamscan` | OK |
| `PROKKA` | `biocontainers/prokka:1.14.6--pl5321hdfd78af_4` | process_medium | `results/annotation/prokka` | OK |

### Etape 7 - Prediction de plastizymes

| Process | Conteneur | Ressources | Sortie | Statut |
|---|---|---|---|---|
| `METARENZ` | `plastizymefinder/metarenz:1.0` | process_medium | `results/plastizyme_prediction/metarenz` | OK |

### Etape 8 - Validation structurale

| Process | Conteneur | Ressources | Sortie | Statut |
|---|---|---|---|---|
| `ALPHAFOLD2` | `catgumag/alphafold:2.3.2` | process_high | `results/structure/alphafold2` | OK |
| `RPSBLAST` | `community.wave.seqera.io/library/blast:2.17.0--d4fb881691596759` | process_medium | `results/structure/cdsearch` | OK |
| `TMALIGN` | `quay.io/biocontainers/tmalign:20240303--hd63eeec_0` | process_low | `results/structure/tmalign` | OK |

### Etape 9 - Rapport

| Process | Conteneur | Ressources | Sortie | Statut |
|---|---|---|---|---|
| `MULTIQC` | `biocontainers/multiqc:1.21--pyhdfd78af_0` | process_single | `results/multiqc` | OK |
| `PLOT_REPORT` | `quay.io/biocontainers/matplotlib:3.5.1` | process_single | `results/figures` | OK |

## Inventaire des modules

| Module | Origine | Conteneur | Canaux emis | stub | meta.yml | tests |
|---|---|---|---|---|---|---|
| `ALPHAFOLD2` | local | `catgumag/alphafold:2.3.2` | `pdb`, `raw` | oui | oui | NON |
| `BOWTIE2_ALIGN` | copie nf-core | `biocontainers/mulled-v2-ac74a7f02cebcfcc07d8e8d1a750d2acf4f99599:f70b2a4d0353cdd6dc64edde26e0b8f6` | `bam`, `bai`, `log`, `fastq` | oui | NON | NON |
| `BOWTIE2_BUILD` | copie nf-core | `biocontainers/bowtie2:2.5.3--py310h8d7afc0_0` | `index` | oui | NON | NON |
| `CDD_DB_DOWNLOAD` | local | `biocontainers/wget:1.21.4` | `db` | oui | oui | NON |
| `CDHIT` | copie nf-core | `biocontainers/cd-hit:4.8.1--hdbdd923_2` | `fasta`, `clusters` | oui | NON | NON |
| `DBCAN2` | copie nf-core | `quay.io/biocontainers/dbcan:5.2.9--pyhdfd78af_0` | `overview`, `hmmer`, `diamond` | oui | NON | NON |
| `DBCAN2_DB_DOWNLOAD` | local | `quay.io/biocontainers/dbcan:4.0.0--pyhdfd78af_0` | `db` | oui | NON | NON |
| `DREP` | copie nf-core | `biocontainers/drep:3.4.5--pyhdfd78af_0` | `passed_bins`, `results` | oui | NON | NON |
| `EGGNOG_DB_DOWNLOAD` | local | `quay.io/biocontainers/eggnog-mapper:2.1.12--pyhdfd78af_0` | `db` | oui | NON | NON |
| `EGGNOG_MAPPER` | copie nf-core | `biocontainers/eggnog-mapper:2.1.12--pyhdfd78af_0` | `annotations`, `hits`, `orthologs` | oui | NON | NON |
| `FASTP` | copie nf-core | `biocontainers/fastp:0.23.4--h5f740d0_0` | `reads`, `json`, `html`, `log`, `reads_fail`, `reads_merged` | oui | NON | NON |
| `FASTQC` | copie nf-core | `biocontainers/fastqc:0.12.1--hdfd78af_0` | `html`, `zip` | oui | NON | NON |
| `GTDBTK_CLASSIFYWF` | copie nf-core | `biocontainers/gtdbtk:2.4.0--pyhdfd78af_1` | `results`, `summary`, `tree` | oui | NON | NON |
| `GTDBTK_DB_DOWNLOAD` | local | `quay.io/biocontainers/gtdbtk:2.4.0--pyhdfd78af_0` | `db` | oui | NON | NON |
| `KOFAMSCAN` | copie nf-core | `biocontainers/kofamscan:1.3.0--hdfd78af_2` | `hits` | oui | NON | NON |
| `KOFAMSCAN_DB_DOWNLOAD` | local | `quay.io/biocontainers/kofamscan:1.3.0--hdfd78af_2` | `db` | oui | NON | NON |
| `KRAKEN2` | copie nf-core | `biocontainers/mulled-v2-5799ab18b5fc678e5ddc5b14f99c9254caacacd7:d36906b073db2c9e71edd5a34e47ce56d95d8f74-0` | `classified_reads_fastq`, `unclassified_reads_fastq`, `classified_reads_assignment`, `report` | oui | NON | NON |
| `KRAKEN2_DB_DOWNLOAD` | local | `quay.io/biocontainers/kraken2:2.1.3--pl5321hdcf5f25_0` | `db` | oui | NON | NON |
| `MEGAHIT` | copie nf-core | `biocontainers/megahit:1.2.9--h5b5514e_2` | `contigs`, `log` | oui | NON | NON |
| `METABAT2` | copie nf-core | `biocontainers/metabat2:2.17--h4da6f23_0` | `bins`, `unbinned`, `depth` | oui | NON | NON |
| `METAPHLAN4` | copie nf-core | `biocontainers/metaphlan:4.1.0--pyhca03a8a_0` | `profile`, `bowtie2out` | oui | NON | NON |
| `METAPHLAN4_DB_DOWNLOAD` | local | `quay.io/biocontainers/metaphlan:4.1.0--pyhca03a8a_0` | `db` | oui | NON | NON |
| `METARENZ` | local | `plastizymefinder/metarenz:1.0` | `csv`, `candidates` | oui | oui | oui |
| `MULTIQC` | copie nf-core | `biocontainers/multiqc:1.21--pyhdfd78af_0` | `report`, `data`, `plots` | oui | NON | NON |
| `PETASE_REF_DOWNLOAD` | local | `biocontainers/wget:1.21.4` | `pdb` | oui | NON | NON |
| `PLOT_REPORT` | local | `quay.io/biocontainers/matplotlib:3.5.1` | `figures`, `krona_text` | oui | oui | NON |
| `PRODIGAL` | copie nf-core | `biocontainers/prodigal:2.6.3--hec16e2b_5` | `gene_annotations`, `amino_acid_fasta`, `nucleotide_fasta`, `all_gene_annotations` | oui | NON | NON |
| `PROKKA` | copie nf-core | `biocontainers/prokka:1.14.6--pl5321hdfd78af_4` | `gff`, `gbk`, `fna`, `faa`, `ffn`, `sqn`, `fsa`, `tbl`, `err`, `log`, `txt`, `tsv` | oui | NON | NON |
| `QUAST` | copie nf-core | `biocontainers/quast:5.2.0--py39pl5321h2add14b_1` | `results`, `tsv`, `html` | oui | NON | NON |
| `RPSBLAST` | local | `community.wave.seqera.io/library/blast:2.17.0--d4fb881691596759` | `hits` | oui | oui | oui |
| `TMALIGN` | local | `quay.io/biocontainers/tmalign:20240303--hd63eeec_0` | `results` | oui | oui | oui |
