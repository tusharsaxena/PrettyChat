Delta: LibKa0s v1.94.0 -> v1.105.0

Recorded for the re-vendor commit. Payload taken from the tag, never the sibling tree: `git -C ../LibKa0s archive v1.105.0 LibKa0s testkit tools` (tag 43ea2bd, commit 79b1d9c; a local annotated tag, not yet on origin, which this run expects). Run under the LibKa0s #75+ run (Ka0sAddonsCommonTasks `docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/`), item RV-PC: the copy and bundle half of `/dev-copilot:wow-revendor-libka0s` only. The adoption interview and its issue filing are skipped by that run's design (section 5); the candidates are listed in `02_CANDIDATES.md` as owed in its phase [3].

## Step 0 pre-flight
For this addon: newest single-tag bundle `docs/revendor/2026-11-07-v1.93.0`, base v1.92.0, vendored-before v1.92.0@5278466: `ok`. No base correction is owed.

## 3a Base
- `grep -n '[Bb]undles' CLAUDE.md` -> `45:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.94.0 (MIT).` before the roll.
- `git log -1 --format=%H -- libs/LibKa0s tests/_kit` = 04d48ba (W2-PC-01, the Retail + Forever port); its CLAUDE.md names v1.94.0. They agree.
- Payload before the copy equalled the library at v1.94.0: `diff -rq` of a v1.94.0 extract against `libs/LibKa0s` (bar the undeclared icons) and against `tests/_kit` printed nothing (payload-matches).
- Range: `git -C ../LibKa0s log --oneline v1.94.0..v1.105.0` is 114 commits, tags v1.95.0 to v1.105.0.

## 3b/3c Per-file minors that moved (old = this addon, new = v1.105.0)
From the loop over the tag's `LibKa0s.xml` (`grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR ...'`):
```
Core.lua                     old: 17    new: 18
Tooltip.lua                  old: none  new: 1
Role.lua                     old: none  new: 1
Callout.lua                  old: none  new: 4
CalloutSettings.lua          old: none  new: 5
WaypointArrow.lua            old: none  new: 2
WaypointArrowSettings.lua    old: none  new: 2
Charts.lua                   old: 1     new: 2
Media.lua                    old: 12    new: 13
SkinDefs.lua                 old: 27    new: 28
SkinDefsOthers.lua           old: 8     new: 10
Widgets.lua                  old: 26    new: 27
WidgetsDropdown.lua          old: 1     new: 2
WidgetsReorder.lua           old: 6     new: 7
WidgetsDragHandle.lua        old: 13    new: 14
WidgetsDragHandleTip.lua     old: none  new: 1
WidgetsCopyWindow.lua        old: 5     new: 6
WidgetsHeader.lua            old: none  new: 1
WidgetsBar.lua               old: none  new: 1
DebugLog.lua                 old: 22    new: 23
DebugLogDiagnostics.lua      old: 7     new: 11
DebugLogWindow.lua           old: 4     new: 5
Launcher.lua                 old: 9     new: 11
OptionsWidgets.lua           old: 45    new: 46
OptionsNav.lua               old: 6     new: 7
OptionsSkinPicker.lua        old: 11    new: 12
OptionsSkinPickerQueue.lua   old: none  new: 1
IconBrowserWindow.lua        old: 1     new: 2
IconBrowser.lua              old: 1     new: 2
PerfPanel.lua                old: 13    new: 14
Sim.lua                      old: 2     new: 3
SimPanel.lua                 old: 10    new: 11
SimPanelRender.lua           old: 3     new: 4
```
Ten new files. Every other file matched v1.94.0 before the copy, and the claimed and actual minors agree, so there is no cross-major skew.

## 3d Diffs
Before the copy, `diff -rq --strip-trailing-cr` against the v1.105.0 extract showed the files above (ten only in the tag), `LibKa0s.xml`, `media/fonts/FONTS.md`, the two new faces (Bebas Neue, Russo One, with their OFL texts), and the new `media/sounds/` and `media/waypoint/` folders. In the kit: `README.md`, `client_globals.lua`, `framework.lua`, `glyphs.lua`, `mock_ace.lua`, `mock_events.lua`, `vendor_sync.lua`, and the new `mock_screen.lua`. No `Only in libs/LibKa0s` line: nothing was removed upstream, so nothing is deleted by hand.

After the copy and before the prune, both diffs (content and bytes) of both payloads were empty. After the prune the only difference is the undeclared icons and the sounds (`Only in <extract>/...`), and `tests/test_vendor_sync.lua` is green.

## 3e Consumption map
`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua'`, outside `libs/` and `tests/`:
```
core/CoreSetup.lua:41       LibKa0s-Core-1.0
core/DebugLogSetup.lua:69   LibKa0s-DebugLog-1.0
core/EnvSetup.lua:60        LibKa0s-Env-1.0
core/LauncherSetup.lua:98   LibKa0s-Launcher-1.0
core/LifecycleSetup.lua:68  LibKa0s-Lifecycle-1.0
core/MediaSetup.lua:42      LibKa0s-Media-1.0
core/SkinSetup.lua:79       LibKa0s-Skin-1.0
core/SkinSetup.lua:288      LibKa0s-DebugLog-1.0
settings/OptionsSetup.lua:17 LibKa0s-Options-1.0
settings/Panel.lua:101      LibKa0s-DebugLog-1.0
settings/Schema.lua:611     LibKa0s-Schema-1.0
settings/Schema.lua:720     LibKa0s-Slash-1.0
settings/Slash.lua:163      LibKa0s-Slash-1.0
```
Majors in the payload with no lookup here: Bus, Callout, Charts, Compat, Glow, IconBrowser, Item, Perf, Pool, Role, Sim, Toast, Tooltip, WaypointArrow, Widgets (Bus, Compat and Perf are recorded declines, `docs/ARCHITECTURE.md` *External dependencies*).

## 3f Kit revision
`grep -n 'Kit.VERSION'`: addon 53, tag 57. Both payloads move together in one commit (the pairing rule, kit 11 or newer for LibKa0s v1.9.0 or newer, is met by construction).

## 3g Contract delta
Majors that moved and that this addon looks up: Core (18), DebugLog (23, Diagnostics 11, Window 5), Launcher (11), Media (13), Skin (SkinDefs 28, SkinDefsOthers 10), Options (Widgets 46, Nav 7, SkinPicker 12, SkinPickerQueue 1). Read in `CHANGELOG.md` at v1.105.0 (the v1.95.0 to v1.105.0 blocks and their *What a consumer owes* lists) and the `docs/api/` documents:
- DebugLog 23 / DebugLogDiagnostics 11 (`docs/api/DebugLog/version-23.11.1.5-docs.md`): the instance gains `D:Report(tag, title, fn)` and `D:Serialize(value, opts)`; reports go to the console, Copy is plain text, the status line is a 24 px `W.Footer`. Additive for a host; the degradation stub owes the two members (fixed in this commit, below).
- OptionsNav 7 (v1.100.0): adds `O.SideTabs`; additive; the Options stub owes it (fixed below).
- OptionsWidgets 46 (v1.101.0): a slider box reverts junk on Enter and on focus loss; "What a consumer owes: nothing". A smoke line.
- Core 18, Launcher 11 (v1.105.0, header buttons and the settings-opener registry): every library window gets a settings mark that opens the owner's settings through the launcher registry, keyed `d.owner or d.name`. This addon's launcher descriptor passes `name = addonName` (`core/LauncherSetup.lua:124`) and `openSettings` (`:165`), and the console is built with `name` and `addonName = addonName` (`core/DebugLogSetup.lua`), so the lookup meets. `extraEntries` is optional.
- Media 13, SkinDefs 28, SkinDefsOthers 10 (two faces; #82/#84 colour moves): this addon's degraded fallback (`core/SkinSetup.lua`) copies no `list.stripe`, `list.hover` or `icon.hot`, and `tests/test_skinsetup.lua`, which holds the fallback to the live values key for key, stayed green, so nothing here re-copies.
- Tooltip 1 and the library's own tooltip sites (#92), OptionsSkinPicker 12 / Queue 1, the sim panel: library-internal; visible changes reach this addon on the copy (smoke lines).
- Kit 57 (#75, hold-while-registered): no suite here went red on it. `LIBRARY_MARKS` gains `settings`, already declared here.
`grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=Libs --exclude-dir=_kit` finds no host attach site.

### Blockers
None. The red cases on the first run (retail; forever is the same build) were the stub members every host with a by-name parity case owes (design section 5), not contract changes:
- `the DebugLog stub carries the whole live surface` (`tests/test_surface_parity.lua:127`): `Report is missing (live: function); Serialize is missing (live: function)`.
- `the Options stub carries the whole live surface` (`tests/test_surface_parity.lua:145`): `SideTabs is missing (live: function)`.

## 3h Span
`vendored.txt` minus `recorded.txt` names v1.94.0 (vendored by 04d48ba, no bundle). A one-tag span bundle, `docs/revendor/2026-11-16-v1.94.0-v1.94.0/`, is written beside this one.

## 3i Icon declaration
`grep -n 'LibKa0s icons:' CLAUDE.md` -> line 46, directly under the provenance line: `chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high.` Kept as written: the run pre-decides no icon change, and `settings` (v1.105.0's new library mark) is already declared. No `LibKa0s sounds:` line: no line means none, so `media/sounds/` prunes to nothing. Hand lists have drifted before (KickCD `tests/test_mediasetup.lua:28`, WhatGroup `tests/test_mediasetup.lua:19`); the owner's in-client smoke is the backstop.

Prune: `lua <extract>/tools/prune-icons.lua .` printed `12 icon(s) declared; kept 13 file(s), removed 5827` (212 Open Iconic, 1435 Phosphor and 4180 Game-icons files) and `sounds none ... removed 362`; a second run reported `removed 0` for both.

## 3j Tests that assume the whole icon folder
`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v '/_kit/'`: `tests/test_libka0s.lua:558` (`info.tga`), `tests/test_skin_preview.lua:223` (`eye.tga`), both declared names; `tests/test_mediasetup.lua:75-101` reads the catalog names and the declared files only. No whole-catalog loop.

## Dead stub mirrors
`grep -rn '__releaseChrome' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit`: none.
