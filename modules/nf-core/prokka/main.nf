process PROKKA {
    tag "$meta.id"
    label 'process_medium'

    conda 'bioconda::prokka=1.14.6'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/prokka:1.14.6--pl5321hdfd78af_4' :
        'biocontainers/prokka:1.14.6--pl5321hdfd78af_4' }"

    input:
    tuple val(meta), path(fasta)
    val   centre
    val   genus
    val   species
    val   strain
    val   plasmid

    output:
    tuple val(meta), path('*.gff'),   emit: gff
    tuple val(meta), path('*.gbk'),   emit: gbk
    tuple val(meta), path('*.fna'),   emit: fna
    tuple val(meta), path('*.faa'),   emit: faa
    tuple val(meta), path('*.ffn'),   emit: ffn
    tuple val(meta), path('*.sqn'),   emit: sqn
    tuple val(meta), path('*.fsa'),   emit: fsa
    tuple val(meta), path('*.tbl'),   emit: tbl
    tuple val(meta), path('*.err'),   emit: err
    tuple val(meta), path('*.log'),   emit: log
    tuple val(meta), path('*.txt'),   emit: txt
    tuple val(meta), path('*.tsv'),   emit: tsv
    path  'versions.yml',             emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args       = task.ext.args   ?: ''
    def prefix     = task.ext.prefix ?: "${meta.id}"
    def centre_arg = centre  ? "--centre ${centre}"   : ''
    def genus_arg  = genus   ? "--genus ${genus}"     : ''
    def sp_arg     = species ? "--species ${species}" : ''
    def strain_arg = strain  ? "--strain ${strain}"   : ''
    def plasmid_arg = plasmid ? "--plasmid ${plasmid}" : ''
    """
    prokka \\
        --outdir ${prefix} \\
        --prefix ${prefix} \\
        --cpus $task.cpus \\
        $centre_arg \\
        $genus_arg \\
        $sp_arg \\
        $strain_arg \\
        $plasmid_arg \\
        $args \\
        $fasta

    # Expose files at top level
    cp ${prefix}/${prefix}.gff .
    cp ${prefix}/${prefix}.gbk .
    cp ${prefix}/${prefix}.fna .
    cp ${prefix}/${prefix}.faa .
    cp ${prefix}/${prefix}.ffn .
    cp ${prefix}/${prefix}.sqn .
    cp ${prefix}/${prefix}.fsa .
    cp ${prefix}/${prefix}.tbl .
    cp ${prefix}/${prefix}.err .
    cp ${prefix}/${prefix}.log .
    cp ${prefix}/${prefix}.txt .
    cp ${prefix}/${prefix}.tsv .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        prokka: \$( prokka --version 2>&1 | sed 's/prokka //' )
    END_VERSIONS
    """
}
