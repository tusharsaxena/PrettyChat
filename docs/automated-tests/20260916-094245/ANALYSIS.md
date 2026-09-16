# Analysis — 20260916-094245

- **Addon:** PrettyChat 1.5.0
- **Verdict:** green
- **Commit:** 78f5ec7ceed5 (master), clean
- **Previous run:** [`20260910-234511`](../20260910-234511/)

## Headline

A routine recorded run at 1.5.0, the first since the release run that tagged it. Lint and tests —
the two suites that gate — are both clean, with the case count up sharply from 328 to 353; perf
**did not run at all**, because this addon ships no `tests/perf.lua`, so this record says nothing
about runtime cost. Complexity stays flat in its averages while the tree grew by 93 functions, and
max CCN ticked 13 → 14 on a newly added `Database.PruneOrphans`, still comfortably under the 15
warn line.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260910-234511` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 44 files | [`lint.txt`](lint.txt) | unchanged |
| tests | pass | 353 passed, 0 skipped, 0 failed, 353 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +25 cases |
| perf | skip | not measured — no `tests/perf.lua` in this addon | — | not measured in either run |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | see below |

**Complexity metrics** (from `manifest.json`'s `suites.complexity`, whose figures are `lizard`'s own
footer in [`complexity.txt`](complexity.txt)):

| Metric | Value |
|---|---|
| Total NLOC | 53773 |
| Functions | 787 |
| Avg NLOC / function | 6.7 |
| Avg CCN | 2.0 |
| Max CCN | 14 |
| Avg tokens / function | 50.4 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 1 |
| Files over the 1500 cap | 1 |

**perf is the one suite that is not a pass, and it is a skip, not a failure.** `manifest.json`
records the reason verbatim: *"no tests/perf.lua — this addon ships no offline scenarios"*, with
`scenarios: 0` and a 2 ms duration — nothing executed. This is a standing condition of the repo
rather than a regression in this run: it is the first of `automated-tests-§3`'s two sanctioned
skip reasons, *nothing to run*. Note that it is **not** the same thing as the addon's ratified
`performance-§12` no-combat-path exemption, which is about the in-game Perf major being declined;
the offline scenarios simply do not exist. Either way, this bundle is **silent about runtime cost**.

## What moved

- **lint** — 0 warnings / 0 errors over 44 files, identical to the previous run in both the figure
  and the file count. No file entered or left `luacheck`'s scope.
- **tests** — 328 → 353 passed (+25), still zero skipped and zero failed, so passed and total agree
  and no case is claiming coverage it did not exercise. The per-case inventory for this run is
  [`test-cases.md`](test-cases.md).
- **perf** — skipped in both runs, for the same reason. Not measured, not compared.
- **complexity** — NLOC 53167 → 53773 (+606) across 694 → 787 functions (+93). The **totals rose
  because the addon grew**; the **averages did not move**: avg NLOC flat at 6.7, avg CCN flat at
  2.0, avg tokens 49.8 → 50.4 (+0.6). That combination is growth, not densification. Warnings 0 in
  both runs, warn rates 0.00 / 0.00. Max CCN 13 → 14: the previous peak was `fitTree`
  (`settings/Panel.lua:417`, still 13), and the new peak is `Database.PruneOrphans`
  (`core/Database.lua:36-60`, CCN 14), which did not exist at the previous run. It is genuinely
  nested control flow — three `pairs` loops over categories, subtable fields and global names, plus
  type guards and two emptiness sweeps — rather than a run of `or`-defaulting lines, but at 25 lines
  and one clear job it reads cleanly and is a point under the warn line, not at it.
- **layout bands** — 1 on-notice file and 1 over-cap file, both the same files at the same sizes as
  the previous run. Nothing newly crossed.

## Complexity watch list

Both tables are maintained in [`RESULTS.md`](../RESULTS.md), which the runner regenerates whole on
every run; the **Disposition** column there is the authored half and is current as of this run.

### Functions `lizard` warned on

None. Zero functions above CCN 15, max 14 — `lizard`'s footer states *"No thresholds exceeded"*
outright.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `tests/test_panel.lua` | 1042 | **Accepted — carried forward unchanged.** Same file, same 1042 lines as the previous run, despite +25 cases elsewhere in the suite. Second consecutive run in the band; the standing re-check trigger is 1200 lines. |
| > 1500 (over cap) | `GlobalStrings/GlobalStrings.lua` | 23842 | **Accepted — carried forward unchanged.** Not shipped and not loaded: no TOC line references it and `.pkgmeta:24` excludes the directory. It is the build-time input `split_globalstrings.py` reads, not a file a reader has to change. |

Neither disposition is near its shelf life: `tests/test_panel.lua` first entered the band at the
run before last, so it has not been carried as *Accepted* across three consecutive release runs.

## Test suite

**353 cases, all passing, none skipped.** [`test-cases.md`](test-cases.md) in this bundle is the
authority on which cases existed at this commit; `docs/test-cases.md` is the same list at HEAD. The
count moved with the addon (+25 cases against +93 functions), so this is not the stalled-count case
the standard asks to be flagged.

## Lint

**0 warnings / 0 errors over 44 files** via `luacheck .` (Luacheck 1.2.0, per `manifest.json`'s
`host`). The file count is unchanged from the previous run. The scope of that `0/0` is set by
`.luacheckrc`'s multi-line `exclude_files` — read it there; a clean lint says nothing about what was
never submitted to it.

## Perf

**No scenarios.** This repo ships no `tests/perf.lua`, so the suite is a permanent skip and this
record is silent about runtime cost. Nothing here says the addon is fast or cheap — only that the
question was not asked offline. The in-game answer is a separate artifact entirely
(`/wow-addon:perf-analysis`, under `docs/perf-analysis/`), and none of this run substitutes for it.

## Actions

None. Both band dispositions carry forward on their own terms, no function warned, and the two
gating suites are clean. `Database.PruneOrphans` at CCN 14 is worth a glance if it grows another
branch, but at zero warnings it is a note, not an action.
