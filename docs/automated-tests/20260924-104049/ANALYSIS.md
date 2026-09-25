# Analysis — 20260924-104049

- **Addon:** PrettyChat 1.5.0
- **Verdict:** green
- **Commit:** f85e6d1ee112 (feat/2026-09-23-review-audit-remediation), clean
- **Previous run:** [`20260916-184747`](../20260916-184747/)

## Headline

Green. This is the first run on the LibKa0s v1.56.0 re-vendor (kit revision 26), taken after the
2026-09-23 remediation items and before any version bump. Both gating suites are clean: lint is 0/0
over 48 files and 481 of 481 cases pass. The case count is up 385 → 481. `perf` is still a skip, but
for a different reason: kit 26 reads the ratified `performance-§12` no-combat-path exemption out of
`docs/ARCHITECTURE.md`'s register, where the previous run could only say "no `tests/perf.lua`".
Complexity kept every average flat while the tree gained 184 functions, and nothing crossed CCN 15.
`settings/Schema.lua` entered the 1000–1500 band, and its Disposition cell rules on it.

## Suites

Every row links its artifact, so a reader can get from a figure to the evidence in one click. A
skipped suite links nothing — there is no artifact — and says what was not measured.

| Suite | Status | Result | Artifact | Moved since 20260916-184747 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 48 files | [`lint.txt`](lint.txt) | files 46 → 48 |
| tests | pass | 481 passed, 0 skipped, 0 failed, 481 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 385 → 481 |
| perf | skip | 0 scenarios. Not measured: `performance-§12` no-combat-path exemption (ratified; `docs/ARCHITECTURE.md` → Documented deviations) | none | the reason moved from "no `tests/perf.lua`" to the exemption |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | see *What moved* |

**Complexity is reported in full**, because a single figure cannot be compared across a change in
size. Every value is `manifest.json`'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 55657 |
| Functions | 1038 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 1.9 |
| Max CCN | 14 |
| Avg tokens / function | 53.0 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 2 |
| Files over the 1500 cap | 1 |

**perf** is the one suite that is not a clean pass. It is a standing skip, not a tooling gap, and it
is the second of `automated-tests-§3`'s two sanctioned reasons. PrettyChat holds a ratified
`performance-§12` no-combat-path exemption: a register row in `docs/ARCHITECTURE.md` backed by the
committed sweep in `docs/performance-sweep.md`. So there is no combat path for a scenario to
measure. The manifest's `skipReason` and `RESULTS.md`'s `## Perf` paragraph both name it. Through
kit revision 25 the runner could only write the first reason ("no `tests/perf.lua`"), and the record
denied an exemption the addon held (`PRETTYCHAT-A-15`). The v1.56.0 re-vendor closed that upstream
(LK-09), and this run is the first to show it.

## What moved

- **lint:** still 0/0. The scope grew from 46 to 48 files: `core/LifecycleSetup.lua`,
  `tests/prose_waivers.lua` and `tests/test_disabled.lua` arrived, and the hand-written
  `tests/test_layout_cap.lua` left for the kit's gate (`lint.txt` in each bundle). The
  `.luacheckrc` exclusions `RESULTS.md` names are unchanged.
- **tests:** 385 → 481 (+96). The growth comes from the launcher and settings work before the
  2026-09-23 review, then the remediation items' red-first cases: the migration v2 cases, the
  page-wide Defaults buttons, the `NS.RejectedEvents` and `SafeRegisterEvents` cases, the memoized
  name list, and the surface-parity pins. Kit 26's section-sign case names also moved some kit
  cases (lines carrying `§` in `test-cases.md`: 7 → 10), so the inventory differs from the previous
  bundle's in names as well as in count.
  No case reported a skip.
- **perf:** still a skip, now with the exemption reason (see above).
- **complexity:** NLOC 54311 → 55657 and functions 854 → 1038. Avg NLOC went 6.7 → 6.8, avg CCN
  2.0 → 1.9, and avg tokens 51.0 → 53.0. Max CCN held at 14 and there are still 0 warnings. The
  functions got smaller and simpler on average while the count rose, which is growth and not
  densification.
- **bands:** the 1000–1500 band went from 1 file to 2. `tests/test_panel.lua` rose 1053 → 1125.
  `settings/Schema.lua` is new at 1070. The over-cap count held at 1, the generated
  `GlobalStrings/GlobalStrings.lua` at 23842, unchanged.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `settings/Schema.lua` | 1070 | on notice, new this run. It grows with the schema rather than by tangle. Re-check at 1200 |
| 1000–1500 (on notice) | `tests/test_panel.lua` | 1125 | accepted, carried forward. Case count, not tangle. Re-check at 1200 |
| > 1500 (over cap) | `GlobalStrings/GlobalStrings.lua` | 23842 | exempt — see docs/ARCHITECTURE.md → Files over the 1500-line cap |

The full Disposition cells are in `RESULTS.md`. The dump's cell now points at the census row instead
of arguing the exemption a second time, and the stale `.pkgmeta:24` citation is gone with it
(`PRETTYCHAT-A-17`).

## Actions

1. `tests/test_panel.lua`: 75 lines of headroom to the 1200 re-check. The next panel feature of
   PC-06's size should peel a suite along a seam first (the per-string editor cases are the obvious
   one). New here; no tracked id.
2. This bundle is not a release record (`"release": null`). No version bump and no tag was cut. The
   release run belongs to `/wow-addon:bump-version` when the owner decides to release.
