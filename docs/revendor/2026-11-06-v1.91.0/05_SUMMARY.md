# Summary

Part of Ka0sAddonsCommonTasks `docs/2026-11-06-FOLLOWUPS_V1_91/` (FU-RV-PC).

## Tag

LibKa0s v1.90.0 -> v1.91.0. The tag is local and not pushed (`55bfbb4`). The base is the tag named on the `CLAUDE.md` provenance line (line 44). It matches the last payload commit `fd42e5d` and the vendored bytes (01_DELTA.md, 3a and 3b).

| File | old | new |
|---|---|---|
| Core.lua | 16 | 17 |
| CorePixel.lua | (new) | 1 |
| SkinPaintExtras.lua | 18 | 19 |
| SkinPaintHud.lua | (new) | 1 |
| SkinAceConfirm.lua | (new) | 1 |
| Widgets.lua | 25 | 26 |
| WidgetsDropdown.lua | (new) | 1 |
| WidgetsLineChart.lua | 6 | 7 |

Kit revision 51 is unchanged, and the kit payload was copied whole in the same commit.

Step 0 was skipped because the installed skill's roster regex matches nothing (fixed upstream by FU-DC1). The 3h listing, run with `tag_at` rewritten on a named variable, printed nothing, so no span bundle was written and no base correction was made.

## The copy

Both payloads were copied whole from a fresh `git -C ../LibKa0s archive v1.91.0 LibKa0s testkit tools` extract. Before the prune, `diff -r --strip-trailing-cr` and `diff -rq` came back empty for both `libs/LibKa0s` and `tests/_kit`. After the prune, the only library differences left are `Only in <extract>/LibKa0s/media/icons` lines for the undeclared icons. Four files are new (`CorePixel.lua`, `SkinAceConfirm.lua`, `SkinPaintHud.lua`, `WidgetsDropdown.lua`). Nothing existed only in the addon, so nothing under `libs/` was deleted except by the prune.

## Delivered for free (class A)

- The line chart's lines are drawn in physical pixels (WidgetsLineChart 7). This addon draws no chart.
- The four band-file peels (Core, Widgets, SkinPaintExtras), which are internal moves with no behaviour change.

## Blockers

None. `tests/loader.lua:43` derives the library file list from `LibKa0s.xml`, so the four new files load in XML order without an edit. No test pins an exact minor, and no stub mirrors a moved member.

## Icons and credits

The provenance line rolled to v1.91.0. The `LibKa0s icons:` line is unchanged and still sits directly under it:
`chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high`.
No provenance split was needed.

`tools/prune-icons.lua` at the tag printed `12 icon(s) declared; kept 13 file(s), removed 5827`. All of the removed files are from the undeclared catalog. Open Iconic is still the only set that ships, so the README's `## Credits` needed no change. There was no dead stub mirror.

## Decisions

These come from the plan (03_DECISIONS.md). Nothing was adopted, nothing was declined and no issue was filed. No candidate was left unreached, and no refresh file was written.

## Gate

After the prune, `~/.claude/dev-copilot/bin/ka0s-bounded luacheck .` reported 0 warnings and 0 errors in 70 files. `~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua` reported 691 passed, 0 failed and 1 skipped (692 total), the same as at v1.90.0. The skip is the existing diagnostics-contract opt-out case, which does not apply to this addon. No addon Lua changed, so the 1500-line cap and the CCN 15 limit are as before.
