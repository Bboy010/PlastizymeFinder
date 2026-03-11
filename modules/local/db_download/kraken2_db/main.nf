/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: KRAKEN2_DB_DOWNLOAD
    Downloads and builds Kraken2 standard database if not provided by user
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
    kraken2-build --download-taxonomy --db kraken2_db
    kraken2-build --download-library bacteria --db kraken2_db
    kraken2-build --download-library archaea  --db kraken2_db
    kraken2-build --download-library viral    --db kraken2_db
    kraken2-build --build --db kraken2_db --threads ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken2: \$(kraken2 --version 2>&1 | head -n1 | sed 's/Kraken version //')
    END_VERSIONS
    """
}
