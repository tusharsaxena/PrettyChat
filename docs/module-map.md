# Module map

Per-module roles + public APIs. Pair this with [override-pipeline.md](./override-pipeline.md) for how the modules talk to each other at runtime.

## Subsystem diagram

```
defaults/Defaults.lua  ──▶ NS.Defaults (categories + format strings)
                    │
                    ├──▶ settings/Schema.lua ──▶ NS.Schema  (rows[], byPath[], single write path)
                    │                       │
                    │                       ├──▶ /pc set / get / list / reset   (settings/Slash.lua)
                    │                       └──▶ Panel widget get/set           (settings/Panel.lua)
                    │
                    └──▶ modules/Override.lua ApplyStrings()
                                │
                                ▼
                          _G[GLOBALNAME]   ◀── WoW chat code reads lazily on every line

GlobalStrings/  ──▶ NS.GlobalStrings (Blizzard reference, ~22,879 entries)
                       │
                       └──▶ settings/Panel.lua "Original Format String" disabled input
```

## Namespace publishing pattern

Every file captures the addon namespace with the same idiom at the top:

```lua
local addonName, NS = ...
```

Public surfaces are exposed on `NS`:

| Member | Set by | Used by |
|--------|--------|---------|
| `NS.Compat` | `core/Compat.lua` | `core/Namespace.lua`, `settings/Slash.lua`, `settings/Panel.lua` (`Compat.GetAddOnMetadata` — C_AddOns vs legacy global) |
| `NS.Const` / `NS.PREFIX` | `core/Constants.lua` | `settings/Panel.lua` (padding / header height / spacers / `Color` palette / `BUTTON_PAIR_REL`); `settings/Slash.lua` (slash-output `Color` codes); `core/Util.lua` (colour-wrap helpers); `core/DebugLogSetup.lua` (`FONT_MONO`); `core/PrettyChat.lua` (`Color` palette; `NS.PREFIX` = shared cyan `[PC]` tag read by `NS.Print`) |
| `NS.name` / `NS.version` | `core/Namespace.lua` | identity bootstrap (records addon name + TOC version so no module re-queries the TOC) |
| `NS.State` | `core/State.lua` | `core/DebugLogSetup.lua`, `settings/Slash.lua` (session-only `debug` flag; `{ debug = false }`, reset every reload/login) |
| `NS.Util` | `core/Util.lua` | `settings/Slash.lua`, `core/DebugLogSetup.lua`, `core/PrettyChat.lua` (`trim` / `note` / `cmd` string helpers; secret-safe `SafeToString` / `IsConcatSafe`) |
| `NS.Database` | `core/Database.lua` | `core/PrettyChat.lua` (`OnInitialize` merges `global.schemaVersion` defaults + runs `RunMigrations`) |
| `NS.DebugLog` / `NS.Debug(tag, fmt, …)` | `core/DebugLogSetup.lua` | every file (on-screen debug console; `NS.Debug` gated on session-only `NS.State.debug`, routed to the console, driven by `/pc debug` through the `DebugLog:SetEnabled` seam) |
| `NS.Print(msg)` | `core/PrettyChat.lua` | every file (cyan `[PC]` chat-output chokepoint) |
| `NS.ProfileDefaults` | `defaults/Profile.lua` | `core/PrettyChat.lua` (`OnInitialize` merges it with `NS.Database.defaults` for `AceDB:New`) |
| `NS.Defaults` | `defaults/Defaults.lua` | `settings/Schema.lua`, `modules/Override.lua`, `settings/Slash.lua`, `settings/Panel.lua` (category → format-string defaults) |
| `NS.L` | `locales/enUS.lua` | `settings/Panel.lua`, `settings/Slash.lua` (English-key localization; `__index` returns the key) |
| `NS.GlobalStrings` | `GlobalStrings/` chunks | `settings/Panel.lua` ("Original Format String" display) |
| `NS.Schema` | `settings/Schema.lua` | `settings/Slash.lua` (slash dispatch), `settings/Panel.lua` (every widget get/set; registers a per-sub-page refresh closure via `Schema.RegisterRefresher` on first `OnShow`) |
| `NS.RenderSample(fmt)` | `modules/Override.lua` | `settings/Panel.lua` (per-string Preview EditBox) |
| `NS.COMMANDS` | `settings/Slash.lua` | `settings/Panel.lua` (parent page's slash-command list — keeps panel and `/pc help` in lockstep with one source) |
| `NS.Config.RegisterPanels()` | `settings/Panel.lua` | `core/PrettyChat.lua` (`OnEnable` calls it after the snapshot/`ApplyStrings` pair, replacing the old `PLAYER_LOGIN` bootstrap frame) |

The addon object **is** the `NS` table itself — `core/PrettyChat.lua` passes `NS` to `:NewAddon` (architecture-§2), so its `AceAddon-3.0` methods hang off `NS`. Other files reach it via `LibStub("AceAddon-3.0"):GetAddon("PrettyChat")`, which returns that same table.

## Public APIs

### `PrettyChat` (the AceAddon object — methods split across three files)

The object is registered in `core/PrettyChat.lua`; its methods hang off that shared object from several files — lifecycle + printer + panel-open in `core/PrettyChat.lua`, the override engine in `modules/Override.lua`, and the slash dispatch in `settings/Slash.lua`.

```lua
-- Lifecycle (core/PrettyChat.lua)
PrettyChat:OnInitialize()              -- AceDB, slash registration ("/pc" + "/prettychat")
PrettyChat:OnEnable()                  -- snapshot Blizzard originals → ApplyStrings → RegisterPanels
PrettyChat:OpenConfig()                -- Settings.OpenToCategory(self.optionsCategoryID); then expandMainCategory(self.optionsCategory) walks SettingsPanel:GetCategoryList():GetCategoryEntry(cat):SetExpanded(true) in pcall to unfold the sub-tree

-- Override pipeline (modules/Override.lua — also see override-pipeline.md)
PrettyChat:ApplyStrings()              -- writes enabled overrides to _G; restores originals for disabled ones
PrettyChat:ResetString(category, globalName)  -- clears BOTH per-string dimensions (custom format + disable flag) + ApplyStrings + NotifyPanelChange
PrettyChat:ResetCategory(category)     -- clears one category's overrides + ApplyStrings + NotifyPanelChange
PrettyChat:ResetAll()                  -- clears every category + the addon-wide flag + ApplyStrings + NotifyPanelChange
PrettyChat:Test(filter?)               -- prints a per-category Original-vs-Formatted block per string (ignores enable toggles); filter is nil | {kind="category", value=…} | {kind="formatstring", value=…}

-- Read helpers (used by Schema closures, ApplyStrings, panel widgets)
PrettyChat:GetStringValue(category, globalName)   -- user override falling back to NS.Defaults
PrettyChat:IsAddonEnabled()                       -- nil → default true
PrettyChat:IsCategoryEnabled(category)            -- nil → default true (from NS.Defaults)
PrettyChat:IsStringEnabled(category, globalName)  -- false iff disabledStrings[NAME] == true
PrettyChat:EnsureCategoryDB(category)             -- creates db.profile.categories[Cat] if missing, returns it

-- Slash dispatch (settings/Slash.lua)
PrettyChat:OnSlashCommand(input)       -- parses verb + rest, dispatches via the COMMANDS table
```

### `NS.Schema` (`settings/Schema.lua`)

See [schema.md](./schema.md) for the row kinds, the single write path, and the auto-clear-on-default behavior.

```lua
NS.Schema.RowsByCategory(category)             -- filtered subset for one category
NS.Schema.FindByPath(path)                     -- O(1) lookup by dot path
NS.Schema.Get(path)                            -- read through the row's get() closure
NS.Schema.Set(path, value)                     -- DB write (row's set closure) → ApplyStrings → NotifyPanelChange
NS.Schema.FormatValue(row, value)              -- type-aware display string (bool → true/false; string → format with `|` doubled to `||`); shared by /pc list rows and the get/set echo
NS.Schema.ResolveCategory(name)                -- case-insensitive "loot" → "Loot"; falls back to unambiguous prefix
NS.Schema.NotifyPanelChange(category?)         -- invokes the closure registered for `category`; nil or "General" runs every closure
                                               -- (per-string disabled state depends on master, so master changes cascade)
NS.Schema.RegisterRefresher(category, fn)      -- settings/Panel.lua registers a per-sub-page refresh closure on first OnShow
NS.Schema.crossRegisteredGlobals               -- map of globalName → {Cat1, Cat2, …} for globals registered under >1 category
NS.Schema.CATEGORY_ORDER                       -- canonical display order (also drives /pc list, panel left-rail)
```

### `NS.Print` (`core/PrettyChat.lua`)

```lua
NS.Print(msg)   -- DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. NS.Util.SafeToString(msg))   PREFIX built from NS.Const.Color.cyan
```

The single chokepoint for addon chat output. Use this, not raw `print()` or `self:Print()`, so the prefix and color stay uniform across files.

`Test()` prints through `NS.Print` like everything else, so every line — headers, footers, and each Original/Formatted preview line — carries the `[PC]` prefix (events-frames-taint-§8: no direct `DEFAULT_CHAT_FRAME:AddMessage` writes).

## Load order

`PrettyChat.toc` is the source of truth. Order is dependency, not alphabetical:

1. Ace3 libraries — LibStub, CallbackHandler-1.0, AceAddon-3.0, AceDB-3.0, AceConsole-3.0, AceGUI-3.0. (`AceConfig-3.0` was removed from `libs/` — no live consumer; re-vendor it if a future feature needs it.)
2. `locales/enUS.lua` — populates `NS.L` (English-key metatable + enUS manifest). Loads first among addon files (toc-file-§5 section order); it only builds `NS.L` and has no earlier-load dependency.
3. `core/Compat.lua` — populates `NS.Compat` (metadata shim). Side-effect-free; the first `core/` file, so any later file can call it.
4. `core/Constants.lua` — populates `NS.Const` + `NS.PREFIX` with panel layout constants, the `Color` palette (incl. the slash-output `azure` / `listHead` codes and `FONT_MONO`), and the cyan tag. Side-effect-free.
5. `core/Namespace.lua` — populates `NS.name` / `NS.version` from the TOC (reads `NS.Compat`, so it loads after it).
6. `core/State.lua` — populates `NS.State` (`{ debug = false }`, session-only).
7. `core/Util.lua` — populates `NS.Util` (`trim` / `note` / `cmd` + secret-safe `SafeToString` / `IsConcatSafe`; reads `NS.Const.Color`, so it loads after Constants).
8. `core/Database.lua` — populates `NS.Database` (`SCHEMA_VERSION`, `global` defaults, `RunMigrations`).
9. `core/DebugLogSetup.lua` — populates `NS.DebugLog` (the on-screen console) + `NS.Debug` (gated sink). Reads `NS.State` / `NS.Util` / `NS.Const.FONT_MONO`.
10. `core/PrettyChat.lua` — creates the AceAddon object **from the `NS` table** (`:NewAddon(NS, …)`, architecture-§2), reclaims the secret-safe `NS.Print` after AceConsole's `:Print` embed, merges `NS.ProfileDefaults` + `NS.Database.defaults` + runs migrations in `OnInitialize`, registers slash commands, owns `OpenConfig`. **Every later file reaches the addon object via** `LibStub("AceAddon-3.0"):GetAddon("PrettyChat")` (which returns `NS`).
11. `defaults/Profile.lua` — populates `NS.ProfileDefaults` (the AceDB `profile` defaults table).
12. `defaults/Defaults.lua` — populates `NS.Defaults`.
13. `GlobalStrings/GlobalStrings_001.lua` … `_010.lua` — populates `NS.GlobalStrings` eagerly so the panel can resolve "Original" values without an explicit load step.
14. `modules/Override.lua` — attaches the override engine to the addon object (`ApplyStrings`, enable-cascade predicates, `ResetCategory` / `ResetAll`, `Test`) and defines `NS.RenderSample`.
15. `settings/Schema.lua` — builds `rows` / `byPath` from `NS.Defaults` (which is loaded earlier) and runs the load-time path validator. Closures bind to live values.
16. `settings/Slash.lua` — defines the `/pc` dispatcher (`NS.COMMANDS`, `OnSlashCommand`, and the per-verb handlers). Loads after Schema so its `list` / `get` / `set` handlers can reach `NS.Schema`.
17. `settings/Panel.lua` — exposes `NS.Config.RegisterPanels`. Called from `PrettyChat:OnEnable`, it registers the parent canvas-layout category + one sub-page per category. Defers AceGUI body rendering until each panel's first `OnShow`; that `OnShow` calls `NS.Schema.RegisterRefresher(category, refreshFn)` so `Schema.NotifyPanelChange` can re-sync the page after a write.

If you add a new file, put it in the right place in `PrettyChat.toc`.
