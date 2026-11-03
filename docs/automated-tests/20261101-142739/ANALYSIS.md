# Analysis — 20261101-142739

- **Addon:** PrettyChat 1.7.0
- **Verdict:** green
- **Commit:** 17a02d5 (feat/2026-11-01-full-skinning), clean
- **Previous run:** [`20261101-025157`](../20261101-025157/)

## Headline

Green at `17a02d5`, on the re-vendored LibKa0s v1.85.0 (kit revision 49): lint 0/0 over 67 files, 658
of 659 cases pass with 1 skipped and 0 failed, max CCN 15 with 0 warnings, and 0 blind and 0 crashed
files. The case count rose by 2, both this run's new cases. Nothing to act on.

## Suites

Every row links its artifact, so a reader can get from a figure to the evidence in one click. A
skipped suite links nothing — there is no artifact — and says what was not measured.

| Suite | Status | Result | Artifact | Moved since 20261101-025157 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 67 files | [`lint.txt`](lint.txt) | unchanged |
| tests | pass | 658 passed, 1 skipped, 0 failed, 659 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | total 657 to 659 |
| perf | skip | 0 scenarios. Not measured: `performance-§12` no-combat-path exemption (ratified; `docs/ARCHITECTURE.md` → Documented deviations) | none | unchanged |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC and functions up, averages but tokens flat; see below |

**Complexity is reported in full**, because a single figure cannot be compared across a change in
size. Every value is [`manifest.json`](manifest.json)'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 59517 |
| Functions | 1544 |
| Avg NLOC / function | 7.3 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.5 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**complexity** passed and is sighted: `blindFiles` and `crashedFiles` are both 0. The max-CCN function
is still `listSettings` at CCN 15 (`settings/Slash.lua:368`, [`complexity.txt`](complexity.txt) line
1330). It sits at the threshold, not over it, and it is not warned on.

**tests** passed with one case skipped, not failed. The skip is the same kit diagnostics-contract case
as the previous run ([`tests.txt`](tests.txt) line 648): it covers an addon that opts out of logging
on, and this addon keeps the default. It is a pre-existing condition, counted in neither the passed
figure nor the failed one.

**perf** skipped by design under the ratified `performance-§12` exemption, as in the previous run. The
run says nothing about runtime cost, and the release gate reads this skip as NOT EVALUATED, not a pass.

## What moved

- **lint:** nothing. Still 0/0 over 67 files.
- **tests:** 657 to 659 in total and 656 to 658 passed. The two are `test_skinsetup.lua`'s *the degraded
  HudFont draws and MarkText answers a string* and `test_skin_surfaces.lua`'s *the tooltip's rendered
  body line draws in gtip.line, spied at AddLine*, per [`test-cases.md`](test-cases.md).
- **perf:** nothing. Still 0 scenarios under the same exemption.
- **complexity:** NLOC 59465 to 59517 and functions 1535 to 1544, average tokens 60.4 to 60.5. Average
  NLOC, average CCN and max CCN did not move, so the addon grew and did not get denser.

## Complexity watch list

Functions `lizard` warned on:

None.

Files by `layout-§1` band:

None.

No disposition is owed.

## Actions

None.
