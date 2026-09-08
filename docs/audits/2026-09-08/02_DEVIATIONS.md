# 02 — Deviations (Ka0s Pretty Chat)

**Run date:** 2026-09-08
**Audited against:** Ka0s WoW Addon Standard **v2.39.0 (2026-09-07)**
**ID prefix:** `PC-` (stable across runs). New IDs continue from the 2026-09-07 run, which ended at
`PC-70`.
**Previous run:** `docs/audits/2026-09-07/` (against v2.38.0), frozen and untouched.

Sections are cited in the `filename-§N` form. Severity is **impact**, per `AUDIT.md` step 5 — never
rule strength. Every entry that fails a MUST says so in its own row regardless of grade.

## Tally, with its basis stated

- **Headline (root deviations only): 7.**
- **Total including `derived from` dependents: 7.** No dependent rows this run: nothing here follows
  from a single unadopted subsystem, and the one declined subsystem (Perf) is **ratified** and
  therefore not an entry at all.
- By grade: **High 0 · Medium 0 · Low 6 · Info 1.**
- **MUST failures: 6 of the 7** (PC-69, PC-71, PC-72, PC-73, PC-74, PC-75). One is SHOULD-level
  (PC-60). PC-76 is an Info observation and fails no rule — the checkpoint it would fail is
  **release**, and no release has been cut. Counted the same way as the headline — roots only — so a
  Low that fails a MUST is visible as both.

**There are no High or Medium findings.** Nothing in this list is reachable by a player, by their
SavedVariables or by a game session today: the whole set is one TOC annotation SHOULD, one absent
test case, and five documentation/register hygiene items. `luacheck .` and the headless suite are
both green with the test tree in scope, both vendored-payload diffs are empty against the tag
`CLAUDE.md` names, `lizard` reports zero functions over CCN 15, and the working tree agrees with the
declared line-ending pin exactly.

**Versus 2026-09-07: 11 → 7.** Nine of that run's eleven closed; two carry forward (PC-60 in
narrowed form, PC-69 deferred by plan); five are new, four of which are register/doc hygiene the
amended rules made visible.

## ID map for the consolidated digest

| Bundle ID | Digest ID | Bundle ID | Digest ID |
|---|---|---|---|
| PC-60 | PRETTYCHAT-A-01 (carried, narrowed) | PC-73 | PRETTYCHAT-B-03 |
| PC-69 | PRETTYCHAT-A-10 (carried) | PC-74 | PRETTYCHAT-B-04 |
| PC-71 | PRETTYCHAT-B-01 | PC-75 | PRETTYCHAT-B-05 |
| PC-72 | PRETTYCHAT-B-02 | PC-76 | PRETTYCHAT-B-06 |

---

## Deviations

| ID | Section(s) | Level | Grade | Deviation | Fix direction |
|---|---|---|---|---|---|
| **PC-60** | `toc-file-§5` | SHOULD | Low | **Carried from 2026-09-07 in narrowed form — the MUST half is closed.** All four load-bearing positions now carry an at-line comment naming what resolves (`PrettyChat.toc:28-32`, `:34-35`, `:40-42`, `:60-63`), so `toc-file-§5`'s MUST passes against its own denominator. What remains is the per-group **SHOULD**: three of the six `#` groups say nothing about being conventional. `# Locales` (`:24`) does it right — *"locale table — no earlier-load dependency"*. `# Core` (`:27`) says only *"the LibKa0s seams load first"*, `# Modules` (`:53`) says only *"the override pipeline"*, and `# Settings` (`:56`) says *"depend on everything else being initialized"*, which is the weaker *order matters* form the rule names explicitly. `# Defaults` (`:49`) states a real constraint rather than freedom. Per `toc-file-§5`'s own grading this is **one SHOULD row for the file**, never one per line. This half was never in `M4-12`'s scope, whose acceptance criterion was *"files no per-line `toc-file-§5` MUST row"*. | Add one *conventional* note per group to `# Core`, `# Modules` and `# Settings`, in the shape `# Locales` already uses — saying which lines in the group are free to move and why, once. Pure comment change, no reordering, no MUST at stake. |
| **PC-69** | `options-ui-§13` (Testing MUST), `testing-§12` | **MUST** | Low | **Carried from 2026-09-07, and deferred on purpose** — `05_TRACEABILITY.md` maps `PRETTYCHAT-A-10` to `M1-LK-08`, disposition **deferred**, one of four repositories in the same position. No suite case pins the tab strip's geometry as **selection-invariant**, and the addon's `Categories` page has eight tabs (`settings/Panel.lua:618`) and is exactly the page that wraps first. The kit has since gained the capability the case needs — `tests/_kit/mock_base.lua:132` now reads `function f:GetHeight() return (self.__geomLive and self.__geomH) or 0 end`, so a frame *can* answer a real height — but nothing in `tests/` asserts the reserved band or any row's y offset across selections. Latent: the library's own measurement is correct today, so no player sees anything. | Add the case `options-ui-§13` names — assert the reserved band height **and every row's y offset** are identical for every value of the selection — and give atlas-bearing textures per-atlas heights through `tests/wow_mock.lua`'s extender so the case is falsifiable. Name the mutation it dies under. `tests/_kit/` is not edited. |
| **PC-71** | `documentation-§3` | **MUST** | Low | Two `.md` files under `docs/` appear in **no** table of `## Documentation map`: `docs/revendor/2026-08-25/01_DELTA.md` and `docs/revendor/2026-08-25/05_SUMMARY.md`. `documentation-§3` MUSTs that *"Every `.md` under `docs/` appears in exactly one of its four tables"*, and its out-of-scope carve-out is an **enumerated** list — `docs/audits/`, `docs/reviews/`, `docs/automated-tests/<run>/`, `docs/perf-analysis/<run>/`, `docs/superpowers/`, `docs/investigations/`. `docs/revendor/` is not on it. The hub names the directory anyway at `docs/ARCHITECTURE.md:167`, which is the right instinct — enumerating a row per re-vendor is exactly what the carve-out forbids — but the standard does not currently sanction it, so the two files are formally orphans. Doc-only; no reader is misled and no player can reach a table. | Raise upstream that `documentation-§3`'s out-of-scope list should carry `docs/revendor/` beside `docs/audits/` and `docs/reviews/` — a frozen dated bundle of exactly the same kind. Do **not** add two rows to the map: that is the growth the carve-out exists to prevent. Until the list changes, the hub's line at `:167` is the honest local answer and stays. |
| **PC-72** | `documentation-§5` | **MUST** | Low | Root `CLAUDE.md:36` is stale in three independent ways, and each is a claim a reader would act on. (1) It says the register carries *"the re-check trigger for each of the **eleven**"* — the register has **nine** active rows (`docs/ARCHITECTURE.md:228-236`). (2) Its enumeration names *"the TOC section order"* and *"the two Ace libs this addon does not vendor"*, both of which were **retired on 2026-09-08** and now sit in the retired block at `docs/ARCHITECTURE.md:238-264`; a reader following that sentence looks for two rows that are gone. (3) It points at `docs/audits/2026-08-05/` as *"the most recent compliance audit"* (*"audited against Standard **v2.21.0**"*) and `docs/reviews/2026-08-05/` as the most recent review, while `docs/audits/2026-09-07/` and `docs/reviews/2026-09-07/` both exist and this bundle makes a third. `documentation-§5` MUSTs the doc set be kept in sync; the line moved out of sync in the same cycle that retired the rows. | Rewrite `CLAUDE.md:36`: count the register rows rather than restating a number, drop the two retired subjects from the enumeration, and repoint the audit and review links at `docs/audits/2026-09-08/` and `docs/reviews/2026-09-07/` with the standard version each was measured against. One line. |
| **PC-73** | `documentation-§3`, `audit-review-history`, `toc-file-§1` | **MUST** | Low | The `toc-file-§1` register row (`docs/ARCHITECTURE.md:230`) records **two** things and one of them is not a deviation. Its *What differs* cell ends *"and `## X-Wago-ID` is absent"*, and its *Why* cell asserts *"`toc-file-§1` asks for both distribution ids once an addon is published anywhere"*. The rule says the opposite: *"`X-Wago-ID` and `X-WoWI-ID` are **optional** (**MAY**) — include each only when the addon is actually listed on that platform … an addon that doesn't publish there simply omits the line."* PrettyChat is not on Wago, so omitting the field is **compliant outright**, not a ratified departure. `documentation-§3`'s **MUST NOT be a graveyard** rule and `audit-review-history`'s second MUST both require an entry whose cited rule permits the behavior to be **retired** and the finding **reported**. The row's other half — the rainbow `## Title:` and stylized `## Author:` brand mark — is a genuine deviation and survives. The re-check trigger is also half-dead: *"The addon being listed on Wago (which re-arms `X-Wago-ID` immediately)"* is the trigger for a row that should not exist. Doc-only; the TOC itself is correct and needs no edit. | Narrow the row to the brand mark alone: strike *"and `## X-Wago-ID` is absent"* from *What differs*, strike the Wago sentence from *Why*, and reduce the trigger to *"a decision to retire the brand mark"*. Note the narrowing in the retired block the way the two 2026-09-08 retirements already are. Do **not** touch `PrettyChat.toc`, and do **not** close issue #7 differently — it is correctly `state:will-not-do`. |
| **PC-74** | `documentation-§5` | **MUST** | Low | `docs/ARCHITECTURE.md:341` carries a second, unmandated doc inventory — `## Doc index`, a 13-row *Topic \| File* table — beside the mandated `## Documentation map` at `:164`. Two inventories of one doc set is one more place to go stale, and it already has: the map registers 20 documents, the index lists 12 of them plus `../DEPENDENCIES.md`, and it is **missing `test-cases.md` and `automated-tests/README.md`** — two of the six rows `documentation-§3` makes mandatory in every addon in every state. Nothing gates it, because the gate `tests/test_doc_structure.lua` checks the map. `documentation-§5` MUSTs the doc set be kept in sync. Doc-only, and the map beside it is correct, so the worst outcome is a reader who does not find a page. | Delete `## Doc index` and fold its one genuinely unique row — the `../DEPENDENCIES.md` pointer, which is not a `docs/` file and so has no place in the map — into `CLAUDE.md`'s docs pointer list, where `documentation-§2` item 4 already puts that kind of signpost. Keeping it and re-syncing it is the worse fix: it recreates the drift on the next doc added. |
| **PC-75** | `localization-§5` | **MUST** | Low | **49 British spellings across 19 authored files**, measured with the `BRITISH` / `ALLOWED` lists v2.39.0 published for exactly this purpose — the whole lists, unmodified, `ALLOWED` removed as whole words first. By word: `colour` ×30, `honour` ×9, `behaviour` ×4, `modelled` ×2, and one each of `neighbour`, `licence`, `labelled`, `acknowledgement`. `localization-§5` binds **code comments and identifiers** and **prose in `docs/`**, not only player-facing text, so all 49 are in scope: e.g. `settings/Schema.lua:72` *"which honours all four modes"*, `modules/Override.lua:41` *"canonical modes are honoured by"*, `core/PrettyChat.lua:102` *"behaviour owed to the second"*, `settings/Panel.lua:465` *"a column of coloured text"*, `.luacheckrc:167` *"not for one stored colour"*. The two densest sites are `tests/test_locale.lua` (16) and `tests/test_schema.lua` (7); `tests/test_locale.lua` alone carries eleven instances of a residue-taxonomy class literally named `SPLIT COLOUR`. **No player-visible string is affected** — `locales/enUS.lua` is clean and no quoted string in the shipped source matches — which is why this is Low and not Medium. The repo has **no** `localization-§5` gate: `grep -rn 'BRITISH\|ALLOWED' tests/*.lua` returns only an unrelated history-heading list at `tests/test_doc_structure.lua:63`. | Two steps, in this order. (1) Sweep the 49, one commit, comments and prose only — the `SPLIT COLOUR` taxonomy class in `tests/test_locale.lua` is a rename of a local literal and accounts for eleven of them by itself. (2) Add the gate, because the collection has already proved a swept repo drifts back: `M4-13` swept KickCD clean and five later items in the same cycle put seventeen back, none of them about spelling. Copy `localization-§5`'s two lists **whole** into a case that scans the tracked authored set — `git ls-files` minus `libs/`, `tests/_kit/`, `GlobalStrings/`, `media/` and the frozen `docs/` bundles — and fail on any hit. A private subset is the failure mode the amendment was written to end. |
| **PC-76** | `automated-tests-§4`, anti-pattern #51 | — | Info | The newest run bundle, `docs/automated-tests/20260908-181425/`, is stamped at commit `4feceda` on `feat/2026-09-07-audit-review-remediation`, **two commits behind `master`** (`0d3edac` *M4c-06*, then the merge `8c06d55`). Its figures no longer match the tree: recorded 323/0/323 tests over 43 lint files, 688 functions, 52,962 NLOC (`docs/automated-tests/RESULTS.md:26`, `:63`); measured today 328/0/328 over 44 files, 694 functions, 53,171 NLOC. The drift is entirely `M4c-06`, which removed the blanket luacheck ignore and edited eleven files. **This is not a MUST failure and is not filed as one:** the checkpoint is **release**, no release has been cut since (`manifest.json` reads `"release": null`, version still 1.4.0), and both figures report zero CCN > 15 and zero lint findings, so nothing the record asserts is *wrong* — only older than the tree. Recorded so the next release run is not surprised by a +6-function, +209-NLOC delta it did not cause. The 2026-09-07 `PC-65` — the genuinely stale, hand-edited standing sections — is **closed**: `RESULTS.md` is now regenerated whole and its watch list is the runner's. | Nothing to fix now. Re-run `tests/_kit/run-automated-tests.sh` as part of the release run for 1.4.1 and let it overwrite `RESULTS.md` in place, per `automated-tests-§4`'s one boundary. Do not hand-edit the numbers. |

---

## Recorded deviations — accepted, not counted

Each matches a **ratified** row in `docs/ARCHITECTURE.md`'s `## Documented deviations`. Per
`AUDIT.md` step 4 they are recorded as accepted, cite the row's rule and Decided date, and **do not
count** toward the headline tally or the MUST count. Every row's **re-check trigger was evaluated
against the tree in front of me** (`audit-review-history`'s third MUST) and **none has fired**.
Nothing found this run is new evidence that any of the reasoning is now wrong — except the Wago half
of the `toc-file-§1` row, which is filed above as PC-73 precisely because it is.

| Rule | Row | Decided | Trigger evaluated today |
|---|---|---|---|
| `performance-§12` | `:228` — no perf harness wired | 2026-08-05, re-checked 2026-09-02 and 2026-09-08 | **Not fired.** The sweep returns exactly two hits and neither runs during combat: `modules/Override.lua:93` registers `PLAYER_REGEN_*` only while `General.visibility` is `inCombat`/`outOfCombat`, at the boundary; `settings/Panel.lua:534` is one guarded `C_Timer.After(0, …)` on the options render path. No `OnUpdate`, no repeating ticker. |
| `layout-§2` | `:229` — `GlobalStrings/` root folder | 2026-08-05, cap half retired 2026-09-08 | **Not fired.** `layout-§2` still MUSTs lowercase subfolders and the folder has not moved under `tests/`. The cap half is correctly gone: v2.39.0's generated-data carve-out covers the 23,842-line dump and `tests/test_layout_cap.lua:348` re-checks all three conditions every run. |
| `toc-file-§1` | `:230` — branded `## Title:`/`## Author:`, no `## X-Wago-ID` | 2026-07-12 | **Half of it should never have been a row** — see PC-73. The brand-mark half stands and its trigger has not fired. Issue #7 remains correctly `state:will-not-do`. |
| `debug-logging-§2` | `:231` — console font not LSM-registered | 2026-08-24 | **Not fired.** `core/MediaSetup.lua:99` calls `Media.RegisterLSM(addonName)`; it returns `0, 0` because LSM is not vendored, and no media picker has appeared to justify vendoring it. |
| `options-ui-§6` | `:232` — TreeGroup pane instead of the 50/50 grid | 2026-07-31, re-shaped 2026-09-03 | **Not fired.** The vendored v1.27.0 payload still offers only `HALF` — `libs/LibKa0s/OptionsWidgets.lua:59` is `local HALF = 0.5` and `RenderGrid` (`:1820`) has no third ratio. |
| `options-ui-§13` | `:233` — vertical string list inside a category tab | 2026-09-03 | **Not fired.** v2.39.0's `§13` still names a *secondary strip*. The three properties it protects all hold: inside the scroll, session-only per primary tab (`ctx.activeSubTab`, `settings/Panel.lua:376-381`), no third level. |
| `testing-§1` | `:234` — `tests/loader.lua` survives beside the kit's | 2026-08-02 | **Not fired.** `tests/_kit/loader.lua:30-32` still says isolation comes from re-running chunks under a new mock; there is no isolated-environment mode. |
| `localization-§1` | `:235` — English only | 2026-08-05 | **Not fired.** `locales/` holds `enUS.lua` alone. `localization-§3` makes this a **terminal compliant state** once registered, and the routing SHOULD is explicitly **not** re-filed. Note this is a different rule from `localization-§5`, which PC-75 files. |
| `options-ui-§15` | `:236` — `Test` beside `Reset all settings` | 2026-09-02, moved into the library 2026-09-03 | **Not fired.** `§15` still names no place for a host-owned page-wide act. `Test` is the composer's `leadButton` (`settings/Schema.lua:116-120`), so the reset's mandated wording still has exactly one writer. |

**Retired rows confirmed retired.** `docs/ARCHITECTURE.md:238-264` records two retirements dated
2026-09-08 — the `toc-file-§5` section-order row (closing 2026-09-07's `PC-61`) and the
`library-stack-§1` AceEvent/AceTimer row (closing `PC-52`). Both are correct against v2.39.0:
`layout.md` and `toc-file.md` now state one identical section order, and `library-stack-§1`'s table
reads *mandatory when used*.

## Closed since 2026-09-07

| ID | Why it is closed |
|---|---|
| **PC-60** (MUST half) | All four load-bearing TOC positions are annotated at the line. `M4-12`. The SHOULD half survives above under the same id. |
| **PC-61** | Retired as a register row on 2026-09-08 (`docs/ARCHITECTURE.md:238-249`), citing the resolved `WowAddonStandards#2`. The TOC order is now mandated by `layout-§1` and `toc-file-§5` alike. |
| **PC-62** | Retired at intake by this cycle's triage (`01_CONSOLIDATED_FINDINGS.md:829`): `## Message Bus` at `docs/ARCHITECTURE.md:125` is accurate, and the combat watcher is already carried by the `performance-§12` row. Not re-filed. |
| **PC-63** | `.pkgmeta:25` now carries `- .claude`, with the justification comment at `:18-24`; `.pkgmeta:15` carries its own row. The dot-entry sweep now prints only `.git`. `M2-19`. |
| **PC-64** | `core/CoreSetup.lua:94` publishes `function NS.MakeCloseButton() return nil end` inside the library-absent branch, above the `return` at `:95`. `M2-03`. |
| **PC-65** | `docs/automated-tests/RESULTS.md` is regenerated whole by the runner and its standing sections match its own newest row. `M5-01`. The residual two-commit lag is PC-76, an Info observation, not this. |
| **PC-66** | The `line-endings-§7` working-tree check now prints **0**. `.gitattributes` is byte-identical to the canonical client-bound body and the vendored gate `tests/_kit/test_eol.lua` reports green. `M4-10`. |
| **PC-67** | `README.md:44-47` is the page-granular table alone; the eight-row per-tab table is gone. `M5-03`. |
| **PC-68** | Closed **by rule change**: `documentation-§3` now MUSTs `### Verification and record` as the fourth table, which is the shape this repo already shipped. `M1-STD-03`. No file moved. |
| **PC-70** | `CLAUDE.md:5-7` carries the standalone adherence line as item 2, above `## Standards compliance (read first)`. `M5-03`. |
