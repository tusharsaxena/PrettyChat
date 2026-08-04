# File index

Where each responsibility lives in the source tree. Match this map to the actual files before editing — `PrettyChat.toc` is the source of truth for load order.

## Source tree (modular)

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
| `defaults/Defaults.lua` | The `NS.Defaults` table — canonical per-category format strings, labels, and per-category `enabled` flag. Single source of truth for what categories and strings exist. Eight categories with **81 rows over 79 unique globals** (Loot 19, Currency 4, Money 8, Reputation 14, Experience 20, Honor 6, Tradeskill 8, Misc 2 — `LOOT_ITEM_CREATED_SELF` and `LOOT_ITEM_CREATED_SELF_MULTIPLE` are registered under both Loot and Tradeskill, see [override-pipeline.md](./override-pipeline.md)). |
| `locales/enUS.lua` | `NS.L` — English-key localization metatable (`__index` returns the key) + seeded enUS UI-string manifest. Wrap new user-facing strings in `L[…]`. |

### `modules/`, `settings/`

| File | Responsibility |
|------|----------------|
| `modules/Override.lua` | The override engine, attached to the shared addon object. Houses `ApplyStrings` (deterministic `CATEGORY_ORDER` + sorted iteration), `Test`, the read helpers (`GetStringValue` / `IsAddonEnabled` / `IsCategoryEnabled` / `IsStringEnabled` / `EnsureCategoryDB`), `ResetString` / `ResetCategory` / `ResetAll`, and `NS.RenderSample(fmt)` shared with the panel's per-row Preview EditBox. |
| `settings/Schema.lua` | Builds a flat `rows` array and `byPath` lookup from `NS.Defaults` at file-load, plus a load-time path validator (`Schema.validation`), `AllRows`, `ApplyDefault` and the type-aware `Schema.FormatValue`. Exposes `NS.Schema` — the **single write path** shared by the slash CLI and the panel. `NotifyPanelChange` drives **both** refresher registries: the library's ctx-scoped one (via `NS.Helpers.RefreshScalars`) and the schema's own, which the bespoke per-string blocks use. Owns `CATEGORY_ORDER`. See [schema.md](./schema.md). |
| `settings/OptionsSetup.lua` | The `LibKa0s-Options-1.0` seam. Publishes `NS.Helpers` — **the instance itself**, decorated in place, never a copy-across table. Supplies the brand, `mainPanelName`, the `get`/`set`/`applyDefault` write seam, `rowsForPage`/`allRows`, and the landing-page hook. Its library-absent branch is the one documented **load-completing** stub (options-ui-§1): PrettyChat's measured load-time member set is empty, which `tests/test_libka0s.lua` pins by comparing schema row counts across a library-absent load. |
| `settings/Slash.lua` | Owns the ordered `COMMANDS` table of **positional triples** (`help`, `config`, `version`, `list`, `get`, `set`, `reset`, `resetall`, `test`, `debug`) — the host's, passed to the library as plain data — and the `LibKa0s-Slash-1.0` descriptor with its two hooks: `format` (the `\|` → `\|\|` doubling) and `parse` (free text containing spaces). Four verbs stay host-owned: `list`'s two reserved sub-keywords and its category filter, `resetall`, `test`, `debug`. Publishes `NS.COMMANDS` and `NS.SlashCommands`. See [slash-commands.md](./slash-commands.md). |
| `settings/Panel.lua` | The three page **bodies**, and nothing else. `buildGeneralBody` draws the virtual `General` page entirely through the library (`RenderRows` + the `pairWith` seam for the console checkbox + `InlineButtonPair`); `buildCategoryBody` uses `RenderField` for the category's Enable row and then the bespoke 40/60 `buildStringRow` blocks; `buildParentBody` is the landing page, handed over as the descriptor's `buildMain`. Each page registers through `H.RegisterOptionsPage` at file load and declares itself with `H.SetRenderer`, which owns the first-OnShow deferral, the every-OnShow Defaults button and the combat refusal. Exposes `NS.Config.RegisterPanels` and `NS.Config.BuildMain`. See [settings-panel.md](./settings-panel.md). |

## GlobalStrings sub-tree

| Path | Purpose |
|------|---------|
| `GlobalStrings/GlobalStrings.lua` | Bundled Blizzard reference (~1.6 MB, ~22,879 entries). **Not loaded by any TOC** — only used as input to `split_globalstrings.py`. |
| `GlobalStrings/GlobalStrings_001.lua` … `_026.lua` | Chunk files, each a contiguous alphabetical range of keys. Each emits `NS.GlobalStrings["KEY"] = "value"` assignments. Loaded *eagerly* by `PrettyChat.toc` — the only load path. |
| `GlobalStrings/split_globalstrings.py` | Splitter script. Re-run after a WoW patch updates `GlobalStrings.lua`; rewrites the chunk files. |
| `GlobalStrings/README.md` | Splitter usage instructions (where to source the latest `GlobalStrings.lua`, how to regenerate). |

## Shared infrastructure

- `PrettyChat.toc` — Interface line (`120007`), version, SavedVariables (`PrettyChatDB`), section comments, and file load order. Order is dependency order, not alphabetical: `libs/` (Ace3, then `libs\LibKa0s\LibKa0s.xml`) → `locales/enUS` → `core/Compat` → `core/Constants` → `core/Namespace` → `core/State` → `core/Util` → `core/Database` → `core/PrettyChat` → `core/CoreSetup` → `core/DebugLogSetup` → `defaults/Profile` → `defaults/Defaults` → GlobalStrings chunks → `modules/Override` → `settings/Schema` → `settings/OptionsSetup` → `settings/Slash` → `settings/Panel`. The three positions that are load-bearing are explained in [module-map.md](./module-map.md).
- `libs/` — vendored Ace3 + LibStub, plus **`libs/LibKa0s/`** (the Ka0s shared library, copied whole from the sibling `../LibKa0s` checkout and **never edited here**). Tracked in git (standard WoW addon practice).
- `tests/` — the headless harness (stock Lua 5.1, no client). `_kit/` (the **vendored** LibKa0s test kit — the registry, the assertions, the runner, the `--list` renderer, the sandboxed loader and the base mock; never edited here), `run.lua` (the suite list, the assertion aliases and `Kit.run`), `loader.lua` (the instance factory: a TOC-derived load list and per-call environment isolation), `wow_mock.lua` (a thin extender over `_kit/mock_base.lua`), and one `test_<module>.lua` suite per module. Excluded from luacheck. See [testing.md](./testing.md).
- `media/` — the runtime `.tga` logo (`settings/Panel.lua`) and `media/fonts/` (vendored JetBrains Mono, OFL), which **is** loaded at runtime by `core/DebugLogSetup.lua` via `NS.Const.FONT_MONO`. Also the `.png`/`.jpg` logo masters and `media/screenshots/` — project-page art the README references by CDN URL, kept here as source backups. WoW cannot load `.png`/`.jpg` at all, so `.pkgmeta` keeps them and the screenshots out of the package.
- `.pkgmeta` — BigWigs/CurseForge packager manifest: `package-as: PrettyChat`, no `externals:` (libraries are vendored, not fetched), and the ignore list that keeps dev-only files out of the shipped zip — `docs/`, `tests/`, `_dev/`, lockfiles, the GlobalStrings source dump + splitter, and the non-runtime project-page art.
- `.gitattributes` — forces CRLF on disk for all text files (overrides per-user `core.autocrlf`).
- `.gitignore` — OS / editor cruft + `TODO.md` + `.claude/`.
- `LICENSE` — MIT.

## Top-level docs

- `README.md` — user-facing.
- `CLAUDE.md` — stub (standard link, accepted deviations, pointer into `docs/`).
- `DEPENDENCIES.md` — the toolchain contract (documentation-§7): runtime / development / release-and-assets, each entry with its evidence, a WSL2-Ubuntu install command and a one-line verification command.
- `docs/automated-tests/RESULTS.md` — the **generated** one-row-per-run record across all four suites, and the complexity watch list; one file, overwritten in place, refreshed at every release (performance-§10). The **table rows are generated** and never hand-edited; the standing sections below the table are written by a reader. See [testing.md](./testing.md).
- `docs/ARCHITECTURE.md` — the engineer brief: design overview, module map, namespace publishing table, invariants, working environment, doc index (documentation-§3 sections).
- `docs/*.md` — topic chunks (this file is one of them). Includes [smoke-tests.md](./smoke-tests.md), the manual in-game test suite. Automated headless coverage lives in `tests/` (`lua tests/run.lua`).
- `docs/pending/LEDGER.md` — decision record for pending items (TODO markers, unexecuted audit steps, open issues), maintained by `/wow-addon:pending-audit`. Rows are `done` / `wont-do` / `deferred`; the closed states stop an item being raised again.
- `docs/audits/<date>/`, `docs/reviews/<date>/` — frozen bundles. History, never edited after the fact.
