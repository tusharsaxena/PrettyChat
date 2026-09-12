# 05 — Summary: PrettyChat re-vendor, 2026-09-12

## Tag

**v1.29.0 to v1.30.0.** Both payloads were copied whole from the tag (`git archive v1.30.0`),
and the `CLAUDE.md` provenance line moved in the same commit, `d35aa85`.

Per-file minors, all unchanged from v1.29.0: `Core` 7, `Env` 1, `Pool` 3, `Item` 1, `Media` 3,
`Widgets` 9, `DebugLog` 12, `Slash` 7, `Options` 15 (`OptionsWidgets` 14, `OptionsCompose` 3,
`OptionsScroll` 3), `Perf` 10 (`PerfPanel` 5). The kit moved from revision **15 to 16**. The
library bytes are identical to the ones already vendored, so the whole delta is the test kit.

## What reached the addon for free (class A)

- `AceGUI:Release` / `widget:Release()` (#27). No caller here and no local shim to delete.
- AceEvent's event half on an `Embed` target (#29). PrettyChat embeds no AceEvent. Its combat
  watcher is a plain frame, and the `wow_mock` frame-stub `_events` recording it uses is a
  different contract that stays.
- The `the automated-test runner is recorded executable (100755)` case (#28). It passes on the
  default path, and the suite moves **328 to 329**. `docs/test-cases.md` was regenerated and the
  README `Tests` badge moved to 329/329 in the re-vendor commit (testing-§5).

## Adopted

- **B1 (#30):** `tests/wow_mock.lua` no longer stamps `object.Printf = noop` after the kit's
  `NewAddon`, so the kit's AceConsole-shaped `Printf` reaches the addon object. The orphaned
  `local function noop` went with it. The rest of the override stays: `GetAddon`, the recorded
  `RegisterChatCommand`, and `Print` into this environment's chat frame. The probe in
  04_EXECUTION_PLAN.md shows the change lands.

## Declined

**Nothing.** No issue was filed or proposed for this re-vendor.

## Skipped or unreached

Nothing. The run was non-interactive against owner answers given in advance (03_DECISIONS.md), and
it neither filed issues nor pushed, as instructed.

## Other live references moved with the bytes

`docs/ARCHITECTURE.md` → `## External dependencies` now names v1.30.0. `DEPENDENCIES.md`'s
citation of the vendored gate's `io.popen` moved from `vendor_sync.lua:184` to `:195`, where kit
revision 16 put it. `docs/testing.md`'s "as this is written" v1.27.0/v1.26.0 snapshot now reads as
the dated example it was. Frozen bundles were not touched.

## Gates

| Gate | Command | After the copy (`d35aa85`) | After B1 |
|---|---|---|---|
| Lint | `luacheck .` | 0 warnings / 0 errors in 44 files | 0 / 0 in 44 files |
| Tests | `lua tests/run.lua` | 329 passed, 0 failed, 0 skipped | 329 passed, 0 failed, 0 skipped |
| Vendor sync | `tests/test_vendor_sync.lua` | 3 of 3 green, none skipped | 3 of 3 green |
| EOL | `tests/_kit/test_eol.lua` | green after straggler repair | green after straggler repair |

Baseline before the run: 328 passed, 0 failed, 0 skipped; luacheck 0/0 in 44 files. No tool was
missing.
