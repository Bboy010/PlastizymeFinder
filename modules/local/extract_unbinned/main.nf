/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: EXTRACT_UNBINNED
    Writes the contigs of an assembly that no bin claimed. Stage 7 screens
    these alongside the high-quality bins, so a plastizyme on a contig that
    was never binned is still found. Used after DAS Tool and for bins
    produced by another pipeline (--contigs_input, e.g. nf-core/mag).
    The bin list may be empty: every contig is then written out.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process EXTRACT_UNBINNED {
    tag "${meta.id}"
    label 'process_single'

    // Same image as METABAT2, which runs this exact filter: awk and zcat only.
    conda 'bioconda::metabat2=2.17'
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] ?
        'https://depot.galaxyproject.org/singularity/metabat2:2.17--h4da6f23_0' :
        'quay.io/biocontainers/metabat2:2.18--h6f16272_0' }"

    input:
    tuple val(meta), path(contigs, stageAs: 'assembly/*'), path(bins, stageAs: 'bins/*')

    output:
    tuple val(meta), path("*.unbinned.fa"), emit: unbinned
    path "versions.yml",                     emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Not zcat -f: this image's zcat is BusyBox, which prints nothing for a
    # file that is not gzipped instead of passing it through.
    read_fasta() { case "\$1" in *.gz) gzip -dc "\$1" ;; *) cat "\$1" ;; esac; }

    touch binned_ids.txt
    for f in bins/*; do
        [ -e "\$f" ] || continue
        read_fasta "\$f" | awk '/^>/ { sub(/^>/, ""); print \$1 }'
    done | sort -u > binned_ids.txt

    # Test FILENAME, not NR == FNR: with no bin, binned_ids.txt is empty and
    # NR == FNR would stay true through the assembly, dropping every contig.
    read_fasta ${contigs} | awk '
        FILENAME == "binned_ids.txt" { binned[\$1] = 1; next }
        /^>/      { id = substr(\$1, 2); keep = !(id in binned) }
        keep      { print }
    ' binned_ids.txt - > ${prefix}.unbinned.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: "\$( (awk --version 2>/dev/null || busybox 2>&1) | head -1 | sed -E 's/[,(].*//; s/ +\$//' )"
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.unbinned.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: "stub"
    END_VERSIONS
    """
}
