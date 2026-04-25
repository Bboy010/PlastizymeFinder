process MEGAHIT {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::megahit=1.2.9'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/megahit:1.2.9--h5b5514e_2' :
        'biocontainers/megahit:1.2.9--h5b5514e_2' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.contigs.fa.gz'), emit: contigs
    tuple val(meta), path('*.log'),           emit: log
    path  'versions.yml',                     emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def in_reads = meta.single_end ?
        "-r ${reads[0]}" :
        "-1 ${reads[0]} -2 ${reads[1]}"
    """
    megahit \\
        $in_reads \\
        -o ${prefix}_megahit \\
        --num-cpu-threads $task.cpus \\
        $args \\
        2>&1 | tee ${prefix}.megahit.log

    # Compress and rename final contigs
    gzip -c ${prefix}_megahit/final.contigs.fa > ${prefix}.contigs.fa.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        megahit: \$( megahit --version | sed 's/MEGAHIT v//' )
    END_VERSIONS
    """
}
