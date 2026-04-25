process QUAST {
    tag "$meta.id"
    label 'process_medium'

    conda 'bioconda::quast=5.2.0'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/quast:5.2.0--py39pl5321h2add14b_1' :
        'biocontainers/quast:5.2.0--py39pl5321h2add14b_1' }"

    input:
    tuple val(meta), path(consensus)
    path  fasta
    path  gff

    output:
    tuple val(meta), path("${prefix}"),         emit: results
    tuple val(meta), path('*.tsv'),             emit: tsv
    tuple val(meta), path('*.html'),            optional: true, emit: html
    path  'versions.yml',                       emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    prefix     = task.ext.prefix ?: "${meta.id}"
    def input  = consensus.collect { it }.join(' ')
    def ref    = fasta ? "--reference ${fasta}" : ''
    def annot  = gff   ? "--features ${gff}"   : ''
    """
    quast.py \\
        --output-dir ${prefix} \\
        --threads $task.cpus \\
        $ref \\
        $annot \\
        $args \\
        $input

    # Expose report.tsv at the top level for MultiQC
    cp ${prefix}/report.tsv ${prefix}.report.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quast: \$( quast.py --version 2>&1 | sed 's/QUAST v//' )
    END_VERSIONS
    """
}
