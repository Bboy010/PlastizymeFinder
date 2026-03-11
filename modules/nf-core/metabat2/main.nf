process METABAT2 {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::metabat2=2.17'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/metabat2:2.17--h4da6f23_0' :
        'biocontainers/metabat2:2.17--h4da6f23_0' }"

    input:
    tuple val(meta), path(fasta)
    tuple val(meta2), path(bam)

    output:
    tuple val(meta), path('bins/*.fa'),          emit: bins
    tuple val(meta), path('*.unbinned.fa'),      optional: true, emit: unbinned
    tuple val(meta), path('*.depth.txt'),        emit: depth
    path  'versions.yml',                        emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Compute contig depth from BAM files
    jgi_summarize_bam_contig_depths \\
        --outputDepth ${prefix}.depth.txt \\
        $bam

    # Run MetaBAT2 binning
    mkdir -p bins
    metabat2 \\
        -i $fasta \\
        -a ${prefix}.depth.txt \\
        -o bins/${prefix}.bin \\
        -t $task.cpus \\
        $args

    # Collect unbinned contigs
    # (sequences in fasta not present in any bin)
    cat bins/${prefix}.bin.*.fa 2>/dev/null | \\
        grep '^>' | sed 's/>//' | sort > binned_ids.txt
    python3 -c "
    import sys
    binned = set(open('binned_ids.txt').read().split())
    out = open('${prefix}.unbinned.fa', 'w')
    fasta = open('$fasta')
    write = False
    for line in fasta:
        if line.startswith('>'):
            write = line[1:].split()[0] not in binned
        if write:
            out.write(line)
    out.close()
    "

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metabat2: \$( metabat2 --help 2>&1 | head -1 | sed 's/.*version //' | sed 's/ .*//' )
    END_VERSIONS
    """
}
