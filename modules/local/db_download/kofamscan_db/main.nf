/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: KOFAMSCAN_DB_DOWNLOAD
    Downloads KofamScan HMM profiles (KEGG KO) if not provided by user
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process KOFAMSCAN_DB_DOWNLOAD {
    label 'process_single'
    label 'error_retry'

    storeDir "${cache_dir}/kofamscan"

    conda "bioconda::kofamscan"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kofamscan:1.3.0--hdfd78af_2' :
        'quay.io/biocontainers/kofamscan:1.3.0--hdfd78af_2' }"

    input:
    val cache_dir

    output:
    path "kofamscan_db", type: 'dir', emit: db
    path "versions.yml",              emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    mkdir -p kofamscan_db
    wget -q https://www.genome.jp/ftp/db/kofam/ko_list.gz        -O kofamscan_db/ko_list.gz
    wget -q https://www.genome.jp/ftp/db/kofam/profiles.tar.gz   -O kofamscan_db/profiles.tar.gz
    gunzip  kofamscan_db/ko_list.gz
    tar -xzf kofamscan_db/profiles.tar.gz -C kofamscan_db/
    rm kofamscan_db/profiles.tar.gz

    # storeDir keeps whatever this task leaves behind, and a later run treats it
    # as a finished database. Refuse to hand over an empty or truncated one.
    tiny=\$(find kofamscan_db -type f -size -1k 2>/dev/null | head -5)
    if [ -n "\$tiny" ]; then
        echo "ERROR: KofamScan download incomplete - suspiciously small files:" >&2
        echo "\$tiny" >&2
        exit 1
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kofamscan: \$(exec_annotation --version 2>&1 | sed 's/KofamScan //')
    END_VERSIONS
    """
    stub:
    """
    mkdir -p kofamscan_db

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kofamscan_db_download: "stub"
    END_VERSIONS
    """
}
