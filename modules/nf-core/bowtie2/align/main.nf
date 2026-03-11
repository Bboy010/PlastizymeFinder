process BOWTIE2_ALIGN {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::bowtie2=2.5.3 bioconda::samtools=1.19'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-ac74a7f02cebcfcc07d8e8d1a750d2acf4f99599:f70b2a4d0353cdd6dc64edde26e0b8f6' :
        'biocontainers/mulled-v2-ac74a7f02cebcfcc07d8e8d1a750d2acf4f99599:f70b2a4d0353cdd6dc64edde26e0b8f6' }"

    input:
    tuple val(meta), path(reads)
    tuple val(meta2), path(index)
    val   save_unaligned
    val   sort_bam

    output:
    tuple val(meta), path('*.bam'),             emit: bam
    tuple val(meta), path('*.bam.bai'),         optional: true, emit: bai
    tuple val(meta), path('*.log'),             emit: log
    tuple val(meta), path('*.fastq.gz'),        optional: true, emit: fastq
    path  'versions.yml',                       emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args          = task.ext.args   ?: ''
    def prefix        = task.ext.prefix ?: "${meta.id}"
    def unaligned_arg = save_unaligned  ?
        (meta.single_end ? "--un-gz ${prefix}.unmapped.fastq.gz" :
                           "--un-conc-gz ${prefix}.unmapped_%.fastq.gz") : ''
    def in_reads      = meta.single_end ?
        "-U ${reads[0]}" :
        "-1 ${reads[0]} -2 ${reads[1]}"
    def samtools_sort = sort_bam ? 'samtools sort' : 'samtools view -bS'
    """
    INDEX=\$(find -L ./ -name "*.rev.1.bt2" | sed 's/\\.rev\\.1\\.bt2\$//')
    [ -z "\$INDEX" ] && INDEX=\$(find -L ./ -name "*.rev.1.bt2l" | sed 's/\\.rev\\.1\\.bt2l\$//')

    bowtie2 \\
        -x \$INDEX \\
        $in_reads \\
        $unaligned_arg \\
        --threads $task.cpus \\
        $args \\
        2> ${prefix}.bowtie2.log \\
    | ${samtools_sort} -@ $task.cpus -o ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2: \$( bowtie2 --version | head -1 | sed 's/.*bowtie2-align-s version //' )
        samtools: \$( samtools --version | head -1 | sed 's/samtools //' )
    END_VERSIONS
    """
}
