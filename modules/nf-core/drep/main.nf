process DREP {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::drep=3.4.5'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/drep:3.4.5--pyhdfd78af_0' :
        'biocontainers/drep:3.4.5--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(bins, stageAs: 'input_bins/*')
    path  checkm_table   // optional genome_info.csv with completeness/contamination

    output:
    tuple val(meta), path('drep_output/dereplicated_genomes/*.fa'), emit: passed_bins
    tuple val(meta), path('drep_output/'),                          emit: results
    path  'versions.yml',                                           emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args   ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    def info_arg  = checkm_table    ? "--genomeInfo ${checkm_table}" : ''
    """
    dRep dereplicate \\
        drep_output \\
        -g input_bins/*.fa \\
        -p $task.cpus \\
        $info_arg \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        drep: \$( dRep --version | sed 's/dRep v//' )
    END_VERSIONS
    """
}
