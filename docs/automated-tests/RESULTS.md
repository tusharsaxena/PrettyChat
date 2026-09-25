# Automated test results

<!-- Regenerated whole by tests/_kit/run-automated-tests.sh on every run. -->
<!-- This file is OVERWRITTEN IN PLACE — the git history of this one path is the trend line. -->
<!-- Everything here is generated EXCEPT the watch list's Disposition column. -->

One row per run. The frozen evidence for each is in the dated folder beside this file;
the analysis of a given run is its `ANALYSIS.md`.

**`lint` and `tests` gate the run and gate the commit** (`testing-§4`).
**`perf` and `complexity` never fail a run and never block a commit** — they are recorded,
read and compared, not thresholded (`performance-§9`, `performance-§10`).

**The tag is gated on all four suites at `pass`, plus zero functions above CCN 15**
(`automated-tests-§3`, *The release gate*), evaluated by `/wow-addon:bump-version` from the
`manifest.json` the release run writes — not by this script, whose exit code is unchanged.

A `skip` is a suite that did not run at all. It is never a pass, and at the release gate it is
**NOT EVALUATED** rather than passed: install the tool and re-run. A `—` is a suite that was
not selected, which is a different fact again.

The **Tests** cell reads `passed/skipped/total`.

**Commit** is the short sha the run measured and **Tree** is whether that tree was clean at the
time. Both are read from git by the runner; neither is ever typed. A **dirty** row measured bytes
that no sha can bring back, so it is kept as an experiment honestly labeled rather than dropped —
and a release record is refused outright on a dirty tree, so no release row can be one.

A row reading `unknown` in both cells was recorded before the runner emitted them. That is what
the record holds about those runs — it is not `clean`, and it is not reconstructed from git
archaeology, for the same reason a skip is never a pass (`automated-tests-§4`).

| Run | Commit | Tree | Version | Lint w/e | Files | Tests | Perf | NLOC | Funcs | Avg NLOC | Avg CCN | Max CCN | CCN warn | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| [`20260924-104049`](20260924-104049/) | `f85e6d1` | clean | 1.5.0 | 0/0 | 48 | 481/0/481 | skip | 55657 | 1038 | 6.8 | 1.9 | 14 | 0 | **green** |
| [`20260916-184747`](20260916-184747/) | unknown | unknown | 1.5.0 | 0/0 | 46 | 385/0/385 | skip | 54311 | 854 | 6.7 | 2.0 | 14 | 0 | **green** |
| [`20260916-094245`](20260916-094245/) | unknown | unknown | 1.5.0 | 0/0 | 44 | 353/0/353 | skip | 53773 | 787 | 6.7 | 2.0 | 14 | 0 | **green** |
| [`20260910-234511`](20260910-234511/) | unknown | unknown | 1.4.0 → 1.5.0 | 0/0 | 44 | 328/0/328 | skip | 53167 | 694 | 6.7 | 2.0 | 13 | 0 | **green** |
| [`20260908-181425`](20260908-181425/) | unknown | unknown | 1.4.0 | 0/0 | 43 | 323/0/323 | skip | 52962 | 688 | 6.6 | 2.0 | 13 | 0 | **green** |
| [`20260825-103457`](20260825-103457/) | unknown | unknown | 1.4.0 | 0/0 | 18 | 271/271 | skip | 51480 | 555 | 6.3 | 1.9 | 12 | 0 | **green** |
| [`20260807-114404`](20260807-114404/) | unknown | unknown | 1.4.0 | 0/0 | 17 | 260/260 | skip | 51337 | 531 | 6.4 | 1.9 | 12 | 0 | **green** |
| [`20260807-110428`](20260807-110428/) | unknown | unknown | 1.4.0 | 0/0 | 17 | 260/260 | skip | 51337 | 531 | 6.4 | 1.9 | 12 | 0 | **green** |
| [`20260807-022707`](20260807-022707/) | unknown | unknown | 1.4.0 | 0/0 | 17 | 260/260 | skip | 51337 | 531 | 6.4 | 1.9 | 12 | 0 | **green** |
| [`20260804-233338`](20260804-233338/) | unknown | unknown | 1.4.0 | 0/0 | 17 | 255/255 | skip | 51248 | 528 | 6.3 | 1.9 | 12 | 0 | **green** |
| [`20260804-214445`](20260804-214445/) | unknown | unknown | 1.4.0 | 0/0 | 17 | 255/255 | skip | 51248 | 528 | 6.3 | 1.9 | 0 | 0 | **green** |
| [`20260804-182235`](20260804-182235/) | unknown | unknown | 1.4.0 | 0/0 | 17 | 255/255 | skip | 51217 | 519 | 6.4 | 1.9 | 23 | 2 | **green** |

## Test suite

**481 cases** — 481 passed, 0 failed, 0 skipped. The generated inventory
[`20260924-104049/test-cases.md`](20260924-104049/test-cases.md) is the authority on which cases existed at this run;
`docs/test-cases.md` is that same list at HEAD.

Moved **385 → 481** since the previous run.

No case reported a `skip`, so passed and total agree and nothing in this row claims coverage
that was not exercised.

## Lint

**0 warnings / 0 errors over 48 files** (`luacheck .`).

Read that figure with its scope attached: `.luacheckrc` excludes 6 path(s) from it — `Libs`, `libs`, `GlobalStrings`, `docs/audits`, `docs/reviews`, `tests/_kit/` —
so nothing under them is in the count above. A `0/0` that never moves is partly a statement about
what was never looked at, which is why the exclusions are NAMED here on every run rather than left
to whoever thinks to open `.luacheckrc`.

## Perf

**This repo holds a ratified `performance-§12` no-combat-path exemption, so `perf` is a
permanent `skip`** — the second of `automated-tests-§3`'s two sanctioned reasons, read by
this runner from the `## Documented deviations` register in `docs/ARCHITECTURE.md`. The exemption, and the sweep behind it, are in
`docs/performance.md`: this record carries no scenario table because the addon has no
combat path for one to measure, not because the question was never asked.

## Complexity watch list

Current as of [`20260924-104049`](20260924-104049/) — **this run's measurement, not its diff.** Max CCN **14** across 1038
functions, **0** of them warned on; 2 file(s) in the 1000–1500 band and 1 over the 1500 cap
(`layout-§1`).

Every row below is generated from this run's own `lizard` output. **The `Disposition` column is
the one authored cell in this file** (`automated-tests-§4`, *the one boundary*): it is carried
forward verbatim while its entry is unchanged, and left **blank** when the entry is new — a blank
cell is this file saying something crossed and nobody has ruled on it yet.

### Functions `lizard` warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `settings/Schema.lua` | 1070 | **On notice, new this run.** 998 lines at the LibKa0s v1.56.0 re-vendor (`18b3e2e`), 1070 at `f85e6d1`: the 2026-09-23 remediation items grew it, the largest shares being PC-00 (+41, clearing the re-vendor reds) and PC-01 (+14, the v1.56.0 Core and Schema forwarding). It is the settings schema — every row, its wiring and the runtime instance over them — so it grows with the schema rather than by tangle, and no function in it is warned on. On notice is the compliant state under `layout-§1`, not a breach, and `docs/ARCHITECTURE.md` → *Files over the 1500-line cap* names it. Re-check at 1200. |
| 1000–1500 (on notice) | `tests/test_panel.lua` | 1125 | **Accepted**, carried forward, with the figure re-read: 1053 → 1125 this run. Fourth consecutive run in the band. The 72 lines are the 2026-09-23 remediation's panel cases: PC-06 (+50, both Defaults buttons page-wide), PC-09 (+20, the New box count) and PC-11 (+10, the memoized name list), less PC-04's retired second-category tooltip cases. Case count, not tangle — the settings panel is the only part of this addon with real branching, so its suite is where the cases live. On notice is the compliant state under `layout-§1`, not a breach, and `docs/ARCHITECTURE.md` → *Files over the 1500-line cap* says the same. Re-check at 1200: 75 lines of headroom, so the next panel feature of this size should peel a suite along a seam (the per-string editor cases are the obvious one) rather than walk it over. |
| > 1500 (over cap) | `GlobalStrings/GlobalStrings.lua` | 23842 | exempt — see docs/ARCHITECTURE.md → Files over the 1500-line cap |

`lizard` counts every `and`/`or` short-circuit as a decision, so in Lua a run of
`t.k = rec.k or D.k` defaulting lines scores high with no visible branching at all: a large CCN
here usually means *this function defaults or guards a lot of fields* rather than *this function
is tangled*, and the two want different fixes (`performance-§10`).

