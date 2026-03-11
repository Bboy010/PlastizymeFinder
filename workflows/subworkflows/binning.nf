/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: BINNING  (Stage 4)
    MetaBAT2 → bins (FASTA per bin) + unbinned contigs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { METABAT2 } from '../../modules/nf-core/metabat2/main'

workflow BINNING {

    take:
    contigs  // channel: [ meta, contigs.fa.gz ]
    bam      // channel: [ meta, sorted.bam ]

    main:
    ch_versions = Channel.empty()

    // Join contigs with their corresponding BAM by sample ID
    ch_contigs_bam = contigs.join(bam, by: 0)

    // MetaBAT2: jgi_summarize_bam_contig_depths + metabat2 binning (handled in one module)
    METABAT2(
        ch_contigs_bam.map { meta, fasta, bam -> [ meta, fasta ] },
        ch_contigs_bam.map { meta, fasta, bam -> [ meta, bam  ] }
    )
    ch_bins     = METABAT2.out.bins     // [ meta, [ bin1.fa, bin2.fa, ... ] ]
    ch_unbinned = METABAT2.out.unbinned // [ meta, unbinned.fa ]
    ch_versions = ch_versions.mix(METABAT2.out.versions.first())

    emit:
    bins     = ch_bins      // → BIN_QC + PLASTIZYME_PREDICTION
    unbinned = ch_unbinned  // → PLASTIZYME_PREDICTION (Stage 7)
    versions = ch_versions
}
