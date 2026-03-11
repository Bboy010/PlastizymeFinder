#!/usr/bin/env python3
"""
Validate PlastizymeFinder input samplesheet.
Checks format, file existence, and paired-end consistency.

Usage:
    check_samplesheet.py <samplesheet.csv> <output.csv>
"""

import csv
import os
import sys
from pathlib import Path


REQUIRED_COLUMNS = {"sample", "fastq_1"}
VALID_EXTENSIONS = {".fastq", ".fq", ".fastq.gz", ".fq.gz"}


def print_error(row_number, row, msg):
    if len(row) > 0:
        print(f"ERROR: Samplesheet row {row_number} [{'|'.join(row)}]: {msg}", file=sys.stderr)
    else:
        print(f"ERROR: Samplesheet row {row_number}: {msg}", file=sys.stderr)
    sys.exit(1)


def check_samplesheet(input_file, output_file):
    with open(input_file, "r", newline="") as fh:
        reader = csv.DictReader(fh, skipinitialspace=True)

        # Check required columns
        if not REQUIRED_COLUMNS.issubset(set(reader.fieldnames or [])):
            missing = REQUIRED_COLUMNS - set(reader.fieldnames or [])
            print(f"ERROR: Missing required columns: {missing}", file=sys.stderr)
            sys.exit(1)

        rows = []
        for row_number, row in enumerate(reader, start=2):
            sample = row["sample"].strip()
            fastq1 = row["fastq_1"].strip()
            fastq2 = row.get("fastq_2", "").strip()

            # Validate sample name
            if not sample:
                print_error(row_number, list(row.values()), "Sample name is empty")
            if " " in sample:
                print_error(row_number, list(row.values()), "Sample name must not contain spaces")

            # Validate fastq_1
            if not fastq1:
                print_error(row_number, list(row.values()), "fastq_1 is empty")
            ext1 = "".join(Path(fastq1).suffixes)
            if ext1 not in VALID_EXTENSIONS:
                print_error(row_number, list(row.values()),
                            f"fastq_1 extension '{ext1}' is not valid. Must be one of: {VALID_EXTENSIONS}")

            # Validate fastq_2 if provided
            single_end = True
            if fastq2:
                ext2 = "".join(Path(fastq2).suffixes)
                if ext2 not in VALID_EXTENSIONS:
                    print_error(row_number, list(row.values()),
                                f"fastq_2 extension '{ext2}' is not valid. Must be one of: {VALID_EXTENSIONS}")
                if fastq1 == fastq2:
                    print_error(row_number, list(row.values()),
                                "fastq_1 and fastq_2 are identical")
                single_end = False

            rows.append({
                "sample": sample,
                "fastq_1": fastq1,
                "fastq_2": fastq2,
                "single_end": str(single_end).lower()
            })

    # Write validated output
    with open(output_file, "w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=["sample", "fastq_1", "fastq_2", "single_end"])
        writer.writeheader()
        writer.writerows(rows)

    print(f"Samplesheet validated successfully: {len(rows)} sample(s)")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <samplesheet.csv> <output.csv}", file=sys.stderr)
        sys.exit(1)
    check_samplesheet(sys.argv[1], sys.argv[2])
