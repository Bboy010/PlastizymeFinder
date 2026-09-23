/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: ASSEMBLY_ANNOTATION  (Stage 3)
    MEGAHIT → QUAST → Prodigal (gene prediction) → Bowtie2 (coverage for binning)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { MEGAHIT               } from '../../modules/nf-core/megahit/main'
include { QUAST as QUAST_ASSEMBLY } from '../../modules/nf-core/quast/main'
include { PRODIGAL              } from '../../modules/nf-core/prodigal/main'
include { BOWTIE2_ALIGN as BOWTIE2_ALIGN_CONTIGS } from '../../modules/nf-core/bowtie2/align/main'
include { BOWTIE2_BUILD         } from '../../modules/nf-core/bowtie2/build/main'

workflow ASSEMBLY_ANNOTATION {

    take:
    reads   // channel: [ meta, [reads] ]

    main:
    def ch_versions = channel.empty()

    // 3a. De novo assembly with MEGAHIT
    MEGAHIT(reads)
    ch_versions = ch_versions.mix(MEGAHIT.out.versions.first())

    // A shallow or low-complexity sample can yield no contig above
    // --min-contig-len. That is a legitimate outcome, not a failure: drop the
    // sample here with a warning rather than let bowtie2-build die on an empty
    // FASTA and take the whole run with it. An empty gzip stream is ~20 bytes.
    ch_contigs = MEGAHIT.out.contigs
        .branch { _meta, fasta ->
            assembled: fasta.size() > 1024
            empty:     true
        }

    ch_contigs.empty.view { meta, _fasta ->
        "WARN: ${meta.id} produced no contig above the minimum length - " +
        "the sample is dropped from assembly-based stages"
    }

    // 3b. Assembly quality evaluation with QUAST
    QUAST_ASSEMBLY(ch_contigs.assembled, [], [])
    ch_versions = ch_versions.mix(QUAST_ASSEMBLY.out.versions.first())

    // 3c. Gene prediction with Prodigal (metagenomic mode)
    PRODIGAL(ch_contigs.assembled, 'gff')
    def ch_proteins = PRODIGAL.out.amino_acid_fasta
    ch_versions = ch_versions.mix(PRODIGAL.out.versions.first())

    // 3d. Index contigs and map reads back → coverage BAMs for MetaBAT2
    BOWTIE2_BUILD(ch_contigs.assembled)
    def ch_index = BOWTIE2_BUILD.out.index
    ch_versions = ch_versions.mix(BOWTIE2_BUILD.out.versions.first())

    // Ensure reads and index are matched by sample ID before alignment
    def ch_reads_for_align = reads
        .join(ch_index, by: 0)
        .map { meta, read_files, _index -> [meta, read_files] }

    BOWTIE2_ALIGN_CONTIGS(ch_reads_for_align, ch_index, true, true)
    ch_bam      = BOWTIE2_ALIGN_CONTIGS.out.bam
    ch_versions = ch_versions.mix(BOWTIE2_ALIGN_CONTIGS.out.versions.first())

    emit:
    contigs  = ch_contigs.assembled  // [ meta, contigs.fa ] → Binning
    bam      = ch_bam       // [ meta, sorted.bam ] → MetaBAT2 depth
    quast    = QUAST_ASSEMBLY.out.tsv   // [ meta, report.tsv ] → reporting
    proteins = ch_proteins  // [ meta, proteins.faa ] → fallback for Stage 7 if annotation skipped
    versions = ch_versions
}
