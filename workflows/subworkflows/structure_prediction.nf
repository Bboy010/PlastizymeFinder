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
    petase_ref  // path: reference PDB for TM-Align (default 6EQE, or user-provided)

    main:
    ch_versions = Channel.empty()

    // 8a. CD-search: conserved domain annotation on candidate FASTA (runs in parallel with AlphaFold2)
    //     Uses NCBI CD-Search REST API → TSV of domain hits
    CDSEARCH(candidates)
    ch_domain_tsv = CDSEARCH.out.hits
    ch_versions   = ch_versions.mix(CDSEARCH.out.versions.first())

    // 8b. AlphaFold2: 3D structure prediction directly on candidate FASTA
    //     (runs in parallel with CD-Search — both use the same input FASTA)
    ALPHAFOLD2(candidates)
    ch_structures = ALPHAFOLD2.out.pdb
    ch_versions   = ch_versions.mix(ALPHAFOLD2.out.versions.first())

    // 8c. TM-Align: structural similarity vs PETase reference
    //     Default reference: 6EQE (IsPETase) — auto-downloaded or user-provided
    TMALIGN(ch_structures, petase_ref)
    ch_tmalign_results = TMALIGN.out.results
    ch_versions        = ch_versions.mix(TMALIGN.out.versions.first())

    emit:
    pdb_structures = ch_structures        // Predicted 3D structures (.pdb)
    domain_hits    = ch_domain_tsv        // CD-Search conserved domain annotations (.tsv)
    tmalign_scores = ch_tmalign_results   // TM-score & RMSD vs PETase references
    versions       = ch_versions
}
