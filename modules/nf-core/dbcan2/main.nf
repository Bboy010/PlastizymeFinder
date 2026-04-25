process DBCAN2 {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::run-dbcan=4.1.4'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/run-dbcan:4.1.4--pyhdfd78af_0' :
        'biocontainers/run-dbcan:4.1.4--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)
    path  db

    output:
    tuple val(meta), path('*.overview.txt'),    emit: overview
    tuple val(meta), path('*.hmmer.out'),        optional: true, emit: hmmer
    tuple val(meta), path('*.diamond.out'),      optional: true, emit: diamond
    path  'versions.yml',                        emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    run_dbcan \\
        $fasta protein \\
        --out_dir ${prefix}_dbcan \\
        --db_dir $db \\
        --cpu $task.cpus \\
        $args

    cp ${prefix}_dbcan/overview.txt ${prefix}.overview.txt
    cp ${prefix}_dbcan/hmmer.out    ${prefix}.hmmer.out    2>/dev/null || true
    cp ${prefix}_dbcan/diamond.out  ${prefix}.diamond.out  2>/dev/null || true

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        run_dbcan: \$( run_dbcan --version 2>&1 | sed 's/run_dbcan //' )
    END_VERSIONS
    """
}
