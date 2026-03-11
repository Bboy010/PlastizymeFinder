/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: TMALIGN
    Structural comparison of predicted structures against known PETase reference PDBs
    Computes TM-score and RMSD for each predicted structure
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process TMALIGN {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::tmalign"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/tmalign:20190822' :
        'quay.io/biocontainers/tmalign:20190822--h9f5acd7_1' }"

    input:
    tuple val(meta), path(pdb_structures)
    path  ref_pdb   // Reference PETase PDB — default 6EQE (IsPETase, Ideonella sakaiensis)
                    // Override with: --petase_ref /path/to/custom.pdb

    output:
    tuple val(meta), path("${meta.id}_tmalign_results.tsv"), emit: results
    path "versions.yml",                                      emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args     = task.ext.args ?: ''
    def prefix   = task.ext.prefix ?: "${meta.id}"
    def ref_name = ref_pdb.baseName
    """
    echo -e "query\\treference\\ttm_score_query\\ttm_score_ref\\trmsd\\taligned_length" > ${prefix}_tmalign_results.tsv

    for query_pdb in ${pdb_structures}/*.pdb; do
        query_name=\$(basename \$query_pdb .pdb)
        result=\$(TMalign \$query_pdb ${ref_pdb} ${args} | \\
            grep -E "^TM-score|^RMSD|Aligned length" | \\
            awk 'BEGIN{OFS="\\t"} /Aligned/{al=\$3} /TM-score.*Chain_1/{tm1=\$2} /TM-score.*Chain_2/{tm2=\$2} /RMSD/{rmsd=\$5} END{print al, tm1, tm2, rmsd}')
        echo -e "\${query_name}\\t${ref_name}\\t\${result}" >> ${prefix}_tmalign_results.tsv
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tmalign: \$(TMalign --version 2>&1 | head -n1 | sed 's/TM-align version //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_tmalign_results.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tmalign: 20190822
    END_VERSIONS
    """
}
