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

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(metaphlan --version 2>&1 | sed 's/MetaPhlAn version //')
    END_VERSIONS
    """
}
