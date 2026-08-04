#!/usr/bin/env python3
"""
Split GlobalStrings.lua into manageable chunk files for GlobalStrings.

Reads GlobalStrings.lua, parses KEY = "value"; entries (ignoring _G["KEY"] entries),
then splits them into evenly-sized chunks that each stay under layout-§1's 1500-LOC cap.

The chunks are cut by ENTRY COUNT, not by first letter. Letter grouping was the
original design and it cannot satisfy the cap: `S` alone is 3283 entries, and `E`,
`C`, `P` and `B` are each over the per-file budget too, so any scheme that keeps a
letter whole ships a file over 1500 lines. GlobalStrings.lua is sorted by key, so
cutting by count still leaves every chunk a contiguous alphabetical range — the
property that made letter grouping readable — without the cap violation.

Nothing depends on which chunk a key lands in: each chunk only assigns into the
shared NS.GlobalStrings table, so the split point is free to move.

Usage:
    python GlobalStrings/split_globalstrings.py
"""

import collections
import glob
import os
import re
import sys

# Entry lines allowed in one chunk. Each file is this plus the two header lines.
#
# Set below 1000, not below 1500. layout-§1 caps a file at 1500 and puts the
# 1000-1500 band "on notice", and performance-§10 requires the complexity report
# to list every on-notice file with a disposition. Chunks sized just under the
# hard cap are legal but would put ~17 rows of "accepted, generated data" in that
# watch list every release, burying the hand-written code the report exists to
# flag. Staying under 1000 keeps generated data out of the report entirely; the
# only cost is more files in the TOC, which costs a reader nothing.
MAX_ENTRIES_PER_CHUNK = 900

# Pattern for KEY = "value"; format (ignores _G["KEY"] = "value"; entries)
RE_SIMPLE = re.compile(r'^([A-Z_][A-Z0-9_]*)\s*=\s*"(.*)"\s*;\s*$')

# Canonical sort order for first characters, used for the distribution printout.
LETTER_ORDER = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789")

# The TOC that loads the chunks, and the comment that opens its chunk block.
TOC_NAME = "PrettyChat.toc"
TOC_MARKER = "# GlobalStrings"


def parse_globalstrings(filepath):
    """Parse GlobalStrings.lua and return list of (key, value) tuples."""
    entries = []
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n\r")
            m = RE_SIMPLE.match(line)
            if m:
                entries.append((m.group(1), m.group(2)))
    return entries


def compute_chunks(entries, max_per_chunk):
    """Split entries into the fewest even chunks that all fit under max_per_chunk.

    Returns a list of entry lists. Sizes differ by at most one, so no chunk sits
    near the cap while another is half empty, and the chunk count only moves when
    Blizzard's string count moves enough to need another file.
    """
    total = len(entries)
    num_chunks = -(-total // max_per_chunk)  # ceil
    base, remainder = divmod(total, num_chunks)

    chunks = []
    start = 0
    for i in range(num_chunks):
        size = base + (1 if i < remainder else 0)
        chunks.append(entries[start:start + size])
        start += size
    return chunks


def rewrite_toc(toc_path, chunk_filenames):
    """Replace the TOC's GlobalStrings chunk list with the files just written.

    The chunk count moves whenever Blizzard's string count crosses a multiple of
    MAX_ENTRIES_PER_CHUNK, and a TOC updated by hand is how a chunk silently stops
    loading. Rewriting it here keeps the two in step by construction.
    """
    with open(toc_path, "r", encoding="utf-8", newline="") as f:
        raw = f.read()
    newline = "\r\n" if "\r\n" in raw else "\n"
    lines = raw.split(newline)

    try:
        marker = next(i for i, ln in enumerate(lines) if ln.startswith(TOC_MARKER))
    except StopIteration:
        print(f"Error: no '{TOC_MARKER}' block in {toc_path}", file=sys.stderr)
        sys.exit(1)

    end = marker + 1
    while end < len(lines) and lines[end].startswith("GlobalStrings\\"):
        end += 1

    new_lines = [f"GlobalStrings\\{name}" for name in chunk_filenames]
    if lines[marker + 1:end] == new_lines:
        print(f"  {TOC_NAME} chunk list already matches — unchanged")
        return

    lines[marker + 1:end] = new_lines
    with open(toc_path, "w", encoding="utf-8", newline="") as f:
        f.write(newline.join(lines))
    print(f"  {TOC_NAME} chunk list rewritten to {len(chunk_filenames)} entries")


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    input_path = os.path.join(script_dir, "GlobalStrings.lua")
    output_dir = script_dir

    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found", file=sys.stderr)
        sys.exit(1)

    # Clean up old chunk files
    for old_file in glob.glob(os.path.join(output_dir, "GlobalStrings_*.lua")):
        os.remove(old_file)
        print(f"  Removed {os.path.basename(old_file)}")

    print(f"Parsing {input_path}...")
    entries = parse_globalstrings(input_path)
    print(f"Total entries parsed: {len(entries)}")

    # Print letter distribution
    letter_counts = collections.Counter()
    for key, _ in entries:
        letter_counts[key[0].upper()] += 1
    print(f"\nLetter distribution:")
    for ch in LETTER_ORDER:
        if ch in letter_counts:
            print(f"  {ch}: {letter_counts[ch]}")
    for ch in sorted(letter_counts):
        if ch not in LETTER_ORDER:
            print(f"  {ch}: {letter_counts[ch]}")
    print(f"  Max entries per chunk: {MAX_ENTRIES_PER_CHUNK}")

    # Cut into evenly-sized, alphabetically contiguous chunks under the cap.
    chunks = compute_chunks(entries, MAX_ENTRIES_PER_CHUNK)

    # Write chunk files
    print()
    total_written = 0
    chunk_filenames = []
    for i, items in enumerate(chunks):
        filename = f"GlobalStrings_{i + 1:03d}.lua"
        filepath = os.path.join(output_dir, filename)
        key_range = f"{items[0][0]}..{items[-1][0]}"

        # CRLF, because .gitattributes pins `* text=auto eol=crlf` and the working
        # tree is expected to match it. Git normalizes the blob to LF either way, so
        # writing LF here leaves the repo correct and the checkout wrong — an
        # invisible drift, since the clean filter makes `git status` read clean
        # regardless. That is exactly what LIBKA0S-16 had to repair by hand.
        with open(filepath, "w", encoding="utf-8", newline="\r\n") as f:
            # Populate the addon-private NS.GlobalStrings (PC-14). `...` yields
            # PrettyChat's namespace under the only load path there is — the
            # chunk list in PrettyChat.toc.
            f.write("local _, NS = ...\n")
            f.write("NS.GlobalStrings = NS.GlobalStrings or {}\n")
            for key, value in items:
                f.write(f'NS.GlobalStrings["{key}"] = "{value}"\n')

        lines = len(items) + 2
        print(f"  {filename} [{key_range}]: {len(items)} entries, {lines} lines")
        chunk_filenames.append(filename)
        total_written += len(items)

    over = [n for n, c in zip(chunk_filenames, chunks) if len(c) + 2 > 1500]
    if over:
        print(f"ERROR: over layout-§1's 1500-LOC cap: {', '.join(over)}", file=sys.stderr)
        sys.exit(1)

    banded = [n for n, c in zip(chunk_filenames, chunks) if len(c) + 2 >= 1000]
    if banded:
        print(
            f"WARNING: in layout-§1's 1000-1500 on-notice band, so the complexity "
            f"report must list them: {', '.join(banded)}",
            file=sys.stderr,
        )

    # Keep the TOC's chunk list in step with what was just written.
    print()
    rewrite_toc(os.path.join(os.path.dirname(script_dir), TOC_NAME), chunk_filenames)

    print(f"\nWrote {len(chunk_filenames)} chunk files, all under the 1500-LOC cap")
    print(f"Total entries written: {total_written}")
    if total_written != len(entries):
        print("WARNING: Entry count mismatch!", file=sys.stderr)
        sys.exit(1)
    print("Done!")


if __name__ == "__main__":
    main()
