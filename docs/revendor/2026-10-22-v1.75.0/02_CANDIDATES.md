# LibKa0s v1.71.0 -> v1.75.0: candidates (PrettyChat)

Sources: `git -C ../LibKa0s log --oneline v1.71.0..v1.75.0`, the tag's `CHANGELOG.md` blocks for
v1.72.0 to v1.75.0, and the `Since` rows of the API documents for every major whose minor moved.
This is a mechanical re-vendor in a non-interactive milestone: nothing is interviewed, and nothing
below is a candidate, so nothing is declined and no GitHub issue is filed.

PrettyChat is frameless: `core/LauncherSetup.lua:195-199` passes no `isLocked`/`toggleLock`, no
`isTestMode`/`toggleTestMode` and no `isWindowShown`/`toggleWindow`, because there is no lock, no
test mode (`/pc test` is a verb that prints) and no window of its own. Every surface below needs a
frame, a list or a page this addon does not have.

| Surface | Since | Class | Verdict | Evidence |
|---|---|---|---|---|
| `W.SearchBox` | Widgets 13 (v1.75.0) | B | not a candidate | A flat filter-bar search box. PrettyChat has no filter bar: its one searchable list is the Categories string list, which is an AceGUI page the Options toolkit draws. |
| `W.TestStrip` | Widgets 13 (v1.75.0) | B | not a candidate | The strip that marks a test-mode window. PrettyChat has no test mode and no window (`core/LauncherSetup.lua:195-199`). |
| `W.StepPanel` | - | - | not a candidate | Withdrawn before release (LK-11 outcome B); the renderer is Sim-private in `SimPanel.lua` with no public contract. |
| `LibKa0s-Glow-1.0` | Glow 1 (v1.75.0) | C | not a candidate | A frame glow over `LibCustomGlow-1.0`. PrettyChat draws no frame to glow. |
| `LibKa0s-Sim-1.0` | Sim 1 (v1.75.0) | C | not a candidate | A scenario simulator for a host with live combat or loot events to replay. PrettyChat rewrites chat format strings; there is nothing to simulate, and Sim adoption is required of no addon (WS-07, the tag's CHANGELOG *What a consumer owes*). |
| `Item.BonusIDsFromLink` | Item 3 (v1.75.0) | B | not a candidate | PrettyChat does not consume the Item major (`01_DELTA.md` 3e) and parses no item link. |
| `O.Drawer` | Options 29 / OptionsDrawer 1 (v1.73.0) | B | not a candidate | A page drawer. No PrettyChat page draws one; the degradation stub gains an inert `Drawer` (blocker 1). |

## Delivered on the copy (class A)

- DebugLog 20 / DebugLogDiagnostics 3: the console and the diagnostics report as the tag ships them.
  The report's `LibKa0s running:` line lists more file minors (Glow, Sim, SimTimeline, SimPanel);
  PrettyChat does not parse that line.
- Options 29: OptionsTabs 9 and OptionsIdList 5 as the tag ships them, including the kept scroll
  position on a page re-render (`docs/smoke-tests.md` RV-77).
- Core 11, Media 5 / MediaIcons 1, Perf 15 / PerfPanel 7 and Widgets 13 ride along whole.
