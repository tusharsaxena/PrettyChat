# Candidates

Part of Ka0sAddonsCommonTasks `docs/2026-11-06-FOLLOWUPS_V1_91/` (FU-RV-PC). Sources: `git -C ../LibKa0s log --oneline v1.90.0..v1.91.0`, the v1.91.0 `CHANGELOG.md` block, and the new `docs/api` documents for Core (17.1), Widgets (26.1.6.13.7.8.5) and Skin (17.1.27.8.19.19.1.1.17.4.9).

## A. Delivered on the re-vendor alone

- **WidgetsLineChart 7** (CHANGELOG v1.91.0, *The line chart's lines in physical pixels*): the axis, grid, markers, crosshair and series are drawn in physical pixels. No member, option or data field moves. This addon draws no line chart, so nothing changes on its screens.
- **Core 17 / CorePixel 1, Widgets 26 / WidgetsDropdown 1, SkinPaintExtras 19 / SkinPaintHud 1 / SkinAceConfirm 1** (CHANGELOG v1.91.0, *The band files peeled*): pure moves along each file's seam. No member, option or behaviour changes.

## B. Host change required

None. v1.91.0 adds no public surface, descriptor field or row type.

## C. Whole-module adoption

None new. No major was added in this range.
