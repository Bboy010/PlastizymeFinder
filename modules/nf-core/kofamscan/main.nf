process KOFAMSCAN {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::kofamscan=1.3.0'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/kofamscan:1.3.0--hdfd78af_2' :
        'quay.io/biocontainers/kofamscan:1.3.0--hdfd78af_2' }"

    input:
    tuple val(meta), path(fasta)
    path  db      // directory containing ko_list and profiles/

    output:
    tuple val(meta), path('*.tsv'),     emit: hits
    path  'versions.yml',               emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // exec_annotation reads the query as text and dies on a compressed file
    // with "invalid byte sequence in UTF-8", so hand it plain FASTA.
    def decompress = fasta.name.endsWith('.gz')
        ? "gzip -cd ${fasta} > query.faa"
        : "ln -s ${fasta} query.faa"
    """
    $decompress

    exec_annotation \\
        --ko-list ${db}/ko_list \\
        --profile ${db}/profiles \\
        --cpu $task.cpus \\
        -f detail-tsv \\
        -o ${prefix}.kofamscan.tsv \\
        $args \\
        query.faa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kofamscan: \$( exec_annotation --version 2>&1 | sed 's/KofamScan //' )
    END_VERSIONS
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kofamscan: "stub"
    END_VERSIONS
    """
}
