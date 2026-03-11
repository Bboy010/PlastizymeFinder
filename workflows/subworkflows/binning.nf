/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: BINNING  (Stage 4)
    MetaBAT2 → bins (FASTA per bin) + unbinned contigs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { METABAT2_METABAT2    } from '../../modules/nf-core/metabat2/metabat2/main'
include { METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS } from '../../modules/nf-core/metabat2/jgisummarizebamcontigdepths/main'

workflow BINNING {

    take:
    contigs  // channel: [ meta, contigs.fa ]
    bam      // channel: [ meta, sorted.bam ]

    main:
    ch_versions = Channel.empty()

    // 4a. Calculate contig depth from BAM
    METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS(bam)
    ch_depth    = METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS.out.depth
    ch_versions = ch_versions.mix(METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS.out.versions.first())

    // Join contigs with their depth files
    ch_contigs_depth = contigs
        .join(ch_depth, by: 0)
        .map { meta, contigs, depth -> [ meta, contigs, depth ] }

    // 4b. Bin contigs with MetaBAT2
    METABAT2_METABAT2(ch_contigs_depth)
    ch_bins     = METABAT2_METABAT2.out.bins     // [ meta, [ bin1.fa, bin2.fa, ... ] ]
    ch_unbinned = METABAT2_METABAT2.out.unbinned // [ meta, unbinned.fa ]
    ch_versions = ch_versions.mix(METABAT2_METABAT2.out.versions.first())

    emit:
    bins     = ch_bins      // → BIN_QC + PLASTIZYME_PREDICTION
    unbinned = ch_unbinned  // → PLASTIZYME_PREDICTION (Stage 7)
    versions = ch_versions
}
