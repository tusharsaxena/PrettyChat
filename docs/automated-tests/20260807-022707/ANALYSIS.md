# Analysis — 20260807-022707

- **Addon:** PrettyChat 1.4.0
- **Verdict:** green
- **Commit:** ae436c9f0264 (master), dirty
- **Started:** 2026-08-07T02:27:07+05:30
- **Previous run:** [`20260804-233338`](../20260804-233338/)

## Headline

Both gating suites are clean — 0 warnings / 0 errors over 17 files, and **260 of 260** cases passing
with **0 skipped** ([`lint.txt`](lint.txt), [`tests.txt`](tests.txt):262). The case count moved for
the first time in this record, 255 → 260, and the movement is real coverage rather than a re-count:
the vendored-payload gate split out of `test_harness.lua` into its own `test_vendor_sync.lua` suite,
and five genuinely new cases arrived — four LibKa0s stub-surface parity checks and one defaults
conversion-sequence check. Complexity is still zero warnings with a measured maximum of **12**, and
it stayed there while the addon grew, which is the reading that matters. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260804-233338` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 17 files | [`lint.txt`](lint.txt) | no change — 0/0 over the same 17 files |
| tests | pass | 260 passed, 0 skipped, 0 failed, 260 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | **+5 cases** (255 → 260); a suite file split out, nothing dropped |
| perf | skip | — no `tests/perf.lua`; this addon ships no offline scenarios | — (not run) | no change — skipped there too, same standing reason |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | grew without densifying — see *What moved* |

### Complexity in full

Every field of `lizard`'s footer, plus the two derived file counts. The **averages** are the point: a
total that rises because the addon grew is a different fact from an average that rises because it got
denser, and only the second is a complexity signal. Every value is `manifest.json`'s
`suites.complexity`, which mirrors the footer at [`complexity.txt`](complexity.txt):607-609.

| Metric | Value |
|---|---|
| Total NLOC | 51337 |
| Functions | 531 |
| Avg NLOC / function | 6.4 |
| Avg CCN | 1.9 |
| Max CCN | 12 |
| Avg tokens / function | 47.9 |
| Warnings (CCN > 15) | 0 |
| Warning rate — `Fun Rt` / `nloc Rt` | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 1 |

[`complexity.txt`](complexity.txt):605 reports "No thresholds exceeded", and the highest-scoring
function in the tree is `Database.RunMigrations@30-50@./core/Database.lua` at CCN 12
([`complexity.txt`](complexity.txt):11) — the same function and the same number as the previous run.

`tests/perf.lua` is absent, so **nothing was measured about runtime cost**. That is a skip, not a
pass: `manifest.json` records `"status": "skip"` with the reason `no tests/perf.lua — this addon
ships no offline scenarios`, and this run says nothing about whether the addon got faster or slower.
`performance-§9`'s zero-overhead evidence does not exist for this addon and cannot until scenarios
are written.

One provenance caveat, recorded rather than corrected — a bundle is frozen evidence
(`automated-tests-§1`). `manifest.json` carries `"dirty": true`, so sha `ae436c9` does not fully
describe what was measured: the tree also held three comment-only citation corrections
(`core/Constants.lua`, `settings/Schema.lua` ×2), replacing a `Config.lua` reference that has not
existed since that file was renamed to `settings/Panel.lua`. Comments do not execute and none of
them can move a figure above, but the sha is stated as incomplete rather than left to imply
otherwise.

## What moved

- **lint** — nothing. 0 warnings / 0 errors over 17 files in both runs ([`lint.txt`](lint.txt)); the
  same 17 files were in scope, so the `0/0` is comparable.
- **tests** — **255 → 260, +5**, and the shape of the suite changed underneath it. Against
  [`20260804-233338`](../20260804-233338/)'s inventory, `test_harness.lua` went 6 → 4 and the two
  vendored-payload cases it lost reappeared as a suite of their own, `test_vendor_sync.lua` (2) — a
  move, not a loss. The net addition is `test_libka0s.lua` 26 → 30, four new stub-surface parity
  cases ("the Core / DebugLog / Options / Slash stub carries the whole live surface"), and
  `test_defaults.lua` 14 → 15, "every default's conversion sequence is a positional prefix of
  Blizzard's". One case was also reworded rather than added (the read-only Original row now reads
  "this client's snapshot"). 0 skipped in both runs ([`tests.txt`](tests.txt):262).
- **perf** — nothing, and nothing could: skipped in both runs for the same standing reason.
- **complexity** — **the addon grew and did not get denser.** Total NLOC 51248 → 51337 (+89) and
  functions 528 → 531 (+3), which is the new test code above. Avg NLOC / function 6.3 → **6.4** and
  Avg tokens / function 47.5 → **47.9** move with it. **Avg CCN is unchanged at 1.9**, **Max CCN is
  unchanged at 12**, and warnings stay **0** with both warning rates at 0.00. The two figures that
  would signal a complexity regression are exactly the two that did not move; the ones that did are
  size, not density.
- **file bands** — unchanged: 0 files in 1000–1500, 1 over the cap. Nothing newly crossed.

## Complexity watch list

### Functions `lizard` warned on

**None.** Zero warnings over 531 functions, measured rather than inferred — the footer at
[`complexity.txt`](complexity.txt):609 records `Warning cnt` 0 against a `Total nloc` of 51337, and
:605 states "No thresholds exceeded" explicitly. The five highest-scoring functions, all well under
the 15 threshold, are `Database.RunMigrations` (`core/Database.lua`, CCN 12,
[`complexity.txt`](complexity.txt):11), `buildParentBody` (`settings/Panel.lua`, 11,
[:114](complexity.txt)), `runTest` (`settings/Slash.lua`, 11, [:176](complexity.txt)),
`PrettyChat:ApplyStrings` (`modules/Override.lua`, 11, [:53](complexity.txt)) and `sampleArg`
(`modules/Override.lua`, 11, [:57](complexity.txt)). This is the same five, at the same scores, as
the previous run. All five are **dense defaulting and guarding** rather than tangled control flow —
`lizard` counts every `and`/`or` short-circuit as a decision, and in Lua a run of `t.k = rec.k or
D.k` lines scores high with no visible branching (`performance-§10`). Naming all five rather than
counting them is the point: the next warned function is a regression against this list, not a
backlog item.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| > 1500 (over cap) | `GlobalStrings/GlobalStrings.lua` | 23840 | **Accepted — not shipped and not loaded.** No TOC line references it and `.pkgmeta` excludes it; it is the build-time input `split_globalstrings.py` reads. `layout-§1` caps files a reader has to change. Carried forward unchanged from `20260804-233338`; nothing newly crossed a band this run. |

The LOC figure is `lizard`'s **NLOC** for the file, [`complexity.txt`](complexity.txt):550 — 23840.
Earlier rows of this record quoted 23842, which is the raw line count; the file has not changed, only
the figure's source is stated here. Nothing is hand-computed.

On the disposition's shelf life: `automated-tests-§4` retires an entry carried as *Accepted* across
**three consecutive release runs**. No run in this record is a release run — every `manifest.json`
here carries `"release": null` — so that clock has not started, and this entry is not yet owed a fix
or a deviation ID. It is the first thing to re-read at the next `--release` run.

## Actions

1. **`tests/perf.lua`** — still absent, so the perf column stays a permanent `skip` and the record
   remains silent about runtime cost. Not new here and not arising from this run; it is a standing
   gap in what this record can say, carried forward from
   [`20260804-233338`](../20260804-233338/ANALYSIS.md).
2. **`GlobalStrings/GlobalStrings.lua` over-cap disposition** — no action now, but the first
   `--release X.Y.Z` run starts the three-release shelf-life clock on it. Re-read the disposition
   there rather than renewing it by default.
