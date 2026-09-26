#!/usr/bin/env python3
"""
Write a PlastizymeFinder --contigs_input samplesheet from an nf-core/mag
results directory, so that mag's assemblies and bins feed stages 5-8.

nf-core/mag (5.x) publishes:
  Assembly/<assembler>/<assembler>-<id>.contigs.fa.gz          (MEGAHIT)
  Assembly/<assembler>/<assembler>-<id>_scaffolds.fasta.gz     (SPAdes)
  GenomeBinning/<binner>/bins/<assembler>-<binner>-<id>.<n>.fa.gz
  GenomeBinning/DASTool/bins/<assembler>-<binner>Refined-<id>.<n>.fa

<id> is the sample, or the group with --coassemble_group.

Usage:
  mag2plastizyme.py --mag_outdir results_mag [--assembler MEGAHIT]
                    [--binner MetaBAT2 | DASTool | none] > contigs_input.csv
"""

import argparse
import csv
import fnmatch
import os
import sys

BIN_EXTENSIONS = (".fa", ".fa.gz", ".fasta", ".fasta.gz", ".fna", ".fna.gz")

# Assembly file name, per assembler, around the sample/group id.
ASSEMBLY_SUFFIXES = {
    "MEGAHIT": [".contigs.fa.gz"],
    "SPAdes": ["_scaffolds.fasta.gz", "_contigs.fasta.gz"],
    "SPAdesHybrid": ["_scaffolds.fasta.gz", "_contigs.fasta.gz"],
}


def find_assemblies(mag_outdir, assembler):
    folder = os.path.join(mag_outdir, "Assembly", assembler)
    if not os.path.isdir(folder):
        sys.exit("ERROR: no assembly folder at {}".format(folder))
    prefix = assembler + "-"
    assemblies = {}
    for suffix in ASSEMBLY_SUFFIXES.get(assembler, [".contigs.fa.gz"]):
        for name in sorted(os.listdir(folder)):
            if name.startswith(prefix) and name.endswith(suffix):
                sample = name[len(prefix) : -len(suffix)]
                assemblies.setdefault(sample, os.path.join(folder, name))
    if not assemblies:
        sys.exit("ERROR: no {} assembly found in {}".format(assembler, folder))
    return assemblies


def bin_glob(mag_outdir, assembler, binner, sample, samples):
    folder = os.path.abspath(os.path.join(mag_outdir, "GenomeBinning", binner, "bins"))
    if not os.path.isdir(folder):
        sys.exit("ERROR: no bin folder at {}".format(folder))
    # A glob that also catches another sample whose id ends with this one
    # ("x" vs "a-x") would mix their bins: refuse rather than guess.
    clashes = [s for s in samples if s != sample and s.endswith("-" + sample)]
    if clashes:
        sys.exit(
            "ERROR: sample '{}' cannot be told apart from {} in bin names".format(sample, clashes)
        )
    pattern = "{}-*-{}.*".format(assembler, sample)
    matches = [
        name
        for name in os.listdir(folder)
        if fnmatch.fnmatch(name, pattern) and name.endswith(BIN_EXTENSIONS)
    ]
    if not matches:
        sys.stderr.write(
            "mag2plastizyme.py: WARN no {} bin for {} - all its contigs will be screened as unbinned\n".format(
                binner, sample
            )
        )
        return ""
    return os.path.join(folder, pattern)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--mag_outdir", required=True, help="nf-core/mag --outdir")
    parser.add_argument("--assembler", default="MEGAHIT", help="Assembly/<assembler> folder (default: MEGAHIT)")
    parser.add_argument(
        "--binner",
        default="DASTool",
        help="GenomeBinning/<binner> folder: DASTool (default), MetaBAT2, MaxBin2, CONCOCT, ... or 'none' for contigs only",
    )
    args = parser.parse_args()

    assemblies = find_assemblies(args.mag_outdir, args.assembler)
    writer = csv.writer(sys.stdout, lineterminator="\n")
    writer.writerow(["sample", "contigs", "bins"])
    for sample in sorted(assemblies):
        bins = (
            ""
            if args.binner.lower() == "none"
            else bin_glob(args.mag_outdir, args.assembler, args.binner, sample, assemblies)
        )
        writer.writerow([sample, os.path.abspath(assemblies[sample]), bins])

    sys.stderr.write("mag2plastizyme.py: wrote {} sample(s)\n".format(len(assemblies)))


if __name__ == "__main__":
    main()
