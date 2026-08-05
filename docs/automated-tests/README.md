# Automated test records

Every run of the four out-of-game suites, recorded. The normative rules are the standard's
[`automated-tests`](https://github.com/tusharsaxena/WowAddonStandards/blob/master/standards/standards/automated-tests.md)
section; this file is the local how-to.

## Running

```sh
tests/_kit/run-automated-tests.sh                            # all four, writes a bundle
tests/_kit/run-automated-tests.sh --suite complexity          # a subset
tests/_kit/run-automated-tests.sh --suite lint --suite tests --no-bundle   # the green gate; writes nothing
```

The runner is **vendored** from `LibKa0s`'s `testkit/` and is byte-identical in every Ka0s addon.
Never edit `tests/_kit/` — a kit fix goes upstream and is re-vendored, and a local patch is reverted
silently by the next re-vendor.

## What gates, and what only records

There are **two** checkpoints — the commit and the tag — and a suite answers differently at each, so
both columns are named (`automated-tests-§3`).

| Suite | Command | Gates the run and the commit? | Gates the tag? |
|---|---|---|---|
| `lint` | `luacheck .` | **yes** | **yes** |
| `tests` | `lua tests/run.lua` | **yes** | **yes** |
| `perf` | `lua tests/perf.lua` | no — recorded only | **yes** |
| `complexity` | `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` | no — recorded only | **yes** |

`perf` and `complexity` are **measured, recorded and diffed — they never fail a run and never block
a commit.** A threshold that fails a run teaches everyone to reach for `--no-verify`, after which the
gate protects nothing and the habit remains. They contribute `amber`, which is a signal rather than a
stop.

**The tag is a different checkpoint.** It is gated on all four suites at `pass` plus zero functions
above CCN 15 (`automated-tests-§3`, *The release gate*), evaluated by `/wow-addon:bump-version` from
the `manifest.json` the release run writes — never by the runner, whose exit code is unchanged. A
`skip` is **NOT EVALUATED** there rather than passed; the one narrow exception is `perf` skipped
because this addon ships no `tests/perf.lua`, which the release notes state out loud.

**A missing tool is a skip, not a failure**, and the skip is recorded with its reason — so a green
run that measured nothing cannot be mistaken for a green run that measured everything.

## What is here

- **`RESULTS.md`** — one row per run across all four suites, plus the current complexity watch list.
  **One file, overwritten in place**: the git history of that single path is the trend line.
- **`<YYYYMMDD-HHMMSS>/`** — one frozen bundle per run: `manifest.json` plus one file per suite.
  Bundles are **never edited** once written and **never pruned**.
  An **`ANALYSIS.md`** (the write-up) is **MUST for a release run and SHOULD otherwise**
  (`automated-tests-§5`), so a bundle without one is not automatically a gap. Of the three recorded
  runs, `20260804-182235` and `20260804-233338` carry one; `20260804-214445` does not, and its
  `manifest.json` records `"release": null`, so it is a skipped SHOULD rather than a missed MUST.
  Nothing in this repo has been recorded as a release run yet.

Offline perf records live in the bundle with the run that produced them — except that this addon
ships no `tests/perf.lua`, so every recorded run's `perf` suite is a **skip** and no bundle holds
one. **In-game** captures cannot be produced by a script — a human runs the `perf` verb in a live
client and exports the record — and they belong in a standing `../perf-runs/` store, which this repo
does not have yet. Neither gap is a passing suite: `RESULTS.md`'s Perf column reads `skip`, and it
means the record says nothing about runtime cost.
