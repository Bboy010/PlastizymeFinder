process BOWTIE2_BUILD {
    tag "${meta.id}"
    label 'process_medium'

    conda "bioconda::bowtie2=2.5.3"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bowtie2:2.5.3--py310h8d7afc0_0' :
        'biocontainers/bowtie2:2.5.3--py310h8d7afc0_0'}"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path('bowtie2')  , emit: index
    path "versions.yml"                , emit: versions

    script:
    def args       = task.ext.args ?: ''
    def decompress = fasta.name.endsWith('.gz') ? "gunzip -c $fasta > input.fa && fasta_input=input.fa" : "fasta_input=$fasta"
    """
    $decompress
    mkdir bowtie2
    bowtie2-build \\
        --threads ${task.cpus} \\
        ${args} \\
        \$fasta_input \\
        bowtie2/${meta.id}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2: \$(echo \$(bowtie2 --version 2>&1) | sed 's/^.*bowtie2-align-s version //; s/ .*\$//')
    END_VERSIONS
    """
}
