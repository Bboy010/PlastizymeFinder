/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: PLOT_REPORT
    Renders the figure set from the raw outputs the pipeline already produced:
    taxonomic composition, rank resolution, MetaPhlAn profile, bin similarity,
    bin quality, assembly statistics and read QC.

    It also writes a Krona-format text file so an ImportText step can turn the
    Kraken2 classification into the interactive sunburst.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process PLOT_REPORT {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/matplotlib:3.5.1'
        : 'quay.io/biocontainers/matplotlib:3.5.1'}"

    input:
    // Each report is staged where the plotting script expects it, so the module
    // reads pipeline channels rather than the published results directory.
    tuple val(meta), path(kraken_report, stageAs: 'results/taxonomy/kraken2/*')
    path metaphlan_profile, stageAs: 'results/taxonomy/metaphlan4/*'
    path quast_tsv        , stageAs: 'results/assembly/quast/assembly/*'
    path drep_output      , stageAs: 'results/bin_qc/drep/*'
    path fastp_json       , stageAs: 'results/fastp/*'

    output:
    tuple val(meta), path("figures/*.png"), emit: figures
    tuple val(meta), path("figures/*.txt"), emit: krona_text, optional: true
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    plot_results.py results figures

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$( python --version 2>&1 | sed 's/Python //' )
        matplotlib: \$( python -c "import matplotlib; print(matplotlib.__version__)" )
    END_VERSIONS
    """

    stub:
    """
    mkdir -p figures
    touch figures/01_taxonomie_kraken2.png figures/kraken2.krona.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: "stub"
        matplotlib: "stub"
    END_VERSIONS
    """
}
