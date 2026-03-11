/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: PREPARE_DATABASES
    Resolves all database paths — uses user-provided paths or triggers auto-download
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { KRAKEN2_DB_DOWNLOAD    } from '../../modules/local/db_download/kraken2_db/main'
include { METAPHLAN4_DB_DOWNLOAD } from '../../modules/local/db_download/metaphlan4_db/main'
include { DBCAN2_DB_DOWNLOAD     } from '../../modules/local/db_download/dbcan2_db/main'
include { EGGNOG_DB_DOWNLOAD     } from '../../modules/local/db_download/eggnog_db/main'
include { KOFAMSCAN_DB_DOWNLOAD  } from '../../modules/local/db_download/kofamscan_db/main'
include { GTDBTK_DB_DOWNLOAD     } from '../../modules/local/db_download/gtdbtk_db/main'
include { PETASE_REF_DOWNLOAD    } from '../../modules/local/db_download/petase_ref/main'

workflow PREPARE_DATABASES {

    main:
    ch_versions = Channel.empty()

    // -----------------------------------------------------------------------
    // Kraken2
    // -----------------------------------------------------------------------
    if (params.kraken2_db) {
        ch_kraken2_db = Channel.fromPath(params.kraken2_db, type: 'dir', checkIfExists: true)
    } else {
        KRAKEN2_DB_DOWNLOAD(params.db_cache_dir)
        ch_kraken2_db = KRAKEN2_DB_DOWNLOAD.out.db
        ch_versions   = ch_versions.mix(KRAKEN2_DB_DOWNLOAD.out.versions)
    }

    // -----------------------------------------------------------------------
    // MetaPhlAn4
    // -----------------------------------------------------------------------
    if (params.metaphlan4_db) {
        ch_metaphlan4_db = Channel.fromPath(params.metaphlan4_db, type: 'dir', checkIfExists: true)
    } else {
        METAPHLAN4_DB_DOWNLOAD(params.db_cache_dir)
        ch_metaphlan4_db = METAPHLAN4_DB_DOWNLOAD.out.db
        ch_versions      = ch_versions.mix(METAPHLAN4_DB_DOWNLOAD.out.versions)
    }

    // -----------------------------------------------------------------------
    // dbCAN2
    // -----------------------------------------------------------------------
    if (params.dbcan2_db) {
        ch_dbcan2_db = Channel.fromPath(params.dbcan2_db, type: 'dir', checkIfExists: true)
    } else {
        DBCAN2_DB_DOWNLOAD(params.db_cache_dir)
        ch_dbcan2_db = DBCAN2_DB_DOWNLOAD.out.db
        ch_versions  = ch_versions.mix(DBCAN2_DB_DOWNLOAD.out.versions)
    }

    // -----------------------------------------------------------------------
    // eggNOG
    // -----------------------------------------------------------------------
    if (params.eggnog_db) {
        ch_eggnog_db = Channel.fromPath(params.eggnog_db, type: 'dir', checkIfExists: true)
    } else {
        EGGNOG_DB_DOWNLOAD(params.db_cache_dir)
        ch_eggnog_db = EGGNOG_DB_DOWNLOAD.out.db
        ch_versions  = ch_versions.mix(EGGNOG_DB_DOWNLOAD.out.versions)
    }

    // -----------------------------------------------------------------------
    // KofamScan
    // -----------------------------------------------------------------------
    if (params.kofamscan_db) {
        ch_kofamscan_db = Channel.fromPath(params.kofamscan_db, type: 'dir', checkIfExists: true)
    } else {
        KOFAMSCAN_DB_DOWNLOAD(params.db_cache_dir)
        ch_kofamscan_db = KOFAMSCAN_DB_DOWNLOAD.out.db
        ch_versions     = ch_versions.mix(KOFAMSCAN_DB_DOWNLOAD.out.versions)
    }

    // -----------------------------------------------------------------------
    // GTDB-tk
    // -----------------------------------------------------------------------
    if (params.gtdbtk_db) {
        ch_gtdbtk_db = Channel.fromPath(params.gtdbtk_db, type: 'dir', checkIfExists: true)
    } else {
        GTDBTK_DB_DOWNLOAD(params.db_cache_dir)
        ch_gtdbtk_db = GTDBTK_DB_DOWNLOAD.out.db
        ch_versions  = ch_versions.mix(GTDBTK_DB_DOWNLOAD.out.versions)
    }

    // -----------------------------------------------------------------------
    // PETase reference PDB for TM-Align
    // -----------------------------------------------------------------------
    if (params.petase_ref) {
        ch_petase_ref = Channel.fromPath(params.petase_ref, checkIfExists: true)
    } else {
        PETASE_REF_DOWNLOAD()
        ch_petase_ref = PETASE_REF_DOWNLOAD.out.pdb
        ch_versions   = ch_versions.mix(PETASE_REF_DOWNLOAD.out.versions)
    }

    emit:
    kraken2_db    = ch_kraken2_db
    metaphlan4_db = ch_metaphlan4_db
    dbcan2_db     = ch_dbcan2_db
    eggnog_db     = ch_eggnog_db
    kofamscan_db  = ch_kofamscan_db
    gtdbtk_db     = ch_gtdbtk_db
    petase_ref    = ch_petase_ref
    versions      = ch_versions
}
