/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: GUNZIP_BINS
    Writes every bin of a sample as plain FASTA under a .fa name. Bins from
    another pipeline come gzipped and named .fa.gz / .fasta / .fna (nf-core/mag:
    MEGAHIT-MetaBAT2-sample.1.fa.gz), while CheckM2 (-x fa) and dRep
    (input_bins/*.fa) in stage 5 only pick up *.fa.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process GUNZIP_BINS {
    tag "${meta.id}"
    label 'process_single'

    // Same image as EXTRACT_UNBINNED: only zcat and sed are needed.
    conda 'bioconda::metabat2=2.17'
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] ?
        'https://depot.galaxyproject.org/singularity/metabat2:2.17--h4da6f23_0' :
        'quay.io/biocontainers/metabat2:2.18--h6f16272_0' }"

    input:
    tuple val(meta), path(bins, stageAs: 'input/*')

    output:
    tuple val(meta), path("bins/*.fa"), emit: bins
    path "versions.yml",                emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    mkdir -p bins
    for f in input/*; do
        name=\$(basename "\$f" | sed -E 's/\\.gz\$//; s/\\.(fa|fasta|fna)\$//')
        # Not zcat -f: this image's zcat is BusyBox, which prints nothing for
        # a file that is not gzipped instead of passing it through.
        case "\$f" in *.gz) gzip -dc "\$f" ;; *) cat "\$f" ;; esac > "bins/\${name}.fa"
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gzip: "\$( (gzip --version 2>/dev/null || busybox 2>&1) | head -1 | sed -E 's/^gzip //; s/[,(].*//; s/ +\$//' )"
    END_VERSIONS
    """

    stub:
    """
    mkdir -p bins
    touch bins/${meta.id}.1.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gzip: "stub"
    END_VERSIONS
    """
}
