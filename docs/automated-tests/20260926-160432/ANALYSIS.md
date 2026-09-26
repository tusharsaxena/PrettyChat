# Analysis — 20260926-160432

- **Addon:** PrettyChat 1.5.0
- **Verdict:** green
- **Commit:** 496d2fdf2741 (master), clean
- **Previous run:** [`20260924-104049`](../20260924-104049/)

## Headline

Green. This is the first run on the LibKa0s v1.61.0 re-vendor (the nav rail) and the diagnostics
rollout, measured on `master` after both merges, 18 commits past the previous run's `f85e6d1`. Both
gating suites are clean: lint is 0/0 over 51 files and 518 of 518 cases pass (up from 481). `perf` is
still the ratified `performance-§12` skip. Complexity held every average flat within rounding while
the tree gained 96 functions, max CCN held at 14, and no file moved in or out of a `layout-§1` band.
Nothing to act on.

## Suites

Every row links its artifact, so a reader can get from a figure to the evidence in one click. A
skipped suite links nothing — there is no artifact — and says what was not measured.

| Suite | Status | Result | Artifact | Moved since 20260924-104049 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 51 files | [`lint.txt`](lint.txt) | files 48 → 51 |
| tests | pass | 518 passed, 0 skipped, 0 failed, 518 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 481 → 518 |
| perf | skip | 0 scenarios. Not measured: `performance-§12` no-combat-path exemption (ratified; `docs/ARCHITECTURE.md` → Documented deviations) | none | unchanged |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | see *What moved* |

**Complexity is reported in full**, because a single figure cannot be compared across a change in
size. Every value is `manifest.json`'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 56453 |
| Functions | 1134 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 1.9 |
| Max CCN | 14 |
| Avg tokens / function | 53.3 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 2 |
| Files over the 1500 cap | 1 |

**perf** is the one suite that is not a clean pass. It is a standing skip, not a tooling gap: the
second of `automated-tests-§3`'s two sanctioned reasons. PrettyChat holds a ratified
`performance-§12` no-combat-path exemption in its `docs/ARCHITECTURE.md` register, and the
manifest's `skipReason` names it. Runtime cost is therefore not measured by this run, by design.
At a release this suite reads as **NOT EVALUATED**, not as a pass.

## What moved

- **lint:** still 0/0. The scope grew from 48 to 51 files: `modules/Diagnostics.lua`,
  `tests/mock_menu.lua` and `tests/test_diagnostics.lua` arrived (compare `lint.txt` across the two
  bundles). The `.luacheckrc` exclusions `RESULTS.md` names are unchanged.
- **tests:** 481 → 518 (+37). The new cases are the diagnostics report
  (`tests/test_diagnostics.lua`), the right-click launcher menu and tooltip (`tests/test_launcher.lua`,
  `tests/mock_menu.lua`), and smaller additions in `test_disabled.lua`, `test_doc_structure.lua`,
  `test_locale.lua` and `test_libka0s.lua` (`test-cases.md`). No case reported a skip.
- **perf:** still a skip, same reason.
- **complexity:** NLOC 55657 → 56453 (+796) and functions 1038 → 1134 (+96). Avg NLOC held at 6.8,
  avg CCN at 1.9, avg tokens 53.0 → 53.3. Max CCN held at 14 (`Database.PruneOrphans`,
  `core/Database.lua:94`) and there are still 0 warnings. The largest per-file function-count gains
  are `modules/Diagnostics.lua` (new, 21), `tests/test_diagnostics.lua` (new, 29) and
  `tests/test_launcher.lua` (45 → 59) (`complexity.txt`). This is growth, not densification.
- **bands:** unchanged. `settings/Schema.lua` 1070 and `tests/test_panel.lua` 1125 are the same
  line counts as the previous run; the generated `GlobalStrings/GlobalStrings.lua` holds at 23842
  over the cap, exempt through the census.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `settings/Schema.lua` | 1070 | on notice, carried forward. Unchanged, second run in the band. Grows with the schema, not by tangle. Re-check at 1200 |
| 1000–1500 (on notice) | `tests/test_panel.lua` | 1125 | accepted, carried forward. Unchanged, fifth run in the band, one release run in that span. Case count, not tangle. Re-check at 1200 |
| > 1500 (over cap) | `GlobalStrings/GlobalStrings.lua` | 23842 | exempt — see docs/ARCHITECTURE.md → Files over the 1500-line cap |

The full Disposition cells are in `RESULTS.md`. Nothing newly crossed a threshold. No **Accepted**
entry has been carried across three release runs: the only release run in this record is
`20260910-234511` (1.5.0).

## Actions

None. This bundle is not a release record (`"release": null`), and no version bump or tag was cut.
The `tests/test_panel.lua` headroom note from the previous run (75 lines to its 1200 re-check)
still stands unchanged.
