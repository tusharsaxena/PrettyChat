# Analysis — 20260804-182235

- **Addon:** PrettyChat 1.4.0
- **Verdict:** green
- **Commit:** f0958eb29787 (master), dirty
- **Started:** 2026-08-04T18:22:35+05:30
- **Previous run:** none — this is the first recorded run

## Headline

The first automated-test record for this addon, produced while adopting `automated-tests`
(standard v2.19.0). Both gating suites are clean: `luacheck` reports 0 warnings / 0 errors across
17 files and the headless harness passes 255 of 255 cases. The offline perf runner is absent (see below). Every figure below is a **baseline** —
there is no previous run to diff against, so nothing here is a regression and nothing is an
improvement.

## Suites

| Suite | Status | Result | Artifact | Moved since previous run |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 17 files | [`lint.txt`](lint.txt) | — first run |
| tests | pass | 255 passed, 0 failed, 255 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | — first run |
| perf | skip | — | — (not run) | — first run |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | — first run |

### Complexity in full

Every field of `lizard`'s footer, plus the two derived file counts. The **averages** are what make
this run comparable to the next one across a change in size: a total that rises because the addon
grew is a different fact from an average that rises because it got denser, and only the second is a
complexity signal.

| Metric | Value |
|---|---|
| Total NLOC | 51217 |
| Functions | 519 |
| Avg NLOC / function | 6.4 |
| Avg CCN | 1.9 |
| Max CCN | 23 |
| Avg tokens / function | 48.0 |
| Warnings (CCN > 15) | 2 |
| Warning rate — `Fun Rt` / `nloc Rt` | 0.0 / 0.03 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 1 |

`tests/perf.lua` is absent — this addon ships no offline scenarios, so nothing was measured there. That is a **skip, not a pass**: it is recorded as one in `manifest.json`, and it means this run says nothing about the addon's runtime cost.

## What moved

**First run — nothing to diff against; every figure above is a baseline reading.** The next run is
the first one that can say something moved, and this record is what it will be read against.

## Complexity watch list

| `PrettyChat:Test` | 23 | `modules/Override.lua` | **Peel next.** Partly relieved by review finding **F-007**, whose shared index deletes the inner collect-and-sort outright. |
| `build` | 18 | `tests/loader.lua` | **Accepted, and expected to disappear** — tracked as **PC-51**, deleted when `LIBKA0S-01` lands. |

**Files in the 1000–1500 band:** None.

**Over the 1500 cap:** `GlobalStrings/GlobalStrings.lua` (23,842) — the unshipped Blizzard source dump. Not loaded by any TOC and excluded by `.pkgmeta:21`. The 26 shipped chunks are all ~882 lines, deliberately under the on-notice band (PC-49).

## Actions

None arising from this run. The dispositions above are carried forward from the complexity reports
written against the same measurements earlier today; each was recorded with its evidence at the
time, and none is new here.
