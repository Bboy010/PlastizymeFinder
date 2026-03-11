/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Subworkflow: QC_PREPROCESSING  (Stage 1)
    FastQC (raw) → fastp → Bowtie2 (PhiX/host removal) → FastQC (trimmed)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

include { FASTQC as FASTQC_RAW      } from '../../modules/nf-core/fastqc/main'
include { FASTP                      } from '../../modules/nf-core/fastp/main'
include { BOWTIE2_ALIGN as BOWTIE2_ALIGN_HOST } from '../../modules/nf-core/bowtie2/align/main'
include { FASTQC as FASTQC_TRIMMED  } from '../../modules/nf-core/fastqc/main'

workflow QC_PREPROCESSING {

    take:
    reads   // channel: [ meta, [ fastq_1, fastq_2 ] ]

    main:
    ch_versions = Channel.empty()
    ch_reports  = Channel.empty()

    // 1a. FastQC on raw reads
    FASTQC_RAW(reads)
    ch_reports  = ch_reports.mix(FASTQC_RAW.out.zip)
    ch_versions = ch_versions.mix(FASTQC_RAW.out.versions.first())

    // 1b. Adapter trimming & quality filtering with fastp
    FASTP(reads, [], false, false)
    ch_trimmed  = FASTP.out.reads
    ch_reports  = ch_reports.mix(FASTP.out.json)
    ch_versions = ch_versions.mix(FASTP.out.versions.first())

    // 1c. Remove PhiX / host reads with Bowtie2
    //     Only runs if params.host_genome is provided
    if (params.host_genome) {
        ch_host_index = Channel.fromPath(params.host_genome)
        BOWTIE2_ALIGN_HOST(ch_trimmed, ch_host_index, false, true)
        ch_clean = BOWTIE2_ALIGN_HOST.out.fastq
        ch_versions = ch_versions.mix(BOWTIE2_ALIGN_HOST.out.versions.first())
    } else {
        ch_clean = ch_trimmed
    }

    // 1d. FastQC on trimmed / cleaned reads
    FASTQC_TRIMMED(ch_clean)
    ch_reports  = ch_reports.mix(FASTQC_TRIMMED.out.zip)
    ch_versions = ch_versions.mix(FASTQC_TRIMMED.out.versions.first())

    emit:
    reads    = ch_clean    // [ meta, [clean_reads] ] → Assembly
    reports  = ch_reports  // All QC files → MultiQC
    versions = ch_versions
}
