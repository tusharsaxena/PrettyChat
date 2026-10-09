# Analysis — 20261009-191724

- **Addon:** PrettyChat 1.6.0 → 1.7.0 (release run, `"release": "1.7.0"`)
- **Verdict:** green
- **Commit:** 3c40352 (master), clean
- **Previous run:** [`20260927-031723`](../20260927-031723/)

## Headline

Green, and the release gate for 1.7.0 passed. Measured at `3c40352`, 63 commits past the previous
run's `a663bc6`: lint 0/0 over 56 files, 574 of 575 cases pass with 1 skipped and 0 failed, max CCN 15
with 0 warnings, and `blindFiles` 0. This is the first **sighted** release run, so the complexity
figures are not directly comparable with the ones above them. `perf` is the ratified
`performance-§12` skip, which the release gate accepts as nothing to run and the 1.7.0 release notes
state in one sentence. Nothing blocks the release.

## Suites

Every row links its artifact, so a reader can get from a figure to the evidence in one click. A
skipped suite links nothing — there is no artifact — and says what was not measured.

| Suite | Status | Result | Artifact | Moved since 20260927-031723 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 56 files | [`lint.txt`](lint.txt) | 53 → 56 files, still 0/0 |
| tests | pass | 574 passed, 1 skipped, 0 failed, 575 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 518 → 575 total; 0 → 1 skipped |
| perf | skip | 0 scenarios. Not measured: `performance-§12` no-combat-path exemption (ratified; `docs/ARCHITECTURE.md` → Documented deviations) | none | unchanged |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | first sighted run; see below |

**Complexity is reported in full**, because a single figure cannot be compared across a change in
size. Every value is [`manifest.json`](manifest.json)'s `suites.complexity`:

| Metric | Value |
|---|---|
| Total NLOC | 57462 |
| Functions | 1319 |
| Avg NLOC / function | 7.3 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 59.9 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 1 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |

**complexity** passed and is sighted: `blindFiles` is 0, so `lizard` measured every function. Every
earlier bundle in `RESULTS.md` predates kit revision 35 and has no `blindFiles` field, so those runs
were **unsighted** and undercount whatever `lizard` dropped. That is why the function count and the
max CCN both moved more than 63 commits of feature work alone would explain, and this run does not
separate the two causes. The max-CCN function is `listSettings` at CCN 15
(`settings/Slash.lua:363`, [`complexity.txt`](complexity.txt)). It does not appear in the previous
bundle's `complexity.txt` at all, so it is **newly measured**, not a regression. It sits at the
threshold, not over it, and it is not warned on.

**tests** passed with one case skipped, not failed. The skip is the kit's diagnostics-contract case
for an addon that opts out of `debug diagnostics` turning logging on
([`tests.txt`](tests.txt), line 564). PrettyChat keeps the default (`Kit.diagnostics.enablesLogging`
is not `false`), so that branch has nothing to check here, and the case above it in the same suite
holds the behavior the addon does have. The skip is counted in the total and in neither passed nor
failed. It is a standing condition of the vendored kit's contract suite, not a gap in this addon's
coverage.

**perf** is a standing skip, not a tooling gap: the second of `automated-tests-§3`'s two sanctioned
reasons. PrettyChat holds a ratified `performance-§12` no-combat-path exemption in its
`docs/ARCHITECTURE.md` register, ships no `tests/perf.lua`, and the manifest's `skipReason` names the
exemption. Runtime cost is therefore not measured by this run, by design. At the release gate this
is the narrow exception `automated-tests-§3` sanctions (nothing was there to run), so the gate
covered lint, tests and complexity, and the new `## Version History` row for 1.7.0 says so.

**Release gate** (read from `manifest.json`): lint pass (0/0); tests pass (0 failed); perf skip,
passed under the no-`tests/perf.lua` exception (`performance-§12`); complexity pass; CCN warnings 0;
`blindFiles` 0.

## What moved

- **lint:** still 0/0, now over 56 files. The three new files are `settings/Profiles.lua`,
  `tests/test_debug_coverage.lua` and `tests/test_profiles.lua` ([`lint.txt`](lint.txt)). The
  `.luacheckrc` exclusions `RESULTS.md` names are unchanged.
- **tests:** 518 → 575 cases. Against the previous bundle's `tests.txt`, 67 case names are new and
  10 are gone or renamed. The growth is the 1.7.0 work: the Profiles page and `/pc profile`
  (`tests/test_profiles.lua`), the debug coverage audit (`tests/test_debug_coverage.lua`), the
  blank-format refusal, the Defaults confirmation, the newer-profile rollback guard, and the kit's
  own contract and `lizard`-sighted cases from the LibKa0s v1.66.0 to v1.71.0 re-vendors. The count
  had been flat at 518 for four runs; it moved because the code did. One case now reports a skip
  where none did before (see above).
- **perf:** still a skip, same reason.
- **complexity:** NLOC 56489 → 57462, functions 1135 → 1319, avg NLOC 6.8 → 7.3, avg CCN 1.9 → 2.1,
  avg tokens 53.3 → 59.9, max CCN 14 → 15, warnings 0 → 0. The previous figures were unsighted and
  these are sighted, so part of every delta is measurement rather than code.
- **bands:** `settings/Schema.lua` 1070 → 1113, still the only file in the band. 0 files over the
  cap.

## Complexity watch list

**Functions `lizard` warned on:**

| Function | CCN | Location | Disposition |
|---|---|---|---|

None. A release bundle has none by construction: the gate requires zero functions above CCN 15.

**Files by `layout-§1` band:**

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `settings/Schema.lua` | 1113 | on notice, re-ruled. +43 lines from the 1.7.0 work (Profiles rows, the blank-format refusal, debug coverage); sixth run in the band, second release run in that span. Grows with the schema, not by tangle. Re-check at 1200 |

The full Disposition cell is in `RESULTS.md`. Nothing newly crossed a band. `settings/Schema.lua` is
carried **On notice**, not **Accepted**, so the three-release-run rule (anti-pattern #53) does not
apply to it. `tests/test_panel.lua`, the entry the 1.6.0 analysis flagged after two **Accepted**
release runs, left the band with the split at `a663bc6` and is no longer owed anything.

## Actions

1. `settings/Slash.lua` `listSettings` (CCN 15, line 363): at the threshold, newly measured. Not
   warned on and not a gate failure, but any further branch in it fails the next release gate. Its
   `category` and `formatstring` arms are self-contained and could be peeled into their own helpers
   before that happens. New here; not yet in the addon's tracking.
