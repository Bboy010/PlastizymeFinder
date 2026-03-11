process FASTQC {
    tag "$meta.id"
    label 'process_medium'

    conda 'bioconda::fastqc=0.12.1'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/fastqc:0.12.1--hdfd78af_0' :
        'biocontainers/fastqc:0.12.1--hdfd78af_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.html'), emit: html
    tuple val(meta), path('*.zip'),  emit: zip
    path 'versions.yml',             emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def memory = task.memory.toGiga()
    """
    fastqc \\
        $args \\
        --threads $task.cpus \\
        --memory ${memory}000 \\
        $reads

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$( fastqc --version | sed 's/FastQC v//' )
    END_VERSIONS
    """
}
