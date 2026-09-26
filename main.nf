#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PlastizymeFinder
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/Bboy010/PlastizymeFinder
    Docs   : https://github.com/Bboy010/PlastizymeFinder/docs
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PLASTIZYMEFINDER } from './workflows/plastizymefinder'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {
    // --help and --version are handled before anything else so they work
    // without an input samplesheet. The help text is rendered from
    // nextflow_schema.json, which keeps it in sync with the real parameters.
    if (params.help) {
        log.info(Utils.help("${projectDir}/nextflow_schema.json", workflow.manifest))
        return
    }

    if (params.version) {
        log.info("${workflow.manifest.name} ${workflow.manifest.version}")
        return
    }

    // Validate mandatory parameters: exactly one of the three entry points
    def entry_points = [params.input, params.contigs_input, params.candidates_fasta].findAll { p -> p }
    if (entry_points.size() == 0) {
        error "ERROR: Please provide one of --input <samplesheet.csv> (reads), --contigs_input <samplesheet.csv> (assemblies and bins, e.g. from nf-core/mag) or --candidates_fasta <sequences.fasta> (a FASTA you already have)"
    }

    if (entry_points.size() > 1) {
        error "ERROR: --input, --contigs_input and --candidates_fasta are different entry points - provide one, not several"
    }

    if (params.contigs_input && !file(params.contigs_input).exists()) {
        error "ERROR: --contigs_input samplesheet does not exist: ${params.contigs_input}"
    }

    if (params.candidates_fasta && !file(params.candidates_fasta).exists()) {
        error "ERROR: --candidates_fasta file does not exist: ${params.candidates_fasta}"
    }

    if (!(params.metarenz_mode in ['cs', 'ps'])) {
        error "ERROR: --metarenz_mode must be 'cs' (nucleotide contigs, BLASTX) or 'ps' (proteins, BLASTP), got '${params.metarenz_mode}'"
    }

    if (!params.pet_db) {
        error """
        =====================================================================
        ERROR: --pet_db is required.

        The PET_DB is a curated database of plastic-degrading enzyme sequences
        built from PAZy, NCBI, BRENDA, and UniProt through manual curation.

        Option 1 — Download the default PET_DB provided by the project:
          https://github.com/Bboy010/PlastizymeFinder/releases

        Option 2 — Build your own database following the guide:
          docs/pet_db_guide.md

        Then run the pipeline with:
          nextflow run main.nf --input samplesheet.csv --pet_db /path/to/pet_db.fasta

        =====================================================================
        """
    }

    PLASTIZYMEFINDER()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
