/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: DBCAN2_DB_DOWNLOAD
    Downloads dbCAN2 CAZyme database if not provided by user
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process DBCAN2_DB_DOWNLOAD {
    label 'process_single'
    label 'error_retry'

    storeDir "${cache_dir}/dbcan2"

    conda "bioconda::dbcan"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/dbcan:4.0.0--pyhdfd78af_0' :
        'quay.io/biocontainers/dbcan:4.0.0--pyhdfd78af_0' }"

    input:
    val cache_dir

    output:
    path "dbcan2_db", type: 'dir', emit: db
    path "versions.yml",           emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    mkdir -p dbcan2_db
    cd dbcan2_db
    wget -q https://pro.unl.edu/dbCAN2/download/Databases/V12/CAZyDB.07262023.fa
    wget -q https://pro.unl.edu/dbCAN2/download/Databases/V12/dbCAN-HMMdb-V12.txt
    wget -q https://pro.unl.edu/dbCAN2/download/Databases/V12/tcdb.fa
    wget -q https://pro.unl.edu/dbCAN2/download/Databases/V12/tf-1.hmm
    wget -q https://pro.unl.edu/dbCAN2/download/Databases/V12/tf-2.hmm
    wget -q https://pro.unl.edu/dbCAN2/download/Databases/V12/stp.hmm
    diamond makedb --in CAZyDB.07262023.fa -d CAZyDB
    hmmpress dbCAN-HMMdb-V12.txt
    cd ..

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dbcan: \$(run_dbcan --version 2>&1 | head -n1)
    END_VERSIONS
    """
}
