# Automated test results

<!-- The newest run is prepended by tests/_kit/run-automated-tests.sh. -->
<!-- This file is OVERWRITTEN IN PLACE — the git history of this one path is the trend line. -->

One row per run. The frozen evidence for each is in the dated folder beside this file;
the analysis of a given run is its `ANALYSIS.md`.

**`lint` and `tests` gate. `perf` and `complexity` are recorded and never fail a run** —
they are read and compared, not thresholded. A `skip` is a suite that did not run at all,
which is never the same as a pass.

| Run | Version | Lint w/e | Files | Tests | Perf | NLOC | Funcs | Avg NLOC | Avg CCN | Max CCN | CCN warn | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| [`20260804-233338`](20260804-233338/) | 1.4.0 | 0/0 | 17 | 255/255 | skip | 51248 | 528 | 6.3 | 1.9 | 12 | 0 | **green** |
| [`20260804-214445`](20260804-214445/) | 1.4.0 | 0/0 | 17 | 255/255 | skip | 51248 | 528 | 6.3 | 1.9 | 0 | 0 | **green** |
| [`20260804-182235`](20260804-182235/) | 1.4.0 | 0/0 | 17 | 255/255 | skip | 51217 | 519 | 6.4 | 1.9 | 23 | 2 | **green** |

**Reading the Max CCN column: the `0` in `20260804-214445` is an instrument fault, not a
measurement.** Runs recorded before the testkit rev-6 re-vendor read `CCN_MAX` out of `lizard`'s
`!!!! Warnings` block, so the figure collapsed to `0` the moment an addon reached zero warnings.
One run of this record is affected — `20260804-214445` — and its true maximum is **12**, which was
always present in that same bundle's [`complexity.txt`](20260804-214445/complexity.txt)
(`Database.RunMigrations@30-50@./core/Database.lua`). The row is left exactly as the runner emitted
it: a generated figure edited by hand reads as measured when it is not (`performance-§10`). Read the
trend as 23 → 12 → 12.

## Test suite

255 cases. The suite builds a fully isolated addon instance per case (`tests/loader.lua`), because the addon's whole job is writing `_G[GLOBALNAME]` and a shared environment would let one case's overrides answer another's reads. The generated inventory `test-cases.md` in each bundle is the authority on what exists at that point; the README badge tracks the same number. The count has now held at 255 across all three recorded runs, including one that refactored two functions — correctly, since that refactor was behavior-preserving and added no seam to cover. The next run that changes source without changing this number is worth a look: panel rendering, live chat overrides and positional `%n$s` formats are covered only by the in-game [smoke-test suite](../smoke-tests.md), so a coverage gap here does not show up as a failure anywhere.

## Lint

Clean over 17 files, and clean over the same 17 in every recorded run. Scope excludes `libs/` (vendored, not this addon's to lint), `tests/`, `docs/audits`, `docs/reviews` and the generated `GlobalStrings/` chunks — the last is 91% of the repo's NLOC and carries no logic, so a clean lint here says nothing at all about that data. Before quoting 0/0, confirm the four seam files (`core/CoreSetup.lua`, `core/DebugLogSetup.lua`, `settings/OptionsSetup.lua`, `settings/Slash.lua`) are inside the set that was actually checked; the config is `.luacheckrc`.

## Perf

This addon ships no `tests/perf.lua`, so the `perf` column is a permanent `skip` rather than a transient tooling gap. Two things follow, and both are standing facts rather than any run's news: the record says **nothing** about the addon's runtime cost, and `performance-§9`'s zero-overhead evidence — that bracketed instrumentation is free when capture is off — does not exist for it. Adding scenarios is the only thing that changes either. In-game captures, which no script can produce, have no standing store in this repo yet.

## Complexity watch list

Current state as of [`20260804-233338`](20260804-233338/) — not that run's diff.
Every function `lizard` warned on, and every file at or above `layout-§1`'s 1000-LOC
on-notice threshold, each with a one-line disposition.

### Functions `lizard` warned on

**None.** Zero warnings over 528 functions, and as of `20260804-233338` the maximum is
**measured** at 12 rather than inferred from an empty warning list — see the note under the
table for why the run before it recorded `0`. The two standing entries were `PrettyChat:Test`
(CCN 23) and `build` in `tests/loader.lua` (CCN 18); both were split into named units, to CCN 6
and 3, with no behavior change. Their dispositions are retired along with them — nothing is
deferred here anymore. The five functions now nearest the threshold, named rather than counted
so the next regression is visible, are `Database.RunMigrations` (`core/Database.lua`, CCN 12),
`PrettyChat:ApplyStrings` (`modules/Override.lua`, 11), `sampleArg` (`modules/Override.lua`, 11),
`runTest` (`settings/Slash.lua`, 11) and `buildParentBody` (`settings/Panel.lua`, 11). The next
warned function is a regression, not a backlog item.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| > 1500 (over cap) | `GlobalStrings/GlobalStrings.lua` | 23842 | **Accepted — not shipped and not loaded.** No TOC references it and `.pkgmeta:21` excludes it; it is the build-time input `split_globalstrings.py` reads. `layout-§1` caps files a reader has to change. |
