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

| Run | Version | Lint w/e | Files | Tests | Perf | NLOC | Funcs | Avg NLOC | Avg CCN | Max CCN | CCN warn | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| [`20260910-234511`](20260910-234511/) | 1.4.0 → 1.5.0 | 0/0 | 44 | 328/0/328 | skip | 53167 | 694 | 6.7 | 2.0 | 13 | 0 | **green** |
| [`20260908-181425`](20260908-181425/) | 1.4.0 | 0/0 | 43 | 323/0/323 | skip | 52962 | 688 | 6.6 | 2.0 | 13 | 0 | **green** |
| [`20260825-103457`](20260825-103457/) | 1.4.0 | 0/0 | 18 | 271/271 | skip | 51480 | 555 | 6.3 | 1.9 | 12 | 0 | **green** |
| [`20260807-114404`](20260807-114404/) | 1.4.0 | 0/0 | 17 | 260/260 | skip | 51337 | 531 | 6.4 | 1.9 | 12 | 0 | **green** |
| [`20260807-110428`](20260807-110428/) | 1.4.0 | 0/0 | 17 | 260/260 | skip | 51337 | 531 | 6.4 | 1.9 | 12 | 0 | **green** |
| [`20260807-022707`](20260807-022707/) | 1.4.0 | 0/0 | 17 | 260/260 | skip | 51337 | 531 | 6.4 | 1.9 | 12 | 0 | **green** |
| [`20260804-233338`](20260804-233338/) | 1.4.0 | 0/0 | 17 | 255/255 | skip | 51248 | 528 | 6.3 | 1.9 | 12 | 0 | **green** |
| [`20260804-214445`](20260804-214445/) | 1.4.0 | 0/0 | 17 | 255/255 | skip | 51248 | 528 | 6.3 | 1.9 | 0 | 0 | **green** |
| [`20260804-182235`](20260804-182235/) | 1.4.0 | 0/0 | 17 | 255/255 | skip | 51217 | 519 | 6.4 | 1.9 | 23 | 2 | **green** |

## Test suite

**328 cases** — 328 passed, 0 failed, 0 skipped. The generated inventory
[`20260910-234511/test-cases.md`](20260910-234511/test-cases.md) is the authority on which cases existed at this run;
`docs/test-cases.md` is that same list at HEAD.

Moved **323 → 328** since the previous run.

No case reported a `skip`, so passed and total agree and nothing in this row claims coverage
that was not exercised.

## Lint

**0 warnings / 0 errors over 44 files** (`luacheck .`).

`.luacheckrc` sets a multi-line `exclude_files`; read it there for the scope of the figure above.
A `0/0` says nothing about what was never looked at.

## Perf

**This repo ships no `tests/perf.lua`, so `perf` is a permanent `skip`** — the first of
`automated-tests-§3`'s two sanctioned reasons, *nothing to run*, rather than a ratified
`performance-§12` no-combat-path exemption. The record is therefore **silent about runtime
cost**: nothing in this file says this addon is fast or cheap, only that the question was
never asked.

## Complexity watch list

Current as of [`20260910-234511`](20260910-234511/) — **this run's measurement, not its diff.** Max CCN **13** across 694
functions, **0** of them warned on; 1 file(s) in the 1000–1500 band and 1 over the 1500 cap
(`layout-§1`).

Every row below is generated from this run's own `lizard` output. **The `Disposition` column is
the one authored cell in this file** (`automated-tests-§4`, *the one boundary*): it is carried
forward verbatim while its entry is unchanged, and left **blank** when the entry is new — a blank
cell is this file saying something crossed and nobody has ruled on it yet.

### Functions `lizard` warned on

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `tests/test_panel.lua` | 1042 | **Accepted.** Newly in the band, and it is the first file this repository has ever had on notice. 526 lines at the previous run's commit; it crossed at 991 with the AceGUI TreeGroup string list and peaked at 1048 before `M4-11` trimmed it by six. The settings panel is the only part of this addon with real branching, so its suite is where the case count lives. On notice is the compliant state under `layout-§1`, not a breach. Re-check at 1200. |
| > 1500 (over cap) | `GlobalStrings/GlobalStrings.lua` | 23842 | **Accepted — not shipped and not loaded.** No TOC line references it and `.pkgmeta:24` excludes the whole `GlobalStrings` directory; it is the build-time input `split_globalstrings.py` reads. `layout-§1` caps files a reader has to change. **The file has not grown**: the 23840 this cell used to sit beside was `lizard`'s NLOC for it, and the 23842 beside it now is the raw line count, which is what the runner's generated table measures. Two lines of difference, one file, no change. |

`lizard` counts every `and`/`or` short-circuit as a decision, so in Lua a run of
`t.k = rec.k or D.k` defaulting lines scores high with no visible branching at all: a large CCN
here usually means *this function defaults or guards a lot of fields* rather than *this function
is tangled*, and the two want different fixes (`performance-§10`).

