#!/usr/bin/env python3
"""
Regenerate docs/processes.md from the module sources and an execution trace.

Run from the repository root, after any change to the modules:

    nextflow run main.nf -profile test_all -stub-run --outdir /tmp/rep -w /tmp/repw
    bin/gen_process_report.py /tmp/rep/pipeline_info/execution_trace.txt
"""
import io
import os
import re
import subprocess
import sys

TRACE = sys.argv[1] if len(sys.argv) > 1 else None

STAGE = [
    ('PREPARE_DATABASES', '0 - Bases de reference'),
    ('QC_PREPROCESSING', '1 - Controle qualite'),
    ('TAXONOMIC_PROFILING', '2 - Profilage taxonomique'),
    ('ASSEMBLY_ANNOTATION', '3 - Assemblage et prediction de genes'),
    ('BINNING', '4 - Binning'),
    ('BIN_QC', '5 - QC des bins et dereplication'),
    ('BIN_CLASSIFICATION', '6 - Annotation fonctionnelle et taxonomique'),
    ('PLASTIZYME_PREDICTION', '7 - Prediction de plastizymes'),
    ('STRUCTURE_PREDICTION', '8 - Validation structurale'),
    ('PLOT_REPORT', '9 - Rapport'),
    ('MULTIQC', '9 - Rapport'),
]

IMG = re.compile(
    r"(?:quay\.io/biocontainers/|biocontainers/|docker://|community\.wave\.seqera\.io/library/"
    r"|nf-core/|catgumag/|mforooz/|plastizymefinder/)[\w\-./]+:[\w\-.+]+")


def sh(cmd):
    return subprocess.check_output(['bash', '-c', cmd]).decode().split()


def stage_of(full):
    for key, label in STAGE:
        if key in full:
            return label
    return '-'


mods = {}
for path in sh('find modules -name main.nf | sort'):
    src = io.open(path, encoding='utf-8').read()
    name = re.search(r'^process (\w+)', src, re.M).group(1)
    label = re.search(r"^\s+label\s+'([\w_]+)'", src, re.M)
    img = IMG.search(src)
    mods[name] = {
        'label': label.group(1) if label else '-',
        'container': img.group(0) if img else '-',
        'emits': [e for e in re.findall(r'emit:\s*(\w+)', src) if e != 'versions'],
        'local': path.startswith('modules/local'),
        'stub': bool(re.search(r'^    stub:', src, re.M)),
        'meta_yml': os.path.exists(os.path.join(os.path.dirname(path), 'meta.yml')),
        'tests': os.path.isdir(os.path.join(os.path.dirname(path), 'tests')),
        'alias_of': None,
    }

for wf in sh('find workflows -name "*.nf"'):
    text = io.open(wf, encoding='utf-8').read()
    for m in re.finditer(r'include\s*\{\s*(\w+)\s+as\s+(\w+)\s*\}', text):
        base, ali = m.group(1), m.group(2)
        if ali not in mods and base in mods:
            mods[ali] = dict(mods[base], alias_of=base)

cfg = io.open('conf/modules.config', encoding='utf-8').read()
pub, override = {}, {}
for m in re.finditer(r"withName:\s*'([^']+)'\s*\{(.*?)\n    \}", cfg, re.S):
    sel, body = m.group(1), m.group(2)
    cm = re.search(r"container\s*=\s*'([^']+)'", body)
    if cm:
        override[sel] = cm.group(1)
    if 'enabled: false' in body:
        pub[sel] = 'non publie'
    else:
        pm = re.search(r'path:\s*\{\s*"\$\{params\.outdir\}/([^"]*)"', body)
        if pm:
            pub[sel] = 'results/' + pm.group(1)


def lookup(table, name, default=None):
    if name in table:
        return table[name]
    for sel, val in table.items():
        if '.*' in sel and re.fullmatch(sel, name):
            return val
    return default


executed = []
if TRACE and os.path.exists(TRACE):
    with io.open(TRACE, encoding='utf-8') as fh:
        for row in [l.rstrip('\n').split('\t') for l in fh][1:]:
            if len(row) > 4:
                executed.append((row[3], row[4]))

real = [m for m in mods.values() if not m['alias_of']]
nxf = subprocess.run(['bash', '-c', "nextflow -version 2>&1 | sed -n 's/.*version \\([0-9.]*\\).*/\\1/p' | head -1"],
                     capture_output=True).stdout.decode().strip()

out = []
w = out.append
w('# Rapport des process - PlastizymeFinder\n')
w('> Genere par `bin/gen_process_report.py` depuis les sources des modules et une')
w('> execution reelle du pipeline. A regenerer apres toute modification des modules.\n')
w('| Element | Valeur |')
w('|---|---|')
if nxf:
    w('| Nextflow | {} |'.format(nxf))
w('| Processus definis | {} |'.format(len(real)))
w('| Alias de processus | {} |'.format(len(mods) - len(real)))
w('| Modules locaux | {} |'.format(len([m for m in real if m['local']])))
w('| Blocs stub | {}/{} |'.format(len([m for m in real if m['stub']]), len(real)))
w('| meta.yml | {}/{} |'.format(len([m for m in real if m['meta_yml']]), len(real)))
w('| Suites tests/ | {}/{} |'.format(len([m for m in real if m['tests']]), len(real)))
if executed:
    ok = len([1 for _, s in executed if s == 'COMPLETED'])
    w('| Processus executes | {}/{} termines |'.format(ok, len(executed)))
w('')

if executed:
    w('## Processus executes\n')
    by_stage = {}
    for full, status in executed:
        by_stage.setdefault(stage_of(full), []).append((full, status))
    seen = set()
    for _, label in STAGE:
        if label in seen or label not in by_stage:
            continue
        seen.add(label)
        w('### Etape {}\n'.format(label))
        w('| Process | Conteneur | Ressources | Sortie | Statut |')
        w('|---|---|---|---|---|')
        for full, status in sorted(by_stage[label]):
            short = full.split(':')[-1].split(' ')[0]
            m = mods.get(short, {})
            ov = lookup(override, short)
            w('| `{}`{} | `{}`{} | {} | `{}` | {} |'.format(
                short,
                '<br><sub>alias de {}</sub>'.format(m['alias_of']) if m.get('alias_of') else '',
                ov or m.get('container', '-'),
                '<br><sub>surcharge config</sub>' if ov else '',
                m.get('label', '-'),
                lookup(pub, short, 'results/' + short.split('_')[0].lower()),
                'OK' if status == 'COMPLETED' else status))
        w('')

w('## Inventaire des modules\n')
w('| Module | Origine | Conteneur | Canaux emis | stub | meta.yml | tests |')
w('|---|---|---|---|---|---|---|')
for name in sorted(k for k, v in mods.items() if not v['alias_of']):
    m = mods[name]
    w('| `{}` | {} | `{}` | {} | {} | {} | {} |'.format(
        name, 'local' if m['local'] else 'copie nf-core', m['container'],
        ', '.join('`{}`'.format(e) for e in m['emits']) or '-',
        'oui' if m['stub'] else 'NON',
        'oui' if m['meta_yml'] else 'NON',
        'oui' if m['tests'] else 'NON'))
w('')

io.open('docs/processes.md', 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print('docs/processes.md - {} process definis, {} executes'.format(len(real), len(executed)))
