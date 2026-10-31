# Analysis — 20261101-000814

- **Addon:** PrettyChat 1.7.0 (`"label": "v1.84.0-adoption"`, not a release run)
- **Verdict:** green
- **Commit:** 353fe21 (feat/2026-10-31-findings-remediation), clean
- **Previous run:** [`20261031-211742`](../20261031-211742/)

## Headline

Green, measured at `353fe21`, on LibKa0s v1.84.0 and 3 commits past the previous run's `b77224b`: lint
0/0 over 67 files, 656 of 657 cases pass with 1 skipped and 0 failed, max CCN 15 with 0 warnings, and 0
blind and 0 crashed files. The re-vendor moved almost nothing here: one function and 3 NLOC, and the
function is the `PositionBlock` stub the new library surface asks of a frameless addon. Nothing to act on.

## Suites

Every row links its artifact, so a reader can get from a figure to the evidence in one click. A
skipped suite links nothing — there is no artifact — and says what was not measured.

| Suite | Status | Result | Artifact | Moved since 20261031-211742 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 67 files | [`lint.txt`](lint.txt) | unchanged; the output is identical |
| tests | pass | 656 passed, 1 skipped, 0 failed, 657 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | unchanged; the inventory is identical |
| perf | skip | 0 scenarios. Not measured: `performance-§12` no-combat-path exemption (ratified; `docs/ARCHITECTURE.md` → Documented deviations) | none | unchanged |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | 59462 → 59465 NLOC, 1534 → 1535 functions; see below |

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
is still `listSettings` at CCN 15 (`settings/Slash.lua:368`, [`complexity.txt`](complexity.txt)). It
sits at the threshold, not over it, and it is not warned on.

**tests** passed with one case skipped, not failed. The skip is the same kit diagnostics-contract case
as the previous run ([`tests.txt`](tests.txt) line 646): it covers an addon that opts out of logging
on, this addon keeps the default, and the case above it holds that default. It is a pre-existing
condition and it counts in neither the passed figure nor the failed one.

**perf** skipped by design under the ratified `performance-§12` exemption, as in every recent run. The
run says nothing about runtime cost, and the release gate reads this skip as NOT EVALUATED, not a pass.

## What moved

- **lint:** nothing. [`lint.txt`](lint.txt) matches the previous run's byte for byte once line endings
  are set aside.
- **tests:** nothing. [`test-cases.md`](test-cases.md) matches the previous inventory, so v1.84.0
  neither added nor removed a case here. The count has now been flat at 657 across 3 runs, which
  `RESULTS.md` flags. Those 3 runs were remediation and this re-vendor, with NLOC 59469 → 59465 over
  them, so the addon has not outgrown its suite.
- **perf:** nothing; still skipped.
- **complexity:** 59462 → 59465 NLOC and 1534 → 1535 functions, a real but trivial change in size. Avg
  NLOC 7.3, avg CCN 2.1 and max CCN 15 did not move; avg tokens went 60.5 → 60.4. The averages hold, so
  this is no complexity signal. Band and over-cap counts stay at 0.

## Complexity watch list

Functions:

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

Files:

| Band | File | LOC | Disposition |
|---|---|---|---|

None.

No Disposition is owed: both tables are empty, so `RESULTS.md` has no blank cell to rule on.

## Actions

None.
