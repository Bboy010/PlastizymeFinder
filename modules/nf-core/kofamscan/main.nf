process KOFAMSCAN {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::kofamscan=1.3.0'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/kofamscan:1.3.0--hdfd78af_2' :
        'biocontainers/kofamscan:1.3.0--hdfd78af_2' }"

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
    """
    exec_annotation \\
        --ko-list ${db}/ko_list \\
        --profile ${db}/profiles \\
        --cpu $task.cpus \\
        -f detail-tsv \\
        -o ${prefix}.kofamscan.tsv \\
        $args \\
        $fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kofamscan: \$( exec_annotation --version 2>&1 | sed 's/KofamScan //' )
    END_VERSIONS
    """
}
