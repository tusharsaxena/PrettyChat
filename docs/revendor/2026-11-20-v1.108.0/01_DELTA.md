Delta: LibKa0s v1.107.0 -> v1.108.0

Recorded for the re-vendor commit. Payload taken from the tag, never the sibling tree: `git -C ../LibKa0s archive v1.108.0 LibKa0s testkit tools` (tag fc7714f, commit 56c20b7; a local annotated tag on the LibKa0s branch `feat/2026-11-20-libka0s-94-97-99-100`, not yet on origin, which this run expects). Run under Ka0sAddonsCommonTasks `docs/2026-11-20-LIBKA0S_94_97_99_100/`, item SD-RV-PC: the copy, provenance, declaration and prune half of `/dev-copilot:wow-revendor-libka0s` only. The run's design skips the adoption interview and the issue filing.

## Step 0 pre-flight
Newest single-tag bundle `docs/revendor/2026-11-19-v1.107.0`, base v1.106.0, vendored-before v1.106.0: `ok`. No base correction is owed.

## 3a Base
- `grep -n '[Bb]undles' CLAUDE.md` -> `45:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.107.0 (MIT).` before the roll.
- `git log -1 --format=%h -- libs/LibKa0s tests/_kit` = 0085585 (the re-cut v1.107.0); its CLAUDE.md names v1.107.0. They agree.
- Payload before the copy equalled the library at v1.107.0: `diff -rq` of a v1.107.0 extract against `libs/LibKa0s` (bar the undeclared icons and the sounds) and against `tests/_kit` printed nothing.
- Range: `git -C ../LibKa0s log --oneline v1.107.0..v1.108.0` is 15 commits (SD-LK-94, SD-LK-99, SD-LK-100, SD-LK-97 Batches A to D, SD-LK-GUARD, SD-LK-REL). `git diff --stat v1.107.0 v1.108.0 -- LibKa0s testkit`: 17 payload files and 6 kit files, 1363 insertions, 306 deletions.

## 3b/3c Per-file minors that moved (old = this addon, new = v1.108.0)
```
Callout.lua                 4 -> 5
CalloutSettings.lua         5 -> 6
Charts.lua                  2 -> 3
ChartsRender.lua            1 -> 2
Core.lua                   18 -> 19
OptionsCompose.lua         19 -> 20
SkinPaint.lua              19 -> 20
SkinPaintControls.lua      18 -> 19
SkinPaintHud.lua            1 -> 2
WaypointArrow.lua           2 -> 3
WaypointArrowSettings.lua   2 -> 3
Widgets.lua                29 -> 30
WidgetsBar.lua              1 -> 2
WidgetsDragHandle.lua      15 -> 16
WidgetsDragHandleTip.lua    2 -> 3
WidgetsDropdown.lua         2 -> 3
WidgetsLineChart.lua        7 -> 8
```
Every other file matched v1.107.0 before the copy; no file is new or removed. Claimed and actual minors agree.

## 3d Diffs
After the copy and before the prune, `diff -r` of both payloads against the extract was empty. No `Only in libs/LibKa0s` line. After the prune the only difference is the undeclared icons and the sounds (`Only in <extract>/...`), and `tests/test_vendor_sync.lua` is green.

## 3e Consumption map
Unchanged from `../2026-11-16-v1.105.0/01_DELTA.md` 3e: Core, DebugLog, Env, Launcher, Lifecycle, Media, Skin, Options, Schema and Slash. No host call of `O.FontGroup`, `O.BorderGroup`, `O.BarGroup`, `O.ColorPair`, `W.Bar`, `S.ApplyBarFill`, `W.ContextMenu`, Charts, Callout or WaypointArrow: `grep -rn -E "FontGroup|BorderGroup|BarGroup|ColorPair|W\.Bar|ApplyBarFill|ContextMenu|Callout|WaypointArrow|skinBands" --include='*.lua' .` outside `libs/` and `tests/_kit/` finds only `core/SkinSetup.lua:445`, the degraded facade's stub name list (`ApplyBarFill` among the no-op names), which needs no change.

## 3f Kit revision
`grep -n 'Kit.VERSION' tests/_kit/framework.lua`: 57 -> 58. Both payloads are copied whole in one commit (the pairing rule is met by construction).

## 3g Contract delta
The tag's *What a consumer owes at its re-vendor* binds composer hosts (Batch A), bar, chart and menu hosts (Batch B), the Callout, WaypointArrow and Quick Comms pad hosts, and every host wiring `Kit.skinSwitch` or `Kit.skinValues` (kit revision 58). Only the last binds here. After the copy the suite stays green under both clients (697 passed, 1 skipped): the six declared surfaces pass the family checks, none holds a StatusBar, and no new `test_skin_values` hit appears. The new kit case "a bar whose texture never moves is reported" adds one test. The run's SD-SK-PC item adds the console report surface (U-25).

### Blockers
None.

## 3h Span
Every vendored tag since v1.94.0 has a bundle. No span bundle is owed.

## 3i Icon declaration
`grep -n 'LibKa0s icons:' CLAUDE.md` -> line 46, directly under the provenance line, kept as written (12 names). No `LibKa0s sounds:` line.

Prune: `lua <extract>/tools/prune-icons.lua .` removed the 362 callout sounds the copy restored and no icon (`12 icon(s) declared; kept 13 file(s), removed 0`); a second run removed 0.

## 3j Tests that assume the whole icon folder
Unchanged from the v1.105.0 bundle's 3j.

## Dead stub mirrors
`grep -rn '__releaseChrome' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit`: none.
