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

## Test suite

255 cases. The suite builds a fully isolated addon instance per case (`tests/loader.lua`), because the addon's whole job is writing `_G[GLOBALNAME]` and a shared environment would let one case's overrides answer another's reads. The generated inventory `test-cases.md` in each bundle is the authority on what exists at that point; the README badge tracks the same number.

## Lint

Clean over 17 files. Scope excludes `libs/` and the generated `GlobalStrings/` chunks — the latter is 91% of the repo's NLOC and carries no logic, so a clean lint here says nothing about that data.

## Perf

This addon ships no `tests/perf.lua`, so the `perf` column is a permanent `skip` rather than a transient tooling gap. Two things follow, and both are standing facts rather than this run's news: the record says **nothing** about the addon's runtime cost, and `performance-§9`'s zero-overhead evidence — that bracketed instrumentation is free when capture is off — does not exist for it. Adding scenarios is the only thing that changes either.

## Complexity watch list

Current state as of [`20260804-214445`](20260804-214445/) — not that run's diff.
Every function `lizard` warned on, and every file at or above `layout-§1`'s 1000-LOC
on-notice threshold, each with a one-line disposition.

### Functions `lizard` warned on

**None.** Zero warnings over 528 functions — the first run of this record with an empty
functions list, and a result rather than a missing section. The two standing entries were
`PrettyChat:Test` (CCN 23) and `build` in `tests/loader.lua` (CCN 18); both were split into
named units this branch, to CCN 6 and 3, with no behavior change. Their dispositions are
retired along with them — nothing is deferred here anymore. The next warned function is a
regression, not a backlog item.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| > 1500 (over cap) | `GlobalStrings/GlobalStrings.lua` | 23842 | **Accepted — not shipped and not loaded.** No TOC references it and `.pkgmeta:21` excludes it; it is the build-time input `split_globalstrings.py` reads. `layout-§1` caps files a reader has to change. |
