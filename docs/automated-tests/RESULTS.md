# Automated test results

<!-- The newest run is prepended by tests/_kit/run-automated-tests.sh. -->
<!-- This file is OVERWRITTEN IN PLACE — the git history of this one path is the trend line. -->

One row per run. The frozen evidence for each is in the dated folder beside this file; where that
folder carries an `ANALYSIS.md`, that file is the run's write-up. One is required only for a release
run and expected otherwise (`automated-tests-§5`): `20260807-114404`, `20260807-110428`,
`20260807-022707`, `20260804-182235` and `20260804-233338` have one, `20260804-214445` does not.

**`lint` and `tests` gate the run and gate the commit** (`testing-§4`).
**`perf` and `complexity` never fail a run and never block a commit** — they are recorded,
read and compared, not thresholded (`performance-§9`, `performance-§10`).

**The tag is gated on all four suites at `pass`, plus zero functions above CCN 15**
(`automated-tests-§3`, *The release gate*), evaluated by `/wow-addon:bump-version` from the
`manifest.json` the release run writes — not by this script, whose exit code is unchanged.

A `skip` is a suite that did not run at all. It is never a pass, and at the release gate it is
**NOT EVALUATED** rather than passed: install the tool and re-run. A `—` is a suite that was
not selected, which is a different fact again.

| Run | Version | Lint w/e | Files | Tests | Perf | NLOC | Funcs | Avg NLOC | Avg CCN | Max CCN | CCN warn | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| [`20260825-103457`](20260825-103457/) | 1.4.0 | 0/0 | 18 | 271/271 | skip | 51480 | 555 | 6.3 | 1.9 | 12 | 0 | **green** |
| [`20260807-114404`](20260807-114404/) | 1.4.0 | 0/0 | 17 | 260/260 | skip | 51337 | 531 | 6.4 | 1.9 | 12 | 0 | **green** |
| [`20260807-110428`](20260807-110428/) | 1.4.0 | 0/0 | 17 | 260/260 | skip | 51337 | 531 | 6.4 | 1.9 | 12 | 0 | **green** |
| [`20260807-022707`](20260807-022707/) | 1.4.0 | 0/0 | 17 | 260/260 | skip | 51337 | 531 | 6.4 | 1.9 | 12 | 0 | **green** |
| [`20260804-233338`](20260804-233338/) | 1.4.0 | 0/0 | 17 | 255/255 | skip | 51248 | 528 | 6.3 | 1.9 | 12 | 0 | **green** |
| [`20260804-214445`](20260804-214445/) | 1.4.0 | 0/0 | 17 | 255/255 | skip | 51248 | 528 | 6.3 | 1.9 | 0 | 0 | **green** |
| [`20260804-182235`](20260804-182235/) | 1.4.0 | 0/0 | 17 | 255/255 | skip | 51217 | 519 | 6.4 | 1.9 | 23 | 2 | **green** |

**Reading the Max CCN column: the `0` in `20260804-214445` is an instrument fault, not a
measurement.** Runs recorded before the testkit rev-6 re-vendor read `CCN_MAX` out of `lizard`'s
`!!!! Warnings` block, so the figure collapsed to `0` the moment an addon reached zero warnings.
One run of this record is affected — `20260804-214445` — and its true maximum is **12**, which was
always present in that same bundle's [`complexity.txt`](20260804-214445/complexity.txt)
(`Database.RunMigrations@30-50@./core/Database.lua`). The row is left exactly as the runner emitted
it: a generated figure edited by hand reads as measured when it is not (`performance-§10`). Read the
trend as 23 → 12 → 12.

## Test suite

260 cases, across 17 suite files, with **0 skipped** — the figure `[20260807-114404](20260807-114404/tests.txt)` states in full rather than the `260/260` the table has room for. The suite builds a fully isolated addon instance per case (`tests/loader.lua`), because the addon's whole job is writing `_G[GLOBALNAME]` and a shared environment would let one case's overrides answer another's reads. The generated inventory `test-cases.md` in each bundle is the authority on what exists at that point; the README badge tracks the same number. The count held at 255 across the first three recorded runs and moved once, at `20260807-022707`: the consumer-side vendored-payload gate split out of `test_harness.lua` into its own `test_vendor_sync.lua` (a move, not new coverage), and five genuinely new cases arrived — four LibKa0s stub-surface parity checks in `test_libka0s.lua` and one conversion-sequence check in `test_defaults.lua`. It has now sat at 260 across **three consecutive runs**, which is expected here because no addon source changed across them; the run to watch is the next one that does change source without moving this number. Panel rendering, live chat overrides and positional `%n$s` formats are covered only by the in-game [smoke-test suite](../smoke-tests.md), so a coverage gap in those areas does not surface as a failure anywhere in this record.

## Lint

Clean over 17 files, and clean over the same 17 in every recorded run. Scope excludes `libs/` (vendored, not this addon's to lint), `tests/`, `docs/audits`, `docs/reviews` and the generated `GlobalStrings/` chunks — the last is **46,771 of the tree's 51,337 NLOC, 91%** (measured from `20260807-114404`'s [`complexity.txt`](20260807-114404/complexity.txt)) and carries no logic, so a clean lint here says nothing at all about that data. The `tests/` exclusion matters as much: the harness is 20 files that lint never reads, and it is where most of the repo's hand-written Lua now lives. Before quoting 0/0, confirm the four seam files (`core/CoreSetup.lua`, `core/DebugLogSetup.lua`, `settings/OptionsSetup.lua`, `settings/Slash.lua`) are inside the set that was actually checked; the config is `.luacheckrc`.

## Perf

This addon ships no `tests/perf.lua`, so the `perf` column is a permanent `skip` rather than a transient tooling gap — the first of `automated-tests-§3`'s two sanctioned reasons, *nothing to run*, and **not** a recorded `performance-§12` no-combat-path exemption. Every bundle records it verbatim as `skipReason: "no tests/perf.lua — this addon ships no offline scenarios"`. Two things follow, and both are standing facts rather than any run's news: the record says **nothing** about the addon's runtime cost, and `performance-§9`'s zero-overhead evidence — that bracketed instrumentation is free when capture is off — does not exist for it. Adding scenarios is the only thing that changes either. It also matters at the tag: a skip is **NOT EVALUATED** rather than passed by the release gate (`automated-tests-§3`), so as things stand no `--release` run of this addon can clear all four suites without either a `tests/perf.lua` or a ratified `performance-§12` exemption. In-game captures, which no script can produce, have no standing store in this repo yet.

## Complexity watch list

Current state as of [`20260807-114404`](20260807-114404/) — not that run's diff.
Every function `lizard` warned on, and every file at or above `layout-§1`'s 1000-LOC
on-notice threshold, each with a one-line disposition.

### Functions `lizard` warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|
| — | — | — | **None.** Zero warnings over 531 functions; nothing is deferred. |

Zero warnings over 531 functions, with the maximum **measured** at 12 rather than inferred from an
empty warning list — see the note under the table for why `20260804-214445` recorded `0`. The two
entries this list once carried were `PrettyChat:Test` (CCN 23) and `build` in `tests/loader.lua`
(CCN 18); both were split into named units, to CCN 6 and 3, with no behavior change, and their
dispositions retired with them. The five functions nearest the threshold, named rather than counted
so the next regression is visible, are `Database.RunMigrations` (`core/Database.lua`, CCN 12),
`buildParentBody` (`settings/Panel.lua`, 11), `runTest` (`settings/Slash.lua`, 11),
`PrettyChat:ApplyStrings` (`modules/Override.lua`, 11) and `sampleArg` (`modules/Override.lua`, 11)
— the same five, at the same scores, as `20260804-233338`, `20260807-022707` and `20260807-110428`.
All five are dense **defaulting and guarding** rather than tangled control flow: `lizard` scores
every `and`/`or` short-circuit as a decision, so a run of `t.k = rec.k or D.k` lines rates high with
no visible branching (`performance-§10`), and the two want different fixes and carry different
risk. The next warned function is a regression against this list, not a backlog item.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| > 1500 (over cap) | `GlobalStrings/GlobalStrings.lua` | 23840 | **Accepted — not shipped and not loaded.** No TOC line references it and `.pkgmeta:24` excludes the whole `GlobalStrings` directory; it is the build-time input `split_globalstrings.py` reads. `layout-§1` caps files a reader has to change. Carried forward unchanged; nothing newly crossed a band at `20260807-114404`. |

No file sits in the 1000–1500 on-notice band. The LOC figure is `lizard`'s NLOC for the file
([`20260807-114404/complexity.txt`](20260807-114404/complexity.txt):550). Rows written before
`20260807-022707` quoted 23842, the raw line count; the file has not changed, only the figure's
stated source. Nothing here is hand-computed.

**On the shelf life of that *Accepted*.** `automated-tests-§4` retires an entry carried as accepted
across **three consecutive release runs**. No run in this record is a release run — every
`manifest.json` here carries `"release": null`, `20260807-114404` included — so the clock has not
started and the entry is not yet owed a fix or a tracked deviation ID. The first `--release X.Y.Z`
run is where this disposition gets re-read rather than renewed by default.

## Line endings

Standing fact about the record itself, not about the addon. Bundles written by testkit revisions 1–9
landed **LF** on disk even though this repo pins `* text=auto eol=crlf`, because the runner writes
through plain shell redirects that bypass git's clean filter — invisible to `git status` and
unreachable by `git add --renormalize`, which fixes the index and not the working tree. LibKa0s
v1.8.2 / **kit revision 10** adds a `normalize_eol` pass over the finished directory that asks
`git check-attr text eol` per path. `20260807-114404` is the first bundle written by revision 10 onto
a **clean** tree and left **untracked**, so its on-disk bytes are the runner's own output with no git
filter in the path: all five bundle files measure equal CR and LF byte counts
(`complexity.txt` 609/609, `lint.txt` 19/19, `manifest.json` 19/19, `test-cases.md` 341/341,
`tests.txt` 262/262), as did this file at the moment the runner finished with it. No count is quoted
here for this file itself, because the standing sections above are rewritten by hand after every run
and any figure would be stale the moment it was written; measure it directly instead. Verify with
byte counts, never `file(1)`, which reports nothing about line terminators for JSON or for a
one-line file (`line-endings-§7`).
