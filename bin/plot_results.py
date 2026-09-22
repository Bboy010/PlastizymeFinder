#!/usr/bin/env python3
"""
Build the PlastizymeFinder figure set from a results directory.

Reads the raw outputs each tool already writes (Kraken2 report, MetaPhlAn
profile, QUAST report, dRep tables, fastp JSON) and renders one figure per
question. Every figure is written as PNG; a Krona text file is emitted
alongside so an ImportText step can turn it into the interactive sunburst.

Usage: plot_results.py <results_dir> <figures_dir>
"""

import json
import os
import sys

import matplotlib
matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np

# --- palette -----------------------------------------------------------------
# Validated categorical slots 1-2 and the blue sequential ramp.
SURFACE = "#fcfcfb"
INK = "#0b0b0b"
INK_SOFT = "#52514e"
GRID = "#e3e2de"
SERIES_1 = "#2a78d6"
SERIES_2 = "#eb6834"
SEQ = ["#cde2fb", "#9ec5f4", "#6da7ec", "#3987e5", "#256abf", "#184f95", "#0d366b"]

plt.rcParams.update({
    "figure.facecolor": SURFACE,
    "axes.facecolor": SURFACE,
    "savefig.facecolor": SURFACE,
    "font.size": 10,
    "font.family": "DejaVu Sans",
    "text.color": INK,
    "axes.labelcolor": INK_SOFT,
    "xtick.color": INK_SOFT,
    "ytick.color": INK_SOFT,
    "axes.edgecolor": GRID,
    "axes.linewidth": 0.8,
    "figure.dpi": 160,
})

RANKS = {"D": "domain", "P": "phylum", "C": "class", "O": "order",
         "F": "family", "G": "genus", "S": "species"}


def finish(ax, title, subtitle=None):
    # The subtitle sits between the title and the plot frame, so the title
    # needs enough padding to clear it.
    ax.set_title(title, loc="left", fontsize=13, fontweight="bold",
                 color=INK, pad=28 if subtitle else 8)
    if subtitle:
        ax.text(0, 1.012, subtitle, transform=ax.transAxes, fontsize=9.5,
                color=INK_SOFT, va="bottom")
    for side in ("top", "right"):
        ax.spines[side].set_visible(False)


def save(fig, outdir, name):
    path = os.path.join(outdir, name)
    fig.savefig(path, bbox_inches="tight")
    plt.close(fig)
    print("  " + path)
    return path


# --- readers -----------------------------------------------------------------

def read_kraken(path):
    """Kraken2 report: pct, clade_reads, direct_reads, rank, taxid, name."""
    rows = []
    with open(path) as fh:
        for line in fh:
            f = line.rstrip("\n").split("\t")
            if len(f) < 6:
                continue
            rows.append({
                "pct": float(f[0]), "reads": int(f[1]), "rank": f[3],
                "name": f[5].strip(), "depth": (len(f[5]) - len(f[5].lstrip())) // 2,
            })
    return rows


def read_metaphlan(path):
    out = []
    with open(path) as fh:
        for line in fh:
            if line.startswith("#"):
                continue
            f = line.rstrip("\n").split("\t")
            if len(f) < 3:
                continue
            out.append((f[0], float(f[2])))
    return out


def read_tsv_pairs(path):
    d = {}
    with open(path) as fh:
        for line in fh:
            f = line.rstrip("\n").split("\t")
            if len(f) == 2:
                d[f[0]] = f[1]
    return d


# --- figures -----------------------------------------------------------------

def fig_taxa_bar(kraken, outdir):
    species = [r for r in kraken if r["rank"] == "S"]
    species.sort(key=lambda r: r["pct"], reverse=True)
    top = species[:15][::-1]
    if not top:
        return None

    fig, ax = plt.subplots(figsize=(8.2, 5.6))
    y = np.arange(len(top))
    ax.barh(y, [r["pct"] for r in top], height=0.62, color=SERIES_1, zorder=3)
    ax.set_yticks(y)
    ax.set_yticklabels([r["name"] for r in top], fontsize=9)
    ax.set_xlabel("share of classified reads (%)")
    ax.xaxis.grid(True, color=GRID, linewidth=0.8, zorder=0)
    ax.set_axisbelow(True)

    widest = max(r["pct"] for r in top)
    for yi, r in zip(y, top):
        ax.text(r["pct"] + widest * 0.015, yi, "{:.2f}".format(r["pct"]),
                va="center", fontsize=8.5, color=INK_SOFT)

    unclassified = next((r["pct"] for r in kraken if r["name"] == "unclassified"), None)
    sub = "Kraken2 - 15 most abundant species"
    if unclassified is not None:
        sub += "  ·  {:.1f}% of reads unclassified".format(unclassified)
    finish(ax, "Taxonomic composition", sub)
    return save(fig, outdir, "01_taxonomy_kraken2.png")


def fig_rank_profile(kraken, outdir):
    """How many taxa are resolved at each rank - shows where the signal dies."""
    counts = {code: 0 for code in RANKS}
    for r in kraken:
        if r["rank"] in counts and r["pct"] > 0:
            counts[r["rank"]] += 1
    order = ["D", "P", "C", "O", "F", "G", "S"]
    vals = [counts[c] for c in order]
    if not any(vals):
        return None

    fig, ax = plt.subplots(figsize=(7.4, 3.8))
    x = np.arange(len(order))
    ax.bar(x, vals, width=0.6, color=SERIES_1, zorder=3)
    ax.set_xticks(x)
    ax.set_xticklabels([RANKS[c] for c in order], fontsize=9.5)
    ax.set_ylabel("distinct taxa")
    ax.yaxis.grid(True, color=GRID, linewidth=0.8, zorder=0)
    ax.set_axisbelow(True)
    for xi, v in zip(x, vals):
        ax.text(xi, v + max(vals) * 0.02, str(v), ha="center",
                fontsize=9, color=INK_SOFT)
    finish(ax, "Taxonomic resolution by rank",
           "Kraken2 - taxa detected at each level")
    return save(fig, outdir, "02_taxonomic_ranks.png")


def fig_metaphlan(profile, outdir):
    species = [(n.split("|")[-1], v) for n, v in profile
               if "|s__" in n and "|t__" not in n]
    species = [(n.replace("s__", "").replace("_", " "), v) for n, v in species]
    species.sort(key=lambda t: t[1], reverse=True)
    top = species[:12][::-1]
    if not top:
        return None

    fig, ax = plt.subplots(figsize=(8.2, 4.8))
    y = np.arange(len(top))
    ax.barh(y, [v for _, v in top], height=0.62, color=SERIES_2, zorder=3)
    ax.set_yticks(y)
    ax.set_yticklabels([n for n, _ in top], fontsize=9)
    ax.set_xlabel("relative abundance (%)")
    ax.xaxis.grid(True, color=GRID, linewidth=0.8, zorder=0)
    ax.set_axisbelow(True)
    widest = max(v for _, v in top)
    for yi, (_, v) in zip(y, top):
        ax.text(v + widest * 0.015, yi, "{:.2f}".format(v), va="center",
                fontsize=8.5, color=INK_SOFT)
    finish(ax, "MetaPhlAn4 abundance profile",
           "12 dominant species - marker-based relative abundance")
    return save(fig, outdir, "03_metaphlan_species.png")


def fig_mash_heatmap(mdb_path, outdir):
    import csv
    sim, names = {}, set()
    with open(mdb_path) as fh:
        for row in csv.DictReader(fh):
            a = row["genome1"].replace(".fa", "")
            b = row["genome2"].replace(".fa", "")
            names.update((a, b))
            sim[(a, b)] = float(row["similarity"])

    def key(n):
        tail = n.rsplit(".", 1)[-1]
        return int(tail) if tail.isdigit() else 0

    labels = sorted(names, key=key)
    n = len(labels)
    if n < 2:
        return None
    m = np.zeros((n, n))
    for i, a in enumerate(labels):
        for j, b in enumerate(labels):
            m[i, j] = sim.get((a, b), sim.get((b, a), 0.0))

    cmap = matplotlib.colors.LinearSegmentedColormap.from_list("seq", SEQ)
    fig, ax = plt.subplots(figsize=(7.6, 6.6))
    im = ax.imshow(m, cmap=cmap, vmin=0, vmax=1, interpolation="nearest")
    short = [l.split(".")[-1] for l in labels]
    ax.set_xticks(np.arange(n))
    ax.set_yticks(np.arange(n))
    ax.set_xticklabels(short, fontsize=6.5, rotation=90)
    ax.set_yticklabels(short, fontsize=6.5)
    ax.set_xlabel("bin")
    cb = fig.colorbar(im, ax=ax, fraction=0.046, pad=0.03)
    cb.set_label("MASH similarity", color=INK_SOFT)
    cb.outline.set_visible(False)
    off = m[~np.eye(n, dtype=bool)]
    finish(ax, "Similarity between bins",
           "dRep / MASH - {} bins, highest off-diagonal similarity {:.2f}"
           .format(n, off.max() if off.size else 0.0))
    return save(fig, outdir, "04_bin_similarity.png")


def fig_bin_scatter(geninfo_path, outdir):
    import csv
    lengths, n50s, names = [], [], []
    with open(geninfo_path) as fh:
        for row in csv.DictReader(fh):
            lengths.append(int(row["length"]))
            n50s.append(int(row["N50"]))
            names.append(row["genome"].replace(".fa", ""))
    if not lengths:
        return None

    fig, ax = plt.subplots(figsize=(7.6, 5.0))
    ax.scatter(np.array(lengths) / 1e6, n50s, s=64, color=SERIES_1,
               edgecolor=SURFACE, linewidth=1.6, zorder=3)
    ax.set_xlabel("bin size (Mb)")
    ax.set_ylabel("bin N50 (bp)")
    ax.grid(True, color=GRID, linewidth=0.8, zorder=0)
    ax.set_axisbelow(True)

    # label only the extremes - never a label on every point
    for i in np.argsort(lengths)[::-1][:3]:
        ax.annotate(names[i].split(".", 1)[-1], (lengths[i] / 1e6, n50s[i]),
                    textcoords="offset points", xytext=(8, 4),
                    fontsize=8.5, color=INK_SOFT)
    finish(ax, "Metagenome bin quality",
           "{} MetaBAT2 bins - size against contiguity".format(len(lengths)))
    return save(fig, outdir, "05_bin_quality.png")


def fig_assembly(report_path, outdir):
    d = read_tsv_pairs(report_path)
    thresholds = [0, 1000, 5000, 10000, 25000, 50000]
    counts, lengths = [], []
    for t in thresholds:
        counts.append(int(d.get("# contigs (>= {} bp)".format(t), 0)))
        lengths.append(int(d.get("Total length (>= {} bp)".format(t), 0)) / 1e6)
    if not any(counts):
        return None

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(9.6, 3.9))
    x = np.arange(len(thresholds))
    labels = ["≥{}".format("0" if t == 0 else "{}k".format(t // 1000))
              for t in thresholds]

    ax1.bar(x, counts, width=0.6, color=SERIES_1, zorder=3)
    ax1.set_xticks(x)
    ax1.set_xticklabels(labels, fontsize=9)
    ax1.set_ylabel("contigs")
    ax1.set_xlabel("minimum length (bp)")
    ax1.yaxis.grid(True, color=GRID, linewidth=0.8, zorder=0)
    ax1.set_axisbelow(True)
    finish(ax1, "Contigs", None)

    ax2.bar(x, lengths, width=0.6, color=SERIES_2, zorder=3)
    ax2.set_xticks(x)
    ax2.set_xticklabels(labels, fontsize=9)
    ax2.set_ylabel("cumulative assembly (Mb)")
    ax2.set_xlabel("minimum length (bp)")
    ax2.yaxis.grid(True, color=GRID, linewidth=0.8, zorder=0)
    ax2.set_axisbelow(True)
    finish(ax2, "Cumulative length", None)

    fig.suptitle("Metagenome assembly  ·  N50 {} bp  ·  largest contig {:.2f} Mb"
                 .format(d.get("N50", "?"), int(d.get("Largest contig", 0)) / 1e6),
                 x=0.005, ha="left", fontsize=12.5, fontweight="bold", color=INK)
    fig.tight_layout(rect=(0, 0, 1, 0.94))
    return save(fig, outdir, "06_assembly.png")


def fig_qc(fastp_json, outdir):
    with open(fastp_json) as fh:
        d = json.load(fh)
    before, after = d["summary"]["before_filtering"], d["summary"]["after_filtering"]
    metrics = [
        ("reads (M)", before["total_reads"] / 1e6, after["total_reads"] / 1e6),
        ("bases (Gb)", before["total_bases"] / 1e9, after["total_bases"] / 1e9),
        ("Q30 (%)", before["q30_rate"] * 100, after["q30_rate"] * 100),
        ("GC (%)", before["gc_content"] * 100, after["gc_content"] * 100),
    ]
    fig, ax = plt.subplots(figsize=(7.8, 4.0))
    x = np.arange(len(metrics))
    w = 0.36
    bars_before = ax.bar(x - w / 2 - 0.01, [m[1] for m in metrics], w,
                         label="before", color=SERIES_1, zorder=3)
    bars_after = ax.bar(x + w / 2 + 0.01, [m[2] for m in metrics], w,
                        label="after", color=SERIES_2, zorder=3)
    ax.set_xticks(x)
    ax.set_xticklabels([m[0] for m in metrics], fontsize=9.5)
    ax.yaxis.grid(True, color=GRID, linewidth=0.8, zorder=0)
    ax.set_axisbelow(True)
    ax.legend(frameon=False, loc="upper right", fontsize=9)
    for bars in (bars_before, bars_after):
        for rect in bars:
            ax.text(rect.get_x() + rect.get_width() / 2, rect.get_height() * 1.02,
                    "{:.1f}".format(rect.get_height()), ha="center",
                    fontsize=8, color=INK_SOFT)
    finish(ax, "Read quality control", "fastp - before and after filtering")
    return save(fig, outdir, "07_read_quality.png")


def write_krona_text(kraken, outdir):
    """Krona input: count <TAB> rank1 <TAB> rank2 ... for an ImportText step."""
    path = os.path.join(outdir, "kraken2.krona.txt")
    lineage, wrote = {}, 0
    with open(path, "w") as out:
        for r in kraken:
            if r["name"] == "unclassified":
                out.write("{}\tunclassified\n".format(r["reads"]))
                wrote += 1
                continue
            lineage[r["depth"]] = r["name"]
            for d in list(lineage):
                if d > r["depth"]:
                    del lineage[d]
            direct = r["reads"] if r["rank"] == "S" else 0
            if direct:
                out.write("{}\t{}\n".format(
                    direct, "\t".join(lineage[d] for d in sorted(lineage))))
                wrote += 1
    print("  {}  ({} lines)".format(path, wrote))
    return path


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__.strip())
    res, outdir = sys.argv[1], sys.argv[2]
    os.makedirs(outdir, exist_ok=True)

    def under(*parts):
        q = os.path.join(res, *parts)
        return q if os.path.exists(q) else None

    def first_in(subdir, suffix):
        d = os.path.join(res, *subdir)
        if not os.path.isdir(d):
            return None
        hits = sorted(f for f in os.listdir(d) if f.endswith(suffix))
        return os.path.join(d, hits[0]) if hits else None

    print("Figures written:")
    made = []

    kraken_path = first_in(("taxonomy", "kraken2"), "report.txt")
    if kraken_path:
        kraken = read_kraken(kraken_path)
        made += [fig_taxa_bar(kraken, outdir), fig_rank_profile(kraken, outdir)]
        write_krona_text(kraken, outdir)

    mp = first_in(("taxonomy", "metaphlan4"), "_profile.txt")
    if mp:
        made.append(fig_metaphlan(read_metaphlan(mp), outdir))

    mdb = under("bin_qc", "drep", "drep_output", "data_tables", "Mdb.csv")
    if mdb:
        made.append(fig_mash_heatmap(mdb, outdir))

    gi = under("bin_qc", "drep", "drep_output", "data_tables", "genomeInformation.csv")
    if gi:
        made.append(fig_bin_scatter(gi, outdir))

    qa = (under("assembly", "quast", "assembly", "report.tsv")
          or under("assembly", "quast", "report.tsv"))
    if qa:
        made.append(fig_assembly(qa, outdir))

    fp = first_in(("fastp",), ".json")
    if fp:
        made.append(fig_qc(fp, outdir))

    n = len([m for m in made if m])
    print("\n{} figure(s) written to {}".format(n, outdir))
    if n == 0:
        print("No usable data found under " + res, file=sys.stderr)


if __name__ == "__main__":
    main()
