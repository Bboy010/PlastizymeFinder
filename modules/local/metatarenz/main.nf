/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: METATARENZ
    Targeted plastizyme prediction using MeTarENZ against PET_DB
    Input: [ meta, sequences.fasta, pet_db.fasta ]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process METATARENZ {
    tag "$meta.id"
    label 'process_medium'

    // TODO: replace with official container when available
    conda "bioconda::metatarenz"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metatarenz:latest' :
        'quay.io/biocontainers/metatarenz:latest' }"

    input:
    tuple val(meta), path(sequences), path(pet_db)
    // sequences: one or more FASTA files (HQ bins + unbinned/discarded from MetaBAT2)
    // pet_db:    curated PET_DB FASTA

    output:
    tuple val(meta), path("${meta.id}_candidates.fasta"), emit: candidates
    tuple val(meta), path("${meta.id}_metatarenz.tsv"),   emit: tsv
    path "versions.yml",                                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Concatenate all input FASTAs (bins + unbinned) into a single query file
    cat ${sequences} > ${prefix}_combined.fasta

    metatarenz \\
        --query ${prefix}_combined.fasta \\
        --db ${pet_db} \\
        --out ${prefix}_metatarenz.tsv \\
        --threads ${task.cpus} \\
        ${args}

    # Extract candidate sequences based on MeTarENZ hits
    awk 'NR>1 {print \$1}' ${prefix}_metatarenz.tsv > hit_ids.txt
    seqtk subseq ${prefix}_combined.fasta hit_ids.txt > ${prefix}_candidates.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metatarenz: \$(metatarenz --version 2>&1 | head -n1 | sed 's/MeTarENZ v//')
        seqtk: \$(seqtk 2>&1 | grep "Version" | sed 's/Version: //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_combined.fasta
    touch ${prefix}_candidates.fasta
    touch ${prefix}_metatarenz.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metatarenz: 1.0.0
        seqtk: 1.3
    END_VERSIONS
    """
}
