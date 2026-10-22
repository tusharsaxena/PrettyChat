Delta: LibKa0s v1.71.0 -> v1.75.0

# LibKa0s v1.71.0 -> v1.75.0: the delta (PrettyChat)

Item PC-RV of the 2026-10-22 "LibKa0s issues #45-#58" run: a mechanical re-vendor with no adoption
interview and no GitHub issue filed (the run's owner scope, M2 non-interactive). Copied from the
annotated tag `v1.75.0` (tag object `eae0ee5`, LibKa0s commit `265a89e`) by
`git -C ../LibKa0s archive v1.75.0 LibKa0s testkit tools | tar -x` into a scratch directory, then
`libs/LibKa0s/` and `tests/_kit/` replaced whole. The tag is **local only**
(`git -C ../LibKa0s ls-remote --tags origin v1.75.0` prints nothing); the payload is taken from the
tag, never the working tree. `tools/` was extracted only for `prune-icons.lua` and is not copied.

This file was written before the copy. The section *After the copy* at the end was added once the
copy and the prune had run.

## Step 0. Pre-flight (this addon)

The newest single-tag bundle is `2026-10-07-v1.71.0/`, whose line 1 reads
`Delta: LibKa0s v1.70.0 -> v1.71.0`. The provenance line before its re-vendor commit named v1.70.0,
so the base it states is right. No correction paragraph is owed.

## 3a. The base

```sh
grep -n '[Bb]undles' CLAUDE.md
# 42:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.71.0 (MIT).
c=$(git log -1 --format=%H -- libs/LibKa0s tests/_kit)
git show "$c:CLAUDE.md" | grep -oE 'Bundles \[LibKa0s\]\([^)]*\) v[0-9.]+'
# Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.71.0
git -C ../LibKa0s archive v1.71.0 LibKa0s testkit | tar -x -C <scratch>/claimed
diff -rq --strip-trailing-cr <scratch>/claimed/LibKa0s libs/LibKa0s \
  && diff -rq --strip-trailing-cr <scratch>/claimed/testkit tests/_kit && echo payload-matches
# payload-matches
```

The line and the payload agree: the base is **v1.71.0** (`cb274a4`), kit revision 38. PrettyChat
never vendored v1.72.0, v1.73.0 or v1.74.0, so the delta is v1.71.0 -> v1.75.0 and those tags need
no record of their own (3h below).

```sh
git -C ../LibKa0s log --oneline v1.71.0..v1.75.0 | wc -l
# 56
git -C ../LibKa0s diff --stat v1.71.0 v1.75.0 -- LibKa0s testkit | tail -1
# 5752 files changed, 8798 insertions(+), 121 deletions(-)   (v1.74.0's icon sets are most of it)
```

## 3b/3c. Per-file minors (the files that moved)

```sh
for f in $(git -C ../LibKa0s show v1.75.0:LibKa0s/LibKa0s.xml | grep -oE 'file="[^"]+\.lua"' | cut -d'"' -f2); do
  ... old: libs/LibKa0s/$f   new: v1.75.0:LibKa0s/$f   (printed only where they differ)
done
```

| File | Major | v1.71.0 | v1.75.0 |
|---|---|---|---|
| `Core.lua` | `LibKa0s-Core-1.0` | 10 | 11 |
| `Item.lua` | `LibKa0s-Item-1.0` | 2 | 3 |
| `Glow.lua` | `LibKa0s-Glow-1.0` (new major) | - | 1 |
| `Media.lua` | `LibKa0s-Media-1.0` | 4 | 5 |
| `MediaIcons.lua` | `LibKa0s-Media-1.0` (new file) | - | 1 |
| `Widgets.lua` | `LibKa0s-Widgets-1.0` | 12 | 13 |
| `DebugLog.lua` | `LibKa0s-DebugLog-1.0` | 19 | 20 |
| `DebugLogDiagnostics.lua` | `LibKa0s-DebugLog-1.0` | 2 | 3 |
| `Options.lua` | `LibKa0s-Options-1.0` | 28 | 29 |
| `OptionsIdList.lua` | `LibKa0s-Options-1.0` | 4 | 5 |
| `OptionsTabs.lua` | `LibKa0s-Options-1.0` | 8 | 9 |
| `OptionsDrawer.lua` | `LibKa0s-Options-1.0` (new file) | - | 1 |
| `Perf.lua` | `LibKa0s-Perf-1.0` | 14 | 15 |
| `PerfPanel.lua` | `LibKa0s-Perf-1.0` | 6 | 7 |
| `Sim.lua` | `LibKa0s-Sim-1.0` (new major) | - | 1 |
| `SimTimeline.lua` | `LibKa0s-Sim-1.0` (new file) | - | 1 |
| `SimPanel.lua` | `LibKa0s-Sim-1.0` (new file) | - | 1 |

No file is behind: no cross-major skew. There is no `WidgetsStepPanel.lua`: the step panel was
withdrawn before release (LK-11 outcome B) and its renderer is Sim-private inside `SimPanel.lua`,
so Widgets 13 carries `W.SearchBox` and `W.TestStrip` only. The majors go from fifteen to
seventeen (`Glow-1.0`, `Sim-1.0`):

```sh
grep -hoE '"LibKa0s-[A-Za-z]+-1\.0"' <scratch>/LibKa0s/*.lua | sort -u | wc -l   # 17 (v1.71.0: 15)
```

## 3d. Diffs

Before the copy the content diff is the whole delta above. After it: see *After the copy*.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
# core/MediaSetup.lua:42 Media, core/EnvSetup.lua:60 Env, core/DebugLogSetup.lua:69 DebugLog,
# core/LauncherSetup.lua:98 Launcher, core/LifecycleSetup.lua:67 Lifecycle, core/CoreSetup.lua:41 Core,
# settings/OptionsSetup.lua:17 Options, settings/Slash.lua:158 Slash, settings/Panel.lua:101 DebugLog,
# settings/Schema.lua:821 Schema, settings/Schema.lua:930 Slash
```

PrettyChat consumes nine majors: Core, Env, Media, DebugLog, Slash, Options, Launcher, Lifecycle
and Schema. Not consumed: Bus, Compat, Glow, Item, Perf, Pool, Sim and Widgets (Pool and Widgets
reach it only through the library's own internal lookups).

## 3f. Kit revision and the pairing rule

```sh
grep -n 'Kit.VERSION' <scratch>/testkit/framework.lua tests/_kit/framework.lua
# <scratch>/testkit/framework.lua:20:Kit.VERSION = 41
# tests/_kit/framework.lua:20:Kit.VERSION = 38
```

Kit 38 -> 41, copied in the same commit as the library (the pairing rule is satisfied by
construction, and kit 40's icon gate reads the `LibKa0s icons:` line this commit writes).

## 3g. Contract delta: Blockers

Majors read: those 3c moved, intersected with those 3e consumes (Core, Media, DebugLog, Options),
plus the kit.

1. **Options 29 / OptionsDrawer 1 (v1.73.0).** `O.Drawer` joins the live surface
   (`docs/api/Options/version-29.2.34.2.5.9.1.7.4.2.1-docs.md:11`). `tests/test_surface_parity.lua:140-141`
   (`the Options stub carries the whole live surface`) goes red until the degradation stub in
   `settings/OptionsSetup.lua` gains `Drawer`, placed after `NavRail` (`:139`) as an inert no-op:
   no page here draws a drawer.
2. **OptionsTabs 9 drops `O.__releaseChrome` (LibKa0s#45).** Same document, `:15` (Supersedes row).
   The mirror at `settings/OptionsSetup.lua:113` is dead and is deleted. `assertSurfaceParity`
   never reports extra stub keys, so this is not red either way; the sibling `__` mirrors stay,
   because their live members still exist.
3. **Kit 39: `M.__fireUnconditional` reaches method-name and function handlers**
   (`docs/api/testkit/version-39-docs.md:14`). PrettyChat's one call site is
   `tests/test_disabled.lua:248` (`disabled/6`), which fires at the watcher frame. PrettyChat
   registers through `Util.SafeRegisterEvents` (`core/CoreSetup.lua:114-127`,
   `modules/Override.lua:126`), not AceEvent method names, so the count stays 1. Confirmed by the
   gate after the copy.
4. **Kit 40: whole-catalog icon test.** `tests/test_mediasetup.lua:84-95` loops `Media.ICONS`
   (`:90`) and fails after the prune. Rewritten to the declaration, read through the kit's own
   parser (`VendorSync.iconDeclaration`, `docs/api/testkit/version-40-docs.md:104`).
5. **Kit 40: `info.tga` assertion.** `tests/test_libka0s.lua:543-547` asserts a file PrettyChat
   does not declare. The descriptor half (`:530-542`) stays; the file half becomes "no IdList is
   drawn here, so `info` is not declared and `info.tga` is absent".
6. **Kit 41 (#46, #47).** `Kit.__deviationRows` and `Kit.__declineFor` are gone
   (`docs/api/testkit/version-41-docs.md:14`); `grep -rn '__deviationRows\|__declineFor' tests`
   outside `_kit` finds nothing. A crashed or bounded lizard run is now a complexity `fail` in a
   separate `crashed` bucket (`version-41-docs.md:69`, `:88`): `docs/testing.md`'s `complexity` row
   says so.
7. **Kit suites new in 39-41.** None declared here unless `Kit.assertSuiteInventory` reports one
   after the copy.

```sh
grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit   # nothing
grep -rn '__releaseChrome' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit
# settings/OptionsSetup.lua:113:        __releaseChrome      = function() end,
```

No host-supplied member's call site moved: PrettyChat passes no `__Attach*` members.

## 3h. Tags vendored and never recorded

The newest bundle `2026-10-07-v1.71.0/` records the base, and v1.72.0 to v1.74.0 were never
vendored here. Nothing unrecorded: no span bundle.

## 3i. The icon declaration (decided by the run's item spec)

No line yet; the provenance line at `CLAUDE.md:42` is a standalone sentence, so no split is
needed. Decided: **`LibKa0s icons: clear, close, copy.`** Derivation, every draw site:

- **Library-drawn (tag's `docs/releasing.md:312-318`).** The DebugLog console's `close`, `copy`
  and `clear`: `core/DebugLogSetup.lua:190` passes `addonName = addonName` so the library draws
  them from this copy (comment `:183-189`). The console's Copy window close is the same `close`.
- **The host seam `NS.Icon`** (`core/MediaSetup.lua:73-76`): no caller in `core/`, `settings/` or
  `modules/`; only `tests/test_mediasetup.lua` reaches it (copy, clear, close).
- **`NS.MakeCloseButton`** (`core/CoreSetup.lua:162-163`): no caller today (comment `:158-161`);
  a caller would draw `close`, already declared.
- **`info` is not declared.** It is drawn only by an Options id list, and PrettyChat draws none
  (`grep -rn 'IdList(' core settings modules` finds only the degradation stub). No `W.TestStrip`,
  no `W.SearchBox`, no Sim panel.
- **No data tables naming catalog icons.** The logo (`core/LauncherSetup.lua:115`,
  `settings/Panel.lua:35`) is a host path, not a catalog entry.

Hand lists have drifted before (KickCD and WhatGroup `tests/test_mediasetup.lua`), and a pruned
icon still resolves to a path and draws blank, so the owner's in-client smoke (`RV-75` in
`docs/smoke-tests.md`) is the backstop.

## 3j. Tests that assume the whole icon folder

```sh
grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'
# tests/test_mediasetup.lua:75   (a membership lookup over Media.ICONS: survives the prune)
# tests/test_mediasetup.lua:88   (the whole-catalog loop: blocker 4)
# tests/test_mediasetup.lua:90
# tests/test_libka0s.lua:545     (info.tga: blocker 5)
# tests/test_libka0s.lua:546
```

## After the copy

```sh
cp -r <scratch>/LibKa0s/. libs/LibKa0s/ && cp -r <scratch>/testkit/. tests/_kit/
diff -r --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s    # before the prune: empty
diff -r --strip-trailing-cr <scratch>/testkit tests/_kit      # empty
# CLAUDE.md: provenance rolled to v1.75.0, `LibKa0s icons: clear, close, copy.` written under it
(cd .. && lua <scratch>/tools/prune-icons.lua PrettyChat)
# prune-icons: PrettyChat: 3 icon(s) declared; kept 4 file(s), removed 5836
```

Removed by set, from the tool's output: Open Iconic 221 (`removed libs/LibKa0s/media/icons/<n>.tga`),
Phosphor 1435 (1434 marks and `LICENSE-phosphor.txt`), Game-icons 4180 (4178 marks,
`LICENSE-game-icons.txt` and `AUTHORS.txt`). Kept: `clear.tga`, `close.tga`, `copy.tga` and
`LICENSE-open-iconic.txt`, about 7.6 KB; no `phosphor/` or `game-icons/` folder remains.

```sh
diff -r --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s | grep -vc '^Only in .*media/icons'   # 0
diff -r --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s | grep -c '^Only in .*media/icons'    # 223
diff -rq <scratch>/LibKa0s libs/LibKa0s | grep -vc 'Only in'                                     # 0 (bytes)
diff -rq <scratch>/testkit tests/_kit | wc -l                                                    # 0
```

The 223 `Only in <scratch>` lines are the 221 undeclared Open Iconic files and the two set folders:
the declaration working (3d), not a fork. No `Only in libs/LibKa0s` line: nothing removed upstream
survives here.

Blocker 3 (`disabled/6`) stayed green on the new kit with no change. Blocker 7: no kit suite was
reported undeclared, so `tests/run.lua` is unchanged.
