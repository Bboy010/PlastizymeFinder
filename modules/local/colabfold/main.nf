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
    // The authors' CUDA image turns on CUDA unified memory with a pool of 4x
    // the GPU's memory, spilling into host RAM. On a 6 GB card that asks for
    // 24 GB of RAM, fills the task's memory and thrashes (45 min without
    // finishing a 236-residue protein). A candidate plastizyme fits in the GPU
    // itself; set ext.gpu_unified_memory = true for proteins that do not.
    def gpu_env = task.ext.use_gpu && !task.ext.gpu_unified_memory
        ? 'export TF_FORCE_UNIFIED_MEMORY=0 XLA_PYTHON_CLIENT_MEM_FRACTION=0.9'
        : ''
    """
    # Docker runs this container as the host's numeric UID (docker.runOptions
    # -u \$(id -u):\$(id -g)), which has no /etc/passwd entry, so HOME resolves
    # to '/' and colabfold's weight download fails with "Permission denied:
    # '/.cache'". Give it a HOME it can write to.
    export HOME="\$PWD"
    # The ColabFold authors' CUDA image (-profile gpu) sets XDG_CACHE_HOME to
    # /cache, which that UID cannot write either.
    export XDG_CACHE_HOME="\$PWD/.cache"
    ${gpu_env}
    # The official ColabFold CUDA image (-profile gpu) ships 'python' only.
    py=\$(command -v python3 || command -v python)

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

        # One structure per candidate: colabfold_batch names each query's best
        # model <query>_unrelaxed_rank_001_*.pdb, plus a _relaxed_ one when
        # Amber ran, which is the one kept. Candidate headers from stage 7
        # read <contig>_bitscore_<n>_ref_<id>: the contig ID names the file.
        for pdb in raw/*_unrelaxed_rank_001_*.pdb; do
            query=\$(basename "\$pdb" | sed -E 's/_unrelaxed_rank_001_.*//')
            relaxed=\$(ls raw/"\$query"_relaxed_rank_001_*.pdb 2>/dev/null | head -1)
            name=\$(echo "\$query" | sed -E 's/_bitscore_.*//')
            cp "\${relaxed:-\$pdb}" "${prefix}.\${name}.colabfold.pdb"
        done

        # Per-residue confidence, so a reader can tell a folded domain from a
        # disordered tail without opening the structure. The Python is kept on
        # one line and printf's newline is escaped twice in the module source:
        # any line at column 0 - a Python block, or a real newline - stops
        # Nextflow stripping the script's indentation, and the END_VERSIONS
        # terminator is then missed.
        printf 'model\tmean_plddt\\n' > ${prefix}.plddt.tsv
        for json in raw/*rank_001*.json; do
            "\$py" -c "import json, sys, os; s = json.load(open(sys.argv[1])).get('plddt') or []; print('%s\t%.2f' % (os.path.basename(sys.argv[1]), sum(s) / len(s) if s else 0))" "\${json}" >> ${prefix}.plddt.tsv
        done
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        colabfold: "\$( "\$py" -c 'import importlib.metadata as m; print(m.version("colabfold"))' 2>/dev/null || echo unknown )"
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p raw
    touch raw/${prefix}_unrelaxed_rank_001_model.pdb
    touch ${prefix}.colabfold.pdb
    printf 'model\tmean_plddt\\n' > ${prefix}.plddt.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        colabfold: 1.5.5
    END_VERSIONS
    """
}
