# Analysis — 20260804-114913

- **Addon:** PrettyChat 1.4.0
- **Verdict:** green
- **Commit:** 058c5b16357e (master), dirty
- **Previous run:** none — this is the first recorded run

## Headline

The first automated-test record for this addon, produced while adopting `automated-tests`
(standard v2.19.0). Both gating suites are clean: `luacheck` reports 0 warnings / 0 errors across
17 files and the headless harness passes 255 of 255 cases. The offline perf runner is absent (see below). Every figure below is a **baseline** —
there is no previous run to diff against, so nothing here is a regression and nothing is an
improvement.

## Suites

| Suite | Status | Result | Moved since previous run |
|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 17 files (`lint.txt`) | — first run |
| tests | pass | 255 passed, 0 failed, 255 total (`tests.txt`) | — first run |
| perf | skip | skip | — first run |
| complexity | pass | 2 warnings, max CCN 23, 51217 NLOC / 519 functions (`complexity.txt`) | — first run |

`tests/perf.lua` is absent — this addon ships no offline scenarios, so nothing was measured here. That is a **skip, not a pass**: it is recorded as one in `manifest.json`, and it means this run says nothing about the addon's runtime cost.

## What moved

**First run — nothing to diff against; every figure above is a baseline reading.** The next run is
the first one that can say something moved, and this record is what it will be read against.

## Complexity watch list

| `PrettyChat:Test` | 23 | `modules/Override.lua` | **Peel next.** Partly relieved by review finding **F-007**, whose shared index deletes the inner collect-and-sort outright. |
| `build` | 18 | `tests/loader.lua` | **Accepted, and expected to disappear** — tracked as **PC-51**, deleted when `LIBKA0S-01` lands. |

**Files in the 1000–1500 band:** None.

**Over the 1500 cap:** `GlobalStrings/GlobalStrings.lua` (23,842) — the unshipped Blizzard source dump. Not loaded by any TOC and excluded by `.pkgmeta:21`; it is the build-time input the splitter reads. The 26 shipped chunks are all ~882 lines, deliberately under the on-notice band (PC-49, closed this session).

## Actions

None arising from this run. The dispositions above are carried forward from the complexity reports
written against the same measurements earlier today; each was recorded with its evidence at the
time, and none is new here.
