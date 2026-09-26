# Analysis — 20260927-030323

- **Addon:** PrettyChat 1.5.0 → 1.6.0 (release run, `"release": "1.6.0"`)
- **Verdict:** green
- **Commit:** c2faa0c (master), clean
- **Previous run:** [`20260926-193107`](../20260926-193107/)

## Headline

Green, and the release gate for 1.6.0 passed. Measured at `c2faa0c`, six commits past the previous
run's `d6e8d76`, and those commits touched only documentation (`README.md`, `docs/testing.md` and the
previous bundle), so every figure is identical to the previous run: lint 0/0 over 51 files, 518 of 518
cases pass, max CCN 14 with 0 warnings. `perf` is the ratified `performance-§12` skip, which the
release gate accepts as nothing to run and the 1.6.0 release notes state in one sentence. Nothing
blocks the release.

## Suites

Every row links its artifact, so a reader can get from a figure to the evidence in one click. A
skipped suite links nothing — there is no artifact — and says what was not measured.

| Suite | Status | Result | Artifact | Moved since 20260926-193107 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 51 files | [`lint.txt`](lint.txt) | unchanged |
| tests | pass | 518 passed, 0 skipped, 0 failed, 518 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | unchanged |
| perf | skip | 0 scenarios. Not measured: `performance-§12` no-combat-path exemption (ratified; `docs/ARCHITECTURE.md` → Documented deviations) | none | unchanged |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | unchanged |

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
`performance-§12` no-combat-path exemption in its `docs/ARCHITECTURE.md` register, ships no
`tests/perf.lua`, and the manifest's `skipReason` names the exemption. Runtime cost is therefore not
measured by this run, by design. At the release gate this is the narrow exception
`automated-tests-§3` sanctions (nothing was there to run), so the gate covered lint, tests and
complexity, and the new `## Version History` row for 1.6.0 says so.

**Release gate** (read from `manifest.json`): lint pass (0/0); tests pass (0 failed); perf skip,
passed under the no-`tests/perf.lua` exception (`performance-§12`); complexity pass; CCN warnings 0.

## What moved

- **lint:** still 0/0 over the same 51 files; `lint.txt` is byte-identical to the previous bundle's.
  The `.luacheckrc` exclusions `RESULTS.md` names are unchanged.
- **tests:** still 518 cases, all passing, none skipped; `test-cases.md` is identical to the previous
  bundle's and to `docs/test-cases.md`. The count is flat across three runs because the commits in
  between changed documentation only, not because coverage stalled against new code.
- **perf:** still a skip, same reason.
- **complexity:** `complexity.txt` is identical to the previous bundle's. NLOC 56455, 1134 functions,
  avg NLOC 6.8, avg CCN 1.9, avg tokens 53.3, max CCN 14, 0 warnings.
- **bands:** `settings/Schema.lua` 1070 and `tests/test_panel.lua` 1125, the same line counts as the
  previous run. 0 files over the cap.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None. A release bundle has none by construction: the gate requires zero functions above CCN 15.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `settings/Schema.lua` | 1070 | on notice, carried forward. Unchanged, fourth run in the band, first release run in that span. Grows with the schema, not by tangle. Re-check at 1200 |
| 1000–1500 (on notice) | `tests/test_panel.lua` | 1125 | accepted, carried forward. Unchanged, seventh run in the band, second release run in that span. Case count, not tangle. Re-check at 1200 |

The full Disposition cells are in `RESULTS.md`. Nothing newly crossed a threshold. No **Accepted**
entry has yet been carried across three release runs: `tests/test_panel.lua` has now been carried
across two (`20260910-234511`, 1.5.0, and this one, 1.6.0). If it is still in the band and still
**Accepted** at the next release run, it is owed a fix or a tracked deviation ID (anti-pattern #53).

## Actions

1. `tests/test_panel.lua`: two release runs as **Accepted**. Before the next release, peel a suite
   along a seam (the per-string editor cases are the obvious one) or record a tracked deviation ID.
   New here; not yet in the addon's tracking.
