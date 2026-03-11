/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: BIN_CLASSIFICATION  (Stage 6)
    Prokka (annotation) → CD-Hit (clustering) → GTDB-tk (taxonomy)
    + eggNOG | dbCAN2 | kofamscan in parallel
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { PROKKA           } from '../../modules/nf-core/prokka/main'
include { CDHIT_CDHIT      } from '../../modules/nf-core/cdhit/cdhit/main'
include { GTDBTK_CLASSIFYWF } from '../../modules/nf-core/gtdbtk/classifywf/main'
include { EGGNOG_MAPPER    } from '../../modules/nf-core/eggnog/emapper/main'
include { DBCAN2           } from '../../modules/nf-core/dbcan2/main'
include { KOFAMSCAN        } from '../../modules/nf-core/kofamscan/main'

workflow BIN_CLASSIFICATION {

    take:
    hq_bins       // channel: path(s) to HQ bin FASTA files
    gtdbtk_db     // channel: path to GTDB-tk reference data
    eggnog_db     // channel: path to eggNOG database
    dbcan2_db     // channel: path to dbCAN2 database
    kofamscan_db  // channel: path to KofamScan profiles

    main:
    ch_versions = Channel.empty()

    // 6a. Prokka: gene prediction & annotation on each bin
    PROKKA(hq_bins, [], [])
    ch_faa      = PROKKA.out.faa    // protein FASTA
    ch_versions = ch_versions.mix(PROKKA.out.versions.first())

    // 6b. CD-Hit: cluster proteins (remove redundancy)
    //     Collect all proteins, cluster globally
    ch_all_proteins = ch_faa
        .map { meta, faa -> faa }
        .collectFile(name: 'all_proteins.faa')

    CDHIT_CDHIT(ch_all_proteins)
    ch_clustered = CDHIT_CDHIT.out.fasta
    ch_versions  = ch_versions.mix(CDHIT_CDHIT.out.versions)

    // 6c. GTDB-tk: phylogenomic taxonomy of bins
    GTDBTK_CLASSIFYWF(hq_bins, gtdbtk_db)
    ch_versions = ch_versions.mix(GTDBTK_CLASSIFYWF.out.versions.first())

    // 6d. Functional annotation — run in parallel
    EGGNOG_MAPPER(ch_clustered, eggnog_db)
    ch_versions = ch_versions.mix(EGGNOG_MAPPER.out.versions)

    DBCAN2(ch_clustered, dbcan2_db)
    ch_versions = ch_versions.mix(DBCAN2.out.versions)

    KOFAMSCAN(ch_clustered, kofamscan_db)
    ch_versions = ch_versions.mix(KOFAMSCAN.out.versions)

    emit:
    proteins       = ch_clustered                 // → PLASTIZYME_PREDICTION (Stage 7)
    taxonomy       = GTDBTK_CLASSIFYWF.out.summary
    eggnog_results = EGGNOG_MAPPER.out.annotations
    dbcan2_results = DBCAN2.out.results
    kegg_results   = KOFAMSCAN.out.mapper_results
    versions       = ch_versions
}
