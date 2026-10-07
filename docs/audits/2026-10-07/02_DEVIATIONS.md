# 02 — Deviations (Ka0s Pretty Chat)

**Run date:** 2026-10-07
**Audited against:** Ka0s WoW Addon Standard **v2.76.1 (2026-10-07)**
**ID prefix:** `PC-` (stable). The 2026-09-23 run ended at `PC-102`, so this run's new IDs are
`PC-103` to `PC-106`. `PC-76` carries forward.
**Previous run:** `docs/audits/2026-09-23/` (v2.64.0). It is frozen and was not edited.

Sections are cited as `filename-§N`, or by bare filename for a section file with no numbered
subsections. **Severity grades impact, not rule strength** (`AUDIT.md` step 5). The **Level**
column names the rule's strength separately, so a Low that fails a MUST shows as both.

## Tally, and how it was counted

- **Headline (root deviations only): 5.**
  - By grade: **High 0 · Medium 0 · Low 3 · Info 2.**
  - By level: **MUST 2 · SHOULD 1 · observation 2.** The two Info rows fail no rule.
- **Total including `derived from` dependents: 5.** This run filed no dependents. PC-104 is a single
  rolled-up root because one sync pass fixes all four of its items, which is the playbook's own
  roll-up instruction for doc drift.
  - By grade: **High 0 · Medium 0 · Low 3 · Info 2.**
  - MUST failures including dependents: **2.**
- **Recorded deviations (accepted, not counted): 8.** These are ratified register rows whose triggers
  have not fired (table below).

**No player, SavedVariables file or session can reach any of these findings.** All three Lows are
documentation or record gaps. The code passed every mechanical check this run made:
- stand-down census: 1 registration site, undone by `UnregisterAllEvents`
- diagnostics: all seven checks
- the library debug sinks
- launcher and minimap row
- line endings: 0 of 575 tracked files off the pin
- vendor diffs: both empty
- packaging: all three checks
- README: all five cheap checks
- lint: 0/0
- tests: 572/0/1 over 573

**Compared with 2026-09-23: 26 roots fell to 5.** Of the 26 earlier roots, 25 are closed, along
with all 4 of their dependents. Twenty were fixed in code or docs by the `PC-00` to `PC-26`
remediation. Five closed because the rule changed: PC-84, PC-93, PC-102 (v2.65.0), PC-69 (`options-ui-§13`'s
consumer-MUST-NOT-duplicate clause) and PC-100 (`architecture-§1` now permits `local _, NS`). PC-76
carries as a re-measured Info. The four new roots are drift that has built up since that run (two
re-vendors without a bundle, doc inventory after v1.69.0/v1.70.0, and hub growth) plus one stale
issue decision.

---

## Deviations: roots

| ID | Section(s) | Level | Grade | Deviation | Fix direction |
|---|---|---|---|---|---|
| **PC-103** | `audit-review-history` (*A re-vendor commit implies a bundle*) | **MUST** | Low | **Two vendored LibKa0s tags have no `docs/revendor/` bundle and no register row: v1.69.0 and v1.70.0.** The playbook's two-listing check, run from the store's horizon (2026-08-25), reads 51 distinct tags off root `CLAUDE.md` at each commit that touched `libs/LibKa0s/` or `tests/_kit/`. Bundles record 49 of them. `136cf54` ("re-vendor LibKa0s v1.69.0 (kit 37; adds the line chart widget)") and `7a1aabf` ("re-vendor LibKa0s v1.70.0") each rolled the provenance line and wrote no bundle. The newest bundle is `docs/revendor/2026-10-04-v1.68.1/`. The finding is doc-only, so it is graded Low, and it still fails the section's MUST. | Write **one consolidated span bundle**, `docs/revendor/2026-10-07-v1.69.0-v1.70.0/`. Its `01_DELTA.md` line 1 is `Delta: LibKa0s v1.68.1 -> v1.70.0 (span: v1.69.0 v1.70.0)`. It names the two commits and the two new files (`WidgetsLineChart.lua`, `WidgetsAutocomplete.lua`) and the kit-37 additions (`mock_lines.lua`). `05_SUMMARY.md` states that no host adoption followed: Widgets is a declined major (#11). Do not write one folder per tag. |
| **PC-104** | `documentation-§5` | **MUST** | Low | **The doc and comment set has drifted from the tree in four places.** This is filed once and rolled up. **(1)** `docs/ARCHITECTURE.md:418` says that for Item, Pool and Widgets "nothing in this addon, and no other vendored LibKa0s file, `LibStub`s any of the three". That is false at v1.70.0: `libs/LibKa0s/DebugLog.lua:33` resolves Widgets (the resize helper), `OptionsNav.lua:20`, `OptionsTabs.lua:38` and `OptionsWidgets.lua:37` resolve Pool, and `OptionsIds.lua:787` and `OptionsIdList.lua:358` resolve Item. The same sentence's "still vendored" list leaves out `WidgetsDragHandle.lua`, `WidgetsLineChart.lua` (new at v1.69.0) and `WidgetsAutocomplete.lua` (new at v1.70.0). **(2)** `docs/performance-sweep.md`'s result block claims to be "verbatim, at the commit that carries this page". Its seven `tests/test_libka0s.lua` rows cite `:802`–`:831`, and the same lines are now at `:831`–`:860`. The 36 shipped-code and other rows match, so there are still 43 lines and the exemption stands. The page also says it was last re-taken in `DG-PC-01` (`:8-9`), while the register row it backs says "last re-taken in the `SP-PC-02R:` commit" (`docs/ARCHITECTURE.md:284`). **(3)** `.luacheckrc:34-37` says "Seven files here DO read it" and "The other eleven". The tree has 10 files with `local addonName, NS` and 12 with `local _, NS` (`docs/ARCHITECTURE.md:81` has it right). **(4)** Live docs, code comments and suites cite cross-repo digest ids with no cycle named: **`PRETTYCHAT-A-03`, `-A-07`, `-A-08`, `-A-09`, `-A-19`, `-A-20` and `-A-25`** (`docs/ARCHITECTURE.md:100`, `:171`, `:173`, `:375`; `docs/module-map.md:54`, `:58`; `defaults/Profile.lua:3`; `tests/test_override.lua:77`; `tests/test_defaults.lua:303`; `tests/test_doc_structure.lua:410`, `:469`). Inside this repo, `-A-03` and `-A-07` to `-A-09` resolve only to the **2026-09-07** audit's ID map, which assigns them to PC-62 and PC-66 to PC-68, which are different findings. For example, `:469` uses `A-03` for a load-order omission, but the 2026-09-07 `A-03` is the `architecture-§4` bus finding. `-A-19`, `-A-20` and `-A-25` resolve nowhere in the repo. (`docs/module-map.md:51`'s `A-05` does match its 2026-09-07 meaning and is not counted.) The register preamble (`:276-280`) explains `PC-NN` and `PC-R-NN` and leaves this form out. | One `/dev-copilot:sync-docs` pass. (1) Rewrite the sentence to say the addon consumes none of the three majors itself, that vendored modules resolve them internally (DebugLog→Widgets, Options→Pool/Item), and that the folder is copied whole. Drop the hand-kept file list, which is the part that goes stale on every re-vendor, or replace it with "the 34 files `LibKa0s.xml` lists". (2) Re-take the sweep block by running the command, and make the page header and the register row name the same commit. (3) Fix the two counts in the comment, or reduce it to history ("until `M4c-06`…") with no live count. (4) Either rewrite each `PRETTYCHAT-A-NN` to the in-repo id it stands for (the 2026-09-23 bundle's `PC-NN`), or add one line to the register preamble saying that `PRETTYCHAT-A-NN` is the 2026-09-23 cross-repo digest's id and where it resolves (`Ka0sAddonsCommonTasks/docs/2026-09-23-REVIEW_AND_STANDARDS_AUDIT_REMEDIATION/01_CONSOLIDATED_FINDINGS.md`). |
| **PC-105** | `documentation-§3` (*`ARCHITECTURE.md` is a hub*) | SHOULD | Low | **`docs/ARCHITECTURE.md` is 434 lines,** over the "roughly 400" the section says the hub SHOULD stay under. It was 387 at the 2026-09-23 run's record commit (`e561b79`). The weight is in `## Documented deviations` (`:265`–`:412`, about 148 lines), and two blocks there are prose rather than register: the retired-row narratives (`:293`–`:335`) and the census's exemption explanation (`:362`–`:412`). Each mandated section's *own* body stays near the 60-line spill threshold. Shape reported per the rule, without arguing the arithmetic. | Move the census's explanatory prose (`:362`–`:412`, the three conditions and the gate notes) into `docs/global-strings.md`. Keep the heading, the measuring command, the table and a one-line pointer. Shorten the retired-row narratives to one sentence each, citing the bundle that retired them. Expected landing is about 360 lines, and nothing is lost. |
| **PC-76** | `automated-tests-§4`, anti-pattern #51 | — | Info | **Carried and re-measured.** The newest bundle, `docs/automated-tests/20260927-031723/` (sha `a663bc6`, clean), is **49 commits** behind HEAD `8626790`. It predates the kit-35 sighted gate, so its manifest has no `suites.complexity.blindFiles`. `RESULTS.md:15` still names the retired `/wow-addon:bump-version`; the vendored runner now writes `/dev-copilot:bump-version`. This run's sighted measurement: 0 warnings, `blindFiles` 0, **max CCN 15**, 1314 functions, 57,375 NLOC, against the record's 14 / 1135 / 56,489. The CCN-15 function is `listSettings` (`settings/Slash.lua:363-422`). The old blind `lizard` did not see it, so it is newly measured, not a regression. It is real branching (four sub-forms of `list`: category, formatstring, bare, filtered), not defaulting, and it sits at the threshold, not over it. `settings/Schema.lua` is 1094 lines (1070 in the record) and is still the only file in the band. Releases are the checkpoint, and none has been cut since 1.6.0, so this is not a finding. | Run `bash tests/_kit/run-automated-tests.sh` as part of the next release and do not hand-edit. Optionally peel `listSettings`' two keyword listings into named helpers when that file is next touched, so the function moves off the threshold. |
| **PC-106** | `audit-review-history` (issue store) | — | Info | **Issue #8 (`state:will-not-do`) asserts a refusal the code has since reversed.** Its body reads "PrettyChat is single-profile by design; per-character / per-realm scoping will not be exposed". The Profiles page (`settings/Profiles.lua`, AceDBOptions, `SP-PC-01`) now exposes exactly that, and the README tells players they can "give a character, class, realm or faction its own". No rule is failed: the decline was never a register row. The issue store is the working queue, though, and a closed refusal the tree contradicts reads as the live decision. | Comment on #8 that `SP-PC-01` (2026-09-29) superseded it, citing `options-ui-§3`. Then either relabel it `state:done` or leave `state:will-not-do` with the supersession on record. No code change. |

---

## Recorded deviations: accepted, not counted

Each of these matches a **ratified** row in `docs/ARCHITECTURE.md` → `## Documented deviations`.
Following `audit-review-history`, each is recorded as accepted with its rule and Decided date and
counts toward neither tally. **Every trigger was evaluated against this tree, and every evidence id
was resolved.**

| Rule | Row | Decided | Trigger evaluated today | Evidence ids |
|---|---|---|---|---|
| `performance-§12` | `:284`, no perf harness wired | 2026-08-05; re-checked 2026-09-02, 2026-09-08, 2026-09-24, 2026-09-29 | **Not fired.** The sweep was re-run: 43 lines. The only combat-time path is the watcher's boundary handler (`modules/Override.lua:140-145`). The two `C_Timer.After(0, …)` calls are one-shot settings-panel redraws (`settings/Panel.lua:533`, `settings/Profiles.lua:143`). No `OnUpdate`, no ticker. The sweep page's line drift is filed under PC-104(2), not here. | `LIBKA0S-12` → issue #10 ✓; issue #14 ✓ |
| `layout-§2` | `:285`, `GlobalStrings/` PascalCase root folder | 2026-08-05; cap half retired 2026-09-08 | **Not fired.** The folder has not moved, and `layout-§2` still requires lowercase. | `PC-49` → `docs/audits/2026-08-04/` ✓; `PC-R-05` → `docs/reviews/2026-08-05/` ✓ |
| `toc-file-§1` | `:286`, brand Title and Author | 2026-07-12; narrowed 2026-09-24 | **Not fired.** | issue #7 ✓ |
| `options-ui-§6` | `:287`, TreeGroup pane instead of 50/50 | 2026-07-31; re-shaped 2026-09-03 | **Not fired.** `O.RenderGrid` (`libs/LibKa0s/OptionsWidgets.lua:1041`) still lays out at `HALF` (`:76`) with no third ratio. | `LIBKA0S-06` → `docs/audits/2026-08-04/` ✓ |
| `options-ui-§13` | `:288`, vertical string list inside a category tab | 2026-09-03 | **Not fired.** v2.69.0's nav rail is a vertical form for the **first** level only (`options-ui-§13`, "A nav rail is permitted as a first level"). The trigger asks for a vertical **secondary** division, and nothing has named one. The selection is session-only, and no third level exists. | in-code justification above `buildCategoryBody` ✓ |
| `testing-§1` | `:289`, `tests/loader.lua` beside the kit's | 2026-08-02 | **Not fired.** Kit revision 37's `makeEnv` still writes through to `_G` (`tests/_kit/loader.lua:22`). | `LIBKA0S-01` → `docs/audits/2026-08-04/` ✓ |
| `localization-§1` | `:290`, English only | 2026-08-05 | **Not fired.** `locales/` holds only `enUS.lua`. Terminal compliant state. | LibKa0s README "The `L` trap" (named, not an id) ✓ |
| `options-ui-§15` | `:291`, `[Test] [Reset all settings]` | 2026-09-02; moved into the library 2026-09-03 | **Not clearly fired.** The nuance carries from 2026-09-23. `options-ui.md:374` names "the composer's `leadButton`" as where a one-shot test action MAY stay, but inside the *Test mode* bullet for an addon **with** a positionable display ("beside it"). For a frameless addon the standard still names no place. The owner may retire the row on the reading that `leadButton` is now a named place. | none cited |

**Issue store (18 issues).** Every issue carries one `state:` label and one `severity:` label. There
is no `[status]` title prefix (anti-pattern #62 is clear) and no `docs/pending/LEDGER.md`. The closed
`state:will-not-do` issues #1, #5, #7, #8, #10–#14, #16 and #17 decline nothing a rule requires,
except #10, which has its register row. None of them owes a row (#8's staleness is PC-106).

## Closed since 2026-09-23

| ID | Why it is closed |
|---|---|
| PC-82 | Span bundle `docs/revendor/2026-09-24-v1.16.0-v1.54.2/` (`PC-25`). The later re-vendors have bundles up to v1.68.1, and the two that do not are PC-103. |
| PC-81 | Categories **Defaults** is page-wide (`ResetCategoriesPage`, `settings/Panel.lua:756`, `PC-06`). |
| PC-87 | The Test tooltip names the debug console (`settings/Schema.lua:193`, `PC-10`). |
| PC-77 (+ PC-78, PC-79, PC-80) | The TOC annotates every load-bearing line (`PrettyChat.toc:40-113`, `PC-18`). |
| PC-83 | The generator now lives at `tools/split_globalstrings.py` and is ignored (`.pkgmeta:45`, `PC-19`). |
| PC-84 | **Closed by rule change**: `events-frames-taint-§1`'s boundary-watcher carve-out (v2.65.0). The watcher meets all of its conditions (01, *Patterns*). |
| PC-85 | `NS.Util.SafeRegisterEvents` plus `NS.RejectedEvents` (`modules/Override.lua:212`, `PC-12`). |
| PC-86 | Items 1–5 and 7 were fixed (`PC-20`). Items 6 and 8 were adjudicated "leave unchanged" by the 2026-09-23 consolidated review (PRETTYCHAT-A-10) and are not re-filed. |
| PC-102 | **Closed by rule change**: `architecture-§4`'s threshold (v2.65.0). `## Message Bus` cites it (`docs/ARCHITECTURE.md:148`). |
| PC-73, PC-88, PC-89 | Register narrowed, retired and re-pointed (`PC-21`, `docs/ARCHITECTURE.md:321-335`). |
| PC-90 (+ PC-91) | The runner reads the register (`RESULTS.md` *Perf*), and `docs/testing.md:248` names the exemption. |
| PC-92 | The band rows no longer carry the over-cap file. The exempt dump is named as a carve-out. |
| PC-93 | **Closed by rule change**: `compat`'s applicability condition (v2.65.0). The legacy rung was deleted (`PC-15`). |
| PC-94 | Defaults are declared once in `defaults/Profile.lua` (`PC-14`). |
| PC-95, PC-99 | The `NS.Schema` publish is idempotent (`settings/Schema.lua:8-9`). All eleven files carry self-naming headers (`PC-16`). |
| PC-96 | The General page draws **Defaults**, bound to `ConfirmResetAll` (`settings/Panel.lua:722`, `:732`). |
| PC-97, PC-98 | Pillow is in `DEPENDENCIES.md:163`. The 1.5.0 row was reworded (`PC-24`). |
| PC-60 | Conventional notes were added per group (`PC-18`). |
| PC-69 | **Closed by rule change**: `options-ui-§13` now says a consumer **MUST NOT** duplicate the library-drawn strip's invariance case. |
| PC-100 | **Closed by rule change**: `architecture-§1` names `local _, NS = ...` compliant. |
| PC-101 | `docs/performance.md` is 41 lines. The sweep moved to `performance-sweep.md` (`PC-23`). |
