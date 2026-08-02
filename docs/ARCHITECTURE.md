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

Modular layout (`core/`, `defaults/`, `locales/`, `modules/`, `settings/`) — the single Ka0s layout (`layout-§1`). Load order is `PrettyChat.toc` (dependency, not alphabetical): libraries first, then `locales/enUS → core/Compat → core/Constants → core/Namespace → core/State → core/Util → core/Database → core/DebugLog → core/PrettyChat → defaults/Profile → defaults/Defaults → GlobalStrings chunks → modules/Override → settings/Schema → settings/Slash → settings/Panel`.

| Module | Publishes on `NS` | Role |
|--------|-------------------|------|
| `core/Compat.lua` | `NS.Compat` | Version-shim seam. `Compat.GetAddOnMetadata` (C_AddOns vs legacy global). |
| `core/Constants.lua` | `NS.Const`, `NS.PREFIX` | Panel layout constants, `Const.Color` palette (incl. `azure` / `listHead` slash-output codes), `Const.BUTTON_PAIR_REL`, `Const.FONT_MONO` (vendored JetBrains Mono path), and the shared cyan `[PC]` chat prefix. Side-effect-free. |
| `core/Namespace.lua` | `NS.name`, `NS.version` | Identity bootstrap — records the addon name + version so any module can read them without re-querying the TOC. |
| `core/State.lua` | `NS.State` | Session-only runtime state (`{ debug = false }`); never persisted, reset every reload/login. |
| `core/Util.lua` | `NS.Util` | Pure string helpers `trim` / `note` / `cmd` (slash dispatcher) plus the secret-safe output helpers `SafeToString` / `IsConcatSafe` (events-frames-taint-§8) that the chat printer and debug sink route through. |
| `core/Database.lua` | `NS.Database` | `SCHEMA_VERSION`, `global.schemaVersion` default, and `RunMigrations(db)` (empty migration set today). |
| `core/DebugLog.lua` | `NS.DebugLog`, `NS.Debug` | On-screen debug console (monospace window) + the gated `NS.Debug(tag, fmt, …)` sink; the `SetEnabled` seam is the single owner of the session debug flag. |
| `core/PrettyChat.lua` | `NS.Print` | AceAddon object (the `NS` table itself — passed to `:NewAddon`, architecture-§2) + lifecycle (`OnInitialize` / `OnEnable`), the secret-safe cyan `[PC]` chat printer (reclaimed after AceConsole's `:Print` embed), and the combat-gated `OpenConfig`. |
| `defaults/Profile.lua` | `NS.ProfileDefaults` | The AceDB `profile` defaults table (`{ profile = { categories = {} } }`); `OnInitialize` merges it with `NS.Database`'s `global` defaults before `AceDB:New`. |
| `defaults/Defaults.lua` | `NS.Defaults` | Category → format-string default table (label + default per string; per-category `enabled`). |
| `locales/enUS.lua` | `NS.L` | Localization table with English-key fallback (`__index` returns the key). Seeds the enUS UI-string manifest. |
| `modules/Override.lua` | `NS.RenderSample` | The override engine — `ApplyStrings`, the enable-cascade predicates, `ResetString` / `ResetCategory` / `ResetAll`, and the Test / sample renderer. |
| `settings/Schema.lua` | `NS.Schema` | Builds `rows`/`byPath` from `NS.Defaults`; single write path (`Schema.Set`), `Schema.FormatValue`, load-time path validator, cross-registered-global map. |
| `settings/Slash.lua` | `NS.COMMANDS` | The `/pc` dispatcher — ordered `COMMANDS` table, `OnSlashCommand`, and every `list` / `get` / `set` / `reset` / `test` / `debug` handler. |
| `settings/Panel.lua` | `NS.Config.RegisterPanels` | Canvas-layout parent + one sub-page per category; per-string editor rows. |

Topic detail: [module-map.md](./module-map.md), [file-index.md](./file-index.md).

## Namespace publishing pattern

Every file opens with `local addonName, NS = ...` — the addon-wide namespace table WoW passes to each chunk. Modules publish their public surface onto `NS`; nothing is exported through a global. The addon object **is** that same `NS` table (`core/PrettyChat.lua` passes `NS` to `:NewAddon`, architecture-§2), so the AceAddon methods hang off it and `LibStub("AceAddon-3.0"):GetAddon("PrettyChat")` returns the very same table.

| Member | Set by | Used by |
|--------|--------|---------|
| `NS.Compat` | `core/Compat.lua` | `core/Namespace.lua`, `settings/Slash.lua`, `settings/Panel.lua` (metadata access) |
| `NS.Const` / `NS.PREFIX` | `core/Constants.lua` | `core/Util.lua`, `core/DebugLog.lua`, `core/PrettyChat.lua`, `settings/Panel.lua`, `settings/Slash.lua` (layout/palette/prefix) |
| `NS.name` / `NS.version` | `core/Namespace.lua` | identity bootstrap (published for any module) |
| `NS.State` | `core/State.lua` | `core/DebugLog.lua`, `settings/Slash.lua` (session-only `debug` flag; reset every reload/login) |
| `NS.Util` | `core/Util.lua` | `settings/Slash.lua`, `core/DebugLog.lua`, `core/PrettyChat.lua` (`trim` / `note` / `cmd` string helpers; secret-safe `SafeToString` / `IsConcatSafe`) |
| `NS.Database` | `core/Database.lua` | `core/PrettyChat.lua` (`OnInitialize` merges defaults + runs migrations) |
| `NS.DebugLog` / `NS.Debug` | `core/DebugLog.lua` | every file (on-screen debug console + gated `NS.Debug` sink; `SetEnabled` seam driven by `/pc debug`) |
| `NS.Print` | `core/PrettyChat.lua` | every file (secret-safe cyan `[PC]` chat-output chokepoint) |
| `NS.ProfileDefaults` | `defaults/Profile.lua` | `core/PrettyChat.lua` (`OnInitialize` merges it with `NS.Database.defaults` for `AceDB:New`) |
| `NS.Defaults` | `defaults/Defaults.lua` | `settings/Schema.lua`, `modules/Override.lua`, `settings/Slash.lua`, `settings/Panel.lua` |
| `NS.L` | `locales/enUS.lua` | `settings/Panel.lua`, `settings/Slash.lua` (UI strings) |
| `NS.GlobalStrings` | `GlobalStrings/` chunks | `settings/Panel.lua` (Original Format String display) |
| `NS.RenderSample` | `modules/Override.lua` | `settings/Panel.lua` (per-string Preview) |
| `NS.Schema` | `settings/Schema.lua` | `settings/Slash.lua` (slash), `settings/Panel.lua` (widgets) |
| `NS.COMMANDS` | `settings/Slash.lua` | `settings/Panel.lua` (parent page slash list) |
| `NS.Config.RegisterPanels()` | `settings/Panel.lua` | `core/PrettyChat.lua` (`OnEnable`) |

## Invariants

Break one of these and the addon misbehaves in ways no test or lint will name.

- **Single write path.** Every settings mutation goes through `NS.Schema.Set(path, value)` — panel widget callbacks (`settings/Panel.lua`) and `/pc set` (`settings/Slash.lua`) alike. Never write `db.profile.categories[…]` directly from outside a row's `set()` closure; only the single path runs `PrettyChat:ApplyStrings()` and `Schema.NotifyPanelChange()`, and it is what keeps panel and slash from drifting.
- **Master toggle wins.** With `General.enabled` false, `ApplyStrings` restores every Blizzard original regardless of per-category and per-string state. Three enable layers, evaluated in order: addon → category → per-string ([override-pipeline.md](./override-pipeline.md)).
- **Format-specifier signatures must match Blizzard's.** Each Blizzard string has a fixed signature (`%s`, `%d`, `%.1f`, `%2$s`, …); a replacement must consume the same conversions in the same order or `string.format` errors at runtime. Copy the signature from the panel's left (Original) edit box.
- **Overrides only ever happen in `ApplyStrings`, and the snapshot only in `OnEnable`.** `OnEnable` runs after Blizzard has populated `_G`, and its pre-override snapshot (iterating `NS.Defaults` deterministically) is the one chance to capture pristine values for the runtime restore-on-disable path. Never assign `_G[GLOBALNAME]` from anywhere but `ApplyStrings`, which walks `CATEGORY_ORDER` plus sorted names so cross-registered globals resolve deterministically (documented last-writer).
- **All chat output goes through `NS.Print`; all developer logging through `NS.Debug`.** `NS.Print` (`core/PrettyChat.lua`) prepends the cyan `NS.PREFIX` (`|cff00ffff[PC]|r `) — **no raw `print(...)` and no direct `DEFAULT_CHAT_FRAME:AddMessage`** anywhere, including `Test()` in `modules/Override.lua`, whose every body line is prefixed. `NS.Debug(tag, fmt, …)` is a zero-alloc no-op while off, gated on the session-only `NS.State.debug` flag whose single owner is `NS.DebugLog:SetEnabled(on)` (`/pc debug on|off`, the console header toggle). Console **visibility** is a separate concern (`:Show()` / `:Hide()` / `:Toggle()` / `:IsShown()`, bare `/pc debug` and the General-page checkbox); the window's OnShow/OnHide fire `Schema.NotifyPanelChange("General")` so the checkbox tracks it. `SetEnabled` prints the colour-coded ack, writes the `[Debug] logging enabled|disabled` bracket, and on enable appends the one-line `[Init]` session summary (`PrettyChat v<ver>, schema v<n>, profile '<key>'`) — the visible boot summary, since the flag is off at login. Traces are **one gated line per event, never per string**: `[Init]`, `[Migrate]` (`core/Database.lua`, only when a step runs), `[Set] <path> = <value>` (`Schema.Set`, the single settings-change seam — no `[Apply]` re-echo), `[Reset]` (`modules/Override.lua`, with apply counts), `[Config]` (`OpenConfig` — opened/refused/blocked). `ApplyStrings` returns `(applied, restored)` and stays silent so its caller emits the summary.
- **User-facing strings go through `NS.L`.** `locales/enUS.lua` exports an English-key metatable (missing keys fall back to the key). Wrap new static UI strings in `L["…"]` and add them to the enUS manifest.

## Settings Schema

`NS.Defaults` is the source data; `settings/Schema.lua` turns it into an ordered `rows` list keyed by dot path. Four row kinds:

- `General.enabled` — addon-wide master toggle (bool). `General` is a **virtual category** with no entry in `NS.Defaults`; stored as `db.profile.enabled` at the profile root.
- `<Category>.enabled` — per-category toggle (bool).
- `<Category>.<GLOBALNAME>.enabled` — per-string toggle (bool).
- `<Category>.<GLOBALNAME>.format` — per-string format string.

Every mutation goes through `NS.Schema.Set(path, value)` — the **single write path** used by both `/pc set` and the panel widgets. Row `set()` closures are pure DB writes; `Schema.Set` runs `PrettyChat:ApplyStrings()` + `Schema.NotifyPanelChange()`. `string_format` rows **auto-clear** on a default match (a value equal to the default deletes the stored override). At load, `Schema.validation` records that every row path resolves to a backing default (loud `NS.Print` warn on any miss). Settings persist in `PrettyChatDB` via AceDB on a single shared Default profile; the `profile` defaults come from `defaults/Profile.lua` (`NS.ProfileDefaults`) and `db.global.schemaVersion` is stamped by `Database.RunMigrations`. Detail: [schema.md](./schema.md).

## Slash Commands

`/pc` and `/prettychat` dispatch through one ordered `COMMANDS` table in `settings/Slash.lua` (help text is generated from the same table). Verbs: `help`, `config`, `version`, `list`, `get`, `set`, `reset`, `resetall`, `test`, `debug`. `NS.COMMANDS` is published so the parent panel renders the same list. Slash `list` / `get` / `set` output follows the mandated colour scheme (slash-commands-§5) via a shared `FormatKV` + `Schema.FormatValue`. Chat input requires `||` for a literal `|`. Detail: [slash-commands.md](./slash-commands.md).

## Event Subscriptions

**None by design.** PrettyChat registers no `RegisterEvent` / chat filters and hooks no chat frames — the entire mechanism is overriding `_G[GLOBALNAME]` and letting WoW's chat code read it lazily. The only lifecycle hooks are the AceAddon callbacks `OnInitialize` (DB + migrations + slash registration) and `OnEnable` (snapshot Blizzard originals → `ApplyStrings` → register panels). Adding an event subscription or chat filter would change the addon's compatibility contract. There is no message bus.

## Taint Notes

- `OpenConfig` guards on `InCombatLockdown()` before `Settings.OpenToCategory` — the protected category-switch taints the panel for the session if called under combat lockdown. The guard lives in `OpenConfig` (not just the slash dispatcher) so programmatic callers are also gated.
- `expandMainCategory` reaches into private `SettingsPanel` internals (`GetCategoryList`, `GetCategoryEntry`, `SetExpanded`) inside a `pcall`; a missing API surfaces a one-time grey notice rather than erroring.
- The always-show-scrollbar patch reaches into AceGUI ScrollFrame internals and restores stock behaviour on widget release so the shared AceGUI pool isn't polluted for other addons.
- No `SecureHook`, no protected-frame creation, no combat-sensitive writes beyond the guarded panel open.

## Known Limitations

- **Retail only.** `## Interface: 120007` (Midnight / Retail). Classic / Classic Era untested.
- **Snapshot is load-time.** `OnEnable` snapshots Blizzard originals only for strings mentioned in `NS.Defaults` (~81). Adding a new `globalName` needs a `/reload` for the snapshot to capture its pristine value.
- **Cross-registered globals: last-writer-wins.** A global registered under two categories (e.g. `LOOT_ITEM_CREATED_SELF` under Loot + Tradeskill) resolves to the **last** category in `CATEGORY_ORDER` — now deterministic (PC-16), surfaced in the per-string tooltip.
- **Positional format rendering is WoW-only.** `%n$s` specifiers rely on WoW's extended `string.format`; the headless test harness (stock Lua 5.1) can't render them and asserts graceful degradation instead.
- **Single shared profile.** Per-character / per-realm profile scoping is not exposed.

## External dependencies

Vendored under `libs/` (the BigWigs packager pulls nothing — no `externals`): LibStub, CallbackHandler-1.0, AceAddon-3.0, AceDB-3.0, AceConsole-3.0, AceGUI-3.0. (`AceConfig-3.0` was removed — no live consumer.)

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
