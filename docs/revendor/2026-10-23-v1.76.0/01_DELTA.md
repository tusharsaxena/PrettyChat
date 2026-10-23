Delta: LibKa0s v1.75.2 -> v1.76.0

# LibKa0s v1.75.2 -> v1.76.0: the delta (PrettyChat)

Item PC-RV of the 2026-10-23 "sim auto-run, QC preview selector, mode strips, MM/KCD simulators"
run (Ka0sAddonsCommonTasks `docs/2026-10-23-SIM_PREVIEW_MODE_STRIPS/`): a mechanical re-vendor with
no adoption interview and no GitHub issue filed (the item spec). Copied from the annotated tag
`v1.76.0` (tag object `546e284`, LibKa0s commit `9949368`) by
`git -C ../LibKa0s archive v1.76.0 LibKa0s testkit tools | tar -x` into a scratch directory, then
`libs/LibKa0s/` and `tests/_kit/` replaced whole. The tag is **local only**
(`git -C ../LibKa0s ls-remote --tags origin v1.76.0` prints nothing); the payload is taken from the
tag, never the working tree. `tools/` was extracted only for `prune-icons.lua` and is not copied.

This file was written before the copy. The section *After the copy* at the end was added once the
copy and the prune had run.

## Step 0. Pre-flight (this addon)

The newest single-tag bundle is `2026-10-22-v1.75.0/`, whose line 1 reads
`Delta: LibKa0s v1.71.0 -> v1.75.0`. The provenance line before its re-vendor commit (`6ef60f5`)
named v1.71.0, so the base it states is right. No correction paragraph is owed.

## 3a. The base

```sh
grep -n '[Bb]undles' CLAUDE.md
# 42:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.75.2 (MIT).
git -C ../LibKa0s archive v1.75.2 LibKa0s testkit | tar -x -C <scratch>/claimed
diff -rq --strip-trailing-cr <scratch>/claimed/LibKa0s libs/LibKa0s | grep -v 'Only in <scratch>/claimed/LibKa0s/media/icons'
#   (nothing: only the pruned icons differ)
diff -rq --strip-trailing-cr <scratch>/claimed/testkit tests/_kit && echo kit-match
# kit-match
```

The line and the payload agree: the base is **v1.75.2** (`154599c`), kit revision 41. v1.75.1 and
v1.75.2 were vendored here without bundles; 3h records them.

```sh
git -C ../LibKa0s log --oneline v1.75.2..v1.76.0 | wc -l
# 8
git -C ../LibKa0s diff --stat v1.75.2 v1.76.0 -- LibKa0s testkit
#  LibKa0s/SimPanel.lua    |  36 ++++++++------
#  LibKa0s/SimTimeline.lua | 122 +++++++++++++++++++++++++++++++++++++-----------
#  LibKa0s/Widgets.lua     |  43 ++++++++++++-----
#  3 files changed, 148 insertions(+), 53 deletions(-)
```

## 3b/3c. Per-file minors (the files that moved)

| File | Major | v1.75.2 | v1.76.0 |
|---|---|---|---|
| `SimTimeline.lua` | `LibKa0s-Sim-1.0` | 2 | 3 |
| `SimPanel.lua` | `LibKa0s-Sim-1.0` | 4 | 5 |
| `Widgets.lua` | `LibKa0s-Widgets-1.0` | 13 | 14 |

`Sim.lua` stays at minor 2 (Sim version key 2.3.5); the Widgets attach files (`WidgetsReorder` 1,
`WidgetsDragHandle` 4, `WidgetsLineChart` 3, `WidgetsAutocomplete` 2) do not move (Widgets key
14.1.4.3.2). No file is behind: no cross-major skew. Still seventeen majors across forty files.

## 3d. Diffs

Before the copy the content diff is the three files above. After it: see *After the copy*.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
# core/LifecycleSetup.lua:67 Lifecycle, core/EnvSetup.lua:60 Env, core/MediaSetup.lua:42 Media,
# core/DebugLogSetup.lua:69 DebugLog, core/CoreSetup.lua:41 Core, core/LauncherSetup.lua:98 Launcher,
# settings/OptionsSetup.lua:17 Options, settings/Schema.lua:821 Schema, settings/Schema.lua:930 Slash,
# settings/Slash.lua:158 Slash, settings/Panel.lua:101 DebugLog
```

PrettyChat consumes nine majors: Core, Env, Media, DebugLog, Slash, Options, Launcher, Lifecycle and
Schema. Neither major that moved (Sim, Widgets) is consumed. Inside the payload `DebugLog.lua`
resolves Widgets for the resize helper and the copy window, neither of which minor 14 touches.

## 3f. Kit revision and the pairing rule

```sh
grep -n 'Kit.VERSION =' <scratch>/testkit/framework.lua tests/_kit/framework.lua
# <scratch>/testkit/framework.lua:20:Kit.VERSION = 41
# tests/_kit/framework.lua:20:Kit.VERSION = 41
```

Kit 41 unchanged; the library and the kit are copied in one commit anyway.

## 3g. Contract delta: Blockers

Majors read: those 3c moved (Sim, Widgets), intersected with those 3e consumes: none. So no host
contract can move here.

- **Sim 2.3.5 (auto-run, Run all removed, `RUN_ALL` leaves `Sim.STRINGS`).** PrettyChat registers no
  simulator and no suite reads `Sim.STRINGS` (`grep -rnE 'RUN_ALL|Run all|LibKa0s-Sim' tests core
  settings modules` finds nothing). Not a blocker.
- **Widgets 14 (`W.TestStrip` `opts.kind`, `strip.kind`).** Additive; no member added
  (`docs/api/Widgets/version-14.1.4.3.2-docs.md`). PrettyChat draws no strip. Not a blocker.
- **Kit:** unchanged, so no new suite and no helper change.

Nothing in 3g.

## 3h. Tags vendored and never recorded

```sh
# the command's listing (AUDIT.md walk + rolled CLAUDE.md lines; recorded = bundle folder tags,
# with line 1 of 01_DELTA.md for the two untagged 2026-08-25 and 2026-09-12 folders)
grep -vxF -f recorded.txt vendored.txt
# v1.75.1
# v1.75.2
```

Both were carried by the 2026-10-23 simulator fix sweeps (`a708988`, `082ffca`). One consolidated
span bundle, `2026-10-23-v1.75.1-v1.75.2/`, is written beside this one.

## 3i. The icon declaration

`CLAUDE.md:43` reads `LibKa0s icons: clear, close, copy.`, the next non-blank line under the
provenance line (`:42`). Kept as it is: the tag's `docs/releasing.md` library-drawn table did not
move between v1.75.2 and v1.76.0 (`git -C ../LibKa0s diff v1.75.2 v1.76.0 -- docs/releasing.md`
adds no icon), and `W.TestStrip`'s mark is host art, which PrettyChat does not draw. Derivation in
`2026-10-22-v1.75.0/01_DELTA.md` 3i still holds. Hand lists have drifted before (KickCD and WhatGroup
`tests/test_mediasetup.lua`), and a pruned icon still resolves to a path and draws blank, so the
owner's in-client smoke is the backstop (`docs/smoke-tests.md` RV-75).

## 3j. Tests that assume the whole icon folder

```sh
grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'
# tests/test_mediasetup.lua:75, :101 and tests/test_libka0s.lua:569 - all already narrowed to the
# declaration by the v1.75.0 re-vendor.
```

Nothing to fix.

## After the copy

```sh
cp -r <scratch>/LibKa0s/. libs/LibKa0s/ && cp -r <scratch>/testkit/. tests/_kit/
diff -r --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s | wc -l    # before the prune: 0
diff -r --strip-trailing-cr <scratch>/testkit tests/_kit | wc -l      # 0
# CLAUDE.md: provenance rolled to v1.76.0; `LibKa0s icons: clear, close, copy.` kept under it
(cd .. && lua <scratch>/tools/prune-icons.lua PrettyChat)
# prune-icons: PrettyChat: 3 icon(s) declared; kept 4 file(s), removed 5836
diff -r --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s | grep -vc '^Only in .*media/icons'   # 0
diff -r --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s | grep -c '^Only in .*media/icons'    # 223
diff -rq <scratch>/testkit tests/_kit | wc -l                                                    # 0
```

The 223 `Only in <scratch>` lines are the 221 undeclared Open Iconic files and the two set folders,
the same as at v1.75.0. No `Only in libs/LibKa0s` line: nothing removed upstream survives here. In
git, only `SimPanel.lua`, `SimTimeline.lua` and `Widgets.lua` change under `libs/LibKa0s/`; the
prune re-removed the icons the copy had brought back, so `media/icons/` is unchanged.
