# Schema and storage

`settings/Schema.lua` is the single source of truth for what's settable. At file-load (after `defaults/Defaults.lua` and `core/PrettyChat.lua`) it iterates `NS.Defaults` and builds a flat array of rows, one per settable value, exposed at `NS.Schema`.

This doc covers: the four row kinds, the single write path that every settings mutation goes through, and the AceDB shape behind it.

## Row kinds

Four row kinds, addressed by dot path:

| Path | Kind | Type | Backed by |
|------|------|------|-----------|
| `General.enabled` | `addon_enabled` | bool | `db.profile.enabled` (addon-wide master toggle; `General` is a *virtual category* — no entry in `NS.Defaults`) |
| `<Category>.enabled` | `category_enabled` | bool | `db.profile.categories[Cat].enabled` (via `IsCategoryEnabled` / `EnsureCategoryDB`) |
| `<Category>.<GLOBALNAME>.enabled` | `string_enabled` | bool | `db.profile.categories[Cat].disabledStrings[NAME]` (**inverted**: `disabledStrings[NAME] = true` means *disabled*) |
| `<Category>.<GLOBALNAME>.format` | `string_format` | string | `db.profile.categories[Cat].strings[NAME]` (with `NS.Defaults[Cat].strings[NAME].default` fallback) |

Each row carries its own `get()` and `set(value)` closures. PrettyChat's storage layout doesn't map 1:1 onto the path structure — the inverted `disabledStrings` table, the virtual `General` category, the default-fallback for formats — so a generic dot-walker (KickCD's `Helpers.Resolve` style) doesn't fit. Closures are simpler than a special-case resolver.

## Single write path

`Schema.Set(path, value)` is the **only** function that mutates settings:

```lua
function Schema.Set(path, value)
    local row = byPath[path]
    if not row then return false end
    row.set(value)                              -- pure DB write
    PrettyChat:ApplyStrings()                   -- reconcile live _G overrides
    Schema.NotifyPanelChange(row.category)      -- refresh the affected page / tab
    NS.Debug("Set", "%s = %s", path, Schema.FormatValue(row, value))  -- [Set] trace (debug-logging-§10)
    return true
end
```

The `NS.Debug("Set", …)` line is the single settings-change trace (debug-logging-§10): a no-op unless `/pc debug on`, and when on it logs exactly one `[Set] <path> = <value>` line per write (value via the shared `Schema.FormatValue`, so it reads like `/pc get`). The `ApplyStrings` re-apply it triggers is an implied consequence and is deliberately **not** re-echoed.

Both surfaces go through the same row's `set()`:

- **Panel widget callbacks** in `settings/Panel.lua` call `NS.Schema.Set(path, val)`.
- **`/pc set`** goes through `LibKa0s-Slash-1.0`'s `CliSet`, which parses the value through the descriptor's `parse` hook and then calls `NS.Schema.Set(path, newVal)`.

Row `set()` closures are pure DB writes — they do **not** run `ApplyStrings` or `NotifyPanelChange` themselves. Both side effects live in `Schema.Set` so a future `Schema.SetMany` / preset-load can apply once per batch instead of N times. Callers must therefore never invoke `row.set(value)` directly; always go through `Schema.Set`.

`Schema.NotifyPanelChange(category)` dispatches to a refresher closure that `settings/Panel.lua` registers for the category tab it has just drawn, via `Schema.RegisterRefresher(category, fn)`. The closure re-syncs every visible widget on that tab from the DB. Master-toggle changes (category `"General"` or `nil`) cascade to every registered refresher since per-string disabled state depends on the master. This keeps the panel and the slash UI from ever drifting — a `/pc set` while the panel is open updates both surfaces in the same frame. At most one category has an entry at a time: the visible tab. A tab that is not on screen has none, and that is correct — it is rebuilt from the live DB the moment it is selected, so it cannot show stale state.

### Auto-clear on default

For `string_format` rows specifically, the row's `set` closure stores `nil` (clears the override entry) when `value` matches the row's PrettyChat default:

```lua
if v == NS.Defaults[category].strings[globalName].default then
    catDB.strings[globalName] = nil
else
    catDB.strings[globalName] = v
end
```

So writing a format back to its default value via `/pc set` or the panel acts as a per-string reset — the override entry is removed from `db.profile.categories[Cat].strings`, and `GetStringValue` falls back to the default on next read. The `strings` table never collects "override that happens to equal the default".

## Public API

| Function | Purpose |
|----------|---------|
| `Schema.RowsByCategory(category)` | Filtered subset for one category. Used by `/pc list <Category>` and the no-arg `/pc list` (iterating `CATEGORY_ORDER`); also used by `schemaReady()` as the presence-check sentinel for "is the schema fully built?". |
| `Schema.FindByPath(path)` | O(1) lookup; returns the row or `nil`. |
| `Schema.Get(path)` / `Schema.Set(path, value)` | Read/write through the row's closures. `Set` returns `false` if the path is unknown. |
| `Schema.FormatValue(row, value)` | Type-aware display string shared by `/pc list` rows and the `/pc get` / `/pc set` echo (slash-commands-§5): bool → `true`/`false`; string → the raw format with `|` doubled to `||` so its color escapes render as literal text; `nil` → `"nil"`. |
| `Schema.ResolveCategory(name)` | Case-insensitive PascalCase resolver — `/pc reset loot` finds `Loot`. Returns `nil` for unknowns. |
| `Schema.NotifyPanelChange(category?)` | Invokes the closure registered for `category` via `RegisterRefresher`. Pass `nil` (or `"General"`) to fire every registered refresher. Safe to call before any tab has been drawn — unregistered categories are no-ops. |
| `Schema.RegisterRefresher(category, fn)` | Sub-page registration hook called by `settings/Panel.lua` on first `OnShow`. The closure should re-sync every visible widget on that page from the DB. |
| `Schema.CATEGORY_ORDER` | Display order array. Imported by `settings/Panel.lua` (tab-strip order on the Categories page, minus the virtual `General`), `modules/Override.lua`'s `Test()` and `settings/Slash.lua`'s `/pc list` (iteration order). The single source of truth — iterating `pairs(NS.Defaults)` would give a non-deterministic order. |

## Reset semantics

Three reset paths, all routed through `PrettyChat:Reset*` not directly through Schema:

- **`PrettyChat:ResetString(category, globalName)`** clears **both** per-string dimensions for one string — the custom format (`strings[NAME]`) and the disable flag (`disabledStrings[NAME]`) — so it matches the full-reset semantics of the two below. Resetting only the format would leave a previously-disabled string half-reset. After clearing, calls `ApplyStrings` and `Schema.NotifyPanelChange(category)`.
- **`PrettyChat:ResetCategory(category)`** clears one category's overrides. Special case: `category == "General"` clears `db.profile.enabled` back to `nil` (default true). After clearing, calls `ApplyStrings` and `Schema.NotifyPanelChange(category)`.
- **`PrettyChat:ResetAll()`** clears `db.profile.enabled` *and* every entry in `db.profile.categories`. Calls `ApplyStrings` and `Schema.NotifyPanelChange(nil)` (every category).

All three are reachable from:

- The per-string `Reset` button on each panel row (`ResetString` — always visible, a no-op when the string is already at default), the `Categories` page's `Defaults` button (in the page header, acting on the visible tab — no popup confirm), and the General sub-page's "Reset all to defaults" button (gated by the `PRETTYCHAT_RESET_ALL` StaticPopup).
- `/pc reset <path>` (one row, through `Schema.ApplyDefault` → the single write seam) and `/pc resetall` (no in-chat confirmation — typing the command is itself the assertion). Category-scoped reset is the settings page's **Defaults** button; `/pc reset` has taken a path rather than a category since `LIBKA0S-10`.

## SavedVariables shape

```
PrettyChatDB.profile.enabled                                         -- bool (addon-wide master toggle; nil = default true)
PrettyChatDB.profile.categories[catName].enabled                     -- bool (nil = default true, sourced from NS.Defaults[Cat].enabled)
PrettyChatDB.profile.categories[catName].strings[globalName]         -- string override (nil = use PrettyChat default)
PrettyChatDB.profile.categories[catName].disabledStrings[globalName] -- true = disabled (absent / nil = enabled)
```

**`enabled` defaults follow the `nil → true` contract.** Neither the addon-wide master toggle nor per-category `enabled` flags appear in the `defaults` table — they're created on first user write and read via `IsAddonEnabled` / `IsCategoryEnabled` which return `true` when the value is `nil`. This keeps SavedVariables empty until the user disables something, and it makes `ResetCategory` coherent: clearing a flag (`= nil`) genuinely returns it to default-true rather than relying on AceDB to re-merge a populated default.

Only user-modified values are stored. The schema's auto-clear keeps `strings[...]` lean — it never collects "override that happens to equal the default".

`db.profile.categories[catName]` is created lazily by `EnsureCategoryDB` on first write. `disabledStrings` and `strings` sub-tables are created lazily inside the row's `set()` closures.

### Profiles

Profiles use AceDB with a single shared `Default` profile:

```lua
self.db = LibStub("AceDB-3.0"):New("PrettyChatDB", defaults, true)
```

The third arg (`true`) selects the `Default` profile name for every character. All characters on the account see the same configuration out of the box.

`AceDBOptions-3.0` (per-character / per-class / per-realm profile UI) is **not** wired in. Adding it is a small contribution: register the AceDBOptions table as a third `PrettyChat_Profiles` sub-page in `settings/Panel.lua` (library-drawn, and deliberately never tabbed). See [scope.md](./scope.md#out-of-scope) for why it isn't there today.

## Build sequence

Schema construction runs once at file-load (`settings/Schema.lua`). The order matters:

1. `buildAddonEnabledRow()` — adds the single `General.enabled` row.
2. For each `category` in `CATEGORY_ORDER` (skipping `General`):
   - `buildCategoryRow(category)` — adds `<Cat>.enabled`.
   - For each `globalName` in `NS.Defaults[Cat].strings` (sorted alphabetically): `buildStringRows(...)` — adds `<Cat>.<NAME>.enabled` *and* `<Cat>.<NAME>.format`.

Closures bind to live values: `NS.Defaults` is populated by `defaults/Defaults.lua` (loaded earlier by the TOC) and the addon object exists (`core/PrettyChat.lua`'s `:NewAddon` ran before `settings/Schema.lua`).
