# 03 — Decisions: LibKa0s v1.55.0

The owner delegated the Step 6 interview (CP-6). Each decision below is the agent's, made by the
sweep's written rules, and is recorded here as it was made, not batched at the end. Declines are
filed as GitHub issues in this repo with exactly one `state:` and one `severity:` label.

## C-1 `LibKa0s-Schema-1.0`: ADOPT

- **Rule:** CP-6 rule 1. The spec prescribes the delta for this repo (`schema.md:579-587`).
- **Reason:** it closes the duplication `library-stack-§7` promoted (C2-F03). It also puts the
  PC-R-01 gate where every write path crosses it. As a row `validate`, the gate runs for `Set`,
  `ApplyDefault` and both value-bound descriptors. As a wrapper in front of the seam, `ApplyDefault`
  would bypass it (`version-1-docs.md:375-383`).
- **Scope taken, from the spec's delta:** `rows` becomes the descriptor array, with `addRow`
  appending and one `Reindex`. `FindByPath`, `Get`, `Set`, `AllRows`, `ApplyDefault` and
  `CountChangedRows` bind to the instance members under their existing names. `refusedBySignature`
  moves into each `string_format` row's `validate`. Each row's `set` is wrapped in
  `PrettyChat.Batch` where it is built. `announce` carries the re-apply and the panel refresh, and
  `format` is `Schema.FormatValue`. `MASTER_SPEC.defaults` gains `debugConsole = false`, and
  `InstallMasterControls` splices through `AddRows(wired, 1)`. The Options and Slash descriptors
  bind the members as values. A write-completing, log-silent degradation stub goes in the setup
  file.
- **Landed:** commit `e741973`. Gate: 438 passed, 0 failed, 0 skipped, 438 total; lint 0 warnings /
  0 errors in 48 files (both through `ka0s-bounded`).
- **Scope kept as the spec says:** `runValidation` (the per-kind resolver; rows are not
  path-mapped), `RowsByCategory`, `ResolveCategory`, `FormatValue`, the refresher dispatch.
- **Sub-decision, `ResetRows` onto `BulkRun` / `BulkAdd`: NOT NOW.** The spec says this repo "MAY
  replace `NS.Util.RunAct` + local tally with `S.BulkRun`/`S.BulkAdd`" (`schema.md:585`), so
  rule 2 applies. Two reasons to leave it. `ResetRows` counts before-versus-after through
  `differsFromDefault`, and the library's tally is read-back. Both give the same N for these rows,
  but the swap is a second mechanical change inside a commit that already moves the seam. Also,
  `tests/test_override.lua` pins the stopped-line wording and count for both raise points, so the
  swap needs its own characterization pass. Filed as a deferred duplication:
  [#18](https://github.com/tusharsaxena/PrettyChat/issues/18), `state:triaged`, `severity:medium`.
- **Sub-decision, `Validate`:** not wired at runtime, per the spec's "Keep: `runValidation`". JC-13
  asks each adopter to re-measure it to zero, so a suite case pins
  `S.Validate{ types = {bool, string}, pages = {General, Categories} }` at `0, 0, 0`.

## C-2 `LibKa0s-Compat-1.0`: NEVER (`state:will-not-do`, `severity:low`)

- **Rule:** CP-6 rule 2, "never", which is allowed only for a structural misfit the spec or the
  repo's own docs record. `compat.md:545` records it: "PrettyChat [has] no `core/Compat.lua`.
  Re-vendor only."
- **Reason:** the addon reads no spell, specialization or secret value. The grep in
  `02_CANDIDATES.md` C-2 prints nothing, so there is nothing to route through the major.
- **Re-check trigger:** the first spell, specialization or secret-value read in this addon.
- **Filed:** [#16](https://github.com/tusharsaxena/PrettyChat/issues/16), `state:will-not-do`,
  `severity:low`, closed as not planned, like the earlier Pool, Item and Widgets declines
  (#11-#13).

## C-3 `LibKa0s-Bus-1.0`: NEVER (`state:will-not-do`, `severity:low`)

- **Rule:** CP-6 rule 2, "never". The repo's own `docs/ARCHITECTURE.md` `## Message Bus` records
  the misfit, and `bus.md` §1 and §12 omit this repo.
- **Reason:** the addon publishes and receives no message, and AceEvent-3.0 is not vendored.
  `Bus.New` would have no receiver to track and `Catalog` no name to validate.
- **Re-check trigger:** the first `LibStub("AceEvent-3.0")` in this addon, which is the trigger
  `## Message Bus` already names.
- **Filed:** [#17](https://github.com/tusharsaxena/PrettyChat/issues/17), `state:will-not-do`,
  `severity:low`, closed as not planned.

## Not decided here

- **`Kit.prose = { exempt = { "GlobalStrings/" } }` (class B-1).** It is a deviation from
  `localization-§5` and CLAUDE.md reserves it for the owner. Not filed as a decline, because it was
  not declined. It is an open owner decision (Phase 5 OPEN 1).
