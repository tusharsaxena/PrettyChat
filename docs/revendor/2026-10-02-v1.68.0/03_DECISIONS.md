# Decisions (PrettyChat, LibKa0s v1.67.0 -> v1.68.0)

No interview: the owner delegated every decision for this run (Ka0sAddonsCommonTasks
`docs/2026-10-02-LIBKA0S_TOOLTIP_PLACE/00_PLAN.md`, Scope: "The other seven: re-vendor only (no
strip)"; "A declined candidate is NOT filed as an issue unless the reason is a real gap"). Decided
by the executor, item TP-PC-01, reasoning recorded here.

| # | Candidate | Decision | Reason | Issue |
|---|---|---|---|---|
| B1 | `tooltipPlace` / descriptor `place` (WidgetsDragHandle 4) | **never (not applicable)** | PrettyChat has no drag strip: no `lib.DragHandle` call and no `LibKa0s-Widgets-1.0` lookup in host code (01_DELTA.md 3e). The hook places a strip's tooltip, and there is no strip whose tooltip could be placed. If a strip is ever added, the field is available then; nothing is lost by declining now. | none filed: not a gap, the surface has nothing to attach to here |

Unreached: none.
