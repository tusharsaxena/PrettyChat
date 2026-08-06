# Module map

Per-module roles + public APIs. Pair this with [data-flow.md](./data-flow.md) for how the modules talk to each other at runtime.

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

GlobalStrings/  ──▶ NOT LOADED (PC-R-05) — repo-only reference data for tests/test_defaults.lua
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
| `NS.Const` / `NS.PREFIX` | `core/Constants.lua` | `settings/Panel.lua` (`Color` palette, `STRING_VSPACER`, the landing page's own section spacers); `settings/Slash.lua` (slash-output `Color` codes); `core/Util.lua` (color-wrap helpers); `core/DebugLogSetup.lua` (`FONT_MONO`); `modules/Override.lua` (`Color` palette for the `Test` report); `core/CoreSetup.lua` (`NS.PREFIX` = the shared cyan `[PC]` tag, passed to the printer as a function so a later change is not frozen out) |
| `NS.name` / `NS.version` | `core/Namespace.lua` | identity bootstrap (records addon name + TOC version so no module re-queries the TOC) |
| `NS.State` | `core/State.lua` | `core/DebugLogSetup.lua`, `settings/Slash.lua` (session-only `debug` flag; `{ debug = false }`, reset every reload/login) |
| `NS.Util` | `core/Util.lua` (`trim` / `note` / `cmd`) + `core/CoreSetup.lua` (`SafeToString` / `IsConcatSafe`) | `settings/Slash.lua`, `modules/Override.lua`, `core/DebugLogSetup.lua` (`trim` / `note` / `cmd` string helpers; secret-safe `SafeToString` / `IsConcatSafe`) |
| `NS.Database` | `core/Database.lua` | `core/PrettyChat.lua` (`OnInitialize` merges `global.schemaVersion` defaults + runs `RunMigrations`) |
| `NS.DebugLog` / `NS.Debug(tag, fmt, …)` | `core/DebugLogSetup.lua` | every file (on-screen debug console; `NS.Debug` gated on session-only `NS.State.debug`, routed to the console, driven by `/pc debug` through the `DebugLog:SetEnabled` seam) |
| `NS.Print(msg)` / `NS.Format(fmt, …)` | `core/CoreSetup.lua` | every file (secret-safe cyan `[PC]` chat-output chokepoint, built by `LibKa0s-Core-1.0` and reclaimed from AceConsole's embed) |
| `NS.ProfileDefaults` | `defaults/Profile.lua` | `core/PrettyChat.lua` (`OnInitialize` merges it with `NS.Database.defaults` for `AceDB:New`) |
| `NS.Defaults` | `defaults/Defaults.lua` | `settings/Schema.lua`, `modules/Override.lua`, `settings/Slash.lua`, `settings/Panel.lua` (category → format-string defaults) |
| `NS.L` | `locales/enUS.lua` | `settings/Panel.lua`, `settings/Slash.lua`, `settings/Schema.lua` (English-key localization; `__index` returns the key) |
| `NS.OriginalFormat(addon, name)` | `modules/Override.lua` | `settings/Panel.lua` ("Original Format String" display) and `/pc test`'s Original line — one reader for both |
| `NS.Schema` | `settings/Schema.lua` | `settings/Slash.lua` (slash dispatch), `settings/Panel.lua` (every widget get/set; registers a per-sub-page refresh closure via `Schema.RegisterRefresher` on first `OnShow`) |
| `NS.RenderSample(fmt)` | `modules/Override.lua` | `settings/Panel.lua` (per-string Preview EditBox) |
| `NS.COMMANDS` / `NS.SlashCommands` | `settings/Slash.lua` | `settings/Panel.lua` renders `NS.SlashCommands:LandingRows()` on the landing page — the SAME formatter the chat help uses, so the two surfaces cannot drift (`LIBKA0S-11`). The call is a **colon**: the library declares `function Sl:LandingRows()`, and the dot form only worked because today's body ignores `self` (PC-R-08) |
| `NS.LIBKA0S_MISSING` | `core/CoreSetup.lua` | `core/DebugLogSetup.lua`, `settings/OptionsSetup.lua`, `settings/Slash.lua` — the shared cause clause each degraded seam appends its own consequence to |
| `NS.Helpers` | `settings/OptionsSetup.lua` | `settings/Panel.lua` (the `LibKa0s-Options-1.0` instance itself, decorated in place), `settings/Schema.lua` (`RefreshScalars`), `core/PrettyChat.lua` (`OpenOptionsPanel`) |
| `NS.Config.RegisterPanels()` | `settings/Panel.lua` | `core/PrettyChat.lua` (`OnEnable` calls it after the snapshot/`ApplyStrings` pair, replacing the old `PLAYER_LOGIN` bootstrap frame) |

The addon object **is** the `NS` table itself — `core/PrettyChat.lua` passes `NS` to `:NewAddon` (architecture-§2), so its `AceAddon-3.0` methods hang off `NS`. Other files reach it via `LibStub("AceAddon-3.0"):GetAddon("PrettyChat")`, which returns that same table.

## Public APIs

### `PrettyChat` (the AceAddon object — methods split across three files)

The object is registered in `core/PrettyChat.lua`; its methods hang off that shared object from several files — lifecycle + printer + panel-open in `core/PrettyChat.lua`, the override engine in `modules/Override.lua`, and the slash dispatch in `settings/Slash.lua`.

```lua
-- Lifecycle (core/PrettyChat.lua)
PrettyChat:OnInitialize()              -- AceDB, slash registration ("/pc" + "/prettychat")
PrettyChat:OnEnable()                  -- snapshot Blizzard originals → ApplyStrings → RegisterPanels
PrettyChat:OpenConfig()                -- a one-line delegate to NS.Helpers.OpenOptionsPanel(); the library owns the combat gate, the OpenToCategory call and the pcall'd left-tree expansion

-- Override pipeline (modules/Override.lua — also see data-flow.md)
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

### `NS.Print` / `NS.Format` (`core/CoreSetup.lua`)

```lua
NS.Print(...)          -- LibKa0s-Core-1.0's printer: NS.PREFIX, sep = "", space-joined secret-safe args
NS.Format(fmt, ...)    -- the same line, through string.format over pre-stringified args
```

The single chokepoint for addon chat output. Use this, not raw `print()` or `self:Print()`, so the prefix and color stay uniform across files.

`Test()` prints through `NS.Print` like everything else, so every line — headers, footers, and each Original/Formatted preview line — carries the `[PC]` prefix (events-frames-taint-§8: no direct `DEFAULT_CHAT_FRAME:AddMessage` writes).

## Load order

`PrettyChat.toc` is the source of truth. Order is dependency, not alphabetical:

1. Libraries — LibStub, CallbackHandler-1.0, AceAddon-3.0, AceDB-3.0, AceConsole-3.0, AceGUI-3.0, then **`libs\LibKa0s\LibKa0s.xml`** (after Ace3, library-stack-§7), which pulls in Core → DebugLog → Slash → Options → OptionsWidgets → OptionsScroll → Perf → PerfPanel. (`AceConfig-3.0` was removed from `libs/` — no live consumer; re-vendor it if a future feature needs it.)
2. `locales/enUS.lua` — populates `NS.L` (English-key metatable + enUS manifest). Loads first among addon files (toc-file-§5 section order); it only builds `NS.L` and has no earlier-load dependency.
3. `core/Compat.lua` — populates `NS.Compat` (metadata shim). Side-effect-free; the first `core/` file, so any later file can call it.
4. `core/Constants.lua` — populates `NS.Const` + `NS.PREFIX` with the `Color` palette (incl. the slash-output `azure` / `listHead` codes), the landing page's own section spacers, `STRING_VSPACER` and `FONT_MONO`, and the cyan tag. Carries **no** panel layout constants — those are the Options module's `LAYOUT` table (options-ui-§8). Side-effect-free.
5. `core/Namespace.lua` — populates `NS.name` / `NS.version` from the TOC (reads `NS.Compat`, so it loads after it).
6. `core/State.lua` — populates `NS.State` (`{ debug = false }`, session-only).
7. `core/Util.lua` — populates `NS.Util` with `trim` / `note` / `cmd` (reads `NS.Const.Color`, so it loads after Constants). The secret-safe pair arrives on the same table from `core/CoreSetup.lua` below.
8. `core/Database.lua` — populates `NS.Database` (`SCHEMA_VERSION`, `global` defaults, `RunMigrations`).
9. `core/PrettyChat.lua` — creates the AceAddon object **from the `NS` table** (`:NewAddon(NS, …)`, architecture-§2), merges `NS.ProfileDefaults` + `NS.Database.defaults` + runs migrations in `OnInitialize`, registers slash commands, and delegates `OpenConfig` to the library's combat-gated panel-open. **Every later file reaches the addon object via** `LibStub("AceAddon-3.0"):GetAddon("PrettyChat")` (which returns `NS`).
10. `core/CoreSetup.lua` — the `LibKa0s-Core-1.0` seam. Populates `NS.LIBKA0S_MISSING`, `NS.Print` / `NS.Format` and `NS.Util.SafeToString` / `IsConcatSafe`. **This position is load-bearing at both ends**: it must follow `core/PrettyChat.lua`, because AceConsole's `:Print` embed lands on `NS` during `:NewAddon` and this file's last two lines reclaim the name (anti-pattern #36); and it must precede `settings/Schema.lua`, the only load-time `NS.Print` caller.
11. `core/DebugLogSetup.lua` — the `LibKa0s-DebugLog-1.0` seam. Populates `NS.DebugLog` (the library's console instance) + `NS.Debug` (its gated sink, bound bare). Reads `NS.State` / `NS.Util` / `NS.Const.FONT_MONO` / `NS.Print`, so it follows all four (debug-logging-§1).
12. `defaults/Profile.lua` — populates `NS.ProfileDefaults` (the AceDB `profile` defaults table).
13. `defaults/Defaults.lua` — populates `NS.Defaults`.
14. `GlobalStrings/` — **not in the load order at all** since PC-R-05. The panel resolves "Original" values from the `OnEnable` snapshot through `NS.OriginalFormat`; the chunks are repo-only reference data that `tests/test_defaults.lua` loads directly.
15. `modules/Override.lua` — attaches the override engine to the addon object (`ApplyStrings`, enable-cascade predicates, `ResetCategory` / `ResetAll`, `Test`) and defines `NS.RenderSample`.
16. `settings/Schema.lua` — builds `rows` / `byPath` from `NS.Defaults` (which is loaded earlier) and runs the load-time path validator. Closures bind to live values.
17. `settings/OptionsSetup.lua` — the `LibKa0s-Options-1.0` seam. Populates `NS.Helpers` (the instance itself). After `settings/Schema.lua`, whose `Get`/`Set`/`RowsByCategory` the descriptor reads, and before `settings/Panel.lua`, which takes it as a file-scope upvalue and registers its pages at file load (options-ui-§1).
18. `settings/Slash.lua` — the `COMMANDS` table and the `LibKa0s-Slash-1.0` descriptor, publishing `NS.COMMANDS` and `NS.SlashCommands`. After Schema so the descriptor's `get`/`set`/`findRow`/`allRows` can reach it.
19. `settings/Panel.lua` — the three page bodies. Registers each page with `NS.Helpers.RegisterOptionsPage` at file load and declares it with `SetRenderer`, which owns the first-`OnShow` deferral, the every-`OnShow` Defaults button and the combat refusal. Exposes `NS.Config.RegisterPanels` (the library's `CreateOptionsPanel`, called from `PrettyChat:OnEnable`) and `NS.Config.BuildMain`. Its bespoke per-string blocks register through `NS.Schema.RegisterRefresher`; every library-made widget registers on its page's own ctx. After `settings/Slash.lua`, because the landing page renders `NS.SlashCommands:LandingRows()`.

If you add a new file, put it in the right place in `PrettyChat.toc`.

## File index

Every non-vendored file, by directory. Folded in from the retired `module-map.md` (standard v2.23.0), which duplicated this map at a different granularity.

Where each responsibility lives in the source tree. Match this map to the actual files before editing — `PrettyChat.toc` is the source of truth for load order.

### Source tree (modular)

Source `.lua` is grouped under `core/`, `defaults/`, `locales/`, `modules/`, and `settings/`.

### `core/`

| File | Responsibility |
|------|----------------|
| `core/Compat.lua` | `NS.Compat` — version-shim seam. `Compat.GetAddOnMetadata` (C_AddOns vs legacy global). Loads first among addon files. |
| `core/Constants.lua` | The `Color` palette (incl. the slash-output `azure` / `listHead` codes), `NS.Const.FONT_MONO` (vendored JetBrains Mono path for the debug console), and `NS.PREFIX` (shared cyan `[PC]` tag). Side-effect-free; loads early so later files can read `NS.Const.*` without an existence check. |
| `core/Namespace.lua` | Identity bootstrap — publishes `NS.name` and `NS.version` (read from the TOC via `NS.Compat`) so no module re-queries metadata. |
| `core/State.lua` | Publishes `NS.State` — session-only runtime state (`{ debug = false }`); never persisted, reset every reload/login. |
| `core/Util.lua` | Publishes `NS.Util` — pure string helpers `trim` / `note` / `cmd` (slash dispatcher). The secret-safe pair `SafeToString` / `IsConcatSafe` is published onto the same table by `core/CoreSetup.lua`, bound to `LibKa0s-Core-1.0`'s own functions; do not re-add host copies here. Loads after Constants (reads `NS.Const.Color`). |
| `core/Database.lua` | `NS.Database` — `SCHEMA_VERSION`, `global.schemaVersion` default, and `RunMigrations(db)` (empty migration set today). Merged into AceDB + run in `PrettyChat:OnInitialize`. |
| `core/CoreSetup.lua` | The `LibKa0s-Core-1.0` seam. Publishes `NS.LIBKA0S_MISSING` (the shared cause clause all four seams append to), `NS.Print` / `NS.Format` (the cyan `[PC]` printer, `sep = ""` because the tag carries its own trailing space) and `NS.Util.SafeToString` / `IsConcatSafe`. **Must load immediately after `core/PrettyChat.lua`** — its last two lines reclaim `NS.Print` from AceConsole's embed — and before `settings/Schema.lua`, the only load-time `NS.Print` caller. |
| `core/DebugLogSetup.lua` | The `LibKa0s-DebugLog-1.0` seam. Publishes `NS.DebugLog` (the library's console instance) and `NS.Debug(tag, fmt, …)` bound bare off it. Supplies only what is this addon's: the frame-name prefix, the title, the mono font path, the `isEnabled`/`setEnabled` pair over `NS.State.debug`, the `[Init]` session summary, and the visibility callback that re-syncs the General page's checkbox. The window, both formatters, the buffer, the scroll sync, the Copy/Clear pair and the `SetEnabled` seam are the library's. |
| `core/PrettyChat.lua` | AceAddon entry. Registers the object, runs `OnInitialize` (DB + `NS.Database` migrations + slash registration) and `OnEnable` (snapshot Blizzard originals → `ApplyStrings` → `RegisterPanels`). `OpenConfig` is a one-line delegate to the library's combat-gated `OpenOptionsPanel`; there is deliberately no second open path (options-ui-§2). The override engine and slash dispatch live in `modules/Override.lua` and `settings/Slash.lua`. |

### `defaults/`, `locales/`

| File | Responsibility |
|------|----------------|
| `defaults/Profile.lua` | Publishes `NS.ProfileDefaults` — the AceDB `profile` defaults table (`{ profile = { categories = {} } }`). `core/PrettyChat.lua`'s `OnInitialize` merges it with `NS.Database`'s `global` defaults before `AceDB:New`. |
| `defaults/Defaults.lua` | The `NS.Defaults` table — canonical per-category format strings, labels, and per-category `enabled` flag. Single source of truth for what categories and strings exist. Eight categories with **81 rows over 79 unique globals** (Loot 19, Currency 4, Money 8, Reputation 14, Experience 20, Honor 6, Tradeskill 8, Misc 2 — `LOOT_ITEM_CREATED_SELF` and `LOOT_ITEM_CREATED_SELF_MULTIPLE` are registered under both Loot and Tradeskill, see [data-flow.md](./data-flow.md)). |
| `locales/enUS.lua` | `NS.L` — English-key localization metatable (`__index` returns the key) + seeded enUS UI-string manifest. Wrap new user-facing strings in `L[…]`. |

### `modules/`, `settings/`

| File | Responsibility |
|------|----------------|
| `modules/Override.lua` | The override engine, attached to the shared addon object. Houses `ApplyStrings` (deterministic `CATEGORY_ORDER` + sorted iteration), `Test`, the read helpers (`GetStringValue` / `IsAddonEnabled` / `IsCategoryEnabled` / `IsStringEnabled` / `EnsureCategoryDB`), `ResetString` / `ResetCategory` / `ResetAll`, and `NS.RenderSample(fmt)` shared with the panel's per-row Preview EditBox. |
| `settings/Schema.lua` | Builds a flat `rows` array and `byPath` lookup from `NS.Defaults` at file-load, plus a load-time path validator (`Schema.validation`), `AllRows`, `ApplyDefault` and the type-aware `Schema.FormatValue`. Exposes `NS.Schema` — the **single write path** shared by the slash CLI and the panel. `NotifyPanelChange` drives **both** refresher registries: the library's ctx-scoped one (via `NS.Helpers.RefreshScalars`) and the schema's own, which the bespoke per-string blocks use. Owns `CATEGORY_ORDER`. See [schema.md](./schema.md). |
| `settings/OptionsSetup.lua` | The `LibKa0s-Options-1.0` seam. Publishes `NS.Helpers` — **the instance itself**, decorated in place, never a copy-across table. Supplies the brand, `mainPanelName`, the `get`/`set`/`applyDefault` write seam, `rowsForPage`/`allRows`, and the landing-page hook. Its library-absent branch is the one documented **load-completing** stub (options-ui-§1): PrettyChat's measured load-time member set is empty, which `tests/test_libka0s.lua` pins by comparing schema row counts across a library-absent load. |
| `settings/Slash.lua` | Owns the ordered `COMMANDS` table of **positional triples** (`help`, `config`, `version`, `list`, `get`, `set`, `reset`, `resetall`, `test`, `debug`) — the host's, passed to the library as plain data — and the `LibKa0s-Slash-1.0` descriptor with its two hooks: `format` (the `\|` → `\|\|` doubling) and `parse` (free text containing spaces). Four verbs stay host-owned: `list`'s two reserved sub-keywords and its category filter, `resetall`, `test`, `debug`. Publishes `NS.COMMANDS` and `NS.SlashCommands`. See [slash-dispatch.md](./slash-dispatch.md). |
| `settings/Panel.lua` | The three page **bodies**, and nothing else. `buildGeneralBody` draws the virtual `General` page entirely through the library (`RenderRows` + the `pairWith` seam for the console checkbox + `InlineButtonPair`); `buildCategoryBody` uses `RenderField` for the category's Enable row and then the bespoke 40/60 `buildStringRow` blocks; `buildParentBody` is the landing page, handed over as the descriptor's `buildMain`. Each page registers through `H.RegisterOptionsPage` at file load and declares itself with `H.SetRenderer`, which owns the first-OnShow deferral, the every-OnShow Defaults button and the combat refusal. Exposes `NS.Config.RegisterPanels` and `NS.Config.BuildMain`. See [settings-panel.md](./settings-panel.md). |

### GlobalStrings sub-tree

| Path | Purpose |
|------|---------|
| `GlobalStrings/GlobalStrings.lua` | Blizzard reference (~1.6 MB, ~22,879 entries). Input to `split_globalstrings.py`. |
| `GlobalStrings/GlobalStrings_001.lua` … `_026.lua` | Chunk files, each a contiguous alphabetical range of keys. Each emits `NS.GlobalStrings["KEY"] = "value"` assignments. **Loaded by nothing at runtime** (PC-R-05) and not shipped; `tests/test_defaults.lua` reads them to check every override against Blizzard's real signature. |
| `GlobalStrings/split_globalstrings.py` | Splitter script. Re-run after a WoW patch updates `GlobalStrings.lua`; rewrites the chunk files and refuses to finish if `PrettyChat.toc` has started loading them again. |
| `GlobalStrings/README.md` | Splitter usage instructions (where to source the latest `GlobalStrings.lua`, how to regenerate). |

### Shared infrastructure

- `PrettyChat.toc` — Interface line (`120007`), version, SavedVariables (`PrettyChatDB`), section comments, and file load order. Order is dependency order, not alphabetical: `libs/` (Ace3, then `libs\LibKa0s\LibKa0s.xml`) → `locales/enUS` → `core/Compat` → `core/Constants` → `core/Namespace` → `core/State` → `core/Util` → `core/Database` → `core/PrettyChat` → `core/CoreSetup` → `core/DebugLogSetup` → `defaults/Profile` → `defaults/Defaults` → `modules/Override` → `settings/Schema` → `settings/OptionsSetup` → `settings/Slash` → `settings/Panel`. The three positions that are load-bearing are explained in [module-map.md](./module-map.md).
- `libs/` — vendored Ace3 + LibStub, plus **`libs/LibKa0s/`** (the Ka0s shared library, copied whole from the sibling `../LibKa0s` checkout and **never edited here**). Tracked in git (standard WoW addon practice).
- `tests/` — the headless harness (stock Lua 5.1, no client). `_kit/` (the **vendored** LibKa0s test kit — the registry, the assertions, the runner, the `--list` renderer, the sandboxed loader, the base mock and `vendor_sync.lua` (the consumer-side vendored-payload gate `tests/test_vendor_sync.lua` calls); never edited here), `run.lua` (the suite list, the assertion aliases and `Kit.run`), `loader.lua` (the instance factory, reduced to the isolation need: both load lists derived through the kit — TOC and `LibKa0s.xml` — plus per-call environment isolation), `wow_mock.lua` (a thin extender over `_kit/mock_base.lua`), and one `test_<module>.lua` suite per module. Excluded from luacheck. See [testing.md](./testing.md).
- `media/` — the runtime `.tga` logo (`settings/Panel.lua`) and `media/fonts/` (vendored JetBrains Mono, OFL), which **is** loaded at runtime by `core/DebugLogSetup.lua` via `NS.Const.FONT_MONO`. Also the `.png`/`.jpg` logo masters and `media/screenshots/` — project-page art the README references by CDN URL, kept here as source backups. WoW cannot load `.png`/`.jpg` at all, so `.pkgmeta` keeps them and the screenshots out of the package.
- `.pkgmeta` — BigWigs/CurseForge packager manifest: `package-as: PrettyChat`, no `externals:` (libraries are vendored, not fetched), and the ignore list that keeps dev-only files out of the shipped zip — `docs/`, `tests/`, `_dev/`, lockfiles, the whole `GlobalStrings/` reference tree (PC-R-05), and the non-runtime project-page art.
- `.gitattributes` — forces CRLF on disk for all text files (overrides per-user `core.autocrlf`).
- `.gitignore` — OS / editor cruft + `TODO.md` + `.claude/`.
- `LICENSE` — MIT.

### Top-level docs

- `README.md` — user-facing.
- `CLAUDE.md` — stub (standard link, pointer into `docs/`). Accepted deviations are **not** here: they live in `## Documented deviations` in `docs/ARCHITECTURE.md`.
- `DEPENDENCIES.md` — the toolchain contract (documentation-§7): runtime / development / release-and-assets, each entry with its evidence, a WSL2-Ubuntu install command and a one-line verification command.
- `docs/automated-tests/RESULTS.md` — the **generated** one-row-per-run record across all four suites, and the complexity watch list; one file, overwritten in place, refreshed at every release (performance-§10). The **table rows are generated** and never hand-edited; the standing sections below the table are written by a reader. See [testing.md](./testing.md).
- `docs/ARCHITECTURE.md` — the engineer brief: design overview, module map, namespace publishing table, invariants, working environment, doc index (documentation-§3 sections). Carries `## Documented deviations` — the single ratified home for every deviation from the standard.
- `docs/performance.md` — what this addon costs. It brackets nothing, under a recorded `performance-§12` no-combat-path exemption; the page carries the committed whole-repo `RegisterEvent` / `OnUpdate` / `C_Timer` sweep that is the exemption's evidence.
- `docs/*.md` — topic chunks (this file is one of them). Includes [smoke-tests.md](./smoke-tests.md), the manual in-game test suite. Automated headless coverage lives in `tests/` (`lua tests/run.lua`).
- `docs/pending/LEDGER.md` — decision record for pending items (TODO markers, unexecuted audit steps, open issues), maintained by `/wow-addon:pending-audit`. Rows are `done` / `wont-do` / `deferred`; the closed states stop an item being raised again.
- `docs/audits/<date>/`, `docs/reviews/<date>/` — frozen bundles. History, never edited after the fact.
