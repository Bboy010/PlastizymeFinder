/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: COLABFOLD
    3D structure prediction for candidate plastizymes.

    ColabFold replaces the plain AlphaFold2 module, for two reasons. It is what
    Hongo et al. (2026) actually used, and it takes its multiple sequence
    alignment from an MMseqs2 server rather than from ~2.6 TB of local
    reference databases — which is why it runs in a notebook, and why it can run
    here without a database download step.

    --host-url points at the public ColabFold server by default. For a run that
    must not depend on an external service, point it at your own instance or
    supply a local colabfold_db.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process COLABFOLD {
    tag "${meta.id}"
    label 'process_high'
    label 'process_gpu'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/colabfold:1.5.5--pyh7cba7a3_2'
        : 'quay.io/biocontainers/colabfold:1.5.5--pyh7cba7a3_2'}"

    input:
    tuple val(meta), path(fasta)
    path weights

    output:
    // All three are optional: with no candidate there is nothing to fold, and
    // emitting a placeholder instead would hand TM-Align an empty structure.
    tuple val(meta), path("*.colabfold.pdb"), emit: pdb,   optional: true
    tuple val(meta), path("*.plddt.tsv")    , emit: plddt, optional: true
    tuple val(meta), path("raw/**")         , emit: raw,   optional: true
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // Amber relaxation only runs on a GPU; ext.use_gpu comes from process_gpu.
    def relax  = task.ext.use_gpu ? '--amber --use-gpu-relax' : ''
    def data   = weights ? "--data ${weights}" : ''
    """
    # An empty candidate FASTA is a legitimate outcome upstream, not an error.
    if [ ! -s ${fasta} ]; then
        echo "WARN: ${fasta} is empty - nothing to fold for ${prefix}, no structure emitted" >&2
    else
        colabfold_batch \
            ${fasta} \
            raw \
            ${data} \
            ${relax} \
            ${args}

        # colabfold_batch names its best model *_rank_001_*.pdb
        cp "\$(ls raw/*rank_001*.pdb | head -1)" ${prefix}.colabfold.pdb

        # Per-residue confidence, so a reader can tell a folded domain from a
        # disordered tail without opening the structure.
        printf 'model\tmean_plddt\n' > ${prefix}.plddt.tsv
        for json in raw/*rank_001*.json; do
            python3 -c "
import json, sys, os
d = json.load(open(sys.argv[1]))
s = d.get('plddt') or []
print('%s\t%.2f' % (os.path.basename(sys.argv[1]), sum(s) / len(s) if s else 0))
" "\${json}" >> ${prefix}.plddt.tsv
        done
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        colabfold: \$( colabfold_batch --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p raw
    touch raw/${prefix}_unrelaxed_rank_001_model.pdb
    touch ${prefix}.colabfold.pdb
    printf 'model\tmean_plddt\n' > ${prefix}.plddt.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        colabfold: 1.5.5
    END_VERSIONS
    """
}
