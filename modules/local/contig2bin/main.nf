/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: CONTIG2BIN
    Writes the contig-to-bin table DAS Tool takes as input, from one binner's
    bin FASTAs. Replaces nf-core's DASTOOL_FASTATOCONTIG2BIN, which gunzips a
    single file and so cannot take the mixed .fa / .fa.gz / .fasta.gz bins
    MetaBAT2, MaxBin2 and CONCOCT write. The bin label is the file name without
    its extensions, so it keeps the sample ID and stays unique across samples.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process CONTIG2BIN {
    tag "${meta.id}-${binner}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] ?
        'https://depot.galaxyproject.org/singularity/das_tool:1.1.7--r44hdfd78af_1' :
        'quay.io/biocontainers/das_tool:1.1.7--r44hdfd78af_1' }"

    input:
    tuple val(meta), path(bins, stageAs: 'bins/*'), val(binner)

    output:
    tuple val(meta), path("*.contig2bin.tsv"), emit: tsv
    path "versions.yml",                        emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}.${binner}"
    """
    # Not zcat -f: BusyBox zcat, which some images ship, prints nothing for a
    # file that is not gzipped instead of passing it through.
    for f in bins/*; do
        label=\$(basename "\$f" | sed -E 's/\\.gz\$//; s/\\.(fa|fasta|fna)\$//')
        case "\$f" in *.gz) gzip -dc "\$f" ;; *) cat "\$f" ;; esac \\
            | awk -v bin="\$label" '/^>/ { sub(/^>/, ""); print \$1 "\\t" bin }'
    done > ${prefix}.contig2bin.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: "\$( (awk --version 2>/dev/null || busybox 2>&1) | head -1 | sed -E 's/[,(].*//; s/ +\$//' )"
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}.${binner}"
    """
    printf 'contig_1\\t${meta.id}.${binner}.1\\n' > ${prefix}.contig2bin.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: "stub"
    END_VERSIONS
    """
}
