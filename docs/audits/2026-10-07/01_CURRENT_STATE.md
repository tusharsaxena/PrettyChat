# 01 — Current State (Ka0s Pretty Chat)

**Run date:** 2026-10-07
**Audited against:** Ka0s WoW Addon Standard **v2.76.1 (2026-10-07)**, read from
`https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master`: `AUDIT.md`,
`standards/STANDARDS.md`, the 27 section files its Sections list links, and `standards/ADDONS.md`.
The fetches went through `curl -fsSL` (faithful fetch). All 27 section files were fetched, and each
was compared byte for byte (`cmp`) with a second `curl` copy taken the same day. All 27 were identical.
**Repo kind:** **Addon**. `dev-copilot-profile` reported `kind=addon` (`reason=toc:## Interface`), and
`ADDONS.md` lists Pretty Chat in its addon table. The run therefore uses the addon rule set: every
section, plus the `AUDIT.md` playbook.
**Tree audited:** branch `feat/2026-10-07-review-audit-remediation` at `8626790` (merge of
`feat/2026-10-06-revendor-libka0s-v1.69.0`), clean apart from a parallel review bundle
(`docs/reviews/2026-10-07/`, untracked, not this run's).
**ID prefix:** `PC-` (stable). The previous run, `docs/audits/2026-09-23/` (v2.64.0), ended at `PC-102`.
New IDs in this run start at `PC-103`.
**Read-only.** This run's only writes are the five files in this folder.

---

## Layout (`layout`)

- Source sits under `core/`, `defaults/`, `locales/`, `modules/` and `settings/` (`PrettyChat.toc`, `# Core` through `# Settings`).
  The tracked tree also has `GlobalStrings/`, which is generated reference data and is never loaded.
  It holds a ratified `layout-§2` register row. The authored generator is
  `tools/split_globalstrings.py`, `.pkgmeta`-ignored at `.pkgmeta:45`.
- **LOC census.** The scope is `git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'`. The only file
  over 1500 lines is `GlobalStrings/GlobalStrings.lua` at 23,842. That is the declared generated-data
  exemption (`tests/run.lua:61`, `Kit.layoutCap = { exempt = { "GlobalStrings/" } }`), and the census
  row at `docs/ARCHITECTURE.md:357` marks it `exempt`. The 1000–1500 band holds one file,
  `settings/Schema.lua`, at 1094 lines. The kit gate `test_layout_cap` is wired (`tests/run.lua:89`).

## TOC (`toc-file`)

- `## Interface: 120100`, `## Version: 1.6.0`, `## SavedVariables: PrettyChatDB`,
  `## X-Standard:` and `## X-Curse-Project-ID: 919766` are all present (`PrettyChat.toc:1-14`).
- `## IconTexture` points at `media\logos\prettychat.logo.128.tga`. The TGA header reads type 2
  (uncompressed), 128×128, 32 bpp, so it is compliant.
- `libs\LibKa0s\LibKa0s.xml` is listed once, after Ace3 and the broker pair. Every load-bearing line
  in `# Core` carries an at-line note naming what resolves (EnvSetup, MediaSetup, Util, CoreSetup,
  DebugLogSetup), and LifecycleSetup and LauncherSetup are marked conventional. The settings lines
  that are load-bearing are annotated as well. The brand Title/Author escapes are ratified under a
  `toc-file-§1` register row.

## Libraries (`library-stack`)

- Vendored: LibStub, CallbackHandler, AceAddon, AceDB, AceConsole, AceGUI, AceConfig, AceDBOptions,
  LibDataBroker-1.1, LibDBIcon-1.0, and **LibKa0s v1.70.0** (provenance line at `CLAUDE.md:42`).
- **Whole-folder vendoring.** `diff -r` of `libs/LibKa0s/` against the `v1.70.0` tag's `LibKa0s/` is
  empty, and so is `diff -r` of `tests/_kit/` against its `testkit/` (03, E-3). The payload holds 34
  `.lua` files, matching `LibKa0s.xml`'s 34 `<Script>` lines. Kit revision 37
  (`tests/_kit/framework.lua:20`).
- Majors wired through setup files: Core (`core/CoreSetup.lua`), Env (`core/EnvSetup.lua`), Media
  (`core/MediaSetup.lua`), DebugLog (`core/DebugLogSetup.lua`), Lifecycle
  (`core/LifecycleSetup.lua:67`), Launcher (`core/LauncherSetup.lua:98`), Options
  (`settings/OptionsSetup.lua:17`), Slash (`settings/Slash.lua:158`) and Schema (`settings/Schema.lua`).
  Perf is declined under the ratified `performance-§12` exemption. Compat and Bus are declined as
  `state:will-not-do` issues #16 and #17. No major is hand-rolled (anti-pattern #47 is clear).
- **Degradation stubs.** The DebugLog stub (`core/DebugLogSetup.lua:100-170`) answers the gates,
  `RunDiagnostics`, `BuildDiagnostics` and `DebugVerb`. The Lifecycle stub
  (`core/LifecycleSetup.lua:74-121`) completes the latch. The Core twin publishes
  `NS.MakeCloseButton` and the three `SafeRegister*` bodies. The kit's surface-parity suite pins all
  of them (`tests/test_surface_parity.lua`).

## Patterns (`architecture`, `events-frames-taint`)

- The namespace is the AceAddon object (`core/PrettyChat.lua:14`). Every module publish is
  idempotent. Ten files read `addonName` and twelve open `local _, NS = ...`, and `architecture-§1`
  now names both forms compliant.
- **Events.** There is one private frame, `PrettyChatCombatWatcher`
  (`modules/Override.lua:199`). It carries `PLAYER_REGEN_DISABLED`/`_ENABLED` only, is created
  lazily, and is registered through `NS.Util.SafeRegisterEvents` (`:212`) with rejected names
  recorded in `NS.RejectedEvents`. Stand-down calls `UnregisterAllEvents` (`:208`). No AceEvent-3.0
  is vendored or embedded, so this is `events-frames-taint-§1`'s **boundary-watcher carve-out**, and
  it is compliant. `docs/ARCHITECTURE.md:173` lists it.
- **Message bus.** None, and the addon is below `architecture-§4`'s threshold because it has one
  feature module and no second module reacts to its events (`docs/ARCHITECTURE.md:148`). It
  publishes no `Ka0s_` message, so the bus-constant check is *Not applicable*.
- **Compat.** No `core/Compat.lua`. The addon makes no deprecated or version-variant call outside
  LibKa0s, which meets `compat`'s applicability condition. The Map row reads *Not applicable*
  (`docs/ARCHITECTURE.md:242`).

## Settings (`options-ui`, `savedvariables`, `architecture-§5`)

- **Pages.** General: `H.RenderTabbedSchema` over the one composed `Master controls` tab
  (`settings/Panel.lua:141`). Categories: `H.TabStrip` of eight categories (`:622`), each with a
  TreeGroup string list and editor, under the ratified `options-ui-§6` and `§13` rows. Profiles:
  AceDBOptions, an exempt page. Landing page: an exempt page.
- **Master controls.** The rows are enable, general visibility, debug console and minimap button.
  The addon is frameless (no `SetMovable` anywhere), so scale, alpha, lock, test mode and reset
  position are correctly omitted. The block closes with `[Test] [Reset all settings]`, where `Test`
  is the composer's `leadButton` (`settings/Schema.lua:191-195`); that layout is a ratified
  `options-ui-§15` row.
- **Defaults buttons.** Both are page-wide. General's goes to `ConfirmResetAll`
  (`settings/Panel.lua:732`), and the Categories page's goes to `ResetCategoriesPage` (`:756`).
- **Schema.** There is one write seam, `LibKa0s-Schema-1.0`'s runtime `Set`. Row `set` closures are
  the only stored-tree writers outside the load pass (`settings/Schema.lua:309-452`). Defaults are
  declared once in `defaults/Profile.lua` (`NS.GeneralDefaults`, `NS.GlobalDefaults`). There are no
  color rows, no `disabledIf`, no LSM groups and no reorder arrows.
- The Options descriptor passes `addonName = addonName` (`settings/OptionsSetup.lua:267`, v2.75.0).

## Slash (`slash-commands`)

- `/pc` and `/prettychat` take 14 verbs (`settings/Slash.lua:46-87`). `enable` and `disable` are
  aliases that write `General.enabled` through `NS.SetAddonEnabled` (`:513`). `liveVerbs` is built
  from `lib.LIVE_VERBS` plus `profile` (`:287-289`), so the full reserved set answers while disabled.
  The only refused feature verb is `test`.
- **Disabled state (`slash-commands-§7`).** Stand-down goes through one latch with two holds
  (`core/LifecycleSetup.lua`), and both arms are `PrettyChat.Reapply` (`modules/Override.lua:272-298`).
  The registration census finds 1 registration site, and it is undone by `UnregisterAllEvents`. There
  are no timers, `OnUpdate` scripts, hooks or messages. The two `C_Timer.After(0, …)` calls are
  one-shot next-frame redraws on the settings panel, which is setup. No SavedVariables write comes
  from a game event. The conformance suite `tests/test_disabled.lua` asserts on the mock's
  registration set (`:181`, `:188`, `:255`). This is the compliant shape.
- **Diagnostics (`debug-logging-§14`).** It has one `COMMANDS` row (`settings/Slash.lua:77`).
  `runDebug` tests `diagnostics` first (`:542`). No alias exists. Both forms reach
  `NS.DebugLog:RunDiagnostics` (`:529`). No `Clear()` and no host `SetEnabled` sit around the run.
  The stub answers with the library-absent line. The README's `## Reporting a bug` section is
  verbatim (`README.md:70-76`).

## Debug (`debug-logging`)

- The `LibKa0s-DebugLog-1.0` descriptor (`core/DebugLogSetup.lua:177-242`) passes `addonName`,
  `brandName` and `diagnostics`. The Launcher, Lifecycle, Options, Slash and Schema descriptors each
  pass `debug` (`core/LauncherSetup.lua:168`, `core/LifecycleSetup.lua:142`,
  `settings/OptionsSetup.lua:270`, `settings/Slash.lua:305`, `settings/Schema.lua:823`). The Launcher
  also passes `debugAtEnable` (`core/LauncherSetup.lua:174`). The change gates are the console's
  `DebugChanged` (`modules/Override.lua:160-163`) and `DebugOnce` (`core/Util.lua:80`). There is no
  hand-rolled memo.

## Launcher (`launcher`)

- One LDB object, labeled `Ka0s Pretty Chat` (`core/LauncherSetup.lua:148`), with `isEnabled` +
  `setEnabled` only (`:186-191`). The addon is frameless, matching `ADDONS.md`'s *Enabled* alone. It
  sets no `OnTooltipShow` and passes none of the retired fields. The minimap row sits at
  `global.minimap.shown`, inverted onto LibDBIcon's `hide`, and no reset reaches it
  (`docs/ARCHITECTURE.md:133`).

## Tests and lint (`testing`, `lint`, `automated-tests`)

- `lua tests/run.lua` (bounded): **572 passed, 0 failed, 1 skipped, 573 total**, exit 0.
  `docs/test-cases.md` is identical to `--list` output, and the README badge `572/572` follows
  `testing-§5`, which excludes skips from both figures.
- `luacheck .` (bounded): **0 warnings / 0 errors in 56 files**. `exclude_files` covers `Libs`,
  `libs`, `GlobalStrings`, `docs/audits`, `docs/reviews` and `tests/_kit/`. That is narrowed to the
  kit for `tests/`, and the harness global sits in `files["tests/"]` (`.luacheckrc:86`).
- Kit suites wired: `test_layout_cap`, `test_prose`, `test_eol`, `test_diagnostics_contract`,
  `test_lizard_sighted` (`tests/run.lua:89-162`), plus `test_vendor_sync` and `test_disabled`.
- **Complexity** was run through the sighted runner (`--suite complexity --no-bundle`): pass, 0
  warnings, max CCN 15, 1314 functions, 57,375 NLOC, `blindFiles` 0. The newest recorded bundle,
  `20260927-031723` (sha `a663bc6`, clean), is **49 commits** behind HEAD and predates the kit-35
  sighting.

## Performance (`performance`)

- No harness is wired, under the ratified `performance-§12` exemption (`docs/ARCHITECTURE.md:284`).
  The committed sweep (`docs/performance-sweep.md`) was re-run here and still returns 43 lines. The
  shipped-code lines are unchanged. Only the test-file line numbers drifted (PC-104).

## Packaging (`packaging`)

- All three `.pkgmeta` checks pass. (a) Every named entry is ignored, including `tools` and
  `.claude`. (b) No dot-entry is unaccounted for except `.git`. (c) No false claims.

## Line endings (`line-endings`)

- `.gitattributes` exists. Its pin is `* text=auto eol=crlf` (client-bound), with `*.sh text eol=lf`
  and `*.py text eol=lf`, and 20 `binary` lines. The first 84 lines are byte-identical to the
  canonical client-bound body in `line-endings-§5`, with no appendix. The working-tree check finds
  **0 of 575** tracked files disagreeing with the pin. The `test_eol` gate is wired.

## Root doc set (`documentation-§1/§2/§7`)

- **README.** The badge row is in canonical order, and the Standard badge is **bare**
  (`README.md:6`). There is no logo image, no library inventory, no numbered list, and no provenance
  line. `## Reporting a bug` sits between Troubleshooting and Issues. Version History highlights are
  bulleted. `## Credits` carries external credit (JetBrains Mono) only.
- **CLAUDE.md** is a stub with every item `documentation-§2` requires. Its provenance line is
  `v1.70.0` (`CLAUDE.md:42`).
- **DEPENDENCIES.md** covers runtime, dev (Lua 5.1, luacheck, lizard, git, diffutils), and
  release/assets (Python 3 for `tools/split_globalstrings.py`, Pillow, packaging).

## `docs/` (`documentation-§3`)

- **Tier 1:** all six docs are present under their canonical names.
- **Tier 2:** `slash-dispatch.md`, `profiles.md` and `debug.md` are present. `midnight-quirks`,
  `message-bus`, `compat-layer` and `perf-analysis/README.md` are each covered by a correct *Not
  applicable* row.
- **Map:** four tables are present. All 18 `.md` files outside the frozen stores are registered
  exactly once, and no row dangles. There are no retired docs (`file-index`, `conventions`,
  `complexity`, `perf-runs`) and no non-canonical names.
- **Hub shape:** `docs/ARCHITECTURE.md` is **434 lines** (PC-105).

## Register and issue store (`audit-review-history`)

- The register has 8 live rows (`docs/ARCHITECTURE.md:284-291`): `performance-§12`, `layout-§2`,
  `toc-file-§1`, `options-ui-§6`, `options-ui-§13`, `testing-§1`, `localization-§1` and
  `options-ui-§15`. The retired blocks are at
  `docs/ARCHITECTURE.md:293-335`. Every trigger was evaluated against this tree, and every evidence
  id in a row resolves (02, *Recorded deviations*).
- Issue store, read via `gh issue list --json`: 18 issues, every one carrying a `state:` label and a
  `severity:` label. There is no `[status]` title prefix and no `docs/pending/LEDGER.md`.

## Re-vendor store (`audit-review-history`)

- The store runs from 2026-08-25 to `2026-10-04-v1.68.1`. 51 distinct tags were vendored since that
  horizon and 49 are recorded. **v1.69.0 and v1.70.0 have no bundle** (PC-103).
