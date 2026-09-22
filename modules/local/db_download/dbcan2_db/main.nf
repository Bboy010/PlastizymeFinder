/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: DBCAN2_DB_DOWNLOAD
    Downloads the dbCAN CAZyme database when the user supplies none.

    Pinned to dbCAN 3, the last line that reads a plain HMMdb + DIAMOND
    database directory. dbCAN 4 and 5 refuse to start unless dbCAN_sub.hmm is
    present, which this layout does not provide.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process DBCAN2_DB_DOWNLOAD {
    label 'process_single'
    label 'error_retry'

    storeDir "${cache_dir}/dbcan2"

    conda "bioconda::dbcan"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/dbcan:3.0.7--pyh5e36f6f_0' :
        'quay.io/biocontainers/dbcan:3.0.7--pyh5e36f6f_0' }"

    input:
    val cache_dir

    output:
    path "dbcan2_db", type: 'dir', emit: db
    path "versions.yml",           emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def base = 'https://pro.unl.edu/dbCAN2/download/Databases/V12'
    """
    mkdir -p dbcan2_db
    cd dbcan2_db
    wget -q ${base}/CAZyDB.07262023.fa
    wget -q ${base}/dbCAN-HMMdb-V12.txt
    wget -q ${base}/tcdb.fa
    wget -q ${base}/tf-1.hmm
    wget -q ${base}/tf-2.hmm
    wget -q ${base}/stp.hmm
    diamond makedb --in CAZyDB.07262023.fa -d CAZy
    hmmpress dbCAN-HMMdb-V12.txt
    cd ..

    # storeDir keeps whatever this task leaves behind, and a later run treats
    # it as a finished database. Refuse to hand over an incomplete one.
    tiny=\$(find dbcan2_db -type f -size -1k 2>/dev/null | head -5)
    if [ -n "\$tiny" ]; then
        echo "ERROR: dbCAN download incomplete - suspiciously small files:" >&2
        echo "\$tiny" >&2
        exit 1
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dbcan: \$(run_dbcan --version 2>&1 | head -n1)
    END_VERSIONS
    """
    stub:
    """
    mkdir -p dbcan2_db

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dbcan2_db_download: "stub"
    END_VERSIONS
    """
}
