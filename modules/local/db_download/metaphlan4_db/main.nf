/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: METAPHLAN4_DB_DOWNLOAD
    Downloads MetaPhlAn4 database if not provided by user
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process METAPHLAN4_DB_DOWNLOAD {
    label 'process_single'
    label 'error_retry'

    storeDir "${cache_dir}/metaphlan4"

    conda "bioconda::metaphlan=4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metaphlan:4.1.0--pyhca03a8a_0' :
        'quay.io/biocontainers/metaphlan:4.1.0--pyhca03a8a_0' }"

    input:
    val cache_dir

    output:
    path "metaphlan4_db", type: 'dir', emit: db
    path "versions.yml",               emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    metaphlan --install --bowtie2db metaphlan4_db

    # storeDir keeps whatever this task leaves behind, and a later run treats it
    # as a finished database. Refuse to hand over an empty or truncated one.
    tiny=\$(find metaphlan4_db -type f -size -1k 2>/dev/null | head -5)
    if [ -n "\$tiny" ]; then
        echo "ERROR: MetaPhlAn download incomplete - suspiciously small files:" >&2
        echo "\$tiny" >&2
        exit 1
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(metaphlan --version 2>&1 | sed 's/MetaPhlAn version //')
    END_VERSIONS
    """
    stub:
    """
    mkdir -p metaphlan4_db

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan4_db_download: "stub"
    END_VERSIONS
    """
}
