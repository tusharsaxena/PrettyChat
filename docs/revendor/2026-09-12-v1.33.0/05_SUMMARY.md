# 05 — Summary: LibKa0s v1.32.0 → v1.33.0

**Tag moved v1.32.0 → v1.33.0 (`7d5e061` → `06ee368`).** Two library files moved: `Options.lua`
(minor 16 → 17) and `Slash.lua` (minor 8 → 9). The kit moved revision 17 → 18. Every other file
keeps its minor. The per-file table is in `01_DELTA.md`. Nothing was deleted inside either payload.

**Reached the addon for free (class A).** The font preload, the docstrings and the kit's
`OnProfileCopied` key. See `02_CANDIDATES.md` for what each means here.

**References rolled.**

- `CLAUDE.md:34`, the provenance line.
- `docs/ARCHITECTURE.md:332`, the vendored-library sentence.

**Comments corrected (kit revision 18).**

- `tests/test_debuglog.lua:382`: said the kit's AceDB fake passes the active profile in the source's place; it now says the direct call pins the handler's contract apart from the fake, which since revision 18 also passes the source.

**Adopted:** none. **Declined:** none. **Skipped or unreached:** none.

**Gates at the re-vendor commit.**

| Point | `lua tests/run.lua` | `luacheck .` | `lizard -C 15` |
|---|---|---|---|
| Before the copy | 350 passed, 0 failed, 0 skipped, 350 total | 0 / 0 in 44 files | clean, no function above CCN 15 |
| After the copy, the roll and the comments | 350 passed, 0 failed, 0 skipped, 350 total | 0 / 0 in 44 files | clean, no function above CCN 15 |

The vendored-payload pair ran rather than skipped, against `../LibKa0s` at `v1.33.0`, and passed.
No suite printed an error line. Nothing was pushed, and no issue was filed.
