# 05 — Summary: LibKa0s v1.54.2 → v1.55.0

Steps 2–4 (the copy) ran in Phase 5 (`01_DELTA.md`, commit `365e3be`). Steps 5–8 ran in Phase 6,
taken by a workflow subagent under the owner's CP-6 delegation.
Branch `suite/2026-09-22-standards-sweep`. Nothing pushed. The addon version is not bumped.

## The tag, and the per-file minors

`v1.54.2` → `v1.55.0` (tag object `bb161b7`, commit `6f9c5e0`). No existing file's LibStub minor
moved. The three new files are `Compat.lua` (Compat 1), `Bus.lua` (Bus 1) and `Schema.lua`
(Schema 1), plus their three `LibKa0s.xml` rows. The kit revision went from 24 to 25. Table and
diffs are in `01_DELTA.md` 3c-3f.

## Delivered on the re-vendor (class A)

- the kit's layout-§1 cap gate, wired with `Kit.layoutCap = { exempt = { "GlobalStrings/" } }`
- suite declaration by (basename, directory); the two shadowing local suites were retired
- `test_eol`'s `.gitattributes` body case
- the automated-test runner's `Commit` / `Tree` cells

All of these landed in `365e3be` (`02_CANDIDATES.md`, class A).

## Contract blockers

Library side: none (`01_DELTA.md` 3g). Kit side: three, all resolved in the re-vendor commit
`365e3be`: pair-keyed suites, the prose gate reaching `GlobalStrings/`, and the cap gate's exempt
set.

## Adopted

| Candidate | Commit | Tests added |
|---|---|---|
| C-1 `LibKa0s-Schema-1.0`, seam adopter | `e741973` | Eleven characterization cases in `tests/test_schema.lua`, written and green before the code moved (434 / 0 / 0 at `365e3be`). Three post-adoption cases in `tests/test_schema.lua`: host names are the members, `Validate` at 0/0/0, `[Set]` before the re-apply. One parity case in `tests/test_surface_parity.lua` covering the stub instance against the live instance, and the stub library against the major by name. |

What the adoption changed on purpose, each change prescribed by the spec (`schema.md` §7 and §11):

- **JC-4.** The `[Set]` line is written before the re-apply instead of after it.
- **JC-5.** The console row's `default` is `false` instead of nil. The reset still closes the window.
- **Arity.** A refused `Set` answers `false, err[, why]` instead of `false`. No caller reads past the
  first value.
- **The gate.** The PC-R-01 check now runs as the format row's `validate`, so `ApplyDefault` and
  the value-bound descriptors cross it too.

Pinned as unchanged: the store and its clear-to-absence, 1 pass and 1 refresh per write, the
`[Set]` line's text, the `/pc set` refusal (one chat line, nothing stored), `/pc reset` of a format
and of the console row, the reset count, and the two library-absent writers.

## Declined

| Candidate | Issue | State | Severity | Why |
|---|---|---|---|---|
| C-2 `LibKa0s-Compat-1.0` | [#16](https://github.com/tusharsaxena/PrettyChat/issues/16) | `state:will-not-do` (closed) | `severity:low` | No spell, specialization or secret-value read anywhere in the addon (`compat.md:545`) |
| C-3 `LibKa0s-Bus-1.0` | [#17](https://github.com/tusharsaxena/PrettyChat/issues/17) | `state:will-not-do` (closed) | `severity:low` | The addon publishes and receives no message, and AceEvent is not vendored (`## Message Bus`) |
| C-1 sub-item: `ResetRows` onto `BulkRun` / `BulkAdd` | [#18](https://github.com/tusharsaxena/PrettyChat/issues/18) | `state:triaged` | `severity:medium` | The spec says MAY. It needs its own characterization pass over `test_override.lua`'s bulk-line pins |

## Skipped or unreached

- **`Kit.prose = { exempt = { "GlobalStrings/" } }` (B-1).** Unreached, because it is the owner's
  call. It deviates from `localization-§5` (standard v2.64.0 forbids a whole-file waiver), so the
  per-word waivers in `tests/prose_waivers.lua` stay. The owner has two ways to change that: ratify
  a row keyed `localization-§5`, or amend §5 upstream.
- **Perf re-run.** Skipped, because this repo has no `tests/perf.lua` (its `performance-§12`
  exemption).
- **lizard.** Run on the touched setup files with
  `ka0s-bounded lizard -C 15 -w settings/Schema.lua settings/OptionsSetup.lua settings/Slash.lua`.
  It printed no warnings. The full automated-test battery was not run.

## Gates

| Point | `ka0s-bounded lua tests/run.lua` | `ka0s-bounded` lint |
|---|---|---|
| Phase 6 start, `365e3be` | 423 passed, 0 failed, 0 skipped, 423 total | 0 warnings / 0 errors in 48 files |
| Characterization cases added, before the code moved | 434 passed, 0 failed, 0 skipped, 434 total | 0 / 0 in 48 files |
| C-1 commit `e741973` | 438 passed, 0 failed, 0 skipped, 438 total | 0 / 0 in 48 files |
| Bundle commit (`docs/test-cases.md` regenerated, badge 438/438) | 438 passed, 0 failed, 0 skipped, 438 total | 0 / 0 in 48 files |

The bundle commit also brings the count of places that append a tail to the shared cause clause, `NS.LIBKA0S_MISSING`, from four to five. The stub's `Validate` line is the fifth. The count is corrected in `docs/ARCHITECTURE.md`, `docs/module-map.md` and `tests/test_locale.lua`, which the adoption commit had left behind.

`settings/Schema.lua` is 998 lines (`wc -l`), still below the 1000-line band layout-§1's census
tracks.

## Open

1. The B-1 owner decision above (Phase 5 OPEN 1). Also the `[upstream]` finding at
   `tests/_kit/test_prose.lua:602-603`, which contradicts `localization-§5`.
2. The in-game smoke owed for the seam move:
   - a panel checkbox and a New-box format edit still write, re-apply and refresh
   - a refused format snaps the New box back
   - the General-page Reset all and `/pc reset state.debugConsole` behave as before
