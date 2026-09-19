/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: CDD_DB_DOWNLOAD
    Downloads the pre-formatted NCBI Conserved Domain Database (CDD) used by
    RPS-BLAST for local conserved-domain annotation — the offline, reproducible
    equivalent of the NCBI Batch CD-Search web service.

    Sets available at https://ftp.ncbi.nlm.nih.gov/pub/mmdb/cdd/little_endian/
      Cdd_LE.tar.gz   ~1.7 GB — full CDD (62,456 models)
      Pfam_LE.tar.gz  ~410 MB — Pfam subset only, suitable for CI and test runs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process CDD_DB_DOWNLOAD {
    tag "${db_set}"
    label 'process_single'
    label 'error_retry'

    storeDir "${cache_dir}/cdd"

    conda "conda-forge::wget=1.21.4"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/wget:1.21.4'
        : 'biocontainers/wget:1.21.4'}"

    input:
    val cache_dir
    val db_set

    output:
    path "cdd_db"      , type: 'dir', emit: db
    path "versions.yml",              emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def ftp_root = 'https://ftp.ncbi.nlm.nih.gov/pub/mmdb/cdd'
    """
    mkdir -p cdd_db

    wget -q "${ftp_root}/little_endian/${db_set}_LE.tar.gz" -O cdd.tar.gz
    if [ ! -s cdd.tar.gz ]; then
        echo "ERROR: failed to download ${db_set}_LE.tar.gz from NCBI" >&2
        exit 1
    fi

    tar -xzf cdd.tar.gz -C cdd_db
    rm cdd.tar.gz

    # RPS-BLAST is pointed at the database *prefix*, not a file: record it once
    # here so downstream modules do not have to guess the naming scheme.
    echo "${db_set}" > cdd_db/db_prefix.txt

    wget -q "${ftp_root}/cdd.info" -O cdd_db/cdd.info || true

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cdd: \$( sed -n 's/^cdd version //p' cdd_db/cdd.info 2>/dev/null | head -n1 || echo "unknown" )
        db_set: "${db_set}"
    END_VERSIONS
    """

    stub:
    """
    mkdir -p cdd_db
    touch cdd_db/${db_set}.loo cdd_db/${db_set}.rps cdd_db/${db_set}.aux
    echo "${db_set}" > cdd_db/db_prefix.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cdd: 3.21
        db_set: "${db_set}"
    END_VERSIONS
    """
}
