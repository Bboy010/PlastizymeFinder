process BOWTIE2_BUILD {
    tag "${meta.id}"
    label 'process_medium'

    conda "bioconda::bowtie2=2.5.4"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b4/b41b403e81883126c3227fc45840015538e8e2212f13abc9ae84e4b98891d51c/data' :
        'community.wave.seqera.io/library/bowtie2_htslib_samtools_pigz:edeb13799090a2a6'}"

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
    stub:
    """
    touch bowtie2

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2_build: "stub"
    END_VERSIONS
    """
}
