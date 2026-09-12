# 01 — Delta: PrettyChat vs LibKa0s v1.31.0

Run date: 2026-09-12, wave B2 of the 2026-09-12 triage, on branch `fix/2026-09-12-triage` (which
already carries #15 as `61ff810`). A second bundle on the same date as `docs/revendor/2026-09-12/`
(the v1.30.0 re-vendor), so this folder carries the tag in its name. That bundle is frozen and was
not touched.

Library checkout: `../LibKa0s`, tag `v1.31.0` on `30db4ed` ("The v1.31.0 release record"). The
payload was extracted from the tag, never from the working tree:

```sh
git -C ../LibKa0s tag --points-at 30db4ed        # v1.31.0
git -C ../LibKa0s archive v1.31.0 LibKa0s testkit | tar -x -C <scratch>/
```

## 3a. Claimed version

```sh
grep -n '[Bb]undles' PrettyChat/CLAUDE.md
```

`CLAUDE.md:34`: "Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.30.0 (MIT)."
`README.md` carries no provenance line (the same grep over it finds none).

## 3b. Actual version: the vendored minors

```sh
grep -hoE 'local (MAJOR, )?(MINOR|WIDGETS_MINOR|SCROLL_MINOR|PANEL_MINOR) *= *("[^"]+", *)?[0-9]+' PrettyChat/libs/LibKa0s/*.lua
grep -nE '^local [A-Z_]*MINOR' PrettyChat/libs/LibKa0s/OptionsCompose.lua   # COMPOSE_MINOR
```

The claim and the bytes agree: every vendored minor is the one v1.30.0 shipped.

## 3c. Per-file minor delta

File list read from the tag's `LibKa0s/LibKa0s.xml` (14 files).

| File | Constant | Vendored (v1.30.0) | v1.31.0 | Delta |
|---|---|---|---|---|
| `Core.lua` | `MINOR` | 7 | 7 | none |
| `Env.lua` | `MINOR` | 1 | 1 | none |
| `Pool.lua` | `MINOR` | 3 | 3 | none |
| `Item.lua` | `MINOR` | 1 | 1 | none |
| `Media.lua` | `MINOR` | 3 | 3 | none |
| `Widgets.lua` | `MINOR` | 9 | 9 | none |
| `DebugLog.lua` | `MINOR` | 12 | 12 | none |
| `Slash.lua` | `MINOR` | 7 | 7 | none |
| `Options.lua` | `MINOR` | 15 | 15 | none |
| `OptionsWidgets.lua` | `WIDGETS_MINOR` | 14 | **15** | +1 |
| `OptionsCompose.lua` | `COMPOSE_MINOR` | 3 | **4** | +1 |
| `OptionsScroll.lua` | `SCROLL_MINOR` | 3 | 3 | none |
| `Perf.lua` | `MINOR` | 10 | 10 | none |
| `PerfPanel.lua` | `PANEL_MINOR` | 5 | 5 | none |

**No cross-major skew.** The vendored copy is behind the tag only on the two files v1.31.0 moves,
and the whole folder is copied in one step.

## 3d. Both diffs, both directions (before the copy)

```sh
diff -rq --strip-trailing-cr <scratch>/LibKa0s PrettyChat/libs/LibKa0s   # 2 files differ
diff -rq                     <scratch>/LibKa0s PrettyChat/libs/LibKa0s   # the same 2
diff -rq --strip-trailing-cr <scratch>/testkit PrettyChat/tests/_kit     # 3 files differ
diff -rq                     <scratch>/testkit PrettyChat/tests/_kit     # the same 3
```

- Library payload: **content dirty** on `OptionsCompose.lua` and `OptionsWidgets.lua`, the two
  files v1.31.0 moves. Nothing else differs, in content or in bytes.
- Test kit: **content dirty** on `README.md`, `framework.lua` (`Kit.VERSION` 16 to 17) and
  `mock_base.lua` (the revision-17 Ace surfaces).
- No `Only in` line on either side, so no file removed upstream survives here.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' PrettyChat --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
```

- `core/CoreSetup.lua:41`: Core
- `core/DebugLogSetup.lua:39`: DebugLog
- `core/EnvSetup.lua:59`: Env
- `core/MediaSetup.lua:42`: Media
- `settings/OptionsSetup.lua:17`: Options
- `settings/Schema.lua:457`: Slash (it was `:405` at v1.30.0; #15 moved the line, not the lookup)
- `settings/Slash.lua:74`: Slash

Majors in the payload with no lookup here: `Item`, `Pool`, `Widgets`, `Perf`. `Perf` is declined
by the `performance-§12` row in `docs/ARCHITECTURE.md` → `## Documented deviations`. None of the
four moved in v1.31.0, so none is raised as a whole-module candidate.

## 3f. Kit revision and the pairing rule

```sh
grep -n 'Kit.VERSION' <scratch>/testkit/framework.lua PrettyChat/tests/_kit/framework.lua
```

The tag reads `Kit.VERSION = 17`; the vendored copy reads `16`. A consumer on LibKa0s v1.9.0 or
newer must take kit revision 11 or later in the same commit as the library, because
`vendor_sync.lua` before revision 11 listed one directory level and normalized line endings on
everything, so it read `media` as a file. Both payloads are copied whole in one commit, so the rule
holds by construction. That rule is why the two payloads move together.

## Baseline before the copy

```sh
lua tests/run.lua    # 333 passed, 0 failed, 0 skipped, 333 total
luacheck .           # 0 warnings / 0 errors in 44 files
```

`.luacheckrc` excludes `libs/` and `tests/_kit/` only, so every seam file and `tests/wow_mock.lua`
are in the checked set.

## Verdict

The delta is not empty: the tag moves v1.30.0 to v1.31.0, two library files move (Options'
composer and flow engine), and the kit moves from revision 16 to 17. The copy goes ahead.

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
recorded above is resolved upstream by Perf minor 11.

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
