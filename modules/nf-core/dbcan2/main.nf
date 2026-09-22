process DBCAN2 {
    tag "$meta.id"
    label 'process_high'

    // The package was renamed run-dbcan -> dbcan, and 4.1.4 exists neither on
    // bioconda nor as an image (quay.io only publishes run-dbcan 2.0.11).
    // v5 changed the CLI - see the script block.
    conda 'bioconda::dbcan=5.2.9'
    container "${workflow.containerEngine in ['singularity', 'apptainer']
        ? 'https://depot.galaxyproject.org/singularity/dbcan:5.2.9--pyhdfd78af_0'
        : 'quay.io/biocontainers/dbcan:5.2.9--pyhdfd78af_0'}"

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
    # dbCAN 5 works through subcommands. Options verified against image 5.2.9:
    #   run_dbcan CAZyme_annotation --mode --input_raw_data --output_dir --db_dir --threads
    run_dbcan CAZyme_annotation \\
        --mode protein \\
        --input_raw_data $fasta \\
        --output_dir ${prefix}_dbcan \\
        --db_dir $db \\
        --threads $task.cpus \\
        $args

    # Output file names changed between v4 and v5, so match on a pattern rather
    # than hard-coding a name.
    cp "\$(ls ${prefix}_dbcan/*overview* | head -1)" ${prefix}.overview.txt
    cp "\$(ls ${prefix}_dbcan/*hmmer*   2>/dev/null | head -1)" ${prefix}.hmmer.out   2>/dev/null || true
    cp "\$(ls ${prefix}_dbcan/*diamond* 2>/dev/null | head -1)" ${prefix}.diamond.out 2>/dev/null || true

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dbcan: \$( run_dbcan --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "5.2.9" )
    END_VERSIONS
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.overview.txt
    touch ${prefix}.hmmer.out
    touch ${prefix}.diamond.out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dbcan2: "stub"
    END_VERSIONS
    """
}
