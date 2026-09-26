# PlastizymeFinder: Citations

## The method

- Hongo *et al.* (2026), *Access Microbiology* — the study whose method PlastizymeFinder
  formalises (see [`docs/deviations.md`](docs/deviations.md)).
  [doi:10.1099/acmi.0.001231.v2](https://doi.org/10.1099/acmi.0.001231.v2)

## Pipeline frameworks

- [Nextflow](https://pubmed.ncbi.nlm.nih.gov/28398311/)

  > Di Tommaso P, Chatzou M, Floden EW, Barja PP, Palumbo E, Notredame C. Nextflow enables reproducible computational workflows. *Nat Biotechnol.* 2017;35(4):316-319. [doi:10.1038/nbt.3820](https://doi.org/10.1038/nbt.3820)

- [nf-core](https://pubmed.ncbi.nlm.nih.gov/32055031/) — modules and conventions reused throughout

  > Ewels PA, Peltzer A, Fillinger S, *et al.* The nf-core framework for community-curated bioinformatics pipelines. *Nat Biotechnol.* 2020;38(3):276-278. [doi:10.1038/s41587-020-0439-x](https://doi.org/10.1038/s41587-020-0439-x)

- [nf-core/mag](https://nf-co.re/mag) — the published analysis ran stages 1-6 with it; stage 4 follows its binners, and `--contigs_input` takes its output

  > Krakau S, Straub D, Gourlé H, Gabernet G, Nahnsen S. nf-core/mag: a best-practice pipeline for metagenome hybrid assembly and binning. *NAR Genom Bioinform.* 2022;4(1):lqac007. [doi:10.1093/nargab/lqac007](https://doi.org/10.1093/nargab/lqac007)

## Stage 1 — QC and preprocessing

- [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)

  > Andrews S. FastQC: a quality control tool for high throughput sequence data. 2010.

- [fastp](https://doi.org/10.1093/bioinformatics/bty560)

  > Chen S, Zhou Y, Chen Y, Gu J. fastp: an ultra-fast all-in-one FASTQ preprocessor. *Bioinformatics.* 2018;34(17):i884-i890. [doi:10.1093/bioinformatics/bty560](https://doi.org/10.1093/bioinformatics/bty560)

- [Bowtie2](https://doi.org/10.1038/nmeth.1923)

  > Langmead B, Salzberg SL. Fast gapped-read alignment with Bowtie 2. *Nat Methods.* 2012;9(4):357-359. [doi:10.1038/nmeth.1923](https://doi.org/10.1038/nmeth.1923)

## Stage 2 — Taxonomic profiling

- [Kraken2](https://doi.org/10.1186/s13059-019-1891-0)

  > Wood DE, Lu J, Langmead B. Improved metagenomic analysis with Kraken 2. *Genome Biol.* 2019;20(1):257. [doi:10.1186/s13059-019-1891-0](https://doi.org/10.1186/s13059-019-1891-0)

- [MetaPhlAn 4](https://doi.org/10.1038/s41587-023-01688-w)

  > Blanco-Míguez A, Beghini F, Cumbo F, *et al.* Extending and improving metagenomic taxonomic profiling with uncharacterized species using MetaPhlAn 4. *Nat Biotechnol.* 2023;41(11):1633-1644. [doi:10.1038/s41587-023-01688-w](https://doi.org/10.1038/s41587-023-01688-w)

## Stage 3 — Assembly and gene prediction

- [MEGAHIT](https://doi.org/10.1093/bioinformatics/btv033)

  > Li D, Liu CM, Luo R, Sadakane K, Lam TW. MEGAHIT: an ultra-fast single-node solution for large and complex metagenomics assembly via succinct de Bruijn graph. *Bioinformatics.* 2015;31(10):1674-1676. [doi:10.1093/bioinformatics/btv033](https://doi.org/10.1093/bioinformatics/btv033)

- [QUAST](https://doi.org/10.1093/bioinformatics/btt086)

  > Gurevich A, Saveliev V, Vyahhi N, Tesler G. QUAST: quality assessment tool for genome assemblies. *Bioinformatics.* 2013;29(8):1072-1075. [doi:10.1093/bioinformatics/btt086](https://doi.org/10.1093/bioinformatics/btt086)

- [Prodigal](https://doi.org/10.1186/1471-2105-11-119)

  > Hyatt D, Chen GL, LoCascio PF, Land ML, Larimer FW, Hauser LJ. Prodigal: prokaryotic gene recognition and translation initiation site identification. *BMC Bioinformatics.* 2010;11:119. [doi:10.1186/1471-2105-11-119](https://doi.org/10.1186/1471-2105-11-119)

- [SAMtools](https://doi.org/10.1093/gigascience/giab008)

  > Danecek P, Bonfield JK, Liddle J, *et al.* Twelve years of SAMtools and BCFtools. *GigaScience.* 2021;10(2):giab008. [doi:10.1093/gigascience/giab008](https://doi.org/10.1093/gigascience/giab008)

## Stage 4 — Binning

- [MetaBAT2](https://doi.org/10.7717/peerj.7359)

  > Kang DD, Li F, Kirton E, *et al.* MetaBAT 2: an adaptive binning algorithm for robust and efficient genome reconstruction from metagenome assemblies. *PeerJ.* 2019;7:e7359. [doi:10.7717/peerj.7359](https://doi.org/10.7717/peerj.7359)

- [MaxBin2](https://doi.org/10.1093/bioinformatics/btv638)

  > Wu YW, Simmons BA, Singer SW. MaxBin 2.0: an automated binning algorithm to recover genomes from multiple metagenomic datasets. *Bioinformatics.* 2016;32(4):605-607. [doi:10.1093/bioinformatics/btv638](https://doi.org/10.1093/bioinformatics/btv638)

- [CONCOCT](https://doi.org/10.1038/nmeth.3103)

  > Alneberg J, Bjarnason BS, de Bruijn I, *et al.* Binning metagenomic contigs by coverage and composition. *Nat Methods.* 2014;11(11):1144-1146. [doi:10.1038/nmeth.3103](https://doi.org/10.1038/nmeth.3103)

- [DAS Tool](https://doi.org/10.1038/s41564-018-0171-1)

  > Sieber CMK, Probst AJ, Sharrar A, *et al.* Recovery of genomes from metagenomes via a dereplication, aggregation and scoring strategy. *Nat Microbiol.* 2018;3(7):836-843. [doi:10.1038/s41564-018-0171-1](https://doi.org/10.1038/s41564-018-0171-1)

## Stage 5 — Bin quality

- [CheckM2](https://doi.org/10.1038/s41592-023-01940-w)

  > Chklovski A, Parks DH, Woodcroft BJ, Tyson GW. CheckM2: a rapid, scalable and accurate tool for assessing microbial genome quality using machine learning. *Nat Methods.* 2023;20(8):1203-1212. [doi:10.1038/s41592-023-01940-w](https://doi.org/10.1038/s41592-023-01940-w)

- [dRep](https://doi.org/10.1038/ismej.2017.126)

  > Olm MR, Brown CT, Brooks B, Banfield JF. dRep: a tool for fast and accurate genomic comparisons that enables improved genome recovery from metagenomes through de-replication. *ISME J.* 2017;11(12):2864-2868. [doi:10.1038/ismej.2017.126](https://doi.org/10.1038/ismej.2017.126)

## Stage 6 — Bin classification and annotation

- [GTDB-Tk](https://doi.org/10.1093/bioinformatics/btz848)

  > Chaumeil PA, Mussig AJ, Hugenholtz P, Parks DH. GTDB-Tk: a toolkit to classify genomes with the Genome Taxonomy Database. *Bioinformatics.* 2020;36(6):1925-1927. [doi:10.1093/bioinformatics/btz848](https://doi.org/10.1093/bioinformatics/btz848)

- [Prokka](https://doi.org/10.1093/bioinformatics/btu153)

  > Seemann T. Prokka: rapid prokaryotic genome annotation. *Bioinformatics.* 2014;30(14):2068-2069. [doi:10.1093/bioinformatics/btu153](https://doi.org/10.1093/bioinformatics/btu153)

- [CD-HIT](https://doi.org/10.1093/bioinformatics/btl158)

  > Li W, Godzik A. Cd-hit: a fast program for clustering and comparing large sets of protein or nucleotide sequences. *Bioinformatics.* 2006;22(13):1658-1659. [doi:10.1093/bioinformatics/btl158](https://doi.org/10.1093/bioinformatics/btl158)

- [eggNOG-mapper](https://doi.org/10.1093/molbev/msab293)

  > Cantalapiedra CP, Hernández-Plaza A, Letunic I, Bork P, Huerta-Cepas J. eggNOG-mapper v2: functional annotation, orthology assignments, and domain prediction at the metagenomic scale. *Mol Biol Evol.* 2021;38(12):5825-5829. [doi:10.1093/molbev/msab293](https://doi.org/10.1093/molbev/msab293)

- [dbCAN2](https://doi.org/10.1093/nar/gky418)

  > Zhang H, Yohe T, Huang L, *et al.* dbCAN2: a meta server for automated carbohydrate-active enzyme annotation. *Nucleic Acids Res.* 2018;46(W1):W95-W101. [doi:10.1093/nar/gky418](https://doi.org/10.1093/nar/gky418)

- [KofamScan](https://doi.org/10.1093/bioinformatics/btz859)

  > Aramaki T, Blanc-Mathieu R, Endo H, *et al.* KofamKOALA: KEGG Ortholog assignment based on profile HMM and adaptive score threshold. *Bioinformatics.* 2020;36(7):2251-2252. [doi:10.1093/bioinformatics/btz859](https://doi.org/10.1093/bioinformatics/btz859)

## Stage 7 — Plastizyme prediction

- [MeTarEnz](https://github.com/mehdiforoozandeh/MeTarEnz) — a published third-party tool, run unmodified from its authors' Docker image (`mforooz/metarenz`, with `procps` added so Nextflow can collect task metrics)

  > Foroozandeh Shahraki M, *et al.* MeTarEnz: a metagenomic targeted enzyme miner. *Nat Prod Bioprospect.* 2024. [doi:10.1007/s13659-023-00426-8](https://doi.org/10.1007/s13659-023-00426-8)

- [BLAST+](https://doi.org/10.1186/1471-2105-10-421) — bundled in the MeTarEnz image, and RPS-BLAST in stage 8

  > Camacho C, Coulouris G, Avagyan V, *et al.* BLAST+: architecture and applications. *BMC Bioinformatics.* 2009;10:421. [doi:10.1186/1471-2105-10-421](https://doi.org/10.1186/1471-2105-10-421)

## Stage 8 — Structure prediction

- [CDD](https://doi.org/10.1093/nar/gkac1096) — profiles searched by RPS-BLAST

  > Wang J, Chitsaz F, Derbyshire MK, *et al.* The conserved domain database in 2023. *Nucleic Acids Res.* 2023;51(D1):D384-D388. [doi:10.1093/nar/gkac1096](https://doi.org/10.1093/nar/gkac1096)

- [ColabFold](https://doi.org/10.1038/s41592-022-01488-1)

  > Mirdita M, Schütze K, Moriwaki Y, Heo L, Ovchinnikov S, Steinegger M. ColabFold: making protein folding accessible to all. *Nat Methods.* 2022;19(6):679-682. [doi:10.1038/s41592-022-01488-1](https://doi.org/10.1038/s41592-022-01488-1)

- [AlphaFold2](https://doi.org/10.1038/s41586-021-03819-2) — the model ColabFold runs

  > Jumper J, Evans R, Pritzel A, *et al.* Highly accurate protein structure prediction with AlphaFold. *Nature.* 2021;596(7873):583-589. [doi:10.1038/s41586-021-03819-2](https://doi.org/10.1038/s41586-021-03819-2)

- [TM-align](https://doi.org/10.1093/nar/gki524)

  > Zhang Y, Skolnick J. TM-align: a protein structure alignment algorithm based on the TM-score. *Nucleic Acids Res.* 2005;33(7):2302-2309. [doi:10.1093/nar/gki524](https://doi.org/10.1093/nar/gki524)

## Reporting

- [MultiQC](https://doi.org/10.1093/bioinformatics/btw354)

  > Ewels P, Magnusson M, Lundin S, Käller M. MultiQC: summarize analysis results for multiple tools and samples in a single report. *Bioinformatics.* 2016;32(19):3047-3048. [doi:10.1093/bioinformatics/btw354](https://doi.org/10.1093/bioinformatics/btw354)

## Software packaging and containerisation

- [Bioconda](https://doi.org/10.1038/s41592-018-0046-7)

  > Grüning B, Dale R, Sjödin A, *et al.* Bioconda: sustainable and comprehensive software distribution for the life sciences. *Nat Methods.* 2018;15(7):475-476. [doi:10.1038/s41592-018-0046-7](https://doi.org/10.1038/s41592-018-0046-7)

- [BioContainers](https://doi.org/10.1093/bioinformatics/btx192)

  > da Veiga Leprevost F, Grüning BA, Alves Aflitos S, *et al.* BioContainers: an open-source and community-driven framework for software standardization. *Bioinformatics.* 2017;33(16):2580-2582. [doi:10.1093/bioinformatics/btx192](https://doi.org/10.1093/bioinformatics/btx192)

- [Docker](https://dl.acm.org/doi/10.5555/2600239.2600241)

  > Merkel D. Docker: lightweight Linux containers for consistent development and deployment. *Linux J.* 2014;2014(239):2.

- [Singularity](https://doi.org/10.1371/journal.pone.0177459)

  > Kurtzer GM, Sochat V, Bauer MW. Singularity: scientific containers for mobility of compute. *PLoS One.* 2017;12(5):e0177459. [doi:10.1371/journal.pone.0177459](https://doi.org/10.1371/journal.pone.0177459)
