# GlobalStrings

A searchable copy of Blizzard's GlobalStrings (~22,879 entries), split into 26 chunk files. The chunks populate the addon-private `NS.GlobalStrings` table (each chunk begins `local _, NS = ...; NS.GlobalStrings = NS.GlobalStrings or {}`).

**Nothing loads these chunks at runtime (PC-R-05).** `PrettyChat.toc` carries no `GlobalStrings\` line and no `# GlobalStrings` section, and `.pkgmeta` keeps the whole folder out of the shipped zip. The chunks are repo-local reference data with exactly one reader, `tests/test_defaults.lua`, which loads them with `loadfile` to check every override against Blizzard's real signature — see [../docs/global-strings.md](../docs/global-strings.md) for why the eager load was removed and for the history of the removed LoadOnDemand sub-addon.

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
5. Asserts `PrettyChat.toc` still does **not** load the chunks (PC-R-05) and exits non-zero if the block has come back; exits non-zero if any chunk would land over 1500 lines, and warns if one enters the 1000-line on-notice band

Chunks are cut by entry count rather than by first letter because letter grouping cannot satisfy the cap: `S` alone is 3283 entries. `GlobalStrings.lua` is sorted by key, so each chunk is still a contiguous alphabetical range.

### When to re-run

Re-run this script whenever `GlobalStrings.lua` is updated (e.g., after a new WoW patch). You can get the latest GlobalStrings.lua [here](https://www.townlong-yak.com/framexml/live/Helix/GlobalStrings.lua).
