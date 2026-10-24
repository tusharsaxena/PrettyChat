Delta: LibKa0s v1.76.0 -> v1.77.0

# LibKa0s v1.76.0 -> v1.77.0: the delta (PrettyChat)

Item PC-RV of the 2026-10-24 "keybindings (015), settings layout (020), frame strata (030)" run
(Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`): a re-vendor with no adoption
interview and no GitHub issue filed (the item spec). Copied from the annotated tag `v1.77.0` (tag
object `7380d36`, LibKa0s commit `78240f7`) by
`git -C ../LibKa0s archive v1.77.0 LibKa0s testkit tools | tar -x` into a scratch directory, then
`libs/LibKa0s/` and `tests/_kit/` replaced whole. The tag is **local only**
(`git -C ../LibKa0s ls-remote --tags origin v1.77.0` prints nothing); the payload is taken from the
tag, never the working tree. `tools/` was extracted only for `prune-icons.lua` and is not copied.

This file was written before the copy. The section *After the copy* at the end was added once the
copy and the prune had run.

## Step 0. Pre-flight (this addon)

The newest single-tag bundle is `2026-10-23-v1.76.0/`, whose line 1 reads
`Delta: LibKa0s v1.75.2 -> v1.76.0`. The provenance line before its re-vendor commit (`83f4c63`)
named v1.75.2, so the base it states is right. No correction paragraph is owed.

## 3a. The base

```sh
grep -n '[Bb]undles' CLAUDE.md
# 42:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.76.0 (MIT).
git -C ../LibKa0s archive v1.76.0 LibKa0s testkit | tar -x -C <scratch>/claimed
diff -rq --strip-trailing-cr <scratch>/claimed/LibKa0s libs/LibKa0s | grep -v 'Only in <scratch>/claimed/LibKa0s/media/icons'
#   (nothing: only the pruned icons differ)
diff -rq --strip-trailing-cr <scratch>/claimed/testkit tests/_kit && echo kit-match
# kit-match
```

The line and the payload agree: the base is **v1.76.0**, kit revision 41. The tag `v1.76.0` now
names LibKa0s commit `e692491` (LK-92, a README-only move after PC-RV2's `7e81ff7`; it is pushed:
`git -C ../LibKa0s ls-remote --tags origin v1.76.0` prints `600303b`).
`git -C ../LibKa0s diff --stat 7e81ff7 e692491 -- LibKa0s testkit` is empty, so the payload this
addon carries is the pushed tag's.

```sh
git -C ../LibKa0s log --oneline v1.76.0..v1.77.0 | wc -l
# 15
git -C ../LibKa0s diff --stat v1.76.0 v1.77.0 -- LibKa0s testkit
#  LibKa0s/Core.lua                |  28 +-
#  LibKa0s/DebugLog.lua            |  13 +-
#  LibKa0s/LibKa0s.xml             |   1 +
#  LibKa0s/Options.lua             |  28 +-
#  LibKa0s/OptionsCombat.lua       |  20 +-
#  LibKa0s/OptionsCompose.lua      |  66 +++-
#  LibKa0s/OptionsIds.lua          |  18 +-
#  LibKa0s/OptionsKeybinds.lua     | 819 ++++++++++++++++++++++++++++++++++++++++
#  LibKa0s/PerfPanel.lua           |   9 +-
#  LibKa0s/SimPanel.lua            |   9 +-
#  LibKa0s/Widgets.lua             |   8 +-
#  LibKa0s/WidgetsAutocomplete.lua |   6 +-
#  LibKa0s/WidgetsDragHandle.lua   |  62 ++-
#  testkit/README.md               |   5 +-
#  testkit/bindings_xml.lua        | 230 +++++++++++
#  testkit/framework.lua           |   7 +-
#  testkit/mock_bindings.lua       | 230 +++++++++++
#  testkit/mock_layers.lua         | 147 ++++++++
#  18 files changed, 1672 insertions(+), 34 deletions(-)
```

## 3b/3c. Per-file minors (the files that moved)

Step 3c's loop over the tag's `LibKa0s/LibKa0s.xml`, rows whose constant differs:

| File | Major | v1.76.0 | v1.77.0 |
|---|---|---|---|
| `Core.lua` | `LibKa0s-Core-1.0` | 11 | 12 |
| `Widgets.lua` | `LibKa0s-Widgets-1.0` | 14 | 15 |
| `WidgetsDragHandle.lua` | `LibKa0s-Widgets-1.0` (`DRAG_MINOR`) | 4 | 5 |
| `WidgetsAutocomplete.lua` | `LibKa0s-Widgets-1.0` (`AUTOCOMPLETE_MINOR`) | 2 | 3 |
| `DebugLog.lua` | `LibKa0s-DebugLog-1.0` | 20 | 21 |
| `Options.lua` | `LibKa0s-Options-1.0` | 29 | 30 |
| `OptionsIds.lua` | `LibKa0s-Options-1.0` (`IDS_MINOR`) | 2 | 3 |
| `OptionsCombat.lua` | `LibKa0s-Options-1.0` (`COMBAT_MINOR`) | 1 | 2 |
| `OptionsCompose.lua` | `LibKa0s-Options-1.0` (`COMPOSE_MINOR`) | 7 | 8 |
| `OptionsKeybinds.lua` | `LibKa0s-Options-1.0` (`KEYBINDS_MINOR`) | (new) | 3 |
| `PerfPanel.lua` | `LibKa0s-Perf-1.0` (`PANEL_MINOR`) | 8 | 9 |
| `SimPanel.lua` | `LibKa0s-Sim-1.0` (`SIM_PANEL_MINOR`) | 5 | 6 |

Version keys at the tag: Core 12, DebugLog 21.3.1, Perf 15.1.1.9, Sim 2.3.6, Widgets 15.1.5.3.3,
Options 30.2.34.3.5.9.2.8.4.2.1.3. `OptionsKeybinds.lua` is new (the twelfth Options file): now
seventeen majors across forty-one files. No file is behind: no cross-major skew.

## 3d. Diffs

Before the copy the content diff is the files above. After it: see *After the copy*.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
# core/EnvSetup.lua:60 Env, core/LifecycleSetup.lua:67 Lifecycle, core/CoreSetup.lua:41 Core,
# core/MediaSetup.lua:42 Media, core/DebugLogSetup.lua:69 DebugLog, core/LauncherSetup.lua:98 Launcher,
# settings/OptionsSetup.lua:17 Options, settings/Slash.lua:158 Slash, settings/Panel.lua:101 DebugLog,
# settings/Schema.lua:821 Schema, settings/Schema.lua:930 Slash
```

The same nine majors as at v1.76.0. Of those, Core, DebugLog and Options moved. Perf, Sim and Widgets
moved too and are not looked up here (DebugLog resolves Widgets inside the payload for its resize
helper and copy window; minor 15 only clamps the dropdown menu).

## 3f. Kit revision and the pairing rule

```sh
grep -n 'Kit.VERSION =' <scratch>/testkit/framework.lua tests/_kit/framework.lua
# <scratch>/testkit/framework.lua:20:Kit.VERSION = 42
# tests/_kit/framework.lua:20:Kit.VERSION = 41
```

Kit 41 -> 42: `mock_bindings.lua` and `mock_layers.lua` (both opt-in) and `bindings_xml.lua`
(`Kit.assertBindingsXml`, `Kit.keybindThroughTab`, published by `Kit.expose`, called only by a suite
that asks). The library and the kit move in one commit, as the pairing rule requires.

## 3g. Contract delta: Blockers

Majors read: those 3c moved, intersected with those 3e consumes: Core, DebugLog, Options.

- **Options 30 (OptionsCompose 8, OptionsKeybinds 1-3): a blocker.** The tag's
  `docs/api/Options/version-30.2.34.3.5.9.2.8.4.2.1.3-docs.md` (around line 2788, *Compatibility*)
  and `CHANGELOG.md`'s v1.77.0 *What a consumer owes*: every Options degradation stub gains
  `StrataTooltip`, `KeybindingsTab`, `KeybindRows` and `KEYBINDS_UNCHANGED`, because
  `Kit.assertSurfaceParity` compares the stub against the live instance.
  `tests/test_surface_parity.lua` ("the Options stub carries the whole live surface") pins
  `settings/OptionsSetup.lua`'s stub that way, so the copy turns it red. Fixed in the re-vendor commit:
  - `KeybindingsTab`, `KeybindRows` and `StrataTooltip` join the stub as inert no-ops, the same
    treatment `NavRail` and `Drawer` got: nothing here calls them (PrettyChat has no key binding
    and no strata row), and each is a render-time member.
  - `KEYBINDS_UNCHANGED` joins the parity case's live-only list, beside `CLASS_COLOR_NOTE` and
    `VISIBILITY_VALUES`, for the reason those sit there: it is the library's English, and a stub
    copy of it is the copy that goes stale. PrettyChat's General defaults tooltip does not read it
    (no key binding to leave unchanged).
- **Core 12 (`Core.RaiseStaticPopups`) and DebugLog 21 (the console is toplevel and re-raises shown
  popups):** additive. The Core stub test compares against `coreSurface(...)`; the new member is a
  library helper the DebugLog console calls, not a host seam. To confirm after the copy.
- **`__Attach*` sites:** `grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs
  --exclude-dir=_kit` finds none. No host-supplied member moved.

## 3h. Tags vendored and never recorded

```sh
grep -vxF -f recorded.txt vendored.txt     # the command's listing
#   (nothing)
```

v1.75.1 and v1.75.2 are recorded by `2026-10-23-v1.75.1-v1.75.2/`, v1.76.0 by its own bundle. No
span bundle is owed.

## 3i. The icon declaration

`CLAUDE.md:43` reads `LibKa0s icons: clear, close, copy.`, the next non-blank line under the
provenance line (`:42`). Kept as it is: the tag's `docs/releasing.md` library-drawn table did not
move between v1.76.0 and v1.77.0 (`git -C ../LibKa0s diff v1.76.0 v1.77.0 -- docs/releasing.md`
adds no icon name), and nothing in this range draws a new catalog icon on a surface PrettyChat wires.
Derivation in `2026-10-22-v1.75.0/01_DELTA.md` 3i still holds. Hand lists have drifted before
(KickCD and WhatGroup `tests/test_mediasetup.lua`), and a pruned icon still resolves to a path and
draws blank, so the owner's in-client smoke is the backstop.

## 3j. Tests that assume the whole icon folder

```sh
grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'
# tests/test_mediasetup.lua:75, :101 and tests/test_libka0s.lua:569 - already narrowed to the
# declaration by the v1.75.0 re-vendor.
```

Nothing to fix. `__releaseChrome` mirrors: none
(`grep -rn '__releaseChrome' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit` is empty).

## After the copy

```sh
cp -r <scratch>/LibKa0s/. libs/LibKa0s/ && cp -r <scratch>/testkit/. tests/_kit/
diff -r --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s | wc -l    # before the prune: 0
diff -r --strip-trailing-cr <scratch>/testkit tests/_kit | wc -l      # 0
diff -rq <scratch>/LibKa0s libs/LibKa0s | wc -l; diff -rq <scratch>/testkit tests/_kit | wc -l   # 0 0 (bytes)
# CLAUDE.md: provenance rolled to v1.77.0; `LibKa0s icons: clear, close, copy.` kept under it
(cd .. && lua <scratch>/tools/prune-icons.lua PrettyChat)
# prune-icons: PrettyChat: 3 icon(s) declared; kept 4 file(s), removed 5836
diff -r --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s | grep -vc '^Only in .*media/icons'   # 0
diff -r --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s | grep -c '^Only in .*media/icons'    # 223
diff -rq <scratch>/testkit tests/_kit | wc -l                                                    # 0
```

The 223 `Only in <scratch>` lines are the undeclared Open Iconic files and the two set folders, the
same as at v1.76.0. No `Only in libs/LibKa0s` line: nothing removed upstream survives here. In git,
twelve files change under `libs/LibKa0s/` and `OptionsKeybinds.lua` is added; under `tests/_kit/`,
`README.md` and `framework.lua` change and `bindings_xml.lua`, `mock_bindings.lua` and
`mock_layers.lua` are added. `media/icons/` is unchanged.

The gate on the bare copy, before the stub fix: `lua tests/run.lua` 573 passed, **1 failed**, 1
skipped. The one red is the 3g blocker, as predicted:

```
FAIL  the Options stub carries the whole live surface
      tests/_kit/asserts.lua:330: LibKa0s-Options-1.0: the degraded stub diverges from the live
      surface in 4 place(s) — KEYBINDS_UNCHANGED is missing (live: string); KeybindRows is missing
      (live: function); KeybindingsTab is missing (live: function); StrataTooltip is missing
      (live: function)
```

The Core and DebugLog stub cases stay green (Core 12's `RaiseStaticPopups` is outside the
`coreSurface` the Core case compares; DebugLog 21 adds no public member). With the fix in
`settings/OptionsSetup.lua` and `tests/test_surface_parity.lua` (3g): 574 passed, 0 failed, 1 skipped.
