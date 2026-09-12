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

**Six positions in that order are load-bearing and are pinned by tests, not by convention:**

- `core/EnvSetup.lua` sits **before** `core/Namespace.lua`, and therefore before `settings/Slash.lua` and `settings/Panel.lua` too, because all three read the TOC at FILE SCOPE — `NS.version`, `VERSION` and `TOC_NOTES` each resolve once at load and keep the answer for the whole session. All three call the seam unguarded, so a seam published later raises on the first load instead of pinning the reported version to a literal for good; `tests/test_envsetup.lua` pins what each of the three actually resolved to, which no raise can tell you.

- `core/MediaSetup.lua` sits **before** `core/Constants.lua`, because `Const.FONT_MONO` is resolved through `NS.MediaFont` at load. A seam published afterwards would leave every install silently on `STANDARD_TEXT_FONT` — a console that reads perfectly well in the wrong face, which is the kind of regression nobody files.

- `core/Util.lua` sits **after** `core/Constants.lua`, because `Color` is taken there as a file-scope upvalue off `NS.Const` — resolved once, at load, and kept for the session. There is no guard and no fallback, so a `Util` that loaded first indexes a nil `NS.Const` and raises during load; nothing asserts this one directly because the harness cannot build an instance at all when it is wrong, which is a louder failure than an assertion.

- `core/CoreSetup.lua` sits **immediately after** `core/PrettyChat.lua`, because that file passes `NS` to `AceAddon:NewAddon` and AceConsole embeds its own `:Print` over the namespace — CoreSetup's last two lines are the reclaim (anti-pattern #36). It also sits **before** `settings/Schema.lua`, the only load-time `NS.Print` caller. Nothing in the repo takes the printer as a file-scope upvalue, so the window between those two is wide.
- `core/DebugLogSetup.lua` sits after Constants (the mono font path), State (the flag) and CoreSetup (the printer), and before every module that calls `NS.Debug` (debug-logging-§1).
- `settings/OptionsSetup.lua` sits after `settings/Schema.lua`, whose `Get`/`Set`/`RowsByCategory` its descriptor reads, and before `settings/Panel.lua`, which takes the instance as a file-scope upvalue and registers its pages at file load (options-ui-§1).

### The shared cause clause

`core/CoreSetup.lua` publishes **`NS.LIBKA0S_MISSING`** — *"The LibKa0s library is missing from this installation of Ka0s Pretty Chat (expected in libs/LibKa0s)"* — outside its own library-absent branch, because the three later seams read it on **both** paths. Each appends its own consequence and its own terminal punctuation: `", so the debug console window is unavailable."`, `", so the settings panel is unavailable."`, `", so the settings CLI is unavailable."`, and Core's own fallback printer announces once, on the first line the addon prints, with `"; running on reduced built-in fallbacks."`. This is a **cross-file contract four seams depend on**, not an implementation detail of one file: a degraded install says the same thing about *why* at every site and a different thing about *what* at each one, across every Ka0s addon a user has open.

| Module | Publishes on `NS` | Role |
|--------|-------------------|------|
| `core/EnvSetup.lua` | `NS.Meta`, `NS.Version` | The `LibKa0s-Env-1.0` seam. Reads one field of this addon's own TOC manifest, and answers its version string (the TOC first, then `NS.version`, then `"?"`), telling the library which addon FOLDER is asking — a vendored copy cannot work that out for itself. Falls back to the C_AddOns-then-legacy-global ladder when the library is absent, so a degraded install reads its own TOC exactly as it did before. Replaced `core/Compat.lua`, which held nothing but the same reader. |
| `core/Constants.lua` | `NS.Const`, `NS.PREFIX` | `Const.Color` palette (incl. `azure` / `listHead` slash-output codes), `Const.STRING_VSPACER`, `Const.FONT_MONO_NAME` / `Const.FONT_MONO` (JetBrains Mono, resolved through `NS.MediaFont` from the LibKa0s payload, falling back to `STANDARD_TEXT_FONT`), and the shared cyan `[PC]` chat prefix. Carries **no** panel layout constants — those are `LibKa0s-Options-1.0`'s `LAYOUT` table (options-ui-§8). Side-effect-free. |
| `core/Namespace.lua` | `NS.name`, `NS.version` | Identity bootstrap — records the addon name + version so any module can read them without re-querying the TOC. |
| `core/State.lua` | `NS.State` | Session-only runtime state (`{ debug = false }`); never persisted, reset every reload/login. |
| `core/Util.lua` | `NS.Util` | Pure string helpers `trim` / `note` / `cmd` (slash dispatcher). The secret-safe pair `SafeToString` / `IsConcatSafe` is **published onto this same table by `core/CoreSetup.lua`**, bound to `LibKa0s-Core-1.0`'s own function objects. |
| `core/Database.lua` | `NS.Database` | `SCHEMA_VERSION`, `global.schemaVersion` default, `RunMigrations(db)` (empty migration set today) and the load-pass repair `PruneOrphans(db)`, which it runs last. |
| `core/MediaSetup.lua` | `NS.Icon`, `NS.MediaFont` | The `LibKa0s-Media-1.0` seam. Answers a texture path (extensionless) or a font path for a name in the library's catalog, telling the library which addon FOLDER is asking — a vendored copy cannot work that out for itself. Both answer `nil` when the library is absent or the name is not one it ships; `nil` is a real answer and is never routed around by concatenation. Ends with `Media.RegisterLSM(addonName)` at file load, a no-op in this install because LibSharedMedia-3.0 is not vendored here. |
| `core/CoreSetup.lua` | `NS.Print`, `NS.Format`, `NS.LIBKA0S_MISSING`, `NS.MakeCloseButton`, `NS.Util.SafeToString`, `NS.Util.IsConcatSafe` | The `LibKa0s-Core-1.0` seam. Builds the cyan `[PC]` printer from the descriptor (`prefix` as a function, `sep = ""` because the tag carries its own trailing space), reclaims `NS.Print` from AceConsole's embed, and owns the library-absent fallbacks. |
| `core/DebugLogSetup.lua` | `NS.DebugLog`, `NS.Debug` | The `LibKa0s-DebugLog-1.0` seam. Supplies the frame-name prefix, the title, the mono font, the `isEnabled`/`setEnabled` pair over `NS.State.debug`, the `[Init]` session summary and the visibility callback; the window, both formatters, the buffer, the scroll sync and the `SetEnabled` seam are the library's. |
| `core/PrettyChat.lua` | the AceAddon object | AceAddon registration (the `NS` table itself — passed to `:NewAddon`, architecture-§2) + lifecycle (`OnInitialize` / `OnEnable`), and `OpenConfig`, now a one-line delegate to the library's combat-gated `OpenOptionsPanel`. |
| `defaults/Profile.lua` | `NS.ProfileDefaults` | The AceDB `profile` defaults table (`{ profile = { categories = {} } }`); `OnInitialize` merges it with `NS.Database`'s `global` defaults before `AceDB:New`. |
| `defaults/Defaults.lua` | `NS.Defaults` | Category → format-string default table (label + default per string; per-category `enabled`). |
| `locales/enUS.lua` | `NS.L` | Localization table with English-key fallback (`__index` returns the key). Seeds the enUS UI-string manifest. |
| `modules/Override.lua` | `NS.RenderSample`, `NS.OriginalFormat` | The override engine — `ApplyStrings`, the enable-cascade predicates, `ResetString` / `ResetCategory` (both through `Schema.ResetRows`) / `ResetAll`, the Test / sample renderer, and the one reader of Blizzard's pristine format (`OriginalFormat`), shared with the panel's Original box. `ResetAll` is a **profile reset** (`options-ui-§12`): one `db:ResetProfile()`, with the re-apply and the one `[Set] reset profile '<name>' to defaults (N rows)` line landing on `core/PrettyChat.lua`'s `OnProfileReset` handler — the same reload a profile switch takes. |
| `settings/Schema.lua` | `NS.Schema` | Builds `rows`/`byPath` from `NS.Defaults`; single write path (`Schema.Set`) and its batched entry (`ResetRows`), `AllRows`, `ApplyDefault`, `FormatValue`, load-time path validator, cross-registered-global map, and the `NotifyPanelChange` fan-out that drives **both** refresher registries. |
| `settings/OptionsSetup.lua` | `NS.Helpers` | The `LibKa0s-Options-1.0` seam — the instance itself, decorated in place. Supplies the brand, the main canvas name, the `get`/`set`/`applyDefault` write seam, the per-page row lookup and the landing-page hook. |
| `settings/Slash.lua` | `NS.COMMANDS`, `NS.SlashCommands` | The ordered `COMMANDS` table (positional triples, the host's), the `LibKa0s-Slash-1.0` descriptor with its `format` and `parse` hooks, and the four host-owned verbs: `list`'s sub-keywords and category filter, `resetall`, `test`, `debug`. |
| `settings/Panel.lua` | `NS.Config.RegisterPanels`, `NS.Config.BuildMain` | The page **bodies** and nothing else, for the addon's three kinds of page: the `General` page (a `TextRow` then `H.RenderTabbedSchema` over its one composed `Master controls` tab, whose `afterGroup` draws the host `Test` button and then the composer's own closing button), the `Categories` page (an `H.TabStrip` of the eight message categories, a footnote, then per tab a library-made Enable row, an AceGUI `TreeGroup` — that category's format strings in its tree pane beside **one** editor for the selected string), and the landing page (a spec — logo, tagline, one `Slash Commands` section — handed to the library's `H.BuildLandingPage`, which owns the body and, at `OptionsWidgets.lua:323`, the `OnRelease` that keeps the logo texture out of AceGUI's shared frame pool). The primary strip is the library's; the tree and the editor beside it are the `options-ui-§13` and `§6` deviations. The canvas factory, the header, the Defaults button, the scroll container and the page registry are the library's. |

Topic detail: [module-map.md](./module-map.md).

## Namespace publishing pattern

Every file opens by destructuring the two values WoW passes each chunk — the addon FOLDER name and the addon-wide namespace table. Seven files read both and spell the header `local addonName, NS = ...`: `core/Namespace.lua`, `core/CoreSetup.lua`, `core/EnvSetup.lua`, `core/MediaSetup.lua`, `core/DebugLogSetup.lua`, `core/PrettyChat.lua` (which hands the folder name to `:NewAddon`) and `settings/Panel.lua` (which builds `Interface\\AddOns\\<folder>` from it). The other eleven never read the folder name and open `local _, NS = ...` — `M4c-06` corrected them when the blanket `211/addonName` suppression that had been hiding them came out of `.luacheckrc`. A copied header naming a value the file does not use is dead code, not a convention. Modules publish their public surface onto `NS`; nothing is exported through a global. The addon object **is** that same `NS` table (`core/PrettyChat.lua` passes `NS` to `:NewAddon`, architecture-§2), so the AceAddon methods hang off it and `LibStub("AceAddon-3.0"):GetAddon("PrettyChat")` returns the very same table.

| Member | Set by | Used by |
|--------|--------|---------|
| `NS.Meta`, `NS.Version` | `core/EnvSetup.lua` | `core/Namespace.lua`, `settings/Slash.lua`, `settings/Panel.lua` (metadata access, all three at FILE SCOPE) |
| `NS.Icon`, `NS.MediaFont` | `core/MediaSetup.lua` | `core/Constants.lua` (`FONT_MONO`, at file scope). **`NS.Icon` has no host caller today** — the marks a player sees are drawn by the library's own console windows, told the folder name through `core/DebugLogSetup.lua`'s descriptor; the seam is published so the first window this addon builds asks the catalog rather than typing a path |
| `NS.MakeCloseButton` | `core/CoreSetup.lua` | **No host caller today**, for the same reason — published so the next window this addon builds does not have to remember the folder name at its call site. The live three-argument wrapper is covered by `tests/test_libka0s.lua`; that the DEGRADED arm publishes the key at all (PC-A-05) is `tests/test_surface_parity.lua`'s Core case |
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

- **Single write path.** Every settings mutation goes through `NS.Schema.Set(path, value)`: the panel widget callbacks (`settings/Panel.lua`), `/pc set` and `/pc reset <path>` (`settings/Slash.lua`). The per-category and per-string resets (`PrettyChat:ResetCategory` / `:ResetString` in `modules/Override.lua`) take its batched entry, `Schema.ResetRows(rows, label)`, which writes each row's default through the same `row.set` behind the same gates. `Set` runs `PrettyChat:ApplyStrings()` and `Schema.NotifyPanelChange()` once per write, `ResetRows` once per batch, and together they keep panel and slash from drifting. Never write `db.profile.categories[…]` directly from outside a row's `set()` closure. The one other writer is `PrettyChat:ResetAll`, the options-ui-§12 profile reset (`db:ResetProfile()`), which architecture-§5 exempts as a wholesale replacement.
- **Master toggle wins.** With `General.enabled` false, `ApplyStrings` restores every Blizzard original regardless of per-category and per-string state. Three enable layers, evaluated in order: addon → category → per-string ([data-flow.md](./data-flow.md)).
- **Format-specifier signatures must match Blizzard's — and `Schema.Set` enforces it.** Each Blizzard string has a fixed signature (`%s`, `%d`, `%.1f`, `%2$s`, …); a replacement must consume the same conversions in the same order or `string.format` errors at runtime, inside Blizzard's chat handler rather than here. Since PC-R-01 the write seam refuses any `string_format` value whose conversion sequence is not a positional **prefix** of the shipped default's — shorter is safe (`string.format` ignores surplus arguments), longer or class-mismatched is the raise. `NS.ConversionSequence(fmt)` in `modules/Override.lua` is the one walk the Preview, the gate and `tests/test_defaults.lua` all read; it used to exist only in the test suite, which is why the shipped code had nothing to ask. Copy the signature from the panel's left (Original) edit box.
- **Overrides only ever happen in `ApplyStrings`, and the snapshot only in `OnEnable`.** `OnEnable` runs after Blizzard has populated `_G`, and its pre-override snapshot (iterating `NS.Defaults` deterministically) is the one chance to capture pristine values for the runtime restore-on-disable path. It records **two** tables — `addon.originalStrings` for the values and `addon.snapshotKeys` for the fact that it looked — because the pristine value of a global this client does not define is `nil`, which is also what an unrecorded entry looks like; the restore arm reads the key set, so an absent global is restored to `nil` rather than left overridden (PC-R-07). Never assign `_G[GLOBALNAME]` from anywhere but `ApplyStrings`, which walks `CATEGORY_ORDER` plus sorted names so cross-registered globals resolve deterministically (documented last-writer).
- **All chat output goes through `NS.Print`; all developer logging through `NS.Debug`.** `NS.Print` (`core/CoreSetup.lua`, built by `LibKa0s-Core-1.0`) prepends the cyan `NS.PREFIX` (`|cff00ffff[PC]|r `) — **no raw `print(...)` and no direct `DEFAULT_CHAT_FRAME:AddMessage`** anywhere, including `Test()` in `modules/Override.lua`, whose every body line is prefixed. `NS.Debug(tag, fmt, …)` is a zero-alloc no-op while off, gated on the session-only `NS.State.debug` flag whose single owner is `NS.DebugLog:SetEnabled(on)` (`/pc debug on|off`, the console header toggle). Console **visibility** is a separate concern (`:Show()` / `:Hide()` / `:Toggle()` / `:IsShown()`, bare `/pc debug` and the General-page checkbox); the window's OnShow/OnHide fire `Schema.NotifyPanelChange("General")` so the checkbox tracks it. `SetEnabled` prints the color-coded ack, writes the `[Debug] logging enabled|disabled` bracket, and on enable appends the one-line `[Init]` session summary (`PrettyChat v<ver>, schema v<n>, profile '<key>'`) — the visible boot summary, since the flag is off at login. Traces are **one gated line per event, never per string**: `[Init]`, `[Migrate]` (`core/Database.lua`, only when a step runs, plus one line when the load-pass repair drops keys), `[Set] <path> = <value>` (`Schema.Set`, the single settings-change seam — no `[Apply]` re-echo), one `[Set] reset <scope>: N rows` per category or string reset (`Schema.ResetRows`, N the rows it changed — debug-logging-§10: a bulk reset is one `[Set]` line, never one per row), one line per profile event from `core/PrettyChat.lua`'s handlers, worded by the event (`[Set] reset profile '<name>' to defaults (N rows)`, `[Set] copied profile 'A' → 'B'`, `[Profile] switched → applied N restored M`); a reset or copy that raises partway still writes its one line, ending ` (stopped by an error)`, then re-raises (`NS.Util.RunAct`); `[Cfg]` (the library's panel-open — opened/refused). `ApplyStrings` returns `(applied, restored)` and stays silent so its caller emits the summary.
- **`libs/` is never edited, and a misfit is a finding rather than a patch.** `libs/LibKa0s/` and `tests/_kit/` are vendored whole from the sibling `../LibKa0s` checkout. A local edit is a fork nobody knows about, and the next re-vendor reverts it silently — so a library problem is fixed upstream and re-vendored back. `tests/test_vendor_sync.lua` — a call into the shared, vendored gate `tests/_kit/vendor_sync.lua` — compares both folders against the released tag the root [CLAUDE.md](../CLAUDE.md)'s provenance line says this addon bundles whenever that checkout is present (kit revision 9 moved that line out of the player-facing README, and reads it with no fallback), and [testing.md](./testing.md) carries the four diffs the release path uses.
- **A LibKa0s descriptor is never handed `NS.L`.** The locale table answers *every* key with the key itself (the standard mandates the metatable fallback), so a module handed it would render raw `SCREAMING_SNAKE` keys in place of English — for every key at once, visible only in game. `tests/test_libka0s.lua` greps every seam file for the three spellings and drives the matcher against all of them. Translate by passing a **plain** table of just the keys you translate.
- **User-facing strings go through `NS.L`.** `locales/enUS.lua` exports an English-key metatable (missing keys fall back to the key). Wrap new static UI strings in `L["…"]` and add them to the enUS manifest.

## Settings Schema

`NS.Defaults` is the source data; `settings/Schema.lua` turns it into an ordered `rows` list keyed by dot path. Six row kinds:

- `General.enabled` — addon-wide master toggle (bool). `General` is a **virtual category** with no entry in `NS.Defaults`; stored as `db.profile.enabled` at the profile root.
- `General.visibility` — when the overrides apply (`always` / `inCombat` / `outOfCombat` / `never`); stored as `db.profile.visibility`, cleared back to nil on `always`.
- `state.debugConsole` — the debug console window's visibility (bool); `sessionOnly`, stores nothing.
- `<Category>.enabled` — per-category toggle (bool).
- `<Category>.<GLOBALNAME>.enabled` — per-string toggle (bool).
- `<Category>.<GLOBALNAME>.format` — per-string format string.

Every row write from `/pc set`, `/pc reset <path>` and the panel widgets goes through `NS.Schema.Set(path, value)`, the **single write path**; the per-category Defaults button and the per-string Reset button go through its batched entry `Schema.ResetRows(rows, label)`. Row `set()` closures are pure DB writes; `Schema.Set` runs `PrettyChat:ApplyStrings()` + `Schema.NotifyPanelChange()`, and, being the seam every value write crosses, owns the conversion-signature gate that refuses a dangerous format before it is stored (returns `false`, refreshes the panel so the box shows what actually **is** stored). `Schema.ResetRows` asks the same gates, writes each row's default through its `set()`, then runs one `ApplyStrings` pass, one `NotifyPanelChange` and one `[Set] reset <label>: N rows` line for the whole batch, N the rows it changed (debug-logging-§10). Every stored row **auto-clears** on a default match (a value equal to the default deletes the stored key), and a `set()` that empties a `strings` / `disabledStrings` / category table drops it, so SavedVariables holds only what a player changed. At load, `Schema.validation` records that every row path resolves to a backing default (loud `NS.Print` warn on any miss). Settings persist in `PrettyChatDB` via AceDB on a single shared Default profile; the `profile` defaults come from `defaults/Profile.lua` (`NS.ProfileDefaults`) and `db.global.schemaVersion` is stamped by `Database.RunMigrations`. Detail: [schema.md](./schema.md).

**Structural registries (architecture-§5): none.** Storage keys: none qualify. `db.profile.categories` is keyed by the fixed `Schema.CATEGORY_ORDER` names, and each category's `strings` / `disabledStrings` by the fixed Blizzard GLOBALNAME set in `NS.Defaults`. The player never adds or removes a member, and every stored leaf has a row path (the load pass enforces this, below), so no collection passes the three-part test. Writer: none is needed. `PrettyChat:EnsureCategoryDB` (`modules/Override.lua`) only creates an empty category table on the first write from a row's `set()` closure, which is a traversal accessor, not a writer. Load pass: `Database.RunMigrations` (`core/Database.lua`), called from `OnInitialize` and from the `OnProfileChanged` / `OnProfileCopied` / `OnProfileReset` callbacks in `core/PrettyChat.lua`. It stamps `db.global.schemaVersion`, which is bookkeeping and not a row, and with `migrations` empty the only other thing it writes is the repair `Database.PruneOrphans`. The repair drops any `strings` / `disabledStrings` key no schema row owns, such as an override for a global string a later version removed, then prunes the tables that empties (savedvariables-§1). This is why a category reset, which writes rows, always leaves no category table behind. `PrettyChat:ResetAll` is the options-ui-§12 profile reset (`db:ResetProfile()`), a wholesale replacement and not a registry write.

**Named non-setting state (architecture-§5): none.** No persistent value in `PrettyChatDB` falls in any of the four classes, as of the 2026-09-12 sweep against Standard v2.44.0. The addon is frameless, so no geometry is drag-written; the debug console's drag (`libs/LibKa0s/DebugLog.lua`) moves the window for the session and writes nothing to SavedVariables. No view is remembered across sessions: the Categories tree's selection and fitted height live on the panel `ctx` (`ctx.__pcTree`, `ctx.__pcTreeH`) and die with it. The addon learns and records nothing. No vendored library is handed an addon table to write into; AceDB's `profileKeys` / `profiles` bookkeeping is the store itself, not state inside it. Every stored leaf is therefore a row, written through `Schema.Set` / `Schema.ResetRows`, or the load pass's `db.global.schemaVersion` stamp. That also means there is no forget, purge or delete of learned or recorded data for debug-logging-§8 to trace; the only deletions are row resets, which the `[Set]` lines already cover.

**Resets.** `PrettyChat:ResetCategory` (the per-category Defaults button) hands `Schema.ResetRows` every row of the category, or for `General` its two stored rows, `General.enabled` and `General.visibility` (never the session-only console toggle); the visibility row's own `set()` re-syncs the combat watcher. `PrettyChat:ResetString` (the per-string Reset button) hands it that string's `.enabled` and `.format` rows. `/pc reset <path>` and the library's `applyDefault` hook (wired in `settings/Slash.lua` and `settings/OptionsSetup.lua`) go through `Schema.ApplyDefault` → `Schema.Set`, bare `/pc reset <category>` only prints guidance, and `/pc resetall` is the profile reset above.

## Message Bus

**There is none, because this addon publishes no named message.** A whole-repo sweep of `core/ defaults/ modules/ settings/ locales/` returns zero `SendMessage`, zero `RegisterMessage` and zero `AceEvent` — AceEvent-3.0 is deliberately not vendored (the `library-stack-§1` row in `## Documented deviations`), so there is no bus to publish on and no sender/payload/consumer triple to tabulate.

What stands in its place is a **direct, synchronous fan-out inside the single write path**. `Schema.Set` (and, once per batch, `Schema.ResetRows`) calls `Schema.NotifyPanelChange()`, which drives **both** refresher registries: `LibKa0s-Options-1.0`'s per-page `ctx.refreshers`, and this addon's own `Schema.RegisterRefresher(category, fn)` list — the one the bespoke per-string blocks in `settings/Panel.lua` sign up to, because a hand-built block is invisible to the library's registry. Each refresher runs under `pcall`, so a page whose AceGUI widgets have been released cannot take a `/pc set` down with it. Sender, payload and consumers are a function call and its closure rather than a message name; detail in [schema.md](./schema.md).

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

- **Retail only.** `## Interface: 120100` (Midnight / Retail). Classic / Classic Era untested.
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

A `PC-NN` id in a **Why** cell is a deviation an audit filed and resolves in `docs/audits/`; a
`PC-R-NN` id is a review finding and resolves in `docs/reviews/2026-08-05/` as `F-0NN`. The short
form is this repository's own shorthand — it is used in code comments and suites as well as here —
and the expansion is stated once, so a reader who has only ever seen the short form can follow it.
`PC-R-05` is that bundle's `F-005`; `PC-R-06` is its `F-006`.

| Rule | What differs | Why | Decided | Re-check trigger |
|---|---|---|---|---|
| `performance-§12` | No perf harness is wired: no `core/PerfSetup.lua`, no `PrettyChatPerfDB`, no `perf` verb registration, no suspend/resume contract, no `tests/perf.lua`, no `docs/perf-analysis/` | **Criterion (a) still holds, and it is narrower than it was.** There is no `OnUpdate` handler and no repeating ticker. The settings revamp added two things the sweep returns. The first is `PrettyChatCombatWatcher`, which listens to `PLAYER_REGEN_DISABLED` / `PLAYER_REGEN_ENABLED` **only while `General.visibility` is `inCombat` or `outOfCombat`** — the two of four canonical modes a player has to go and choose. A default install registers nothing, and even when armed the handler runs at the combat BOUNDARY (at most twice per fight), never during it, and does one deterministic `ApplyStrings` pass over ~170 table writes with no allocation per string. The second is one guarded `C_Timer.After(0, …)` at `settings/Panel.lua:533-534` — a one-shot next-frame layout fit on the options-panel render path, reachable only with that panel open, which `OpenOptionsPanel` refuses to open under `InCombatLockdown()`. A one-shot hop off a UI render is none of the three things criterion (a) names. **Both (b) and (c)** still apply: every declared bucket would read `0.000` by construction, and `suspend` would flip the player's chat formatting back to Blizzard's mid-fight for a capture that can only report zero. Reasoned at length as [`LIBKA0S-12`](https://github.com/tusharsaxena/PrettyChat/issues/10) | 2026-08-05, re-checked 2026-09-02 and again 2026-09-08 (the 2026-09-02 sweep predated the settings-panel timer by one day) | **The first `OnUpdate` handler, repeating ticker, or event handler that runs DURING combat rather than at its boundary re-arms the full wiring MUST.** Re-run the sweep in `performance.md`: it now returns the watcher and the settings panel's next-frame fit, and the question to ask of any new hit is whether it fires while the player is fighting |
| `layout-§2` | `GlobalStrings/` is a **PascalCase, root-level** folder outside the mandated `core/ defaults/ settings/ locales/ modules/` skeleton (`layout-§1`), holding 26 machine-generated chunks (~22,879 Blizzard reference strings) plus the 23,842-line source dump `GlobalStrings/GlobalStrings.lua` | The modular layout has no home for bulk generated reference data. **Nothing ships and nothing loads:** since PC-R-05 the whole folder is `.pkgmeta`-ignored and `PrettyChat.toc` carries no chunk line, so it is repo-only reference data that `tests/test_defaults.lua` reads to check every override against Blizzard's real signature. Chunks stay cut by entry count, not by first letter, and each is under 1000 lines so the generated data stays out of `layout-§1`'s on-notice band (PC-49). Regenerate with `python3 GlobalStrings/split_globalstrings.py`, which now REFUSES to run if the TOC has started loading the chunks again. **What is left in this row is the folder's NAME and PLACE, and nothing else.** It used to carry the dump's 1500-LOC breach too; `layout-§1` was revised on 2026-09-08 (standard v2.39.0) to cap generated non-shipping data at its generator rather than at its output, so the dump is exempt **by rule** and is recorded under *Files over the 1500-line cap* below rather than deviating here | 2026-08-05, cap half retired 2026-09-08 | **The old trigger has half fired and is replaced.** What ends this row now is a `layout-§2` revision permitting a PascalCase non-source folder at the root, **or** the folder moving under `tests/` now that it is a fixture rather than shipped data — which would settle the casing and the placement in one move. The `toc-file-§5` half of this pair was already closed; the cap half closed with the revision |
| `toc-file-§1` | `## Title:` keeps its rainbow `\|cRRGGBB…\|r` escapes, `## Author:` keeps its stylized `aDd1kTeD2Ka0s` casing, and `## X-Wago-ID` is absent | The color escapes and the casing are the addon's brand mark, kept deliberately rather than normalized to `Ka0s Pretty Chat` / `add1kted2ka0s`. `toc-file-§1` asks for both distribution ids once an addon is published anywhere; PrettyChat is on CurseForge only (`## X-Curse-Project-ID: 919766`), so there is no Wago listing to reference. Do not add the field and do not commit a placeholder | 2026-07-12 | The addon being listed on Wago (which re-arms `X-Wago-ID` immediately), or a decision to retire the brand mark |
| `debug-logging-§2` | The debug console's monospace font (JetBrains Mono, OFL) reaches the library as the console descriptor's `font` path via `Const.FONT_MONO`, and **no LibSharedMedia registration happens in this install** | The reason changed with the adoption of `LibKa0s-Media-1.0`. Registration is no longer omitted by choice: `core/MediaSetup.lua` calls `Media.RegisterLSM(addonName)` at load like every other addon in the collection, and that call returns `0, 0` because PrettyChat does not vendor LibSharedMedia-3.0 and has no font-picker consumer to justify vendoring it. The console stays fixed-monospace on purpose — readability of aligned log output does not depend on player taste. Not to be "fixed" by hand-rolling a registration | 2026-08-24 | The first user-facing media picker in this addon, which would give LSM a consumer and pull the library in |
| `options-ui-§6` | A category tab is an AceGUI `TreeGroup` — a 200px tree pane beside a content pane — instead of the schema-driven 50/50 two-column grid | The pane holds full color-escaped format strings — the Blizzard original, the user's replacement and the live preview — at FULL width, which is the width the deviation exists to buy; a 50/50 grid clips them, and `LibKa0s-Options-1.0`'s caller-driven `RenderGrid` offers `HALF` (0.5) or full width and no third ratio, so it cannot express a tree-plus-content pane at all (`LIBKA0S-06`). Justified in-code above `buildCategoryBody`. **Re-shaped 2026-09-03**: it was a 40/60 THREE-ROW editor (`LEFT_W` / `RIGHT_W`), with the string chosen from a secondary strip above it. The strip became the left column (see the `§13` row below) and the editor's three fields became full width inside the right one, so the split moved from inside the editor to the page — the ratio is still not one the flow engine has | 2026-07-31, re-shaped 2026-09-03 | `RenderGrid` gaining a third width ratio (`LIBKA0S-06`), or the pane no longer needing to show three format strings at full width |
| `options-ui-§13` | Inside a category tab, the format strings are chosen from a **vertical list** — AceGUI's `TreeGroup` — rather than from a secondary tab strip | `§13` permits a secondary strip inside one primary tab, and this page had one. A strip is packed **horizontally** and wraps: Experience registers twenty strings with names like *XP Gain (Exhausted, Group)*, which came out as **five rows of buttons** above the editor they select — chrome taller than its content, and a paragraph of buttons to scan for one name. The same twenty read down a column at a glance. What `§13` is protecting is intact: the division is ordinary content **inside the scroll** rather than a second pinned band, there is no third level, and the selection is session-only (`ctx.activeSubTab`, keyed per category). The widget is AceGUI's own `TreeGroup` — the container behind every AceConfig left nav — so the bordered panes, the selected row's highlight bar, the row spacing and the tree pane's scrollbar are all its, not this addon's. Justified in-code above `buildCategoryBody` | 2026-09-03 | An `options-ui` revision that names a vertical form for a secondary division — at which point this is permitted outright and the row retires — or the longest category shrinking to a strip that does not wrap |
| `testing-§1` | `tests/wow_mock.lua` is the thin extender over `tests/_kit/mock_base.lua` the rule asks for, but **`tests/loader.lua` survives** beside `tests/_kit/loader.lua` | The kit builds one shared environment whose `__newindex` writes through to the real `_G`. This addon's entire feature is rewriting `_G[GLOBALNAME]` and half the suite asserts on what landed there, so a shared environment would let one suite's overrides answer another suite's reads. `tests/loader.lua` is reduced to exactly that isolation need — a fresh mock per instance, `_G` pointed back at it, chunks compiled once — and takes everything else from the kit (`Loader.makeEnv`, `Loader.tocFiles`, `Loader.xmlFiles`). Reported upstream as `LIBKA0S-01` | 2026-08-02 | `tests/_kit/loader.lua` gaining an isolated-environment mode (`LIBKA0S-01`), after which `tests/loader.lua` is deleted outright |
| `localization-§1` | **PrettyChat ships English only.** `locales/` holds `enUS.lua` and nothing else, and the category names interpolated into three routed strings (`Enable %s`, `Enable or disable all %s string overrides.`, `Shared with %s …`) are English identifiers that no locale file can translate | The routing SHOULD is **largely satisfied**, and this row now carries the part that is not. Until M4-21 this cell claimed `tests/test_locale.lua` made an unwrapped string red. It did not and could not: the scan built its candidate set from a `gmatch` of `L["…"]`, so it could only ever find strings that were **already** wrapped — `testing-§12`'s own failure mode, sitting inside the check for this rule, which is how `settings/Slash.lua`'s usage lines stayed English through four audits with nothing going red. The suite now scans the same TOC-derived sources for string LITERALS and requires every unrouted one to be **recorded, with its reason**, in the residue register at the foot of `tests/test_locale.lua`; a new bare sentence in a settings file is red, and so is a register entry that has stopped matching the tree. Ten `settings/Slash.lua` and three `modules/Override.lua` lines were routed in that pass, byte for byte — `L` falls back to the key, so nothing a player sees moved. What the register holds is three kinds of thing: the shared degraded-install stem (`core/CoreSetup.lua:29-34`) and the four per-site tails that four whole-sentence keys would each duplicate; the lines whose prose is split across two mandated colour spans (`slash-commands-§4`/`§5`), where one key would have to carry `|c…|r` escapes inside translatable text and two keys would re-create the fragments PC-R-06 removed; and the brand name and the descriptor fields crossing to LibKa0s, which must never be handed `NS.L` (LIBKA0S-05, "The `L` trap"). Below the register's floor sit the **one-word labels** — `Category: `, `Name: `, `Original: ` and `Formatted: ` in the `/pc test` report, and the 81 display labels in `defaults/Defaults.lua` — which read the same as a table key to any mechanical test and are unrouted; translating those is the localization pass no translator has yet asked for. What is recorded here is the shipping decision — no second locale file — and the one residue routing cannot reach. There were **four** such strings until the eight category pages became one tabbed page: `Reset all %s strings to defaults.` lost its caller, because one Defaults button over eight tabs cannot carry a wording fixed at panel-build time. The residue shrank; the deviation did not change. A category name is a **schema path segment** (`Loot.enabled`, `/pc set Loot.enabled false`), so translating the display name would either desynchronize it from the path a user types or need a second display-name table that only a translator can populate; neither is worth building before a translator exists. `localization-§3` makes this a terminal compliant state once it is a row here, and an audit **MUST NOT** re-file the routing SHOULD against it | 2026-08-05 | **The first non-English locale file added to `locales/`.** That fires both halves: the new file gets the four `%s` sentences, and the category display-name question becomes real and needs the second table |
| `options-ui-§15` | The `Master controls` tab's closing button pair reads **`[Test] [Reset all settings]`** rather than the canonical `Reset all settings` alone that §15 gives a frameless addon | §15 fixes the block's ROWS and closes it with the reset pair; it does not give an addon anywhere else to put a page-wide ACT. `Test` is a preview verb no other Ka0s addon has — it renders every format string with sample arguments — and it belongs to the addon as a whole rather than to any category, so the General page is the only page it can live on. **The host no longer draws it.** It was a button on a row of its own above the reset, drawn here; since LibKa0s **v1.25.0** (`OptionsCompose` minor 2) it is the composer's `leadButton`, declared in `MASTER_SPEC` and drawn by the composer into the pair's empty right half — the one cell §15 leaves a frameless addon, which has no *Reset position*. That matters because §15 also fixes the reset's WORDING: drawing the pair host-side would have put a second copy of *"Reset all settings"* in this addon, which is the drift the composer exists to end. The composed rows and their order are untouched and the canonical button still closes the tab | 2026-09-02, moved into the library 2026-09-03 | An `options-ui` revision that names a place for host-owned page-wide acts, or `Test` moving off the panel entirely |

**Retired on 2026-09-08, two rows, both because the collision they recorded was upstream.**

- **`toc-file-§5` — `# Locales` immediately after `# Libraries`.** The row never argued that this
  addon wanted a different order; it argued that the standard asked for two, `toc-file-§5` putting
  Locales before Defaults and `layout-§1`'s load order putting Defaults first, and that PrettyChat
  had resolved toward the former. There is no disagreement left to resolve: `layout.md:53` states
  the folder order `libs/* → locales/* → core/* → defaults/* → modules/* → settings/*`,
  `toc-file.md:109` states the header order **Libraries → Locales → Core → Defaults → Modules →
  Settings**, and `layout-§1` adds that if the two ever disagree "that is a defect in this document
  rather than a choice an addon gets to make". This TOC's sections (`PrettyChat.toc:15`, `:24`,
  `:27`, `:49`, `:53`, `:56`) are that order, so what the row recorded as a departure is now
  mandated by both sections at once. The row's trigger — *"WowAddonStandards#2 resolving"* — fired
  on 2026-08-06, when that issue was closed `state:will-not-do`; the `# GlobalStrings` half had
  already closed with `PC-R-05`. `PC-61`.

- **`library-stack-§1` — AceEvent-3.0 and AceTimer-3.0 not vendored.** The row recorded a
  contradiction inside one section: `§1`'s table listed both among the libs every Ace3 addon
  vendors, while `§3` MUSTs vendoring only libs the addon actually `LibStub`s. This addon reaches
  neither — it starts no timers, and the two combat-boundary events its visibility watcher needs go
  on a plain frame it creates lazily and drops again (`modules/Override.lua`) — so it could satisfy
  one half or the other and never both. `library-stack-§1`'s table now reads that "mandatory" means
  mandatory **when used**, marks AceEvent and AceTimer that way, and names this addon as the case
  the wording was written for — adding that an addon holding a ratified-deviation row for a
  contradiction that lives upstream is the graveyard the register exists to prevent, manufactured
  by the standard rather than by the addon, and that the row is retired rather than re-argued.
  Vendoring six of the table's eight rows is compliant. The row's trigger was, in as many words,
  *"the next `library-stack` edit"*; this is that edit. `PC-52`.

### Files over the 1500-line cap

`layout-§1` caps every **authored** `.lua` file this repository tracks at 1500 lines — `tests/`
included, and never mind that only five folders hold source — and carves out exactly two things:
vendored code (`libs/`, `tests/_kit/`), which is audited in the repository that writes it, and
**generated non-shipping data**, which is capped at its generator rather than at its output. A file
over the cap that neither carve-out reaches has three terminal states: peeled, an open issue naming
the seam a peel would follow, or a ratified row in the register above carrying a re-check trigger.
What the rule does not allow is a fourth — a file over the cap that nothing anywhere remarks on,
"the count sitting in a bundle manifest that no document reads". This table is the remark, and it
is why an audit **MUST NOT** re-file `layout-§1` against the file in it.

Measured 2026-09-08 with

```sh
git ls-files '*.lua' | grep -v '^libs/' | grep -v '^tests/_kit/' | xargs wc -l | sort -rn
```

| File | Lines (2026-09-08) | Disposition |
|---|---|---|
| `GlobalStrings/GlobalStrings.lua` | 23,842 | **Exempt** by `layout-§1`'s generated-data carve-out. Not a deviation and not a breach; the three conditions below are re-checked on every run by `tests/test_layout_cap.lua` |

**This addon has no cap breach.** One file is over 1500 lines and it is the generated dump, which
the carve-out reaches. Nothing here is peeled, and nothing needed to be.

**The exemption is earned condition by condition, and each condition is one line somebody could
delete for an unrelated reason.** `layout-§1` grants it only when **all three** hold, so all three
are re-derived on every run rather than asserted once and then trusted:

1. **Generated, and saying so.** `GlobalStrings/GlobalStrings.lua:1` reads
   `-- AUTOMATICALLY GENERATED -- Your benefactors send their regards.` It is an extraction from
   the client, and the next extraction overwrites any hand edit wholesale.
2. **Nothing loads it.** `PrettyChat.toc` carries no `GlobalStrings\` line and has not since
   PC-R-05, and the headless harness derives its file list from that same TOC, so one absence
   answers for the client and for the suite. `tests/test_defaults.lua` reading the chunks through
   `loadfile` is a fixture being read as data, which the rule names explicitly as still qualifying.
3. **`.pkgmeta`-ignored.** The `- GlobalStrings` entry drops the whole folder from the packaged
   zip, so no player downloads a byte of it.

A file failing any one of the three "is an ordinary source file with an unusual origin, and the cap
binds it". That is why the gate re-derives the answer instead of carrying the path in a skip list:
a TOC line added back, or a `.pkgmeta` entry tidied away, turns a 23,842-line file into a
`layout-§1` MUST, and it should turn a suite red on the way in rather than surface in an audit two
months later.

**The line count is dated because it drifts, and nothing asserts it.** What
`tests/test_layout_cap.lua` asserts is the *membership* of this table, in both directions: a file
that crosses 1500 and is not listed here turns the suite red, and so does a row for a file that has
fallen back under the cap or been deleted. The figure in that column is a measurement, not a claim
about today.

**The 1000-1500 band is on notice, not in breach**: `tests/test_panel.lua` (1042) is the only file
in it, and the 26 generated chunks are deliberately cut by entry count to stay under 1000 (PC-49)
so a regeneration cannot walk them into the band. The band is named here so a later reader can tell
it was looked at rather than missed; nothing in it needs a disposition until it crosses.

## External dependencies

Vendored under `libs/` (the BigWigs packager pulls nothing — no `externals`): LibStub, CallbackHandler-1.0, AceAddon-3.0, AceDB-3.0, AceConsole-3.0, AceGUI-3.0, and **[LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.33.0** (`libs/LibKa0s/`, listed in the TOC as `libs\LibKa0s\LibKa0s.xml` after Ace3). (`AceConfig-3.0` was removed — no live consumer.)

Six of LibKa0s's ten majors are adopted: **Core**, **Env**, **Media**, **DebugLog**, **Slash** and **Options**. **Perf is declined** under a recorded `performance-§12` no-combat-path exemption — the register row above, with its sweep in [performance.md](./performance.md) and its reasoning at [LIBKA0S-12](https://github.com/tusharsaxena/PrettyChat/issues/10). **Item**, **Pool** and **Widgets** are not consumed here at all — nothing in this addon, and no other vendored LibKa0s file, `LibStub`s any of the three. `Item.lua`, `Pool.lua`, `Widgets.lua`, `Perf.lua` and `PerfPanel.lua` are still vendored, because the folder is copied whole and never file by file.

The shared test kit is vendored separately to `tests/_kit/` — **never** to `libs/`, which is the ship payload.

## Testing

Headless harness under `tests/` (stock Lua 5.1, no client): `lua tests/run.lua` + `luacheck .`. Suites register named `test(name, fn)` cases; `lua tests/run.lua --list` prints the generated case inventory ([test-cases.md](./test-cases.md), testing-§5) — the authoritative pass count, mirrored by the README `tests` badge. Manual in-game validation: [smoke-tests.md](./smoke-tests.md). Full verification guide and the commit gate: [testing.md](./testing.md).

## Working environment

- **Dual-path WSL.** `/home/tushar/GIT/PrettyChat/` and `/mnt/d/Profile/Users/Tushar/Documents/GIT/PrettyChat/` are the same repo via symlink.
- **`.gitattributes`** forces CRLF on disk for all text files — hence the `--strip-trailing-cr` in the inventory diff ([testing.md](./testing.md)).
- **`.gitignore`** covers OS/editor cruft and `.claude/`. `libs/` is tracked (vendored Ace3), as are `GlobalStrings/`, `media/`, all `.lua` source, `tests/`, `.luacheckrc` and `.pkgmeta`.
- **Case-insensitive `/mnt/d`.** `libs/` was renamed from `Libs/` on disk; with `core.ignorecase=true`, recording a case flip in git needs `git mv -f Libs libs` even though the working tree already reads lowercase.

