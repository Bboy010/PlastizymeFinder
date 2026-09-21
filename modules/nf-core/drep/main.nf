process DREP {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::drep=3.4.5 bioconda::checkm-genome "conda-forge::pandas<2.2"'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/drep:3.4.5--pyhdfd78af_0' :
        'quay.io/biocontainers/drep:3.4.5--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(bins, stageAs: 'input_bins/*')
    path  checkm_table   // optional genome_info.csv with completeness/contamination

    output:
    tuple val(meta), path('drep_output/dereplicated_genomes/*.fa'), emit: passed_bins, optional: true
    tuple val(meta), path('drep_output/'),                          emit: results
    path  'versions.yml',                                           emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args         = task.ext.args ?: ''
    def info_arg     = checkm_table ? "--genomeInfo ${checkm_table}" : '--ignoreGenomeQuality'
    // Without a CheckM genomeInfo table dRep has nothing to score completeness
    // or contamination against, so drop thresholds that could not be applied.
    def filter_args  = checkm_table ? args : args.replaceAll(/-(comp|con)\s+\S+/, '').replaceAll(/\s+/, ' ').trim()
    def checkm_setup = params.checkm_db ? "checkm data setRoot ${params.checkm_db}" : ''
    """
    $checkm_setup

    # A sample whose bins all fail dRep's filters is a biological outcome, not
    # a pipeline error: dRep exits non-zero, and we let the sample drop rather
    # than kill the run. Any other failure stays fatal.
    if ! dRep dereplicate \\
        drep_output \\
        -g input_bins/*.fa \\
        -p $task.cpus \\
        $info_arg \\
        $filter_args > drep.log 2>&1
    then
        if grep -q '0.00% of genomes passed' drep.log; then
            echo "WARN: no bin of ${meta.id} passed dRep's filters - sample dropped from bin-level stages" >&2
            mkdir -p drep_output/dereplicated_genomes
        else
            cat drep.log >&2
            exit 1
        fi
    fi
    cat drep.log

    # dRep returns 0 even when every secondary clustering call fails, which
    # leaves no dereplicated genome at all. Say so instead of emitting nothing.
    if ! compgen -G 'drep_output/dereplicated_genomes/*.fa' > /dev/null; then
        echo "WARN: dRep produced no dereplicated genome for ${meta.id} - check drep_output/log/logger.log for clustering errors" >&2
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        drep: \$( dRep -v 2>&1 | grep -oP '(?<=dRep )[0-9.]+' || echo 'unknown' )
    END_VERSIONS
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p drep_output/dereplicated_genomes
    touch drep_output/dereplicated_genomes/${prefix}.fa
    mkdir -p drep_output
    touch drep_output/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        drep: "stub"
    END_VERSIONS
    """
}
