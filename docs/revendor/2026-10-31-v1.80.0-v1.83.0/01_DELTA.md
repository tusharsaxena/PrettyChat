Delta: LibKa0s v1.77.0 -> v1.83.0 (span: v1.80.0 v1.81.0 v1.82.0 v1.83.0)

# The consolidated span v1.80.0 to v1.83.0 (PrettyChat)

Written 2026-10-31 by item FX-PC-DOCS of the findings remediation (Ka0sAddonsCommonTasks
`docs/2026-10-31-FINDINGS_REMEDIATION/`), because the pre-merge sync-docs pass found `docs/revendor/`
stopping at `2026-10-24-v1.77.0/`. Records only: no code moved for this folder.

The base before the span is **v1.77.0**, recorded in `2026-10-24-v1.77.0/`. This addon never vendored
v1.78.0 or v1.79.0: the v1.80.0 commit took them whole, so their changes are listed under v1.80.0.

```sh
git log --format='%h %ad %s' --date=short -5 -- CLAUDE.md   # before FX-PC-DOCS
3b99a63 2026-10-31 PC-F01: Re-vendor LibKa0s v1.83.0, move the outline default, drop the README font text
75a7c5e 2026-10-30 PC-01: Re-vendor LibKa0s v1.82.0 from the local tag
4ae80a6 2026-10-30 PC-RV: Re-vendor LibKa0s v1.81.0 from the local tag
69d049d 2026-10-29 PC-RV: Re-vendor LibKa0s v1.80.0 from the local tag
83dd40f 2026-10-26 BL-03: Run the green gate's lint through the bounded runner
```

Tags were re-cut while the runs were open, so a commit below may name a tag at an earlier position
than it holds now. The figures here are from the final tags; the final payload for v1.83.0 is
`d6ac61e`, tag commit `6c816fd`.

## v1.80.0, commit `69d049d` (with v1.78.0 and v1.79.0)

`git -C ../LibKa0s diff --stat v1.77.0 v1.80.0 -- LibKa0s testkit`: 74 files, 10923 insertions, 795
deletions.

- **New:** the `LibKa0s-Skin-1.0` major, at Skin minor 7, with `SkinDefs.lua`, `SkinEUI.lua`,
  `SkinAce.lua` and the three `SkinPaint*.lua` files; `OptionsAppearance.lua`, the Skin tab;
  `OptionsSkinPicker.lua`, the first-run picker; `DebugLogWindow.lua`; `WidgetsCopyWindow.lua`;
  `Toast.lua`; the skin fonts and textures under `media/`.
- Kit revision **42 -> 44**, with `mock_paint.lua` new.
- `LibKa0s icons:` gained `settings`, and the README's icon credits moved with it.

**What reached this addon.** The degradation stub in `settings/OptionsSetup.lua` gained
`AppearanceTab`, `AppearanceRows`, `SkinPicker` and `HideSkinPicker` in this commit. The adoption
itself (the skin seam, the `skin.*` rows and the picker) is PC-01 to PC-05 of Ka0sAddonsCommonTasks
`docs/2026-10-29-SKINNING_ROLLOUT/`.

## v1.81.0, commit `4ae80a6`

`git -C ../LibKa0s diff --stat v1.80.0 v1.81.0 -- LibKa0s testkit`: 24 files, none of them new.

- Skin minor 7 -> 8, with the paint files; Core and DebugLogWindow moved; the Options, Widgets,
  PerfPanel and SimPanel files moved.
- Kit unchanged at revision 44.

**What reached this addon.** The commit rolled the stamps only. The follow-ups' smoke and doc changes
are PC-02 of Ka0sAddonsCommonTasks `docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS/`.

## v1.82.0, commit `75a7c5e`

`git -C ../LibKa0s diff --stat v1.81.0 v1.82.0 -- LibKa0s testkit`: 31 files.

- Skin minor 8 -> 9; `OptionsSwitch.lua` new; the font set changed.
- Kit revision **44 -> 45**, with `glyphs.lua` new.

**What reached this addon.** The degraded skin facade gained `FontFlags` and `HudFontSize`, and the
Options stub gained `SkinVerb`, in this commit. `skin.outline`, `/pc skin` and the glyph guard are
PC-01 and PC-02 of Ka0sAddonsCommonTasks `docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/`.

## v1.83.0, commits `3b99a63`, `c531b86` and `d6ac61e`

`git -C ../LibKa0s diff --stat v1.82.0 v1.83.0 -- LibKa0s testkit`: 33 files.

- Skin minor 9 -> 10; `OptionsMedia.lua` new, the previewing media pickers; the font set grew and
  `media/fonts/FONTS.md` is new.
- Kit revision **45 -> 46**.

**What reached this addon.** `skin.outline`'s default moved to `hud` (`3b99a63`), and `getLSM` reached
the Skin tab's pickers (PC-F02). `c531b86` and `d6ac61e` took the two re-cuts of the tag. All of it is
in Ka0sAddonsCommonTasks `docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/`.
