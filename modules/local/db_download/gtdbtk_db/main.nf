/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: GTDBTK_DB_DOWNLOAD
    Downloads GTDB-tk reference data if not provided by user (~70 GB)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process GTDBTK_DB_DOWNLOAD {
    label 'process_single'
    label 'error_retry'

    storeDir "${cache_dir}/gtdbtk"

    conda "bioconda::gtdbtk"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gtdbtk:2.4.0--pyhdfd78af_0' :
        'quay.io/biocontainers/gtdbtk:2.4.0--pyhdfd78af_0' }"

    input:
    val cache_dir

    output:
    path "gtdbtk_db", type: 'dir', emit: db
    path "versions.yml",           emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    mkdir -p gtdbtk_db
    wget -q https://data.gtdb.ecogenomic.org/releases/latest/auxillary_files/gtdbtk_package/full_package/gtdbtk_data.tar.gz
    tar -xzf gtdbtk_data.tar.gz -C gtdbtk_db/ --strip-components=1
    rm gtdbtk_data.tar.gz

    # storeDir keeps whatever this task leaves behind, and a later run treats it
    # as a finished database. Refuse to hand over an empty or truncated one.
    tiny=\$(find gtdbtk_db -type f -size -1k 2>/dev/null | head -5)
    if [ -n "\$tiny" ]; then
        echo "ERROR: GTDB-Tk download incomplete - suspiciously small files:" >&2
        echo "\$tiny" >&2
        exit 1
    fi
    export GTDBTK_DATA_PATH=\$(pwd)/gtdbtk_db

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk: \$(gtdbtk --version 2>&1 | head -n1 | sed 's/gtdbtk: //')
    END_VERSIONS
    """
    stub:
    """
    mkdir -p gtdbtk_db

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk_db_download: "stub"
    END_VERSIONS
    """
}
