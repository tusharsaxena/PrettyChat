# Testing

Contributor-facing verification guide. (Player-facing docs live in the root [README](../README.md); this content was moved out of the README under the Ka0s Standard v2.1.0, which keeps the README player-only.)

## Headless harness

PrettyChat ships a headless test harness that runs under stock Lua 5.1 with no WoW client — it loads the addon sources into a mock WoW environment and exercises the compat shim, constants, string helpers, locale manifest, defaults data, schema, sample renderer, apply pipeline and override engine, migration runner, addon lifecycle, debug console, slash dispatcher, and settings panel.

```sh
lua tests/run.lua          # run every suite (exits non-zero on failure)
lua tests/run.lua --list   # print the test-case inventory (runs nothing)
luacheck .                 # static analysis (config in .luacheckrc)
```

## How the harness works

```
tests/
  run.lua            -- the runner + micro-framework; also the --list inventory mode
  loader.lua         -- loads each source in TOC order and runs OnInitialize/OnEnable
  wow_mock.lua       -- the WoW API mock builder (a fresh env per instance)
  test_<module>.lua  -- one suite per module
```

- `run.lua` registers every suite, then runs each case under `pcall`; a case passes when its body neither errors nor trips an assertion.
- `loader.lua` reproduces the `local addonName, NS = ...` header, loads the sources in TOC order, seeds every schema-registered Blizzard global with a recognisable `ORIG:<NAME>` value, and runs the AceAddon lifecycle. `ctx.loadAddon()` therefore returns a **fresh, fully-booted addon instance** (`{ env, NS, addon }`) — suites never share state.
- `wow_mock.lua` stubs the Blizzard surface, LibStub/Ace3, the Settings API and AceGUI. Four pieces of fidelity are load-bearing and must not be simplified away:
  - the AceAddon mock stamps AceConsole's colliding `:Print` mixin, so the tests exercise the real printer-reclaim path;
  - frames resolve unknown **PascalCase** keys to a self-returning no-op but unknown lowercase keys to `nil` — addon-owned fields (`panel.defaultsBtn`, `frame.log`) are lowercase, and a blanket catch-all would silently invert every `if not …` guard;
  - `Show()`/`Hide()` fire the OnShow/OnHide scripts and hooks, which is what makes the panel's lazy first-OnShow body build testable;
  - the AceGUI mock records widget type, label, value, disabled state, callbacks and child order, so a suite can walk the panel tree and fire a widget callback (`widget:Fire("OnValueChanged", v)`).

What the mocks deliberately do *not* model is layout: they answer "which widget, seeded from what, wired to which schema path", never where anything lands on screen. Rendering, fonts, skinning, taint and live chat stay in the [smoke-test suite](./smoke-tests.md).

## The gate

Both `lua tests/run.lua` and `luacheck .` must be green before any commit. The suites register named `test(name, fn)` cases; the `Tests` badge in the README badge row shows the pass/total.

## Test-case inventory & badge sync (`testing-§5`)

The authoritative case count lives in the **generated** inventory [`test-cases.md`](./test-cases.md) — every case, grouped by suite, with per-suite and grand totals. It is produced by the runner's `--list` mode, never hand-edited:

```sh
lua tests/run.lua --list > docs/test-cases.md   # regenerate the inventory
# verify it's in sync (CR-agnostic, since docs are CRLF on disk):
diff --strip-trailing-cr <(lua tests/run.lua --list) docs/test-cases.md
```

Whenever the suite changes — a case added, removed, or renamed, or the pass count moves (i.e. whenever a failing test is resolved) — regenerate `docs/test-cases.md` and update the README `Tests` badge count **in the same change**, never as a follow-up.

## In-game validation

For behaviour stock Lua can't cover (panel rendering, live chat overrides, positional `%n$s` formats), follow the manual [smoke-test suite](./smoke-tests.md) — it lists which invariant each test guards, so a failure can be tied back to a specific area of the addon.
