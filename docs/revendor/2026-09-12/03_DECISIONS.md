# 03 — Decisions

This run was **non-interactive**. The owner gave the answers up front on 2026-09-12, as a written
rule applied to each candidate rather than as a per-candidate interview:

- **Adopt:** delete a local shim only where the kit now provides the same contract and the suite
  stays green, with characterization first.
- **Decline:** anything that needs a harness migration, for example a `wow_mock` that replaces the
  kit's `NewAddon`/`AceEvent`/`LibStub` wholesale so the kit fix cannot reach it. A decline is
  recorded here and returned to the orchestrator as a proposed issue. **This run files no GitHub
  issue and pushes nothing.**

The brief for this addon names B1 by line: "delete that one line if the suite stays green
(measure), else decline with reason. Keep the rest of the override."

| # | Candidate | Decision | Reason |
|---|---|---|---|
| B1 | Delete `object.Printf = noop` from the `tests/wow_mock.lua` `NewAddon` override (#30) | **adopt** | The kit provides the same contract (`mock_base.lua:578`). The override still calls `baseNewAddon` first, so the kit's `Printf` reaches the object once the stamp goes, and no harness migration is needed. 329/329 green before and after, and luacheck 0/0 once the orphaned `local function noop` goes with it. |

No candidate was declined, so no decline issue exists, filed or proposed. No candidate was left
unreached.
