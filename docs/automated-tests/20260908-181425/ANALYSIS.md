# Analysis — 20260908-181425

- **Addon:** PrettyChat 1.4.0
- **Verdict:** green
- **Commit:** 4feceda (`feat/2026-09-07-audit-review-remediation`), clean
- **Previous run:** [`20260825-103457`](../20260825-103457/)

## Headline

Three suites pass and one is a permanent skip. Lint 0/0 over 43 files, 323 cases with none failed and
none skipped, `lizard` warns on nothing at max CCN 13 across 688 functions, and `perf` skips because
this repository ships no `tests/perf.lua`.

This is the first bundle written by test-kit revision 15 and the first whose `RESULTS.md` came out of
the runner end to end. The watch list it replaces described [`20260807-114404`](../20260807-114404/),
two runs back — not through neglect, but because until today the two tables `automated-tests-§4`
mandates had no producer and the standing sections had to be rewritten by hand after every run.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260825-103457` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 43 files | [`lint.txt`](lint.txt) | 18 → 43 files; 0/0 unchanged |
| tests | pass | 323 passed, 0 skipped, 0 failed, 323 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 271 → 323 |
| perf | skip | no `tests/perf.lua` | — | Unchanged, and permanent |
| complexity | pass | 0 warnings, max CCN 13 | [`complexity.txt`](complexity.txt) | Max 12 → 13; band 0 → 1 file |

**Complexity in full.**

| Metric | `20260825-103457` | This run |
|---|---|---|
| Total NLOC | 51480 | 52962 |
| Functions | 555 | 688 |
| Avg NLOC / function | 6.3 | 6.6 |
| Avg CCN | 1.9 | 2.0 |
| Max CCN | 12 | 13 |
| Avg tokens / function | 47.6 | 49.4 |
| Warnings (CCN > 15) | 0 | 0 |
| Files 1000–1500 | 0 | 1 |
| Files over 1500 | 1 | 1 |

**Read the Total NLOC column with its cause attached.** 52962 against 688 functions is 77 NLOC per
function, and the Avg NLOC column says 6.6. Both are right: nearly all of that total is
`GlobalStrings/GlobalStrings.lua`, 23840 NLOC of generated data holding no functions at all, plus its
split chunks. This addon's own hand-written Lua is a small fraction of the figure, and a reader
comparing this repository's NLOC to a sibling's is comparing a data file to an addon.

The five functions nearest the line, named rather than counted so the next regression is visible:
`fitTree` (`settings/Panel.lua@415-438`, 13), `scanLiterals` (`tests/test_locale.lua@143-181`, 12),
`PrettyChat@123-172` (`modules/Override.lua`, 12), `Database.RunMigrations`
(`core/Database.lua@30-50`, 12) and `runTest` (`settings/Slash.lua@336-383`, 11). The threshold is
15, so there is real headroom here — this is the only repository in the collection with more than a
point or two of it.

## What moved

- **lint** — 18 → 43 files at 0/0, `M4-11` bringing the test tree into scope. The exclusions still
  matter more than the figure: `.luacheckrc` excludes `GlobalStrings`, which is the great majority
  of the tree's NLOC and carries no logic, so a clean lint here says nothing whatever about that
  data. It never entered lint scope and it never will.
- **tests** — 271 → 323. `docs/test-cases.md` and the README badge already read 323, and the
  bundle's [`test-cases.md`](test-cases.md) is byte-identical to `docs/test-cases.md` at HEAD, so no
  count claim moves in this commit. What the suite does **not** cover has not changed: panel
  rendering, live chat overrides and positional `%n$s` formats are exercised only by the in-game
  [smoke-test suite](../../smoke-tests.md), so a gap there surfaces nowhere in this record.
- **complexity** — max CCN 12 → 13, `fitTree` in the settings panel. Still two clear points under
  the threshold.
- **Band** — `tests/test_panel.lua` crossed 1000 and is the first file this repository has ever had
  on notice. 526 lines at the previous run's commit, 991 with the AceGUI TreeGroup string list,
  1048, then 1042. `GlobalStrings/GlobalStrings.lua` is unchanged.

## The GlobalStrings figure moved and the file did not

The band row reads **23842** where the previous, hand-written row read **23840**. The file has not
changed by a byte. The old row quoted `lizard`'s NLOC for it; the runner's generated table measures
raw line count, which is what `layout-§1` caps. Two lines of difference, one source of truth swapped
for another, no growth. It is worth stating plainly because a two-line rise in a 23,000-line file is
exactly the kind of thing a later reader takes for drift.

Its disposition is unchanged and still correct: the file is not shipped and not loaded — no TOC line
references it, `.pkgmeta:24` excludes the whole directory, and it is the build-time input
`split_globalstrings.py` reads. `layout-§1` caps files a reader has to change.

## On the `perf` skip, which is the one standing gap

This is the first of `automated-tests-§3`'s two sanctioned reasons — *nothing to run* — and **not** a
ratified `performance-§12` no-combat-path exemption. Two consequences, both standing facts rather
than this run's news:

- The record says **nothing** about this addon's runtime cost, and `performance-§9`'s zero-overhead
  evidence does not exist for it.
- At the tag, a skip is **NOT EVALUATED** rather than passed. As things stand no `--release` run of
  this addon can clear all four suites without either a `tests/perf.lua` or a ratified exemption.

Adding scenarios is the only thing that changes either.

## What this run removed from the record, deliberately

The regeneration dropped a standing section on line endings that recorded
[`20260807-114404`](../20260807-114404/) as the first bundle written by kit revision 10's
`normalize_eol` pass onto a clean tree, with equal CR and LF counts across all five of its files. The
substance is now asserted rather than described: the suite carries a case that checks every tracked
file against the terminator `.gitattributes` declares for it, on every run. A paragraph that had to
be rewritten by hand became a gate that cannot go stale.

## The `ANALYSIS.md` gap, noted once

Three of eight bundles here carry no `ANALYSIS.md`: `20260804-214445`, `20260825-103457`, and until
this file, this one. The first two are not getting one. An analysis written today into a folder
stamped in August would date a reading to a day nobody took it, which is worse than a gap, because a
gap is legible. Fixed forward. Collection-wide the gap stands at 37 of 95 bundles.

## Actions

None. No warned function, one tracked over-cap file that is not shipped, one newly on-notice suite
with a re-check trigger, and no disposition due for conversion — every manifest here carries
`"release": null`, so the three-consecutive-release-runs clock has not started.
