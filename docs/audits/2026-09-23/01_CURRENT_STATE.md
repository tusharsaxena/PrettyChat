# 01 — Current state (Ka0s Pretty Chat)

**Run date:** 2026-09-23
**Audited against:** Ka0s WoW Addon Standard **v2.64.0 (2026-09-23)**, fetched verbatim with `curl -fsSL`
from `https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master` — `AUDIT.md`,
`standards/STANDARDS.md`, all 27 section files its *Sections* list links, and `standards/ADDONS.md`.
**Repository kind:** **Addon** — it has a `.toc` (`PrettyChat.toc`) and is a row of `ADDONS.md`'s
*In-scope addons* table (launcher rung **(c)**). Audited against the whole addon rule set.
**Tree measured:** branch `feat/2026-09-23-review-audit-remediation`, HEAD `2a32870`, clean working
tree before this bundle was written (`git status --short` empty).
**Previous run:** `docs/audits/2026-09-08/` (against v2.39.0), frozen and untouched. ID prefix `PC-`
reused; that run ended at `PC-76`.
**Bounded runner:** `ka0s-bounded` is not on `PATH` in this shell; it exists at
`~/.claude/wow-addon/bin/ka0s-bounded` and every `luacheck`, `lua tests/run.lua` and `lizard` run
below went through it by full path. No run exited 124 or 137.

---

## 1. Layout (`layout`)

- Source lives under `core/` (12 files), `defaults/` (2), `modules/` (1), `settings/` (4) and
  `locales/` (1) — 20 files, nothing loose at the root. `libs/`, `tests/`, `media/`, `docs/` present.
  No `tools/` folder.
- `GlobalStrings/` — a PascalCase root folder holding the 23,842-line generated dump
  `GlobalStrings/GlobalStrings.lua`, 26 generated chunks, `README.md` and the **authored generator
  `GlobalStrings/split_globalstrings.py`**. The folder's name and place are a ratified
  `layout-§2` register row; the generator's placement is **not** (layout-§1 v2.61.0 — see PC-83).
- **Census (layout-§1).** `git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'` → **75** tracked
  authored-or-generated `.lua` files; one over 1500 (`GlobalStrings/GlobalStrings.lua`, 23,842,
  declared exempt), one in the 1000–1500 band (`tests/test_panel.lua`, 1053). `settings/Schema.lua`
  sits at 998. The hub carries `### Files over the 1500-line cap` under `## Documented deviations`
  (`docs/ARCHITECTURE.md:307`) with one `exempt` row, and the exemption's three conditions hold on
  the tree (banner at `GlobalStrings/GlobalStrings.lua:1`, no `GlobalStrings\` TOC line, `.pkgmeta:39`
  `- GlobalStrings`). The kit's cap gate is wired by the pair (`tests/run.lua:74`) and green.
- `media/` holds `logos/` (`prettychat.logo.128.tga`, `.tga`, `.png`, `.jpg`) and `screenshots/`
  only; nothing that duplicates `libs/LibKa0s/media/`.
- Logo files: `prettychat.logo.128.tga` is TGA type **2**, **128×128**, **32** bpp (65,580 bytes);
  the landing-page `prettychat.logo.tga` is type 10, 300×300, 24 bpp (not graded — options-ui-§5).

## 2. TOC (`toc-file`)

`PrettyChat.toc` (84 lines, single trailing CRLF newline):

- Field order matches `toc-file-§1` exactly: Interface `120100` (single Retail value), Title (rainbow
  brand mark — ratified row), Notes, Author `aDd1kTeD2Ka0s` (ratified), Version `1.5.0`,
  `IconTexture: Interface\AddOns\PrettyChat\media\logos\prettychat.logo.128.tga` (the addon's own
  128 file), `SavedVariables: PrettyChatDB` (one — the addon holds the `performance-§12` exemption),
  OptionalDeps, DefaultState, `Category-enUS: Chat & Communication`, `X-License: MIT`, `X-Standard`,
  `X-Curse-Project-ID: 919766` (published). No `X-Wago-ID` (not listed — compliant by `toc-file-§1`'s
  MAY).
- Sections in the mandated order Libraries → Locales → Core → Defaults → Modules → Settings
  (`:15`, `:31`, `:34`, `:69`, `:73`, `:76`). Every vendored library listed directly;
  `libs\LibKa0s\LibKa0s.xml` once, after Ace3 and the broker pair (`:29`).
- **Position annotations (`toc-file-§5`).** Annotated load-bearing: `core\EnvSetup.lua` (`:35-40`),
  `core\MediaSetup.lua` (`:41-43`), `core\Util.lua` (`:47-50`), `settings\Panel.lua` (`:80-84`).
  Annotated conventional: `core\LifecycleSetup.lua` (`:55-61`), `core\LauncherSetup.lua` (`:62-67`).
  **Unannotated but load-bearing** by the seam files' own file-scope reads: `core\CoreSetup.lua`
  (`:53`), `core\DebugLogSetup.lua` (`:54`), `settings\OptionsSetup.lua` (`:78`),
  `settings\Slash.lua` (`:79`) — the first three are the very positions `docs/ARCHITECTURE.md:35`
  lists as load-bearing (PC-77..PC-80).

## 3. Libraries (`library-stack`)

- `libs/`: LibStub, CallbackHandler-1.0, AceAddon-3.0, AceDB-3.0, AceConsole-3.0, AceGUI-3.0,
  LibDataBroker-1.1, LibDBIcon-1.0, LibKa0s. No AceEvent/AceTimer (reached by nothing — compliant
  under library-stack-§1's *when used*), no AceConfig. `.pkgmeta` carries no `externals:`.
- **LibKa0s v1.55.0**, per root `CLAUDE.md:42` (`Bundles [LibKa0s](…) v1.55.0 (MIT).`). The line is
  in `CLAUDE.md` only; `README.md` carries no provenance line and no library section.
- `diff -r` of the whole ship folder and of `testkit/` against the sibling `../LibKa0s` checked out
  at tag `v1.55.0` (`git archive v1.55.0`) — **both empty** (146 tracked files under
  `libs/LibKa0s/`). `tests/_kit/run-automated-tests.sh` is recorded `100755`.
- **Adopted majors (9 of 15):** Core (`core/CoreSetup.lua`), Env (`core/EnvSetup.lua`), Media
  (`core/MediaSetup.lua`), DebugLog (`core/DebugLogSetup.lua`), Lifecycle (`core/LifecycleSetup.lua`),
  Launcher (`core/LauncherSetup.lua`), Schema (`settings/Schema.lua:715-740`, with a
  runtime-completing host stub at `:547-713` citing the major's API document), Options
  (`settings/OptionsSetup.lua`, load-completing stub), Slash (`settings/Slash.lua`). Compat and Bus
  declined as structural misfits (issues #16, #17 — `state:will-not-do`); neither is required at
  v2.64.0 (library-stack-§7). Perf declined under the ratified `performance-§12` row. Item, Pool,
  Widgets not consumed (issues #11–#13).
- **Stub coverage.** Member census per seam (grep over `core modules settings`) against each
  library-absent branch: Core (Print, Format, MakeCloseButton, Util.IsConcatSafe/SafeToString) —
  all answered; DebugLog (Debug, Add, SetEnabled, Toggle, Show, Hide, IsShown, SessionSummary) —
  all answered; Lifecycle (Set, IsDown, Reevaluate, Holds) — all answered; Slash (OnSlash,
  PrintHelp, LandingRows, CliGet/Set/List/Reset/Version, Text, DisabledLine) — all answered; Options
  — load-completing by design (`MasterControls` real, `EnsureScroll` nil-guard documented at
  `settings/OptionsSetup.lua:225-235`); Launcher — no stub by documented decision, both call sites
  guarded (`core/LauncherSetup.lua:65-85`). `tests/test_surface_parity.lua` pins the parity.

## 4. Architecture (`architecture`)

- `NS` is passed to `NewAddon` (`core/PrettyChat.lua:14`); AceConsole's `:Print` clobber reclaimed at
  `core/CoreSetup.lua:142`. No `_G[addonName]`.
- Files open `local addonName, NS = ...` (9) or `local _, NS = ...` (11) — see PC-100 (Info).
- Modules publish on `NS`; `settings/Schema.lua:5-6` publishes `NS.Schema` non-idempotently (PC-95).
- **Message bus:** none — zero `SendMessage` / `RegisterMessage` and zero `"Ka0s_…"` literals in the
  addon's own Lua; `## Message Bus` says there is none "because this addon publishes no named
  message" (`docs/ARCHITECTURE.md:137-143`). But `architecture-§4`'s applicability threshold is *two
  or more feature modules, **or any module that registers game events***, and `modules/Override.lua`
  registers two (`:139`) — so the bus MUST binds, and neither the hub's reason nor any register row
  answers that threshold (PC-102).
- **Schema-as-single-source (architecture-§5):** 174 rows (4 composed Master-controls rows + 170
  category rows); single write seam `Schema.Set` = `LibKa0s-Schema-1.0`'s `Set`; every stored write is
  inside a row's `set` closure (`settings/Schema.lua:196-257`, `:358-419`), the load pass
  (`core/Database.lua:52-115`), or wholesale replacement (`modules/Override.lua:396-411`,
  `db:ResetProfile()`). Structural registries: none; named non-setting state: none — both stated in
  `docs/ARCHITECTURE.md:131-133`. Boot validation `runValidation` (`settings/Schema.lua:522-541`).

## 5. SavedVariables (`savedvariables`)

- `PrettyChatDB` only; `global.schemaVersion` (`core/Database.lua:36`) with an empty migration table
  and a load-pass repair `PruneOrphans` (`:52-76`). Profile defaults in `defaults/Profile.lua`
  (`{ profile = { categories = {} } }`); the `global` defaults and the Master-controls defaults are
  hard-coded elsewhere (PC-94).

## 6. Settings panel (`options-ui`)

- `settings/OptionsSetup.lua` builds one `LibKa0s-Options-1.0` instance at `NS.Helpers`
  (`:250-303`). Pages: landing (library `BuildLandingPage` over the host spec), **General** (one tab,
  `Master controls`, composed — Enable PrettyChat, General visibility, Debug console, Minimap
  button, closed by `[Test] [Reset all settings]`; no Defaults button, `settings/Panel.lua:722`),
  **Categories** (primary `H.TabStrip` of 8 categories; per tab the category Enable row, a footnote,
  and an AceGUI `TreeGroup` string list beside one editor).
- Page → tab list (from the schema): General → [`Master controls`]; Categories → [Loot, Currency,
  Money, Reputation, Experience, Honor, Tradeskill, Misc].
- Frameless (whole-repo `SetMovable` sweep returns only two comments), so master scale/alpha/lock
  and reset position are omitted and there is no Test mode row — compliant.
- No color rows, no LSM rows, no reorder lists, no `disabledIf`, no chat-scroll arrows, no host
  combat guard (grep results in `03_EVIDENCE.md` §E6).
- Global reset: `PrettyChat:ResetAll` = `db:ResetProfile()` (`modules/Override.lua:396-411`) behind
  the verbatim `options-ui-§12` popup (`settings/Panel.lua:43-55`).
- **The Categories page's Defaults button resets only the selected tab** (`settings/Panel.lua:738`,
  `:752-754`) — PC-81.

## 7. Launcher (`launcher`)

- One LDB object via `LibKa0s-Launcher-1.0` (`core/LauncherSetup.lua:111-177`), name = folder,
  `label = "Ka0s Pretty Chat"`, icon = the 128 file, no `onClick` (rung (c) — matches `ADDONS.md`),
  right-click `openSettings`. `minimap.hide` stored in `db.global.minimap` (declared default,
  `core/Database.lua:37`); the row inverts at the write seam (`settings/Schema.lua:229-245`). Neither
  reset reaches it (profile reset; General has no Defaults; `ResetCategory('General')` is an
  allow-list, `modules/Override.lua:332`). No broker toggle. Compliant.

## 8. Slash commands (`slash-commands`)

- `/pc` + `/prettychat` via AceConsole (`core/PrettyChat.lua:68-69`), dispatched by
  `LibKa0s-Slash-1.0` minor 14 (`libs/LibKa0s/Slash.lua:21`) from the host's positional `COMMANDS`
  (12 verbs: help, config, version, list, get, set, reset, resetall, test, debug, enable, disable —
  `settings/Slash.lua:45-74`). `enable`/`disable` write `General.enabled` through `CliSet`
  (`:414-431`). `perf` reserved, not registered (exempt). No `lock`/`unlock` (nothing to lock —
  outside `slash-commands-§8`).
- **Disabled state (`slash-commands-§7`).** Stand-down built on `LibKa0s-Lifecycle-1.0` (v1.55.0 ≥
  the v1.42.0 floor): `disabled` hold from the stored path (`settings/Schema.lua:196-203`,
  `core/PrettyChat.lua:207`, `:88-89`), both arms = `PrettyChat.Reapply` (one mechanism,
  `modules/Override.lua:200-231`). Registration census: the addon's only registration is the combat
  watcher's two `PLAYER_REGEN_*` events (`modules/Override.lua:139`), unregistered via
  `UnregisterAllEvents` (`:135`) because `SyncCombatWatch` reads the latch first (`:115-116`). No
  timers, tickers, `OnUpdate`, messages or hooks outside the settings panel body. No game-event
  SavedVariables write while disabled. Slash surface fully live; the one feature verb `test` refuses
  through the library gate (`isEnabled`/`brandName`, `settings/Slash.lua:258-259`). Launcher rung
  (c) unchanged while disabled, writes nothing. `tests/test_disabled.lua` asserts on the kit's
  recording registry with `red under:` comments on steps 3, 6 and 10. **Compliant.**

## 9. Localization (`localization`)

- `NS.L` metatable fallback (`locales/enUS.lua`); English-only is a ratified `localization-§1` row
  (terminal state). **US English:** the kit's prose gate is wired by the pair (`tests/run.lua:83`)
  and green; an independent scan of the tracked authored set with the canonical `BRITISH`/`ALLOWED`
  lists returns hits only inside `tests/prose_waivers.lua` (which quotes the waived words) — PC-75
  is closed.

## 10. Events, frames, taint (`events-frames-taint`)

- Overrides `_G[GLOBALNAME]` (the SHOULD shape of §5), deterministic cross-registration order
  (`CATEGORY_ORDER` + sorted names). The combat watcher is a private `CreateFrame("Frame",
  "PrettyChatCombatWatcher")` carrying two non-unit events (PC-84) registered by a bare loop with no
  `pcall` helper and no rejected-name record (PC-85). Panel open is the library's combat-gated open.

## 11. Compat (`compat`)

- No `core/Compat.lua` (deleted when the Env seam took its one shim — `core/EnvSetup.lua:6-20`); the
  library-absent rung of `NS.Meta` calls the legacy global `GetAddOnMetadata` directly
  (`core/EnvSetup.lua:75-76`) — PC-93.

## 12. Debug console (`debug-logging`)

- `LibKa0s-DebugLog-1.0` instance (`core/DebugLogSetup.lua:112-166`): `name`/`addonName` = folder,
  font `NS.Const.FONT_MONO` (JetBrains Mono from the payload), thin forwarders, `initSummary`, flag in
  `NS.State.debug` (session-only). Stub covers every called member (`:41-110`). Traces: `[Init]`,
  `[Migrate]`, `[Set]` (write seam + bulk + profile events), `[Profile]`, `[Visibility]`,
  `[Lifecycle]`.

## 13. Tests, lint, complexity (`testing`, `lint`, `automated-tests`, `performance-§10`)

- `luacheck .` → **0 warnings / 0 errors in 48 files** (bounded, exit 0). `.luacheckrc` excludes
  `Libs`, `libs`, `GlobalStrings`, `docs/audits`, `docs/reviews`, `tests/_kit/`; no top-level
  `ignore`; harness globals in `files["tests/"]`; four one-file `212/self` stanzas, each commented.
- `lua tests/run.lua` → **438 passed, 0 failed, 0 skipped, 438 total** (bounded, exit 0);
  `--list` output byte-identical to `docs/test-cases.md`; README badge `Tests-438%2F438_passing`.
  Kit revision 25 gates wired by the pair: `test_layout_cap`, `test_prose`, `test_eol`;
  `test_vendor_sync`, `test_surface_parity`, `test_disabled` present.
- `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` (lizard 1.24.0) → **941 functions, 54,817 NLOC,
  avg CCN 1.9, 0 warnings.** Newest record `docs/automated-tests/20260916-184747/` (sha `093305b`,
  clean, 30 commits behind HEAD) recorded 854 functions / 54,311 NLOC / max CCN 14 / 0 warnings —
  no function crossed a threshold and no file entered the band since (PC-76, Info).
- The `perf` suite is recorded as "ships no `tests/perf.lua`" rather than as the `performance-§12`
  exemption the addon holds (PC-90).

## 14. Performance (`performance`)

- Ratified `performance-§12` exemption (`docs/ARCHITECTURE.md:269`); `docs/performance.md` carries
  the committed sweep. Trigger not fired (evidence §E9).

## 15. Packaging (`packaging`)

- `.pkgmeta`: `package-as: PrettyChat`, no externals; ignores `.luacheckrc`, `.gitignore`,
  `.gitattributes`, `docs`, `tests`, `_dev`, `.pkgmeta`, `*.bak`, `.claude` (present, untracked),
  `CLAUDE.md`, `DEPENDENCIES.md`, `GlobalStrings`, `media/screenshots`, `media/logos/*.png|*.jpg`.
  Checks (a)/(b)/(c) print nothing but `.git`. No `tools/` today (so no `- tools` owed yet).

## 16. `.gitattributes` (`line-endings`)

- Pin recorded verbatim: `* text=auto eol=crlf` (`.gitattributes:26`), `*.sh text eol=lf` (`:36`),
  `*.py text eol=lf` (`:37`), 23 `binary` marks. The first 84 lines diff clean against
  `line-endings-§5`'s client-bound canonical body; nothing follows it. Working-tree check (e): **0**
  tracked files disagree with the declared pin. Kit gate `test_eol` green.

## 17. Root doc set (`documentation-§1/§2/§7`)

- **README.md** — H1 `# Ka0s Pretty Chat`; badge row in canonical order, standard badge **bare**
  (`README.md:6`); no logo image; no library inventory; sections Screenshots, Usage (5 prose
  paragraphs), How it works, FAQ, Troubleshooting, Issues, Version History. The 1.5.0 row uses
  codebase jargon (PC-98).
- **CLAUDE.md** — stub in the mandated order: H1, adherence line, `## Standards compliance (read
  first)` verbatim in substance, docs pointer list, green-gate line, provenance line (`:42`).
- **DEPENDENCIES.md** — runtime / development / release groups with install + verify commands; the
  release group omits the layout-§4 logo recipe's Pillow (PC-97).
- No `CHANGELOG.md`, no `TODO.md`, no `docs/agent-context.md`, no `docs/pending/LEDGER.md`.

## 18. `docs/` (`documentation-§3`)

- **Tier 1** present under exact names: `scope.md`, `module-map.md`, `schema.md`,
  `settings-panel.md`, `data-flow.md`, `common-tasks.md`.
- **Tier 2** evaluated against the code: `slash-dispatch.md` present (12 commands ≥ 8);
  `midnight-quirks.md` N/A (no client-version workaround of its own); `compat-layer.md` N/A (no
  `core/Compat.lua`, §3 grep = 0 < 3); `message-bus.md` N/A (0 messages); `profiles.md` N/A (no
  profile control); `debug.md` N/A (no surface beyond the library console);
  `perf-analysis/README.md` N/A (exempt). Every N/A row carries its trigger
  (`docs/ARCHITECTURE.md:221-231`).
- **`## Documentation map`** (`:190`): four tables in order — Required, Conditional, Verification and
  record (the six mandated rows), Addon-specific (`global-strings.md`). Every `.md` under `docs/`
  outside the frozen stores (`audits/`, `reviews/`, `automated-tests/<run>/`, `revendor/`,
  `superpowers/`) is in exactly one table; no dangling rows; no self-row (MAY — not filed).
- No non-canonical Tier 1/2 filenames; no retired `file-index.md`, `conventions.md`,
  `complexity.md`, `perf-runs/`.
- Hub shape: 387 lines (< ~400); Module Map 44 lines, Settings Schema 20 — no unspilled section
  (`## Documented deviations` is 119 lines but has no canonical spill target and is the register).
- The hub and three topic docs still describe a General-page explainer line and a host-drawn Test
  button that the code no longer has (PC-86).

## 19. Deviation register and issue store (`audit-review-history`)

Register read first (`docs/ARCHITECTURE.md:250-305`), nine rows. Issue store read with
`gh issue list --state all --limit 200 --json number,title,state,labels,url` (18 issues; every one
carries exactly one `state:` and one `severity:` label; no `[status]` title prefix). Outcome per row
is in `02_DEVIATIONS.md` → *Recorded deviations*. Two rows owe action: the `toc-file-§1` row's Wago
half (PC-73, carried) and the `debug-logging-§2` row, which records behavior the standard now treats
as compliant (PC-88); the `localization-§1` row cites an id that resolves nowhere (PC-89).

**Re-vendor store:** 7 bundles; 32 commits since the store's horizon (2026-08-25) touched
`libs/LibKa0s`, vendoring 31 distinct tags; **26 tags have no bundle** (PC-82).

## 20. What changed since 2026-09-08

LibKa0s v1.27.0 → v1.55.0 (Launcher, Lifecycle, Schema adopted; kit revision 25 gates wired), the
disabled state rebuilt on the latch, the launcher added, the `Categories` page tabbed, `/pc test`
routed to the console, the prose sweep completed. PC-71, PC-72, PC-74 and PC-75 are closed (see
`02_DEVIATIONS.md` → *Closed since 2026-09-08*).
