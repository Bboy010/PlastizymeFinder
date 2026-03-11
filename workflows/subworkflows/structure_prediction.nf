/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: STRUCTURE_PREDICTION  (Stage 8)
    CD-search (conserved domain) → AlphaFold2 (3D prediction) → TM-Align (vs PETase)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { CDSEARCH  } from '../../modules/nf-core/cdsearch/main'
include { ALPHAFOLD2 } from '../../modules/nf-core/alphafold2/main'
include { TMALIGN   } from '../../modules/local/tmalign/main'

workflow STRUCTURE_PREDICTION {

    take:
    candidates  // channel: [ meta, candidates.fasta ] from PLASTIZYME_PREDICTION

    main:
    ch_versions = Channel.empty()

    // 8a. CD-search: identify conserved domains (filter candidates with PETase-like domains)
    CDSEARCH(candidates)
    ch_domain_hits = CDSEARCH.out.hits
    ch_versions    = ch_versions.mix(CDSEARCH.out.versions.first())

    // 8b. AlphaFold2: predict 3D structure for filtered candidates
    //     Input: proteins that passed CD-search domain filter
    ALPHAFOLD2(ch_domain_hits)
    ch_structures = ALPHAFOLD2.out.pdb
    ch_versions   = ch_versions.mix(ALPHAFOLD2.out.versions.first())

    // 8c. TM-Align: structural comparison with known PETase reference structures
    //     Returns TM-score and RMSD for each predicted structure vs PETase
    TMALIGN(ch_structures)
    ch_tmalign_results = TMALIGN.out.results
    ch_versions        = ch_versions.mix(TMALIGN.out.versions.first())

    emit:
    pdb_structures = ch_structures        // Predicted 3D structures
    tmalign_scores = ch_tmalign_results   // Structural similarity to PETase
    versions       = ch_versions
}
