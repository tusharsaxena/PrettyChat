# Analysis — 20260804-233338

- **Addon:** PrettyChat 1.4.0
- **Verdict:** green
- **Commit:** 9bb28dbdfde5 (feat/fix-ccn), dirty
- **Started:** 2026-08-04T23:33:38+05:30
- **Previous run:** [`20260804-214445`](../20260804-214445/)

## Headline

This is the run that closes the CCN work: **zero functions above CCN 15**, with a measured maximum of
**12** (`Database.RunMigrations`) — [`complexity.txt`](complexity.txt):601 reports "No thresholds
exceeded", and `manifest.json` records `maxCcn: 12` against `warnings: 0`. The previous run,
[`20260804-214445`](../20260804-214445/), measured **the same code** — identical NLOC (51248),
function count (528), Avg CCN (1.9) and Avg NLOC (6.3) — but under a test kit whose `CCN_MAX` was
read out of `lizard`'s `!!!! Warnings` block, so it reported `0` the moment the warning list went
empty. Nothing about the addon moved between the two runs; the **instrument** did. Both gating suites
stay clean: 0 warnings / 0 errors over 17 files, 255 of 255 cases passing. Nothing to act on.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260804-214445` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 17 files | [`lint.txt`](lint.txt) | no change — 0/0 over 17 files there too |
| tests | pass | 255 passed, 0 failed, 255 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | no change — 255/255 there too |
| perf | skip | — no `tests/perf.lua`; this addon ships no offline scenarios | — (not run) | no change — skipped there too |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Max CCN now reported: **12** (recorded as `0` there, an instrument fault) |

### Complexity in full

Every field of `lizard`'s footer, plus the two derived file counts. The **averages** are the point: a
total that rises because the addon grew is a different fact from an average that rises because it got
denser, and only the second is a complexity signal. Every value is `manifest.json`'s
`suites.complexity`, which mirrors the footer at [`complexity.txt`](complexity.txt):603-605.

| Metric | Value |
|---|---|
| Total NLOC | 51248 |
| Functions | 528 |
| Avg NLOC / function | 6.3 |
| Avg CCN | 1.9 |
| Max CCN | 12 |
| Avg tokens / function | 47.5 |
| Warnings (CCN > 15) | 0 |
| Warning rate — `Fun Rt` / `nloc Rt` | 0.00 / 0.00 |
| Files in the 1000–1500 band | 0 |
| Files over the 1500 cap | 1 |

`tests/perf.lua` is absent, so nothing was measured about runtime cost. That is a **skip, not a
pass**: `manifest.json` records it as `"status": "skip"` with its reason, and this run says nothing
about whether the addon got faster or slower. `performance-§9`'s zero-overhead evidence does not
exist for this addon, and no run of this record can supply it until scenarios are written.

Two provenance caveats, recorded rather than corrected — a bundle is frozen evidence
(`automated-tests-§1`). `manifest.json` carries `"dirty": true`, so sha `9bb28db` does **not** fully
describe what was measured: the tree also held the LibKa0s v1.7.0 re-vendor that later landed as
`f5ebb36`, which is exactly the change that made the Max CCN figure readable. And the complexity
suite's `"durationMs": -1000` is negative, so it is a kit timing artifact rather than an elapsed
time; no figure above depends on it.

## What moved

- **lint** — nothing. 0 warnings / 0 errors over 17 files in both runs ([`lint.txt`](lint.txt)).
- **tests** — nothing. 255 passed / 0 failed in both runs ([`tests.txt`](tests.txt)); the generated
  inventory [`test-cases.md`](test-cases.md) is unchanged, so no case was added, renamed or dropped.
- **perf** — nothing, and nothing could: skipped in both runs for the same standing reason.
- **complexity** — **no code moved; the measurement did.** NLOC, functions, Avg NLOC, Avg CCN, Avg
  tokens, both warning rates and both file-band counts are identical to `20260804-214445`. The one
  changed figure is Max CCN, `0` → `12`, and it is an instrument correction rather than a regression:
  the previous kit derived `CCN_MAX` from the warnings block alone. The true maximum was always in
  that run's own [`complexity.txt`](../20260804-214445/complexity.txt), which scores
  `Database.RunMigrations@30-50@./core/Database.lua` at CCN 12 — the same function, the same number.
- **the arc across three runs** — [`20260804-182235`](../20260804-182235/) measured Max CCN 23 with 2
  warnings: `PrettyChat:Test` at 23 and `build` in `tests/loader.lua` at 18. Both were split into
  named units on this branch with no behavior change. [`complexity.txt`](complexity.txt):66 now
  scores `PrettyChat@300-325@./modules/Override.lua` — `PrettyChat:Test`, `modules/Override.lua:300`
  — at **CCN 6**, and :183 scores `build@118-144@./tests/loader.lua` at **CCN 3**. Read the trend as
  23 → 12 → 12; the intervening `0` is the instrument fault described above.

## Complexity watch list

### Functions `lizard` warned on

**None.** Zero warnings over 528 functions, and with this run the figure is finally *measured* rather
than inferred from an empty warning list. The five highest-scoring functions, all well under the 15
threshold, are — from [`complexity.txt`](complexity.txt) — `Database.RunMigrations`
(`core/Database.lua`, CCN 12), `PrettyChat:ApplyStrings` (`modules/Override.lua`, 11), `sampleArg`
(`modules/Override.lua`, 11), `runTest` (`settings/Slash.lua`, 11) and `buildParentBody`
(`settings/Panel.lua`, 11). Naming all five rather than counting them is the point: the next warned
function is a regression against this list, not a backlog item.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| > 1500 (over cap) | `GlobalStrings/GlobalStrings.lua` | 23842 | **Accepted — not shipped and not loaded.** No TOC references it and `.pkgmeta:21` excludes it; it is the build-time input `split_globalstrings.py` reads. `layout-§1` caps files a reader has to change. Carried forward unchanged from `20260804-182235`; nothing newly crossed a band this run. |

## Actions

1. **`docs/automated-tests/RESULTS.md`** — the `20260804-214445` row's `Max CCN 0` stands as
   recorded, because a generated row that has been hand-corrected reads as measured when it is not
   (`performance-§10`). Instead that file's standing prose names the affected stamp, the cause and
   where the true figure lives, so a reader hitting `23 → 0 → 12` in the trend column reaches the
   explanation in one step. Written as this run's Step 3.
2. **`tests/perf.lua`** — still absent, so the perf column stays a permanent `skip`. Not new here and
   not arising from this run; it is a standing gap in what this record is able to say.
