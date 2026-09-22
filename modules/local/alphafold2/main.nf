/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: ALPHAFOLD2
    3D structure prediction for candidate plastizymes.

    AlphaFold2 has no Bioconda recipe and is not available as an nf-core
    module — nf-core/proteinfold also keeps it as a local module. GPU
    allocation is driven by the 'process_gpu' label (see conf/base.config)
    and enabled with -profile gpu.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ALPHAFOLD2 {
    tag "${meta.id}"
    label 'process_high'
    label 'process_gpu'

    container 'catgumag/alphafold:2.3.2'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.alphafold2.pdb"), emit: pdb
    tuple val(meta), path("raw/**")          , emit: raw
    path "versions.yml"                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("ALPHAFOLD2 does not support Conda: AlphaFold2 has no Bioconda recipe. Use -profile docker or singularity.")
    }
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // ext.use_gpu is set by the process_gpu label; relaxation must match it.
    def use_gpu = task.ext.use_gpu ? 'true' : 'false'
    """
    python /app/alphafold/run_alphafold.py \
        --fasta_paths=${fasta} \
        --output_dir=\$PWD \
        --model_preset=monomer \
        --db_preset=reduced_dbs \
        --use_gpu_relax=${use_gpu} \
        ${args}

    cp "${fasta.baseName}"/ranked_0.pdb ./${prefix}.alphafold2.pdb
    mv "${fasta.baseName}" raw/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        alphafold2: "2.3.2"
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.alphafold2.pdb
    mkdir -p raw
    touch raw/ranked_0.pdb raw/ranking_debug.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        alphafold2: "2.3.2"
    END_VERSIONS
    """
}
