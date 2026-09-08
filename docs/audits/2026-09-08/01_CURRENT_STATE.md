# 01 — Current state (Ka0s Pretty Chat)

**Run date:** 2026-09-08
**Audited against:** Ka0s WoW Addon Standard **v2.39.0 (2026-09-07)** — line 1 of
`standards/STANDARDS.md` on `master`, fetched verbatim with `curl -fsSL` and confirmed before any
measurement was taken. All 26 section files linked from that index's **Sections** list were fetched
fresh into a clean directory (no reuse of any earlier session's copies), plus `standards/ADDONS.md`.
**Playbook:** `AUDIT.md` at the same ref.
**Repo state:** `master` @ `8c06d55` *(Merge branch 'feat/2026-09-07-audit-review-remediation')*,
working tree clean.
**Previous run:** `docs/audits/2026-09-07/` (against v2.38.0). That bundle is **frozen and untouched**.

This addon has a `.toc`, so it is audited against the **addon** rule set, not `library-stack-§7`'s
library applicability list (`AUDIT.md` step 1).

---

## Layout (`layout`)

Modular, exactly the mandated skeleton: `core/`, `defaults/`, `locales/`, `modules/`, `settings/`,
plus vendored `libs/` and `tests/`. Folder casing is lowercase throughout; `media/` holds only
`logos/` and `screenshots/`.

One root folder sits outside the skeleton — `GlobalStrings/` (PascalCase, 26 generated chunks plus a
23,842-line source dump). It is a **ratified register row** (`docs/ARCHITECTURE.md:229`,
`layout-§2`, Decided 2026-08-05). Its **cap half** was retired on 2026-09-08 by v2.39.0's own
amendment: `layout-§1` now caps *generated non-shipping data at its generator rather than at its
output*, and `GlobalStrings/GlobalStrings.lua` earns all three carve-out conditions —
`GlobalStrings/GlobalStrings.lua:1` reads `-- AUTOMATICALLY GENERATED -- Your benefactors send their
regards.`; nothing loads it (`grep -n GlobalStrings PrettyChat.toc` returns nothing); and
`.pkgmeta:39` ignores the whole folder. The repo carries its own gate for this,
`tests/test_layout_cap.lua`, whose case *"every row claiming layout-§1's generated-data carve-out
still earns all three of its conditions"* (`tests/test_layout_cap.lua:348`) re-checks it every run.

Largest authored file: `tests/test_panel.lua` at 1042 lines — inside `layout-§1`'s 1000–1500
on-notice band, which is a compliant state, and recorded as such in
`docs/automated-tests/RESULTS.md:80`. No authored file is over 1500.

## TOC (`toc-file`)

`PrettyChat.toc`, 64 lines. Metadata block carries every required field in order, including
`## X-Standard:` (`:12`) and `## X-Curse-Project-ID: 919766` (`:13`) — the addon *is* published, so
the field is mandatory and present. `## X-Wago-ID` is absent, which `toc-file-§1` makes **optional
(MAY)** for an addon not listed on Wago; see PC-73 for what that means for the register row still
recording it.

Section headers are `# Libraries` (`:15`) → `# Locales` (`:24`) → `# Core` (`:27`) → `# Defaults`
(`:49`) → `# Modules` (`:53`) → `# Settings` (`:56`), which is `toc-file-§5`'s mandated order and
`layout-§1`'s folder load order at once. `libs\LibKa0s\LibKa0s.xml` is listed **once**, after Ace3
(`:22`) — never individual module `.lua` files.

**Load-bearing annotation (`toc-file-§5`).** The denominator was established by reading the seam
files and `core/Constants.lua`, not by counting lines. Four positions resolve something at file
scope, and all four now carry an at-line comment naming what resolves:

| Position | Line | Annotation cited at | What resolves |
|---|---|---|---|
| `core\EnvSetup.lua` | `:33` | `:28-32` | `NS.Meta`, read at file scope by `core/Namespace.lua:8`, `settings/Panel.lua` and `settings/Slash.lua:24` |
| `core\MediaSetup.lua` | `:36` | `:34-35` | `NS.MediaFont`, from which `core/Constants.lua` resolves `FONT_MONO` at load |
| `core\Util.lua` | `:43` | `:40-42` | `NS.Const.Color`, taken as a file-scope upvalue at `core/Util.lua:14` |
| `settings\Panel.lua` | `:64` | `:60-63` | `NS.Helpers` + `NS.Schema`, then `Helpers.RegisterOptionsPage` **called** at file scope |

`core\Constants.lua` (`:37`) and `core\Namespace.lua` (`:38`) carry nothing and are compliant: each
is pinned by the annotated line above it, which is the shape `toc-file-§5`'s worked example
sanctions. The **MUST** half of the 2026-09-07 finding `PC-60` is therefore closed. The **SHOULD**
half is not — see PC-60 below.

## Libraries (`library-stack`)

Vendored: `LibStub`, `CallbackHandler-1.0`, `AceAddon-3.0`, `AceDB-3.0`, `AceConsole-3.0`,
`AceGUI-3.0`, `LibKa0s`. Every one is reached by one of `library-stack-§3`'s three routes — a direct
`LibStub` call, an Ace3 mixin name string (`"AceConsole-3.0"` at `core/PrettyChat.lua:14`), or a
vendored lib reaching another (CallbackHandler). AceEvent-3.0 and AceTimer-3.0 are **not** vendored
and are **not** reached; v2.39.0's `library-stack-§1` now reads *mandatory when used*, and the
register row that recorded the old contradiction was retired on 2026-09-08
(`docs/ARCHITECTURE.md:253-264`).

**LibKa0s provenance:** `CLAUDE.md:34` — `Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s)
v1.27.0 (MIT).` Exactly one hit, in root `CLAUDE.md`; **zero** hits in `README.md`. Both vendored
payloads diff **empty** against tag `v1.27.0` in the sibling repo — see `03_EVIDENCE.md`.

Six of ten majors adopted, each as a descriptor plus a degradation stub in the addon's own setup
file: Core (`core/CoreSetup.lua`), Env (`core/EnvSetup.lua`), Media (`core/MediaSetup.lua`),
DebugLog (`core/DebugLogSetup.lua`), Slash (`settings/Slash.lua:74`), Options
(`settings/OptionsSetup.lua:17`). The addon carries **no** console window, widget maker, dispatcher
or test framework of its own — the compliant state. Pool, Item and Widgets are declined on the
issue store (#13, #12, #11, all `state:will-not-do`); `library-stack-§3`'s prune rule makes those
declines compliant with no register row owed. Perf is declined under a **ratified**
`performance-§12` exemption (`docs/ARCHITECTURE.md:228`).

**Shared media (`library-stack-§8`).** `media/` holds `logos/` and `screenshots/` only — no private
`fonts/`, `icons/` or `textures/` shadowing `libs/LibKa0s/media/`. `core/MediaSetup.lua:99` makes
one `Media.RegisterLSM(addonName)` call fed the addon's own first vararg, and loads before
`core/Constants.lua`. The DebugLog descriptor carries `addonName = addonName`
(`core/DebugLogSetup.lua:125`). The `MakeCloseButton(` grep returns exactly the wrapper definition,
its degraded twin and one test call — no direct `lib.`/`Core.`/`NS.DebugLog.` reach.

## Architecture (`architecture`)

`core/Namespace.lua` bootstraps `NS`; AceAddon-3.0 at `core/PrettyChat.lua:14`; one feature module
(`modules/Override.lua`). **No message bus.** `architecture-§4`'s applicability clause was examined:
the addon defines zero messages (`grep SendMessage\|RegisterMessage` over the authored tree returns
nothing) and has one feature module. The combat watcher that registers `PLAYER_REGEN_*`
(`modules/Override.lua:93`) is recorded in the `performance-§12` register row. `docs/ARCHITECTURE.md`
carries `## Message Bus` (`:125`) saying so. Not filed this run — the 2026-09-07 `PC-62` was retired
at intake by the cycle's own triage.

## SavedVariables (`savedvariables`)

AceDB via `core/PrettyChat.lua`; profile defaults in `defaults/Profile.lua`; `schemaVersion` and an
idempotent migration runner in `core/Database.lua:14,30`. `savedvariables-§5` checked: the one
`or`-default in the tree, `modules/Override.lua:48` (`self.db.profile.visibility or "always"`), is
over a string whose falsy state is not a user choice; `enabled`, whose stored `false` **is**, uses
`== nil` at `modules/Override.lua:32`.

**No migration is owed for `General visibility`.** `options-ui-§15` requires one where a *show only
in combat* boolean shipped at that path. `git log -S` over `defaults/Profile.lua` and
`settings/Schema.lua` finds no `inCombat` and no prior `visibility` value; the dropdown was born a
four-value dropdown. Recorded as compliant, not filed.

## Settings panel (`options-ui`)

Built by `LibKa0s-Options-1.0` from a descriptor (`settings/OptionsSetup.lua`). Nine content checks
were run from the schema rather than from the screen:

- **(a) Strips.** Two rendered pages, both with a strip. `General` → `H.RenderTabbedSchema`
  (`settings/Panel.lua:125`), one tab, drawing a one-tab strip. `Categories` → `H.TabStrip`
  (`settings/Panel.lua:618`) with eight tabs derived from `Schema.CATEGORY_ORDER`. The landing page
  is the host's `buildMain` and is **exempt** and mandated in that shape; there is no Profiles page.
- **(b) Master controls.** First and only tab on `General`, composed — `MASTER_SPEC` at
  `settings/Schema.lua:79`. The frameless omission (master scale, master alpha, lock frame, reset
  position) is proven by a whole-repo `SetMovable` sweep returning only `libs/` and two comments
  that say so. `General visibility` stays and honours all four modes.
- **(c)/(d) Color rows.** The addon ships **none** — `grep 'type *= *"color"'` over `settings/`
  returns nothing, and `tests/test_schema.lua:176` gates it. No `disabledIf` anywhere.
- **(e) Reorder.** No `ScrollUp-Up`/`ScrollDown-Up` art, no `MoveUp`/`MoveDown` handler, no stored
  position field.
- **(f) Media groups.** No `LSM30_Font`/`LSM30_Border`/`LSM30_Statusbar` hit in `settings/`.
- **(g) Chrome.** Neither page declares a page-wide control inside a `group`; neither draws two
  chrome bands or boxes one.
- **(h) Wrapped-strip geometry.** The **library** measures the wrapped-row pitch from the inactive
  cap atlas. The **addon's suite** pins nothing about it — see PC-69.
- **(i) Secondary division.** One `TreeGroup` list inside a category tab, session-only per primary
  tab (`ctx.activeSubTab`), inside the scroll, no third level — a **ratified** `options-ui-§13`
  register row (`docs/ARCHITECTURE.md:233`).

`docs/settings-panel.md:9-10` carries the page → tab → row table `documentation-§3` requires,
derived from the schema.

## Slash (`slash-commands`)

`LibKa0s-Slash-1.0` descriptor in `settings/Slash.lua:74+`; `NS.COMMANDS` (`settings/Slash.lua:72`)
carries **10** verbs, over `slash-dispatch.md`'s eight-verb trigger, and the doc is present.

## Debug (`debug-logging`)

`LibKa0s-DebugLog-1.0` descriptor at `core/DebugLogSetup.lua:39+` with `addonName`, plus a
member-answering stub. No `modules/DebugLog.lua`, no console of the addon's own.

## Localization (`localization`)

`locales/enUS.lua` only, with `NS.L` metatable fallback. `localization-§1`'s English-only shipping
decision is a **ratified** register row (`docs/ARCHITECTURE.md:235`) and `localization-§3` makes that
a **terminal compliant state**, so the routing SHOULD is explicitly **not** re-filed.

`localization-§5` is a different rule and it is where this addon fails. v2.39.0 published the
`BRITISH` / `ALLOWED` lists so the US-English MUST could finally be *run* rather than read; run whole
over the authored tree they return **49 hits across 19 files** — `colour` ×30, `honour` ×9,
`behaviour` ×4, plus five singles. All 49 are code comments and `docs/` prose; `locales/enUS.lua` is
clean and no quoted string in the shipped source matches, so nothing a player reads is affected. The
repo has no gate for it. That is PC-75, and it is the finding this cycle's amendments made visible.

## Tests, lint, perf, complexity

- `luacheck .` — **0 warnings / 0 errors in 44 files**, with `tests/` **in scope**:
  `.luacheckrc:26` narrows `exclude_files` to `"tests/_kit/"`, there is no top-level `ignore`, and
  the harness global sits in a `files["tests/"]` stanza.
- `lua tests/run.lua` — **328 passed, 0 failed, 0 skipped**.
- `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` — **0 warnings**, max CCN 13, 694 functions,
  53,171 NLOC.
- Perf is a permanent `skip` under the ratified `performance-§12` exemption; `.luacheckrc` carries
  neither `debugprofilestop` nor `PrettyChatPerfDB`, which is the compliant consequence.
- Newest run bundle `docs/automated-tests/20260908-181425/` is at commit `4feceda`, two commits
  behind `master` — see PC-76.

## `.gitattributes` (`line-endings`)

Present at the repo root and **byte-identical** to `line-endings-§5`'s canonical **client-bound**
body: 81 lines, `diff` against the extracted canonical block is empty, and there is nothing below it
(no `§5 appendix`, and none is needed). Pin recorded verbatim: `* text=auto eol=crlf`
(`:26`); `*.sh text eol=lf` (`:34`); 20 `binary` rows. The working-tree check prints **0**. The
`line-endings-§7` gate is present and vendored — `tests/_kit/test_eol.lua`, reporting *"eol: every
tracked file carries the terminator .gitattributes declares for it"* green in the run above.

## Packaging (`packaging`)

`.pkgmeta` ignores every root dot-entry the repo has. The dot-entry sweep prints only
`UNACCOUNTED — .git`, which is the one entry the packager never sees. `.claude` (`:25`) and
`.pkgmeta` (`:15`) both carry rows with justification comments. `.superpowers` does not exist here
and `.pkgmeta:24` says so deliberately.

## Root docs

- **`README.md`** — H1, the five canonical badges in order (`:3-7`), logo, description,
  `## What's new in 1.4.0`, `## Screenshots`, `## Usage` (with both subsections), `## How it works`,
  `## FAQ`, `## Troubleshooting`, `## Issues and feature requests`, `## Version History`. No
  `## Credits`, which is correct with nothing external to credit. The three cheap greps:
  standard badge is the **bare** `![Standard](…)` at `:6`; **no** bundled-library heading and no
  roll-call in the intro; **no** `Bundles [LibKa0s]` line. The settings table is page-granular
  (`:66-69`) with the per-tab breakdown gone — 2026-09-07's `PC-67` is closed.
- **`CLAUDE.md`** — a stub with the adherence line at `:5-7` (2026-09-07's `PC-70` closed),
  `## Standards compliance (read first)` at `:9`, the docs pointer list, the green-gate line and the
  provenance line at `:34`. `:36` is stale — PC-72.
- **`DEPENDENCIES.md`** — present, the WSL2/Ubuntu toolchain contract.
- No `CHANGELOG.md`, no `TODO.md`, no `docs/agent-context.md`.

## `docs/` shape (`documentation-§3`) — measured as a directory listing

**Tier 1 — all six present** under exactly the canonical names: `scope.md`, `module-map.md`,
`schema.md`, `settings-panel.md`, `data-flow.md`, `common-tasks.md`.

**Tier 2 — every trigger evaluated against the code**, and the register at
`docs/ARCHITECTURE.md:180-190` answers each:

| Doc | Trigger, measured | State | Correct? |
|---|---|---|---|
| `slash-dispatch.md` | `NS.COMMANDS` = **10** ≥ 8 | Present | yes |
| `midnight-quirks.md` | no client-version workaround of the addon's own | Not applicable | yes |
| `compat-layer.md` | no `core/Compat.lua`; the §3 grep counts **0** < 3 | Not applicable | yes |
| `message-bus.md` | **0** distinct messages, not > 10 | Not applicable | yes |
| `profiles.md` | no profile control in the options UI | Not applicable | yes |
| `debug.md` | no debug surface beyond the LibKa0s console | Not applicable | yes |
| `perf-analysis/README.md` | harness not wired (ratified `performance-§12`) | Not applicable | yes |

**`## Documentation map`** is present at `docs/ARCHITECTURE.md:164` with **four** tables in the
mandated order — Required (`:169`), Conditional (`:180`), **Verification and record** (`:192`),
Addon-specific (`:203`). The fourth table holds exactly the six rows `documentation-§3` names, and
`perf-analysis/README.md` correctly registers in Conditional rather than here. v2.39.0's amendment
ratifies the shape this repo already shipped, which closes 2026-09-07's `PC-68` by rule change. No
justifying note against the old three-table MUST survives. `ARCHITECTURE.md` does not register
itself, which is a **MAY** and is filed neither way. Two `.md` files under `docs/` are covered only
by a directory name that `documentation-§3`'s out-of-scope list does not carry — PC-71.

**Non-canonical filenames:** none. No `data-model.md`, `saved-variables.md`, `pipeline.md`,
`settings-system.md`, `wow-quirks.md`, `slash-commands.md`, `debug-console.md`.
**Retired docs:** no `file-index.md`, no `conventions.md`, no `complexity.md`, no `docs/perf-runs/`.
**Hub shape:** 359 lines, under the ~400 SHOULD. The only mandated section past ~60 lines is
`## Documented deviations` at 112, which is the register itself and has no topic doc to spill to —
not a finding.

A second, unmandated inventory sits at `docs/ARCHITECTURE.md:341` (`## Doc index`) — PC-74.

## Deviation register and issue store

`docs/ARCHITECTURE.md:209` carries `## Documented deviations` with **9** active rows and a
**Retired on 2026-09-08** block holding two (`:238-253`). Every row's re-check trigger was evaluated
against the tree in front of me and **none has fired**; every evidence id resolves, which
`tests/test_doc_structure.lua` also gates. One row cites a rule the standard permits outright —
PC-73.

The issue store is GitHub issues on this repo: 14 issues, every one carrying a `state:` label and a
`severity:` label, none carrying a `[status]` title prefix. No `docs/pending/LEDGER.md` and no
`docs/pending/`. The inverse check was run: every `state:will-not-do` issue either has a register row
(#10 → `performance-§12`; #7 → `toc-file-§1`) or declines something the standard makes optional
(#13/#12/#11 under `library-stack-§3`'s prune rule, #8 under `options-ui-§3`'s **MAY**), so no
missing-row finding is owed.
