process METAPHLAN4 {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::metaphlan=4.1.0'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/metaphlan:4.1.0--pyhca03a8a_0' :
        'biocontainers/metaphlan:4.1.0--pyhca03a8a_0' }"

    input:
    tuple val(meta), path(reads)
    path  db

    output:
    tuple val(meta), path('*_profile.txt'),        emit: profile
    tuple val(meta), path('*_bowtie2out.bz2'),     optional: true, emit: bowtie2out
    path  'versions.yml',                          emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args   ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    def input_arg = meta.single_end ?
        "${reads[0]}" :
        "${reads[0]},${reads[1]}"
    def input_type = meta.single_end ? 'fastq' : 'fastq'
    """
    metaphlan \\
        $input_arg \\
        --bowtie2db $db \\
        --input_type $input_type \\
        --nproc $task.cpus \\
        --bowtie2out ${prefix}_bowtie2out.bz2 \\
        -o ${prefix}_profile.txt \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$( metaphlan --version 2>&1 | sed 's/MetaPhlAn version //' )
    END_VERSIONS
    """
}
