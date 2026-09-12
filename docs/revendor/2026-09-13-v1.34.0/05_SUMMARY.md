# 05 — Summary: LibKa0s v1.33.0 → v1.34.0

**Tag moved v1.33.0 → v1.34.0 (`9165044` → `33bae81`).** Three library files moved: `Slash.lua`
(minor 9 → 10), `Options.lua` (minor 17 → 18) and `OptionsCompose.lua` (minor 4 → 5). The kit moved
revision 18 → 19. Every other file keeps its minor. The per-file table is in `01_DELTA.md`. Nothing
was deleted inside either payload.

**Reached the addon for free (class A).** The tooltip, whose text does not move, and kit revision
19's keyless `OnProfileReset`, which the handler never read. See `02_CANDIDATES.md` for what each
means here.

**References rolled.**

- `CLAUDE.md:34`, the provenance line.
- `docs/ARCHITECTURE.md:332`, the vendored-library sentence.

**Comments corrected.** None in the re-vendor commit. The two test comments that describe the old
parse move with the adoption.

**Adopted:** the `parse` simplification, in the commit after the re-vendor (see `03_DECISIONS.md`).
**Declined:** none. **Skipped or unreached:** none.

**Gates.**

| Point | `lua tests/run.lua` | `luacheck .` | `lizard -C 15` |
|---|---|---|---|
| Before the copy | 350 passed, 0 failed, 0 skipped, 350 total | 0 / 0 in 44 files | clean, no function above CCN 15 |
| After the copy, the roll and this bundle | 350 passed, 0 failed, 0 skipped, 350 total | 0 / 0 in 44 files | clean, no function above CCN 15 |

The vendored-payload pair ran rather than skipped, against `../LibKa0s` at `v1.34.0`, and passed.
No suite total moved at the re-vendor. Nothing was pushed, and no issue was filed.
