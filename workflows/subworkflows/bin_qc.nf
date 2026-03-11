/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: BIN_QC  (Stage 5)
    QUAST (per-bin quality) → dRep (deduplication + completeness/contamination filter)
    Outputs only high-quality bins
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { QUAST as QUAST_BINS } from '../../modules/nf-core/quast/main'
include { DREP                } from '../../modules/nf-core/drep/main'

workflow BIN_QC {

    take:
    bins   // channel: [ meta, [ bin1.fa, bin2.fa, ... ] ]

    main:
    ch_versions = Channel.empty()

    // 5a. QUAST quality stats on each bin set
    QUAST_BINS(bins, [], [], false, false)
    ch_versions = ch_versions.mix(QUAST_BINS.out.versions.first())

    // 5b. dRep: dereplicate + filter by completeness/contamination thresholds
    //     Collects all bins across all samples for global dereplication
    ch_all_bins = bins
        .map { meta, bin_list -> bin_list }
        .flatten()
        .collect()

    DREP(ch_all_bins)
    ch_hq_bins  = DREP.out.dereplicated_genomes
    ch_versions = ch_versions.mix(DREP.out.versions)

    emit:
    passed_bins = ch_hq_bins  // → BIN_CLASSIFICATION + PLASTIZYME_PREDICTION
    quast_stats = QUAST_BINS.out.results
    versions    = ch_versions
}
