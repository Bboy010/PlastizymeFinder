/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: CHECKM2_DB_DOWNLOAD
    Downloads the CheckM2 DIAMOND reference database when the user supplies none.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process CHECKM2_DB_DOWNLOAD {
    label 'process_single'
    label 'error_retry'

    storeDir "${cache_dir}/checkm2"

    conda 'bioconda::checkm2=1.0.2'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/checkm2:1.0.2--pyh7cba7a3_0' :
        'quay.io/biocontainers/checkm2:1.0.2--pyh7cba7a3_0' }"

    input:
    val cache_dir

    output:
    path "checkm2_db", type: 'dir', emit: db
    path "versions.yml",            emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    checkm2 database --download --path checkm2_db

    # storeDir keeps whatever this task leaves behind, and a later run treats
    # it as a finished database. Refuse to hand over a truncated one - the
    # real DIAMOND database is on the order of 3 GB.
    dmnd=\$(find checkm2_db -name '*.dmnd' -print -quit)
    if [ -z "\$dmnd" ] || [ \$(stat -c%s "\$dmnd") -lt 1000000000 ]; then
        echo "ERROR: CheckM2 database download incomplete or missing" >&2
        exit 1
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkm2: \$( checkm2 --version 2>&1 | tail -n1 )
    END_VERSIONS
    """
    stub:
    """
    mkdir -p checkm2_db

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkm2_db_download: "stub"
    END_VERSIONS
    """
}
