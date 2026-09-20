process METARENZ {
    tag "${meta.id}"
    label 'process_medium'

    // MeTarEnz is distributed only as a Docker image by its authors — there is
    // no Bioconda recipe, so this module cannot run under -profile conda.
    //
    // The image below is the upstream one plus procps, which Nextflow needs to
    // collect task metrics; see containers/metarenz/Dockerfile for the two-line
    // recipe and the build/push instructions. Override it with:
    //   process { withName: 'METARENZ' { container = '<your-registry>/...' } }
    //
    // Upstream tool : https://github.com/mehdiforoozandeh/MeTarEnz
    // Upstream image: https://hub.docker.com/r/mforooz/metarenz
    container 'ghcr.io/bboy010/plastizymefinder-metarenz:1.0'

    input:
    // Staged into separate directories so a query and a database that happen to
    // share a file name cannot collide in the task directory.
    tuple val(meta), path(sequences, stageAs: 'query/*')
    path pet_db, stageAs: 'db/*'
    val  screening_mode

    output:
    tuple val(meta), path("*.metarenz.csv")      , emit: csv
    tuple val(meta), path("*.candidates.faa")    , emit: candidates
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit early rather than fail deep inside the container (pattern borrowed from nf-core/proteinfold)
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("METARENZ does not support Conda: MeTarEnz has no Bioconda recipe. Use -profile docker or singularity.")
    }
    def args   = task.ext.args ?: '-bs 50'
    def prefix = task.ext.prefix ?: "${meta.id}"
    // 'cs' emits the six-frame translation in a column named 'translation';
    // 'ps' emits the aligned query in a column named 'query_seq'.
    def seq_column = screening_mode == 'cs' ? 'translation' : 'query_seq'
    """
    # MeTarEnz resolves its BLAST binaries, its help text and its output tree
    # relative to the *current* directory (see blasters.py: os.system('./blastp ...')),
    # so link them into the task directory instead of running inside the image.
    ln -s /home/MeTarEnz/blastp /home/MeTarEnz/blastx /home/MeTarEnz/makeblastdb .
    ln -s /home/MeTarEnz/help /home/MeTarEnz/Models .
    mkdir -p temp MeTarEnz_Results

    # Accept plain or gzipped FASTA; MeTarEnz reads uncompressed input only.
    zcat -f ${sequences} > ${prefix}.query.fa

    python /home/MeTarEnz/metarenz.py ${screening_mode} \
        -i ${prefix}.query.fa \
        -db ${pet_db} \
        -t ${task.cpus} \
        -o ${prefix} \
        ${args}

    # MeTarEnz exits 0 and writes nothing when no sequence passes the bit-score
    # filter, so the outputs are materialised here to keep the channel contract.
    if [ -f "MeTarEnz_Results/${prefix}/screening_results.csv" ]; then
        cp "MeTarEnz_Results/${prefix}/screening_results.csv" ${prefix}.metarenz.csv
    else
        echo ",query_id,${seq_column},source_seq_id,bitscore,evalue" > ${prefix}.metarenz.csv
        echo "WARN: MeTarEnz reported no plastizyme candidate for ${prefix}" >&2
    fi

    csv2fasta.py ${prefix}.metarenz.csv ${seq_column} ${prefix}.candidates.faa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metarenz: "1.0"
        blast: \$( ./blastp -version 2>&1 | sed -n 's/^blastp: //p' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo ",query_id,${screening_mode == 'cs' ? 'translation' : 'query_seq'},source_seq_id,bitscore,evalue" \
        > ${prefix}.metarenz.csv
    touch ${prefix}.candidates.faa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metarenz: 1.0
        blast: 2.9.0+
    END_VERSIONS
    """
}
