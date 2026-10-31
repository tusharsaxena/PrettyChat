# Analysis — 20261031-211742

- **Addon:** PrettyChat 1.7.0 (`"label": "findings-remediation"`, not a release run)
- **Verdict:** green
- **Commit:** b77224b (feat/2026-10-31-findings-remediation), clean
- **Previous run:** [`20261031-202238`](../20261031-202238/)

## Headline

Green, measured at `b77224b`, 10 commits past the previous run's `d6ac61e`: lint 0/0 over 67 files, 656
of 657 cases pass with 1 skipped and 0 failed, max CCN 15 with 0 warnings, and 0 blind and 0 crashed
files. The one real movement is the one this run was meant to confirm: the 1000–1500 band went 1 → 0,
so `settings/Schema.lua`'s peel took it out of the band and the watch list is empty. Nothing to act on.

## Suites

Every row links its artifact, so a reader can get from a figure to the evidence in one click. A
skipped suite links nothing — there is no artifact — and says what was not measured.

| Suite | Status | Result | Artifact | Moved since 20261031-202238 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 67 files | [`lint.txt`](lint.txt) | 65 → 67 files, still 0/0 |
| tests | pass | 656 passed, 1 skipped, 0 failed, 657 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | unchanged; the inventory is identical |
| perf | skip | 0 scenarios. Not measured: `performance-§12` no-combat-path exemption (ratified; `docs/ARCHITECTURE.md` → Documented deviations) | none | unchanged |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | band files 1 → 0; see below |

**Complexity is reported in full**, because a single figure cannot be compared across a change in
size. Every value is [`manifest.json`](manifest.json)'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 59462 |
| Functions | 1534 |
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
is still `listSettings` at CCN 15 (`settings/Slash.lua:368`, [`complexity.txt`](complexity.txt)). It
sits at the threshold, not over it, and it is not warned on.

**tests** passed with one case skipped, not failed. The skip is the same kit diagnostics-contract case
as the previous run, for an addon that opts out of `debug diagnostics` turning logging on
([`tests.txt`](tests.txt), line 646). PrettyChat keeps the default (`Kit.diagnostics.enablesLogging`
is not `false`), so that branch has nothing to check here, and the case above it holds the behavior
the addon does have. It is a pre-existing condition, counted in the total and in neither passed nor
failed. At the release gate it is NOT EVALUATED rather than passed.

**perf** skipped: nothing was measured, by the ratified `performance-§12` no-combat-path exemption
in `docs/ARCHITECTURE.md`. This is a standing fact about the addon, not a tooling gap. The release gate
reads this skip as NOT EVALUATED, not as a pass.

## What moved

- **lint:** 65 → 67 files in scope, 0/0 at both readings. The two added files are the
  `settings/SchemaStub.lua` and `settings/SchemaSkin.lua` peels.
- **tests:** did not move. 656 passed, 1 skipped, 0 failed, 657 total at both readings, and
  [`test-cases.md`](test-cases.md) is identical to the previous run's.
- **perf:** did not move; 0 scenarios at both readings.
- **complexity totals:** NLOC 59469 → 59462, functions 1538 → 1534. A slight fall, not growth.
- **complexity densities:** avg NLOC 7.2 → 7.3, avg CCN 2.1 → 2.1, max CCN 15 → 15, avg tokens
  60.2 → 60.5. The small rise follows from the same code sitting in four fewer functions; avg CCN did
  not move, so it is not a complexity signal.
- **watch list:** warnings 0 → 0, band files 1 → 0, over-cap files 0 → 0, blind files 0 → 0, crashed
  files 0 → 0. `settings/Schema.lua`'s row dropped, as its `FX-PC-SIZE` disposition said it would at
  this run.
- **version:** 1.7.0 at both readings.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|

None.

## Actions

None.
