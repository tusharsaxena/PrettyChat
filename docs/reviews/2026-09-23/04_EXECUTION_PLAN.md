# 04 — Execution plan (PrettyChat, 2026-09-23)

This plan has no upstream milestone, because there are no `[upstream]` findings. It does include one
**cross-repo handoff** (H-1, into LootHistory). Every task edits this repository only. Nothing touches
`libs/` or `tests/_kit/`.

The green gate for every task is
`ka0s-bounded lua5.1 tests/run.lua` plus `ka0s-bounded luacheck .` at 0/0. When a task changes the
number of test cases, the `--list` output goes into `docs/test-cases.md` and the README `Tests` badge
changes **in the same commit**.

## M1: Hygiene and truth fixes (low risk, touches no data)

- **Done when:** C-04 through C-09 are merged, the gate is green, and the inventory and badge are updated.

| Task | Owner role | Changes (findings) | Files |
|---|---|---|---|
| M1-T1 | lint-maintainer | C-08 (F-008) | `.luacheckrc` |
| M1-T2 | lua-refactorer | C-09 (F-009) | `modules/Override.lua`, `settings/Schema.lua`, `settings/Panel.lua` |
| M1-T3 | lua-fixer | C-04 (F-004) + test | `modules/Override.lua`, `tests/test_override.lua` |
| M1-T4 | lua-fixer | C-07 (F-007) + test | `settings/Panel.lua`, `tests/test_panel.lua` |
| M1-T5 | lua-fixer | C-05 (F-005) + test + docs | `settings/Panel.lua`, `tests/test_libka0s.lua`, `docs/settings-panel.md`, `docs/module-map.md` |
| M1-T6 | ux-cleanup | C-06 (F-006) | `settings/Schema.lua`, `settings/Slash.lua`, `settings/Panel.lua`, `locales/enUS.lua` |

**Concurrency map:**

- M1-T1 is parallel with everything else.
- M1-T2 and M1-T3 both touch `modules/Override.lua`, so they run **serially: T3, then T2**.
- M1-T2, M1-T4, M1-T5 and M1-T6 all touch `settings/Panel.lua`, so they run **serially: T4, T5, T6,
  then T2**.
- M1-T2 and M1-T6 both touch `settings/Schema.lua`, which the order above already covers.

**Order:** T1 in parallel with (T3, then T4, then T5, then T6, then T2).

**Checkpoint CP-1:** a human reviews the diff of C-06's user-facing strings and C-09's ordering. Run the
SMK-C09 diff before M2.

## M2: Migration runner, then collapse the cross-registration (touches SavedVariables)

- **Done when:** C-02 and C-03 are merged. The migration tests are green, and the four retired
  cross-registration cases have been replaced. Docs updated: ARCHITECTURE Known Limitations,
  `data-flow.md`, `slash-dispatch.md`, `module-map.md`, and `smoke-tests.md` T-53. SMK-C02/C03 passes
  in-client.

| Task | Owner role | Changes (findings) | Files |
|---|---|---|---|
| M2-T1 | savedvariables-engineer | C-02 (F-003) + 2 tests | `core/Database.lua`, `core/PrettyChat.lua` (comment), `tests/test_database.lua` |
| M2-T2 | lua-refactorer | C-03 (F-002): defaults, migration v2, schema assertion, panel tooltip removal, locale key removal, test swap, docs | `defaults/Defaults.lua`, `core/Database.lua`, `settings/Schema.lua`, `settings/Panel.lua`, `locales/enUS.lua`, `tests/test_apply.lua`, `tests/test_panel.lua`, `tests/test_schema.lua`, `tests/test_defaults.lua`, `tests/test_database.lua`, `docs/*.md`, `docs/test-cases.md`, `README.md` |

- M2-T2 depends on M2-T1: they share `core/Database.lua`, and T2's migration needs T1's profile-step
  list. Run them **serially**.
- M2 depends on M1, because it shares `settings/Schema.lua` and `settings/Panel.lua`.

**Checkpoint CP-2 (before merging M2-T2):** back up a real SavedVariables file and run SMK-C02/C03 on
two profiles.

## M3: Cross-addon contract (documentation here, code in LootHistory)

- **Done when:**
  - C-01 is merged in this repo.
  - The LootHistory issue for H-1 is filed, citing F-001 and this bundle's path.
  - SMK-F001's first half (the arg1 wording changes with combat state) has been observed and recorded.
- **Exit criterion for the handoff:** a LootHistory commit implementing H-1 with a test that flips a
  global between two parses. That lands in LootHistory's own plan, not here.

| Task | Owner role | Changes (findings) | Files |
|---|---|---|---|
| M3-T1 | docs-maintainer | C-01 (F-001) | `docs/ARCHITECTURE.md`, `docs/scope.md`, `docs/smoke-tests.md` |
| M3-T2 | coordinator | H-1 handoff issue (F-001) | LootHistory repo, issue only |

- M3-T1 touches `docs/ARCHITECTURE.md`, and so does M2-T2 (Known Limitations). Run M3-T1 **after**
  M2-T2, or rebase it onto M2-T2.
- M3-T2 is parallel with everything.

**Checkpoint CP-3:** in-client SMK-F001 with LootHistory loaded. Attach the `/etrace` evidence to the
LootHistory issue.

## Suggested commit boundaries

One commit per task:

1. `Drop twelve dead globals from .luacheckrc` (M1-T1)
2. `Never report our own override as Blizzard's original` (M1-T3)
3. `Stop leaking gsub's count into Schema.Set` (M1-T4)
4. `Print the degraded /pc test report to chat, as the code claims` (M1-T5)
5. `Correct the Test tooltip, the resetall help row and three stale comments` (M1-T6)
6. `One sorted-names table for every category walk` (M1-T2)
7. `Run profile migrations on every profile; stamp only on success` (M2-T1)
8. `Give each Blizzard global one registration; migrate the dead Loot copies` (M2-T2)
9. `Document that PrettyChat rewrites the chat payload every addon reads` (M3-T1)

Every commit ends with the session attribution lines. Push after M1 and after M2. **Merge only on the
user's go-ahead.**
