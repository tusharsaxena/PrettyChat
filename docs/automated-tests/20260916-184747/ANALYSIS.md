# Analysis — 20260916-184747

- **Addon:** PrettyChat 1.5.0
- **Verdict:** green
- **Commit:** 093305b90d0e (master), clean
- **Previous run:** [`20260916-094245`](../20260916-094245/)

## Headline

Green, and the only thing that moved is the launcher landing. Both gating suites are clean — lint
0/0 over 46 files, 385 of 385 cases passing — and the case count is up 353 → 385 on the minimap
button and broker plugin adopted since the previous run this morning. `perf` **did not run at all**;
this addon ships no `tests/perf.lua`, so the record stays silent about runtime cost. Complexity held
every average flat while the tree gained 67 functions, nothing crossed CCN 15, and nothing new
entered a watch-list band.

## Suites

Every row links its artifact, so a reader can get from a figure to the evidence in one click. A
skipped suite links nothing — there is no artifact — and says what was not measured.

| Suite | Status | Result | Artifact | Moved since `20260916-094245` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 46 files | [`lint.txt`](lint.txt) | +2 files, still 0/0 |
| tests | pass | 385 passed, 0 skipped, 0 failed, 385 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +32 cases |
| perf | skip | not measured — no `tests/perf.lua` in this addon | — | not measured in either run |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | see below |

**Complexity metrics** (from `manifest.json`'s `suites.complexity`, which records `lizard`'s own
footer as printed in [`complexity.txt`](complexity.txt)):

| Metric | Value |
|---|---|
| Total NLOC | 54311 |
| Functions | 854 |
| Avg NLOC / function | 6.7 |
| Avg CCN | 2.0 |
| Max CCN | 14 |
| Avg tokens / function | 51.0 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 1 |
| Files over the 1500 cap | 1 |

The averages are the point. Total NLOC rose 53773 → 54311 and the function count rose 787 → 854,
which is the addon growing — `core/LauncherSetup.lua` arrived, `settings/Slash.lua` and
`settings/Schema.lua` grew, and `tests/test_launcher.lua` arrived with 566 lines of suite. Avg NLOC
per function and avg CCN did not move at all (6.7 and 2.0). Avg tokens per function ticked 50.4 →
51.0, the one density figure that moved, and 0.6 tokens on a function count that grew by 8.5% is
noise rather than a signal. Max CCN is unchanged at 14, on `Database.PruneOrphans`
([`complexity.txt`](complexity.txt), `core/Database.lua:52-76`), the same function that set it last
run.

`perf` is the only suite that is not a clean pass, and it is a **skip, not a pass**: the runner found
no `tests/perf.lua` and ran nothing. This is a standing fact about the addon rather than a tooling
gap on this host — `lizard` 1.24.0 and `luacheck` 1.2.0 are both present per `manifest.json`'s
`host` block — and it is the first of `automated-tests-§3`'s two sanctioned reasons, *nothing to
run*, not a ratified `performance-§12` exemption. Nothing in this bundle says this addon is cheap at
runtime; the question was never asked.

## What moved

- **lint** — 44 → 46 files, still 0 warnings / 0 errors. The two new files in scope are
  `core/LauncherSetup.lua` and `tests/test_launcher.lua`; the vendored `LibDBIcon-1.0`,
  `LibDataBroker-1.1` and `LibKa0s/Launcher.lua` that arrived alongside them are under `libs/`,
  which `.luacheckrc` excludes, so they never entered the figure.
- **tests** — 353 → 385, **+32 cases**, and no case reported a skip in either run. The new
  `tests/test_launcher.lua` carries the bulk; `tests/test_slash.lua` grew by 192 lines over the same
  span. The count has now moved in four consecutive runs, so this is not a suite that stopped
  growing while the addon did.
- **perf** — not measured in either run. Unchanged, and unchanged because there is nothing to run.
- **complexity** — totals up (NLOC 53773 → 54311, functions 787 → 854), averages flat (avg NLOC 6.7
  → 6.7, avg CCN 2.0 → 2.0), avg tokens 50.4 → 51.0, max CCN 14 → 14, warnings 0 → 0. Band counts
  unchanged at 1 on notice and 1 over the cap.
- **watch list** — no new entry. `tests/test_panel.lua` moved 1042 → 1053 within the 1000–1500 band;
  `GlobalStrings/GlobalStrings.lua` is unchanged at 23842.

The git log between the two runs (`78f5ec7..093305b`) says what drove all of it. Eleven of the twelve
commits are one piece of work: re-vendoring LibKa0s v1.39.0 for its `Launcher` major and adopting it
— a minimap button, a broker plugin and the reserved verbs that go with them. The twelfth,
`093305b`, is a documentation correction rather than a behaviour change: it counts the host-owned
verbs as **five, not four**, because `reset` belongs on that list — `runReset` intercepts a category
name and redirects before delegating to `CliReset`, so the host owns the verb even though the
delegate does the work — and it drops a README line that offered a `/pc reset setting` argument the
dispatcher never accepted. Neither of those is visible in any figure above, which is the correct
outcome for a docs fix.

## Complexity watch list

### Functions `lizard` warned on

None. Nothing reached CCN 15; the ceiling is 14 at `Database.PruneOrphans`
(`core/Database.lua:52-76`, [`complexity.txt`](complexity.txt)). The runners-up are `fitTree`
(13, `settings/Panel.lua:420-443`) and a flat band of four at 12. Every one of those is dense
**defaulting and guarding** rather than tangled control flow: `lizard` counts each `and`/`or`
short-circuit as a decision, so a Lua run of `t.k = rec.k or D.k` lines scores high with no
branching a reader would see (`performance-§10`).

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `tests/test_panel.lua` | 1053 | **Accepted**, carried forward, with the figure re-read: 1042 → 1053 this run. Third consecutive run in the band, and still the only file this repository has ever had on notice. Case count, not tangle — the settings panel is the only part of this addon with real branching, so its suite is where the cases live, and avg CCN across the file is 1.9. On notice is the compliant state under `layout-§1`, not a breach. Re-check at 1200. |
| > 1500 (over cap) | `GlobalStrings/GlobalStrings.lua` | 23842 | **Accepted — not shipped and not loaded.** Unchanged this run. `layout-§1`'s generated-non-shipping-data carve-out reaches it: no TOC line loads it, `.pkgmeta` drops the whole folder from the zip, and `.luacheckrc` excludes it. `tests/test_layout_cap.lua` re-derives all three conditions on every run, and `docs/ARCHITECTURE.md` → `### Files over the 1500-line cap` is the standing remark the rule requires. Not a deviation and not a breach. |

Neither disposition is over its shelf life. `automated-tests-§4` charges an entry carried as
Accepted across **three consecutive release runs**; `tests/test_panel.lua` has appeared in exactly
one release run (`73c0040`, Release 1.5.0) plus two ordinary ones, so it is at one of three. Nothing
here is owed a deviation ID yet.

## Actions

None. Both gating suites are clean, nothing crossed a complexity threshold, and no watch-list entry
is new or overdue. The one thing a reader should carry away is not a defect but an absence: with no
`tests/perf.lua`, this addon has **no** `performance-§9` zero-overhead evidence, and every run in
`RESULTS.md` back to the first has recorded `perf` as `skip`. Adding scenarios is not required by
any gate today and is not filed as an action here, but it is the gap this record cannot close.
