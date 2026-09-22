/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: BIN_QC  (Stage 5)
    QUAST (per-bin quality) → CheckM2 (completeness/contamination) →
    dRep (deduplication + quality filter, per the study's thresholds)
    Outputs only high-quality bins
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { QUAST as QUAST_BINS } from '../../modules/nf-core/quast/main'
include { CHECKM2             } from '../../modules/local/checkm2/main'
include { DREP                } from '../../modules/nf-core/drep/main'

workflow BIN_QC {

    take:
    bins        // channel: [ meta, [ bin1.fa, bin2.fa, ... ] ]
    checkm2_db  // channel: path — CheckM2 DIAMOND database, or [] to skip quality filtering

    main:
    def ch_versions = channel.empty()

    // 5a. QUAST quality stats on each bin set
    QUAST_BINS(bins, [], [])
    ch_versions = ch_versions.mix(QUAST_BINS.out.versions.first())

    // Collects all bins across all samples under a single dummy meta, since
    // dRep dereplicates globally rather than per sample.
    def ch_all_bins = bins
        .map { _meta, bin_list -> bin_list }
        .flatten()
        .collect()
        .map { bin_list -> [ [ id: 'all_samples' ], bin_list ] }

    // 5b. CheckM2: completeness/contamination, reshaped for dRep's --genomeInfo.
    //     Gated on the param rather than the channel: an empty channel object
    //     is still truthy in Groovy, so `if (checkm2_db)` would always run.
    //     Without a database, dRep falls back to filtering on size and ANI
    //     alone - the study's completeness/contamination thresholds are then
    //     not the ones enforced, so this path exists but is not the default.
    def ch_genome_info = channel.value([])
    if (!params.skip_drep_checkm) {
        CHECKM2(ch_all_bins, checkm2_db)
        ch_genome_info = CHECKM2.out.genome_info.map { _meta, csv -> csv }
        ch_versions    = ch_versions.mix(CHECKM2.out.versions)
    }

    // 5c. dRep: dereplicate + filter by completeness/contamination thresholds
    DREP(ch_all_bins, ch_genome_info)
    ch_hq_bins  = DREP.out.passed_bins
    ch_versions = ch_versions.mix(DREP.out.versions)

    emit:
    passed_bins = ch_hq_bins       // → BIN_CLASSIFICATION + PLASTIZYME_PREDICTION
    quast_stats = QUAST_BINS.out.results
    drep_tables = DREP.out.results       // [ meta, drep_output/ ] → reporting
    versions    = ch_versions
}
