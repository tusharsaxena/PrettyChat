# Architecture

Orient-yourself map for **Ka0s Pretty Chat**. This file is the high-level index; topic detail lives alongside it in `docs/`.

## Overview

A WoW addon that overrides Blizzard's `GlobalStrings.lua` format strings — `LOOT_ITEM_SELF`, `COMBATLOG_XPGAIN_*`, `FACTION_STANDING_INCREASED`, etc. — to reformat system chat lines (loot, currency, money, reputation, XP, honor, tradeskill, misc) into a color-coded `Category | Context | Source | +/- value` layout. WoW's chat code reads `_G[GLOBALNAME]` lazily on every line, so overrides take effect uniformly across any chat UI (default Blizzard, ElvUI, Glass, …) without per-message hooks. Eight format-bearing categories (81 strings, 173 schema rows — 170 of them the categories', plus the three-row composed `Master controls` block) are addressed via a flat schema + `/pc` slash CLI + two Blizzard-panel sub-pages: `General`, whose one tab is `Master controls`, and a `Categories` page carrying one tab per category and, inside each, a list of that category's format strings beside the editor for the one selected.

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

GlobalStrings/   ─▶ NOT LOADED (PC-R-05). Repo-only reference data; tests/test_defaults.lua
                    reads it to check every override against Blizzard's real signature

OnEnable snapshot ─▶ addon.originalStrings ─▶ NS.OriginalFormat(addon, GLOBALNAME)
                       ├─▶ settings/Panel.lua "Original Format String" disabled input
                       └─▶ /pc test's Original line
```

## Module Map

Modular layout (`core/`, `defaults/`, `locales/`, `modules/`, `settings/`) — the single Ka0s layout (`layout-§1`). Load order is `PrettyChat.toc` (dependency, not alphabetical): libraries first — **including `libs\LibKa0s\LibKa0s.xml`, after Ace3** — then `locales/enUS → core/EnvSetup → core/MediaSetup → core/Constants → core/Namespace → core/State → core/Util → core/Database → core/PrettyChat → core/CoreSetup → core/DebugLogSetup → defaults/Profile → defaults/Defaults → modules/Override → settings/Schema → settings/OptionsSetup → settings/Slash → settings/Panel`.

**Five positions in that order are load-bearing and are pinned by tests, not by convention:**

- `core/EnvSetup.lua` sits **before** `core/Namespace.lua`, and therefore before `settings/Slash.lua` and `settings/Panel.lua` too, because all three read the TOC at FILE SCOPE — `NS.version`, `VERSION` and `TOC_NOTES` each resolve once at load and keep the answer for the whole session. All three call the seam unguarded, so a seam published later raises on the first load instead of pinning the reported version to a literal for good; `tests/test_envsetup.lua` pins what each of the three actually resolved to, which no raise can tell you.

- `core/MediaSetup.lua` sits **before** `core/Constants.lua`, because `Const.FONT_MONO` is resolved through `NS.MediaFont` at load. A seam published afterwards would leave every install silently on `STANDARD_TEXT_FONT` — a console that reads perfectly well in the wrong face, which is the kind of regression nobody files.

- `core/CoreSetup.lua` sits **immediately after** `core/PrettyChat.lua`, because that file passes `NS` to `AceAddon:NewAddon` and AceConsole embeds its own `:Print` over the namespace — CoreSetup's last two lines are the reclaim (anti-pattern #36). It also sits **before** `settings/Schema.lua`, the only load-time `NS.Print` caller. Nothing in the repo takes the printer as a file-scope upvalue, so the window between those two is wide.
- `core/DebugLogSetup.lua` sits after Constants (the mono font path), State (the flag) and CoreSetup (the printer), and before every module that calls `NS.Debug` (debug-logging-§1).
- `settings/OptionsSetup.lua` sits after `settings/Schema.lua`, whose `Get`/`Set`/`RowsByCategory` its descriptor reads, and before `settings/Panel.lua`, which takes the instance as a file-scope upvalue and registers its pages at file load (options-ui-§1).

### The shared cause clause

`core/CoreSetup.lua` publishes **`NS.LIBKA0S_MISSING`** — *"The LibKa0s library is missing from this installation of Ka0s Pretty Chat (expected in libs/LibKa0s)"* — outside its own library-absent branch, because the three later seams read it on **both** paths. Each appends its own consequence and its own terminal punctuation: `", so the debug console window is unavailable."`, `", so the settings panel is unavailable."`, `", so the settings CLI is unavailable."`, and Core's own fallback printer announces once, on the first line the addon prints, with `"; running on reduced built-in fallbacks."`. This is a **cross-file contract four seams depend on**, not an implementation detail of one file: a degraded install says the same thing about *why* at every site and a different thing about *what* at each one, across every Ka0s addon a user has open.

| Module | Publishes on `NS` | Role |
|--------|-------------------|------|
| `core/EnvSetup.lua` | `NS.Meta`, `NS.Version` | The `LibKa0s-Env-1.0` seam. Reads one field of this addon's own TOC manifest, and answers its version string (the TOC first, then `NS.version`, then `"?"`), telling the library which addon FOLDER is asking — a vendored copy cannot work that out for itself. Falls back to the C_AddOns-then-legacy-global ladder when the library is absent, so a degraded install reads its own TOC exactly as it did before. Replaced `core/Compat.lua`, which held nothing but the same reader. |
| `core/Constants.lua` | `NS.Const`, `NS.PREFIX` | `Const.Color` palette (incl. `azure` / `listHead` slash-output codes), the landing page's own section spacers, `Const.STRING_VSPACER`, `Const.FONT_MONO_NAME` / `Const.FONT_MONO` (JetBrains Mono, resolved through `NS.MediaFont` from the LibKa0s payload, falling back to `STANDARD_TEXT_FONT`), and the shared cyan `[PC]` chat prefix. Carries **no** panel layout constants — those are `LibKa0s-Options-1.0`'s `LAYOUT` table (options-ui-§8). Side-effect-free. |
| `core/Namespace.lua` | `NS.name`, `NS.version` | Identity bootstrap — records the addon name + version so any module can read them without re-querying the TOC. |
| `core/State.lua` | `NS.State` | Session-only runtime state (`{ debug = false }`); never persisted, reset every reload/login. |
| `core/Util.lua` | `NS.Util` | Pure string helpers `trim` / `note` / `cmd` (slash dispatcher). The secret-safe pair `SafeToString` / `IsConcatSafe` is **published onto this same table by `core/CoreSetup.lua`**, bound to `LibKa0s-Core-1.0`'s own function objects. |
| `core/Database.lua` | `NS.Database` | `SCHEMA_VERSION`, `global.schemaVersion` default, and `RunMigrations(db)` (empty migration set today). |
| `core/MediaSetup.lua` | `NS.Icon`, `NS.MediaFont` | The `LibKa0s-Media-1.0` seam. Answers a texture path (extensionless) or a font path for a name in the library's catalog, telling the library which addon FOLDER is asking — a vendored copy cannot work that out for itself. Both answer `nil` when the library is absent or the name is not one it ships; `nil` is a real answer and is never routed around by concatenation. Ends with `Media.RegisterLSM(addonName)` at file load, a no-op in this install because LibSharedMedia-3.0 is not vendored here. |
| `core/CoreSetup.lua` | `NS.Print`, `NS.Format`, `NS.LIBKA0S_MISSING`, `NS.MakeCloseButton`, `NS.Util.SafeToString`, `NS.Util.IsConcatSafe` | The `LibKa0s-Core-1.0` seam. Builds the cyan `[PC]` printer from the descriptor (`prefix` as a function, `sep = ""` because the tag carries its own trailing space), reclaims `NS.Print` from AceConsole's embed, and owns the library-absent fallbacks. |
| `core/DebugLogSetup.lua` | `NS.DebugLog`, `NS.Debug` | The `LibKa0s-DebugLog-1.0` seam. Supplies the frame-name prefix, the title, the mono font, the `isEnabled`/`setEnabled` pair over `NS.State.debug`, the `[Init]` session summary and the visibility callback; the window, both formatters, the buffer, the scroll sync and the `SetEnabled` seam are the library's. |
| `core/PrettyChat.lua` | the AceAddon object | AceAddon registration (the `NS` table itself — passed to `:NewAddon`, architecture-§2) + lifecycle (`OnInitialize` / `OnEnable`), and `OpenConfig`, now a one-line delegate to the library's combat-gated `OpenOptionsPanel`. |
| `defaults/Profile.lua` | `NS.ProfileDefaults` | The AceDB `profile` defaults table (`{ profile = { categories = {} } }`); `OnInitialize` merges it with `NS.Database`'s `global` defaults before `AceDB:New`. |
| `defaults/Defaults.lua` | `NS.Defaults` | Category → format-string default table (label + default per string; per-category `enabled`). |
| `locales/enUS.lua` | `NS.L` | Localization table with English-key fallback (`__index` returns the key). Seeds the enUS UI-string manifest. |
| `modules/Override.lua` | `NS.RenderSample`, `NS.OriginalFormat` | The override engine — `ApplyStrings`, the enable-cascade predicates, `ResetString` / `ResetCategory` / `ResetAll`, the Test / sample renderer, and the one reader of Blizzard's pristine format (`OriginalFormat`), shared with the panel's Original box. `ResetAll` is a **profile reset** (`options-ui-§12`): one `db:ResetProfile()`, with the re-apply and the `[Reset]` summary landing on `core/PrettyChat.lua`'s `OnProfileReset` handler — the same path a profile switch takes. |
| `settings/Schema.lua` | `NS.Schema` | Builds `rows`/`byPath` from `NS.Defaults`; single write path (`Schema.Set`), `AllRows`, `ApplyDefault`, `FormatValue`, load-time path validator, cross-registered-global map, and the `NotifyPanelChange` fan-out that drives **both** refresher registries. |
| `settings/OptionsSetup.lua` | `NS.Helpers` | The `LibKa0s-Options-1.0` seam — the instance itself, decorated in place. Supplies the brand, the main canvas name, the `get`/`set`/`applyDefault` write seam, the per-page row lookup and the landing-page hook. |
| `settings/Slash.lua` | `NS.COMMANDS`, `NS.SlashCommands` | The ordered `COMMANDS` table (positional triples, the host's), the `LibKa0s-Slash-1.0` descriptor with its `format` and `parse` hooks, and the four host-owned verbs: `list`'s sub-keywords and category filter, `resetall`, `test`, `debug`. |
| `settings/Panel.lua` | `NS.Config.RegisterPanels`, `NS.Config.BuildMain` | The page **bodies** and nothing else, for the addon's three kinds of page: the `General` page (a `TextRow` then `H.RenderTabbedSchema` over its one composed `Master controls` tab, whose `afterGroup` draws the host `Test` button and then the composer's own closing button), the `Categories` page (an `H.TabStrip` of the eight message categories, a footnote, then per tab a library-made Enable row, a bespoke 33/67 split — a list of that category's format strings beside **one** editor for the selected string), and the landing page. The primary strip is the library's; the list and the editor beside it are the `options-ui-§13` and `§6` deviations. The canvas factory, the header, the Defaults button, the scroll container and the page registry are the library's. |

Topic detail: [module-map.md](./module-map.md).

## Namespace publishing pattern

Every file opens with `local addonName, NS = ...` — the addon-wide namespace table WoW passes to each chunk. Modules publish their public surface onto `NS`; nothing is exported through a global. The addon object **is** that same `NS` table (`core/PrettyChat.lua` passes `NS` to `:NewAddon`, architecture-§2), so the AceAddon methods hang off it and `LibStub("AceAddon-3.0"):GetAddon("PrettyChat")` returns the very same table.

| Member | Set by | Used by |
|--------|--------|---------|
| `NS.Meta`, `NS.Version` | `core/EnvSetup.lua` | `core/Namespace.lua`, `settings/Slash.lua`, `settings/Panel.lua` (metadata access, all three at FILE SCOPE) |
| `NS.Icon`, `NS.MediaFont` | `core/MediaSetup.lua` | `core/Constants.lua` (`FONT_MONO`, at file scope). **`NS.Icon` has no host caller today** — the marks a player sees are drawn by the library's own console windows, told the folder name through `core/DebugLogSetup.lua`'s descriptor; the seam is published so the first window this addon builds asks the catalog rather than typing a path |
| `NS.MakeCloseButton` | `core/CoreSetup.lua` | **No host caller today**, for the same reason — published so the next window this addon builds does not have to remember the folder name at its call site. Covered by `tests/test_libka0s.lua` |
| `NS.Const` / `NS.PREFIX` | `core/Constants.lua` | `core/Util.lua`, `core/CoreSetup.lua`, `core/DebugLogSetup.lua`, `modules/Override.lua`, `settings/Panel.lua`, `settings/Slash.lua` (palette/spacers/font/prefix) |
| `NS.name` / `NS.version` | `core/Namespace.lua` | identity bootstrap (published for any module) |
| `NS.State` | `core/State.lua` | `core/DebugLogSetup.lua`, `settings/Slash.lua` (session-only `debug` flag; reset every reload/login) |
| `NS.Util` | `core/Util.lua` (`trim` / `note` / `cmd`) + `core/CoreSetup.lua` (`SafeToString` / `IsConcatSafe`, bound to Core's) | `settings/Slash.lua`, `modules/Override.lua`, `core/DebugLogSetup.lua` |
| `NS.Database` | `core/Database.lua` | `core/PrettyChat.lua` (`OnInitialize` merges defaults + runs migrations) |
| `NS.LIBKA0S_MISSING` | `core/CoreSetup.lua` | `core/DebugLogSetup.lua`, `settings/OptionsSetup.lua`, `settings/Slash.lua` — the shared cause clause every degraded seam appends its own consequence to |
| `NS.DebugLog` / `NS.Debug` | `core/DebugLogSetup.lua` | every file (the `LibKa0s-DebugLog-1.0` console + its gated `Debug` sink, bound bare; `SetEnabled` seam driven by `/pc debug`) |
| `NS.Print` / `NS.Format` | `core/CoreSetup.lua` | `NS.Print` — every file (secret-safe cyan `[PC]` chat-output chokepoint, built by `LibKa0s-Core-1.0`). **`NS.Format` has no host caller today** — published on both the library and the degraded path so the first caller added later is not nil in exactly the install the fallback exists for |
| `NS.ProfileDefaults` | `defaults/Profile.lua` | `core/PrettyChat.lua` (`OnInitialize` merges it with `NS.Database.defaults` for `AceDB:New`) |
| `NS.Defaults` | `defaults/Defaults.lua` | `settings/Schema.lua`, `modules/Override.lua`, `settings/Slash.lua`, `settings/Panel.lua` |
| `NS.L` | `locales/enUS.lua` | `settings/Panel.lua`, `settings/Slash.lua`, `settings/Schema.lua` (UI strings — the `General.enabled` row's label and tooltip) |
| `NS.OriginalFormat` | `modules/Override.lua` | `settings/Panel.lua` (Original Format String display), `modules/Override.lua` (`/pc test`'s Original line) — one reader of Blizzard's pristine format for both surfaces |
| `NS.RenderSample` | `modules/Override.lua` | `settings/Panel.lua` (per-string Preview) |
| `NS.Schema` | `settings/Schema.lua` | `settings/Slash.lua` (slash), `settings/Panel.lua` (widgets) |
| `NS.COMMANDS` / `NS.SlashCommands` | `settings/Slash.lua` | `settings/Panel.lua` reads **`NS.SlashCommands`** (the landing page renders `NS.SlashCommands:LandingRows()`). **`NS.COMMANDS` has no consumer in the addon's own source** — the descriptor is handed the file-local `COMMANDS` upvalue, and the published copy is read only by the suite (`tests/test_slash.lua`, `test_panel.lua`, `test_libka0s.lua`, `test_locale.lua`, `test_debuglog.lua`), which is where the host-owns-its-verbs contract is actually pinned |
| `NS.Helpers` | `settings/OptionsSetup.lua` | `settings/Panel.lua` (the `LibKa0s-Options-1.0` instance itself), `settings/Schema.lua` (`RefreshScalars`), `core/PrettyChat.lua` (`OpenOptionsPanel`) |
| `NS.Config.RegisterPanels()` | `settings/Panel.lua` | `core/PrettyChat.lua` (`OnEnable`) |

## Invariants

Break one of these and the addon misbehaves in ways no test or lint will name.

- **Single write path.** Every settings mutation goes through `NS.Schema.Set(path, value)` — panel widget callbacks (`settings/Panel.lua`) and `/pc set` (`settings/Slash.lua`) alike. Never write `db.profile.categories[…]` directly from outside a row's `set()` closure; only the single path runs `PrettyChat:ApplyStrings()` and `Schema.NotifyPanelChange()`, and it is what keeps panel and slash from drifting.
- **Master toggle wins.** With `General.enabled` false, `ApplyStrings` restores every Blizzard original regardless of per-category and per-string state. Three enable layers, evaluated in order: addon → category → per-string ([data-flow.md](./data-flow.md)).
- **Format-specifier signatures must match Blizzard's.** Each Blizzard string has a fixed signature (`%s`, `%d`, `%.1f`, `%2$s`, …); a replacement must consume the same conversions in the same order or `string.format` errors at runtime. Copy the signature from the panel's left (Original) edit box.
- **Overrides only ever happen in `ApplyStrings`, and the snapshot only in `OnEnable`.** `OnEnable` runs after Blizzard has populated `_G`, and its pre-override snapshot (iterating `NS.Defaults` deterministically) is the one chance to capture pristine values for the runtime restore-on-disable path. Never assign `_G[GLOBALNAME]` from anywhere but `ApplyStrings`, which walks `CATEGORY_ORDER` plus sorted names so cross-registered globals resolve deterministically (documented last-writer).
- **All chat output goes through `NS.Print`; all developer logging through `NS.Debug`.** `NS.Print` (`core/CoreSetup.lua`, built by `LibKa0s-Core-1.0`) prepends the cyan `NS.PREFIX` (`|cff00ffff[PC]|r `) — **no raw `print(...)` and no direct `DEFAULT_CHAT_FRAME:AddMessage`** anywhere, including `Test()` in `modules/Override.lua`, whose every body line is prefixed. `NS.Debug(tag, fmt, …)` is a zero-alloc no-op while off, gated on the session-only `NS.State.debug` flag whose single owner is `NS.DebugLog:SetEnabled(on)` (`/pc debug on|off`, the console header toggle). Console **visibility** is a separate concern (`:Show()` / `:Hide()` / `:Toggle()` / `:IsShown()`, bare `/pc debug` and the General-page checkbox); the window's OnShow/OnHide fire `Schema.NotifyPanelChange("General")` so the checkbox tracks it. `SetEnabled` prints the color-coded ack, writes the `[Debug] logging enabled|disabled` bracket, and on enable appends the one-line `[Init]` session summary (`PrettyChat v<ver>, schema v<n>, profile '<key>'`) — the visible boot summary, since the flag is off at login. Traces are **one gated line per event, never per string**: `[Init]`, `[Migrate]` (`core/Database.lua`, only when a step runs), `[Set] <path> = <value>` (`Schema.Set`, the single settings-change seam — no `[Apply]` re-echo), `[Reset]` (`modules/Override.lua`, with apply counts), `[Cfg]` (the library's panel-open — opened/refused). `ApplyStrings` returns `(applied, restored)` and stays silent so its caller emits the summary.
- **`libs/` is never edited, and a misfit is a finding rather than a patch.** `libs/LibKa0s/` and `tests/_kit/` are vendored whole from the sibling `../LibKa0s` checkout. A local edit is a fork nobody knows about, and the next re-vendor reverts it silently — so a library problem is fixed upstream and re-vendored back. `tests/test_vendor_sync.lua` — a call into the shared, vendored gate `tests/_kit/vendor_sync.lua` — compares both folders against the released tag the root [CLAUDE.md](../CLAUDE.md)'s provenance line says this addon bundles whenever that checkout is present (kit revision 9 moved that line out of the player-facing README, and reads it with no fallback), and [testing.md](./testing.md) carries the four diffs the release path uses.
- **A LibKa0s descriptor is never handed `NS.L`.** The locale table answers *every* key with the key itself (the standard mandates the metatable fallback), so a module handed it would render raw `SCREAMING_SNAKE` keys in place of English — for every key at once, visible only in game. `tests/test_libka0s.lua` greps every seam file for the three spellings and drives the matcher against all of them. Translate by passing a **plain** table of just the keys you translate.
- **User-facing strings go through `NS.L`.** `locales/enUS.lua` exports an English-key metatable (missing keys fall back to the key). Wrap new static UI strings in `L["…"]` and add them to the enUS manifest.

## Settings Schema

`NS.Defaults` is the source data; `settings/Schema.lua` turns it into an ordered `rows` list keyed by dot path. Four row kinds:

- `General.enabled` — addon-wide master toggle (bool). `General` is a **virtual category** with no entry in `NS.Defaults`; stored as `db.profile.enabled` at the profile root.
- `<Category>.enabled` — per-category toggle (bool).
- `<Category>.<GLOBALNAME>.enabled` — per-string toggle (bool).
- `<Category>.<GLOBALNAME>.format` — per-string format string.

Every mutation goes through `NS.Schema.Set(path, value)` — the **single write path** used by both `/pc set` and the panel widgets. Row `set()` closures are pure DB writes; `Schema.Set` runs `PrettyChat:ApplyStrings()` + `Schema.NotifyPanelChange()`. `string_format` rows **auto-clear** on a default match (a value equal to the default deletes the stored override). At load, `Schema.validation` records that every row path resolves to a backing default (loud `NS.Print` warn on any miss). Settings persist in `PrettyChatDB` via AceDB on a single shared Default profile; the `profile` defaults come from `defaults/Profile.lua` (`NS.ProfileDefaults`) and `db.global.schemaVersion` is stamped by `Database.RunMigrations`. Detail: [schema.md](./schema.md).

## Message Bus

**There is none, because this addon publishes no named message.** A whole-repo sweep of `core/ defaults/ modules/ settings/ locales/` returns zero `SendMessage`, zero `RegisterMessage` and zero `AceEvent` — AceEvent-3.0 is deliberately not vendored (the `library-stack-§1` row in `## Documented deviations`), so there is no bus to publish on and no sender/payload/consumer triple to tabulate.

What stands in its place is a **direct, synchronous fan-out inside the single write path**. `Schema.Set` calls `Schema.NotifyPanelChange()`, which drives **both** refresher registries: `LibKa0s-Options-1.0`'s per-page `ctx.refreshers`, and this addon's own `Schema.RegisterRefresher(category, fn)` list — the one the bespoke per-string blocks in `settings/Panel.lua` sign up to, because a hand-built block is invisible to the library's registry. Each refresher runs under `pcall`, so a page whose AceGUI widgets have been released cannot take a `/pc set` down with it. Sender, payload and consumers are a function call and its closure rather than a message name; detail in [schema.md](./schema.md).

**Re-check trigger:** the first `LibStub("AceEvent-3.0")` in this addon. Vendoring AceEvent means there are named messages, and they belong in a table here.

## Slash Commands

`/pc` and `/prettychat` dispatch through one ordered `COMMANDS` table in `settings/Slash.lua` (help text is generated from the same table). Verbs: `help`, `config`, `version`, `list`, `get`, `set`, `reset`, `resetall`, `test`, `debug`. `NS.COMMANDS` is published as positional triples so the landing page renders the same list through `Sl:LandingRows()` — one formatter, two surfaces. Dispatch, help, the schema verbs, the `key = value` pair and the parser are `LibKa0s-Slash-1.0`'s; this addon adds a `format` hook (the `||` doubling) and a `parse` hook (free text containing spaces). `reset` takes a **path**, not a category. Chat input requires `||` for a literal `|`. Detail: [slash-dispatch.md](./slash-dispatch.md).

## Event Subscriptions

**Two, and only while the player has asked for them.** PrettyChat registers no chat filters and hooks no chat frames — the entire mechanism is overriding `_G[GLOBALNAME]` and letting WoW's chat code read it lazily — and the only lifecycle hooks are the AceAddon callbacks `OnInitialize` (DB + migrations + slash registration) and `OnEnable` (snapshot Blizzard originals → arm the combat watcher → `ApplyStrings` → register panels).

| Event | Registered by | When it is registered | What it does |
|---|---|---|---|
| `PLAYER_REGEN_DISABLED` | `PrettyChatCombatWatcher` (`modules/Override.lua`) | only while `General.visibility` is `inCombat` or `outOfCombat` | one `ApplyStrings` pass + one `[Visibility]` summary line |
| `PLAYER_REGEN_ENABLED` | the same frame | the same condition | the same |

The watcher frame is **created lazily on the first combat-scoped write** and its events are dropped again the moment the mode leaves that set (`PrettyChat:SyncCombatWatch`), so a default install — `visibility = "always"` — creates no frame and registers nothing at all. That gating is what keeps the `performance-§12` exemption below intact, and it is pinned by `tests/test_override.lua`. Adding an unconditional event subscription or a chat filter would change the addon's compatibility contract. (What the addon has instead of a bus is under `## Message Bus` above.)

## Taint Notes

- The panel-open guards on `InCombatLockdown()` before `Settings.OpenToCategory` — the protected category-switch taints the panel for the session if called under combat lockdown. The guard lives **inside the library's `OpenOptionsPanel`** rather than in the slash dispatcher, so every caller is gated; `PrettyChat:OpenConfig` is a one-line delegate and there is deliberately no second open path (options-ui-§2).
- The category-tree expansion reaches into private `SettingsPanel` internals (`GetCategoryList`, `GetCategoryEntry`, `SetExpanded`) inside a `pcall`. That code is `LibKa0s-Options-1.0`'s now, and it is silent when the private API moves — see [LIBKA0S-04](https://github.com/tusharsaxena/PrettyChat/issues/9).
- The always-show-scrollbar patch reaches into AceGUI ScrollFrame internals and restores stock behavior on widget release so the shared AceGUI pool isn't polluted for other addons. Also the library's (`OptionsScroll.lua`).
- `SetRenderer` puts a **second** combat guard on the render itself, because the Blizzard AddOns sidebar reaches a panel without going through the panel-open at all — the path a user is most likely to take mid-fight. Before adopting, this addon had no guard there.
- No `SecureHook`, no protected-frame creation, no combat-sensitive writes beyond the guarded panel open.

## Known Limitations

- **Retail only.** `## Interface: 120007` (Midnight / Retail). Classic / Classic Era untested.
- **Snapshot is load-time.** `OnEnable` snapshots Blizzard originals only for strings mentioned in `NS.Defaults` (~81). Adding a new `globalName` needs a `/reload` for the snapshot to capture its pristine value.
- **Cross-registered globals: last-writer-wins.** A global registered under two categories (e.g. `LOOT_ITEM_CREATED_SELF` under Loot + Tradeskill) resolves to the **last** category in `CATEGORY_ORDER` — now deterministic (PC-16), surfaced in the per-string tooltip.
- **Positional format rendering is WoW-only.** `%n$s` specifiers rely on WoW's extended `string.format`; the headless test harness (stock Lua 5.1) can't render them and asserts graceful degradation instead.
- **Single shared profile.** Per-character / per-realm profile scoping is not exposed.

## Documentation map

Every `.md` under `docs/` appears in exactly one table below (`documentation-§3`). Frozen and
generated directories are named once each and never enumerated per run: `docs/audits/`, `docs/reviews/`, `docs/automated-tests/`, `docs/revendor/`, `docs/superpowers/`.

### Required (documentation-§3, Tier 1)

| Doc | Covers |
|---|---|
| `scope.md` | What the addon restyles in chat, and what it leaves to Blizzard |
| `module-map.md` | Every non-vendored file, its responsibility, and load order |
| `schema.md` | The persisted shape, every default, and the migration seam |
| `settings-panel.md` | The panel tree, per-option behavior, and the write seam |
| `data-flow.md` | Message in → override pipeline → what the player reads |
| `common-tasks.md` | Recipes for the changes made most often here |

### Conditional (documentation-§3, Tier 2)

| Doc | Status | Trigger |
|---|---|---|
| `slash-dispatch.md` | Present | 10 verbs in the command table |
| `midnight-quirks.md` | Not applicable | No client-version workaround of the addon’s own; the GlobalStrings work is data, not a shim |
| `message-bus.md` | Not applicable | The addon defines no cross-module messages |
| `compat-layer.md` | Not applicable | There is no `core/Compat.lua`. Its one shim, `Compat.GetAddOnMetadata`, is now `LibKa0s-Env-1.0` behind `core/EnvSetup.lua`, and this addon has no addon-specific client-version shim left to document |
| `profiles.md` | Not applicable | No profile control ships in the options UI |
| `debug.md` | Not applicable | The console is `LibKa0s-DebugLog-1.0`’s, with no debug surface of the addon’s own |
| `perf-analysis/README.md` | Not applicable | No performance harness is wired — see `performance.md` |

### Verification and record

| Doc | Covers |
|---|---|
| `testing.md` | How to run the harness and lint; the green commit gate |
| `smoke-tests.md` | The in-game smoke-test suite |
| `test-cases.md` | The generated case inventory (authoritative pass count) |
| `performance.md` | The addon performance page |
| `automated-tests/README.md` | What the automated-test record is and how to produce it |
| `automated-tests/RESULTS.md` | One row per run; generated, never hand-edited |

### Addon-specific (documentation-§3, Tier 3)

| Doc | Covers |
|---|---|
| `global-strings.md` | The GlobalStrings sub-tree: what is overridden and how it is generated |

## Documented deviations

Every ratified deviation from the Ka0s WoW Addon Standard lives here and **only** here
(`documentation-§3`). A decision may be *reasoned* at length in this repo's GitHub issues
or in an audit bundle, and the row cites that id — but **a deviation not in this table is not
ratified**, and an audit that cannot find a decision here re-files it as an open MUST.

**Re-check trigger** is the condition that ends the deviation, written so a reader can tell whether it
has already fired. A row whose cited rule the standard has since changed — so the behavior is now
mandated or permitted outright — is **retired**, not kept.

| Rule | What differs | Why | Decided | Re-check trigger |
|---|---|---|---|---|
| `performance-§12` | No perf harness is wired: no `core/PerfSetup.lua`, no `PrettyChatPerfDB`, no `perf` verb registration, no suspend/resume contract, no `tests/perf.lua`, no `docs/perf-analysis/` | **Criterion (a) still holds, and it is narrower than it was.** There is no `OnUpdate` handler and no repeating ticker; what the settings revamp added is `PrettyChatCombatWatcher`, which listens to `PLAYER_REGEN_DISABLED` / `PLAYER_REGEN_ENABLED` **only while `General.visibility` is `inCombat` or `outOfCombat`** — the two of four canonical modes a player has to go and choose. A default install registers nothing, and even when armed the handler runs at the combat BOUNDARY (at most twice per fight), never during it, and does one deterministic `ApplyStrings` pass over ~170 table writes with no allocation per string. **Both (b) and (c)** still apply: every declared bucket would read `0.000` by construction, and `suspend` would flip the player's chat formatting back to Blizzard's mid-fight for a capture that can only report zero. Reasoned at length as [`LIBKA0S-12`](https://github.com/tusharsaxena/PrettyChat/issues/10) | 2026-08-05, re-checked 2026-09-02 | **The first `OnUpdate` handler, repeating ticker, or event handler that runs DURING combat rather than at its boundary re-arms the full wiring MUST.** Re-run the sweep in `performance.md`: it now returns the watcher, and the question to ask of any new hit is whether it fires while the player is fighting |
| `layout-§2` | `GlobalStrings/` is a **PascalCase, root-level** folder outside the mandated `core/ defaults/ settings/ locales/ modules/` skeleton (`layout-§1`), holding 26 machine-generated chunks (~22,879 Blizzard reference strings) plus the 23,842-line source dump `GlobalStrings/GlobalStrings.lua`, which is over `layout-§1`'s 1500-LOC cap | The modular layout has no home for bulk generated reference data. **Nothing ships and nothing loads:** since PC-R-05 the whole folder is `.pkgmeta`-ignored and `PrettyChat.toc` carries no chunk line, so it is repo-only reference data that `tests/test_defaults.lua` reads to check every override against Blizzard's real signature. Chunks stay cut by entry count, not by first letter, and each is under 1000 lines so the generated data stays out of `layout-§1`'s on-notice band (PC-49). Regenerate with `python3 GlobalStrings/split_globalstrings.py`, which now REFUSES to run if the TOC has started loading the chunks again | 2026-08-05 | A `layout` revision that sanctions a generated-data folder, **or** the folder moving under `tests/` now that it is a fixture rather than shipped data. The `toc-file-§5` half of this pair is already closed |
| `toc-file-§5` | `# Locales` sits immediately after `# Libraries` rather than after `# Defaults` | The non-canonical `# GlobalStrings` section this row also covered is **gone** — PC-R-05 removed it, and the splitter now fails if it returns. The Locales placement is a **standard-internal conflict**: `toc-file-§5` orders Locales before Defaults, `layout-§1`'s load order puts Defaults first, and the two disagree (the same pair disagree on `settings/*` vs `modules/*`). Resolved toward `toc-file-§5` in both places; `locales/enUS.lua` only builds `NS.L` and has no earlier-load dependency, so loading it first is safe. Raised upstream as [WowAddonStandards#2](https://github.com/tusharsaxena/WowAddonStandards/issues/2) | 2026-07-18 | WowAddonStandards#2 resolving. If it resolves in favor of `layout-§1`, both orderings here are revisited |
| `toc-file-§1` | `## Title:` keeps its rainbow `\|cRRGGBB…\|r` escapes, `## Author:` keeps its stylized `aDd1kTeD2Ka0s` casing, and `## X-Wago-ID` is absent | The color escapes and the casing are the addon's brand mark, kept deliberately rather than normalized to `Ka0s Pretty Chat` / `add1kted2ka0s`. `toc-file-§1` asks for both distribution ids once an addon is published anywhere; PrettyChat is on CurseForge only (`## X-Curse-Project-ID: 919766`), so there is no Wago listing to reference. Do not add the field and do not commit a placeholder | 2026-07-12 | The addon being listed on Wago (which re-arms `X-Wago-ID` immediately), or a decision to retire the brand mark |
| `debug-logging-§2` | The debug console's monospace font (JetBrains Mono, OFL) reaches the library as the console descriptor's `font` path via `Const.FONT_MONO`, and **no LibSharedMedia registration happens in this install** | The reason changed with the adoption of `LibKa0s-Media-1.0`. Registration is no longer omitted by choice: `core/MediaSetup.lua` calls `Media.RegisterLSM(addonName)` at load like every other addon in the collection, and that call returns `0, 0` because PrettyChat does not vendor LibSharedMedia-3.0 and has no font-picker consumer to justify vendoring it. The console stays fixed-monospace on purpose — readability of aligned log output does not depend on player taste. Not to be "fixed" by hand-rolling a registration | 2026-08-24 | The first user-facing media picker in this addon, which would give LSM a consumer and pull the library in |
| `options-ui-§6` | A category tab is a bespoke 33/67 split (`LIST_W` / `PANE_W` in `settings/Panel.lua`) instead of the schema-driven 50/50 two-column grid | The pane holds full color-escaped format strings — the Blizzard original, the user's replacement and the live preview — at FULL width, which is the width the deviation exists to buy; a 50/50 grid clips them, and `LibKa0s-Options-1.0`'s caller-driven `RenderGrid` offers `HALF` (0.5) or full width and no third ratio, so it cannot express 33/67 either (`LIBKA0S-06`). Justified in-code above `buildCategoryBody`. **Re-shaped 2026-09-03**: it was a 40/60 THREE-ROW editor (`LEFT_W` / `RIGHT_W`), with the string chosen from a secondary strip above it. The strip became the left column (see the `§13` row below) and the editor's three fields became full width inside the right one, so the split moved from inside the editor to the page — the ratio is still not one the flow engine has | 2026-07-31, re-shaped 2026-09-03 | `RenderGrid` gaining a third width ratio (`LIBKA0S-06`), or the pane no longer needing to show three format strings at full width |
| `options-ui-§13` | Inside a category tab, the format strings are chosen from a **vertical list** in the left column rather than from a secondary tab strip | `§13` permits a secondary strip inside one primary tab, and this page had one. A strip is packed **horizontally** and wraps: Experience registers twenty strings with names like *XP Gain (Exhausted, Group)*, which came out as **five rows of buttons** above the editor they select — chrome taller than its content, and a paragraph of buttons to scan for one name. The same twenty read down a column at a glance. What `§13` is protecting is intact: the division is ordinary content **inside the scroll** rather than a second pinned band, there is no third level, and the selection is session-only (`ctx.activeSubTab`, keyed per category). Justified in-code above `buildCategoryBody` | 2026-09-03 | An `options-ui` revision that names a vertical form for a secondary division — at which point this is permitted outright and the row retires — or the longest category shrinking to a strip that does not wrap |
| `testing-§1` | `tests/wow_mock.lua` is the thin extender over `tests/_kit/mock_base.lua` the rule asks for, but **`tests/loader.lua` survives** beside `tests/_kit/loader.lua` | The kit builds one shared environment whose `__newindex` writes through to the real `_G`. This addon's entire feature is rewriting `_G[GLOBALNAME]` and half the suite asserts on what landed there, so a shared environment would let one suite's overrides answer another suite's reads. `tests/loader.lua` is reduced to exactly that isolation need — a fresh mock per instance, `_G` pointed back at it, chunks compiled once — and takes everything else from the kit (`Loader.makeEnv`, `Loader.tocFiles`, `Loader.xmlFiles`). Reported upstream as `LIBKA0S-01` | 2026-08-02 | `tests/_kit/loader.lua` gaining an isolated-environment mode (`LIBKA0S-01`), after which `tests/loader.lua` is deleted outright |
| `localization-§1` | **PrettyChat ships English only.** `locales/` holds `enUS.lua` and nothing else, and the category names interpolated into three routed strings (`Enable %s`, `Enable or disable all %s string overrides.`, `Shared with %s …`) are English identifiers that no locale file can translate | The routing SHOULD is **satisfied**, not declined: every user-facing string goes through `NS.L`, and `tests/test_locale.lua` scans the TOC-derived sources in both directions so an unwrapped string or a dead manifest key is red. What is recorded here is the shipping decision — no second locale file — and the one residue routing cannot reach. There were **four** such strings until the eight category pages became one tabbed page: `Reset all %s strings to defaults.` lost its caller, because one Defaults button over eight tabs cannot carry a wording fixed at panel-build time. The residue shrank; the deviation did not change. A category name is a **schema path segment** (`Loot.enabled`, `/pc set Loot.enabled false`), so translating the display name would either desynchronize it from the path a user types or need a second display-name table that only a translator can populate; neither is worth building before a translator exists. `localization-§3` makes this a terminal compliant state once it is a row here, and an audit **MUST NOT** re-file the routing SHOULD against it | 2026-08-05 | **The first non-English locale file added to `locales/`.** That fires both halves: the new file gets the four `%s` sentences, and the category display-name question becomes real and needs the second table |
| `options-ui-§15` | The `Master controls` tab's closing button pair reads **`[Test] [Reset all settings]`** rather than the canonical `Reset all settings` alone that §15 gives a frameless addon | §15 fixes the block's ROWS and closes it with the reset pair; it does not give an addon anywhere else to put a page-wide ACT. `Test` is a preview verb no other Ka0s addon has — it renders every format string with sample arguments — and it belongs to the addon as a whole rather than to any category, so the General page is the only page it can live on. **The host no longer draws it.** It was a button on a row of its own above the reset, drawn here; since LibKa0s **v1.25.0** (`OptionsCompose` minor 2) it is the composer's `leadButton`, declared in `MASTER_SPEC` and drawn by the composer into the pair's empty right half — the one cell §15 leaves a frameless addon, which has no *Reset position*. That matters because §15 also fixes the reset's WORDING: drawing the pair host-side would have put a second copy of *"Reset all settings"* in this addon, which is the drift the composer exists to end. The composed rows and their order are untouched and the canonical button still closes the tab | 2026-09-02, moved into the library 2026-09-03 | An `options-ui` revision that names a place for host-owned page-wide acts, or `Test` moving off the panel entirely |
| `library-stack-§1` | `AceEvent-3.0` and `AceTimer-3.0` are **not** vendored, although `library-stack-§1`'s mandatory-libs table lists both as vendored | The rule contradicts itself: `library-stack.md:13-14` lists AceEvent and AceTimer among the libs every Ace3 addon vendors, while `library-stack.md:39` MUSTs vendoring **only** libs the addon actually `LibStub("X")`. This addon `LibStub`s neither — it starts no timers, and the two combat-boundary events the General visibility watcher needs go on a plain `CreateFrame("Frame")` (`modules/Override.lua`), which is two lines and no dependency. So the two halves cannot both be satisfied, and `:39` (vendor what you use, nothing more) wins. Recorded as PC-52 in `docs/audits/2026-08-04/02_DEVIATIONS.md`; no upstream item resolves it | 2026-08-04 | The next `library-stack` edit — the contradiction is upstream, and this row ends when the standard picks one half |

## External dependencies

Vendored under `libs/` (the BigWigs packager pulls nothing — no `externals`): LibStub, CallbackHandler-1.0, AceAddon-3.0, AceDB-3.0, AceConsole-3.0, AceGUI-3.0, and **[LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.25.0** (`libs/LibKa0s/`, listed in the TOC as `libs\LibKa0s\LibKa0s.xml` after Ace3). (`AceConfig-3.0` was removed — no live consumer.)

Six of LibKa0s's ten majors are adopted: **Core**, **Env**, **Media**, **DebugLog**, **Slash** and **Options**. **Perf is declined** under a recorded `performance-§12` no-combat-path exemption — the register row above, with its sweep in [performance.md](./performance.md) and its reasoning at [LIBKA0S-12](https://github.com/tusharsaxena/PrettyChat/issues/10). **Item**, **Pool** and **Widgets** are not consumed here at all — nothing in this addon, and no other vendored LibKa0s file, `LibStub`s any of the three. `Item.lua`, `Pool.lua`, `Widgets.lua`, `Perf.lua` and `PerfPanel.lua` are still vendored, because the folder is copied whole and never file by file.

The shared test kit is vendored separately to `tests/_kit/` — **never** to `libs/`, which is the ship payload.

## Testing

Headless harness under `tests/` (stock Lua 5.1, no client): `lua tests/run.lua` + `luacheck .`. Suites register named `test(name, fn)` cases; `lua tests/run.lua --list` prints the generated case inventory ([test-cases.md](./test-cases.md), testing-§5) — the authoritative pass count, mirrored by the README `tests` badge. Manual in-game validation: [smoke-tests.md](./smoke-tests.md). Full verification guide and the commit gate: [testing.md](./testing.md).

## Working environment

- **Dual-path WSL.** `/home/tushar/GIT/PrettyChat/` and `/mnt/d/Profile/Users/Tushar/Documents/GIT/PrettyChat/` are the same repo via symlink.
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
| Per-file responsibility map, module roles + public APIs | [module-map.md](./module-map.md) |
| Snapshot → ApplyStrings → restore + 3-layer enable order | [data-flow.md](./data-flow.md) |
| Schema row kinds + single write path + auto-clear + AceDB shape | [schema.md](./schema.md) |
| Canvas-layout panel framework | [settings-panel.md](./settings-panel.md) |
| `COMMANDS` table + full command reference | [slash-dispatch.md](./slash-dispatch.md) |
| Dual-load story + splitter script | [global-strings.md](./global-strings.md) |
| Recipes (add string/category, fix a format) | [common-tasks.md](./common-tasks.md) |
| Quick recipe + full smoke-test suite | [smoke-tests.md](./smoke-tests.md) |
