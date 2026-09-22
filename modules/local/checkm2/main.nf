/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Module: CHECKM2
    Estimates bin completeness and contamination with CheckM2's ML models,
    then reshapes the result into dRep's --genomeInfo layout so the study's
    quality thresholds (default: completeness >= 50, contamination <= 10)
    are the ones actually enforced, not dropped for lack of a table.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process CHECKM2 {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::checkm2=1.0.2'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/checkm2:1.0.2--pyh7cba7a3_0' :
        'quay.io/biocontainers/checkm2:1.0.2--pyh7cba7a3_0' }"

    input:
    tuple val(meta), path(bins, stageAs: 'input_bins/*')
    path  db   // the .dmnd file, or a directory that contains one (searched recursively)

    output:
    tuple val(meta), path('*.genome_info.csv'), emit: genome_info
    path  '*.quality_report.tsv',                emit: report
    path  'versions.yml',                        emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # The Zenodo backpack for this database nests the .dmnd one level down
    # (CheckM2_database/uniref100.KO.1.dmnd); accept either layout.
    dmnd=\$( [ -f "${db}" ] && echo "${db}" || find "${db}" -name '*.dmnd' -print -quit )
    if [ -z "\$dmnd" ]; then
        echo "ERROR: no .dmnd file found under ${db}" >&2
        exit 1
    fi

    checkm2 predict \\
        --threads $task.cpus \\
        --input input_bins \\
        -x fa \\
        --output-directory checkm2_out \\
        --database_path "\$dmnd" \\
        $args

    # dRep's --genomeInfo wants exactly: genome,completeness,contamination,
    # with "genome" the bin's file *name* (not path) including its extension.
    python3 -c "
import csv
with open('checkm2_out/quality_report.tsv') as fh, open('${prefix}.genome_info.csv', 'w', newline='') as out:
    reader = csv.DictReader(fh, delimiter='\t')
    writer = csv.writer(out)
    writer.writerow(['genome', 'completeness', 'contamination'])
    for row in reader:
        writer.writerow([row['Name'] + '.fa', row['Completeness'], row['Contamination']])
"
    cp checkm2_out/quality_report.tsv ${prefix}.quality_report.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkm2: \$( checkm2 --version 2>&1 | tail -n1 )
    END_VERSIONS
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    printf 'genome,completeness,contamination\\n' > ${prefix}.genome_info.csv
    printf 'Name\\tCompleteness\\tContamination\\n' > ${prefix}.quality_report.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkm2: "stub"
    END_VERSIONS
    """
}
