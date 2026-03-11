process KRAKEN2 {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::kraken2=2.1.3 bioconda::krakentools=1.2'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-5799ab18b5fc678e5ddc5b14f99c9254caacacd7:d36906b073db2c9e71edd5a34e47ce56d95d8f74-0' :
        'biocontainers/mulled-v2-5799ab18b5fc678e5ddc5b14f99c9254caacacd7:d36906b073db2c9e71edd5a34e47ce56d95d8f74-0' }"

    input:
    tuple val(meta), path(reads)
    path  db
    val   save_output_fastqs
    val   save_reads_assignment

    output:
    tuple val(meta), path('*.classified*.fastq.gz'),   optional: true, emit: classified_reads_fastq
    tuple val(meta), path('*.unclassified*.fastq.gz'), optional: true, emit: unclassified_reads_fastq
    tuple val(meta), path('*classifiedreads.txt'),     optional: true, emit: classified_reads_assignment
    tuple val(meta), path('*report.txt'),              emit: report
    path  'versions.yml',                              emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args             = task.ext.args   ?: ''
    def prefix           = task.ext.prefix ?: "${meta.id}"
    def paired_arg       = meta.single_end ? '' : '--paired'
    def classified_arg   = save_output_fastqs ?
        (meta.single_end ? "--classified-out ${prefix}.classified.fastq" :
                           "--classified-out ${prefix}.classified#.fastq") : ''
    def unclassified_arg = save_output_fastqs ?
        (meta.single_end ? "--unclassified-out ${prefix}.unclassified.fastq" :
                           "--unclassified-out ${prefix}.unclassified#.fastq") : ''
    def readclass_arg    = save_reads_assignment ? "--output ${prefix}.classifiedreads.txt" : '--output /dev/null'
    """
    kraken2 \\
        --db $db \\
        --threads $task.cpus \\
        --report ${prefix}.kraken2.report.txt \\
        --report-zero-counts \\
        $paired_arg \\
        $classified_arg \\
        $unclassified_arg \\
        $readclass_arg \\
        $args \\
        $reads

    if [ "$save_output_fastqs" = "true" ]; then
        gzip ${prefix}.classified*.fastq 2>/dev/null || true
        gzip ${prefix}.unclassified*.fastq 2>/dev/null || true
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken2: \$( kraken2 --version | head -1 | sed 's/Kraken version //' | sed 's/, Copyright.*//' )
    END_VERSIONS
    """
}
