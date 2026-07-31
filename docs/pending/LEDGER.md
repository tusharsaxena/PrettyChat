# Pending-items ledger

Decision record for pending items in this addon — TODO/FIXME markers, unexecuted audit and
review plan steps, doc open questions, open GitHub issues, and recorded-but-unacted Claude
memory. Maintained by `/wow-addon:pending-audit`; do not hand-edit rows it owns.

Each run re-discovers pending items and matches them against this table by **ID + evidence
hash**. A `done` or `wont-do` row closes the question permanently — the item is not raised
again. A `deferred` row keeps the item alive but quiet: it reappears only as a collapsed count.
If an item's evidence text later changes, its hash changes, and it is re-interviewed as a
changed item even if it was previously closed.

## Notation

| Marker | Value | Meaning | Re-surfaces? |
|---|---|---|---|
| 🟢 | `done` | Implemented this run | No — closed |
| 🔵 | `wont-do` | User decided it will never be done | No — closed |
| 🟡 | `deferred` | Not now; still on the books | Yes, as a collapsed count |

Green is resolved. Blue is a deliberate, settled close — declining to do something is a
decision, not a failure. Yellow is the only row type still demanding attention, so a column of
yellow is this file telling you what is left. There is deliberately no red: nothing here is an
error state.

## Decisions

| ID | Evidence hash | Source | Decision | Date | Rationale |
|---|---|---|---|---|---|
| PLAN-01 | `8f163e02` | Audit 2026-07-18, PC-37 (`packaging`) | 🟢 done | 2026-07-31 | "Make this consistent with WowAddonStandards and other Ka0s addons." Rewrote `.pkgmeta` to the `packaging.md` minimum template (added `_dev`, dropped the stale `TODO.md` entry) and added two commented project-specific ignore blocks in the BankLedger/PanelMaster house style — the GlobalStrings dev-only source assets and the non-runtime project-page art. ~3.9 MB off the shipped package. |
| PLAN-02 | `7da6f99a` | Audit 2026-07-18, PC-28 (`architecture-§1`) | 🟢 done | 2026-07-31 | "Do the rename now." Mechanical `ns` → `NS` across every `.lua` under `core/ defaults/ locales/ modules/ settings/ tests/`, plus `.luacheckrc` and the whole `docs/` set. The generated `GlobalStrings_0NN.lua` chunks were regenerated through the splitter so they match (verified a pure rename: 0 unpaired diff lines, entry count unchanged at 22,879). |
| PLAN-03 | `c15d2def` | Audit 2026-07-18, PC-10 (`toc-file-§1`) | 🔵 wont-do | 2026-07-31 | PrettyChat is distributed through CurseForge only; there is no Wago listing and none is planned, so `## X-Wago-ID` will never be carried. The CLAUDE.md bullet was reworded from "omitted until a real Wago id is available" to a settled statement so it no longer reads as pending. The MUST remains recorded in the frozen 2026-07-18 audit bundle. |
| PLAN-04 | `950a2209` | Audit 2026-07-18, PC-23 (`options-ui-§6`) | 🟢 done | 2026-07-31 | The 40/60 per-string editor layout was justified in-code but absent from CLAUDE.md, which claims to be the source of truth for intentional divergences. Added it as an accepted-deviation bullet carrying the in-code reason (the right column holds full colour-escaped format strings and a 50/50 split clips them). No code change — the layout stays. |
| DOC-01 | `59c5754f` | `CLAUDE.md:10` | 🟢 done | 2026-07-31 | The "raise upstream" instruction had never been acted on. Filed [WowAddonStandards#2](https://github.com/tusharsaxena/WowAddonStandards/issues/2), which documents **two** contradictions between `toc-file-§5` and `layout-§1` (Locales placement, and Modules vs Settings order) — the second was not previously recorded here. CLAUDE.md now cites the issue instead of carrying a dangling instruction. |
| DOC-02 | `160aae22` | `docs/global-strings.md:10-12` | 🟢 done | 2026-07-31 | The LoadOnDemand sub-addon path was dormant *and* documented as broken-if-reactivated (post-PC-14 the chunks would populate the sub-addon's own namespace). Deleted `GlobalStrings/GlobalStrings.toc` rather than leave a fallback that could not work, and rewrote the docs, the sub-`README.md`, and the splitter (which no longer rewrites a TOC that does not exist) to match. |
| ISS-01 | `25bd6725` | GitHub issue #1 | 🟡 deferred | 2026-07-31 | Refreshing the ~81 default format templates is a taste call about wording and styling that needs a design pass on the actual strings, not a mechanical fix folded into a sweep. GitHub issue #1 stays open. |
| ISS-02 | `67289112` | GitHub issue #2 | 🟡 deferred | 2026-07-31 | A user-defined "Custom" replacement source is real feature work — new schema row source, a ninth panel page, slash surface, and saved-variable shape changes — and deserves its own design pass and branch. GitHub issue #2 stays open. |
| DOC-03 | `f0c024c3` | `docs/ARCHITECTURE.md:84` | 🔵 wont-do | 2026-07-31 | PrettyChat is single-profile by design; per-character / per-realm scoping will not be exposed. The `AceDB-3.0:New(..., true)` default-profile pin stays. The ARCHITECTURE.md line stays as written — it accurately describes behaviour users need to know, so it remains useful documentation rather than tracked debt. |
| DOC-04 | `acf03d7d` | `docs/ARCHITECTURE.md:80` | 🟡 deferred | 2026-07-31 | Known Limitation (load-time snapshot needs `/reload` for newly added globals). Documentation of a real constraint, not debt — it states no intent to change. Kept visible rather than closed. |
| DOC-05 | `0a8cff45` | `docs/ARCHITECTURE.md:81` | 🟡 deferred | 2026-07-31 | Known Limitation (cross-registered globals resolve last-writer-wins). Documentation of a real constraint, already mitigated by the PC-16 tooltip. Kept visible rather than closed. |
| DOC-06 | `586d7473` | `docs/ARCHITECTURE.md:79` | 🟡 deferred | 2026-07-31 | Known Limitation (Retail only, Classic untested). Documentation of a real scope boundary, not debt. Kept visible rather than closed. |
| DOC-07 | `8decfa48` | `docs/ARCHITECTURE.md:82` | 🟡 deferred | 2026-07-31 | Known Limitation (positional `%n$s` is WoW-only; the headless harness asserts graceful degradation instead). Documentation of a real harness constraint, not debt. Kept visible rather than closed. |
