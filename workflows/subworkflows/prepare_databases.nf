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
include { CDD_DB_DOWNLOAD        } from '../../modules/local/db_download/cdd_db/main'
include { CHECKM2_DB_DOWNLOAD    } from '../../modules/local/db_download/checkm2_db/main'

workflow PREPARE_DATABASES {

    main:
    def ch_versions = channel.empty()

    // A database that no enabled stage consumes is never fetched, so each
    // channel needs a defined empty default.
    def ch_kraken2_db    = channel.empty()
    def ch_metaphlan4_db = channel.empty()
    def ch_dbcan2_db     = channel.empty()
    def ch_eggnog_db     = channel.empty()
    def ch_kofamscan_db  = channel.empty()
    def ch_gtdbtk_db     = channel.empty()
    def ch_petase_ref    = channel.empty()
    def ch_cdd_db        = channel.empty()
    def ch_checkm2_db    = channel.empty()

    // -----------------------------------------------------------------------
    // Kraken2
    // -----------------------------------------------------------------------
    if (params.kraken2_db) {
        ch_kraken2_db = channel.fromPath(params.kraken2_db, type: 'dir', checkIfExists: true)
    } else {
        if (!params.skip_taxonomy) {
            // only fetched when the stage that uses it runs
            KRAKEN2_DB_DOWNLOAD(params.db_cache_dir)
            ch_kraken2_db = KRAKEN2_DB_DOWNLOAD.out.db
            ch_versions   = ch_versions.mix(KRAKEN2_DB_DOWNLOAD.out.versions)
        }
    }

    // -----------------------------------------------------------------------
    // MetaPhlAn4
    // -----------------------------------------------------------------------
    if (params.metaphlan4_db) {
        ch_metaphlan4_db = channel.fromPath(params.metaphlan4_db, type: 'dir', checkIfExists: true)
    } else {
        if (!params.skip_taxonomy) {
            // only fetched when the stage that uses it runs
            METAPHLAN4_DB_DOWNLOAD(params.db_cache_dir)
            ch_metaphlan4_db = METAPHLAN4_DB_DOWNLOAD.out.db
            ch_versions      = ch_versions.mix(METAPHLAN4_DB_DOWNLOAD.out.versions)
        }
    }

    // -----------------------------------------------------------------------
    // dbCAN2
    // -----------------------------------------------------------------------
    if (params.dbcan2_db) {
        ch_dbcan2_db = channel.fromPath(params.dbcan2_db, type: 'dir', checkIfExists: true)
    } else {
        if (!params.skip_annotation) {
            // only fetched when the stage that uses it runs
            DBCAN2_DB_DOWNLOAD(params.db_cache_dir)
            ch_dbcan2_db = DBCAN2_DB_DOWNLOAD.out.db
            ch_versions  = ch_versions.mix(DBCAN2_DB_DOWNLOAD.out.versions)
        }
    }

    // -----------------------------------------------------------------------
    // eggNOG
    // -----------------------------------------------------------------------
    if (params.eggnog_db) {
        ch_eggnog_db = channel.fromPath(params.eggnog_db, type: 'dir', checkIfExists: true)
    } else {
        if (!params.skip_annotation) {
            // only fetched when the stage that uses it runs
            EGGNOG_DB_DOWNLOAD(params.db_cache_dir)
            ch_eggnog_db = EGGNOG_DB_DOWNLOAD.out.db
            ch_versions  = ch_versions.mix(EGGNOG_DB_DOWNLOAD.out.versions)
        }
    }

    // -----------------------------------------------------------------------
    // KofamScan
    // -----------------------------------------------------------------------
    if (params.kofamscan_db) {
        ch_kofamscan_db = channel.fromPath(params.kofamscan_db, type: 'dir', checkIfExists: true)
    } else {
        if (!params.skip_annotation) {
            // only fetched when the stage that uses it runs
            KOFAMSCAN_DB_DOWNLOAD(params.db_cache_dir)
            ch_kofamscan_db = KOFAMSCAN_DB_DOWNLOAD.out.db
            ch_versions     = ch_versions.mix(KOFAMSCAN_DB_DOWNLOAD.out.versions)
        }
    }

    // -----------------------------------------------------------------------
    // GTDB-tk
    // -----------------------------------------------------------------------
    if (params.gtdbtk_db) {
        ch_gtdbtk_db = channel.fromPath(params.gtdbtk_db, type: 'dir', checkIfExists: true)
    } else {
        if (!params.skip_annotation) {
            // only fetched when the stage that uses it runs
            GTDBTK_DB_DOWNLOAD(params.db_cache_dir)
            ch_gtdbtk_db = GTDBTK_DB_DOWNLOAD.out.db
            ch_versions  = ch_versions.mix(GTDBTK_DB_DOWNLOAD.out.versions)
        }
    }

    // -----------------------------------------------------------------------
    // PETase reference PDB for TM-Align
    // -----------------------------------------------------------------------
    if (params.petase_ref) {
        ch_petase_ref = channel.fromPath(params.petase_ref, checkIfExists: true)
    } else {
        PETASE_REF_DOWNLOAD()
        ch_petase_ref = PETASE_REF_DOWNLOAD.out.pdb
        ch_versions   = ch_versions.mix(PETASE_REF_DOWNLOAD.out.versions)
    }

    // -----------------------------------------------------------------------
    // NCBI CDD — conserved-domain profiles for local RPS-BLAST (Stage 8)
    // -----------------------------------------------------------------------
    if (params.cdd_db) {
        ch_cdd_db = channel.fromPath(params.cdd_db, type: 'dir', checkIfExists: true)
    } else {
        if (!params.skip_structure && !params.skip_plastizyme) {
            // only fetched when the stage that uses it runs
            CDD_DB_DOWNLOAD(params.db_cache_dir, params.cdd_db_set)
            ch_cdd_db   = CDD_DB_DOWNLOAD.out.db
            ch_versions = ch_versions.mix(CDD_DB_DOWNLOAD.out.versions)
        }
    }

    // -----------------------------------------------------------------------
    // CheckM2 — completeness/contamination model for dRep's --genomeInfo
    // -----------------------------------------------------------------------
    if (params.checkm_db) {
        ch_checkm2_db = channel.fromPath(params.checkm_db, checkIfExists: true)
    } else {
        if (!params.skip_drep_checkm) {
            // only fetched when the stage that uses it runs
            CHECKM2_DB_DOWNLOAD(params.db_cache_dir)
            ch_checkm2_db = CHECKM2_DB_DOWNLOAD.out.db
            ch_versions   = ch_versions.mix(CHECKM2_DB_DOWNLOAD.out.versions)
        }
    }

    emit:
    kraken2_db    = ch_kraken2_db
    metaphlan4_db = ch_metaphlan4_db
    dbcan2_db     = ch_dbcan2_db
    eggnog_db     = ch_eggnog_db
    kofamscan_db  = ch_kofamscan_db
    gtdbtk_db     = ch_gtdbtk_db
    petase_ref    = ch_petase_ref
    cdd_db        = ch_cdd_db
    checkm2_db    = ch_checkm2_db
    versions      = ch_versions
}
