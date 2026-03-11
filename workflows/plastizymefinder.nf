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
include { MULTIQC } from '../modules/nf-core/multiqc/main'

// -----------------------------------------------------------------------
// HELPER FUNCTIONS
// -----------------------------------------------------------------------

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

    ch_versions = Channel.empty()

    // -----------------------------------------------------------------------
    // 0. Parse samplesheet → channel of [ meta, [reads] ]
    // -----------------------------------------------------------------------
    ch_reads = Channel
        .fromPath(params.input)
        .splitCsv(header: true, sep: ',', strip: true)
        .map { row -> validate_samplesheet(row) }

    // -----------------------------------------------------------------------
    // 0. Resolve all databases (user-provided paths OR auto-download)
    // -----------------------------------------------------------------------
    PREPARE_DATABASES()

    ch_kraken2_db    = PREPARE_DATABASES.out.kraken2_db
    ch_metaphlan4_db = PREPARE_DATABASES.out.metaphlan4_db
    ch_dbcan2_db     = PREPARE_DATABASES.out.dbcan2_db
    ch_eggnog_db     = PREPARE_DATABASES.out.eggnog_db
    ch_kofamscan_db  = PREPARE_DATABASES.out.kofamscan_db
    ch_gtdbtk_db     = PREPARE_DATABASES.out.gtdbtk_db
    ch_petase_ref    = PREPARE_DATABASES.out.petase_ref  // 6EQE or user-provided PDB
    ch_pet_db        = Channel.fromPath(params.pet_db)

    ch_versions = ch_versions.mix(PREPARE_DATABASES.out.versions)

    // -----------------------------------------------------------------------
    // Stage 1 — QC & Preprocessing
    // FastQC (raw) → fastp → Bowtie2 (PhiX/host removal) → FastQC (trimmed)
    // -----------------------------------------------------------------------
    QC_PREPROCESSING(ch_reads)

    ch_clean_reads   = QC_PREPROCESSING.out.reads
    ch_qc_reports    = QC_PREPROCESSING.out.reports
    ch_versions      = ch_versions.mix(QC_PREPROCESSING.out.versions)

    // -----------------------------------------------------------------------
    // Stage 2 — Taxonomic Profiling (runs in parallel with assembly)
    // Kraken2/Krona + MetaPhlAn4
    // -----------------------------------------------------------------------
    if (!params.skip_taxonomy) {
        TAXONOMIC_PROFILING(
            ch_clean_reads,
            ch_kraken2_db,
            ch_metaphlan4_db
        )
        ch_versions = ch_versions.mix(TAXONOMIC_PROFILING.out.versions)
    }

    // -----------------------------------------------------------------------
    // Stage 3 — De Novo Assembly, Contig Evaluation & Annotation
    // MEGAHIT → QUAST → Prodigal → Bowtie2 (coverage)
    // -----------------------------------------------------------------------
    ASSEMBLY_ANNOTATION(ch_clean_reads)

    ch_contigs  = ASSEMBLY_ANNOTATION.out.contigs
    ch_bam      = ASSEMBLY_ANNOTATION.out.bam        // coverage BAMs for MetaBAT2
    ch_versions = ch_versions.mix(ASSEMBLY_ANNOTATION.out.versions)

    // -----------------------------------------------------------------------
    // Stage 4 — Contig Binning
    // MetaBAT2 → bins + unbinned
    // -----------------------------------------------------------------------
    BINNING(ch_contigs, ch_bam)

    ch_bins     = BINNING.out.bins       // [ meta, path/to/bin/*.fa ] per sample
    ch_unbinned = BINNING.out.unbinned   // [ meta, unbinned.fa ]
    ch_versions = ch_versions.mix(BINNING.out.versions)

    // -----------------------------------------------------------------------
    // Stage 5 — Bin Quality Evaluation
    // QUAST per bin + dRep deduplication/filtering
    // -----------------------------------------------------------------------
    BIN_QC(ch_bins)

    ch_hq_bins  = BIN_QC.out.passed_bins
    ch_versions = ch_versions.mix(BIN_QC.out.versions)

    // -----------------------------------------------------------------------
    // Stage 6 — Bin Taxonomic Classification & Gene Annotation
    // Prokka → CD-Hit → GTDB-tk + (eggNOG | dbCAN2 | kofamscan in parallel)
    // -----------------------------------------------------------------------
    if (!params.skip_annotation) {
        BIN_CLASSIFICATION(
            ch_hq_bins,
            ch_gtdbtk_db,
            ch_eggnog_db,
            ch_dbcan2_db,
            ch_kofamscan_db
        )
        ch_proteins = BIN_CLASSIFICATION.out.proteins   // clustered proteins for Stage 7
        ch_versions = ch_versions.mix(BIN_CLASSIFICATION.out.versions)
    } else {
        // If annotation is skipped, extract proteins from Prodigal output
        ch_proteins = ASSEMBLY_ANNOTATION.out.proteins
    }

    // -----------------------------------------------------------------------
    // Stage 7 — Targeted Plastizyme Prediction
    // Input: HQ bins + unbinned contigs (combined per sample) + PET_DB → MeTarENZ
    // -----------------------------------------------------------------------
    PLASTIZYME_PREDICTION(
        ch_hq_bins,
        ch_unbinned,
        ch_pet_db
    )

    ch_candidates = PLASTIZYME_PREDICTION.out.candidates
    ch_versions   = ch_versions.mix(PLASTIZYME_PREDICTION.out.versions)

    // -----------------------------------------------------------------------
    // Stage 8 — Conservative Domain Search & 3D Structure Prediction
    // CD-search → AlphaFold2 → TM-Align (vs known PETase structures)
    // -----------------------------------------------------------------------
    if (!params.skip_structure) {
        STRUCTURE_PREDICTION(ch_candidates, ch_petase_ref)
        ch_versions = ch_versions.mix(STRUCTURE_PREDICTION.out.versions)
    }

    // -----------------------------------------------------------------------
    // MultiQC — aggregate QC reports from all stages
    // -----------------------------------------------------------------------
    MULTIQC(
        ch_qc_reports.collect(),
        [],
        [],
        []
    )
}
