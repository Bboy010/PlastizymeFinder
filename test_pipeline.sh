#!/usr/bin/env bash
#
# PlastizymeFinder — suite de validation
#
#   ./test_pipeline.sh           lint, config et DAG complet en stub
#   ./test_pipeline.sh --modules ajoute les tests nf-test des modules locaux
#
# Chaque test échoue bruyamment : pas de dégradation silencieuse en warning.

set -uo pipefail

PASS=0
FAIL=0
WORKDIR=$(mktemp -d)
trap 'rm -rf "${WORKDIR}"' EXIT

ok()    { printf '  \033[32mOK\033[0m     %s\n' "$1"; PASS=$((PASS + 1)); }
ko()    { printf '  \033[31mECHEC\033[0m  %s\n' "$1"; FAIL=$((FAIL + 1)); }
skip()  { printf '  \033[33mIGNORE\033[0m %s\n' "$1"; }
note()  { printf '  \033[33mNOTE\033[0m   %s\n' "$1"; }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }

NXF_VERSION=$(nextflow -version 2>&1 | awk '/^ *version /{print $2; exit}')
printf '\033[1mPlastizymeFinder — validation\033[0m   (Nextflow %s)\n' \
    "${NXF_VERSION:-inconnue}"

head_ "1. Syntaxe stricte"

# `nextflow lint` n'existe qu'à partir de Nextflow 25.
if nextflow lint . > "${WORKDIR}/lint.log" 2>&1; then
    ok "$(grep -oE '[0-9]+ files had no errors' "${WORKDIR}/lint.log" | head -1)"
    WARNS=$(grep -cE '^Warn ' "${WORKDIR}/lint.log" || true)
    if [ "${WARNS}" -gt 0 ]; then
        note "${WARNS} avertissement(s) de style"
        grep -E '^Warn ' "${WORKDIR}/lint.log" | sed 's/^/         /'
    fi
elif grep -q "Unknown command" "${WORKDIR}/lint.log"; then
    skip "nextflow lint absent — nécessite Nextflow >= 25"
else
    ko "nextflow lint signale des erreurs :"
    tail -25 "${WORKDIR}/lint.log" | sed 's/^/         /'
fi

head_ "2. Configuration"

for profile in test test_all 'test,docker' 'docker,gpu' singularity; do
    if nextflow config -profile "${profile}" > /dev/null 2>&1; then
        ok "profil ${profile} se charge"
    else
        ko "profil ${profile} ne se charge pas"
    fi
done

head_ "3. Données de test"

for f in assets/testdata/samplesheet_test.csv \
         assets/testdata/pet_db_test.fasta \
         assets/testdata/test_sample_R1.fastq.gz \
         assets/testdata/test_sample_R2.fastq.gz \
         assets/testdata/structures/petase_ref_test.pdb; do
    if [ -s "${f}" ]; then ok "${f}"; else ko "${f} absent ou vide"; fi
done

head_ "4. Tous les modules ont un bloc stub"

MISSING=$(for f in $(find modules -name main.nf); do
              grep -q '^    stub:' "${f}" || echo "${f}"
          done)
if [ -z "${MISSING}" ]; then
    ok "$(find modules -name main.nf | wc -l) modules, tous avec stub"
else
    ko "modules sans stub :"
    echo "${MISSING}" | sed 's/^/         /'
fi

head_ "5. Pipeline de bout en bout (stub, 9 étapes)"

# `test_all` = `test` sans sauter l'étape 8. On passe par un profil, et non par
# `--skip_structure false` : depuis Nextflow 25, un booléen passé en ligne de
# commande arrive comme la chaîne "false", qui est vraie. Le test passait alors
# en silence sans jamais exécuter l'étape 8.
if nextflow run main.nf -profile test_all -stub-run \
        --outdir "${WORKDIR}/out" -w "${WORKDIR}/work" > "${WORKDIR}/run.log" 2>&1; then
    TRACE="${WORKDIR}/out/pipeline_info/execution_trace.txt"
    TOTAL=$(($(wc -l < "${TRACE}") - 1))
    DONE=$(grep -c COMPLETED "${TRACE}")
    ok "${DONE}/${TOTAL} processus terminés"

    for stage in QC_PREPROCESSING TAXONOMIC_PROFILING ASSEMBLY_ANNOTATION \
                 BINNING BIN_QC BIN_CLASSIFICATION PLASTIZYME_PREDICTION \
                 STRUCTURE_PREDICTION MULTIQC; do
        if grep -q "${stage}" "${TRACE}"; then
            ok "étape ${stage}"
        else
            ko "étape ${stage} absente"
        fi
    done
else
    ko "le pipeline ne s'exécute pas — 20 dernières lignes :"
    tail -20 "${WORKDIR}/run.log" | sed 's/^/         /'
fi

if [ "${1:-}" = "--modules" ]; then
    head_ "6. Tests unitaires des modules locaux (exécution réelle)"
    if ! docker info > /dev/null 2>&1; then
        skip "le démon Docker ne répond pas — tests réels non exécutés"
    elif ! command -v nf-test > /dev/null 2>&1; then
        ko "nf-test n'est pas installé (https://www.nf-test.com)"
    elif nf-test test modules/local --profile docker > "${WORKDIR}/nft.log" 2>&1; then
        ok "$(grep -c PASSED "${WORKDIR}/nft.log") tests nf-test passés"
    else
        ko "nf-test en échec :"
        tail -20 "${WORKDIR}/nft.log" | sed 's/^/         /'
    fi
fi

printf '\n\033[1mBilan : %d réussis, %d échecs\033[0m\n' "${PASS}" "${FAIL}"
[ "${FAIL}" -eq 0 ] || exit 1
