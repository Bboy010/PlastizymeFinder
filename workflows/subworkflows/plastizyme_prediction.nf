/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: PLASTIZYME_PREDICTION  (Stage 7)

    Input  : every bin from Stage 4 (binning) + unbinned/discarded contigs + PET_DB
    Process: Concatenate bins + unbinned per sample → MeTarEnz vs PET_DB
    Output : Candidate plastizyme proteins (FASTA) + the screening table

    Design note:
    MeTarEnz receives a combined FASTA of bins + unbinned/discarded contigs so
    that no sequence is missed in the plastizyme search. Because those are
    nucleotide contigs, the default screening mode is 'cs' (contig_screening,
    BLASTX), which reports the six-frame translation of every hit. Set
    --metarenz_mode ps to screen pre-translated proteins with BLASTP instead.

    Design note — why every bin, not just the high-quality ones:
    Stage 5 (dRep + CheckM2) exists to decide which bins are worth annotating
    and classifying in Stage 6, not to decide what gets screened here. A bin
    dRep dereplicates away, or CheckM2 scores below threshold, is still a
    genuine assembled sequence and may carry a plastizyme; filtering it out
    before screening would silently drop candidates. Screening every bin
    (rather than only Stage 5's survivors) is also the published method's own
    design, not an improvement on it - see the schema in the paper.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { METARENZ } from '../../modules/local/metarenz/main'

workflow PLASTIZYME_PREDICTION {

    take:
    bins      // channel: [ meta, [ bin1.fa, bin2.fa, ... ] ] — every bin from Stage 4, unfiltered
    unbinned  // channel: [ meta, unbinned.fa ] — contigs no bin claimed, per sample
    pet_db    // channel: path — PET_DB FASTA (curated plastic-degrading sequences)
    mode      // value:   'cs' (nucleotide contigs) or 'ps' (proteins)

    main:
    def ch_versions = channel.empty()

    // -----------------------------------------------------------------------
    // Merge every bin + unbinned/discarded into one list of FASTAs per sample.
    // remainder: true keeps samples that produced no bin at all.
    // -----------------------------------------------------------------------
    def ch_query = bins
        .join(unbinned, by: 0, remainder: true)
        .map { meta, sample_bins, unbinned_fa ->
            def all_fastas = []
            if (sample_bins) {
                all_fastas += sample_bins instanceof List ? sample_bins : [sample_bins]
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
