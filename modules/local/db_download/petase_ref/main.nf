/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: PETASE_REF_DOWNLOAD
    Downloads the default PETase reference structure from RCSB PDB
    Default: 6EQE — IsPETase from Ideonella sakaiensis (wild-type)
    User can override with --petase_ref /path/to/custom.pdb
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process PETASE_REF_DOWNLOAD {
    tag "6EQE"
    label 'process_single'

    conda "conda-forge::wget=1.21.4"
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/wget:1.21.4' :
        'biocontainers/wget:1.21.4' }"

    output:
    path '*.pdb',        emit: pdb
    path 'versions.yml', emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def pdb_id = task.ext.pdb_id ?: '6EQE'
    """
    wget -q "https://files.rcsb.org/download/${pdb_id}.pdb" -O ${pdb_id}.pdb

    # Verify download
    if [ ! -s ${pdb_id}.pdb ]; then
        echo "ERROR: Failed to download ${pdb_id}.pdb from RCSB" >&2
        exit 1
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: \$( wget --version | head -1 | sed 's/GNU Wget //' | sed 's/ .*//' )
        pdb_id: "${pdb_id}"
        source: "https://files.rcsb.org/download/${pdb_id}.pdb"
    END_VERSIONS
    """

    stub:
    def pdb_id = task.ext.pdb_id ?: '6EQE'
    """
    touch ${pdb_id}.pdb
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: 1.21.4
        pdb_id: "${pdb_id}"
    END_VERSIONS
    """
}
