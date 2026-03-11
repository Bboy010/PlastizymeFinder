process MULTIQC {
    label 'process_single'

    conda 'bioconda::multiqc=1.21'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.21--pyhdfd78af_0' :
        'biocontainers/multiqc:1.21--pyhdfd78af_0' }"

    input:
    path  multiqc_files, stageAs: 'multiqc_input/*'
    path  multiqc_config
    path  extra_multiqc_config
    path  multiqc_logo

    output:
    path "*multiqc_report.html",  emit: report
    path "*_data",                emit: data
    path "*_plots",               optional: true, emit: plots
    path "versions.yml",          emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args         ?: ''
    def config_arg  = multiqc_config        ? "--config $multiqc_config"       : ''
    def extra_arg   = extra_multiqc_config  ? "--config $extra_multiqc_config" : ''
    def logo_arg    = multiqc_logo          ? "--cl-config 'custom_logo: \"${multiqc_logo}\"'" : ''
    def title_arg   = params.multiqc_title  ? "--title \"${params.multiqc_title}\"" : ''
    """
    multiqc \\
        --force \\
        $config_arg \\
        $extra_arg \\
        $logo_arg \\
        $title_arg \\
        $args \\
        multiqc_input/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed 's/multiqc, version //' )
    END_VERSIONS
    """
}
