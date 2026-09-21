process MEGAHIT {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::megahit=1.2.9'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/megahit:1.2.9--h5b5514e_2' :
        'quay.io/biocontainers/megahit:1.2.9--h5b5514e_2' }"

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
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # A plausible assembly, not an empty archive: downstream stages branch on
    # whether a sample produced contigs, and an empty stub would make every
    # stub run look like a failed assembly. The content is high-entropy on
    # purpose - the branch tests the compressed size, and a run of identical
    # bases would gzip down to a few dozen bytes and read as empty.
    {
        echo ">${prefix}_contig_1 len=2040"
        head -c 4000 /dev/urandom | base64 | head -c 3000 | fold -w 60
    } | gzip > ${prefix}.contigs.fa.gz
    touch ${prefix}.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        megahit: "stub"
    END_VERSIONS
    """
}
