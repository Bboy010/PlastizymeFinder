/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: KRAKEN2_DB_DOWNLOAD
    Fetches a pre-built Kraken2 index when the user supplies no database.

    Building the standard database locally is not a realistic default: it
    downloads over 100 GB of genomes and its build step needs far more memory
    than a workstation has. The pre-built indexes published alongside Kraken2
    are the same data, already built, and the capped 8 GB standard index keeps
    the pipeline runnable on ordinary hardware. Override params.kraken2_db_url
    to pick a different index, or params.kraken2_db to use your own.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process KRAKEN2_DB_DOWNLOAD {
    label 'process_single'
    label 'error_retry'

    storeDir "${cache_dir}/kraken2"

    conda "bioconda::kraken2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kraken2:2.1.3--pl5321hdcf5f25_0' :
        'quay.io/biocontainers/kraken2:2.1.3--pl5321hdcf5f25_0' }"

    input:
    val cache_dir

    output:
    path "kraken2_db", type: 'dir', emit: db
    path "versions.yml",            emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    wget --no-verbose -O kraken2_db.tar.gz '${params.kraken2_db_url}'

    mkdir -p kraken2_db
    tar -xzf kraken2_db.tar.gz -C kraken2_db --strip-components=0
    rm kraken2_db.tar.gz

    # Some archives carry the index in a subdirectory: flatten it so the path
    # this module emits is always a usable Kraken2 database.
    if [ ! -f kraken2_db/taxo.k2d ]; then
        found=\$(find kraken2_db -name taxo.k2d -print -quit)
        if [ -n "\$found" ]; then
            mv "\$(dirname "\$found")"/* kraken2_db/
        fi
    fi

    for required in hash.k2d opts.k2d taxo.k2d; do
        if [ ! -f "kraken2_db/\$required" ]; then
            echo "ERROR: \$required missing - '${params.kraken2_db_url}' is not a Kraken2 index" >&2
            exit 1
        fi
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken2: \$(kraken2 --version 2>&1 | head -n1 | sed 's/Kraken version //')
        kraken2_db_url: '${params.kraken2_db_url}'
    END_VERSIONS
    """
    stub:
    """
    mkdir -p kraken2_db
    touch kraken2_db/hash.k2d kraken2_db/opts.k2d kraken2_db/taxo.k2d

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken2_db_download: "stub"
    END_VERSIONS
    """
}
