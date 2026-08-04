# Testing

Contributor-facing verification guide. (Player-facing docs live in the root [README](../README.md); this content was moved out of the README under the Ka0s Standard v2.1.0, which keeps the README player-only.)

## Headless harness

PrettyChat runs on the **shared LibKa0s test kit** (testing-§1), vendored whole to `tests/_kit/` and never edited there. The kit owns the case registry, the assertions, the runner, the `--list` renderer, the sandboxed source loader and the TOC reader; what stays in this repo is the instance factory, the mock extender and the suite list.

It runs under stock Lua 5.1 with no WoW client, loading the vendored library files and then the addon's own sources into a mock WoW environment, and exercises the compat shim, constants, string helpers, locale manifest, defaults data, schema, sample renderer, apply pipeline and override engine, migration runner, addon lifecycle, debug console, slash dispatcher, settings panel — and the four LibKa0s seams.

```sh
lua tests/run.lua          # run every suite (exits non-zero on failure)
lua tests/run.lua --list   # print the test-case inventory (runs nothing)
luacheck .                 # static analysis (config in .luacheckrc)
```

## How the harness works

```
tests/
  _kit/              -- VENDORED, never edited: framework.lua, loader.lua, mock_base.lua, README.md
  run.lua            -- the suite list, the assertion aliases, and Kit.run
  loader.lua         -- the instance factory: TOC-derived load list + per-call isolation
  wow_mock.lua       -- a thin EXTENDER over tests/_kit/mock_base.lua
  test_<module>.lua  -- one suite per module; each reads _G.PC_TEST
```

- `run.lua` builds the shared table with `Kit.expose` and hands the ordered suite list to `Kit.run`. `t.eq` / `t.truthy` / `t.falsy` / `t.nilv` are **aliases** onto `Kit.assertEqual` / `assertTrue` / `assertFalse` / `assertNil`, so the failure messages and the caller-line reporting are the kit's everywhere; `neq` is the one the kit does not carry and is a thin `Kit.fail` wrapper.
- `loader.lua` derives the addon's own file list from `PrettyChat.toc` with `Loader.tocFiles` (testing-§9) rather than restating it, lists every file of `LibKa0s.xml` explicitly in XML order, seeds every schema-registered Blizzard global with a recognizable `ORIG:<NAME>` value, and runs the AceAddon lifecycle. `ctx.loadAddon()` returns a **fresh, fully-booted, isolated instance** (`{ env, NS, addon }`); `ctx.loadAddon({ skip = { … } })` loads with files genuinely absent, which is how the degraded-install cases are driven rather than by hand-stubbing (testing-§8), and `{ mock = fn }` reshapes the environment before anything loads.

  **Why this file survives the kit adoption.** `tests/_kit/loader.lua` builds ONE environment whose `__newindex` writes through to the real `_G`. This addon's entire feature is rewriting `_G[GLOBALNAME]`, and half the suite asserts on what landed there — so each instance needs its own. `tests/wow_mock.lua` points `_G` back at the mock table and this file builds a fresh mock per call, which is what supplies the isolation the kit has no mode for. Chunks compile once and re-run per instance, because `loadfile` on the ~1.9 MB of generated `GlobalStrings/` chunks would otherwise dominate the run.
- `wow_mock.lua` is a **thin extender** (testing-§1): `local base = dofile("tests/_kit/mock_base.lua")`, then a builder that overwrites the fifteen keys this addon genuinely needs differently. Its own header documents each with the reason it cannot come from the base. The load-bearing ones:
  - **distinct `CreateFontString` / `CreateTexture` objects.** The base aliases them onto the frame itself — a divergence its own README documents as deliberate — and the debug console hangs three FontStrings off one title bar, so an aliased one would make `frame.debugToggle.text` read back the window *title*;
  - `Show()`/`Hide()` **fire** the OnShow/OnHide scripts and hooks; the base tracks visibility only, and every settings page builds its body on first show;
  - a **recording** `DEFAULT_CHAT_FRAME`; the base's stub frame answers `AddMessage` from its metatable and keeps nothing, which would silence every chat assertion in the suite;
  - `AceAddon:GetAddon`, which the base omits and three PrettyChat files call;
  - `SettingsPanel = nil`, so the private category-tree walk takes its guarded fallback rather than "succeeding" against a stub that answers every method;
  - `C_AddOns` / `GetAddOnMetadata`, deliberately absent from the base so a Compat shim's fallback branch stays drivable.

What the mocks deliberately do *not* model is layout: they answer "which widget, seeded from what, wired to which schema path", never where anything lands on screen. Rendering, fonts, skinning, taint and live chat stay in the [smoke-test suite](./smoke-tests.md).

## The gate

Both `lua tests/run.lua` and `luacheck .` must be green before any commit. Lint config is `.luacheckrc` (`std=lua51`; excludes `libs/`, `GlobalStrings/`, `tests/`, `docs/audits`, `docs/reviews`). The suites register named `test(name, fn)` cases; the `Tests` badge in the README badge row shows the pass/total.

**The `luacheck` figure is scoped, not repo-wide.** `libs/` is excluded — correctly; vendored code is not this addon's to lint — and so is `tests/`. Before quoting 0/0, confirm the four seam files are inside the set that was actually checked:

```sh
luacheck . --formatter plain | tail -1     # and read the file count it reports
```

A warning inside `core/CoreSetup.lua`, `core/DebugLogSetup.lua`, `settings/OptionsSetup.lua` or `settings/Slash.lua` is an adoption defect. A warning elsewhere is pre-existing host hygiene. Neither statement means anything if the lint never opened the file.

## The vendor gate — four diffs, and they answer two different questions

**Nothing else in this repo can see a stale vendored library.** `lua tests/run.lua` passes against a stale copy that still works, and the library's own suite passes against the library. So the sync is checked directly, from the repo root, with the sibling `../LibKa0s` checkout present:

```sh
diff -r --strip-trailing-cr ../LibKa0s/LibKa0s libs/LibKa0s    # content — MUST be empty
diff -r ../LibKa0s/LibKa0s libs/LibKa0s                        # bytes  — SHOULD be empty
diff -r --strip-trailing-cr ../LibKa0s/testkit tests/_kit      # content — MUST be empty
diff -r ../LibKa0s/testkit tests/_kit                          # bytes  — SHOULD be empty
```

Run **both** of each pair and read the difference between them:

- **content differs** → a real fork in `libs/` or `tests/_kit/`, which is the one state the vendoring discipline forbids. Fix it upstream in `../LibKa0s` and re-vendor whole (`cp -r ../LibKa0s/LibKa0s/. libs/LibKa0s/`); never edit the vendored copy.
- **content same, bytes differ** → **nothing has forked.** The two checkouts merely disagree about line endings. Every repo here pins `* text=auto eol=crlf` while git stores LF blobs, so a working tree holding either ending round-trips to the same blob and `git status` stays clean on both sides — the state is invisible and self-perpetuating. Renormalize whichever side drifted (`git add --renormalize .`); re-vendoring will **not** converge it, it just moves the wrong endings downstream.

`tests/test_harness.lua` runs the same comparison mechanically whenever the sibling checkout is present, on raw bytes with no normalization. It is the only gate that can go quiet — a missing sibling means it did not look — which is why the commands above stay written down here.

## Test-case inventory & badge sync (`testing-§5`)

The authoritative case count lives in the **generated** inventory [`test-cases.md`](./test-cases.md) — every case, grouped by suite, with per-suite and grand totals. It is produced by the runner's `--list` mode, never hand-edited:

```sh
lua tests/run.lua --list > docs/test-cases.md   # regenerate the inventory
# verify it's in sync (CR-agnostic, since docs are CRLF on disk):
diff --strip-trailing-cr <(lua tests/run.lua --list) docs/test-cases.md
```

Whenever the suite changes — a case added, removed, or renamed, or the pass count moves (i.e. whenever a failing test is resolved) — regenerate `docs/test-cases.md` and update the README `Tests` badge count **in the same change**, never as a follow-up.

## Automated test records — the consolidated run

All four out-of-game suites go through one vendored runner, and every run is recorded
(`automated-tests`):

```sh
tests/_kit/run-automated-tests.sh                            # all four, writes a bundle
tests/_kit/run-automated-tests.sh --suite complexity          # a subset
tests/_kit/run-automated-tests.sh --suite lint --suite tests --no-bundle   # the green gate; writes nothing
```

| Suite | Command | Gates? |
|---|---|---|
| `lint` | `luacheck .` | **yes** |
| `tests` | `lua tests/run.lua` | **yes** |
| `perf` | `lua tests/perf.lua` | no — recorded only |
| `complexity` | `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` | no — recorded only |

**`perf` and `complexity` never fail a run.** They are measured, recorded and diffed — a threshold
that fails a run teaches everyone to reach for `--no-verify`, after which the gate protects nothing
and the habit remains. They contribute `amber`, which is a signal rather than a stop. **A missing
tool is a skip recorded with its reason**, never a pass.

The runner is **vendored** from `LibKa0s`'s `testkit/`; never edit `tests/_kit/`. A kit fix goes
upstream and is re-vendored.

**At release, not at commit.** A full bundle is produced as part of every version bump, before the
tag, with an `ANALYSIS.md` write-up. Commits are gated on lint + tests only.

Results live in [`automated-tests/`](./automated-tests/): `RESULTS.md` is one row per run across all
four suites plus the current complexity watch list — **one file, overwritten in place**, so its git
history is the trend line — and each `<YYYYMMDD-HHMMSS>/` is a frozen bundle of that run's raw
output. Bundles are never edited and never pruned.

`docs/complexity.md` was this addon's standalone complexity report through standard v2.18.0; it is
**retired** — its raw output is each bundle's `complexity.txt` and its trend line is `RESULTS.md`.

## In-game validation

For behavior stock Lua can't cover (panel rendering, live chat overrides, positional `%n$s` formats), follow the manual [smoke-test suite](./smoke-tests.md) — it lists which invariant each test guards, so a failure can be tied back to a specific area of the addon.
