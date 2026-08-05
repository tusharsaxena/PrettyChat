# 01 — Current State (Ka0s Pretty Chat)

**Run date:** 2026-08-05
**Audited against:** Ka0s WoW Addon Standard **v2.21.0 (2026-08-04)**
**Playbook:** `AUDIT.md` (fetched from `raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master`)
**Addon version:** `1.4.0` (`PrettyChat.toc:5`) · HEAD `a2ba8f8`
**ID prefix:** `PC-` (assigned at the 2026-07-12 run; reused)

## Provenance of the rules

`AUDIT.md` and `standards/STANDARDS.md` were fetched with `curl -fsSL` and read verbatim; every one of
the **25 section files** the index's *Sections* list links was then fetched from
`$RAW/standards/standards/<file>.md` and read: `layout`, `toc-file`, `library-stack`, `architecture`,
`savedvariables`, `options-ui`, `standalone-windows`, `preview-mode`, `slash-commands`, `localization`,
`events-frames-taint`, `public-api`, `compat`, `debug-logging`, `packaging`, `lint`, `testing`,
`performance`, `automated-tests`, `documentation`, `audit-review-history`, `versioning-git`,
`naming-cheatsheet`, `anti-patterns`, `open-evolutions`. (`tiered-layout.md` appears only inside the
v2.0.0/v1.5.0 changelog entries as frozen history and 404s at the section path — correctly, it was
renamed to `layout.md`.) No rule in this bundle was reconstructed from memory.

Sections are cited as `filename-§N`; the retired global `§N.M` notation is not used.

---

## 1. Layout (`layout`)

Modular skeleton present and correct: `core/` (9 files), `defaults/` (2), `settings/` (4),
`locales/` (1), `modules/` (1), plus `libs/`, `tests/`, `docs/`, `media/`. Subfolders lowercase,
Lua files PascalCase, `libs/` lowercase (`layout-§2`).

`media/` uses typed subfolders only — `media/fonts/`, `media/logos/`, `media/screenshots/`
(`layout-§3`); nothing loose.

**Outside the skeleton:** `GlobalStrings/` — a root-level **PascalCase** folder holding 26 generated
chunk files, the 23,842-line source dump, a `README.md` and `split_globalstrings.py`. Recorded as an
accepted exception at `CLAUDE.md:8`. Since the 2026-08-04 run the chunks were re-split: every shipped
chunk is now **882 lines** (`GlobalStrings/GlobalStrings_001..026.lua`), under both `layout-§1`'s
1500-LOC cap and its 1000-LOC on-notice band. The unshipped dump `GlobalStrings/GlobalStrings.lua`
(23,842 lines) remains over the cap and is dispositioned in the watch list.

Largest addon-owned source file: `settings/Panel.lua` at 423 lines. No addon file is in the
1000–1500 band.

## 2. TOC (`toc-file`)

`PrettyChat.toc` carries, in `toc-file-§1` order: `Interface: 120007`, `Title` (rainbow-escaped),
`Notes`, `Author: aDd1kTeD2Ka0s`, `Version: 1.4.0`, `IconTexture`, `SavedVariables: PrettyChatDB`,
`OptionalDeps`, `DefaultState`, `Category-enUS: Chat & Communication`, `X-License: MIT`,
`X-Standard: …/WowAddonStandards`, `X-Curse-Project-ID: 919766`. No `Dependencies` line. Single
Interface value; file ends with one trailing CRLF newline (`toc-file-§5`).

File listing sections: `# Libraries` → `# Locales` → `# Core` → `# Defaults` → **`# GlobalStrings`** →
`# Modules` → `# Settings`. The library block lists the single aggregate
`libs\LibKa0s\LibKa0s.xml` once, after Ace3 (`toc-file-§4`, `library-stack-§7`) — no individual
module `.lua` lines, no `embeds.xml`.

`SavedVariables` declares **one** global; `toc-file-§2` mandates two (`PrettyChatDB, PrettyChatPerfDB`).

## 3. Library stack (`library-stack`)

Vendored under `libs/`: `LibStub`, `CallbackHandler-1.0`, `AceAddon-3.0`, `AceDB-3.0`,
`AceConsole-3.0`, `AceGUI-3.0` (with its full `widgets/` set), and `LibKa0s/`. No `externals:` in
`.pkgmeta`. `AceEvent-3.0`/`AceTimer-3.0` are deliberately absent — the addon `LibStub`s neither.

`libs/LibKa0s/` carries **all eight ship files plus LICENSE** — `Core.lua`, `DebugLog.lua`,
`Slash.lua`, `Options.lua`, `OptionsWidgets.lua`, `OptionsScroll.lua`, `Perf.lua`, `PerfPanel.lua` —
and `LibKa0s.xml` lists exactly those eight. Both multi-file majors are complete
(Options shell + both attach files; Perf shell + `PerfPanel.lua`), so there is no partial-vendoring
shape (anti-pattern #48). The vendored `testkit` is at `tests/_kit/`, **not** under `libs/`
(`testing-§1`). Nothing under `libs/` or `tests/_kit/` is patched locally as far as this repo can
show; the authoritative `diff -r` against the sibling `../LibKa0s` repo was **not run** — see
`03_EVIDENCE.md`.

**Adoption:** four of five majors are wired, each through its own setup file with a descriptor and a
degradation stub — Core (`core/CoreSetup.lua:41,101-110`), DebugLog (`core/DebugLogSetup.lua:39,109-152`),
Options (`settings/OptionsSetup.lua:17,104-153`), Slash (`settings/Slash.lua:72,158-179`). **Perf is
declined**, recorded at `CLAUDE.md:6` and `docs/pending/LEDGER.md:66`.

## 4. Architecture (`architecture`)

`local addonName, NS = ...` at the head of every source file; no `_G[addonName]` table; no public API
surface (`public-api` N/A). `core/PrettyChat.lua:14` promotes `NS` via
`AceAddon:NewAddon(NS, addonName, "AceConsole-3.0")`, and `core/CoreSetup.lua:106-110` reclaims
`NS.Print`/`NS.Format` from the library printer after the embed (anti-pattern #36 handled, and the
mock models the clobber).

Schema-as-single-source is present: `settings/Schema.lua` builds one row per setting from
`defaults/Defaults.lua`, validates every path at load, and `NS.Schema.Set` is the single write seam
that the panel (`settings/OptionsSetup.lua:121-123`) and the slash layer both take.

**No message bus.** `docs/ARCHITECTURE.md:119` states it outright; cross-module wiring is direct table
access (`modules/Override.lua` → `NS.Schema.NotifyPanelChange`, `settings/Schema.lua` →
`NS.Helpers.RefreshScalars`). The addon registers **zero** events, timers and tickers.

## 5. SavedVariables (`savedvariables`)

AceDB tree under `PrettyChatDB`; profile defaults in `defaults/Profile.lua`; `core/Database.lua`
carries `SCHEMA_VERSION = 1`, a `global.schemaVersion` default and an idempotent `RunMigrations`
runner with an empty migration table. Defaulting uses `== nil` where falsy is meaningful
(`modules/Override.lua:31`), so `savedvariables-§5` / anti-pattern #54 is clean. No
`PrettyChatPerfDB` (the second sanctioned global) exists.

## 6. Options UI (`options-ui`)

The panel is built by `LibKa0s-Options-1.0` from a descriptor (`settings/OptionsSetup.lua:104-153`):
`parentTitle`, `mainPanelName`, printer/debug forwarders, the `get`/`set`/`applyDefault` write seam,
`rowsForPage`/`allRows`, and a `buildMain` hook for the landing page. Fields deliberately not passed
are each named with a reason at `:137-152`. `settings/Panel.lua` registers nine sub-pages and owns
only page bodies. The per-string editor is a bespoke **40/60** three-row block
(`settings/Panel.lua:127-128`), not the schema-driven 50/50 grid.

The library-absent branch (`settings/OptionsSetup.lua:19-97`) is the standard's one documented
**load-completing** stub, with its measured justification written down at `:26-33`.

## 7. Slash (`slash-commands`)

`NS.COMMANDS` is an ordered table of ten positional triples (`settings/Slash.lua:45-70`) dispatched
through `LibKa0s-Slash-1.0` (`:72,158-179`), with `/pc` + `/prettychat` and the mandated cyan `[PC]`
tag from the shared printer. Verbs: `help`, `config`, `version`, `list`, `get`, `set`, `reset`,
`resetall`, `test`, `debug`. The reserved verb **`perf` is not registered**.

## 8. Debug logging (`debug-logging`)

The console is the library's, wired at `core/DebugLogSetup.lua:109-152` — frame-name prefix, title,
`NS.Const.FONT_MONO`, slash token, the `isEnabled`/`setEnabled` pair over the session-only
`NS.State.debug` flag, call-time `print`/`safeToString` forwarders, `initSummary`, and an
`onVisibilityChanged` hook. `NS.Debug` is the bare gated sink. The stub at `:41-106` answers **19**
members plus `buffer`, with the two omissions (the line formatters) explained at `:64-67`. The
monospace font is applied by path and is **not** registered with LibSharedMedia
(`core/Constants.lua:54-60`).

## 9. Testing (`testing`) and the automated-test record (`automated-tests`)

`tests/_kit/` holds the vendored kit (`framework.lua`, `loader.lua`, `mock_base.lua`, `README.md`,
`run-automated-tests.sh`, mode `0755`). `tests/wow_mock.lua` is a thin extender over
`mock_base.lua`; `tests/loader.lua` (155 lines) survives as an addon-side per-instance environment
factory that delegates to `Loader.makeEnv`/`Loader.tocFiles`. 17 suites, **255 cases**, and
`docs/test-cases.md` is byte-in-sync with `--list`. `.gitattributes` carries `*.sh text eol=lf`.

`docs/automated-tests/` holds three frozen bundles (`20260804-182235`, `-214445`, `-233338`), a
generated `RESULTS.md` trend line with two watch-list tables, and `README.md`. The retired
`docs/complexity.md` is **absent** — correctly. No release run has been recorded
(`manifest.json: "release": null`).

**There is no `tests/perf.lua`**, so the `perf` suite is a standing `skip`.

## 10. Performance (`performance`)

Not wired: no `core/PerfSetup.lua`, no `NS.Perf`, no buckets, no `perf` verb, no `PrettyChatPerfDB`,
no `tests/perf.lua`, and neither `debugprofilestop` nor `PrettyChatPerfDB` in `.luacheckrc`. The
decline is recorded at `CLAUDE.md:6` and `docs/pending/LEDGER.md:66` on two structural grounds (no
event/timer path; `suspend` would flip chat formatting mid-fight).

Complexity **is** measured and current: `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` run today
is identical to `docs/automated-tests/20260804-233338/complexity.txt` — 51,248 nloc, 528 functions,
avg CCN 1.9, **0 warnings**, max CCN 12.

## 11. Packaging, lint, compat, versioning

`.pkgmeta`: `package-as: PrettyChat`, `enable-nolib-creation: no`, no `externals:`, ignores
`.luacheckrc`, `.gitignore`, `.gitattributes`, `docs`, `tests`, `_dev`, `*.bak`, the GlobalStrings
build-time assets and the project-page art. `.luacheckrc`: `std = "lua51"`, scoped excludes, commented
`globals`. `core/Compat.lua` exists and is TOC-loaded first. Version `1.4.0` is semver and matches the
README badge row and the top Version History row; work is trunk-based on `master`.

## 12. Documentation (`documentation`)

**Root doc set** — `README.md` (full, player-facing), `CLAUDE.md`, `DEPENDENCIES.md`, `LICENSE`. No
fourth doc. `DEPENDENCIES.md` is evidence-based, split runtime/development/release, gives WSL2/Ubuntu
commands with the `pipx` route and the PEP 668 warning, and a verification line per tool.

`CLAUDE.md` is **64 lines** and is a full agent brief, not a stub: six accepted-deviation paragraphs
(`:5-13`) precede `## Standards compliance (read first)` at `:14`, which the mandated item order puts
third.

**`docs/` canonical trio** — `ARCHITECTURE.md`, `testing.md`, `smoke-tests.md`: all three present. No
`docs/agent-context.md`, and `CLAUDE.md:33-48` states it must never return.

**The five required topic-detail docs** — `test-cases.md` ✅ (generated, in sync),
`automated-tests/README.md` ✅, `automated-tests/RESULTS.md` ✅ (generated, single path),
**`performance.md` ❌ absent**, **`perf-runs/README.md` ❌ absent**.

**The three-place standards reference** — all three present: `PrettyChat.toc:12`, `README.md:6`,
`CLAUDE.md:14`.

README structure departs from the canonical order in two places: `## Unreleased` at `:15` (between
Description and `## What's new`) and `## Credits` at `:120` (between Troubleshooting and Issues). One
angle-bracket placeholder survives in shipped content at `:116`. `docs/ARCHITECTURE.md` has no
`## Message Bus` heading (the content sits inside `## Event Subscriptions` at `:117-119`).

**Commit gate vs release gate:** `docs/testing.md:113-121` and `docs/automated-tests/README.md:19-29`
both state the commit half correctly (`lint` + `tests` gate; `perf`/`complexity` recorded, a missing
tool is a skip) and say a full bundle is produced at release before the tag — but **neither states
v2.21.0's release gate**: all four suites at `pass` plus `suites.complexity.warnings == 0` at the tag,
with a `skip` blocking as not-evaluated. `RESULTS.md:11-13` carries the same half-statement.

## 13. Not applicable

`standalone-windows` (no non-secure main window of the addon's own — the debug console is the
library's), `preview-mode` (no positionable display; `/pc test` is a chat preview), `public-api`
(nothing exposed).
