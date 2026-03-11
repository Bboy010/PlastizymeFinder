/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: PLASTIZYME_PREDICTION  (Stage 7)

    Input  : HQ bins (from dRep) + unbinned/discarded contigs (from MetaBAT2) + PET_DB
    Process: Concatenate bins + unbinned per sample → MeTarENZ vs PET_DB
    Output : Candidate plastizyme sequences (FASTA + hit table)

    Design note:
    MeTarENZ receives by default a combined FASTA of bins + unbinned/discarded
    from MetaBAT2, ensuring no sequences are missed in the plastizyme search.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { METATARENZ } from '../../modules/local/metatarenz/main'

workflow PLASTIZYME_PREDICTION {

    take:
    hq_bins   // channel: [ meta, [ bin1.fa, bin2.fa, ... ] ] — HQ bins from dRep
    unbinned  // channel: [ meta, unbinned.fa ] — contigs discarded by MetaBAT2, per sample
    pet_db    // channel: path — PET_DB FASTA (curated plastic-degrading sequences)

    main:
    ch_versions = Channel.empty()

    // -----------------------------------------------------------------------
    // Merge HQ bins + unbinned/discarded into one list of FASTAs per sample
    // Join on meta.id (remainder:true keeps samples with no HQ bins)
    // -----------------------------------------------------------------------
    ch_combined = hq_bins
        .join(unbinned, by: 0, remainder: true)
        .map { meta, bins, unbinned_fa ->
            def all_fastas = []
            if (bins)        all_fastas += bins instanceof List ? bins : [ bins ]
            if (unbinned_fa) all_fastas += [ unbinned_fa ]
            [ meta, all_fastas ]
        }

    // -----------------------------------------------------------------------
    // Attach PET_DB to each sample → MeTarENZ input tuple:
    //   [ meta, [ all_fastas ], pet_db_path ]
    // -----------------------------------------------------------------------
    ch_input = ch_combined.combine(pet_db)

    METATARENZ(ch_input)

    ch_candidates = METATARENZ.out.candidates   // [ meta, candidates.fasta ]
    ch_versions   = ch_versions.mix(METATARENZ.out.versions.first())

    emit:
    candidates = ch_candidates      // → STRUCTURE_PREDICTION (Stage 8)
    tsv        = METATARENZ.out.tsv // hit table for reporting
    versions   = ch_versions
}
