# 02 — Candidates: LibKa0s v1.58.0 -> v1.60.0

Sources: `git -C ../LibKa0s log --oneline v1.58.0..v1.60.0`, the `CHANGELOG.md` blocks for v1.59.0
and v1.60.0, and the `Since` rows of `docs/api/DebugLog/version-14.1-docs.md`,
`docs/api/Slash/version-16-docs.md` and `docs/api/Widgets/version-10.3-docs.md`. The contract churn
in `01_DELTA.md` 3g is not a candidate; it rides in the copy commit.

## A. Delivered on the re-vendor alone

- **`diagnostics` in the Slash live set** (Slash 16, `version-16-docs.md:50`). This addon passes no
  `liveVerbs`, so once it registers the verb, `/pc diagnostics` answers while disabled with no host
  edit.
- **The 3000-line console** (DebugLog 14, `version-14.1-docs.md:463`). The window's
  `SetMaxLines`, the copy window and the counter all read `lib.MAX_BUFFER`.
- **`lib.TIME_COPY`**, the copy-timing switch, off by default (DebugLog 14).

## B. Host change required

| Candidate | Evidence | Touches | Blast radius | Recommendation |
|---|---|---|---|---|
| The diagnostics report: `D:RunDiagnostics`, `D:DebugVerb`, the `brandName` and `diagnostics` descriptor fields, `out:escape` for format strings | `CHANGELOG.md` v1.60.0 "DebugLogDiagnostics minor 1"; `version-14.1-docs.md:58-124` | `core/DebugLogSetup.lua`, a new `modules/Diagnostics.lua`, `settings/Slash.lua`, `tests/run.lua` (`Kit.diagnostics`) | Additive | **Adopt, in DR-PC-03** (the rollout plan decides it: `debug-logging-§14` makes it a MUST) |
| Slash 16's `diagnostics` verb registered in `COMMANDS` | `version-16-docs.md:39-61` | `settings/Slash.lua` | Additive | **Adopt, in DR-PC-03**, with the report |

## C. Whole-module adoption

- **WidgetsDragHandle minor 3, the close mark** (v1.59.0, `CHANGELOG.md` v1.59.0 block;
  `docs/api/Widgets/version-10.3-docs.md`). This addon is frameless and looks up no Widgets major,
  so it has no drag handle for an X to sit on. **Not a candidate here** (rollout plan, M3: the X is
  adopted by ConsumableMaster and AbsorbTracker only).

The buffer change is not an adoption; it is class A.
