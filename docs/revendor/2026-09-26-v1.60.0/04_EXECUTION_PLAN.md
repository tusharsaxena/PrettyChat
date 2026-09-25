# 04 — Execution plan

Nothing is adopted in this run. Both adoptions are the rollout plan's later items, on this branch:

| Item | What | Files |
|---|---|---|
| DR-PC-03 | `modules/Diagnostics.lua` on the helper, with `out:escape` for format values (live-global audit, snapshot health, patch drift, render check); the `diagnostics` verb and the `debug diagnostics` word; `Kit.diagnostics` wired so the kit's contract suite runs instead of skipping | `modules/Diagnostics.lua`, `core/DebugLogSetup.lua`, `settings/Slash.lua`, `PrettyChat.toc`, `tests/run.lua`, new tests |
| DR-PC-04 | README `## Reporting a bug` | `README.md` |
| DR-PC-05 | `docs/debug.md` and the doc ripple (slash-dispatch twelve -> thirteen, smoke-tests buffer lines, the `Schema.lua` comment) | `docs/` |

This run's own commit, DR-PC-01, carries only what the copy needs to stay green: the payloads, the
provenance line, the stub's three members, the kit suite's declaration, the buffer re-pins, the
live-set literal, the corrected `liveVerbs` comment, and the docs the re-vendor touches.
