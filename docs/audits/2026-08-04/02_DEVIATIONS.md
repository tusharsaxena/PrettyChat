# 02 — Deviations (Ka0s Pretty Chat)

**Run date:** 2026-08-04
**Audited against:** Ka0s WoW Addon Standard **v2.17.1 (2026-08-03)**
**ID prefix:** `PC-` (stable across runs; recurring deviations keep their original ID)

**Standard provenance.** All 24 section files, `STANDARDS.md` and `AUDIT.md` were fetched over
the network from `raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master` and verified
**byte-identical** (`diff` / `diff -r`) against the clean local checkout at HEAD `2141229`. No
rule in this document was reconstructed from memory, and no section went unassessed.

Sections are cited in the `filename-§N` form. The retired global `§N.M` notation is not used.

---

## Legend

| Field | Meaning |
|---|---|
| **Level** | MUST / SHOULD / MAY, as the violated rule states it |
| **Status** | `open` = no recorded decision · `documented` = an accepted deviation with a written reason in the repo |

---

## MUST-level deviations (12)

| ID | Section(s) | Level | Status | Deviation | Fix direction |
|---|---|---|---|---|---|
| **PC-25** | `layout-§1`, `layout-§2`, `toc-file-§5` | MUST | documented | `GlobalStrings/` is an eleventh, **PascalCase**, **root-level** source folder outside the mandated `core/ defaults/ settings/ locales/ modules/` skeleton (`layout-§1` MUSTs source under those folders; `layout-§2` MUSTs lowercase subfolders), and it forces a non-canonical `# GlobalStrings` section into the TOC file listing between `# Defaults` and `# Modules` (`PrettyChat.toc:42-52`), whose section set `toc-file-§5` fixes. Recorded at `CLAUDE.md:8` as a generated-data exception. *(Absorbs the former PC-33, whose `# Locales` half is fixed.)* | Either relocate the ten runtime chunks under a lowercase typed folder inside the skeleton — e.g. `defaults/globalstrings/` — which removes both halves at once and lets the `# Defaults` section carry them; or keep the exception and extend the `CLAUDE.md:8` record to name `layout-§2` and `toc-file-§5` explicitly, not only `layout`. |
| **PC-40** | `performance-§1` (also `library-stack-§7` adoption) | MUST | documented | No `core/PerfSetup.lua` and no `NS.Perf` instance — `LibKa0s-Perf-1.0` is vendored but never wired. `performance`'s adoption strength is **MUST for the wiring**, independent of how much coverage the addon needs. Declined on two structural grounds at `docs/pending/LEDGER.md:66` (no hot path; `suspend` would visibly flip chat formatting mid-fight). | Either (a) add a minimal `core/PerfSetup.lua` — descriptor with an empty or single-bucket set, a member-answering stub, and a `suspend`/`resume` pair that is honestly a no-op for an addon with no event registrations — so the wiring exists and `/pc perf` answers; or (b) take the decline upstream as a **standard change** carving out addons with no runtime execution path, and record the outcome here. Do not leave it as a silent local decision. |
| **PC-41** | `toc-file-§2`, `savedvariables-§4`, `performance-§5` | MUST | open | `## SavedVariables: PrettyChatDB` declares **one** global; the standard mandates exactly two, `<Addon>DB` **and** `<Addon>PerfDB`. | Add `PrettyChatPerfDB` to the TOC line (order: `PrettyChatDB, PrettyChatPerfDB`) and hand its name to the Perf descriptor (PC-40). Blocked on PC-40's resolution. |
| **PC-42** | `slash-commands-§2`, `performance-§4` | MUST | open | The reserved verb **`perf`** is not registered in `NS.COMMANDS`. `perf` is reserved collection-wide and MUST be registered by the addon through its own table. | Add a `{"perf", …, function(rest) runPerf(rest) end}` triple that forwards to the Perf instance's command entry point and prints the returned lines through `NS.Print`. Blocked on PC-40. |
| **PC-43** | `performance-§9`, `testing-§7` | MUST | open | No `tests/perf.lua` offline scenario runner, and therefore no **zero-overhead scenario** — the measured evidence `performance-§2` requires rather than a comment claiming it. | Add `tests/perf.lua`, outside the green gate, asserting only deterministic quantities (allocations / call counts), with a scenario running the hottest bracketed path with capture off. Blocked on PC-40. |
| **PC-44** | `documentation-§3` | MUST | open | Two of the three **required** topic-detail docs are absent: `docs/performance.md` and `docs/perf-runs/README.md`. (`docs/test-cases.md`, the third, is present and generated.) | Add both. `docs/performance.md` states which paths are bracketed and why, how to run `/pc perf`, and what the harness can and cannot resolve; `docs/perf-runs/README.md` documents the record naming and points at the library's canonical schema. Blocked on PC-40. |
| **PC-45** | `lint`, `performance-§2`, `performance-§5` | MUST | open | `.luacheckrc` declares neither `debugprofilestop` in `read_globals` nor `PrettyChatPerfDB` in `globals` — both explicit MUSTs once the perf wiring exists. | Add `debugprofilestop` to `read_globals` and `PrettyChatPerfDB` to `globals` with a justifying comment, in the same change as PC-40/PC-41. |
| **PC-46** | `documentation-§1` | MUST | open | An **angle-bracket placeholder** survives in shipped README content: `` `/pc reset <setting>` `` (`README.md:116`). CurseForge strips `<setting>` as an unknown HTML tag **even inside backticks**, so players see `/pc reset` with the argument silently deleted, while GitHub renders it correctly. | Write the argument bare — `` `/pc reset setting` `` — matching the same command's already-correct spelling at `README.md:63`. One-line edit. Do not sweep real HTML (`<br>`, `<code>`) while doing it. |
| **PC-47** | `documentation-§1`, anti-pattern #28 | MUST | open | Two non-canonical README sections break the fixed section order: `## Unreleased` (`README.md:15`) sits between the Description and `## What's new`, and `## Credits` (`README.md:120`) sits between `## Troubleshooting` and `## Issues and feature requests`. The canonical order admits neither. | Fold `## Unreleased`'s three bullets into `## What's new` at the next version bump (they are the next release's highlights and belong in the Version History row that ships them), and move the LibKa0s attribution into the Description paragraph or `docs/ARCHITECTURE.md` — the README is player-facing. |
| **PC-48** | `documentation-§2`, anti-pattern #26 | MUST | open | Root `CLAUDE.md` has grown from the mandated **stub** into a full agent brief: 64 lines carrying six multi-sentence accepted-deviation paragraphs (`:8-13`), code invariants and seven guardrails. The mandated item order is also broken — the `## Standards compliance (read first)` section is at `:14`, after all six deviation paragraphs, where it must be item 3. | Move the six accepted-deviation records into `docs/ARCHITECTURE.md` (or a `docs/deviations.md` topic doc) — `documentation-§6` names `docs/` and the audit bundle as their home, not `CLAUDE.md` — and reduce the root file to the five mandated items in order: H1, adherence line, `## Standards compliance (read first)`, the read-the-docs pointer list, the green-gate line. |
| **PC-49** | `layout-§1` | MUST | documented | Eight shipped `.lua` files exceed the **1500-LOC cap**: `GlobalStrings_001` (2893), `_002` (2425), `_004` (2662), `_005` (2494), `_006` (2498), `_007` (2312), `_009` (3285), `_010` (2176). The unshipped source dump `GlobalStrings/GlobalStrings.lua` is 23842. Covered in spirit by the `CLAUDE.md:8` generated-data exception, which does not name the LOC cap. | Re-run `split_globalstrings.py` with a chunk target under 1500 lines (roughly 16–18 chunks instead of 10) and update the TOC's `# GlobalStrings` list — a mechanical regeneration, no logic change. Alternatively extend the `CLAUDE.md:8` exception to name `layout-§1`'s cap explicitly, so the deviation is recorded rather than implied. |
| **PC-50** | `architecture-§4`, anti-pattern #19 | MUST | documented | There is **no closed message bus**. `docs/ARCHITECTURE.md:119` states so outright, and cross-file wiring is direct table access — e.g. `modules/Override.lua:100-102,112-113,130-131` calls `NS.Schema.NotifyPanelChange`, and `settings/Schema.lua:270-272` reaches into `NS.Helpers.RefreshScalars`. | Low practical impact — the addon has one feature module and no event traffic, so the clobber hazards `architecture-§4` exists to prevent cannot arise. Two honest routes: introduce a single `Ka0s_PrettyChat_SettingsChanged` message with `NS.NewBusTarget()` receivers (and document it in a new `Message Bus` section, PC-53), or record the absence as an **accepted deviation** with the single-module rationale. Currently it is stated as a fact rather than classified as a deviation. |

---

## SHOULD-level deviations (6)

| ID | Section(s) | Level | Status | Deviation | Fix direction |
|---|---|---|---|---|---|
| **PC-23** | `options-ui-§6` | SHOULD | documented | The per-string editor is a bespoke **40/60** three-row block (`LEFT_W = 0.4` / `RIGHT_W = 0.6`, `settings/Panel.lua:127-128`; `buildStringRow` at `:130`) instead of the schema-driven 50/50 grid. Justified in-code and at `CLAUDE.md:11`: the right column holds full color-escaped format strings that a 50/50 split clips. Re-checked against `LibKa0s-Options-1.0`'s `RenderGrid`, which offers only `HALF` or full width (LIBKA0S-06). | Keep as the documented deviation, **or** push a third ratio into `RenderGrid` as an **additive** descriptor/API field upstream in LibKa0s so every consumer gets it, rather than keeping the host-side layout. The upstream route is the one `anti-patterns` #47 prefers. |
| **PC-27** | `toc-file-§1` | SHOULD | documented | `## Title:` carries rainbow `\|cRRGGBB…\|r` escapes rather than the plain `Ka0s <Human Name>` form, and `## Author:` uses `aDd1kTeD2Ka0s` rather than `add1kted2ka0s` (`PrettyChat.toc:2,4`). Recorded at `CLAUDE.md:10` as the addon's brand mark. | Keep as the documented brand deviation. No action recommended; re-confirm only if the collection ever normalizes TOC branding. |
| **PC-51** | `testing-§1` | SHOULD | documented | `tests/loader.lua` (132 lines) survives as an addon-side instance factory beside the kit's loader. It is **not** a re-implementation — it delegates to `Loader.makeEnv` and `Loader.tocFiles` — but it does own environment construction, which `testing-§1` places in the kit. Justified at `CLAUDE.md:12`: the addon's entire feature is writing `_G[GLOBALNAME]` and half the suite asserts per-instance, and the kit has no isolated-environment mode. Reported upstream as LIBKA0S-01. | Keep until LIBKA0S-01 lands an isolated-environment mode in `testkit/`, then delete `tests/loader.lua` and re-vendor. Track the upstream item so this does not become permanent by default. |
| **PC-53** | `documentation-§3` | SHOULD | open | `docs/ARCHITECTURE.md` lacks the mandated **Message Bus** section heading; the content ("There is no message bus") lives inside `## Event Subscriptions` (`:117-119`). The required section list is fixed, and a reader grepping for the heading finds nothing. | Add a `## Message Bus` heading carrying the existing sentence, or the message table if PC-50 is closed by introducing one. One-line structural edit. |
| **PC-54** | `debug-logging-§2` | SHOULD | documented | The vendored monospace font is handed to the console as a raw path constant (`core/Constants.lua:60`) and is **not** registered with LibSharedMedia-3.0. `debug-logging-§2` says register it at load. Justified at `core/Constants.lua:54-59` and `CLAUDE.md:9`: the addon ships no media picker, so LSM has no consumer surface. | Keep as the documented deviation. If LSM is ever vendored for another reason, add the one-line `LSM:Register("font", "JetBrains Mono", path)` at the same time — the registration exists to expose the font to *other* addons, which is the half the current rationale does not cover. |
| **PC-55** | `performance-§10` | SHOULD | open | No `docs/complexity.md`. `performance-§10` SHOULDs a committed `lizard` report over the addon's own source, excluding `libs/`. | Run `lizard core defaults settings modules locales` and commit the output as `docs/complexity.md` with a line stating it is generated and how. Absent tooling makes the report stale, not the addon non-compliant — but it has never been generated. |

---

## Advisory (MAY / standard-internal tension) (2)

| ID | Section(s) | Level | Status | Note |
|---|---|---|---|---|
| **PC-52** | `library-stack-§1` vs `library-stack-§3` | MAY | open | `AceEvent-3.0` and `AceTimer-3.0` appear in `library-stack-§1`'s *"Mandatory libs (every Ace3 addon)"* table but are **not** vendored — correctly, since the addon `LibStub`s neither and `library-stack-§3` MUSTs *"vendor only libs the addon actually uses"*. The two rules pull opposite ways for an addon this small. **Not** actionable in this repo; worth raising upstream so §1's table is read as *"the mandatory set for an addon that uses them"*. |
| **PC-56** | `toc-file-§1` | MAY | open | `## Category-enUS: Chat & Communication` (`PrettyChat.toc:10`) is outside the standard's enumerated set `<Combat\|Group\|Auction\|Chat\|UI\|Misc>`. The value is a real Blizzard category string, so this may be the standard's enumeration being incomplete rather than the TOC being wrong. Either narrow the TOC to `Chat`, or raise the enumeration upstream. |

---

## Resolved since the 2026-07-18 run

Recorded so the IDs are not re-issued and the history stays legible.

| ID | Section | How it closed |
|---|---|---|
| **PC-10** | `toc-file-§1` | **Resolved by the standard.** v2.17.1's `toc-file-§1` makes `X-Wago-ID` / `X-WoWI-ID` **MAY**, included only when the addon is actually listed there. PrettyChat is CurseForge-only, so omitting the field is now correct. |
| **PC-28** | `architecture-§1` | Fixed — the namespace upvalue is `NS` throughout. |
| **PC-30** | `architecture-§2` | Fixed — `NewAddon(NS, addonName, "AceConsole-3.0")` (`core/PrettyChat.lua:14`), with the printer reclaimed at `core/CoreSetup.lua:109` and the clobber modeled in the mock. |
| **PC-31** | `documentation-§2`/`§6` | Fixed — `## Standards compliance (read first)` present verbatim in substance (`CLAUDE.md:14-31`); H1 retitled. (Its *placement* is now PC-48.) |
| **PC-32** | `documentation-§3`/`§6` | **Resolved by the standard.** v2.17.0 deleted `docs/agent-context.md`; the reference is now a three-place rule and all three places are satisfied. |
| **PC-33** | `toc-file-§5` | **Partly fixed** — `# Locales` now sits immediately after `# Libraries`. The non-canonical `# GlobalStrings` section remains, inseparable from PC-25; carried forward as part of PC-25 rather than as its own open row. |
| **PC-34** | `events-frames-taint-§8` | Fixed — `NS.Print` and the debug sink are built from `LibKa0s-Core-1.0` (`core/CoreSetup.lua:90-110`), which probes `table.concat`. |
| **PC-35** | `events-frames-taint-§8` | Fixed — no addon-source call site writes to `DEFAULT_CHAT_FRAME` outside the degradation branch; a repo grep for a raw `print(` finds nothing. |
| **PC-36** | `documentation-§1` | Fixed — the settings panel renders as a `Tab \| Covers` table (`README.md:72-82`). |
| **PC-37** | `packaging` | Fixed — `.pkgmeta` ignores the GlobalStrings source assets and the project-page art. |
| **PC-38** | `slash-commands-§4` | Fixed — the help header comes from the library's renderer. |
| **PC-39** | `savedvariables-§2` | Fixed — `defaults/Profile.lua` exists and holds the profile defaults. |

**Still open and carried forward:** **PC-25** (now absorbing PC-33's `# GlobalStrings` half), **PC-23**, **PC-27** — all three are rows in the tables above.

---

## Counts

| Level | Open | Documented | Total |
|---|---|---|---|
| MUST | 8 | 4 | **12** (PC-25 carried forward + PC-40…PC-50) |
| SHOULD | 2 | 4 | **6** |
| MAY / advisory | 2 | 0 | **2** |

*PC-25 is counted once; its TOC-section half (the former PC-33) is folded into it rather than re-issued.*

**Grand total: 20 deviations** — 12 MUST, 6 SHOULD, 2 advisory.
</content>
