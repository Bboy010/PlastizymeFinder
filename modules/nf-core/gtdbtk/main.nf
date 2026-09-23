process GTDBTK_CLASSIFYWF {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::gtdbtk=2.4.0 "pydantic<2" "python<3.12" "numpy<2"'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/gtdbtk:2.4.0--pyhdfd78af_1' :
        'quay.io/biocontainers/gtdbtk:2.4.0--pyhdfd78af_1' }"

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
    """
    export GTDBTK_DATA_PATH=\$(realpath $db)

    # pplacer loads the full reference tree into RAM (R226: ~89 GB) unless
    # told to spill to disk. Confirmed by an OOM kill (memcg) on a 28 GB
    # container with 7 genomes: pplacer's rss hit 29 GB before the kernel
    # killed it, mid-way through caching the tree. --scratch_dir trades speed
    # for staying inside ordinary workstation memory.
    mkdir -p gtdbtk_scratch
    gtdbtk classify_wf \\
        --genome_dir input_bins \\
        --out_dir gtdbtk_output \\
        --extension fa \\
        --cpus $task.cpus \\
        --scratch_dir gtdbtk_scratch \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk: \$( gtdbtk --version | sed 's/gtdbtk: //' | sed 's/ (.*//' )
    END_VERSIONS
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p gtdbtk_output
    touch gtdbtk_output/
    touch gtdbtk_output/${prefix}.summary.tsv
    touch gtdbtk_output/${prefix}.backbone.classify.tree

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk_classifywf: "stub"
    END_VERSIONS
    """
}
