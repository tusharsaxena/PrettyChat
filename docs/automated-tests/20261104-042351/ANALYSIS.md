# Analysis — 20261104-042351

- **Addon:** PrettyChat 1.7.0
- **Verdict:** green
- **Commit:** f092704 (feat/2026-11-01-full-skinning), clean
- **Previous run:** [`20261101-201604`](../20261101-201604/)

## Headline

Green at `f092704`, the round 6 head of the full skinning run: lint 0/0 over 70 files, 690 of 691
cases pass with 1 skipped and 0 failed, max CCN 15 with 0 warnings, and 0 blind and 0 crashed files.
The case count rose by 18, mostly from the new skin picker console-preview suite. Nothing to act on.

## Suites

Every row links its artifact, so a reader can get from a figure to the evidence in one click. A
skipped suite links nothing — there is no artifact — and says what was not measured.

| Suite | Status | Result | Artifact | Moved since 20261101-201604 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 70 files | [`lint.txt`](lint.txt) | files 68 to 70 |
| tests | pass | 690 passed, 1 skipped, 0 failed, 691 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | total 673 to 691 |
| perf | skip | 0 scenarios. Not measured: `performance-§12` no-combat-path exemption (ratified; `docs/ARCHITECTURE.md` → Documented deviations) | none | unchanged |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC and functions up, averages flat or down; see below |

**Complexity is reported in full**, because a single figure cannot be compared across a change in
size. Every value is [`manifest.json`](manifest.json)'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 59910 |
| Functions | 1604 |
| Avg NLOC / function | 7.2 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.0 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**complexity** passed and is sighted: `blindFiles` and `crashedFiles` are both 0. The max-CCN function
is still `listSettings` at CCN 15 (`./settings/Slash.lua:368`, [`complexity.txt`](complexity.txt) line
1389). It sits at the threshold, not over it, and it is not warned on.

**tests** passed with one case skipped, not failed. The skip is the same kit diagnostics-contract case
as the previous run ([`tests.txt`](tests.txt) line 667): it covers an addon that opts out of logging
on, and this addon keeps the default. It is a pre-existing condition, counted in neither the passed
figure nor the failed one.

**perf** skipped by design under the ratified `performance-§12` exemption, as in the previous run. The
run says nothing about runtime cost, and the release gate reads this skip as NOT EVALUATED, not a pass.

## What moved

- **lint:** 68 to 70 files, the new `tests/test_skin_preview.lua` and `tests/test_launcher_skin_entry.lua`.
  Still 0/0.
- **tests:** 673 to 691 in total and 672 to 690 passed, per [`test-cases.md`](test-cases.md):
  `test_skin_preview.lua` adds 15 cases (the picker's eye previews on the debug console with the
  `/pc test` sample), `test_launcher_skin_entry.lua` 1, `test_database.lua` 1 (the v3 font migration
  to Ka0s Ubuntu) and `test_debuglog.lua` 1 (no line under either console title). One skin picker case
  was renamed to say "no one-shot eye". The skip count did not move.
- **perf:** nothing. Still 0 scenarios under the same exemption.
- **complexity:** NLOC 59625 to 59910, functions 1564 to 1604, average tokens 60.2 to 60.0. Average
  NLOC, average CCN and max CCN did not move, so the addon grew and did not get denser.

## Complexity watch list

Functions `lizard` warned on:

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

Files by `layout-§1` band:

| Band | File | LOC | Disposition |
|---|---|---|---|

None.

No disposition is owed.

## Actions

None.
