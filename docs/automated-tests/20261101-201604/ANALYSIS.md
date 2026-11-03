# Analysis — 20261101-201604

- **Addon:** PrettyChat 1.7.0
- **Verdict:** green
- **Commit:** ff8d62e (feat/2026-11-01-full-skinning), clean
- **Previous run:** [`20261101-142739`](../20261101-142739/)

## Headline

Green at `ff8d62e`, on the re-cut LibKa0s v1.85.0 (kit revision 50): lint 0/0 over 68 files, 672 of
673 cases pass with 1 skipped and 0 failed, max CCN 15 with 0 warnings, and 0 blind and 0 crashed
files. The case count rose by 14, all from the kit's two skin gates and one degraded-facade pin.
Nothing to act on.

## Suites

Every row links its artifact, so a reader can get from a figure to the evidence in one click. A
skipped suite links nothing — there is no artifact — and says what was not measured.

| Suite | Status | Result | Artifact | Moved since 20261101-142739 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 68 files | [`lint.txt`](lint.txt) | files 67 to 68 |
| tests | pass | 672 passed, 1 skipped, 0 failed, 673 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | total 659 to 673 |
| perf | skip | 0 scenarios. Not measured: `performance-§12` no-combat-path exemption (ratified; `docs/ARCHITECTURE.md` → Documented deviations) | none | unchanged |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | NLOC and functions up, average NLOC and tokens down; see below |

**Complexity is reported in full**, because a single figure cannot be compared across a change in
size. Every value is [`manifest.json`](manifest.json)'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 59625 |
| Functions | 1564 |
| Avg NLOC / function | 7.2 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.2 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**complexity** passed and is sighted: `blindFiles` and `crashedFiles` are both 0. The max-CCN function
is still `listSettings` at CCN 15 (`./settings/Slash.lua:368`, [`complexity.txt`](complexity.txt) line
1350). It sits at the threshold, not over it, and it is not warned on.

**tests** passed with one case skipped, not failed. The skip is the same kit diagnostics-contract case
as the previous run ([`tests.txt`](tests.txt) line 649): it covers an addon that opts out of logging
on, and this addon keeps the default. It is a pre-existing condition, counted in neither the passed
figure nor the failed one. The two new gates' declared skips are gone: both suites run with facts.

**perf** skipped by design under the ratified `performance-§12` exemption, as in the previous run. The
run says nothing about runtime cost, and the release gate reads this skip as NOT EVALUATED, not a pass.

## What moved

- **lint:** 67 to 68 files, the new `tests/skin_surfaces.lua`. Still 0/0.
- **tests:** 659 to 673 in total and 658 to 672 passed. The kit's `test_skin_values` adds 3 cases and
  `test_skin_switch` 10, and `test_skinsetup.lua` adds *the degraded BarBorder answers the stored three
  it is handed*, per [`test-cases.md`](test-cases.md).
- **perf:** nothing. Still 0 scenarios under the same exemption.
- **complexity:** NLOC 59517 to 59625, functions 1544 to 1564, average NLOC 7.3 to 7.2 and average tokens
  60.5 to 60.2. Average CCN and max CCN did not move, so the addon grew and did not get denser.

## Complexity watch list

Functions `lizard` warned on:

None.

Files by `layout-§1` band:

None.

No disposition is owed.

## Actions

None.
