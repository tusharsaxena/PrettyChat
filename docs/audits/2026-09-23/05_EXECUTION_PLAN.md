# 05 — Execution plan (Ka0s Pretty Chat)

**Run date:** 2026-09-23 · **Standard:** v2.64.0 · Keyed to `02_DEVIATIONS.md` and
`04_TECHNICAL_DESIGN.md`.

Ordered hand-off to the remediation engagement. **Upstream first** (Sprint 0 standard decisions,
Sprint 1 LibKa0s), then the **whole-folder re-vendor** (Sprint 2), then this addon (Sprints 3–5),
then the release record (Sprint 6). Every step names its IDs and its acceptance check. The green
gate (`lua tests/run.lua` + `luacheck .`, both through `ka0s-bounded`) runs before every commit.

Scope of this plan: **26 root deviations + 4 dependents = 30 entries** (High 1, Medium 2, Low 24,
Info 3 counting dependents; MUST 24 counting dependents). Every entry appears below — the three Info
rows as confirm-only steps.

---

## Sprint 0 — Upstream decisions (WowAddonStandards) — no PrettyChat code

| Step | IDs | Action | Done when |
|---|---|---|---|
| 0.1 | PC-84 | File an issue: extend `events-frames-taint-§1`'s carve-out to a lazily-created, fully-stood-down private frame for boundary events, or state that such an addon records a row; cite the `library-stack-§1` note that already names this frame. | Issue filed with this bundle's ID; ruling recorded in the standard's changelog. |
| 0.2 | PC-102 | File an issue: does `architecture-§4`'s "any module that registers game events" arm bind a one-module addon whose only registrant is that frame? | Ruling recorded. |
| 0.3 | PC-93 | File an issue: does `compat`'s "every addon MUST ship `core/Compat.lua`" bind an addon with no addon-specific shim (`library-stack-§7` already says PrettyChat carries none)? | Ruling recorded. |
| 0.4 | PC-100 | File an issue: permit `local _, NS = ...` in `architecture-§1` where the file never reads the name. | Ruling recorded (Info — no addon change either way). |
| 0.5 | PC-69 | File an issue: `options-ui-§13`'s Testing MUST vs `testing-§8` for a library-drawn strip. | Ruling recorded. |
| 0.6 | PC-96 | File an issue: make the subcategory Defaults button's existence explicit (or not) in `options-ui-§5`. | Ruling recorded. |
| 0.7 | PC-82 (process) | Optional: raise the playbook's fixed High for an unrecorded re-vendor tag against its own impact table. | Issue filed; no dependency for this addon. |

Sprint 0 does not block Sprints 1–5: every addon step that depends on a ruling is written to take
either outcome (marked **[R0.n]**).

## Sprint 1 — Upstream code (LibKa0s) — before any re-vendor

| Step | IDs | Action | Done when |
|---|---|---|---|
| 1.1 | PC-90 (→ PC-91) | `testkit/run-automated-tests.sh`: detect a `performance-§12` row under `## Documented deviations` (or accept an explicit consumer fact) and emit the second sanctioned `perf` skip reason in `skipReason` and in the generated standing section. Kit self-test with two fixtures. Changelog entry. | LibKa0s suite green; the fixture with the row writes "performance-§12 no-combat-path exemption". |
| 1.2 | PC-69 **[R0.5]** | LibKa0s suite case pinning the tab strip's wrap invariance (band + every row offset identical across selections, per-atlas-height mock, `-- red under:`). | Case red under "read pitch off the selected tab", green otherwise. |
| 1.3 | — | Tag the LibKa0s release carrying 1.1 (and 1.2). | Tag pushed; `git -C ../LibKa0s tag` shows it. |

## Sprint 2 — Re-vendor LibKa0s whole, and close the bundle backlog

| Step | IDs | Action | Done when |
|---|---|---|---|
| 2.1 | (library-stack-§7) | Copy the new tag's **entire** `LibKa0s/` over `libs/LibKa0s/` and `testkit/` over `tests/_kit/`; move `CLAUDE.md:42`'s provenance line in the **same commit**; `git update-index --chmod=+x tests/_kit/run-automated-tests.sh`. Stand-alone re-vendor commit (versioning-git SHOULD). | `diff -r` of both payloads against the tag empty; `tests/test_vendor_sync.lua` green; `git ls-files -s tests/_kit/run-automated-tests.sh` → `100755`; full suite and lint green. |
| 2.2 | — | `docs/revendor/<date>-v<newtag>/` bundle (`01_DELTA.md`, `05_SUMMARY.md` at least) for 2.1. | Folder name carries the tag. |
| 2.3 | **PC-82** | One consolidated backlog bundle `docs/revendor/<date>-v1.18.0-v1.53.0/`: `01_DELTA.md` listing the 26 unrecorded tags with the commit that carried each (`git log --format='%h %ad %s' -- libs/LibKa0s`), `05_SUMMARY.md` recording what was adopted (Launcher at v1.39.0, the latch after v1.42.0) and that the rest were carried by sweeps. | Re-running `AUDIT.md`'s recorded-vs-vendored check prints **0** unrecorded tags. |

## Sprint 3 — Player-visible fixes (Medium)

| Step | IDs | Action | Done when |
|---|---|---|---|
| 3.1 | **PC-87** | Reword the Test tooltip key (`settings/Schema.lua:162`) and the `enUS` manifest entry together; add the source-text case. | Tooltip says the console; `test_locale` and the prose gate green. |
| 3.2 | **PC-81** | **Owner decision first.** Either make the Categories Defaults page-wide (one `Schema.ResetRows` batch over all eight categories, new tooltip key, optional confirmation popup, README/settings-panel/schema/smoke-test docs in the same commit) **or** add a `## Documented deviations` row keyed `options-ui-§13` with the drafted trigger. | Chosen scope asserted in `tests/test_panel.lua` (footer `OnDefault` included); docs match; no dead `enUS` key. |

## Sprint 4 — Structure and code MUSTs (Low)

| Step | IDs | Action | Done when |
|---|---|---|---|
| 4.1 | **PC-77**, PC-78, PC-79, PC-80, **PC-60** | Comment-only TOC edit: at-line comments on `core\CoreSetup.lua`, `core\DebugLogSetup.lua`, `settings\OptionsSetup.lua`, `settings\Slash.lua` naming what resolves; one conventional note per group. Align `docs/ARCHITECTURE.md:35` and `docs/module-map.md` with the TOC. Optional doc-structure case pinning hub list ↔ TOC comments. | No load-bearing line without a comment; group notes present; suite green. |
| 4.2 | **PC-85** | `registerEvent` helper with `pcall` (+ `C_EventUtils.IsEventValid` front gate), `NS.RejectedEvents` surfaced on `/pc debug` and in `[Init]`; kit `M.__badEvents` case. | One bad name leaves the other registered and is reported; `test_disabled` still green. |
| 4.3 | **PC-84**, **PC-102** **[R0.1, R0.2]** | Apply the rulings: rewrite `## Message Bus`'s reason to the (narrowed) threshold, or add register rows keyed `events-frames-taint-§1` and `architecture-§4` with the drafted triggers. | Hub and register agree with the ruled text; no finding left open. |
| 4.4 | **PC-93** **[R0.3]** | If the MUST stands: minimal `core/Compat.lua` owning the legacy `GetAddOnMetadata` rung, TOC-annotated, `core/EnvSetup.lua` calling it; update the `compat-layer.md` N/A row text. If it does not: nothing. | `grep -n 'GetAddOnMetadata(' core` outside `core/Compat.lua` → only the `C_AddOns` form. |
| 4.5 | **PC-94** | Characterization cases for `IsAddonEnabled`/`GetVisibility`; add `defaults/Global.lua` and `NS.GeneralDefaults`; read them from `MASTER_SPEC`, the getters, the visibility row and `Database.defaults` (assembled at `OnInitialize`). | Each default literal appears once under `defaults/`; characterization cases unchanged and green. |
| 4.6 | **PC-95** | `NS.Schema = NS.Schema or {}` in `settings/Schema.lua`. | Suite green. |
| 4.7 | **PC-96** **[R0.6]** | Enable the General page Defaults button over `ResetCategory("General")`; update `docs/settings-panel.md:79`; extend `tests/test_launcher.lua` to press the real button. | Button present; minimap row and console row survive it (existing assertions). |
| 4.8 | **PC-83** | `git mv GlobalStrings/split_globalstrings.py tools/split_globalstrings.py`; `.pkgmeta` gains `- tools`; update DEPENDENCIES.md, `docs/common-tasks.md`, `docs/global-strings.md`, `GlobalStrings/README.md`, `tests/prose_waivers.lua:7`, the `layout-§2` register row's *Why*; verify the script's repo-root paths. | `git ls-files '*.py' '*.sh'` shows the generator under `tools/`; `.pkgmeta` checks (a)/(b)/(c) clean; `python3 tools/split_globalstrings.py` exits 0 on an unchanged dump. |
| 4.9 | PC-69 **[R0.5]** | Only if the host MUST is kept: the host wrap-invariance case (design C9). | Case present with `-- red under:`; otherwise closed by ruling. |

## Sprint 5 — Documentation and register hygiene (Low)

| Step | IDs | Action | Done when |
|---|---|---|---|
| 5.1 | **PC-73** | Narrow the `toc-file-§1` register row to the brand mark; note the narrowing in the retired block. | Row names no Wago clause. |
| 5.2 | **PC-88** | Retire the `debug-logging-§2` row into the retired block with the reason. | Register holds only live deviations. |
| 5.3 | **PC-89** | Re-point `LIBKA0S-05` (register row, `locales/enUS.lua:26`, `tests/test_locale.lua:237`) at a resolvable source. | Every id the register cites resolves. |
| 5.4 | **PC-86** | Sync pass over the eight drift items (General explainer ×4 docs, load order, Slash minor, `STRING_VSPACER` comment, the stale `IsAddonEnabled` comment, `scope.md` "doc index", `.pkgmeta` line-number citations → `packaging`, the doc-map out-of-scope sentence → `docs/automated-tests/<run>/`). | Each quoted line in `03_EVIDENCE.md` §E15 reads true against the code. |
| 5.5 | **PC-97** | Pillow entry under *Release / assets* in `DEPENDENCIES.md`. | Entry with why/install/verify and "not needed to build or test". |
| 5.6 | **PC-98** | Reword the two jargon highlights in `README.md:74` through the de-AI pass. | No codebase term in the Version History row. |
| 5.7 | **PC-99** | Self-naming first comment in the eleven files listed. | The header check prints `yes` for all 20 source files. |
| 5.8 | **PC-91** | `docs/testing.md:238-239` names the `performance-§12` exemption as the reason `perf` is skipped. | Sentence names the exemption. |
| 5.9 | PC-101 (Info) | Optional: trim `docs/performance.md`'s first screen to §3's four facts, sweep below. | Owner's call; no finding either way. |
| 5.10 | PC-100 (Info) | None — tracks ruling 0.4. | — |

## Sprint 6 — Release record

| Step | IDs | Action | Done when |
|---|---|---|---|
| 6.1 | PC-76 (Info), **PC-90** check, **PC-92** | At the next release: `tests/_kit/run-automated-tests.sh` (all four suites) on the re-vendored kit. Set the over-cap row's **Disposition** (the one authored cell) to point at the census row. Write `ANALYSIS.md`; regenerate `docs/test-cases.md` and the README `[tests]` badge in the same change. | New `RESULTS.md` row carries the commit SHA and clean mark; `perf` skip names `performance-§12`; the GlobalStrings row's disposition points at `docs/ARCHITECTURE.md` → Files over the 1500-line cap; zero CCN > 15. |
| 6.2 | — | Re-audit (`/wow-addon:standards-audit`) into a new dated folder; this bundle stays frozen. | New bundle's tally reflects the closures above. |

---

## Traceability

| ID | Grade | Level | Sprint.step |
|---|---|---|---|
| PC-82 | High | MUST | 2.3 |
| PC-81 | Medium | MUST | 3.2 |
| PC-87 | Medium | MUST | 3.1 |
| PC-77 | Low | MUST | 4.1 |
| PC-78 (← PC-77) | Low | MUST | 4.1 |
| PC-79 (← PC-77) | Low | MUST | 4.1 |
| PC-80 (← PC-77) | Low | MUST | 4.1 |
| PC-83 | Low | MUST | 4.8 |
| PC-84 | Low | MUST | 0.1 → 4.3 |
| PC-85 | Low | MUST | 4.2 |
| PC-86 | Low | MUST | 5.4 |
| PC-88 | Low | MUST | 5.2 |
| PC-89 | Low | MUST | 5.3 |
| PC-90 | Low | MUST | 1.1 → 2.1 → 6.1 |
| PC-91 (← PC-90) | Low | MUST | 5.8 |
| PC-92 | Low | MUST | 6.1 |
| PC-93 | Low | MUST | 0.3 → 4.4 |
| PC-94 | Low | MUST | 4.5 |
| PC-95 | Low | MUST | 4.6 |
| PC-96 | Low | contract | 0.6 → 4.7 |
| PC-97 | Low | MUST | 5.5 |
| PC-98 | Low | MUST | 5.6 |
| PC-102 | Low | MUST | 0.2 → 4.3 |
| PC-73 | Low | MUST | 5.1 |
| PC-69 | Low | MUST | 0.5 → 1.2 / 4.9 |
| PC-60 | Low | SHOULD | 4.1 |
| PC-99 | Low | SHOULD | 5.7 |
| PC-76 | Info | — | 6.1 |
| PC-100 | Info | — | 0.4 / 5.10 |
| PC-101 | Info | — | 5.9 |

Thirty rows: 26 roots + 4 dependents. High 1 · Medium 2 · Low 24 · Info 3. MUST 24 (20 roots + 4
dependents), SHOULD 2, contract 1, observation 3.
