# Analysis — 20260927-031723

- **Addon:** PrettyChat 1.6.0
- **Verdict:** green
- **Commit:** a663bc6 (master), clean
- **Previous run:** [`20260927-030323`](../20260927-030323/) (the 1.6.0 release run)

## Headline

Green. This run measures `a663bc6`, the commit that split `tests/test_panel.lua`, and the split
did what it set out to do. The band table now holds only `settings/Schema.lua`. The case count is
unchanged at 518, all passing, and lint is still 0/0, now over 53 files instead of 51 because the
split added two files. `perf` is the ratified `performance-§12` skip. Nothing needs action.

## Suites

Every row links its artifact, so a reader can get from a figure to the evidence in one click. A
skipped suite links nothing — there is no artifact — and says what was not measured.

| Suite | Status | Result | Artifact | Moved since 20260927-030323 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 53 files | [`lint.txt`](lint.txt) | files 51 → 53 (`tests/panel_fixture.lua`, `tests/test_panel_categories.lua`); still 0/0 |
| tests | pass | 518 passed, 0 skipped, 0 failed, 518 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | total unchanged; `test_panel.lua` 48 → 25, new `test_panel_categories.lua` 23 |
| perf | skip | 0 scenarios. Not measured: `performance-§12` no-combat-path exemption (ratified; `docs/ARCHITECTURE.md` → Documented deviations) | none | unchanged |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC +34, functions +1; averages and max unchanged; band files 2 → 1 |

**Complexity is reported in full**, because a single figure cannot be compared across a change in
size. Every value is [`manifest.json`](manifest.json)'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 56489 |
| Functions | 1135 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 1.9 |
| Max CCN | 14 |
| Avg tokens / function | 53.3 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 1 |
| Files over the 1500 cap | 0 |

**perf** is the one suite that did not pass cleanly, and the skip is permanent by design rather
than a missing tool. It is the second of `automated-tests-§3`'s two sanctioned reasons: PrettyChat
has a ratified `performance-§12` no-combat-path exemption in its `docs/ARCHITECTURE.md` register
and ships no `tests/perf.lua`. The manifest's `skipReason` names the exemption. This run does not
measure runtime cost.

## What moved

- **lint:** 0/0 as before. The two new files, `tests/panel_fixture.lua` and
  `tests/test_panel_categories.lua`, appear in `lint.txt` as `OK`, and they account for the whole
  51 → 53 rise. The `.luacheckrc` exclusions are unchanged.
- **tests:** 518 of 518 pass, none skipped, the same total as the previous run. In `test-cases.md`
  the change is only where cases live. `test_panel.lua` went from 48 to 25 and
  `test_panel_categories.lua` holds the other 23. The three parent-page cases moved to a different
  line within `test_panel.lua`'s list. No case was added or dropped. This is the fourth run in a
  row at 518, and the one after the release run changed test layout only, so the flat count does
  not mean coverage has stalled.
- **perf:** still a skip, for the same reason.
- **complexity:** NLOC 56455 → 56489 (+34) and functions 1134 → 1135 (+1). Both come from the
  split: in `complexity.txt`, `tests/panel_fixture.lua` adds four helpers (`panelFrame`, `byLabel`,
  `tabButtons`, `sortedNames`), and the `tests/test_panel.lua` entries are now spread across it and
  `tests/test_panel_categories.lua`, with each suite carrying its own file-level setup. Avg NLOC 6.8,
  avg CCN 1.9, avg tokens 53.3 and max CCN 14 did not move, and there are still 0 warnings.
- **bands:** `tests/test_panel.lua` left the 1000–1500 band. It was 1125 lines in the previous run,
  and the generated band table no longer lists it. `settings/Schema.lua` did not move from 1070.
  Files in the band went from 2 to 1, and 0 files are over the cap.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `settings/Schema.lua` | 1070 | on notice, carried forward. Unchanged, fifth run in the band, one release run in that span (1.6.0). Grows with the schema, not by tangle. Re-check at 1200 |

The full Disposition cell is in `RESULTS.md`. Nothing newly crossed a threshold. The one entry
that was nearing anti-pattern #53's three-release limit was `tests/test_panel.lua`, which had been
carried as **Accepted** through two release runs. It has now been fixed by the split rather than
carried again, which closes the previous run's Action 1. `settings/Schema.lua` is **On notice**,
not **Accepted**, and it has one release run in the band.

## Actions

None.
