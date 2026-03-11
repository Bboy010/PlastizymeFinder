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
    ch_versions = Channel.empty()

    // 3a. De novo assembly with MEGAHIT
    MEGAHIT(reads)
    ch_contigs  = MEGAHIT.out.contigs
    ch_versions = ch_versions.mix(MEGAHIT.out.versions.first())

    // 3b. Assembly quality evaluation with QUAST
    QUAST_ASSEMBLY(ch_contigs, [], [], false, false)
    ch_versions = ch_versions.mix(QUAST_ASSEMBLY.out.versions.first())

    // 3c. Gene prediction with Prodigal (metagenomic mode)
    PRODIGAL(ch_contigs, 'gff')
    ch_proteins = PRODIGAL.out.amino_acid_fasta
    ch_versions = ch_versions.mix(PRODIGAL.out.versions.first())

    // 3d. Index contigs and map reads back → coverage BAMs for MetaBAT2
    BOWTIE2_BUILD(ch_contigs)
    ch_index = BOWTIE2_BUILD.out.index
    ch_versions = ch_versions.mix(BOWTIE2_BUILD.out.versions.first())

    // Join reads with their corresponding contig index by sample ID
    ch_reads_with_index = reads
        .join(ch_index, by: 0)
        .map { meta, reads, index -> [ meta, reads, index ] }

    BOWTIE2_ALIGN_CONTIGS(ch_reads_with_index, [], true, false)
    ch_bam      = BOWTIE2_ALIGN_CONTIGS.out.bam
    ch_versions = ch_versions.mix(BOWTIE2_ALIGN_CONTIGS.out.versions.first())

    emit:
    contigs  = ch_contigs   // [ meta, contigs.fa ] → Binning
    bam      = ch_bam       // [ meta, sorted.bam ] → MetaBAT2 depth
    proteins = ch_proteins  // [ meta, proteins.faa ] → fallback for Stage 7 if annotation skipped
    versions = ch_versions
}
