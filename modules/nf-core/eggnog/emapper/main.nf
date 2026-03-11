process EGGNOG_MAPPER {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::eggnog-mapper=2.1.12'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/eggnog-mapper:2.1.12--pyhdfd78af_0' :
        'biocontainers/eggnog-mapper:2.1.12--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)
    path  db
    val   db_type

    output:
    tuple val(meta), path('*.emapper.annotations'),         emit: annotations
    tuple val(meta), path('*.emapper.hits'),                optional: true, emit: hits
    tuple val(meta), path('*.emapper.seed_orthologs'),      optional: true, emit: orthologs
    path  'versions.yml',                                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args     = task.ext.args   ?: ''
    def prefix   = task.ext.prefix ?: "${meta.id}"
    def db_arg   = db_type         ?: 'proteins'
    """
    emapper.py \\
        -i $fasta \\
        --itype ${db_arg} \\
        --data_dir $db \\
        --output ${prefix} \\
        --cpu $task.cpus \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eggnog-mapper: \$( emapper.py --version 2>&1 | grep 'emapper' | sed 's/emapper-//' | sed 's/ .*//' )
    END_VERSIONS
    """
}
