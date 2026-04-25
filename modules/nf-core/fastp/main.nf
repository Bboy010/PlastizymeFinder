process FASTP {
    tag "$meta.id"
    label 'process_medium'

    conda 'bioconda::fastp=0.23.4'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/fastp:0.23.4--h5f740d0_0' :
        'biocontainers/fastp:0.23.4--h5f740d0_0' }"

    input:
    tuple val(meta), path(reads)
    path  adapter_fasta
    val   save_trimmed_fail
    val   save_merged

    output:
    tuple val(meta), path('*.fastp.fastq.gz'),  emit: reads
    tuple val(meta), path('*.json'),             emit: json
    tuple val(meta), path('*.html'),             emit: html
    tuple val(meta), path('*.log'),              emit: log
    tuple val(meta), path('*.fail.fastq.gz'),    optional: true, emit: reads_fail
    tuple val(meta), path('*.merged.fastq.gz'),  optional: true, emit: reads_merged
    path 'versions.yml',                         emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args   ?: ''
    def prefix      = task.ext.prefix ?: "${meta.id}"
    def adapter_arg = adapter_fasta   ? "--adapter_fasta ${adapter_fasta}" : ''
    def fail_arg    = save_trimmed_fail ? '--failed_out ${prefix}.fail.fastq.gz' : ''
    def in_reads    = meta.single_end  ?
        "--in1 ${reads[0]}" :
        "--in1 ${reads[0]} --in2 ${reads[1]}"
    def out_reads   = meta.single_end  ?
        "--out1 ${prefix}.fastp.fastq.gz" :
        "--out1 ${prefix}_1.fastp.fastq.gz --out2 ${prefix}_2.fastp.fastq.gz"
    """
    fastp \\
        $in_reads \\
        $out_reads \\
        $adapter_arg \\
        $fail_arg \\
        --json ${prefix}.fastp.json \\
        --html ${prefix}.fastp.html \\
        --thread $task.cpus \\
        $args \\
        2> ${prefix}.fastp.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$( fastp --version 2>&1 | sed -e 's/fastp //g' )
    END_VERSIONS
    """
}
