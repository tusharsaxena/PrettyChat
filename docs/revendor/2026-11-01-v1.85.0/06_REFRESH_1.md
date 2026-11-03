# Refresh 1 of v1.85.0

The tag is still local-only (`git -C ../LibKa0s ls-remote --tags origin v1.85.0` prints nothing) and was re-cut for the owner's rulings of 2026-11-01 and the gate before any push, so this is a refresh and not a new re-vendor. FS-PC-GATE of Ka0sAddonsCommonTasks `docs/2026-11-01-FULL_SKINNING/`.

- **Old:** `9776130`. `libs/LibKa0s/` and `tests/_kit/` matched it before this copy.
- **New:** `2ad1a5080112cc1323fe79f7e134b00768a7ebca`, tag object `36506d6`.

| File | Constant | Old | New |
|---|---|---|---|
| `OptionsCompose.lua` | `COMPOSE_MINOR` | 17 | 18 |
| `SkinDefs.lua` | `DEFS_MINOR` | 24 | 25 |
| `SkinDefsOthers.lua` | `OTHERS_MINOR` | 6 | 7 |
| `SkinEUI.lua` | `EUI_MINOR` | 3 | 4 |
| `SkinPaint.lua` | `PAINT_MINOR` | 16 | 17 |
| `SkinPaintControls.lua` | `CONTROLS_MINOR` | 14 | 15 |
| `SkinPaintExtras.lua` | `EXTRAS_MINOR` | 15 | 16 |
| kit | `Kit.VERSION` | 49 | 50 |

`Media.lua`, `Skin.lua` and `Widgets.lua` moved too (Media minor 12, Widgets minor 21). The kit gains `skin_values.lua`, `skin_switch.lua` and their two suites.

**Blockers:** the facade's `BarBorder` and `HoverArt`, and both new suites in `tests/run.lua`; resolved in this commit. `O.LabelFont` was already in the Options stub. This addon has no Widgets stub, so `ContextMenu` owes nothing.

**Not owed:** this addon has no bar, HUD string, glow or icon border of its own, so the rulings' bar, icon, glow and cover values reach it only through the library's chrome. It calls neither `Skin.FollowOnce` nor `S.Mark`, so no repair step and no release handling apply.

**Adopted:** `Kit.skinValues` with nine rows, the `Const.Color` chat escapes, cause L13; nothing typed had a token to move to. `Kit.skinSwitch` over `tests/skin_surfaces.lua`.

**Prune:** 11 icons declared, kept 12 files, removed 5828, the declaration unchanged. After it, `diff -r` against the tag lists only the pruned icons, CRLF kept.

**Gate:** 673 cases, 672 passed, 0 failed, 1 skipped; luacheck 0/0 in 68 files.
