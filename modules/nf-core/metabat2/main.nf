process METABAT2 {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::metabat2=2.17'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/metabat2:2.17--h4da6f23_0' :
        'quay.io/biocontainers/metabat2:2.18--h6f16272_0' }"

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

    # Collect unbinned contigs (sequences in the assembly that no bin claimed).
    # awk rather than python: the MetaBAT2 container ships no interpreter.
    cat bins/${prefix}.bin.*.fa 2>/dev/null | \
        awk '/^>/ { sub(/^>/, ""); print \$1 }' | sort -u > binned_ids.txt

    if [[ "${fasta}" == *.gz ]]; then
        decompress="zcat"
    else
        decompress="cat"
    fi

    \$decompress $fasta | awk '
        NR == FNR { binned[\$1] = 1; next }
        /^>/      { id = substr(\$1, 2); keep = !(id in binned) }
        keep      { print }
    ' binned_ids.txt - > ${prefix}.unbinned.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metabat2: \$( metabat2 --help 2>&1 | head -1 | sed 's/.*version //' | sed 's/ .*//' )
    END_VERSIONS
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p bins
    touch bins/${prefix}.fa
    touch ${prefix}.unbinned.fa
    touch ${prefix}.depth.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metabat2: "stub"
    END_VERSIONS
    """
}
