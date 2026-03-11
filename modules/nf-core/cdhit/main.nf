process CDHIT {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::cd-hit=4.8.1'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/cd-hit:4.8.1--hdbdd923_2' :
        'biocontainers/cd-hit:4.8.1--hdbdd923_2' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path('*.fa.gz'),    emit: fasta
    tuple val(meta), path('*.clstr'),    emit: clusters
    path  'versions.yml',                emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cd-hit \\
        -i $fasta \\
        -o ${prefix}.cdhit.fa \\
        -T $task.cpus \\
        -M ${task.memory.toMega()} \\
        $args

    gzip ${prefix}.cdhit.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cdhit: \$( cd-hit -h 2>&1 | head -1 | sed 's/.*CD-HIT version //' | sed 's/ (.*//' )
    END_VERSIONS
    """
}
