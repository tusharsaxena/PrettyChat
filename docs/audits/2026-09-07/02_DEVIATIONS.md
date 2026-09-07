# 02 — Deviations (Ka0s Pretty Chat)

**Run date:** 2026-09-07
**Audited against:** Ka0s WoW Addon Standard **v2.38.0 (2026-09-02)**
**ID prefix:** `PC-` (stable across runs). New IDs continue from the 2026-08-05 run, which ended at
`PC-59`.
**Previous run:** `docs/audits/2026-08-05/` (against v2.21.0).

Sections are cited in the `filename-§N` form. Severity is **impact**, per `AUDIT.md` step 5 — never
rule strength. Every entry that fails a MUST says so in its own row regardless of grade.

## Tally, with its basis stated

- **Headline (root deviations only): 11.**
- **Total including `derived from` dependents: 11.** No dependent rows this run — nothing here
  follows from a single unadopted subsystem, because the only declined subsystem (Perf) is
  **ratified** and therefore not an entry at all.
- By grade: **High 0 · Medium 0 · Low 11 · Info 0.**
- **MUST failures: 9 of the 11** (PC-60, PC-61, PC-62, PC-63, PC-64, PC-65, PC-66, PC-67, PC-68). Two
  are SHOULD-level (PC-69, PC-70). Counted the same way — roots only, dependents excluded — so a Low
  that fails a MUST is visible as both.

**There are no High or Medium findings.** Nothing in this list is reachable by a player, by their
SavedVariables or by a game session today: the whole set is TOC annotation, register hygiene, a
package ignore line, a latent stub member, a stale test record, four un-renormalized files and three
documentation shapes. `luacheck .` and the headless suite are both green, both vendored-payload diffs
are empty, and `lizard` reports zero functions over CCN 15.

## ID map for the consolidated digest

| Bundle ID | Digest ID | Bundle ID | Digest ID |
|---|---|---|---|
| PC-60 | PRETTYCHAT-A-01 | PC-66 | PRETTYCHAT-A-07 |
| PC-61 | PRETTYCHAT-A-02 | PC-67 | PRETTYCHAT-A-08 |
| PC-62 | PRETTYCHAT-A-03 | PC-68 | PRETTYCHAT-A-09 |
| PC-63 | PRETTYCHAT-A-04 | PC-69 | PRETTYCHAT-A-10 |
| PC-64 | PRETTYCHAT-A-05 | PC-70 | PRETTYCHAT-A-11 |
| PC-65 | PRETTYCHAT-A-06 | | |

---

## Deviations

| ID | Section(s) | Level | Grade | Deviation | Fix direction |
|---|---|---|---|---|---|
| **PC-60** | `toc-file-§5` | **MUST** | Low | Three load-bearing TOC positions carry no at-line comment naming what resolves. `PrettyChat.toc:40` (`core\Util.lua`) — `core/Util.lua:14` takes `local Color = NS.Const.Color` at file scope, so the line must sit below `core\Constants.lua`; `PrettyChat.toc:43` (`core\CoreSetup.lua`) — `core/CoreSetup.lua:39` takes `local Util = NS.Util`, and the file also reclaims `NS.Print` after `NewAddon`; `PrettyChat.toc:57` (`settings\Panel.lua`) — `settings/Panel.lua:22` takes `local H = NS.Helpers`, published by `settings\OptionsSetup.lua` two lines above. The `# Settings` header's *"depend on everything else being initialized"* (`:53`) is the weaker *order matters* form the rule names explicitly. Separately, **no** line is marked **conventional** (the SHOULD half). The reasons exist — they are just in the `.lua` files (`core/Util.lua:5`), not in the TOC where the rule puts them. | Add one comment per load-bearing line naming what resolves, in the shape `core\MediaSetup.lua` already uses at `:34-35`; add one *conventional* note per group for the remainder. Pure comment change, no reordering. |
| **PC-61** | `documentation-§3`, `audit-review-history` | **MUST** | Low | The `toc-file-§5` register row (`docs/ARCHITECTURE.md:222`) cites a rule the standard has **since changed**, which `audit-review-history` requires be reported and the row retired. The row records `# Locales` before `# Defaults` as a departure forced by a *standard-internal conflict* between `toc-file-§5` and `layout-§1`. In v2.38.0 there is no conflict: `layout.md:53` states the folder load order `libs/* → locales/* → core/* → defaults/* → modules/* → settings/*`, identical to `toc-file-§5`'s header order, and adds *"if the two ever disagree that is a defect in this document"*. The TOC's actual order (`PrettyChat.toc:15,24,27,46,50,53`) is now **mandated** by both. The row's other half — the `# GlobalStrings` section — is already noted as closed. | Retire the row outright and note the closure (upstream `WowAddonStandards#2` resolved in favor of `toc-file-§5`). Do not re-file the TOC order as anything: it is compliant. |
| **PC-62** | `architecture-§4`, `documentation-§3` | **MUST** | Low | `architecture-§4`'s applicability clause binds *"any module that registers game events"*. Since the settings revamp, `modules/Override.lua:76-96` creates `PrettyChatCombatWatcher` and registers `PLAYER_REGEN_DISABLED` / `PLAYER_REGEN_ENABLED` on it, so the threshold the section names has been crossed — while `docs/ARCHITECTURE.md:123-129` still records the addon as *below* it. There is no bus and **no register row** for the absence. The section's own rationale (the CallbackHandler same-target clobber) still cannot arise with **one** feature module and no second receiver, so the honest reading is that the trigger is over-broad rather than that this addon owes a bus. | Two routes, and the standard prefers the second: (a) file a `## Documented deviations` row against `architecture-§4` recording the single-module rationale, its Decided date and a re-check trigger (the second feature module); or (b) raise upstream that the *"registers game events"* trigger should read *"two or more feature modules, or a module that registers events and a second party to notify"*. Building a one-module bus is the wrong answer. |
| **PC-63** | `packaging` | **MUST** | Low | `.pkgmeta`'s ignore list does not carry `.claude`, so the agent tooling directory is packaged into the AddOn a player installs. Measured with `AUDIT.md`'s dot-entry sweep: `UNACCOUNTED — .claude`, `UNACCOUNTED — .pkgmeta`. `.git` is exempt; `.pkgmeta` is read by the packager and needs at most a justification comment. This is the exact failure the sweep was added for after five addons shipped one. | Add `- .claude` to the ignore list, with the one-line comment the neighbouring entries carry, and either add `- .pkgmeta` or a comment saying why the packager's own manifest is left in. |
| **PC-64** | `performance-§1`, `testing-§8` | **MUST** | Low | The `LibKa0s-Core-1.0` degradation stub does **not** answer `NS.MakeCloseButton`. `core/CoreSetup.lua:84` returns out of the library-absent branch, and the wrapper is published at `:111-113`, below it — so a degraded install has the member as `nil`. The file argues the opposite principle two paragraphs earlier for `NS.Format` (`:74-77`: *"Published on BOTH paths… the first caller added later would work in every install that has the library and be nil in the one this branch exists for"*). The suite cannot see it: `tests/test_libka0s.lua:683-689`'s `coreSurface` projection lists four members and omits `MakeCloseButton`, although its own derivation comment (`:682`) names a grep that would return it. **Latent only** — `docs/ARCHITECTURE.md:80` records that there is no host caller today, which is why this is Low and not Medium. | Publish a degraded `NS.MakeCloseButton` in the stub branch (returning `nil`, exactly as `core/DebugLogSetup.lua:89` already does for its own copy), and add the member to `coreSurface` so the parity case covers it. Alternatively, write the omission down as a decision — but then the parity projection still needs the member with the reason as data, which is the shape that file already uses for its `ignore` lists. |
| **PC-65** | `automated-tests-§1`, `automated-tests-§4`, anti-pattern #51 | **MUST** | Low | `docs/automated-tests/RESULTS.md`'s hand-written standing sections are stale by two increments. They are anchored at run `20260807-114404` — *"260 cases, across 17 suite files"* (`:44`), *"Clean over 17 files"* (`:48`), *"Current state as of `20260807-114404`"* (`:56`), and a watch-list row whose disposition reads *"nothing newly crossed a band at `20260807-114404`"* (`:84`) — while the table's newest row (`:25`) is `20260825-103457` at 271/271 over 18 files, and the tree has changed again since (`92c43f5`, 2026-09-03). Measured today: 300/300 over 18 suite files, `lizard` 645 functions / 52,211 NLOC against the recorded 555 / 51,480. The intro's ANALYSIS.md roll-call (`:7-9`) also predates the 20260825 bundle. The checkpoint is **release**, so this is a record-keeping finding, not a commit-gate one. | Run `tests/_kit/run-automated-tests.sh` to record a current bundle, then rewrite the four standing sections against it. Do not hand-edit the numbers — a generated figure edited by hand reads as measured, which `RESULTS.md:74-79` already says about a different row. |
| **PC-66** | `line-endings-§1`, `line-endings-§7` | **MUST** | Low | **4 tracked files disagree with the declared `* text=auto eol=crlf` pin.** One rolled-up finding, per the playbook — the fix is a single action and enumerating inflates the tally for it. The `.gitattributes` itself is correct and complete (pin at `:26`, `*.sh` carve-out at `:34`, 20 `binary` rows), so this is the correct-config-over-unrenormalized-tree case the check exists to catch. The number is far lower than a pre-v2.28.1 bundle would have reported for this repo; earlier frozen bundles are never edited, so the two figures sit side by side for different commands. | `git add --renormalize .`, then delete and re-check-out the stragglers (`rm <path> && git checkout -- <path>`), then re-run the command in `03_EVIDENCE.md` and confirm it prints `0`. |
| **PC-67** | `documentation-§1` (item 7) | **MUST** | Low | The README carries a **per-tab** breakdown of the Categories page — `README.md:71` *"The **Categories** page carries eight tabs across the top:"* followed by an eight-row Tab table (`:73-82`). `documentation-§1` item 7 puts the README's settings summary at **page** granularity and places the per-tab breakdown in `docs/settings-panel.md`: *"the per-tab breakdown that options-ui-§13's strip makes derivable belongs in `docs/settings-panel.md` … not here."* The page-granularity table above it (`:66-69`) is the compliant half and is correct. | Delete `README.md:71-82` and fold anything it says that `docs/settings-panel.md` does not already carry into that file. Keep the closing paragraph at `:84`, which is player-facing behavior rather than a tab inventory. |
| **PC-68** | `documentation-§3` | **MUST** | Low | `## Documentation map` uses **four** tables — Required / Conditional / **Verification and record** / Addon-specific (`docs/ARCHITECTURE.md:167,178,190,201`) — where the section's canonical shape is **three** (*"Every `.md` under `docs/` appears in exactly one of its three tables"*). The extra table is not padding: it holds the five verification-and-record docs the same section makes mandatory (`test-cases.md`, `performance.md`, `automated-tests/README.md`, `automated-tests/RESULTS.md`, and the conditional `perf-analysis/README.md`), and the three canonical tables have **no home for them** — they are not Tier 1, not Tier 2 and not "addon-specific". The map is otherwise correct in both directions: every `.md` under `docs/` appears exactly once and no row is dangling. | Raise upstream: `documentation-§3` should either name a fourth *Verification and record* table or state that the five belong in the Required table. Until then keep the fourth table — collapsing it into Tier 3 would file mandated docs as addon-specific, which is worse. |
| **PC-69** | `options-ui-§13`, `testing-§12` | SHOULD | Low | No suite case pins the tab strip's geometry as **selection-invariant**, and none could fail today. The vendored library has the fix — `libs/LibKa0s/OptionsWidgets.lua:384-399` measures the wrapped-row pitch once from the **inactive** cap atlas and says so — but the addon's own suite asserts nothing about the reserved band or the rows' y offsets across selections, and `tests/_kit/mock_base.lua:97` answers `GetHeight() == 0` for every frame, so a harness-level case would be green against nothing. The Categories page has eight tabs (`settings/Panel.lua:616-623`) and is exactly the page that wraps first. | Add the case in the shape the library's own comment names — assert the band height and every row's y offset are identical for every value of the selection — and give the mock per-atlas heights so the case is falsifiable. The mock change is a `tests/wow_mock.lua` extender concern, not a `tests/_kit/` edit. |
| **PC-70** | `documentation-§2` (item 2) | SHOULD | Low | Root `CLAUDE.md` has no standalone **adherence line** as item 2. `CLAUDE.md:3` is a one-line description of what the addon does; the adherence statement — *"This repo is built to the Ka0s WoW Addon Standard (https://github.com/tusharsaxena/WowAddonStandards)"* — first appears at `:7-8`, inside item 3's `## Standards compliance (read first)` section. Substance is present, position is not. Every other mandated item is present and in order, including the provenance line at `:30`. | Promote a one-sentence adherence line to `:4`, above the `## Standards compliance` heading. One-line insert; do not remove the sentence at `:7-8`, which item 3 needs. |

---

## Recorded deviations — accepted, not counted

Each of these matches a **ratified** row in `docs/ARCHITECTURE.md`'s `## Documented deviations`
register. Per `AUDIT.md` step 4 they are recorded as accepted, cite the row's rule and Decided date,
and **do not count** toward the MUST tally. Nothing found this run is new evidence that any of the
reasoning is now wrong — except PC-61, which is filed above precisely because it is.

| Rule | Row | Decided | Confirmed here |
|---|---|---|---|
| `performance-§12` | `:220` — no perf harness wired | 2026-08-05, re-checked 2026-09-02 | Criterion (a) holds: `modules/Override.lua:76-96` registers only at the combat **boundary**, and only while `General.visibility` is `inCombat`/`outOfCombat`. No `OnUpdate`, no ticker. `perf` correctly unregistered, no `PrettyChatPerfDB`, no `debugprofilestop` in `.luacheckrc`, no `docs/perf-analysis/` — all four are the compliant consequences of the exemption, not gaps. |
| `layout-§2` | `:221` — `GlobalStrings/` root folder | 2026-08-05 | Still unshipped and unloaded: `.pkgmeta:24` ignores the folder, no TOC line references it. |
| `toc-file-§1` | `:223` — branded `## Title:`/`## Author:`, no `## X-Wago-ID` | 2026-07-12 | Unchanged; `toc-file-§1` still asks for Wago only where listed. Issue #7 closed `state:will-not-do`. |
| `debug-logging-§2` | `:224` — console font not LSM-registered | 2026-08-24 | `core/MediaSetup.lua:88` calls `Media.RegisterLSM(addonName)`; it returns `0, 0` because LSM is not vendored. Not a gap. |
| `options-ui-§6` | `:225` — TreeGroup pane instead of the 50/50 grid | 2026-07-31, re-shaped 2026-09-03 | `RenderGrid` still offers only `HALF` or full width in the vendored v1.25.0 payload. |
| `options-ui-§13` | `:226` — vertical string list inside a category tab | 2026-09-03 | Selection is session-only and per primary tab (`ctx.activeSubTab`); no third level; the division is inside the scroll. |
| `testing-§1` | `:227` — `tests/loader.lua` survives beside the kit's | 2026-08-02 | `tests/_kit/loader.lua` still has no isolated-environment mode. |
| `localization-§1` | `:228` — English only | 2026-08-05 | `localization-§3` makes this a **terminal compliant state** once registered; the routing SHOULD is satisfied and `tests/test_locale.lua` scans both directions. Explicitly **not** re-filed (this closes 2026-08-05's PC-59). |
| `options-ui-§15` | `:229` — `Test` beside `Reset all settings` | 2026-09-02, moved into the library 2026-09-03 | Now the composer's `leadButton` (`settings/Schema.lua:116-120`), so the reset's mandated wording has exactly one writer. |
| `library-stack-§1` | `:230` — AceEvent/AceTimer not vendored | 2026-08-04 | The contradiction persists upstream: `library-stack.md:13-14` lists both as vendored, `:39` MUSTs vendoring only what the addon `LibStub`s. Neither is `LibStub`ed here. |

## Closed since 2026-08-05

| ID | Why it is closed |
|---|---|
| PC-25 | The non-canonical `# GlobalStrings` TOC section is gone; the surviving `layout-§2` half is a ratified register row (`:221`). |
| PC-40 → PC-45 | The whole blocked perf cluster is resolved by the ratified `performance-§12` exemption (`:220`), which the standard added in v2.24.0 for exactly this shape. Under it, the missing `PrettyChatPerfDB`, the unregistered `perf` verb, the absent `tests/perf.lua`, the absent perf docs and the omitted `.luacheckrc` entries are each the **compliant** state. |
| PC-46, PC-47 | `README.md` carries no angle-bracket placeholder and no `## Unreleased` / `## Credits`; the section order is canonical. |
| PC-48 | `CLAUDE.md` is a 64-line stub; the six accepted-deviation paragraphs moved to the register. The residue is PC-70. |
| PC-49 | Superseded by the `layout-§2` register row and `RESULTS.md:84`'s watch-list entry; only one *Accepted* disposition exists and no release run has yet started its shelf-life clock. |
| PC-50 | Superseded by PC-62, which files the same subject against the rule's **current** applicability clause. |
| PC-51, PC-23, PC-27, PC-54, PC-52 | All now ratified register rows (`:227`, `:225`, `:223`, `:224`, `:230`). |
| PC-53 | `## Message Bus` exists as its own heading (`docs/ARCHITECTURE.md:123`). |
| PC-57 | `RESULTS.md:15-20` now states the release gate in the standard's own terms, including `skip` reading as NOT EVALUATED. |
| PC-58 | `docs/automated-tests/RESULTS.md:44` records the conversion-sequence case added at `20260807-022707`, and `tests/test_defaults.lua` now checks each override against the Blizzard signature in `GlobalStrings/`. |
| PC-59 | Ratified as the `localization-§1` register row (`:228`), which `localization-§3` makes terminal. Explicitly not re-filed. |
| PC-55, PC-56 | Carried closed from the 2026-08-05 run. |
