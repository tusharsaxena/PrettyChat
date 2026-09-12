# 05 — Summary: PrettyChat re-vendor to LibKa0s v1.32.0, 2026-09-12

## Tag

**v1.31.0 (`e7e1962`) to v1.32.0 (`e18dd12`, a local tag, not pushed).** Both payloads were copied whole
from the tag (`git archive v1.32.0 LibKa0s testkit`). After the copy, all four diffs (library and kit,
content and bytes) are empty. No file was deleted, because no `Only in` line appeared.

| File | Before | After |
|---|---|---|
| `Options.lua` | 15 | **16** |
| `Slash.lua` | 7 | **8** |
| every other file in `LibKa0s.xml` | unchanged | unchanged |
| kit (`tests/_kit/`) | revision 17 | revision 17 (byte-identical) |

## Delivered for free (class A)

The optional `bulkBegin` / `bulkEnd` bracket arrives in Options 16 and Slash 8. PrettyChat supplies
neither field, so the library's `RestoreDefaults`, `RestoreAllDefaults` and `CliResetAll` walks run
exactly as they did at v1.31.0. Nothing in the addon moved on the re-vendor alone.

## Adopted

Nothing from the library. The bracket is not on PrettyChat's live path (`02_CANDIDATES.md` B1).

## Implemented in this run (the rollout's own acts)

| Commit | What |
|---|---|
| `9511b85` | Re-vendor LibKa0s v1.32.0: both payloads, the CLAUDE.md provenance line and the ARCHITECTURE.md reference, and `01_DELTA.md` |
| `1319ed7` | `Database.RunMigrations` back under `lizard -C 15`: the step loop moves into `runSteps(db, from)`. It was CCN 16, introduced by `cbf9775` earlier on this branch. |
| `7299b23` | debug-logging-§10 in PrettyChat's own resets: tests first, code, docs |

Each act now logs exactly one line in total:

| Act | Line |
|---|---|
| Category Defaults / `ResetCategory(cat)` | `[Set] reset <Cat>: N rows` (e.g. `[Set] reset Loot: 3 rows`) |
| General Defaults / `ResetCategory("General")` | `[Set] reset General: N rows` |
| Per-string Reset / `ResetString(cat, G)` | `[Set] reset <Cat>.<G>: N rows` |
| Reset all (popup, `/pc resetall`, degraded stub) / `ResetAll()` | `[Set] reset profile 'Default' to defaults (N rows)`, from `OnProfileReset` |
| A profile reset AceDB starts on its own | `[Set] reset profile 'Default' to defaults` (count unknown, omitted) |
| Profile copy | `[Set] copied profile 'A' → 'B'`, from `OnProfileCopied` |
| Profile switch (unchanged) | `[Profile] switched → applied N restored M` |

N counts only the rows whose value changed. A reset with nothing to change logs `: 0 rows`.

## Declined, skipped, unreached

- B1 (adopt the descriptor bracket): not adopted because it is not on the path. It is recorded here
  only: the rollout spec says not to file issues.
- No interview was held. The run was non-interactive, with its scope set by the rollout spec.
- Not pushed.

## Upstream finding: the kit's AceDB fake

`tests/_kit/mock_base.lua:1185-1187` fires every profile callback as `cb(event, db, current)`. Real
AceDB fires `OnProfileCopied(event, db, sourceProfileKey)` (`libs/AceDB-3.0/AceDB-3.0.lua:618-619`).
So, headless, a copy handler that reads the source argument sees the **active** profile in the
source's place. PrettyChat's handler follows AceDB's real signature. `test_debuglog.lua` drives it
directly with the real arguments to pin `'Alt' → 'Default'`, and checks only the line's shape end to
end. The fix belongs in `../LibKa0s` `testkit/mock_base.lua` (pass the copy's source name), not here:
`tests/_kit/` is read-only.

## Gates

| Stage | `lua tests/run.lua` | `luacheck .` | `lizard -C 15` |
|---|---|---|---|
| Baseline (before the copy) | 339 / 0 / 0 | 0 / 0 in 44 files | 1 warning (`RunMigrations` CCN 16) |
| After `9511b85` (re-vendor) | 339 / 0 / 0, vendor sync green against v1.32.0 | 0 / 0 | same 1 warning |
| After `1319ed7` | 339 / 0 / 0 | 0 / 0 | clean |
| Tests written, before the code | 336 passed, 9 failed | — | — |
| After `7299b23` | **345 / 0 / 0** | **0 / 0 in 44 files** | **clean** |

Line endings: every touched file is CRLF with CR == LF. `docs/test-cases.md` was regenerated with
`lua tests/run.lua --list` (345), and the README badge reads 345/345.
