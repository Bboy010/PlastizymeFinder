/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: PLASTIZYME_PREDICTION  (Stage 7)

    Input  : HQ bins (from dRep) + unbinned/discarded contigs (from MetaBAT2) + PET_DB
    Process: Concatenate bins + unbinned per sample → MeTarEnz vs PET_DB
    Output : Candidate plastizyme proteins (FASTA) + the screening table

    Design note:
    MeTarEnz receives a combined FASTA of bins + unbinned/discarded contigs so
    that no sequence is missed in the plastizyme search. Because those are
    nucleotide contigs, the default screening mode is 'cs' (contig_screening,
    BLASTX), which reports the six-frame translation of every hit. Set
    --metarenz_mode ps to screen pre-translated proteins with BLASTP instead.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { METARENZ } from '../../modules/local/metarenz/main'

workflow PLASTIZYME_PREDICTION {

    take:
    hq_bins   // channel: [ meta, [ bin1.fa, bin2.fa, ... ] ] — HQ bins from dRep
    unbinned  // channel: [ meta, unbinned.fa ] — contigs discarded by MetaBAT2, per sample
    pet_db    // channel: path — PET_DB FASTA (curated plastic-degrading sequences)
    mode      // value:   'cs' (nucleotide contigs) or 'ps' (proteins)

    main:
    def ch_versions = channel.empty()

    // -----------------------------------------------------------------------
    // Merge HQ bins + unbinned/discarded into one list of FASTAs per sample.
    // remainder: true keeps samples that produced no HQ bin at all.
    // -----------------------------------------------------------------------
    def ch_query = hq_bins
        .join(unbinned, by: 0, remainder: true)
        .map { meta, bins, unbinned_fa ->
            def all_fastas = []
            if (bins) {
                all_fastas += bins instanceof List ? bins : [bins]
            }
            if (unbinned_fa) {
                all_fastas += [unbinned_fa]
            }
            [meta, all_fastas]
        }
        .filter { _meta, fastas -> fastas.size() > 0 }

    METARENZ(ch_query, pet_db, mode)
    ch_versions = ch_versions.mix(METARENZ.out.versions.first())

    emit:
    candidates = METARENZ.out.candidates   // [ meta, *.candidates.faa ] → STRUCTURE_PREDICTION
    csv        = METARENZ.out.csv          // [ meta, *.metarenz.csv ]   → reporting
    versions   = ch_versions
}
