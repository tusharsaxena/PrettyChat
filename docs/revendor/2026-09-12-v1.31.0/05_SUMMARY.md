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
