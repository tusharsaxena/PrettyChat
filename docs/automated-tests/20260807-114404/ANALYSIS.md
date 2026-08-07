# Analysis — 20260807-114404

- **Addon:** PrettyChat 1.4.0
- **Verdict:** green
- **Commit:** 836beb5fb8f7 (master), clean
- **Started:** 2026-08-07T11:44:04+05:30
- **Previous run:** [`20260807-110428`](../20260807-110428/)

## Headline

Green on both gating suites, and every measured figure is byte-for-byte the previous run's: lint 0/0
over 17 files, **260 of 260** cases passing with **0 skipped**, 51337 NLOC over 531 functions, max
CCN 12, zero complexity warnings. No addon source moved between the two runs — the only commit
between them, `836beb5`, re-synced `.gitattributes` to the canonical body — so identical numbers are
the correct result rather than a missing measurement.

What this run adds over the previous one is **provenance for the line-ending fix**. Run
`20260807-110428` was written on a dirty tree and committed in the same change as the re-vendor
(`b7b9180`), so its CRLF-on-disk cannot be distinguished from a checkout conversion. This bundle is
**untracked** — git has never applied a filter to it — and all five files are CRLF anyway. That is
kit revision 10's `normalize_eol` observed directly at write time, with no git filter in the path.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260807-110428` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 17 files | [`lint.txt`](lint.txt) | no change — 0/0 over the same 17 files |
| tests | pass | 260 passed, 0 skipped, 0 failed, 260 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | no change — same 260, identical inventory |
| perf | skip | — no `tests/perf.lua`; this addon ships no offline scenarios | — (not run) | no change — skipped there too, same standing reason |
| complexity | pass | 0 warnings, max CCN 12 | [`complexity.txt`](complexity.txt) | no change — every footer field identical |

### Complexity in full

Every field of `lizard`'s footer, from `manifest.json`'s `suites.complexity`, mirroring
[`complexity.txt`](complexity.txt):607-609.

| Metric | Value | vs `20260807-110428` |
|---|---|---|
| Total NLOC | 51337 | unchanged |
| Functions | 531 | unchanged |
| Avg NLOC / function | 6.4 | unchanged |
| Avg CCN | 1.9 | unchanged |
| Max CCN | 12 | unchanged |
| Avg tokens / function | 47.9 | unchanged |
| Warnings (CCN > 15) | 0 | unchanged |
| Warning rate — `Fun Rt` / `nloc Rt` | 0.00 / 0.00 | unchanged |
| Files in the 1000–1500 band | 0 | unchanged |
| Files over the 1500 cap | 1 | unchanged |

Both halves are reported deliberately. The **total** (51337 NLOC, 531 functions) says how large the
tree is; the **averages** (6.4 NLOC and 1.9 CCN per function, 47.9 tokens) say how dense it is. Only
the second is a complexity signal, and neither moved. The total is dominated by generated data rather
than logic: `GlobalStrings/GlobalStrings.lua` alone is 23840 NLOC
([`complexity.txt`](complexity.txt):550) at CCN 0, so the average CCN of 1.9 is diluted by a large
body of declarations and should be read alongside the max, not instead of it.

`tests/perf.lua` is absent, so **nothing was measured about runtime cost**. `manifest.json` records
`"status": "skip"` with the reason verbatim; this run says nothing about whether the addon got faster
or slower, and `performance-§9`'s zero-overhead evidence does not exist for this addon. This is the
first of `automated-tests-§3`'s two sanctioned perf skip reasons — *nothing to run* — not a
`performance-§12` no-combat-path exemption, and not a missing tool.

Everything else was measured: `lua` 5.1.5, `luacheck` 1.2.0 and `lizard` 1.23.0 were all present and
all executed (`manifest.json`'s `host` block). No suite was skipped for a missing tool.

## What moved

- **lint** — nothing. Same 17 files, same 0/0. [`lint.txt`](lint.txt) is byte-identical to the
  previous run's.
- **tests** — nothing. Same 260 passed / 0 skipped / 260 total, and [`test-cases.md`](test-cases.md)
  is byte-identical, so the inventory did not gain, lose or rename a case.
- **perf** — nothing, and nothing could. Standing skip.
- **complexity** — nothing. [`complexity.txt`](complexity.txt) is byte-identical to the previous
  run's, footer included.
- **the tree state** — this run was taken on a **clean** working tree
  (`manifest.json`: `"dirty": false`) at `836beb5`, where the previous run carried `"dirty": true`.
  The previous bundle's numbers described a tree that also held the uncommitted re-vendor; this one's
  describe exactly what `836beb5` contains. That the figures agree is the useful part: it confirms
  the re-vendored payload measured the same before and after it was committed.
- **line endings** — the run's own news. Every file the runner wrote carries CRLF, matching the
  repo's `* text=auto eol=crlf` pin, measured as CR-byte count against LF-byte count
  (`line-endings-§7`'s check, not `file(1)`, which reports nothing for JSON or a one-line file):
  `complexity.txt` 609/609, `lint.txt` 19/19, `manifest.json` 19/19, `test-cases.md` 341/341,
  `tests.txt` 262/262. Zero mismatches across all five. `RESULTS.md`, which the runner appends to
  rather than creates, measured 89/89 the moment the run finished — one CRLF pair more than the
  88/88 the previous run left it at, the row this run prepended. It has grown since, because Step
  4's standing sections are rewritten by hand after the run; that later state is not this bundle's
  evidence.

## Complexity watch list

### Functions `lizard` warned on

**None.** Zero warnings over 531 functions — [`complexity.txt`](complexity.txt):605 states "No
thresholds exceeded" and the footer's `Warning cnt` is 0. The highest-scoring function in the tree is
`Database.RunMigrations@30-50@./core/Database.lua` at CCN 12
([`complexity.txt`](complexity.txt):11), unchanged across the last four runs.

The five functions nearest the threshold carry forward from
[`20260807-110428`](../20260807-110428/ANALYSIS.md) at identical scores, named rather than counted so
the next regression is visible against a list instead of a number:

| Function | CCN | Location | Disposition |
|---|---|---|---|
| `Database.RunMigrations` | 12 | `core/Database.lua` ([`complexity.txt`](complexity.txt):11) | Below threshold — dense **defaulting/guarding**, not tangled control flow. No action. |
| `PrettyChat:ApplyStrings` | 11 | `modules/Override.lua` ([`complexity.txt`](complexity.txt):53) | Below threshold — defaulting/guarding. No action. |
| `sampleArg` | 11 | `modules/Override.lua` ([`complexity.txt`](complexity.txt):57) | Below threshold — defaulting/guarding. No action. |
| `buildParentBody` | 11 | `settings/Panel.lua` ([`complexity.txt`](complexity.txt):114) | Below threshold — defaulting/guarding. No action. |
| `runTest` | 11 | `settings/Slash.lua` ([`complexity.txt`](complexity.txt):176) | Below threshold — defaulting/guarding. No action. |

All five are dense **defaulting and guarding** rather than tangled control flow. `lizard` scores every
`and`/`or` short-circuit as a decision, so a run of `t.k = rec.k or D.k` lines rates high with no
visible branching at all (`performance-§10`), and the two conditions want different fixes and carry
different risk. Nothing here is deferred: the next warned function is a **regression** against this
list, not a backlog item.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| > 1500 (over cap) | `GlobalStrings/GlobalStrings.lua` | 23840 | **Accepted — not shipped and not loaded.** No TOC line references it and `.pkgmeta` excludes the whole `GlobalStrings` directory; it is the build-time input `split_globalstrings.py` reads. `layout-§1` caps files a reader has to change. Carried forward unchanged; nothing newly crossed a band this run. |

The LOC figure is `lizard`'s NLOC for the file ([`complexity.txt`](complexity.txt):550). Nothing here
is hand-computed. No file sits in the 1000–1500 band (`manifest.json`: `"bandFiles": 0`).

`automated-tests-§4`'s three-release shelf life on that **Accepted** has not started: every
`manifest.json` in this record carries `"release": null`, this one included, so no entry has been
carried across even one release run, let alone three. The first `--release X.Y.Z` run is where the
disposition gets re-read rather than renewed by default.

## Actions

1. **`tests/perf.lua`** — still absent. The perf column stays a permanent `skip` and the record stays
   silent about runtime cost. Standing gap carried forward from
   [`20260807-110428`](../20260807-110428/ANALYSIS.md), not arising here. It is also the one thing
   that would stop a `--release` run cleanly clearing all four suites, since a skip is **NOT
   EVALUATED** rather than passed at the tag (`automated-tests-§3`).
2. **`GlobalStrings/GlobalStrings.lua` over-cap disposition** — no action now; the first
   `--release X.Y.Z` run starts the shelf-life clock. Re-read the disposition there rather than
   renewing it.
3. **Nothing from the kit re-vendor.** Both gating suites are green on a clean tree, the vendored
   payload gates pass against the tag, and the bundle now lands with the line endings the repo
   declares — verified as an untracked directory, so no git filter can be credited for it. The
   revision 10 `normalize_eol` fix is proven end to end here.
