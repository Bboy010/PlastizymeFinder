process CDSEARCH {
    tag "$meta.id"
    label 'process_medium'

    // CD-Search is an NCBI web service — rpstblastn is the local equivalent
    conda 'bioconda::blast=2.15.0'
    container "${ workflow.containerEngine == 'singularity' ?
        'https://depot.galaxyproject.org/singularity/blast:2.15.0--pl5321h6f7f691_1' :
        'biocontainers/blast:2.15.0--pl5321h6f7f691_1' }"

    input:
    tuple val(meta), path(fasta)   // protein FASTA

    output:
    tuple val(meta), path('*.tsv'),     emit: hits
    path  'versions.yml',               emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Use NCBI CD-Search REST API for conserved domain annotation
    # Submits query and polls until results are ready
    python3 - <<'PYEOF'
import urllib.request, urllib.parse, time, sys

query = open("${fasta}").read()
base_url = "https://www.ncbi.nlm.nih.gov/Structure/bwrpsb/bwrpsb.cgi"

# Submit
params = urllib.parse.urlencode({
    "queries":    query,
    "db":         "cdd",
    "smode":      "auto",
    "useid1":     "true",
    "compbasedadj": "1",
    "filter":     "true",
    "evalue":     "0.01",
    "maxhit":     "500",
    "dmode":      "rep",
    "tdata":      "hits",
}).encode()

resp   = urllib.request.urlopen(base_url, params)
lines  = resp.read().decode().splitlines()
cdsid  = next(l.split()[-1] for l in lines if l.startswith("#cdsid"))

# Poll
for attempt in range(30):
    time.sleep(10)
    check  = urllib.request.urlopen(f"{base_url}?tdata=hits&cddefl=false&cdsid={cdsid}")
    status = check.read().decode()
    if "#status\t0" in status:
        with open("${prefix}.cdsearch.tsv", "w") as f:
            f.write(status)
        sys.exit(0)

sys.stderr.write("CD-Search timed out\\n")
sys.exit(1)
PYEOF

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cdsearch: NCBI_CD-Search_REST_API
        blast: \$( blastp -version 2>&1 | head -1 | sed 's/blastp: //' )
    END_VERSIONS
    """
}
