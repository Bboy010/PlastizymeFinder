process GTDBTK_CLASSIFYWF {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::gtdbtk=2.4.0'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/gtdbtk:2.4.0--pyhdfd78af_1' :
        'biocontainers/gtdbtk:2.4.0--pyhdfd78af_1' }"

    input:
    tuple val(meta), path(bins, stageAs: 'input_bins/*')
    path  db

    output:
    tuple val(meta), path('gtdbtk_output/'),                                           emit: results
    tuple val(meta), path('gtdbtk_output/*.summary.tsv'),   optional: true,            emit: summary
    tuple val(meta), path('gtdbtk_output/*.backbone.classify.tree'), optional: true,   emit: tree
    path  'versions.yml',                                                               emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    export GTDBTK_DATA_PATH=$db

    gtdbtk classify_wf \\
        --genome_dir input_bins \\
        --out_dir gtdbtk_output \\
        --extension fa \\
        --cpus $task.cpus \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk: \$( gtdbtk --version | sed 's/gtdbtk: //' | sed 's/ (.*//' )
    END_VERSIONS
    """
}
