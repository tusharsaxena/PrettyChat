# 06 — Refresh: LibKa0s v1.75.0 from the moved local tag

Run 2026-10-23, plan item PC-RV2, on branch `feat/2026-10-22-libka0s-issues-45-58`. Files 01 to 05
are frozen and record the PC-RV copy; this file records what happened after it.

## Why

The local tag `v1.75.0` moved after PC-RV vendored it. It went from `265a89e` to `6bf5f3e` (LK-26:
Sim minor 2, SimTimeline minor 2) and then to `9e5c4e2` (LK-27: SimPanel minor 2), its final
position. This refresh brings the vendored payload from **`265a89e`** to **`9e5c4e2`**.

## What changed

The same copy PC-RV made was repeated: `git -C ../LibKa0s archive v1.75.0 LibKa0s testkit` at
`9e5c4e2`, copied whole over `libs/LibKa0s/` and `tests/_kit/`, then the tag's
`tools/prune-icons.lua` run against the unchanged `LibKa0s icons: clear, close, copy.` line (kept
4 files, removed 5836, the same result as PC-RV). Afterwards both folders match the tag apart from
the pruned icons, and no file existed only on the addon side. Three files changed:

| File | Before (`265a89e`) | After (`9e5c4e2`) |
|---|---|---|
| `libs/LibKa0s/Sim.lua` | `LibKa0s-Sim-1.0` minor 1 | minor 2 |
| `libs/LibKa0s/SimTimeline.lua` | `TIMELINE_MINOR` 1 | 2 |
| `libs/LibKa0s/SimPanel.lua` | `SIM_PANEL_MINOR` 1 | 2 |

`tests/_kit/` is identical to the tag's `testkit/` (kit revision unchanged). The `CLAUDE.md`
provenance line stays `v1.75.0` and the icon declaration was not edited.

## Ripple

None. PrettyChat does not bind `LibKa0s-Sim-1.0`, and no test or doc here pins a Sim, SimTimeline
or SimPanel minor. The addon version and the TOC are unchanged.

## Gates

`ka0s-bounded luacheck .` 0 warnings / 0 errors in 56 files; `ka0s-bounded lua tests/run.lua` 574
passed, 0 failed, 1 skipped (575), the vendor-sync cases green against the moved tag; no authored
`.lua` over the 1500-line cap outside the census.
