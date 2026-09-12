# 03 — Decisions

This run was **non-interactive** (wave B2 of the 2026-09-12 triage). The owner's brief gave the rule
up front: adopt any kit-17 surface that retires a local layer, for example the
`RegisterChatCommand` recording or the `Print` override, but only where the suite stays green.
Filing and pushing are skipped for this run, so a decline is recorded here and returned to the
orchestrator as a proposed issue. **No GitHub issue was filed and nothing was pushed.**

| # | Candidate | Decision | Reason |
|---|---|---|---|
| B1 | Forward `NewAddon`'s name and mixin list to the kit | **adopt** | Retires the local `GetAddon`, name stamp and `RegisterChatCommand` recorder. The characterization case was red before the change and green after; 333/333, luacheck 0/0. The `Print` override was kept, not retired: without it a failed reclaim prints nothing and the reclaim guard goes vacuous (02_CANDIDATES.md, B1). |
| B2 | Drive the lifecycle through `AceAddon.frame` | **not now** (proposed `state:triaged`, `severity:low`; not filed) | This is not a local layer the brief names. `tests/loader.lua` is slated for deletion when `LIBKA0S-01` lands, and the change would touch every instance's boot, degraded loads included, for no new assertion. |

No candidate was left unreached.
