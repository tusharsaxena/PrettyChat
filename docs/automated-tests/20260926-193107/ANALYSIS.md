# Analysis — 20260926-193107

- **Addon:** PrettyChat 1.5.0
- **Verdict:** green
- **Commit:** d6e8d76 (feat/2026-09-26-automated-tests-sweep), clean
- **Previous run:** [`20260926-160432`](../20260926-160432/)

## Headline

Green. This is the final run of the 2026-09-26 automated-tests sweep, measured on the LibKa0s v1.62.0
re-vendor (kit revision 31, `d6e8d76`), two commits past the previous run's `496d2fd`. Both gating
suites are unchanged and clean: lint 0/0 over 51 files, 518 of 518 cases pass. `perf` is still the
ratified `performance-§12` skip. Complexity moved by 2 NLOC in one test file and nothing else, max CCN
holds at 14 with 0 warnings, and the only band change is that the generated
`GlobalStrings/GlobalStrings.lua` no longer counts as over the cap, because the new kit reads the
repo's declared carve-out. Nothing to act on.

## Suites

Every row links its artifact, so a reader can get from a figure to the evidence in one click. A
skipped suite links nothing — there is no artifact — and says what was not measured.

| Suite | Status | Result | Artifact | Moved since 20260926-160432 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 51 files | [`lint.txt`](lint.txt) | unchanged |
| tests | pass | 518 passed, 0 skipped, 0 failed, 518 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | unchanged |
| perf | skip | 0 scenarios. Not measured: `performance-§12` no-combat-path exemption (ratified; `docs/ARCHITECTURE.md` → Documented deviations) | none | unchanged |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC +2; over-cap files 1 → 0 |

**Complexity is reported in full**, because a single figure cannot be compared across a change in
size. Every value is [`manifest.json`](manifest.json)'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 56455 |
| Functions | 1134 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 1.9 |
| Max CCN | 14 |
| Avg tokens / function | 53.3 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 2 |
| Files over the 1500 cap | 0 |

**perf** is the one suite that is not a clean pass. It is a standing skip, not a tooling gap: the
second of `automated-tests-§3`'s two sanctioned reasons. PrettyChat holds a ratified
`performance-§12` no-combat-path exemption in its `docs/ARCHITECTURE.md` register, and the
manifest's `skipReason` names it. Runtime cost is therefore not measured by this run, by design.
At a release this suite reads as **NOT EVALUATED**, not as a pass.

## What moved

- **lint:** still 0/0 over the same 51 files (`lint.txt` matches the previous bundle's). The
  `.luacheckrc` exclusions `RESULTS.md` names are unchanged.
- **tests:** still 518 cases, all passing, none skipped. `test-cases.md` is identical to the
  previous bundle's. The v1.62.0 re-vendor widened one existing case in `tests/test_libka0s.lua`
  (the Options `L`-trap tripwire now also reads `OptionsIds.lua`, `OptionsIdList.lua` and
  `OptionsRegistry.lua`, where v1.62.0 moved the code it covered) without adding a case, so the
  flat count follows from what changed rather than from coverage stalling.
- **perf:** still a skip, same reason.
- **complexity:** NLOC 56453 → 56455 (+2), all of it `tests/test_libka0s.lua` (535 → 537, the two
  added path lines in that case; `complexity.txt`). Functions held at 1134, avg NLOC 6.8, avg CCN
  1.9, avg tokens 53.3, max CCN 14, 0 warnings. Nothing densified.
- **bands:** `settings/Schema.lua` 1070 and `tests/test_panel.lua` 1125 are the same line counts as
  the previous run. The previous run's manifest recorded `overCapFiles: 1`, the generated
  `GlobalStrings/GlobalStrings.lua` at 23842 lines. Kit revision 31 honours the repo's
  `Kit.layoutCap.exempt` declaration in `tests/run.lua` and leaves it out as generated non-shipping
  data (`layout-§1`'s second carve-out), so the count is 0 now. The file did not change; the
  counting did, and it now agrees with what the cap binds.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `settings/Schema.lua` | 1070 | on notice, carried forward. Unchanged, third run in the band. Grows with the schema, not by tangle. Re-check at 1200 |
| 1000–1500 (on notice) | `tests/test_panel.lua` | 1125 | accepted, carried forward. Unchanged, sixth run in the band, one release run in that span. Case count, not tangle. Re-check at 1200 |

The full Disposition cells are in `RESULTS.md`. Nothing newly crossed a threshold. The
`GlobalStrings/GlobalStrings.lua` over-cap row left the table (see *What moved*). No **Accepted**
entry has been carried across three release runs: the only release run in this record is
`20260910-234511` (1.5.0).

## Actions

None. This bundle is not a release record (`"release": null`), and no version bump or tag was cut.
The `tests/test_panel.lua` headroom note (75 lines to its 1200 re-check) still stands.
