# PrettyChat review — 2026-10-07 — 04 Execution plan

Work happens on `feat/2026-10-07-review-audit-remediation` in every repo it touches. Commit subjects follow the collection's `<ID>: ` convention. Nothing is merged, tagged or version-bumped without the owner's go-ahead.

## M0: Owner triage (checkpoint)

- **Done when:** the owner has accepted or declined each row of the disposition table in `02`. The open calls are F-003 (confirm or keep), and F-011 and F-013 (optional).

## M1: Cross-repo handoffs, in parallel with M2

- **T1.1 (U-1 / F-001):** LootHistory, `core/Util.lua` and a new test. Role: lua-fixer in LootHistory. Open the LootHistory issue citing H-1 first, with throttled GitHub writes.
- **T1.2 (U-2 / F-007):** LibKa0s, `testkit/framework.lua`. Role: library-maintainer. Bump `Kit.VERSION` and release.
- **T1.3 (U-3 / F-008):** WowAddonStandards, an `open-evolutions` proposal. Role: standards-editor. There is no code exit for this one.
- **Done when:** T1.1 is committed and green in LootHistory, and T1.2 is tagged in LibKa0s.
- **Exit for PrettyChat:** a **re-vendor commit** (`/dev-copilot:wow-revendor-libka0s`) that brings the new kit and regenerates `docs/test-cases.md` in the same commit.

## M2: PrettyChat local fixes

| Task | Role | Implements | Files |
|---|---|---|---|
| T2.1 | lua-fixer | C-02 / F-002 | `settings/Schema.lua`, `locales/enUS.lua`, `tests/test_schema.lua`, `docs/test-cases.md`, `README.md` (badge) |
| T2.2 | ux-cleanup | C-03 / F-003 (if accepted) | `settings/Panel.lua`, `locales/enUS.lua`, `tests/test_panel.lua`, `docs/test-cases.md`, `README.md` |
| T2.3 | lua-fixer | C-04 / F-004 | `core/Database.lua`, `tests/test_database.lua`, `docs/test-cases.md`, `README.md` |
| T2.4 | ux-cleanup | C-11 / F-011 (if accepted) | `settings/Slash.lua`, `tests/test_slash.lua`, `docs/test-cases.md`, `README.md` |
| T2.5 | doc-fixer | C-05, C-06 / F-005, F-006 | `docs/data-flow.md`, `settings/Panel.lua` (comments), `modules/Override.lua` (comment), `settings/Schema.lua` (comment) |
| T2.6 | doc-fixer | C-10 / F-010 | `docs/ARCHITECTURE.md`, after T1.1 lands |
| T2.7 | test-author | C-13 / F-013 (if accepted) | `tests/test_envsetup.lua`, `docs/test-cases.md`, `README.md` |

## Concurrency map

- T2.1, T2.2, T2.3, T2.4 and T2.7 all touch `docs/test-cases.md` and the README badge, so they **must be serialized**. Run them in the order T2.1 → T2.3 → T2.2 → T2.4 → T2.7 and regenerate the inventory in each commit.
- T2.1 and T2.5 both touch `settings/Schema.lua`, and T2.2 and T2.5 both touch `settings/Panel.lua`, so T2.5 goes last.
- T2.1 and T2.2 both touch `locales/enUS.lua`, which the serialization above already covers.
- The M1 tasks are in other repos and are **parallelizable** with M2.
- T2.6 depends on T1.1, because the line numbers move.

## Checkpoints

1. **After M2:** `lua tests/run.lua` shows 0 failed, `luacheck .` shows 0/0, the complexity runner shows no warnings, and the badge equals the inventory's pass count. Push the feature branch only if the owner authorized it.
2. **After the M1 re-vendor:** re-run vendor sync (`diff -rq`) and cross-addon classes 2 and 3 across all 11.
3. **Owner in-client:** `03_SMOKE_TESTS.md`, with U-1 run with LootHistory loaded.

## Commit strategy

One commit per task:

- `PC-REV-02: refuse a blank format at the row gate (F-002)`
- `PC-REV-03: confirm the Categories page reset (F-003)`
- `PC-REV-04: leave a newer schema stamp and its keys untouched (F-004)`
- `PC-REV-05: correct the taint sentence and the report-length figures (F-005, F-006)`
- `PC-REV-10: cite LootHistory's pattern builders by name (F-010)`
- `PC-REV-11: keep General out of /pc test category (F-011)`
- `chore: re-vendor LibKa0s <tag> (kit <rev>; inventory excludes skips)` (U-2 exit)

Each commit ends with the session's attribution trailers.
