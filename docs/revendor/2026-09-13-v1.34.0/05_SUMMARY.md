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

**Comments corrected.** None in the re-vendor commit. The adoption corrects the two test comments that
described the old first-word parse (`tests/test_slash.lua:217`, `tests/test_libka0s.lua:550`), and
the live docs that did the same (`docs/slash-dispatch.md:39`, `:72`, `:85`, `docs/ARCHITECTURE.md:143`,
`docs/module-map.md:233`).

**Adopted:** the `parse` simplification, in the commit after the re-vendor (see `03_DECISIONS.md`).
**Declined:** none. **Skipped or unreached:** none.

**Gates.**

| Point | `lua tests/run.lua` | `luacheck .` | `lizard -C 15` |
|---|---|---|---|
| Before the copy | 350 passed, 0 failed, 0 skipped, 350 total | 0 / 0 in 44 files | clean, no function above CCN 15 |
| After the copy, the roll and this bundle | 350 passed, 0 failed, 0 skipped, 350 total | 0 / 0 in 44 files | clean, no function above CCN 15 |
| After the adoption (the parse simplification) | 351 passed, 0 failed, 0 skipped, 351 total | 0 / 0 in 44 files | clean, no function above CCN 15 |

The vendored-payload pair ran rather than skipped, against `../LibKa0s` at `v1.34.0`, and passed.
No suite total moved at the re-vendor. The adoption adds one case and moves the total to 351;
`docs/test-cases.md` and the README badge move with it. The case is red against the pre-simplification
adapter, which kept the trailing spaces of a direct `CliSet`. It is also red with minor 9's `Slash.lua`
swapped in under the simplified adapter, which then stored only the first word. Dropping the `||`
unescape turns it and the round-trip case red. Nothing was pushed, and no issue was filed.
