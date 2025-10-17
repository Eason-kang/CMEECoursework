#!/usr/bin/env python3
"""
align_seq.py

Read two DNA sequences from a single CSV file (default: ../data/DNAseq.csv),
find the best alignment of the shorter sequence against the longer sequence,
and write the best alignment and score to ../results/best_alignment.txt.

Run:
    python align_seq.py
"""

import os
import sys
import csv
from typing import Tuple, List

INPUT_PATH  = "../data/Twoseqs.csv"        
OUTPUT_DIR  = "../results"
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "best_alignment.txt")

def _clean(seq: str) -> str:
    """Return an uppercase DNA sequence with whitespace removed."""
    return "".join(seq.split()).upper()


def _read_two_sequences(path: str) -> Tuple[str, str]:
   
    sequences: List[str] = []
    with open(path, newline="") as f:
        r = csv.reader(f)
        first = next(r, None)
        if first is None:
            raise ValueError("Input CSV is empty.")

        header_lc = [c.strip().lower() for c in first]
        if "sequence" in header_lc:
            idx = header_lc.index("sequence")
            for row in r:
                if len(row) > idx and row[idx].strip():
                    sequences.append(_clean(row[idx]))
        else:
            for cell in first:
                if cell and cell.strip():
                    sequences.append(_clean(cell))
            for row in r:
                for cell in row:
                    if cell and cell.strip():
                        sequences.append(_clean(cell))

   
    sequences = [s for s in sequences if s]
    if len(sequences) < 2:
        raise ValueError("Need at least two sequences in the CSV.")
    return sequences[0], sequences[1]


def calculate_score(long_seq: str, short_seq: str, start: int) -> Tuple[int, str]:
    overlap = min(len(long_seq) - start, len(short_seq))
    score = 0
    matched = []
    for i in range(overlap):
        if long_seq[i + start] == short_seq[i]:
            matched.append("*")
            score += 1
        else:
            matched.append("-")
    return score, ("." * start) + "".join(matched)


def best_alignment(seq1: str, seq2: str) -> Tuple[str, str, str, int, int]:
    if len(seq1) >= len(seq2):
        long_seq, short_seq = seq1, seq2
    else:
        long_seq, short_seq = seq2, seq1

    best_score = -1
    best_start = 0
    best_align = ""
    best_match = ""

    for start in range(len(long_seq)):
        if start >= len(long_seq):  # safety
            break
        score, match_line = calculate_score(long_seq, short_seq, start)
        if score >= best_score:     # keep the *last* best, like the original script
            best_score = score
            best_start = start
            best_align = ("." * start) + short_seq
            best_match = match_line

    return long_seq, best_align, best_match, best_score, best_start


def main(argv: List[str]) -> int:
    try:
        raw1, raw2 = _read_two_sequences(INPUT_PATH)
    except FileNotFoundError:
        print(f"ERROR: Input file not found: {INPUT_PATH}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"ERROR reading sequences: {e}", file=sys.stderr)
        return 1

    long_seq, aligned_short, match_line, score, start = best_alignment(raw1, raw2)

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    with open(OUTPUT_FILE, "w") as out:
        out.write("Best alignment (short onto long):\n")
        out.write(f"{aligned_short}\n")
        out.write(f"{match_line}\n")
        out.write(f"{long_seq}\n")
        out.write(f"Start position: {start}\n")
        out.write(f"Best score: {score}\n")

    print(f"Wrote best alignment to {OUTPUT_FILE}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
