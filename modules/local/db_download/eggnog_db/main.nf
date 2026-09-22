/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: EGGNOG_DB_DOWNLOAD
    Downloads eggNOG database if not provided by user (~50 GB)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process EGGNOG_DB_DOWNLOAD {
    label 'process_single'
    label 'error_retry'

    storeDir "${cache_dir}/eggnog"

    conda "bioconda::eggnog-mapper"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eggnog-mapper:2.1.12--pyhdfd78af_0' :
        'quay.io/biocontainers/eggnog-mapper:2.1.12--pyhdfd78af_0' }"

    input:
    val cache_dir

    output:
    path "eggnog_db", type: 'dir', emit: db
    path "versions.yml",           emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    mkdir -p eggnog_db
    download_eggnog_data.py --data_dir eggnog_db -y

    # storeDir keeps whatever this task leaves behind, and a later run treats it
    # as a finished database. Refuse to hand over an empty or truncated one.
    tiny=\$(find eggnog_db -type f -size -1k 2>/dev/null | head -5)
    if [ -n "\$tiny" ]; then
        echo "ERROR: eggNOG download incomplete - suspiciously small files:" >&2
        echo "\$tiny" >&2
        exit 1
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eggnog-mapper: \$(emapper.py --version 2>&1 | grep -oE 'emapper-[0-9.]+' | head -n1 | sed 's/emapper-//' || echo 'unknown')
    END_VERSIONS
    """
    stub:
    """
    mkdir -p eggnog_db

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eggnog_db_download: "stub"
    END_VERSIONS
    """
}
