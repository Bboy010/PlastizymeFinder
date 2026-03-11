/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: TAXONOMIC_PROFILING  (Stage 2)
    Kraken2 + Krona visualization + MetaPhlAn4
    Runs in parallel with assembly
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { KRAKEN2_KRAKEN2  } from '../../modules/nf-core/kraken2/kraken2/main'
include { METAPHLAN4       } from '../../modules/nf-core/metaphlan4/main'

workflow TAXONOMIC_PROFILING {

    take:
    reads         // channel: [ meta, [reads] ]
    kraken2_db    // channel: path to Kraken2 DB directory
    metaphlan4_db // channel: path to MetaPhlAn4 DB directory

    main:
    ch_versions = Channel.empty()

    // 2a. Kraken2 taxonomic classification
    KRAKEN2_KRAKEN2(
        reads,
        kraken2_db,
        false,   // save_output_fastqs
        true     // save_reads_assignment
    )
    ch_versions = ch_versions.mix(KRAKEN2_KRAKEN2.out.versions.first())

    // 2b. MetaPhlAn4 species-level profiling
    METAPHLAN4(reads, metaphlan4_db)
    ch_versions = ch_versions.mix(METAPHLAN4.out.versions.first())

    emit:
    kraken2_report  = KRAKEN2_KRAKEN2.out.report
    metaphlan4_profile = METAPHLAN4.out.profile
    versions        = ch_versions
}
