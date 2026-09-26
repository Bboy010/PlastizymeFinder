/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: BINNING  (Stage 4)
    MetaBAT2 + MaxBin2 + CONCOCT → DAS Tool refinement → bins + unbinned contigs

    Same binners and refinement as nf-core/mag. With --refine_bins_dastool false
    only MetaBAT2 runs, which is the configuration of the study (Hongo et al.
    2026): MaxBin2 and CONCOCT bins are only ever used through DAS Tool.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { METABAT2                 } from '../../modules/nf-core/metabat2/main'
include { MAXBIN2                  } from '../../modules/nf-core/maxbin2/main'
include { GUNZIP as GUNZIP_CONTIGS } from '../../modules/nf-core/gunzip/main'
include { SAMTOOLS_INDEX           } from '../../modules/nf-core/samtools/index/main'
include { FASTA_BINNING_CONCOCT    } from '../../subworkflows/nf-core/fasta_binning_concoct/main'
include { CONTIG2BIN               } from '../../modules/local/contig2bin/main'
include { DASTOOL_DASTOOL          } from '../../modules/nf-core/dastool/dastool/main'
include { EXTRACT_UNBINNED         } from '../../modules/local/extract_unbinned/main'

workflow BINNING {

    take:
    contigs  // channel: [ meta, contigs.fa.gz ]
    bam      // channel: [ meta, sorted.bam ]

    main:
    def ch_versions = channel.empty()

    // Join contigs with their corresponding BAM by sample ID
    def ch_contigs_bam = contigs.join(bam, by: 0)

    // MetaBAT2: jgi_summarize_bam_contig_depths + metabat2 binning (handled in one module)
    METABAT2(
        ch_contigs_bam.map { meta, fasta, _bam -> [ meta, fasta ] },
        ch_contigs_bam.map { meta, _fasta, bam_file -> [ meta, bam_file  ] }
    )
    ch_versions = ch_versions.mix(METABAT2.out.versions.first())

    def ch_bins
    def ch_unbinned
    if (!params.refine_bins_dastool) {
        ch_bins     = METABAT2.out.bins     // [ meta, [ bin1.fa, bin2.fa, ... ] ]
        ch_unbinned = METABAT2.out.unbinned // [ meta, unbinned.fa ]
    } else {
        // One [ meta, [bins], binner ] entry per sample and binner, for DAS Tool.
        def ch_binner_bins = METABAT2.out.bins.map { meta, bins -> [ meta, bins, 'metabat2' ] }

        // MaxBin2 reuses MetaBAT2's coverage rather than mapping the reads again.
        if (!params.skip_maxbin2) {
            MAXBIN2(
                contigs.join(METABAT2.out.abundance, by: 0)
                    .map { meta, fasta, abund -> [ meta, fasta, [], abund ] }
            )
            ch_binner_bins = ch_binner_bins.mix(
                MAXBIN2.out.binned_fastas.map { meta, bins -> [ meta, bins, 'maxbin2' ] }
            )
        }

        // CONCOCT reads neither gzipped contigs nor an unindexed BAM.
        if (!params.skip_concoct) {
            GUNZIP_CONTIGS(contigs)
            SAMTOOLS_INDEX(bam)
            FASTA_BINNING_CONCOCT(
                GUNZIP_CONTIGS.out.gunzip,
                bam.join(SAMTOOLS_INDEX.out.index, by: 0)
            )
            ch_binner_bins = ch_binner_bins.mix(
                FASTA_BINNING_CONCOCT.out.bins.map { meta, bins -> [ meta, bins, 'concoct' ] }
            )
        }

        CONTIG2BIN(ch_binner_bins)
        ch_versions = ch_versions.mix(CONTIG2BIN.out.versions.first())

        // DAS Tool keeps, for each contig, the best-scoring bin across binners.
        DASTOOL_DASTOOL(
            contigs.join(
                CONTIG2BIN.out.tsv
                    .filter { _meta, tsv -> tsv.size() > 0 }
                    .groupTuple(by: 0),
                by: 0
            ).map { meta, fasta, tsvs -> [ meta, fasta, tsvs, [] ] },
            []
        )
        ch_bins = DASTOOL_DASTOOL.out.bins
            .map { meta, bins -> [ meta, bins instanceof List ? bins : [ bins ] ] }

        // A sample where DAS Tool keeps no bin still has its contigs screened:
        // the unbinned set is then the whole assembly.
        EXTRACT_UNBINNED(
            contigs.join(ch_bins, by: 0, remainder: true)
                .map { meta, fasta, bins -> [ meta, fasta, bins ?: [] ] }
        )
        ch_unbinned = EXTRACT_UNBINNED.out.unbinned
        ch_versions = ch_versions.mix(EXTRACT_UNBINNED.out.versions.first())
    }

    emit:
    bins     = ch_bins      // → BIN_QC + PLASTIZYME_PREDICTION
    unbinned = ch_unbinned  // → PLASTIZYME_PREDICTION (Stage 7)
    versions = ch_versions
}
