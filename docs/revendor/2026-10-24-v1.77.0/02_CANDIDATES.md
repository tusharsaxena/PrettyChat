# LibKa0s v1.76.0 -> v1.77.0: candidates (PrettyChat)

Sources: `git -C ../LibKa0s log --oneline v1.76.0..v1.77.0`, the tag's `CHANGELOG.md` v1.77.0 block,
and the API documents for the majors that moved (`docs/api/Options/version-30.2.34.3.5.9.2.8.4.2.1.3-docs.md`,
`docs/api/Core/`, `docs/api/DebugLog/`, `docs/api/Widgets/version-15.1.5.3.3-docs.md`,
`docs/api/testkit/version-42-docs.md`). The run's item spec pre-decides the adoptions: the ones this
run needs are PrettyChat's PC-ZS item (strata), and PrettyChat has no PC-KB item (it is frameless and
ships no key binding). Nothing is interviewed, every other candidate is recorded as
**deferred (run 2026-10-24)**, and no GitHub issue is filed (the item spec). The 3g blocker (the four
Options stub members) is not a candidate; it is fixed in the re-vendor commit.

| Surface | Since | Class | Verdict | Evidence |
|---|---|---|---|---|
| `O.KeybindingsTab`, `O.KeybindRows`, `O.KEYBINDS_UNCHANGED` | OptionsKeybinds 2 (v1.77.0) | B | deferred (run 2026-10-24) | CHANGELOG v1.77.0 *OptionsKeybinds minor 2*. PrettyChat ships no `Bindings.xml` and no key binding, so there is no row to draw; the run plans no PC-KB item. |
| `O.StrataTooltip(values[, strings])` | OptionsCompose 8 (v1.77.0) | B | deferred (run 2026-10-24), PC-ZS's to take | CHANGELOG v1.77.0 *OptionsCompose minor 8*. PrettyChat has no player-chosen strata row today; PC-ZS step 3 decides it. |
| `Core.RaiseStaticPopups()` | Core 12 (v1.77.0) | B | deferred (run 2026-10-24) | CHANGELOG v1.77.0 *Core minor 12*. PrettyChat opens no window of its own to re-raise popups from. |
| `W.DragHandle` `spec.level`, `spec.ignoreParentAlpha`, `ApplyLevel` | WidgetsDragHandle 5 (v1.77.0) | C | deferred (run 2026-10-24) | PrettyChat consumes no Widgets and draws no handle. |
| Kit `mock_layers.lua` | kit 42 | B (tests) | deferred (run 2026-10-24), PC-ZS's to take | `docs/api/testkit/version-42-docs.md`; PC-ZS step 2 pins frame classes through it. |
| Kit `mock_bindings.lua`, `Kit.assertBindingsXml`, `Kit.keybindThroughTab` | kit 42 | B (tests) | deferred (run 2026-10-24) | No `Bindings.xml` and no Keybindings tab here. |

## Delivered on the copy (class A)

- **The debug console is toplevel and re-raises a shown confirmation** (DebugLog 21 with Core 12):
  `/pc debug` opens a DIALOG console that now rises among its DIALOG peers on a click and never
  buries a shown `StaticPopup` (for example the *Reset all settings* confirmation). This is PRC-Z01 + Z02 of
  Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/inputs/strata/PrettyChat.md` (the
  LibKa0s CHANGELOG cites them as PRE-Z01 and PRE-Z02), fixed in the library (LK-01).
- **Clamped dropdown menus** (Widgets 15) and **the IdList suggestion list closed at combat start**
  (OptionsIds 3, OptionsCombat 2): ride along; PrettyChat draws neither surface.
- **PerfPanel 9 and SimPanel 6** (toplevel, popup re-raise): ride along; PrettyChat opens neither.
