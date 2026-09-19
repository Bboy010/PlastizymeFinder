#!/usr/bin/env bash
#
# PlastizymeFinder validation suite
#
#   ./test_pipeline.sh           lint, config and a full stub run
#   ./test_pipeline.sh --modules also runs the nf-test cases for local modules
#
# Every check fails loudly: nothing is downgraded to a warning.

set -uo pipefail

PASS=0
FAIL=0
WORKDIR=$(mktemp -d)
trap 'rm -rf "${WORKDIR}"' EXIT

ok()    { printf '  \033[32mPASS\033[0m   %s\n' "$1"; PASS=$((PASS + 1)); }
ko()    { printf '  \033[31mFAIL\033[0m   %s\n' "$1"; FAIL=$((FAIL + 1)); }
skip()  { printf '  \033[33mSKIP\033[0m   %s\n' "$1"; }
note()  { printf '  \033[33mNOTE\033[0m   %s\n' "$1"; }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }

NXF_VERSION=$(nextflow -version 2>&1 | awk '/^ *version /{print $2; exit}')
printf '\033[1mPlastizymeFinder validation\033[0m   (Nextflow %s)\n' \
    "${NXF_VERSION:-unknown}"

head_ "1. Strict syntax"

# `nextflow lint` only exists from Nextflow 25 onwards.
if nextflow lint . > "${WORKDIR}/lint.log" 2>&1; then
    ok "$(grep -oE '[0-9]+ files had no errors' "${WORKDIR}/lint.log" | head -1)"
    WARNS=$(grep -cE '^Warn ' "${WORKDIR}/lint.log" || true)
    if [ "${WARNS}" -gt 0 ]; then
        note "${WARNS} style warning(s)"
        grep -E '^Warn ' "${WORKDIR}/lint.log" | sed 's/^/         /'
    fi
elif grep -q "Unknown command" "${WORKDIR}/lint.log"; then
    skip "nextflow lint unavailable - requires Nextflow >= 25"
else
    ko "nextflow lint reports errors:"
    tail -25 "${WORKDIR}/lint.log" | sed 's/^/         /'
fi

head_ "2. Configuration"

for profile in test test_all 'test,docker' 'docker,gpu' singularity; do
    if nextflow config -profile "${profile}" > /dev/null 2>&1; then
        ok "profile ${profile} loads"
    else
        ko "profile ${profile} does not load"
    fi
done

head_ "3. Test data"

for f in assets/testdata/samplesheet_test.csv \
         assets/testdata/pet_db_test.fasta \
         assets/testdata/test_sample_R1.fastq.gz \
         assets/testdata/test_sample_R2.fastq.gz \
         assets/testdata/structures/petase_ref_test.pdb; do
    if [ -s "${f}" ]; then ok "${f}"; else ko "${f} missing or empty"; fi
done

head_ "4. Every module has a stub block"

MISSING=$(for f in $(find modules -name main.nf); do
              grep -q '^    stub:' "${f}" || echo "${f}"
          done)
if [ -z "${MISSING}" ]; then
    ok "$(find modules -name main.nf | wc -l) modules, all with a stub"
else
    ko "modules without a stub:"
    echo "${MISSING}" | sed 's/^/         /'
fi

head_ "5. End-to-end run (stub, 9 stages)"

# `test_all` is `test` without skipping stage 8. It has to be a profile, not
# `--skip_structure false`: since Nextflow 25 a boolean passed on the command
# line arrives as the String "false", which is truthy. Stage 8 was silently
# skipped and this check passed anyway.
if nextflow run main.nf -profile test_all -stub-run \
        --outdir "${WORKDIR}/out" -w "${WORKDIR}/work" > "${WORKDIR}/run.log" 2>&1; then
    TRACE="${WORKDIR}/out/pipeline_info/execution_trace.txt"
    TOTAL=$(($(wc -l < "${TRACE}") - 1))
    DONE=$(grep -c COMPLETED "${TRACE}")
    ok "${DONE}/${TOTAL} processes completed"

    for stage in QC_PREPROCESSING TAXONOMIC_PROFILING ASSEMBLY_ANNOTATION \
                 BINNING BIN_QC BIN_CLASSIFICATION PLASTIZYME_PREDICTION \
                 STRUCTURE_PREDICTION MULTIQC; do
        if grep -q "${stage}" "${TRACE}"; then
            ok "stage ${stage}"
        else
            ko "stage ${stage} did not run"
        fi
    done
else
    ko "the pipeline does not run - last 20 lines:"
    tail -20 "${WORKDIR}/run.log" | sed 's/^/         /'
fi

if [ "${1:-}" = "--modules" ]; then
    head_ "6. Unit tests for local modules (real execution)"
    if ! docker info > /dev/null 2>&1; then
        skip "the Docker daemon is not responding - real tests not run"
    elif ! command -v nf-test > /dev/null 2>&1; then
        ko "nf-test is not installed (https://www.nf-test.com)"
    elif nf-test test modules/local --profile docker > "${WORKDIR}/nft.log" 2>&1; then
        ok "$(grep -c PASSED "${WORKDIR}/nft.log") nf-test cases passed"
    else
        ko "nf-test failed:"
        tail -20 "${WORKDIR}/nft.log" | sed 's/^/         /'
    fi
fi

printf '\n\033[1mSummary: %d passed, %d failed\033[0m\n' "${PASS}" "${FAIL}"
[ "${FAIL}" -eq 0 ] || exit 1
