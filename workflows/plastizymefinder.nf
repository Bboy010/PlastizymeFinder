/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PlastizymeFinder — Main workflow
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

// -----------------------------------------------------------------------
// IMPORT SUBWORKFLOWS
// -----------------------------------------------------------------------
include { PREPARE_DATABASES      } from '../workflows/subworkflows/prepare_databases'
include { QC_PREPROCESSING       } from '../workflows/subworkflows/qc_preprocessing'
include { TAXONOMIC_PROFILING    } from '../workflows/subworkflows/taxonomic_profiling'
include { ASSEMBLY_ANNOTATION    } from '../workflows/subworkflows/assembly_annotation'
include { BINNING                } from '../workflows/subworkflows/binning'
include { BIN_QC                 } from '../workflows/subworkflows/bin_qc'
include { BIN_CLASSIFICATION     } from '../workflows/subworkflows/bin_classification'
include { PLASTIZYME_PREDICTION  } from '../workflows/subworkflows/plastizyme_prediction'
include { STRUCTURE_PREDICTION   } from '../workflows/subworkflows/structure_prediction'

// -----------------------------------------------------------------------
// IMPORT MODULES
// -----------------------------------------------------------------------
include { MULTIQC     } from '../modules/nf-core/multiqc/main'
include { PLOT_REPORT } from '../modules/local/plotreport/main'
include { METARENZ    } from '../modules/local/metarenz/main'
include { GUNZIP_BINS      } from '../modules/local/gunzip_bins/main'
include { EXTRACT_UNBINNED } from '../modules/local/extract_unbinned/main'

// -----------------------------------------------------------------------
// HELPER FUNCTIONS
// -----------------------------------------------------------------------

// One row of --contigs_input: sample,contigs[,bins]. `bins` is a directory
// (every *.fa, *.fasta, *.fna in it, gzipped or not) or a glob.
def parse_contigs_row(LinkedHashMap row) {
    if (!row.sample)  error "ERROR in --contigs_input: 'sample' is missing in row ${row}"
    if (!row.contigs) error "ERROR in --contigs_input: 'contigs' is missing for sample ${row.sample}"

    def contigs = file(row.contigs, checkIfExists: true)
    def bins    = []
    if (row.bins) {
        def pattern = row.bins.contains('*') || !file(row.bins).isDirectory()
            ? row.bins
            : "${row.bins.replaceAll('/+$', '')}/*.{fa,fasta,fna,fa.gz,fasta.gz,fna.gz}"
        bins = files(pattern)
        if (!bins) error "ERROR in --contigs_input: no bin FASTA found at '${row.bins}' for sample ${row.sample}"
    }
    return [ [id: row.sample], contigs, bins ]
}

def validate_samplesheet(LinkedHashMap row) {
    def meta   = [id: row.sample]
    def reads  = []

    if (!row.fastq_1) error "ERROR in samplesheet: 'fastq_1' is missing for sample ${row.sample}"
    if (!file(row.fastq_1).exists()) error "ERROR: fastq_1 file does not exist: ${row.fastq_1}"

    if (row.fastq_2) {
        reads = [ file(row.fastq_1), file(row.fastq_2) ]
        meta.single_end = false
    } else {
        reads = [ file(row.fastq_1) ]
        meta.single_end = true
    }
    return [ meta, reads ]
}

// -----------------------------------------------------------------------
// MAIN WORKFLOW
// -----------------------------------------------------------------------

workflow PLASTIZYMEFINDER {

    // -----------------------------------------------------------------------
    // Standalone entry point: screen a FASTA the caller already has, instead
    // of raw reads. Skips stages 1-6 entirely - no assembly, no binning, no
    // taxonomy - and goes straight to plastizyme screening (stage 7) and,
    // unless --skip_structure, structure prediction (stage 8). This is the
    // path for candidate sequences obtained some other way: a published
    // protein catalogue, someone else's assembly, sequences from a different
    // pipeline entirely.
    // -----------------------------------------------------------------------
    if (params.candidates_fasta) {
        // Stages 2 and 6 have nothing to run on here (no reads, no bins) -
        // force them off so PREPARE_DATABASES doesn't fetch Kraken2, MetaPhlAn4,
        // dbCAN, eggNOG, KofamScan or GTDB-Tk for a run that will never use them.
        params.skip_taxonomy    = true
        params.skip_annotation  = true
        params.skip_drep_checkm = true

        def ch_versions = channel.empty()
        def ch_pet_db   = channel.fromPath(params.pet_db, checkIfExists: true)

        def meta = [id: file(params.candidates_fasta).simpleName]
        def ch_query = channel.of([meta, [file(params.candidates_fasta, checkIfExists: true)]])

        METARENZ(ch_query, ch_pet_db, params.metarenz_mode)
        ch_versions = ch_versions.mix(METARENZ.out.versions)

        if (!params.skip_structure) {
            // Same databases stage 8 always uses; petase_ref and cdd_db have
            // their own auto-download so no other database is needed here.
            PREPARE_DATABASES()
            ch_versions = ch_versions.mix(PREPARE_DATABASES.out.versions)

            STRUCTURE_PREDICTION(
                METARENZ.out.candidates,
                PREPARE_DATABASES.out.petase_ref,
                PREPARE_DATABASES.out.cdd_db,
                params.colabfold_weights ? channel.fromPath(params.colabfold_weights, checkIfExists: true) : []
            )
            ch_versions = ch_versions.mix(STRUCTURE_PREDICTION.out.versions)
        }

        ch_versions
            .unique()
            .collectFile(name: 'software_versions.yml', sort: true, storeDir: "${params.outdir}/pipeline_info")

        return
    }

    def ch_versions = channel.empty()

    // Chained entry point (--contigs_input): stages 1-4 already ran in another
    // pipeline (typically nf-core/mag) and there are no reads to profile, so
    // stage 2 is forced off before PREPARE_DATABASES decides what to
    // download. Stage 6 (bin annotation/taxonomy) is forced off too: this
    // entry point is the pipeline's narrow "plastizyme prediction" identity -
    // mag for assembly/binning, this for screening + structure - and stage 6
    // is out of that scope. Override with --skip_annotation false through a
    // profile or -params-file, not the command line: since Nextflow 25 a CLI
    // "false" arrives as the truthy String "false".
    if (params.contigs_input) {
        params.skip_taxonomy   = true
        params.skip_annotation = true
    }

    // -----------------------------------------------------------------------
    // 0. Resolve all databases (user-provided paths OR auto-download)
    // -----------------------------------------------------------------------
    PREPARE_DATABASES()

    def ch_kraken2_db    = PREPARE_DATABASES.out.kraken2_db
    def ch_metaphlan4_db = PREPARE_DATABASES.out.metaphlan4_db
    def ch_dbcan2_db     = PREPARE_DATABASES.out.dbcan2_db
    def ch_eggnog_db     = PREPARE_DATABASES.out.eggnog_db
    def ch_kofamscan_db  = PREPARE_DATABASES.out.kofamscan_db
    def ch_gtdbtk_db     = PREPARE_DATABASES.out.gtdbtk_db
    def ch_petase_ref    = PREPARE_DATABASES.out.petase_ref  // 6EQE or user-provided PDB
    def ch_cdd_db        = PREPARE_DATABASES.out.cdd_db      // CDD profiles for RPS-BLAST
    def ch_checkm2_db    = PREPARE_DATABASES.out.checkm2_db  // dRep --genomeInfo quality model
    // A value channel, not fromPath: a queue channel holds the database once,
    // so METARENZ would consume it on the first sample and never run again.
    def ch_pet_db        = channel.value(file(params.pet_db, checkIfExists: true))

    ch_versions = ch_versions.mix(PREPARE_DATABASES.out.versions)

    // Reports of stages 1-3. They stay empty on the chained entry point,
    // where those stages ran elsewhere.
    def ch_qc_reports        = channel.empty()
    def ch_fastp_json        = channel.empty()
    def ch_kraken2_report    = channel.empty()
    def ch_metaphlan_profile = channel.empty()
    def ch_assembly_quast    = channel.empty()
    def ch_prodigal_proteins = channel.empty()

    def ch_bins                // [ meta, [ bin1.fa, bin2.fa, ... ] ] per sample
    def ch_unbinned            // [ meta, unbinned.fa ]

    if (params.contigs_input) {
        // -------------------------------------------------------------------
        // Chained entry point — assemblies and bins from another pipeline
        // (nf-core/mag: Assembly/<assembler>/ and GenomeBinning/<binner>/bins/).
        // Stage 5 re-applies the study's CheckM2 + dRep thresholds to those
        // bins, and contigs no bin claimed are screened as unbinned.
        // -------------------------------------------------------------------
        def ch_assemblies = channel
            .fromPath(params.contigs_input)
            .splitCsv(header: true, sep: ',', strip: true)
            .map { row -> parse_contigs_row(row) }

        // Bins are gunzipped under a .fa name: CheckM2 and dRep read no other.
        GUNZIP_BINS(
            ch_assemblies
                .filter { _meta, _contigs, bins -> bins.size() > 0 }
                .map { meta, _contigs, bins -> [ meta, bins ] }
        )
        ch_bins     = GUNZIP_BINS.out.bins
        ch_versions = ch_versions.mix(GUNZIP_BINS.out.versions.first())

        EXTRACT_UNBINNED(ch_assemblies)
        ch_unbinned = EXTRACT_UNBINNED.out.unbinned
        ch_versions = ch_versions.mix(EXTRACT_UNBINNED.out.versions.first())
    } else {
        // -------------------------------------------------------------------
        // 0. Parse samplesheet → channel of [ meta, [reads] ]
        // -------------------------------------------------------------------
        def ch_reads = channel
            .fromPath(params.input)
            .splitCsv(header: true, sep: ',', strip: true)
            .map { row -> validate_samplesheet(row) }

        // -------------------------------------------------------------------
        // Stage 1 — QC & Preprocessing
        // FastQC (raw) → fastp → Bowtie2 (PhiX/host removal) → FastQC (trimmed)
        // -------------------------------------------------------------------
        QC_PREPROCESSING(ch_reads)

        def ch_clean_reads = QC_PREPROCESSING.out.reads
        ch_qc_reports      = QC_PREPROCESSING.out.reports
        ch_fastp_json      = QC_PREPROCESSING.out.fastp_json
        ch_versions        = ch_versions.mix(QC_PREPROCESSING.out.versions)

        // -------------------------------------------------------------------
        // Stage 2 — Taxonomic Profiling (runs in parallel with assembly)
        // Kraken2/Krona + MetaPhlAn4
        // -------------------------------------------------------------------
        if (!params.skip_taxonomy) {
            TAXONOMIC_PROFILING(
                ch_clean_reads,
                ch_kraken2_db,
                ch_metaphlan4_db
            )
            ch_kraken2_report    = TAXONOMIC_PROFILING.out.kraken2_report
            ch_metaphlan_profile = TAXONOMIC_PROFILING.out.metaphlan4_profile
            ch_versions          = ch_versions.mix(TAXONOMIC_PROFILING.out.versions)
        }

        // -------------------------------------------------------------------
        // Stage 3 — De Novo Assembly, Contig Evaluation & Annotation
        // MEGAHIT → QUAST → Prodigal → Bowtie2 (coverage)
        // -------------------------------------------------------------------
        ASSEMBLY_ANNOTATION(ch_clean_reads)

        ch_assembly_quast    = ASSEMBLY_ANNOTATION.out.quast
        ch_prodigal_proteins = ASSEMBLY_ANNOTATION.out.proteins
        ch_versions          = ch_versions.mix(ASSEMBLY_ANNOTATION.out.versions)

        // -------------------------------------------------------------------
        // Stage 4 — Contig Binning
        // MetaBAT2 + MaxBin2 + CONCOCT → DAS Tool → bins + unbinned
        // -------------------------------------------------------------------
        BINNING(ASSEMBLY_ANNOTATION.out.contigs, ASSEMBLY_ANNOTATION.out.bam)

        ch_bins     = BINNING.out.bins
        ch_unbinned = BINNING.out.unbinned
        ch_versions = ch_versions.mix(BINNING.out.versions)
    }

    // -----------------------------------------------------------------------
    // Stage 5 — Bin Quality Evaluation
    // QUAST per bin + dRep deduplication/filtering. Feeds Stage 6 only: per
    // the published method's own schema, Stage 7 screens every bin straight
    // from Stage 4 (see below) - dRep decides what is worth annotating and
    // classifying, not what gets screened for plastizymes. So Stage 5 has no
    // reason to run when Stage 6 doesn't: skipped together, gated on the same
    // flag. That also means --skip_annotation (forced true for the chained
    // entry point, see above) needs no CheckM2 database at all.
    //
    // Stage 6 — Bin Taxonomic Classification & Gene Annotation
    // Prokka → CD-Hit → GTDB-tk + (eggNOG | dbCAN2 | kofamscan in parallel)
    // -----------------------------------------------------------------------
    def ch_bin_quast       = channel.empty()  // → MultiQC
    def ch_bin_drep_tables = channel.empty()  // → PLOT_REPORT
    def ch_proteins
    if (!params.skip_annotation) {
        BIN_QC(ch_bins, ch_checkm2_db)
        ch_bin_quast       = BIN_QC.out.quast_stats
        ch_bin_drep_tables = BIN_QC.out.drep_tables
        ch_versions        = ch_versions.mix(BIN_QC.out.versions)

        BIN_CLASSIFICATION(
            BIN_QC.out.passed_bins,
            ch_gtdbtk_db,
            ch_eggnog_db,
            ch_dbcan2_db,
            ch_kofamscan_db
        )
        ch_proteins = BIN_CLASSIFICATION.out.proteins   // clustered proteins - unused downstream, kept for parity with the Prodigal fallback below
        ch_versions = ch_versions.mix(BIN_CLASSIFICATION.out.versions)
    } else {
        // If annotation is skipped, extract proteins from Prodigal output
        ch_proteins = ch_prodigal_proteins
    }

    // -----------------------------------------------------------------------
    // Stage 7 — Targeted Plastizyme Prediction
    // Input: every bin from Stage 4 (not Stage 5's filtered/dereplicated set)
    // + unbinned contigs (combined per sample) + PET_DB → MeTarEnz. See the
    // design note in plastizyme_prediction.nf for why Stage 5 is bypassed.
    // -----------------------------------------------------------------------
    def ch_candidates = channel.empty()
    if (!params.skip_plastizyme) {
        PLASTIZYME_PREDICTION(
            ch_bins,
            ch_unbinned,
            ch_pet_db,
            params.metarenz_mode
        )
        ch_candidates = PLASTIZYME_PREDICTION.out.candidates
        ch_versions   = ch_versions.mix(PLASTIZYME_PREDICTION.out.versions)
    }

    // -----------------------------------------------------------------------
    // Stage 8 — Conservative Domain Search & 3D Structure Prediction
    // CD-search → AlphaFold2 → TM-Align (vs known PETase structures)
    // -----------------------------------------------------------------------
    if (!params.skip_structure && !params.skip_plastizyme) {
        STRUCTURE_PREDICTION(
            ch_candidates,
            ch_petase_ref,
            ch_cdd_db,
            params.colabfold_weights ? channel.fromPath(params.colabfold_weights, checkIfExists: true) : []
        )
        ch_versions = ch_versions.mix(STRUCTURE_PREDICTION.out.versions)
    }

    // -----------------------------------------------------------------------
    // Software versions — every module emits a versions.yml; collate them into
    // a single file so the run is reproducible and MultiQC can report it.
    // -----------------------------------------------------------------------
    // Modules taken from nf-core/modules since 2026 (MaxBin2, CONCOCT, DAS Tool,
    // samtools, gunzip) publish their version on the 'versions' topic instead
    // of a versions.yml file; render those entries in the same YAML layout.
    def ch_topic_versions = channel.topic('versions')
        .unique()
        .map { process, tool, version -> "\"${process}\":\n    ${tool}: ${version}\n".toString() }

    // Read as text so both kinds sort together (collectFile cannot compare a
    // file with a string). The *_mqc_versions.yml name makes MultiQC render it
    // as its Software Versions section - and gives MultiQC something to report
    // on the chained entry point, where no stage 1-3 report exists.
    def ch_collated_versions = ch_versions
        .unique()
        .map { f -> f.text }
        .mix(ch_topic_versions)
        .collectFile(name: 'software_mqc_versions.yml', sort: true)

    // -----------------------------------------------------------------------
    // MultiQC — aggregate the reports of every stage, not just the QC one.
    // Each subworkflow contributes what MultiQC knows how to parse.
    // -----------------------------------------------------------------------
    def ch_multiqc_files = channel.empty()
        .mix(ch_qc_reports.map { _meta, files -> files })
        .mix(ch_kraken2_report.map { _meta, f -> f })
        .mix(ch_metaphlan_profile.map { _meta, f -> f })
        .mix(ch_assembly_quast.map { _meta, f -> f })
        .mix(ch_bin_quast.map { _meta, f -> f })
        .mix(ch_collated_versions)

    def ch_multiqc_config = params.multiqc_config
        ? channel.fromPath(params.multiqc_config, checkIfExists: true)
        : channel.fromPath("${projectDir}/assets/multiqc_config.yml", checkIfExists: true)

    MULTIQC(
        ch_multiqc_files.collect(),
        ch_multiqc_config.collect().ifEmpty([]),
        [],
        []
    )

    // -----------------------------------------------------------------------
    // Figures — taxonomy, assembly, bins and read QC, rendered from the raw
    // reports each tool wrote. Every input is optional: a skipped stage simply
    // drops the figures that depend on it. On the chained entry point the
    // reports of stages 1-3 live in the upstream pipeline's results, and the
    // script exits non-zero when it finds nothing to plot, so it is not run.
    // -----------------------------------------------------------------------
    if (!params.contigs_input) {
        PLOT_REPORT(
            ch_kraken2_report.ifEmpty { [[id: 'all_samples'], []] },
            ch_metaphlan_profile.map { _meta, f -> f }.ifEmpty([]),
            ch_assembly_quast.map { _meta, f -> f }.ifEmpty([]),
            ch_bin_drep_tables.map { _meta, f -> f }.ifEmpty([]),
            ch_fastp_json.map { _meta, f -> f }.ifEmpty([])
        )
        ch_versions = ch_versions.mix(PLOT_REPORT.out.versions)
    }
}
