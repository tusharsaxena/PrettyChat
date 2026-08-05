# 02 — Deviations (Ka0s Pretty Chat)

**Run date:** 2026-08-05
**Audited against:** Ka0s WoW Addon Standard **v2.21.0 (2026-08-04)**
**ID prefix:** `PC-` (stable across runs; a recurring deviation keeps its original ID)
**Previous run:** `docs/audits/2026-08-04/` (against v2.17.1)

Sections are cited in the `filename-§N` form. The retired global `§N.M` notation is not used.

## Legend

| Field | Meaning |
|---|---|
| **Level** | MUST / SHOULD / MAY, as the violated rule states it |
| **Status** | `open` = no recorded decision · `documented` = accepted deviation with a written reason in the repo |

---

## MUST-level deviations (12)

| ID | Section(s) | Level | Status | Deviation | Fix direction |
|---|---|---|---|---|---|
| **PC-25** | `layout-§1`, `layout-§2`, `toc-file-§5` | MUST | documented | `GlobalStrings/` is an eleventh, **PascalCase**, **root-level** source folder outside the mandated `core/ defaults/ settings/ locales/ modules/` skeleton, and it forces a non-canonical `# GlobalStrings` section into the TOC file listing between `# Defaults` and `# Modules` (`PrettyChat.toc:42-68`), whose section set `toc-file-§5` fixes. Recorded at `CLAUDE.md:8`. | Relocate the 26 runtime chunks under a lowercase typed folder inside the skeleton — e.g. `defaults/globalstrings/` — which closes both halves and lets `# Defaults` carry them; or keep the exception and extend the `CLAUDE.md:8` record to name `layout-§2` and `toc-file-§5` explicitly, not only `layout`. |
| **PC-40** | `performance-§1` (also `library-stack-§7` adoption) | MUST | documented | No `core/PerfSetup.lua` and no `NS.Perf` — `LibKa0s-Perf-1.0` is vendored but never wired. `performance`'s adoption strength is **MUST for the wiring**, independent of coverage. Declined at `CLAUDE.md:6` / `docs/pending/LEDGER.md:66` (no hot path; `suspend` would flip chat formatting mid-fight). | Either (a) add a minimal `core/PerfSetup.lua` — descriptor with an empty or single-bucket set, a member-answering stub, and an honestly no-op `suspend`/`resume` — so the wiring exists and `/pc perf` answers; or (b) take the decline upstream as a **standard change** carving out addons with no runtime execution path, and record the outcome. Do not leave it a silent local decision. |
| **PC-41** | `toc-file-§2`, `savedvariables-§4`, `performance-§5` | MUST | open | `## SavedVariables: PrettyChatDB` (`PrettyChat.toc:7`) declares **one** global; exactly two are mandated — `<Addon>DB` **and** `<Addon>PerfDB`. | Add `PrettyChatPerfDB` in order and hand its name to the Perf descriptor. Blocked on PC-40. |
| **PC-42** | `slash-commands-§2`, `performance-§4` | MUST | open | The reserved verb **`perf`** is absent from `NS.COMMANDS` (`settings/Slash.lua:45-70`). | Add a `{"perf", …}` triple forwarding to the Perf instance's command entry point, printing returned lines through `NS.Print`. Blocked on PC-40. |
| **PC-43** | `performance-§9`, `testing-§7` | MUST | open | No `tests/perf.lua` offline scenario runner, so no **zero-overhead scenario** — the measured evidence `performance-§2` requires rather than a comment. The `perf` suite is a permanent `skip` in every recorded bundle. | Add `tests/perf.lua` outside the green gate, asserting only deterministic quantities, with a scenario running the hottest bracketed path with capture off. Blocked on PC-40. |
| **PC-44** | `documentation-§3` | MUST | open | Two of the **five required** topic-detail docs are absent: `docs/performance.md` and `docs/perf-runs/README.md`. (`test-cases.md`, `automated-tests/README.md` and `automated-tests/RESULTS.md` are all present.) | Add both. `performance.md` states which paths are bracketed and why, how to run `/pc perf`, and what the harness can and cannot resolve; `perf-runs/README.md` documents the in-game record naming and points at the library's canonical schema, noting offline runs live in `docs/automated-tests/`. Blocked on PC-40. |
| **PC-45** | `lint`, `performance-§2`, `performance-§5` | MUST | open | `.luacheckrc` declares neither `debugprofilestop` in `read_globals` nor `PrettyChatPerfDB` in `globals` (`.luacheckrc:31-62`) — both explicit MUSTs once the perf wiring exists. | Add both, with the justifying comment `globals` requires, in the same change as PC-40/PC-41. |
| **PC-46** | `documentation-§1` | MUST | open | An **angle-bracket placeholder** survives in shipped README content: `` `/pc reset <setting>` `` (`README.md:116`). CurseForge strips `<setting>` as an unknown HTML tag **even inside backticks**, so players see `/pc reset` with the argument deleted, while GitHub renders it correctly. | Write it bare — `` `/pc reset setting` `` — matching the same command's correct spelling at `README.md:63`. One-line edit; do not sweep real HTML. |
| **PC-47** | `documentation-§1`, anti-pattern #28 | MUST | open | Two non-canonical README sections break the fixed order: `## Unreleased` (`README.md:15`) between the Description and `## What's new`, and `## Credits` (`README.md:120`) between `## Troubleshooting` and `## Issues and feature requests`. | Fold `## Unreleased`'s three bullets into `## What's new` at the next version bump (they are the next release's highlights and belong in the Version History row that ships them), and move the LibKa0s attribution into the Description paragraph or `docs/ARCHITECTURE.md`. |
| **PC-48** | `documentation-§2`, anti-pattern #26 | MUST | open | Root `CLAUDE.md` is a full agent brief, not the mandated **stub**: 64 lines carrying six multi-sentence accepted-deviation paragraphs (`:5-13`), code invariants and eight guardrails. The item order is also broken — `## Standards compliance (read first)` sits at `:14`, after all six deviation paragraphs, where it must be item 3. | Move the six accepted-deviation records into `docs/ARCHITECTURE.md` (or a `docs/deviations.md` topic doc) — `documentation-§6` names `docs/` and the audit bundle as their home — and reduce the root file to the five mandated items in order: H1, adherence line, `## Standards compliance (read first)`, the read-the-docs pointer list, the green-gate line. |
| **PC-49** | `layout-§1` | MUST | documented | **Reduced since 2026-08-04.** The eight over-cap shipped chunks are gone — every `GlobalStrings_0NN.lua` is now 882 lines. What remains over the 1500-LOC cap is the single **unshipped, unloaded** source dump `GlobalStrings/GlobalStrings.lua` (23,842 lines). No TOC line references it and `.pkgmeta:21` excludes it. Dispositioned as *Accepted* in `docs/automated-tests/RESULTS.md:65`. | Keep as the documented exception, and extend `CLAUDE.md:8` to name `layout-§1`'s cap explicitly for the dump so the record matches the rule. Watch the shelf-life rule: the disposition may not read *accepted* across three consecutive **release** runs (anti-pattern #53) — none have occurred yet, so the clock has not started. |
| **PC-50** | `architecture-§4`, anti-pattern #19 | MUST | documented | There is **no closed message bus**. `docs/ARCHITECTURE.md:119` states so; cross-file wiring is direct table access — `modules/Override.lua:100-102,112-113,130-131` calls `NS.Schema.NotifyPanelChange`, `settings/Schema.lua:270-272` reaches into `NS.Helpers.RefreshScalars`. | Low practical impact — one feature module, zero event traffic, so the clobber hazards `architecture-§4` exists to prevent cannot arise. Two honest routes: introduce a single `Ka0s_PrettyChat_SettingsChanged` message with `NS.NewBusTarget()` receivers (documented in a new `## Message Bus` section, PC-53), or classify the absence as an **accepted deviation** with the single-module rationale. Today it is stated as a fact rather than classified. |
| **PC-57** | `automated-tests-§3` (*The release gate*), `automated-tests-§6`, `documentation-§5` | MUST | open | **New.** The repo states the commit gate correctly and the **release gate not at all**. `docs/testing.md:113-121` and `docs/automated-tests/README.md:19-29` both print a `Gates?` table reading `complexity → no — recorded only` with no release column, and `RESULTS.md:11-13` says "`perf` and `complexity` are recorded and never fail a run" full stop. v2.21.0 makes the **tag** gate on all four suites at `pass` plus `suites.complexity.warnings == 0`, with a `skip` blocking as NOT EVALUATED. As written, a reader is told complexity never gates — which is now false at the one checkpoint where it decides whether a release ships. | Add the release-gate half to all three places, in the standard's own terms: commits on `lint` + the harness (unchanged, and the runner's exit code stays as it is), the tag on all four plus zero CCN > 15, evaluated by `/wow-addon:bump-version` from the run's `manifest.json`, a `skip` never reading as a pass — with the one narrow exception that `perf` skipped for *no `tests/perf.lua`* passes and **MUST** be said plainly in the release notes (which is this addon's standing case, PC-43). |

---

## SHOULD-level deviations (7)

| ID | Section(s) | Level | Status | Deviation | Fix direction |
|---|---|---|---|---|---|
| **PC-23** | `options-ui-§6` | SHOULD | documented | The per-string editor is a bespoke **40/60** three-row block (`LEFT_W = 0.4` / `RIGHT_W = 0.6`, `settings/Panel.lua:127-128`) instead of the schema-driven 50/50 grid. Justified in-code and at `CLAUDE.md:11`: the right column holds full color-escaped format strings that a 50/50 split clips. `LibKa0s-Options-1.0`'s `RenderGrid` offers only `HALF` or full width (LIBKA0S-06). | Keep as documented, **or** push a third ratio into `RenderGrid` as an **additive** descriptor field upstream in LibKa0s so every consumer gets it. The upstream route is the one anti-pattern #47 prefers. |
| **PC-27** | `toc-file-§1` | SHOULD | documented | `## Title:` carries rainbow `\|cRRGGBB…\|r` escapes rather than plain `Ka0s <Human Name>`, and `## Author:` is `aDd1kTeD2Ka0s` rather than `add1kted2ka0s` (`PrettyChat.toc:2,4`). Recorded at `CLAUDE.md:10` as the brand mark. | Keep. Re-confirm only if the collection ever normalizes TOC branding. |
| **PC-51** | `testing-§1` | SHOULD | documented | `tests/loader.lua` (155 lines) survives as an addon-side instance factory beside the kit's loader. Not a re-implementation — it delegates to `Loader.makeEnv` and `Loader.tocFiles` — but it owns environment construction, which `testing-§1` places in the kit. Justified at `CLAUDE.md:12`: the addon's whole feature is writing `_G[GLOBALNAME]` and half the suite asserts per instance; the kit has no isolated-environment mode. Reported upstream as LIBKA0S-01. | Keep until LIBKA0S-01 lands an isolated-environment mode in `testkit/`, then delete `tests/loader.lua` and re-vendor. Track the upstream item so it does not become permanent by default. |
| **PC-53** | `documentation-§3` | SHOULD | open | `docs/ARCHITECTURE.md` lacks the mandated **Message Bus** section heading; the content ("There is no message bus") is the last sentence of `## Event Subscriptions` (`:117-119`). The required section list is fixed, and a reader grepping for the heading finds nothing. | Add a `## Message Bus` heading carrying that sentence, or the message table if PC-50 closes by introducing one. One-line structural edit. |
| **PC-54** | `debug-logging-§2` | SHOULD | documented | The vendored monospace font is handed to the console as a raw path constant (`core/Constants.lua:60`) and is **not** registered with LibSharedMedia-3.0. Justified at `core/Constants.lua:54-59` and `CLAUDE.md:9`: the addon ships no media picker, so LSM has no consumer surface. | Keep. If LSM is ever vendored for another reason, add the one-line `LSM:Register("font", "JetBrains Mono", path)` in the same change — registration exists to expose the font to *other* addons, the half the current rationale does not cover. |
| **PC-58** | `testing-§12` | SHOULD | open | **New.** `tests/test_defaults.lua:107-114` — *"every default format string renders with sample arguments"* — feeds `NS.RenderSample` arguments synthesized **from the same string** (`modules/Override.lua:171-197` picks one sample value per conversion found in the format). The assertion is therefore derived from the value under test: it cannot detect a default whose conversions disagree with the **Blizzard signature** the client actually calls it with. That is exactly the class of defect the 2026-08-05 review found shipped, twice, at `defaults/Defaults.lua:162-165` and `:190-193` — with this case green over both. It reads as coverage of the shipped defaults and is coverage of the preview path only. | Add a second case that pins each override's conversion sequence against the **Blizzard original** captured in `NS.GlobalStrings` (same count, same order, same types), which is falsifiable by construction. Keep the existing case — it is a valid preview-path test — and re-title it so its scope is honest. The two shipped defaults themselves are review findings F-001/F-002, not audit deviations; they are named here only as the evidence that this case cannot fail. |
| **PC-59** | `localization-§1`, `localization-§2` | SHOULD | open | **New.** User-facing text is assembled by concatenation and never reaches `NS.L`, so it cannot be translated in any locale file: `settings/Schema.lua:72-73` (`"Enable " .. category`, `"Enable or disable all " .. category .. " string overrides."`), `settings/Panel.lua:167-169` (the shared-global tooltip) and `:392-394` (`"Reset all " .. category .. " strings to defaults."`). `locales/enUS.lua:9-11` describes its seeded block as "the authoritative manifest of the addon's user-facing string surface" — true as written (it manifests what *is* wrapped) and misleading in effect. The standard has no explicit MUST that every user-facing string be wrapped, which is why this is filed SHOULD. | Move the fixed halves into `L` and format the variable half in — `L["Enable %s"]:format(category)` — so translators get a key with a placeholder rather than an English fragment, and reword the `locales/enUS.lua` header to say what the manifest covers and what it does not. |

---

## Advisory (MAY / standard-internal tension) (2)

| ID | Section(s) | Level | Status | Note |
|---|---|---|---|---|
| **PC-52** | `library-stack-§1` vs `library-stack-§3` | MAY | open | `AceEvent-3.0` and `AceTimer-3.0` sit in `library-stack-§1`'s *"Mandatory libs"* table but are **not** vendored — correctly, since the addon `LibStub`s neither and `library-stack-§3` MUSTs *"vendor only libs the addon actually uses"*. The two rules pull opposite ways for an addon this small. Not actionable here; worth raising upstream so §1's table reads as *"the mandatory set for an addon that uses them"*. Already recorded at `DEPENDENCIES.md:118-119`. |
| **PC-56** | `toc-file-§1` | MAY | open | `## Category-enUS: Chat & Communication` (`PrettyChat.toc:10`) is outside the enumerated set `<Combat\|Group\|Auction\|Chat\|UI\|Misc>`. The value is a real Blizzard category string, so this may be the standard's enumeration being incomplete rather than the TOC being wrong. Narrow the TOC to `Chat`, or raise the enumeration upstream. |

---

## Resolved since the 2026-08-04 run

| ID | Section | How it closed |
|---|---|---|
| **PC-55** | `performance-§10` | **Resolved by the standard, and by adoption.** v2.19.0 retired `docs/complexity.md`; its raw output is now each bundle's `complexity.txt` and its trend-line role is `docs/automated-tests/RESULTS.md`. The addon adopted `automated-tests` in `058c5b1`, ships three frozen bundles and a two-table watch list, and carries **no** surviving `docs/complexity.md` — which is the compliant state, not a missing doc. |
| **PC-49** (partly) | `layout-§1` | The eight over-cap **shipped** chunks were re-split to 882 lines each in `9198678`. Only the unshipped 23,842-line dump remains over cap; PC-49 stays open in reduced form rather than being re-issued. |

---

## Counts

| Level | Open | Documented | Total |
|---|---|---|---|
| MUST | 8 | 4 | **12** |
| SHOULD | 3 | 4 | **7** |
| MAY / advisory | 2 | 0 | **2** |

**Grand total: 21 deviations** — 12 MUST, 7 SHOULD, 2 advisory. Three are new this run (PC-57, PC-58,
PC-59); one closed (PC-55); one reduced (PC-49). Nine of the twelve MUSTs are the single blocked
cluster PC-40 → PC-45 plus the doc/README/CLAUDE items.
