# 02 — Candidates: LibKa0s v1.55.0

Run: 2026-09-23, Step 5 of `/wow-addon:revendor-libka0s`, taken by a workflow subagent in Phase 6 of
the suite standards sweep. The interview of Step 6 is replaced by the owner's delegation (CP-6): the
agent decides by the sweep's written rules and records each decision in `03_DECISIONS.md`.
Branch `suite/2026-09-22-standards-sweep` @ `365e3be` (the re-vendor commit, `01_DELTA.md`).

## Sources read, in the playbook's order

1. `git -C ../LibKa0s log --oneline v1.54.2..v1.55.0`: 8 commits. The list is in `01_DELTA.md`.
2. `../LibKa0s/CHANGELOG.md`, the `## v1.55.0` block (lines 1-504 of that block as extracted with
   `awk '/^## v1.55.0/{f=1} /^## v1.54.2/{f=0} f'`).
3. The API documents of the three new majors: `../LibKa0s/docs/api/Compat/version-1-docs.md`,
   `../LibKa0s/docs/api/Bus/version-1-docs.md` and `../LibKa0s/docs/api/Schema/version-1-docs.md`.
   No existing major's minor moved (`01_DELTA.md` 3c), so no `Since` diff applies to them.
4. The candidate source named by the sweep: the three design specs' per-consumer adoption deltas,
   `Ka0sAddonsCommonTasks/docs/2026-09-22-SUITE_STANDARDS_AND_LIBKA0S_SWEEP/3b-specs/`
   `compat.md` §8 (lines 429-547), `bus.md` §12 (lines 538-642) and `schema.md` §11 (lines 465-600),
   each with its "every consumer" common block.

## Class A: delivered on the re-vendor, not offered

| Item | Evidence | Where it landed |
|---|---|---|
| Kit revision 25's cap gate `tests/_kit/test_layout_cap.lua` | CHANGELOG v1.55.0 "`test_layout_cap.lua` — the cap gate, in the kit" | Wired in `365e3be` with `Kit.layoutCap = { exempt = { "GlobalStrings/" } }` |
| Suite declaration keyed by (basename, directory) | CHANGELOG "The declaration is the pair" | `365e3be` wired `test_layout_cap` and `test_prose` in pair form and deleted the two shadowing local files |
| `test_eol`'s second case (the `.gitattributes` body) | CHANGELOG "`test_eol.lua` — a second case" | Green at `365e3be` with no host change: "Nothing is owed for `test_eol`'s second case" |
| The automated-test runner's `Commit` and `Tree` cells | CHANGELOG "The automated-test runner names the commit" | Runner-side only. No host change. |

## Class B: host change on a surface this addon already consumes

| # | Candidate | Evidence | Status |
|---|---|---|---|
| B-1 | `Kit.prose = { exempt = { "GlobalStrings/" } }` in place of the per-word waivers in `tests/prose_waivers.lua` | CHANGELOG v1.55.0 lines 204-212 (the carve-out) and 333-338 ("a documented deviation until the standard says otherwise"); standard v2.64.0 `localization.md:263-289` ("A whole-file waiver is forbidden") | **Not a candidate this run can decide.** Taking it deviates from `localization-§5`, and CLAUDE.md requires such a change to go to the owner. It is carried as Phase 5's OPEN 1 and repeated in `05_SUMMARY.md`. |

## Class C: majors this addon does not consume (`01_DELTA.md` 3e)

### C-1 `LibKa0s-Schema-1.0`: the settings schema's runtime, adopted as a seam adopter

- **What:** the row registry, the single write seam `Set`, `ApplyDefault`, the profile-reset count
  and the degradation-stub contract, replacing the host-owned copies in `settings/Schema.lua`.
- **Evidence:** spec `schema.md:579-587` names this repo as a seam adopter with no `resolveRoot`
  ("every row is closure-backed"), at file:line: `settings/Schema.lua:43-49` (`rows` / `byPath` /
  `addRow`), `:479-481` (`FindByPath`), `:523-527` (`Get`), `:636-670` (`Set`), `:620-629`
  (`refusedBySignature` into `validate`), `:676-678` (`AllRows`), `:690-693` (`ApplyDefault`),
  `:104-107` (`MASTER_SPEC.defaults` gains `debugConsole = false`, JC-5), `:715-721`
  (`CountChangedRows`), `:495-521` (`InstallMasterControls`), `:744-780` (`ResetRows`, which MAY
  move to `BulkRun`). The library contract is `docs/api/Schema/version-1-docs.md:115-169` (instance
  surface and the `Set` pipeline), `:284-373` (the degradation stub and how a host pins it),
  `:375-383` (a gate in front of the seam) and `:385-406` (adoption notes).
- **Files it touches:** `settings/Schema.lua`, `settings/OptionsSetup.lua` (descriptor members and
  the degraded composer's console default), `settings/Slash.lua` (descriptor members),
  `modules/Override.lua` (a comment naming `Batch`'s callers), `tests/test_schema.lua`,
  `tests/test_surface_parity.lua`, `docs/ARCHITECTURE.md`, `docs/schema.md`.
- **Recommendation: adopt.** The spec prescribes it for this repo. The adoption moves the
  PC-R-01 conversion-signature gate from a wrapper in front of the seam into each format row's
  `validate`. After that, `ApplyDefault` and every value-bound descriptor cross the gate too. Today
  `ApplyDefault` reaches the gate only because it calls the host's own `Set`. The spec calls the
  bypass "latent, not live" once the gate is a wrapper (`schema.md:582`).
- **Blast radius: replacing.** It deletes the host-owned index, the `Get` / `Set` / `ApplyDefault`
  / `CountChangedRows` bodies and the head splice, and rewires what survives onto an instance.
  Behavior changes the spec prescribes on purpose: the `[Set]` line is written before the re-apply
  rather than after (JC-4); the console row declares `default = false` rather than none (JC-5); a
  refused `Set` answers `false, err, why` rather than `false`; and duplicate paths resolve
  first-wins (JC-7). No row path in this schema is duplicated, so the last is unreachable.
- **Rule-4 class:** closes a recorded gap: the duplication `library-stack-§7` promoted, harvest
  finding C2-F03.

### C-2 `LibKa0s-Compat-1.0`: the version-variant readers and the secret seam

- **What:** nine stateless members: `IsSecret`, `CanAccess`, `IsSafeKey`, and the spell and
  specialization readers.
- **Evidence:** spec `compat.md:542-545`: "AbsorbTracker and PrettyChat have no
  `core/Compat.lua`. Re-vendor only (8.0)." `compat.md:582-584` (OPEN-5) records the missing
  shim. This repo has no call site for any member:
  `git ls-files '*.lua' | grep -v -e '^libs/' -e '^tests/' -e '^GlobalStrings/' | xargs grep -n -e GetSpellInfo -e C_Spell -e GetSpecialization -e issecret -e canaccess -e C_SpecializationInfo -e GetSpellCooldown -e GetSpellTexture`
  prints nothing. The addon rewrites Blizzard's loot, currency and XP format strings and reads no
  spell, specialization or combat value.
- **Files it would touch:** none. There is no call site to route through it.
- **Recommendation: never (`state:will-not-do`, `severity:low`).** It is a structural misfit that
  the spec itself records. Re-check trigger: the first spell, specialization or secret-value read in
  this addon.
- **Blast radius:** none, because nothing would change.

### C-3 `LibKa0s-Bus-1.0`: the stand-down record and the message catalog

- **What:** `New` (tracked receivers, `StandDown` / `StandUp`) and `Catalog` (validated
  `Ka0s_<Addon>_<Event>` names).
- **Evidence:** spec `bus.md:41-59` lists nine homes and this repo is not one of them. `bus.md:538-642`
  (§12) gives no delta for it. `docs/ARCHITECTURE.md` `## Message Bus` records "There is none,
  because this addon publishes no named message": zero `SendMessage`, zero `RegisterMessage`, zero
  `AceEvent`, and AceEvent-3.0 deliberately not vendored. That section names its own re-check trigger:
  "the first `LibStub("AceEvent-3.0")` in this addon". `tests/test_disabled.lua`'s header records
  that the addon "registers no message and no bucket".
- **Files it would touch:** none.
- **Recommendation: never (`state:will-not-do`, `severity:low`).** It is a structural misfit that the
  repo's own docs record. Re-check trigger: as above.
- **Blast radius:** none.

## Order for Step 6 (rule 4)

No candidate fixes a live defect. C-1 closes a recorded gap. C-2 and C-3 are new capability with no
consumer. So the order is C-1, then C-2, then C-3 (both zero radius).
