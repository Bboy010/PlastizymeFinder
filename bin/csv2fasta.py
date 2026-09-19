#!/usr/bin/env python3
"""
Convert a MeTarEnz screening_results.csv into a protein FASTA of candidates.

MeTarEnz names the sequence column differently depending on the screening mode:
  - contig_screening (cs): 'translation'  — six-frame translation of the hit
  - protein_screening (ps): 'query_seq'   — aligned query sequence

Usage: csv2fasta.py <screening_results.csv> <sequence_column> <output.faa>
"""

import csv
import sys

csv.field_size_limit(min(sys.maxsize, 2**31 - 1))


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__.strip())

    csv_path, seq_column, fasta_path = sys.argv[1:4]
    written = 0

    with open(csv_path, newline="") as handle, open(fasta_path, "w") as out:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None or seq_column not in reader.fieldnames:
            sys.exit(
                "ERROR: column '{}' not found in {} (columns: {})".format(
                    seq_column, csv_path, reader.fieldnames
                )
            )
        for row in reader:
            sequence = (row.get(seq_column) or "").replace("-", "").strip()
            identifier = (row.get("query_id") or "").strip()
            if not sequence or not identifier:
                continue
            bitscore = (row.get("bitscore") or "NA").strip()
            source = (row.get("source_seq_id") or "NA").strip()
            out.write(">{} bitscore={} ref={}\n".format(identifier, bitscore, source))
            for i in range(0, len(sequence), 60):
                out.write(sequence[i : i + 60] + "\n")
            written += 1

    sys.stderr.write("csv2fasta.py: wrote {} candidate sequence(s)\n".format(written))


if __name__ == "__main__":
    main()
