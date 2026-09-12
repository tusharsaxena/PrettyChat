# 05 — Summary: PrettyChat re-vendor to LibKa0s v1.31.0, 2026-09-12

## Tag

**v1.30.0 to v1.31.0.** Both payloads were copied whole from the tag (`git archive v1.31.0`), and
the `CLAUDE.md` provenance line and the `docs/ARCHITECTURE.md` external-dependencies reference moved
in the same commit, `8a2fdf9`. No README provenance line existed to remove.

Per-file minors: `OptionsWidgets` **14 to 15** and `OptionsCompose` **3 to 4**. Everything else is
unchanged: `Core` 7, `Env` 1, `Pool` 3, `Item` 1, `Media` 3, `Widgets` 9, `DebugLog` 12, `Slash` 7,
`Options` 15, `OptionsScroll` 3, `Perf` 10, `PerfPanel` 5. The kit moved from revision **16 to 17**.
No file was removed upstream, so nothing was deleted from `libs/`.

## What reached the addon for free (class A)

- The flow engine's `path == nil` arm (OptionsWidgets 15). Every PrettyChat row has a path, so it
  renders exactly as before.
- The composers' `spec.bind` arm (OptionsCompose 4). `MasterControls` is path-keyed here and pinned
  byte-for-byte upstream. PrettyChat has no registry records to bind.
- Kit 17's AceEvent, AceTimer, `__fireTimers` and AceGUI layout surfaces. PrettyChat embeds only
  AceConsole, so they have nothing to replace.

## Adopted

- **B1 (`de344d3`):** `tests/wow_mock.lua` forwards `NewAddon`'s name and mixin list to the kit,
  retiring its own `GetAddon`, name stamp and `RegisterChatCommand` recorder. The `/pc` case now
  runs both commands through `AceConsole:__slash` (red before, green after). The `Print` override
  stays, for the reason in 02_CANDIDATES.md.
- **Upstream note:** PrettyChat now calls the kit's `NewAddon` with a name, so of the two callers
  that kit divergence 1 (no-name `NewAddon`) exists for, only WhatGroup is left.

## Declined

- **B2, drive the lifecycle through `AceAddon.frame`:** not now. Proposed as a `state:triaged`,
  `severity:low` issue, **not filed** (this run skips filing).

## Skipped or unreached

Nothing unreached. Filing and pushing were skipped, as instructed.

## Gates

| Gate | Command | Baseline | After the copy (`8a2fdf9`) | After B1 (`de344d3`) |
|---|---|---|---|---|
| Lint | `luacheck .` | 0 / 0 in 44 files | 0 / 0 in 44 files | 0 / 0 in 44 files |
| Tests | `lua tests/run.lua` | 333 / 0 / 0 | 333 / 0 / 0 | 333 / 0 / 0 |
| Vendor sync | `tests/test_vendor_sync.lua` | green | green, none skipped | green |
| EOL | `tests/_kit/test_eol.lua` | green | green | green |

No tool was missing.

## Addendum, 2026-09-12: the v1.31.0 tag was re-cut before release

This bundle was written against the first cut of the `v1.31.0` tag (commit `30db4ed`). Before anything
was pushed, a review of that release found defects in the kit-17 fakes, and LibKa0s re-cut the tag on the
fixed tree: **`v1.31.0` now points at `e7e1962`**. `44b2b38` ("Re-vendor the reviewed LibKa0s v1.31.0
(tag moved to e7e1962)") copied both payloads whole from the re-cut tag, and the vendor-sync cases pass
against it.

What the re-cut changed, relative to the tables above:

| File | First cut | Re-cut |
|---|---|---|
| `Perf.lua` | minor 10 (unchanged) | **minor 11**: `P.Save` traces the ring trim once past its cap (debug-logging-§8) |
| `OptionsWidgets.lua` | minor 15 | minor 15 (review fixes land inside the unreleased minor: `pairWith` keyed by `row.path or row.field`; a bound row's `disabledIf` reads through `row.get`) |
| `OptionsCompose.lua` | minor 4 | minor 4 (unchanged surface) |
| kit (`tests/_kit/`) | revision 17 | revision 17 (review fixes: repeating-timer delay no longer drifts; the nameless `NewAddon` path is exactly one table argument; the timer handle field is AceTimer's own `cancelled`, and `NewTimer` handles answer `IsCancelled()`; dispatch survives a handler error; `ADDON_LOADED` after login enables a load-on-demand addon; the AceEvent library object carries the message API) |

So three files in `LibKa0s/` move in this release, not two, and any "the ring trim is not traced" finding
recorded above is resolved upstream by Perf minor 11. The per-file minors line above therefore reads
`Perf` **10 to 11** for the release as vendored.

**PrettyChat declines Perf, so Perf minor 11 reaches nothing here.** The decline is the
`performance-§12` row in `docs/ARCHITECTURE.md` → `## Documented deviations`, and no file outside
`libs/` looks up `LibKa0s-Perf-1.0`. `Perf.lua` moves only because the folder is copied whole. The two
OptionsWidgets fixes touch bound (`path`-less) rows only, and every PrettyChat row has a path. Of the kit
fixes, the timer and event ones have nothing to replace (PrettyChat embeds only AceConsole), and the
nameless-`NewAddon` narrowing does not reach the harness, which passes a name since `de344d3`.

The gate was re-run on the re-cut payload:

| Gate | Command | At `44b2b38` |
|---|---|---|
| Lint | `luacheck .` | 0 / 0 in 44 files |
| Tests | `lua tests/run.lua` | 333 cases, 0 failed |
| Vendor sync | `tests/test_vendor_sync.lua` | green against `e7e1962`, none skipped |

`libs/` and `tests/_kit/` are byte-identical from `44b2b38` to the head of this branch, so the vendor-sync
row was read in the main checkout, where `../LibKa0s` sits beside the repo. A detached worktree of
`44b2b38` has no `../LibKa0s` beside it and reports those two cases as skipped rather than compared
(331 passed, 2 skipped).
