# Analysis — 20260807-110428

- **Addon:** PrettyChat 1.4.0
- **Verdict:** green
- **Commit:** 6782003e3139 (master), dirty
- **Started:** 2026-08-07T11:04:28+05:30
- **Previous run:** [`20260807-022707`](../20260807-022707/)

## Headline

This run exists to prove a **re-vendor**, not a code change. `libs/LibKa0s/` and `tests/_kit/` were
replaced wholesale from LibKa0s **v1.8.2** (`ac857fd9`), the provenance line in `CLAUDE.md` moved to
v1.8.2 in the same commit, and this is the first bundle in the record written by **kit revision 10**.
Nothing in the addon's own source moved, and the figures say so: lint is 0/0 over the same 17 files,
**260 of 260** cases pass with **0 skipped**, and every complexity number is byte-for-byte the
previous run's. The one thing that did change is invisible to the table above — **the bundle is CRLF
on disk**, which is what kit revision 10 fixes and what the previous nine runs got wrong.

The gate that went red on the last attempt, `tests/test_vendor_sync.lua`, **passes** — both cases,
against the tag rather than against `master`, and reporting PASS rather than the SKIP a missing
sibling would produce.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260807-022707` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 17 files | [`lint.txt`](lint.txt) | no change — 0/0 over the same 17 files |
| tests | pass | 260 passed, 0 failed, 0 skipped, 260 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | no change — same 260, same inventory |
| perf | skip | — no `tests/perf.lua`; this addon ships no offline scenarios | — (not run) | no change — skipped there too, same standing reason |
| complexity | pass | 0 warnings, max CCN 12 | [`complexity.txt`](complexity.txt) | **nothing moved** — every field identical |

### Complexity in full

Every field of `lizard`'s footer, from `manifest.json`'s `suites.complexity`, mirroring
[`complexity.txt`](complexity.txt):607-609.

| Metric | Value | vs `20260807-022707` |
|---|---|---|
| Total NLOC | 51337 | unchanged |
| Functions | 531 | unchanged |
| Avg NLOC / function | 6.4 | unchanged |
| Avg CCN | 1.9 | unchanged |
| Max CCN | 12 | unchanged |
| Avg tokens / function | 47.9 | unchanged |
| Warnings (CCN > 15) | 0 | unchanged |
| Warning rate — `Fun Rt` / `nloc Rt` | 0.00 / 0.00 | unchanged |
| Files in the 1000–1500 band | 0 | unchanged |
| Files over the 1500 cap | 1 | unchanged |

That every field is unchanged is the finding, not a lack of one. `lizard`'s scope excludes `libs/`
and `tests/_kit/` (`-x "./libs/*" -x "./tests/_kit/*"`), so a re-vendor **should** be invisible here —
and it is. A moved number would have meant the re-vendor reached somewhere it had no business
reaching.

`tests/perf.lua` is absent, so **nothing was measured about runtime cost**. `manifest.json` records
`"status": "skip"` with the reason; this run says nothing about whether the addon got faster or
slower.

One provenance caveat, recorded rather than corrected — a bundle is frozen evidence
(`automated-tests-§1`). `manifest.json` carries `"dirty": true`, so sha `6782003` does not describe
what was measured: the tree also held the re-vendored payload and the moved provenance line, which
are precisely what this run is evidence for. The bundle is written before the commit that carries it,
so `dirty` is the expected state here rather than a lapse.

## What moved

- **lint** — nothing. Same 17 files, same 0/0.
- **tests** — nothing in the counts, but two cases changed what they were asserting *against*:
  "libs/LibKa0s is the LibKa0s release CLAUDE.md says this addon bundles" and "tests/_kit is the test
  kit that shipped with that release" now resolve **v1.8.2** and pass. Before the re-vendor the same
  two cases failed, because `CLAUDE.md` and the bytes disagreed — which is exactly the drift the gate
  exists to catch, working as designed.
- **perf** — nothing, and nothing could.
- **complexity** — nothing. See above; this is the expected result, not an absence of measurement.
- **line endings — the real change.** Every file this run wrote carries CRLF, matching the repo's
  `* text=auto eol=crlf` pin: `complexity.txt` 609/609, `lint.txt` 19/19, `manifest.json` 19/19,
  `test-cases.md` 341/341, `tests.txt` 262/262 (CR count / LF count), and the appended
  `RESULTS.md` row leaves that file at 88/88. Kit revision 9 wrote all five LF, because the runner
  writes through plain shell redirects that bypass git's clean filter — invisible to `git status` and
  unreachable by `git add --renormalize`, which fixes the index and not the working tree. Revision 10
  adds a single `normalize_eol` pass over the finished directory that asks `git check-attr text eol`
  per path. Working-tree strays measured by `line-endings-§7`'s corrected check: **0 before, 0 after**.

## Complexity watch list

### Functions `lizard` warned on

**None.** Zero warnings over 531 functions — [`complexity.txt`](complexity.txt):605 states "No
thresholds exceeded" and the footer records `Warning cnt` 0. The highest-scoring function in the tree
is `Database.RunMigrations@30-50@./core/Database.lua` at CCN 12
([`complexity.txt`](complexity.txt):11), the same function at the same score as the previous two runs.
The five-function list from [`20260807-022707`](../20260807-022707/ANALYSIS.md) carries forward
unchanged: `Database.RunMigrations` (12), `buildParentBody` (11), `runTest` (11),
`PrettyChat:ApplyStrings` (11) and `sampleArg` (11). The next warned function is a regression against
that list.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| > 1500 (over cap) | `GlobalStrings/GlobalStrings.lua` | 23840 | **Accepted — not shipped and not loaded.** No TOC line references it and `.pkgmeta` excludes it; it is the build-time input `split_globalstrings.py` reads. Carried forward unchanged; nothing newly crossed a band this run. |

`automated-tests-§4`'s three-release shelf life has not started — every `manifest.json` in this record
carries `"release": null`, this one included.

## Actions

1. **`tests/perf.lua`** — still absent; the perf column stays a permanent `skip` and the record stays
   silent about runtime cost. Standing gap, carried forward from
   [`20260807-022707`](../20260807-022707/ANALYSIS.md), not arising here.
2. **`GlobalStrings/GlobalStrings.lua` over-cap disposition** — no action now; the first
   `--release X.Y.Z` run starts the shelf-life clock. Re-read the disposition there.
3. **Nothing from the re-vendor itself.** Both gating suites are green, the vendor gate passes against
   the tag, and the bundle now lands with the line endings the repo declares.
