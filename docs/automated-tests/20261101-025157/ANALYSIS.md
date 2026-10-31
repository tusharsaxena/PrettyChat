# Analysis — 20261101-025157

- **Addon:** PrettyChat 1.7.0 (`"label": "final-pre-merge"`, not a release run)
- **Verdict:** green
- **Commit:** 5e74de0 (feat/2026-10-31-findings-remediation), clean
- **Previous run:** [`20261101-000814`](../20261101-000814/)

## Headline

Green at `5e74de0`, 3 commits past the previous run's `353fe21`: lint 0/0 over 67 files, 656 of 657
cases pass with 1 skipped and 0 failed, max CCN 15 with 0 warnings, and 0 blind and 0 crashed files.
No figure moved, and the only artifact that differs is `complexity.txt`, where five
`tests/test_surface_parity.lua` rows shifted by one line. Nothing to act on.

## Suites

Every row links its artifact, so a reader can get from a figure to the evidence in one click. A
skipped suite links nothing — there is no artifact — and says what was not measured.

| Suite | Status | Result | Artifact | Moved since 20261101-000814 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 67 files | [`lint.txt`](lint.txt) | unchanged; the output is identical |
| tests | pass | 656 passed, 1 skipped, 0 failed, 657 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | unchanged; the inventory is identical |
| perf | skip | 0 scenarios. Not measured: `performance-§12` no-combat-path exemption (ratified; `docs/ARCHITECTURE.md` → Documented deviations) | none | unchanged |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | every figure unchanged; see below |

**Complexity is reported in full**, because a single figure cannot be compared across a change in
size. Every value is [`manifest.json`](manifest.json)'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 59465 |
| Functions | 1535 |
| Avg NLOC / function | 7.3 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.4 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**complexity** passed and is sighted: `blindFiles` and `crashedFiles` are both 0. The max-CCN function
is still `listSettings` at CCN 15 (`settings/Slash.lua:368`, [`complexity.txt`](complexity.txt) line
1322). It sits at the threshold, not over it, and it is not warned on.

**tests** passed with one case skipped, not failed. The skip is the same kit diagnostics-contract case
as the previous run ([`tests.txt`](tests.txt) line 646): it covers an addon that opts out of logging
on, this addon keeps the default. It is a pre-existing condition and it counts in neither the passed
figure nor the failed one.

**perf** skipped by design under the ratified `performance-§12` exemption, as in the previous run. The
run says nothing about runtime cost, and the release gate reads this skip as NOT EVALUATED, not a pass.

## What moved

- **lint:** nothing. [`lint.txt`](lint.txt) matches the previous run's once line endings are set aside.
- **tests:** nothing. [`tests.txt`](tests.txt) and [`test-cases.md`](test-cases.md) match the previous
  run's the same way, so the case count stays at 657.
- **perf:** nothing. Still 0 scenarios under the same exemption.
- **complexity:** no figure moved. Five anonymous-function rows for `tests/test_surface_parity.lua`
  in [`complexity.txt`](complexity.txt) (lines 226–230) start one line later or run one line longer;
  their NLOC, CCN and tokens are unchanged.

## Complexity watch list

Functions `lizard` warned on:

None.

Files by `layout-§1` band:

None.

No disposition is owed.

## Actions

None.
