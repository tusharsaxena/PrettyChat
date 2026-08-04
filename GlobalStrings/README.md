# GlobalStrings

A searchable copy of Blizzard's GlobalStrings (~22,879 entries), split into 26 chunk files. The chunks populate the addon-private `NS.GlobalStrings` table (each chunk begins `local _, NS = ...; NS.GlobalStrings = NS.GlobalStrings or {}`).

`PrettyChat.toc` loads `GlobalStrings_001.lua` … `GlobalStrings_026.lua` *eagerly at addon startup* so the Settings panel can show originals without an explicit load step. That is the only load path — see [../docs/global-strings.md](../docs/global-strings.md) for the history of the removed LoadOnDemand sub-addon.

## Files

- `GlobalStrings.lua` — Full Blizzard reference (~1.6 MB, source file, not loaded by any TOC; only used as input to `split_globalstrings.py`)
- `GlobalStrings_001.lua` ... `GlobalStrings_026.lua` — Chunk files, each a contiguous alphabetical range of keys
- `split_globalstrings.py` — Python script to regenerate chunk files from `GlobalStrings.lua`

## split_globalstrings.py

Parses `GlobalStrings.lua` for `KEY = "value";` entries (ignoring `_G["KEY"]` entries), then splits them into evenly-sized chunk files that each stay under `layout-§1`'s 1500-LOC cap.

### Usage

From the project root:

```
python3 GlobalStrings/split_globalstrings.py
```

### What it does

1. Prints letter distribution and the per-chunk entry cap
2. Cuts the sorted entries into the fewest even chunks that all fit under `MAX_ENTRIES_PER_CHUNK` (900 entries + 2 header lines)
3. Cleans up old `GlobalStrings_*.lua` files before writing new ones
4. Writes chunk files as `NS.GlobalStrings["KEY"] = "value"` assignments (with a `local _, NS = ...` header)
5. Rewrites `PrettyChat.toc`'s `# GlobalStrings` list to match, and exits non-zero if any chunk would land over 1500 lines, and warns if one enters the 1000-line on-notice band

Chunks are cut by entry count rather than by first letter because letter grouping cannot satisfy the cap: `S` alone is 3283 entries. `GlobalStrings.lua` is sorted by key, so each chunk is still a contiguous alphabetical range.

### When to re-run

Re-run this script whenever `GlobalStrings.lua` is updated (e.g., after a new WoW patch). You can get the latest GlobalStrings.lua [here](https://www.townlong-yak.com/framexml/live/Helix/GlobalStrings.lua).
