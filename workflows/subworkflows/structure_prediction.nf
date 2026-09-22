/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: STRUCTURE_PREDICTION  (Stage 8)

    RPS-BLAST vs CDD (conserved domains)  ─┐
                                           ├─ both read the same candidate FASTA
    AlphaFold2 (3D prediction) ────────────┘
        └─ TM-Align vs the reference PETase (default 6EQE)

    RPS-BLAST against the pre-formatted CDD profiles is the local, offline
    equivalent of NCBI Batch CD-Search: same domain assignments, but
    reproducible, cacheable by -resume and free of network quotas.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { RPSBLAST   } from '../../modules/local/rpsblast/main'
include { ALPHAFOLD2 } from '../../modules/local/alphafold2/main'
include { TMALIGN    } from '../../modules/local/tmalign/main'

workflow STRUCTURE_PREDICTION {

    take:
    candidates  // channel: [ meta, candidates.faa ] from PLASTIZYME_PREDICTION
    petase_ref  // channel: path — reference PDB for TM-Align (default 6EQE)
    cdd_db      // channel: path — pre-formatted CDD RPS-BLAST database directory

    main:
    def ch_versions = channel.empty()

    // 8a. Conserved-domain annotation of the candidates (parallel to AlphaFold2)
    RPSBLAST(candidates, cdd_db)
    ch_versions = ch_versions.mix(RPSBLAST.out.versions.first())

    // 8b. 3D structure prediction on the same candidate FASTA
    ALPHAFOLD2(candidates)
    ch_versions = ch_versions.mix(ALPHAFOLD2.out.versions.first())

    // 8c. Structural similarity of every predicted model vs the PETase reference
    TMALIGN(ALPHAFOLD2.out.pdb, petase_ref)
    ch_versions = ch_versions.mix(TMALIGN.out.versions.first())

    emit:
    pdb_structures = ALPHAFOLD2.out.pdb   // predicted 3D structures (.pdb)
    domain_hits    = RPSBLAST.out.hits    // conserved-domain annotations (.tsv)
    tmalign_scores = TMALIGN.out.results  // TM-score, RMSD vs the PETase reference
    versions       = ch_versions
}
