# 04 — Execution plan

Three commits on `fix/2026-09-12-triage`, each gated by `lua tests/run.lua`, `luacheck .` and
`lizard -l lua -x "./libs/*" -x "./tests/_kit/*" -C 15 -w .`, with CR == LF on every touched file.

## 1. Re-vendor (Step 4)

Both payloads copied whole from `v1.32.0`. The CLAUDE.md provenance line and the ARCHITECTURE.md
external-dependencies reference roll in the same commit, with `01_DELTA.md`.

## 2. `RunMigrations` under the complexity gate

`cbf9775`, earlier on this branch, took `Database.RunMigrations` to CCN 16. The pending-step loop moves
into a named local, `runSteps(db, from)`, unchanged. This is a mechanical move with no behaviour
change. The existing `test_database.lua` cases cover both halves (the step loop, and the stamp plus
repair).

## 3. debug-logging-§10 in PrettyChat's own resets (tests first)

The standard's rule: a bulk reset is ONE `[Set] <act> <scope>: N rows` line, N = the rows actually
changed, no per-row `[Set]` line. A profile reset or copy is one line from the profile-event handler,
worded by the event, and nothing else logs it.

**Characterization / red first.** These cases were written before the code, and all failed against it
(336 passed, 9 failed):

| Suite | Case | Assertion that proves it |
|---|---|---|
| `test_override.lua` | ResetCategory: one pass, one [Set] reset line counting the rows written | 1 pass, exactly 1 `[Set]` line, 0 `[Reset]`, `[Set] reset Loot: 3 rows` |
| `test_override.lua` | ResetCategory('General'): one pass, one [Set] reset line, the watcher disarmed | `[Set] reset General: 2 rows` |
| `test_override.lua` | ResetString: one pass, one [Set] reset line, both of the string's rows cleared | `[Set] reset Loot.<G>: 2 rows` |
| `test_override.lua` | a reset counts only the rows it changed, and still logs once when none | `: 1 rows` when the enable row was already default; `: 0 rows` on a clean category, still 1 pass |
| `test_debuglog.lua` | ResetAll logs one [Set] reset profile line counting the rows it rewrote | whole buffer is 1 line: `[Set] reset profile 'Default' to defaults (3 rows)` |
| `test_debuglog.lua` | /pc resetall is one debug line in total | 1 line, `(1 rows)` |
| `test_debuglog.lua` | a profile reset AceDB starts on its own is one line, without a count | 1 line ending `to defaults` |
| `test_debuglog.lua` | a profile copy logs one [Set] copied line and nothing else | 1 line, `[Set] copied profile '…' → 'Default'`, the copy landed |
| `test_debuglog.lua` | the copy line names AceDB's source profile and the active one | `[Set] copied profile 'Alt' → 'Default'` from AceDB's real `(event, db, source)` |
| `test_debuglog.lua` | a profile switch keeps its one [Profile] line | 1 line, `[Profile] switched → applied` (this one was already green: the switch line is unchanged) |

**Code:**

- `settings/Schema.lua`: `Schema.ResetRows` counts the rows whose value differs from the default
  before it writes, and logs `[Set] reset <label>: N rows`. It keeps one `ApplyStrings` pass and one
  `NotifyPanelChange`. Add `Schema.CountChangedRows()` (stored rows only; `sessionOnly` skipped).
- `modules/Override.lua`: `PrettyChat:ResetAll` counts first, parks the count on `pendingResetRows`
  around `db:ResetProfile()`, and clears it even if the reset raises.
- `core/PrettyChat.lua`: the three callbacks become `OnProfileChanged` / `OnProfileCopied` /
  `OnProfileReset` methods over one shared `reloadProfile`. Each emits one line worded by the event.

**Docs in the same commit:** `schema.md`, `ARCHITECTURE.md` (the debug-logging-§9 citations that
meant §10, at the write-path paragraph and the trace list), `module-map.md`, `data-flow.md`,
`slash-dispatch.md`, `smoke-tests.md` T-58, plus the regenerated `test-cases.md` and README badge.

**N = 0:** a reset with nothing to change logs `[Set] reset <scope>: 0 rows`, not silence. That is one
line per act, and the standard's correction accepts either as long as the choice is stated.

**Nesting:** none exists here. `ResetAll` never calls `ResetRows`; it is one `db:ResetProfile()`. So
the depth counter the correction describes for nested brackets has nothing to count in PrettyChat.
The "ResetAll is exactly one line in total" cases are the proof.
