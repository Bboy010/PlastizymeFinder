process PRODIGAL {
    tag "$meta.id"
    label 'process_medium'

    conda 'bioconda::prodigal=2.6.3'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/prodigal:2.6.3--hec16e2b_5' :
        'biocontainers/prodigal:2.6.3--hec16e2b_5' }"

    input:
    tuple val(meta), path(fasta)
    val   output_format

    output:
    tuple val(meta), path('*.gff'),              emit: gene_annotations
    tuple val(meta), path('*.faa'),              emit: amino_acid_fasta
    tuple val(meta), path('*.fna'),              emit: nucleotide_fasta
    tuple val(meta), path('*.txt'),              emit: all_gene_annotations
    path  'versions.yml',                        emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def format = output_format    ?: 'gff'
    """
    prodigal \\
        -i $fasta \\
        -a ${prefix}.faa \\
        -d ${prefix}.fna \\
        -o ${prefix}.${format} \\
        -f ${format} \\
        -s ${prefix}.txt \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        prodigal: \$( prodigal -v 2>&1 | sed -n 's/Prodigal V\\([0-9.]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
