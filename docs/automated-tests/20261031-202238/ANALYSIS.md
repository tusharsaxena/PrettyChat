# Analysis — 20261031-202238

- **Addon:** PrettyChat 1.7.0 (pre-merge run, `"label": "pre-merge"`, not a release run)
- **Verdict:** green
- **Commit:** d6ac61e (feat/2026-10-31-font-pickers-skin-faces), clean
- **Previous run:** [`20261009-191724`](../20261009-191724/)

## Headline

Green, measured at `d6ac61e`, 54 commits past the previous run's `3c40352`: lint 0/0 over 65 files, 656
of 657 cases pass with 1 skipped and 0 failed, max CCN 15 with 0 warnings, and 0 blind and 0 crashed
files. Totals rose with the skin and font work while the densities held, so nothing here is a
complexity signal. The one thing to act on is `settings/Schema.lua`: at 1225 lines it passed the 1200
re-check its own disposition set, and it has been re-ruled below. No code changed for this run.

## Suites

Every row links its artifact, so a reader can get from a figure to the evidence in one click. A
skipped suite links nothing — there is no artifact — and says what was not measured.

| Suite | Status | Result | Artifact | Moved since 20261009-191724 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 65 files | [`lint.txt`](lint.txt) | 56 → 65 files, still 0/0 |
| tests | pass | 656 passed, 1 skipped, 0 failed, 657 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 575 → 657 total; skipped unchanged at 1 |
| perf | skip | 0 scenarios. Not measured: `performance-§12` no-combat-path exemption (ratified; `docs/ARCHITECTURE.md` → Documented deviations) | none | unchanged |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | densities held; see below |

**Complexity is reported in full**, because a single figure cannot be compared across a change in
size. Every value is [`manifest.json`](manifest.json)'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 59469 |
| Functions | 1538 |
| Avg NLOC / function | 7.2 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.2 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 1 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**complexity** passed and is sighted: `blindFiles` and `crashedFiles` are both 0. The max-CCN function
is still `listSettings` at CCN 15 (`settings/Slash.lua:368`, [`complexity.txt`](complexity.txt)). It
sits at the threshold, not over it, and it is not warned on. `crashedFiles` is new to this manifest
(the previous one has no such field), so it has no earlier reading to compare with.

**tests** passed with one case skipped, not failed. The skip is the same kit diagnostics-contract case
as the previous run, for an addon that opts out of `debug diagnostics` turning logging on
([`tests.txt`](tests.txt), line 646). PrettyChat keeps the default (`Kit.diagnostics.enablesLogging`
is not `false`), so that branch has nothing to check here, and the case above it holds the behavior
the addon does have. It is a pre-existing condition, counted in the total and in neither passed nor
failed. At the release gate it is NOT EVALUATED rather than passed.

**perf** skipped: nothing was measured, by the ratified `performance-§12` no-combat-path exemption
in `docs/ARCHITECTURE.md`. This is a standing fact about the addon, not a tooling gap.

## What moved

- **lint:** 56 → 65 files in scope, 0/0 at both readings.
- **tests:** 574 → 656 passed, 575 → 657 total, 1 → 1 skipped, 0 → 0 failed.
- **perf:** did not move; 0 scenarios at both readings.
- **complexity totals:** NLOC 57462 → 59469, functions 1319 → 1538. This is growth.
- **complexity densities:** avg NLOC 7.3 → 7.2, avg CCN 2.1 → 2.1, max CCN 15 → 15, avg tokens
  59.9 → 60.2. The addon grew without getting meaningfully denser.
- **watch list:** warnings 0 → 0, band files 1 → 1, over-cap files 0 → 0, blind files 0 → 0.
  `settings/Schema.lua` moved 1113 → 1225 lines.
- **version:** this run reads 1.7.0; the previous row was the 1.6.0 → 1.7.0 release run.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `settings/Schema.lua` | 1225 | **On notice**, re-ruled: 651 NLOC, because the rest of the file is comments and blank lines, and the skin rows are a cohesive block, not tangle. Re-check at 1300; the peel seam is the `General ▸ Skin` block. |

Left out as generated non-shipping data (`layout-§1`'s second carve-out): `GlobalStrings/GlobalStrings.lua`.

The carried disposition said to re-check at 1200, and this run crossed that, so the cell was re-ruled
rather than carried. The file's 651 NLOC comes from [`complexity.txt`](complexity.txt). No function in
it is warned on. The growth is the skin rows, the block at lines 497–624 of the file at
`d6ac61e`, which is also the seam a peel would follow.

The disposition has now stood through two release runs, 1.6.0 and 1.7.0. This run is not a release
run, so it does not count. The next release run that carries the file is the third.

## Actions

1. `settings/Schema.lua`: the next release run is the third to carry this entry, so decide then
   whether to peel the `General ▸ Skin` block or record a tracked deviation. New here; no issue or
   deviation ID owns it yet.
2. `docs/ARCHITECTURE.md`, the cap-census prose: it still gives `settings/Schema.lua` as 1087 lines.
   New here; a documentation fix for the sync-docs pass, outside this run's record.
