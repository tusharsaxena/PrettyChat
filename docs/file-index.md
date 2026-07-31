# File index

Where each responsibility lives in the source tree. Match this map to the actual files before editing — `PrettyChat.toc` is the source of truth for load order.

## Source tree (modular)

Source `.lua` is grouped under `core/`, `defaults/`, `locales/`, `modules/`, and `settings/`.

### `core/`

| File | Responsibility |
|------|----------------|
| `core/Compat.lua` | `NS.Compat` — version-shim seam. `Compat.GetAddOnMetadata` (C_AddOns vs legacy global). Loads first among addon files. |
| `core/Constants.lua` | Layout constants on `NS.Const` (panel padding / header height / Defaults-button width / spacers / `BUTTON_PAIR_REL`), the `Color` palette (incl. the slash-output `azure` / `listHead` codes), `NS.Const.FONT_MONO` (vendored JetBrains Mono path for the debug console), and `NS.PREFIX` (shared cyan `[PC]` tag). Side-effect-free; loads early so later files can read `NS.Const.*` without an existence check. |
| `core/Namespace.lua` | Identity bootstrap — publishes `NS.name` and `NS.version` (read from the TOC via `NS.Compat`) so no module re-queries metadata. |
| `core/State.lua` | Publishes `NS.State` — session-only runtime state (`{ debug = false }`); never persisted, reset every reload/login. |
| `core/Util.lua` | Publishes `NS.Util` — pure string helpers `trim` / `note` / `cmd` (slash dispatcher) plus secret-safe output helpers `SafeToString` / `IsConcatSafe` (events-frames-taint-§8) that the chat printer and debug sink route through. Loads after Constants (reads `NS.Const.Color`). |
| `core/Database.lua` | `NS.Database` — `SCHEMA_VERSION`, `global.schemaVersion` default, and `RunMigrations(db)` (empty migration set today). Merged into AceDB + run in `PrettyChat:OnInitialize`. |
| `core/DebugLog.lua` | Publishes `NS.DebugLog` (the on-screen debug console — a monospace DIALOG-strata window with a `Debug: ON/OFF` header toggle + Copy/Clear buttons) and `NS.Debug(tag, fmt, …)` (the gated, zero-alloc-when-off sink that routes to the console). The `DebugLog:SetEnabled(on)` seam is the single owner of the session debug flag. |
| `core/PrettyChat.lua` | AceAddon entry. Registers the object, defines `NS.Print`, runs `OnInitialize` (DB + `NS.Database` migrations + slash registration) and `OnEnable` (snapshot Blizzard originals → `ApplyStrings` → `RegisterPanels`), and owns the combat-gated `OpenConfig`. The override engine and slash dispatch live in `modules/Override.lua` and `settings/Slash.lua`. |

### `defaults/`, `locales/`

| File | Responsibility |
|------|----------------|
| `defaults/Profile.lua` | Publishes `NS.ProfileDefaults` — the AceDB `profile` defaults table (`{ profile = { categories = {} } }`). `core/PrettyChat.lua`'s `OnInitialize` merges it with `NS.Database`'s `global` defaults before `AceDB:New`. |
| `defaults/Defaults.lua` | The `NS.Defaults` table — canonical per-category format strings, labels, and per-category `enabled` flag. Single source of truth for what categories and strings exist. Eight categories with **81 rows over 79 unique globals** (Loot 19, Currency 4, Money 8, Reputation 14, Experience 20, Honor 6, Tradeskill 8, Misc 2 — `LOOT_ITEM_CREATED_SELF` and `LOOT_ITEM_CREATED_SELF_MULTIPLE` are registered under both Loot and Tradeskill, see [override-pipeline.md](./override-pipeline.md)). |
| `locales/enUS.lua` | `NS.L` — English-key localization metatable (`__index` returns the key) + seeded enUS UI-string manifest. Wrap new user-facing strings in `L[…]`. |

### `modules/`, `settings/`

| File | Responsibility |
|------|----------------|
| `modules/Override.lua` | The override engine, attached to the shared addon object. Houses `ApplyStrings` (deterministic `CATEGORY_ORDER` + sorted iteration), `Test`, the read helpers (`GetStringValue` / `IsAddonEnabled` / `IsCategoryEnabled` / `IsStringEnabled` / `EnsureCategoryDB`), `ResetString` / `ResetCategory` / `ResetAll`, and `NS.RenderSample(fmt)` shared with the panel's per-row Preview EditBox. |
| `settings/Schema.lua` | Builds a flat `rows` array and `byPath` lookup from `NS.Defaults` at file-load, plus a load-time path validator (`Schema.validation`) and the type-aware `Schema.FormatValue`. Exposes `NS.Schema` — the **single write path** shared by slash commands and panel widgets. Owns `CATEGORY_ORDER` (the canonical display order, including the virtual `General`). See [schema.md](./schema.md). |
| `settings/Slash.lua` | The `/pc` / `/prettychat` dispatcher. Owns the ordered `COMMANDS` table (`help`, `config`, `version`, `list`, `get`, `set`, `reset`, `resetall`, `test`, `debug`) that drives both dispatch and `/pc help`, `OnSlashCommand`, and every `runX` / `listSettings` / `getSetting` / `setSetting` handler. Slash `list` / `get` / `set` output uses the shared `FormatKV` + `Schema.FormatValue` for the mandated colour scheme (slash-commands-§5). Publishes `NS.COMMANDS`. See [slash-commands.md](./slash-commands.md). |
| `settings/Panel.lua` | Settings panel built directly on `Settings.RegisterCanvasLayoutCategory` / `RegisterCanvasLayoutSubcategory` with AceGUI body content. `buildGeneralBody` builds the virtual `General` page; `buildCategoryBody` + `buildStringRow` build each format-bearing page; `buildParentBody` renders the parent landing page. UI strings go through `NS.L`. Exposes `NS.Config.RegisterPanels` (called from `PrettyChat:OnEnable`); each sub-page's first `OnShow` calls `NS.Schema.RegisterRefresher(category, refreshFn)` so `Schema.NotifyPanelChange` can re-sync the page after a write. All widget callbacks delegate to `NS.Schema.Set/Get`. See [settings-panel.md](./settings-panel.md). |

## GlobalStrings sub-tree

| Path | Purpose |
|------|---------|
| `GlobalStrings/GlobalStrings.lua` | Bundled Blizzard reference (~1.6 MB, ~22,879 entries). **Not loaded by any TOC** — only used as input to `split_globalstrings.py`. |
| `GlobalStrings/GlobalStrings_001.lua` … `_010.lua` | Chunk files. Each emits `NS.GlobalStrings["KEY"] = "value"` assignments. Loaded *eagerly* by `PrettyChat.toc` — the only load path. |
| `GlobalStrings/split_globalstrings.py` | Splitter script. Re-run after a WoW patch updates `GlobalStrings.lua`; rewrites the chunk files. |
| `GlobalStrings/README.md` | Splitter usage instructions (where to source the latest `GlobalStrings.lua`, how to regenerate). |

## Shared infrastructure

- `PrettyChat.toc` — Interface line (`120007`), version, SavedVariables (`PrettyChatDB`), section comments, and file load order. Order is dependency order, not alphabetical: `libs/` → `locales/enUS` → `core/Compat` → `core/Constants` → `core/Namespace` → `core/State` → `core/Util` → `core/Database` → `core/DebugLog` → `core/PrettyChat` → `defaults/Profile` → `defaults/Defaults` → GlobalStrings chunks → `modules/Override` → `settings/Schema` → `settings/Slash` → `settings/Panel`.
- `libs/` — vendored Ace3 + LibStub. Tracked in git (standard WoW addon practice).
- `tests/` — the headless harness (stock Lua 5.1, no client). `run.lua` (runner + micro-framework + the `--list` inventory mode), `loader.lua` (loads the sources in TOC order and runs the AceAddon lifecycle), `wow_mock.lua` (the WoW/Ace3/AceGUI/Settings mock builder), and one `test_<module>.lua` suite per module. Excluded from luacheck. See [testing.md](./testing.md).
- `media/` — the runtime `.tga` logo (`settings/Panel.lua`) and `media/fonts/` (vendored JetBrains Mono, OFL), which **is** loaded at runtime by `core/DebugLog.lua` via `NS.Const.FONT_MONO`. Also the `.png`/`.jpg` logo masters and `media/screenshots/` — project-page art the README references by CDN URL, kept here as source backups. WoW cannot load `.png`/`.jpg` at all, so `.pkgmeta` keeps them and the screenshots out of the package.
- `.pkgmeta` — BigWigs/CurseForge packager manifest: `package-as: PrettyChat`, no `externals:` (libraries are vendored, not fetched), and the ignore list that keeps dev-only files out of the shipped zip — `docs/`, `tests/`, `_dev/`, lockfiles, the GlobalStrings source dump + splitter, and the non-runtime project-page art.
- `.gitattributes` — forces CRLF on disk for all text files (overrides per-user `core.autocrlf`).
- `.gitignore` — OS / editor cruft + `TODO.md` + `.claude/`.
- `LICENSE` — MIT.

## Top-level docs

- `README.md` — user-facing.
- `CLAUDE.md` — stub (standard link + pointer to `docs/`); full engineer brief in [agent-context.md](./agent-context.md).
- `docs/ARCHITECTURE.md` — design overview + invariants + doc index (documentation-§3 sections).
- `docs/*.md` — topic chunks (this file is one of them). Includes [smoke-tests.md](./smoke-tests.md), the manual in-game test suite. Automated headless coverage lives in `tests/` (`lua tests/run.lua`).
- `docs/pending/LEDGER.md` — decision record for pending items (TODO markers, unexecuted audit steps, open issues), maintained by `/wow-addon:pending-audit`. Rows are `done` / `wont-do` / `deferred`; the closed states stop an item being raised again.
- `docs/audits/<date>/`, `docs/reviews/<date>/` — frozen bundles. History, never edited after the fact.
