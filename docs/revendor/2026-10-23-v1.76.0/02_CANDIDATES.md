# LibKa0s v1.75.2 -> v1.76.0: candidates (PrettyChat)

Sources: `git -C ../LibKa0s log --oneline v1.75.2..v1.76.0`, the tag's `CHANGELOG.md` v1.76.0 block,
and the API documents for the two majors that moved (`docs/api/Sim/version-2.3.5-docs.md`,
`docs/api/Widgets/version-14.1.4.3.2-docs.md`). This is a mechanical re-vendor in a non-interactive
milestone: nothing is interviewed, and nothing below is a candidate, so nothing is declined and no
GitHub issue is filed.

PrettyChat is frameless: there is no lock, no test mode (`/pc test` is a verb that prints) and no
window of its own, and it rewrites chat format strings, so there is nothing to simulate.

| Surface | Since | Class | Verdict | Evidence |
|---|---|---|---|---|
| `W.TestStrip(parent, { kind = "sim" })`, `strip.kind` | Widgets 14 (v1.76.0) | B | not a candidate | The simulation flavor of the mode strip. PrettyChat draws no strip, has no test mode and no simulator. |
| Sim auto-run (Run all removed) | SimTimeline 3 / SimPanel 5 (v1.76.0) | C | not a candidate | Behavior of a registered simulator. PrettyChat registers none (`2026-10-22-v1.75.0/02_CANDIDATES.md`). |

## Delivered on the copy (class A)

- Nothing this addon reaches. `SimTimeline.lua`, `SimPanel.lua` and `Widgets.lua` ride along whole;
  `DebugLog.lua`'s use of Widgets (the resize helper and the copy window) is unchanged by minor 14.
