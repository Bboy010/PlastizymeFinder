/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: BIN_CLASSIFICATION  (Stage 6)
    Prokka (annotation) → CD-Hit (clustering) → GTDB-tk (taxonomy)
    + eggNOG | dbCAN2 | kofamscan in parallel
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { PROKKA            } from '../../modules/nf-core/prokka/main'
include { CDHIT             } from '../../modules/nf-core/cdhit/main'
include { GTDBTK_CLASSIFYWF } from '../../modules/nf-core/gtdbtk/main'
include { EGGNOG_MAPPER     } from '../../modules/nf-core/eggnog/emapper/main'
include { DBCAN2            } from '../../modules/nf-core/dbcan2/main'
include { KOFAMSCAN         } from '../../modules/nf-core/kofamscan/main'

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
    PROKKA(hq_bins, [], [], [], [], [])
    ch_faa      = PROKKA.out.faa    // protein FASTA
    ch_versions = ch_versions.mix(PROKKA.out.versions.first())

    // 6b. CD-Hit: cluster proteins (remove redundancy)
    //     Collect all proteins across bins, cluster globally under a single meta
    ch_all_proteins = ch_faa
        .map { meta, faa -> faa }
        .collect()
        .map { faas ->
            def merged_meta = [ id: 'all_bins' ]
            [ merged_meta, faas ]
        }
        .flatMap { meta, faas ->
            // Merge all FAA files into one for CD-HIT
            [ [ meta, faas.flatten() ] ]
        }

    CDHIT(ch_all_proteins)
    ch_clustered = CDHIT.out.fasta
    ch_versions  = ch_versions.mix(CDHIT.out.versions)

    // 6c. GTDB-tk: phylogenomic taxonomy of bins
    GTDBTK_CLASSIFYWF(hq_bins, gtdbtk_db)
    ch_versions = ch_versions.mix(GTDBTK_CLASSIFYWF.out.versions.first())

    // 6d. Functional annotation — run in parallel on clustered proteins
    EGGNOG_MAPPER(ch_clustered, eggnog_db, 'proteins')
    ch_versions = ch_versions.mix(EGGNOG_MAPPER.out.versions)

    DBCAN2(ch_clustered, dbcan2_db)
    ch_versions = ch_versions.mix(DBCAN2.out.versions)

    KOFAMSCAN(ch_clustered, kofamscan_db)
    ch_versions = ch_versions.mix(KOFAMSCAN.out.versions)

    emit:
    proteins       = ch_clustered                  // → PLASTIZYME_PREDICTION (Stage 7)
    taxonomy       = GTDBTK_CLASSIFYWF.out.summary
    eggnog_results = EGGNOG_MAPPER.out.annotations
    dbcan2_results = DBCAN2.out.overview
    kegg_results   = KOFAMSCAN.out.hits
    versions       = ch_versions
}
