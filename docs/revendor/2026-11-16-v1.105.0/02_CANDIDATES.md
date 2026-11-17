# 02 Candidates, LibKa0s v1.94.0 -> v1.105.0

Sources: `git -C ../LibKa0s log --oneline v1.94.0..v1.105.0`; LibKa0s `CHANGELOG.md`, the v1.95.0 to v1.105.0 blocks; `docs/api/DebugLog/version-23.11.1.5-docs.md`; Ka0sAddonsCommonTasks `docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/03_ADOPTION_PLAN.md` and its research note R8 section 3.

**Class A, delivered on the copy alone**
- Every library window's header strip, **extras · settings · close**, with a settings mark that opens this addon's settings (#86; Core 18, WidgetsHeader 1, Launcher 11). The launcher registers the opener from the descriptor this addon already passes (`core/LauncherSetup.lua:124`, `:165`).
- The debug console's 24 px `W.Footer` status line and plain-text Copy (#79, #90; DebugLogWindow 5).
- The library's own tooltips placed by `LibKa0s-Tooltip-1.0` (#92 part B): dropdown entries, the minimap button, the skin picker's toolbar.
- Skin colour moves (#82, #84): Ka0s Default's row tints, seven skins' `icon.hot`.
- The slider box that reverts junk (OptionsWidgets 46), two new faces (Media 13), the sim panel's default title (#78).
- Kit revision 57: registered frames held until they unregister; `mock_screen.lua` (opt-in).

**Class B, host change required: owed in phase [3], not offered here**
- **#92, own tooltips through the placers.** One `SetOwner` site: `settings/Panel.lua:439` (`GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")`). Moves onto `PlaceBeside`/`PlaceAttached`. Additive at the call site. Recommended: adopt.
- **#79, `D:Report` / `D:Serialize`.** R8 found no multi-line report verb in chat. `/pc test` (`settings/Slash.lua:75`) already writes its sample lines to the debug console; the adoption run confirms whether it should go through `D:Report` for the one pointer line. `/pc list` is the reserved verb and stays in chat. Expected small or none.
- **#87, `Sim.Sample(client)`.** No sample-character fixture found in `core/`, `settings/` or `modules/`. Expected not to apply; the adoption run confirms it.
- **#86, own windows' header strips.** This addon draws no window of its own (the console and copy window are the library's): not applicable.
- **#88 / #89, docked strip and `W.Footer`.** No test strip and no hand-built footer here: not applicable.
- **#85, Callout.** Not a candidate consumer here.

**Class C, whole-module**: none new to offer. Majors in the payload this addon does not look up: Bus, Callout, Charts, Compat, Glow, IconBrowser, Item, Perf, Pool, Role, Sim, Toast, Tooltip, WaypointArrow, Widgets. Bus, Compat and Perf are settled declines.

**Blockers (3g)**: none. The stub members (`Report`, `Serialize`, `SideTabs`) are owed fixes, made in the re-vendor commit.
