# Architecture

Orient-yourself map for **Ka0s Pretty Chat**. This file is the high-level index; topic detail lives alongside it in `docs/`.

## Overview

A WoW addon that overrides Blizzard's `GlobalStrings.lua` format strings — `LOOT_ITEM_SELF`, `COMBATLOG_XPGAIN_*`, `FACTION_STANDING_INCREASED`, etc. — to reformat system chat lines (loot, currency, money, reputation, XP, honor, tradeskill, misc) into a color-coded `Category | Context | Source | +/- value` layout. WoW's chat code reads `_G[GLOBALNAME]` lazily on every line, so overrides take effect uniformly across any chat UI (default Blizzard, ElvUI, Glass, …) without per-message hooks. Eight format-bearing categories (81 strings total) are addressed via a flat schema + `/pc` slash CLI + a Blizzard-panel sub-page per category.

```
defaults/Defaults.lua  ─▶ NS.Defaults (categories + format strings + per-cat enabled)
                    │
                    ├─▶ settings/Schema.lua ─▶ NS.Schema  (rows[], byPath[], single write path)
                    │                       │
                    │                       ├─▶ /pc set / get / list / reset   (settings/Slash.lua)
                    │                       └─▶ Panel widget get/set           (settings/Panel.lua)
                    │
                    └─▶ modules/Override.lua ApplyStrings()
                                │
                                ▼
                          _G[GLOBALNAME]   ◀── WoW chat code reads lazily on every line
                                                (no addon hooks, no per-message rewriting)

GlobalStrings/   ─▶ NS.GlobalStrings (Blizzard reference, ~22,879 entries)
                       │
                       └─▶ settings/Panel.lua "Original Format String" disabled input
```

## Module Map

Modular layout (`core/`, `defaults/`, `locales/`, `modules/`, `settings/`) — the single Ka0s layout (`layout-§1`). Load order is `PrettyChat.toc` (dependency, not alphabetical): libraries first — **including `libs\LibKa0s\LibKa0s.xml`, after Ace3** — then `locales/enUS → core/Compat → core/Constants → core/Namespace → core/State → core/Util → core/Database → core/PrettyChat → core/CoreSetup → core/DebugLogSetup → defaults/Profile → defaults/Defaults → GlobalStrings chunks → modules/Override → settings/Schema → settings/OptionsSetup → settings/Slash → settings/Panel`.

**Three positions in that order are load-bearing and are pinned by tests, not by convention:**

- `core/CoreSetup.lua` sits **immediately after** `core/PrettyChat.lua`, because that file passes `NS` to `AceAddon:NewAddon` and AceConsole embeds its own `:Print` over the namespace — CoreSetup's last two lines are the reclaim (anti-pattern #36). It also sits **before** `settings/Schema.lua`, the only load-time `NS.Print` caller. Nothing in the repo takes the printer as a file-scope upvalue, so the window between those two is wide.
- `core/DebugLogSetup.lua` sits after Constants (the mono font path), State (the flag) and CoreSetup (the printer), and before every module that calls `NS.Debug` (debug-logging-§1).
- `settings/OptionsSetup.lua` sits after `settings/Schema.lua`, whose `Get`/`Set`/`RowsByCategory` its descriptor reads, and before `settings/Panel.lua`, which takes the instance as a file-scope upvalue and registers its pages at file load (options-ui-§1).

### The shared cause clause

`core/CoreSetup.lua` publishes **`NS.LIBKA0S_MISSING`** — *"The LibKa0s library is missing from this installation of Ka0s Pretty Chat (expected in libs/LibKa0s)"* — outside its own library-absent branch, because the three later seams read it on **both** paths. Each appends its own consequence and its own terminal punctuation: `", so the debug console window is unavailable."`, `", so the settings panel is unavailable."`, `", so the settings CLI is unavailable."`, and Core's own fallback printer announces once, on the first line the addon prints, with `"; running on reduced built-in fallbacks."`. This is a **cross-file contract four seams depend on**, not an implementation detail of one file: a degraded install says the same thing about *why* at every site and a different thing about *what* at each one, across every Ka0s addon a user has open.

| Module | Publishes on `NS` | Role |
|--------|-------------------|------|
| `core/Compat.lua` | `NS.Compat` | Version-shim seam. `Compat.GetAddOnMetadata` (C_AddOns vs legacy global). |
| `core/Constants.lua` | `NS.Const`, `NS.PREFIX` | `Const.Color` palette (incl. `azure` / `listHead` slash-output codes), the landing page's own section spacers, `Const.STRING_VSPACER`, `Const.FONT_MONO` (vendored JetBrains Mono path), and the shared cyan `[PC]` chat prefix. Carries **no** panel layout constants — those are `LibKa0s-Options-1.0`'s `LAYOUT` table (options-ui-§8). Side-effect-free. |
| `core/Namespace.lua` | `NS.name`, `NS.version` | Identity bootstrap — records the addon name + version so any module can read them without re-querying the TOC. |
| `core/State.lua` | `NS.State` | Session-only runtime state (`{ debug = false }`); never persisted, reset every reload/login. |
| `core/Util.lua` | `NS.Util` | Pure string helpers `trim` / `note` / `cmd` (slash dispatcher). The secret-safe pair `SafeToString` / `IsConcatSafe` is **published onto this same table by `core/CoreSetup.lua`**, bound to `LibKa0s-Core-1.0`'s own function objects. |
| `core/Database.lua` | `NS.Database` | `SCHEMA_VERSION`, `global.schemaVersion` default, and `RunMigrations(db)` (empty migration set today). |
| `core/CoreSetup.lua` | `NS.Print`, `NS.Format`, `NS.LIBKA0S_MISSING`, `NS.Util.SafeToString`, `NS.Util.IsConcatSafe` | The `LibKa0s-Core-1.0` seam. Builds the cyan `[PC]` printer from the descriptor (`prefix` as a function, `sep = ""` because the tag carries its own trailing space), reclaims `NS.Print` from AceConsole's embed, and owns the library-absent fallbacks. |
| `core/DebugLogSetup.lua` | `NS.DebugLog`, `NS.Debug` | The `LibKa0s-DebugLog-1.0` seam. Supplies the frame-name prefix, the title, the mono font, the `isEnabled`/`setEnabled` pair over `NS.State.debug`, the `[Init]` session summary and the visibility callback; the window, both formatters, the buffer, the scroll sync and the `SetEnabled` seam are the library's. |
| `core/PrettyChat.lua` | the AceAddon object | AceAddon registration (the `NS` table itself — passed to `:NewAddon`, architecture-§2) + lifecycle (`OnInitialize` / `OnEnable`), and `OpenConfig`, now a one-line delegate to the library's combat-gated `OpenOptionsPanel`. |
| `defaults/Profile.lua` | `NS.ProfileDefaults` | The AceDB `profile` defaults table (`{ profile = { categories = {} } }`); `OnInitialize` merges it with `NS.Database`'s `global` defaults before `AceDB:New`. |
| `defaults/Defaults.lua` | `NS.Defaults` | Category → format-string default table (label + default per string; per-category `enabled`). |
| `locales/enUS.lua` | `NS.L` | Localization table with English-key fallback (`__index` returns the key). Seeds the enUS UI-string manifest. |
| `modules/Override.lua` | `NS.RenderSample` | The override engine — `ApplyStrings`, the enable-cascade predicates, `ResetString` / `ResetCategory` / `ResetAll`, and the Test / sample renderer. |
| `settings/Schema.lua` | `NS.Schema` | Builds `rows`/`byPath` from `NS.Defaults`; single write path (`Schema.Set`), `AllRows`, `ApplyDefault`, `FormatValue`, load-time path validator, cross-registered-global map, and the `NotifyPanelChange` fan-out that drives **both** refresher registries. |
| `settings/OptionsSetup.lua` | `NS.Helpers` | The `LibKa0s-Options-1.0` seam — the instance itself, decorated in place. Supplies the brand, the main canvas name, the `get`/`set`/`applyDefault` write seam, the per-page row lookup and the landing-page hook. |
| `settings/Slash.lua` | `NS.COMMANDS`, `NS.SlashCommands` | The ordered `COMMANDS` table (positional triples, the host's), the `LibKa0s-Slash-1.0` descriptor with its `format` and `parse` hooks, and the four host-owned verbs: `list`'s sub-keywords and category filter, `resetall`, `test`, `debug`. |
| `settings/Panel.lua` | `NS.Config.RegisterPanels`, `NS.Config.BuildMain` | The three page **bodies** and nothing else: the General page (library-drawn), the category pages (a library-made Enable row plus the bespoke 40/60 per-string editor), and the landing page. The canvas factory, the header, the Defaults button, the scroll container and the page registry are the library's. |

Topic detail: [module-map.md](./module-map.md), [file-index.md](./file-index.md).

## Namespace publishing pattern

Every file opens with `local addonName, NS = ...` — the addon-wide namespace table WoW passes to each chunk. Modules publish their public surface onto `NS`; nothing is exported through a global. The addon object **is** that same `NS` table (`core/PrettyChat.lua` passes `NS` to `:NewAddon`, architecture-§2), so the AceAddon methods hang off it and `LibStub("AceAddon-3.0"):GetAddon("PrettyChat")` returns the very same table.

| Member | Set by | Used by |
|--------|--------|---------|
| `NS.Compat` | `core/Compat.lua` | `core/Namespace.lua`, `settings/Slash.lua`, `settings/Panel.lua` (metadata access) |
| `NS.Const` / `NS.PREFIX` | `core/Constants.lua` | `core/Util.lua`, `core/CoreSetup.lua`, `core/DebugLogSetup.lua`, `modules/Override.lua`, `settings/Panel.lua`, `settings/Slash.lua` (palette/spacers/font/prefix) |
| `NS.name` / `NS.version` | `core/Namespace.lua` | identity bootstrap (published for any module) |
| `NS.State` | `core/State.lua` | `core/DebugLogSetup.lua`, `settings/Slash.lua` (session-only `debug` flag; reset every reload/login) |
| `NS.Util` | `core/Util.lua` (`trim` / `note` / `cmd`) + `core/CoreSetup.lua` (`SafeToString` / `IsConcatSafe`, bound to Core's) | `settings/Slash.lua`, `modules/Override.lua`, `core/DebugLogSetup.lua` |
| `NS.Database` | `core/Database.lua` | `core/PrettyChat.lua` (`OnInitialize` merges defaults + runs migrations) |
| `NS.LIBKA0S_MISSING` | `core/CoreSetup.lua` | `core/DebugLogSetup.lua`, `settings/OptionsSetup.lua`, `settings/Slash.lua` — the shared cause clause every degraded seam appends its own consequence to |
| `NS.DebugLog` / `NS.Debug` | `core/DebugLogSetup.lua` | every file (the `LibKa0s-DebugLog-1.0` console + its gated `Debug` sink, bound bare; `SetEnabled` seam driven by `/pc debug`) |
| `NS.Print` / `NS.Format` | `core/CoreSetup.lua` | every file (secret-safe cyan `[PC]` chat-output chokepoint, built by `LibKa0s-Core-1.0`) |
| `NS.ProfileDefaults` | `defaults/Profile.lua` | `core/PrettyChat.lua` (`OnInitialize` merges it with `NS.Database.defaults` for `AceDB:New`) |
| `NS.Defaults` | `defaults/Defaults.lua` | `settings/Schema.lua`, `modules/Override.lua`, `settings/Slash.lua`, `settings/Panel.lua` |
| `NS.L` | `locales/enUS.lua` | `settings/Panel.lua`, `settings/Slash.lua`, `settings/Schema.lua` (UI strings — the `General.enabled` row's label and tooltip) |
| `NS.GlobalStrings` | `GlobalStrings/` chunks | `settings/Panel.lua` (Original Format String display) |
| `NS.RenderSample` | `modules/Override.lua` | `settings/Panel.lua` (per-string Preview) |
| `NS.Schema` | `settings/Schema.lua` | `settings/Slash.lua` (slash), `settings/Panel.lua` (widgets) |
| `NS.COMMANDS` / `NS.SlashCommands` | `settings/Slash.lua` | `settings/Panel.lua` (the landing page renders `NS.SlashCommands.LandingRows()`) |
| `NS.Helpers` | `settings/OptionsSetup.lua` | `settings/Panel.lua` (the `LibKa0s-Options-1.0` instance itself), `settings/Schema.lua` (`RefreshScalars`), `core/PrettyChat.lua` (`OpenOptionsPanel`) |
| `NS.Config.RegisterPanels()` | `settings/Panel.lua` | `core/PrettyChat.lua` (`OnEnable`) |

## Invariants

Break one of these and the addon misbehaves in ways no test or lint will name.

- **Single write path.** Every settings mutation goes through `NS.Schema.Set(path, value)` — panel widget callbacks (`settings/Panel.lua`) and `/pc set` (`settings/Slash.lua`) alike. Never write `db.profile.categories[…]` directly from outside a row's `set()` closure; only the single path runs `PrettyChat:ApplyStrings()` and `Schema.NotifyPanelChange()`, and it is what keeps panel and slash from drifting.
- **Master toggle wins.** With `General.enabled` false, `ApplyStrings` restores every Blizzard original regardless of per-category and per-string state. Three enable layers, evaluated in order: addon → category → per-string ([override-pipeline.md](./override-pipeline.md)).
- **Format-specifier signatures must match Blizzard's.** Each Blizzard string has a fixed signature (`%s`, `%d`, `%.1f`, `%2$s`, …); a replacement must consume the same conversions in the same order or `string.format` errors at runtime. Copy the signature from the panel's left (Original) edit box.
- **Overrides only ever happen in `ApplyStrings`, and the snapshot only in `OnEnable`.** `OnEnable` runs after Blizzard has populated `_G`, and its pre-override snapshot (iterating `NS.Defaults` deterministically) is the one chance to capture pristine values for the runtime restore-on-disable path. Never assign `_G[GLOBALNAME]` from anywhere but `ApplyStrings`, which walks `CATEGORY_ORDER` plus sorted names so cross-registered globals resolve deterministically (documented last-writer).
- **All chat output goes through `NS.Print`; all developer logging through `NS.Debug`.** `NS.Print` (`core/CoreSetup.lua`, built by `LibKa0s-Core-1.0`) prepends the cyan `NS.PREFIX` (`|cff00ffff[PC]|r `) — **no raw `print(...)` and no direct `DEFAULT_CHAT_FRAME:AddMessage`** anywhere, including `Test()` in `modules/Override.lua`, whose every body line is prefixed. `NS.Debug(tag, fmt, …)` is a zero-alloc no-op while off, gated on the session-only `NS.State.debug` flag whose single owner is `NS.DebugLog:SetEnabled(on)` (`/pc debug on|off`, the console header toggle). Console **visibility** is a separate concern (`:Show()` / `:Hide()` / `:Toggle()` / `:IsShown()`, bare `/pc debug` and the General-page checkbox); the window's OnShow/OnHide fire `Schema.NotifyPanelChange("General")` so the checkbox tracks it. `SetEnabled` prints the color-coded ack, writes the `[Debug] logging enabled|disabled` bracket, and on enable appends the one-line `[Init]` session summary (`PrettyChat v<ver>, schema v<n>, profile '<key>'`) — the visible boot summary, since the flag is off at login. Traces are **one gated line per event, never per string**: `[Init]`, `[Migrate]` (`core/Database.lua`, only when a step runs), `[Set] <path> = <value>` (`Schema.Set`, the single settings-change seam — no `[Apply]` re-echo), `[Reset]` (`modules/Override.lua`, with apply counts), `[Cfg]` (the library's panel-open — opened/refused). `ApplyStrings` returns `(applied, restored)` and stays silent so its caller emits the summary.
- **`libs/` is never edited, and a misfit is a finding rather than a patch.** `libs/LibKa0s/` and `tests/_kit/` are vendored whole from the sibling `../LibKa0s` checkout. A local edit is a fork nobody knows about, and the next re-vendor reverts it silently — so a library problem is fixed upstream and re-vendored back. `tests/test_vendor_sync.lua` — a call into the shared, vendored gate `tests/_kit/vendor_sync.lua` — compares both folders against the released tag the README says this addon bundles whenever that checkout is present, and [testing.md](./testing.md) carries the four diffs the release path uses.
- **A LibKa0s descriptor is never handed `NS.L`.** The locale table answers *every* key with the key itself (the standard mandates the metatable fallback), so a module handed it would render raw `SCREAMING_SNAKE` keys in place of English — for every key at once, visible only in game. `tests/test_libka0s.lua` greps every seam file for the three spellings and drives the matcher against all of them. Translate by passing a **plain** table of just the keys you translate.
- **User-facing strings go through `NS.L`.** `locales/enUS.lua` exports an English-key metatable (missing keys fall back to the key). Wrap new static UI strings in `L["…"]` and add them to the enUS manifest.

## Settings Schema

`NS.Defaults` is the source data; `settings/Schema.lua` turns it into an ordered `rows` list keyed by dot path. Four row kinds:

- `General.enabled` — addon-wide master toggle (bool). `General` is a **virtual category** with no entry in `NS.Defaults`; stored as `db.profile.enabled` at the profile root.
- `<Category>.enabled` — per-category toggle (bool).
- `<Category>.<GLOBALNAME>.enabled` — per-string toggle (bool).
- `<Category>.<GLOBALNAME>.format` — per-string format string.

Every mutation goes through `NS.Schema.Set(path, value)` — the **single write path** used by both `/pc set` and the panel widgets. Row `set()` closures are pure DB writes; `Schema.Set` runs `PrettyChat:ApplyStrings()` + `Schema.NotifyPanelChange()`. `string_format` rows **auto-clear** on a default match (a value equal to the default deletes the stored override). At load, `Schema.validation` records that every row path resolves to a backing default (loud `NS.Print` warn on any miss). Settings persist in `PrettyChatDB` via AceDB on a single shared Default profile; the `profile` defaults come from `defaults/Profile.lua` (`NS.ProfileDefaults`) and `db.global.schemaVersion` is stamped by `Database.RunMigrations`. Detail: [schema.md](./schema.md).

## Slash Commands

`/pc` and `/prettychat` dispatch through one ordered `COMMANDS` table in `settings/Slash.lua` (help text is generated from the same table). Verbs: `help`, `config`, `version`, `list`, `get`, `set`, `reset`, `resetall`, `test`, `debug`. `NS.COMMANDS` is published as positional triples so the landing page renders the same list through `Sl:LandingRows()` — one formatter, two surfaces. Dispatch, help, the schema verbs, the `key = value` pair and the parser are `LibKa0s-Slash-1.0`'s; this addon adds a `format` hook (the `||` doubling) and a `parse` hook (free text containing spaces). `reset` takes a **path**, not a category. Chat input requires `||` for a literal `|`. Detail: [slash-commands.md](./slash-commands.md).

## Event Subscriptions

**None by design**, and a whole-repo sweep of `core/ defaults/ modules/ settings/ locales/` confirms it: zero `RegisterEvent`, zero `OnUpdate`, zero `C_Timer`, zero ticker. PrettyChat registers no chat filters and hooks no chat frames — the entire mechanism is overriding `_G[GLOBALNAME]` and letting WoW's chat code read it lazily. The only lifecycle hooks are the AceAddon callbacks `OnInitialize` (DB + migrations + slash registration) and `OnEnable` (snapshot Blizzard originals → `ApplyStrings` → register panels). Adding an event subscription or chat filter would change the addon's compatibility contract. There is no message bus.

## Taint Notes

- The panel-open guards on `InCombatLockdown()` before `Settings.OpenToCategory` — the protected category-switch taints the panel for the session if called under combat lockdown. The guard lives **inside the library's `OpenOptionsPanel`** rather than in the slash dispatcher, so every caller is gated; `PrettyChat:OpenConfig` is a one-line delegate and there is deliberately no second open path (options-ui-§2).
- The category-tree expansion reaches into private `SettingsPanel` internals (`GetCategoryList`, `GetCategoryEntry`, `SetExpanded`) inside a `pcall`. That code is `LibKa0s-Options-1.0`'s now, and it is silent when the private API moves — see LIBKA0S-04.
- The always-show-scrollbar patch reaches into AceGUI ScrollFrame internals and restores stock behavior on widget release so the shared AceGUI pool isn't polluted for other addons. Also the library's (`OptionsScroll.lua`).
- `SetRenderer` puts a **second** combat guard on the render itself, because the Blizzard AddOns sidebar reaches a panel without going through the panel-open at all — the path a user is most likely to take mid-fight. Before adopting, this addon had no guard there.
- No `SecureHook`, no protected-frame creation, no combat-sensitive writes beyond the guarded panel open.

## Known Limitations

- **Retail only.** `## Interface: 120007` (Midnight / Retail). Classic / Classic Era untested.
- **Snapshot is load-time.** `OnEnable` snapshots Blizzard originals only for strings mentioned in `NS.Defaults` (~81). Adding a new `globalName` needs a `/reload` for the snapshot to capture its pristine value.
- **Cross-registered globals: last-writer-wins.** A global registered under two categories (e.g. `LOOT_ITEM_CREATED_SELF` under Loot + Tradeskill) resolves to the **last** category in `CATEGORY_ORDER` — now deterministic (PC-16), surfaced in the per-string tooltip.
- **Positional format rendering is WoW-only.** `%n$s` specifiers rely on WoW's extended `string.format`; the headless test harness (stock Lua 5.1) can't render them and asserts graceful degradation instead.
- **Single shared profile.** Per-character / per-realm profile scoping is not exposed.

## Documented deviations

Every ratified deviation from the Ka0s WoW Addon Standard lives here and **only** here
(`documentation-§3`). A decision may be *reasoned* at length in [pending/LEDGER.md](./pending/LEDGER.md)
or in an audit bundle, and the row cites that id — but **a deviation not in this table is not
ratified**, and an audit that cannot find a decision here re-files it as an open MUST.

**Re-check trigger** is the condition that ends the deviation, written so a reader can tell whether it
has already fired. A row whose cited rule the standard has since changed — so the behavior is now
mandated or permitted outright — is **retired**, not kept.

| Rule | What differs | Why | Decided | Re-check trigger |
|---|---|---|---|---|
| `performance-§12` | No perf harness is wired: no `core/PerfSetup.lua`, no `PrettyChatPerfDB`, no `perf` verb registration, no suspend/resume contract, no `tests/perf.lua`, no `docs/perf-runs/` | **Criterion (a)** holds — no `OnUpdate` handler, no repeating ticker, no in-combat event handler — proven by the committed whole-repo sweep in [performance.md](./performance.md), which returns one hit and it is a `.luacheckrc` lint declaration rather than a call. **Both (b) and (c)** apply: every declared bucket would read `0.000` by construction, and `suspend` would flip the player's chat formatting back to Blizzard's mid-fight for a capture that can only report zero. Reasoned at length as `LIBKA0S-12` in [pending/LEDGER.md](./pending/LEDGER.md) | 2026-08-05 | **The first `OnUpdate` handler, repeating ticker, or in-combat event handler doing real work re-arms the full wiring MUST.** Re-run the sweep in `performance.md`; if it returns a call, the exemption is over |
| `layout-§2` | `GlobalStrings/` is a **PascalCase, root-level** folder outside the mandated `core/ defaults/ settings/ locales/ modules/` skeleton (`layout-§1`), holding 26 machine-generated chunks (~22,879 Blizzard reference strings) plus the **unshipped, unloaded** 23,842-line source dump `GlobalStrings/GlobalStrings.lua`, which is over `layout-§1`'s 1500-LOC cap | The modular layout has no home for bulk generated reference data. Chunks are cut by entry count, not by first letter, and each is under 1000 lines so the shipped data stays out of `layout-§1`'s on-notice band (PC-49). The dump is excluded by `.pkgmeta:21` and referenced by no TOC line, so nothing loads it. Regenerate with `python3 GlobalStrings/split_globalstrings.py` | 2026-07-15 | A `layout` revision that sanctions a generated-data folder, **or** the chunks moving under a lowercase folder inside the skeleton (`defaults/globalstrings/`) without breaking TOC load order — which would close this row and the `toc-file-§5` row below together |
| `toc-file-§5` | The TOC file listing carries a non-canonical `# GlobalStrings` section (`PrettyChat.toc:42-68`), and `# Locales` sits immediately after `# Libraries` rather than after `# Defaults` | The `# GlobalStrings` section is only the TOC home of the `layout-§2` exception above. The Locales placement is a **standard-internal conflict**: `toc-file-§5` orders Locales before Defaults, `layout-§1`'s load order puts Defaults first, and the two disagree (the same pair disagree on `settings/*` vs `modules/*`). Resolved toward `toc-file-§5` in both places; `locales/enUS.lua` only builds `NS.L` and has no earlier-load dependency, so loading it first is safe. Raised upstream as [WowAddonStandards#2](https://github.com/tusharsaxena/WowAddonStandards/issues/2) | 2026-07-18 | WowAddonStandards#2 resolving. If it resolves in favor of `layout-§1`, both orderings here are revisited |
| `toc-file-§1` | `## Title:` keeps its rainbow `\|cRRGGBB…\|r` escapes, `## Author:` keeps its stylized `aDd1kTeD2Ka0s` casing, and `## X-Wago-ID` is absent | The color escapes and the casing are the addon's brand mark, kept deliberately rather than normalized to `Ka0s Pretty Chat` / `add1kted2ka0s`. `toc-file-§1` asks for both distribution ids once an addon is published anywhere; PrettyChat is on CurseForge only (`## X-Curse-Project-ID: 919766`), so there is no Wago listing to reference. Do not add the field and do not commit a placeholder | 2026-07-12 | The addon being listed on Wago (which re-arms `X-Wago-ID` immediately), or a decision to retire the brand mark |
| `debug-logging-§2` | The debug console's monospace font (JetBrains Mono, OFL, `media/fonts/`) is handed to the library as the console descriptor's `font` path via `Const.FONT_MONO`, **without** LibSharedMedia registration | The console is intentionally fixed-monospace — readability of aligned log output does not depend on player taste — and this addon ships **no** font, texture, border or sound picker anywhere (2026-07-17 media audit), so LSM would have no consumer surface. Not to be "fixed" by adding LSM | 2026-07-17 | The first user-facing media picker in this addon, which gives LSM a consumer |
| `options-ui-§6` | The per-string editor in `settings/Panel.lua` uses a bespoke 40/60 three-row layout (`LEFT_W = 0.4` / `RIGHT_W = 0.6`) instead of the schema-driven 50/50 two-column grid | The right column holds full color-escaped format strings — the Blizzard original, the user's replacement and the live preview — which a 50/50 split clips. Re-checked against `LibKa0s-Options-1.0`'s caller-driven `RenderGrid` during adoption and kept: `RenderGrid` offers `HALF` (0.5) or full width and no third ratio, so it cannot express 40/60 either (`LIBKA0S-06`). Justified in-code above `buildStringRow` | 2026-07-31 | `RenderGrid` gaining a third width ratio (`LIBKA0S-06`), or the editor no longer needing to show three format strings side by side |
| `testing-§1` | `tests/wow_mock.lua` is the thin extender over `tests/_kit/mock_base.lua` the rule asks for, but **`tests/loader.lua` survives** beside `tests/_kit/loader.lua` | The kit builds one shared environment whose `__newindex` writes through to the real `_G`. This addon's entire feature is rewriting `_G[GLOBALNAME]` and half the suite asserts on what landed there, so a shared environment would let one suite's overrides answer another suite's reads. `tests/loader.lua` is reduced to exactly that isolation need — a fresh mock per instance, `_G` pointed back at it, chunks compiled once — and takes everything else from the kit (`Loader.makeEnv`, `Loader.tocFiles`, `Loader.xmlFiles`). Reported upstream as `LIBKA0S-01` | 2026-08-02 | `tests/_kit/loader.lua` gaining an isolated-environment mode (`LIBKA0S-01`), after which `tests/loader.lua` is deleted outright |
| `library-stack-§1` | `AceEvent-3.0` and `AceTimer-3.0` are **not** vendored, although `library-stack-§1`'s mandatory-libs table lists both as vendored | The rule contradicts itself: `library-stack.md:13-14` lists AceEvent and AceTimer among the libs every Ace3 addon vendors, while `library-stack.md:39` MUSTs vendoring **only** libs the addon actually `LibStub("X")`. This addon `LibStub`s neither — it registers no events and starts no timers — so the two halves cannot both be satisfied, and `:39` (vendor what you use, nothing more) wins. Recorded as PC-52 in `docs/audits/2026-08-04/02_DEVIATIONS.md`; no upstream item resolves it | 2026-08-04 | The next `library-stack` edit — the contradiction is upstream, and this row ends when the standard picks one half |

## External dependencies

Vendored under `libs/` (the BigWigs packager pulls nothing — no `externals`): LibStub, CallbackHandler-1.0, AceAddon-3.0, AceDB-3.0, AceConsole-3.0, AceGUI-3.0, and **[LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.8.0** (`libs/LibKa0s/`, listed in the TOC as `libs\LibKa0s\LibKa0s.xml` after Ace3). (`AceConfig-3.0` was removed — no live consumer.)

Four of LibKa0s's five majors are adopted: **Core**, **DebugLog**, **Slash** and **Options**. **Perf is declined** under a recorded `performance-§12` no-combat-path exemption — the register row above, with its sweep in [performance.md](./performance.md) and its reasoning at LIBKA0S-12 in [pending/LEDGER.md](./pending/LEDGER.md). `Perf.lua` and `PerfPanel.lua` are still vendored, because the folder is copied whole and never file by file.

The shared test kit is vendored separately to `tests/_kit/` — **never** to `libs/`, which is the ship payload.

## Testing

Headless harness under `tests/` (stock Lua 5.1, no client): `lua tests/run.lua` + `luacheck .`. Suites register named `test(name, fn)` cases; `lua tests/run.lua --list` prints the generated case inventory ([test-cases.md](./test-cases.md), testing-§5) — the authoritative pass count, mirrored by the README `tests` badge. Manual in-game validation: [smoke-tests.md](./smoke-tests.md). Full verification guide and the commit gate: [testing.md](./testing.md).

## Working environment

- **Dual-path WSL.** `/home/tushar/GIT/prettychat/` and `/mnt/d/Profile/Users/Tushar/Documents/GIT/prettychat/` are the same repo via symlink.
- **`.gitattributes`** forces CRLF on disk for all text files — hence the `--strip-trailing-cr` in the inventory diff ([testing.md](./testing.md)).
- **`.gitignore`** covers OS/editor cruft and `.claude/`. `libs/` is tracked (vendored Ace3), as are `GlobalStrings/`, `media/`, all `.lua` source, `tests/`, `.luacheckrc` and `.pkgmeta`.
- **Case-insensitive `/mnt/d`.** `libs/` was renamed from `Libs/` on disk; with `core.ignorecase=true`, recording a case flip in git needs `git mv -f Libs libs` even though the working tree already reads lowercase.

## Doc index

Topic-specific detail lives in `docs/`. Read on demand.

| Topic | File |
|-------|------|
| How to verify: harness, lint, the commit gate | [testing.md](./testing.md) |
| What to install: the toolchain contract | [../DEPENDENCIES.md](../DEPENDENCIES.md) |
| Automated test records + the complexity watch list | [automated-tests/RESULTS.md](./automated-tests/RESULTS.md) |
| What this addon costs + the no-combat-path sweep | [performance.md](./performance.md) |
| In/out scope + resolved decisions | [scope.md](./scope.md) |
| Per-file responsibility map | [file-index.md](./file-index.md) |
| Module roles + public APIs | [module-map.md](./module-map.md) |
| Snapshot → ApplyStrings → restore + 3-layer enable order | [override-pipeline.md](./override-pipeline.md) |
| Schema row kinds + single write path + auto-clear + AceDB shape | [schema.md](./schema.md) |
| Canvas-layout panel framework | [settings-panel.md](./settings-panel.md) |
| `COMMANDS` table + full command reference | [slash-commands.md](./slash-commands.md) |
| Dual-load story + splitter script | [global-strings.md](./global-strings.md) |
| Recipes (add string/category, fix a format) | [common-tasks.md](./common-tasks.md) |
| Quick recipe + full smoke-test suite | [smoke-tests.md](./smoke-tests.md) |
| Every LibKa0s adoption decision, declined surface and reported gap | [pending/LEDGER.md](./pending/LEDGER.md) |
