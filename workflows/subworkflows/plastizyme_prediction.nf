/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: PLASTIZYME_PREDICTION  (Stage 7)

    Input  : HQ bins + unbinned contigs (mixed) + PET_DB
    Process: MeTarENZ — targeted plastizyme prediction against PET_DB
    Output : Candidate plastizyme sequences (FASTA + annotations)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { METATARENZ } from '../../modules/local/metatarenz/main'

workflow PLASTIZYME_PREDICTION {

    take:
    sequences  // channel: [ meta, fasta ] — HQ bins + unbinned (mixed with .mix())
    pet_db     // channel: path to PET_DB FASTA (curated plastic-degrading sequences)

    main:
    ch_versions = Channel.empty()

    // Combine each sequence file with the PET_DB for MeTarENZ search
    ch_input = sequences.combine(pet_db)
    // ch_input : [ meta, fasta, pet_db_path ]

    METATARENZ(ch_input)

    ch_candidates = METATARENZ.out.candidates   // [ meta, candidates.fasta ]
    ch_versions   = ch_versions.mix(METATARENZ.out.versions.first())

    emit:
    candidates = ch_candidates  // → STRUCTURE_PREDICTION (Stage 8)
    versions   = ch_versions
}
