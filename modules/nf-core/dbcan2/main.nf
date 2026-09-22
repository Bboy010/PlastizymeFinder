process DBCAN2 {
    tag "$meta.id"
    label 'process_high'

    // Pinned to dbCAN 3, the last line that reads a plain HMMdb + DIAMOND
    // directory. Verified against image 3.0.7: 4.x and 5.x abort with
    // "No dbCAN_sub HMM database found" whatever --tools is set to, so they
    // cannot annotate against a database that has no dbCAN_sub.hmm.
    conda 'bioconda::dbcan=3.0.7'
    container "${workflow.containerEngine in ['singularity', 'apptainer']
        ? 'https://depot.galaxyproject.org/singularity/dbcan:3.0.7--pyh5e36f6f_0'
        : 'quay.io/biocontainers/dbcan:3.0.7--pyh5e36f6f_0'}"

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
    # The HMMdb carries its release in the filename (V8, V12, ...), so find it
    # rather than hard-coding a version the database may not be.
    hmmdb=\$(cd $db && ls dbCAN-HMMdb-*.txt 2>/dev/null | head -1)
    if [ -z "\$hmmdb" ]; then
        echo "ERROR: no dbCAN-HMMdb-*.txt in $db" >&2
        exit 1
    fi

    run_dbcan $fasta protein \
        --db_dir $db \
        --dbCANFile "\$hmmdb" \
        --tools hmmer diamond \
        --out_dir ${prefix}_dbcan \
        --dbcan_thread $task.cpus \
        $args

    cp ${prefix}_dbcan/overview.txt ${prefix}.overview.txt
    cp ${prefix}_dbcan/hmmer.out    ${prefix}.hmmer.out   2>/dev/null || true
    cp ${prefix}_dbcan/diamond.out  ${prefix}.diamond.out 2>/dev/null || true

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dbcan: \$( run_dbcan --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo '3.0.7' )
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
