Delta: LibKa0s v1.84.0 -> v1.85.0

Part of Ka0sAddonsCommonTasks `docs/2026-11-01-FULL_SKINNING/` (FS-PC-RV). Written before the copy. The tag is local at commit `9776130`: `git -C ../LibKa0s ls-remote --tags origin v1.85.0` prints nothing. Payload taken with `git -C ../LibKa0s archive v1.85.0 LibKa0s testkit tools`.

## Base (3a, 3b)

`grep -n '[Bb]undles' CLAUDE.md` names v1.84.0 on line 44. `git log -1 --format=%H -- libs/LibKa0s tests/_kit` gives a commit whose line names v1.84.0, and `diff -rq` of both payloads against `git archive v1.84.0` shows only the undeclared icons: the bytes are v1.84.0.

Newest single-tag bundle `2026-10-31-v1.84.0` states base v1.83.0, which is the addon's history. No correction owed. Step 0's collection-wide pre-flight was run for this addon only, by hand: the plan's lead owns the fan-out.

## Per-file minors (3c), moved files only

`for f in the tag's LibKa0s.xml files: grep the [A-Z_]*MINOR constant, old against tag`

| File | old | new |
|---|---|---|
| Glow.lua | 1 | 2 |
| Toast.lua | 1 | 2 |
| Skin.lua | 11 | 14 |
| SkinDefs.lua | 19 | 24 |
| SkinDefsOthers.lua | 1 | 6 |
| SkinPaint.lua | 13 | 16 |
| SkinPaintExtras.lua | 7 | 15 |
| SkinPaintControls.lua | 11 | 14 |
| SkinEUI.lua | 2 | 3 |
| SkinAce.lua | 6 | 9 |
| Widgets.lua | 17 | 20 |
| WidgetsReorder.lua | 3 | 5 |
| WidgetsDragHandle.lua | 10 | 12 |
| WidgetsLineChart.lua | 5 | 6 |
| WidgetsAutocomplete.lua | 5 | 6 |
| WidgetsCopyWindow.lua | 2 | 4 |
| DebugLogWindow.lua | 2 | 3 |
| Launcher.lua | 5 | 6 |
| OptionsWidgets.lua | 41 | 44 |
| OptionsIds.lua | 6 | 7 |
| OptionsIdList.lua | 7 | 8 |
| OptionsTabs.lua | 13 | 15 |
| OptionsCompose.lua | 16 | 17 |
| OptionsScroll.lua | 10 | 13 |
| OptionsNav.lua | 4 | 5 |
| OptionsDrawer.lua | 4 | 5 |
| OptionsKeybinds.lua | 6 | 7 |
| OptionsAppearance.lua | 5 | 6 |
| OptionsSkinPicker.lua | 5 | 7 |
| OptionsMedia.lua | 3 | 4 |
| PerfPanel.lua | 11 | 12 |
| SimPanel.lua | 9 | 10 |
| SimPanelRender.lua | 1 | 2 |

No file is behind the old tag: no cross-major skew.

## Kit (3f)

`grep -n 'Kit.VERSION'`: revision 47 -> 49. The two payloads move together.

## Consumption (3e)

Lookups outside `libs/` and `tests/`: Lifecycle, Launcher, Core, Env, Media, DebugLog, Skin (`core/*Setup.lua`), Schema, Slash, Options, DebugLog (`settings/`). Unchanged.

## Blockers (3g, 3j)

- **Skin facade.** `CHANGELOG.md` v1.85.0, "What a consumer owes", and the Options document's *Moving to this version*, section 7: the degraded facade in `core/SkinSetup.lua` gains `Mark`, `MarkText`, `HudTextColor`, `HudLabelColor`, `BarFillColor`, `HudShadow`, `BarGloss` and `HudFont`. Fixed in the re-vendor commit.
- **Options stub.** CHANGELOG, OptionsWidgets minor 43: `settings/OptionsSetup.lua`'s stub gains `LabelFont`. Fixed in the re-vendor commit.
- **Icons.** `docs/releasing.md` Step 8 for v1.85.0: `chevron-down, chevron-up, close, confirm, info, move, reset, volume-high`. Decided by the plan, not re-asked. Hand lists have drifted before; the owner's smoke is the backstop.
- **3j.** `tests/test_libka0s.lua` and `tests/test_mediasetup.lua` assert `info` is neither declared nor shipped, and `tests/test_mediasetup.lua` carries the drawn set. Fixed in the re-vendor commit.
- No `__Attach*` site in this addon outside `libs/`, and `__releaseChrome` has no mirror here.

## Unrecorded tags (3h)

v1.80.0 to v1.83.0 are recorded by the span bundle `2026-10-31-v1.80.0-v1.83.0`; nothing unrecorded.
