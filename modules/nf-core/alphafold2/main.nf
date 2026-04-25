process ALPHAFOLD2 {
    tag "$meta.id"
    label 'process_high'

    // AlphaFold2 — GPU strongly recommended
    // Official container from DeepMind / community builds
    conda { exit 1; "AlphaFold2 must be run via container (docker/singularity)" }
    container "${ workflow.containerEngine == 'singularity' ?
        'docker://catgumag/alphafold:2.3.2' :
        'catgumag/alphafold:2.3.2' }"

    input:
    tuple val(meta), path(fasta)   // single-protein FASTA per candidate

    output:
    tuple val(meta), path("${meta.id}/ranked_0.pdb"),            emit: pdb
    tuple val(meta), path("${meta.id}/ranking_debug.json"),      emit: ranking
    tuple val(meta), path("${meta.id}/"),                        emit: results
    path  'versions.yml',                                        emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = meta.id
    """
    python /app/alphafold/run_alphafold.py \\
        --fasta_paths=$fasta \\
        --output_dir=. \\
        --model_preset=monomer \\
        --db_preset=reduced_dbs \\
        --max_template_date=2024-01-01 \\
        --use_gpu_relax=true \\
        --num_multimer_predictions_per_model=1 \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        alphafold2: "2.3.2"
    END_VERSIONS
    """
}
