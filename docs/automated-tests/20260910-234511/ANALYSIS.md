# Analysis — 20260910-234511

- **Addon:** PrettyChat 1.4.0 → 1.5.0
- **Verdict:** green
- **Commit:** e91c32ff1870 (master), clean
- **Previous run:** [`20260908-181425`](../20260908-181425/)

## Headline

The release run for **1.5.0**. Lint, tests and complexity are green with zero functions above CCN 15 — and the max CCN here is 13, the lowest in the collection; **perf did not run**, as no `tests/perf.lua` ships. Five new test cases and 205 more NLOC. The 23,842-line over-cap entry is `GlobalStrings/GlobalStrings.lua`, which is neither shipped nor loaded.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260908-181425` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 44 files | [`lint.txt`](lint.txt) | see below |
| tests | pass | 328 passed, 0 skipped, 0 failed, 328 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | see below |
| perf | skip | not measured — no `tests/perf.lua` in this addon | — | not measured in either run |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | see below |

| Metric | Value |
|---|---|
| Total NLOC | 53167 |
| Functions | 694 |
| Avg NLOC / function | 6.7 |
| Avg CCN | 2.0 |
| Max CCN | 13 |
| Avg tokens / function | 49.8 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.0 / 0.0 |
| Files in the 1000–1500 band | 1 |
| Files over the 1500 cap | 1 |

**perf is the one suite that is not a clean pass, and it is a skip rather than a failure.** `manifest.json` records the reason verbatim: *"no tests/perf.lua — this addon ships no offline scenarios"*. Nothing ran, so nothing was measured — this is a pre-existing condition of the addon, not a regression in this run, and it is stated in the release notes as well as here. The release gate's perf condition is satisfied by the no-scenarios exception, which means this tag rests on three measured suites.

## What moved

- **lint** — 44 files, up one from 43. Still 0 warnings / 0 errors.
- **tests** — 328 passed, up 5 from 323. No skips, no failures.
- **perf** — skipped in both runs: no `tests/perf.lua`. Not measured.
- **complexity** — NLOC 52962 → 53167 (+205) over 688 → 694 functions (+6). Avg NLOC 6.6 → 6.7, avg CCN flat at 2.0, avg tokens 49.4 → 49.8. Max CCN flat at 13, zero warnings in both. One band file and one over-cap file, unchanged.

## Complexity watch list

Both tables are maintained in [`RESULTS.md`](../RESULTS.md), which the runner regenerates whole on every run; the **Disposition** column there is the authored half and is current as of this run.

### Functions `lizard` warned on

None. Zero functions above CCN 15 is what the release gate required, and it is what this run measured — max CCN 13.

### Files by `layout-§1` band

1 file(s) in the 1000–1500 on-notice band, 1 over the 1500 cap. Each carries a disposition in [`RESULTS.md`](../RESULTS.md#files-by-layout-1-band). The band is not part of the release gate.

## Actions

None. The over-cap `GlobalStrings/GlobalStrings.lua` is a reference dump excluded by `.pkgmeta:24` and referenced by no TOC line — its disposition is current and its size is not a code-health signal. `tests/test_panel.lua` remains the repository's only band entry.
