# Schema and storage

`settings/Schema.lua` is the single source of truth for what's settable. At file-load (after `defaults/Defaults.lua` and `core/PrettyChat.lua`) it iterates `NS.Defaults` and builds a flat array of rows, one per settable value, exposed at `NS.Schema`.

This doc covers: the six row kinds, the single write path that every panel and slash row write goes through (and its batched entry, which the two resets take), and the AceDB shape behind it.

## Row kinds

Seven row kinds, addressed by dot path. The first four are the **composed** `Master controls` block (`H.MasterControls`, options-ui-§15); the last three are this addon's own:

| Path | Kind | Type | Backed by |
|------|------|------|-----------|
| `General.enabled` | `addon_enabled` | bool | `db.profile.enabled` (addon-wide master toggle; `General` is a *virtual category* — no entry in `NS.Defaults`) |
| `General.visibility` | `addon_visibility` | string enum | `db.profile.visibility` (`always` / `inCombat` / `outOfCombat` / `never`; cleared when set back to `always`, so the default stores nothing). Honored in `ApplyStrings` through `PrettyChat:IsVisible`, and the two combat modes arm `PrettyChatCombatWatcher` |
| `state.debugConsole` | `debug_console` | bool | **nothing** — `sessionOnly`, mirroring `NS.DebugLog:IsShown()`. Unprefixed and verbatim, because session state lives outside the block's own prefix. The write seam's `announce` skips its `ApplyStrings` re-apply for this row. Its `default` is `false`, the reset target (`MASTER_SPEC.defaults.debugConsole`): `LibKa0s-Schema-1.0` reads a nil default as "no restore", so `/pc reset state.debugConsole` needs a value to write |
| `global.minimap.hide` | `minimap_button` | bool | `db.global.minimap.hide` — LibDBIcon's **own** table, declared in `core/Database.lua`'s AceDB `global` defaults and handed straight to the library (`launcher-§3`). **Unprefixed and verbatim** for a different reason than the console row's: this table lives in the **global** store, outside the block's profile prefix entirely, because a minimap button belongs to the installation rather than to a profile — a profile switch must not move a player's buttons. **Surviving a reset is a property of the setting, not of that scope** (`launcher-§3`): neither options-ui-§12's *Reset all settings* nor a page-scoped **Defaults** button may un-hide it or re-hide a shown one. Neither reaches it here — the first is `db:ResetProfile()` over a profile this table is not in, and the General page's **Defaults** button is that same profile reset behind the same popup (`options-ui-§12`). The one per-category call that could walk it, `PrettyChat:ResetCategory('General')`, has no panel button any more, and `modules/Override.lua`'s `GENERAL_RESET_PATHS` still names the two profile rows one by one instead of walking the category, which would reach this one. **The row's sense is inverted against the stored key**: the label says *shown*, `hide` says hidden, so its `get`/`set` negate and the `set` writes the LEAF (never the whole table — LibDBIcon keeps `minimapPos` in there too) and then calls `NS.Launcher:SetShown`. Stored, not session |
| `<Category>.enabled` | `category_enabled` | bool | `db.profile.categories[Cat].enabled` (via `IsCategoryEnabled` / `EnsureCategoryDB`) |
| `<Category>.<GLOBALNAME>.enabled` | `string_enabled` | bool | `db.profile.categories[Cat].disabledStrings[NAME]` (**inverted**: `disabledStrings[NAME] = true` means *disabled*) |
| `<Category>.<GLOBALNAME>.format` | `string_format` | string | `db.profile.categories[Cat].strings[NAME]` (with `NS.Defaults[Cat].strings[NAME].default` fallback) |

Each row carries its own `get()` and `set(value)` closures. PrettyChat's storage layout doesn't map 1:1 onto the path structure — the inverted `disabledStrings` table, the virtual `General` category, the default-fallback for formats — so a generic dot-walker (KickCD's `Helpers.Resolve` style) doesn't fit. Closures are simpler than a special-case resolver.

## Single write path

Every settings mutation goes through `Schema.Set(path, value)`. `/pc reset <path>` does too, through `Schema.ApplyDefault`. The Categories page's page-wide reset and the per-category and per-string resets (`PrettyChat:ResetCategoriesPage` / `:ResetCategory` / `:ResetString` in `modules/Override.lua`) take its batched entry, `Schema.ResetRows` (see [Reset semantics](#reset-semantics)). The only other writer is `/pc resetall`'s profile reset, which architecture-§5 exempts as a wholesale replacement.

**The seam is `LibKa0s-Schema-1.0`'s.** `settings/Schema.lua` builds the rows, then makes one runtime instance over them, `NS.SchemaRuntime`. The instance comes from the library, or from the host's degradation stub when LibKa0s is absent. `Schema.Set`, `Schema.Get`, `Schema.FindByPath`, `Schema.AllRows`, `Schema.ApplyDefault` and `Schema.CountChangedRows` are the instance's `Set`, `Get`, `FindRow`, `AllRows`, `ApplyDefault` and `CountOffDefault`, bound under the names every caller already used. The Options and Slash descriptors take the same members as values. What the host hands the runtime:

```lua
local S = SchemaLib:New({
    rows     = rows,                                  -- the live array, by reference
    announce = function(row)                          -- the write's tail
        if not row.sessionOnly then PrettyChat:ApplyStrings() end   -- console toggle stores nothing
        Schema.NotifyPanelChange(row.category)        -- refresh the affected page / tab
    end,
    debug    = function(tag, fmt, ...) return NS.Debug(tag, fmt, ...) end,
    format   = function(row, v) return Schema.FormatValue(row, v) end,  -- the [Set] value
    print    = function(line) return NS.Print(line) end,
})
```

No `resolveRoot`: every row carries its own `get` / `set`, so the runtime never walks a stored tree. The runtime's `Set` does, in this order:

1. It refuses an unknown path (`false, err`).
2. It runs the row's `validate`, which is the conversion-signature gate on a format row (`false, err, why`).
3. It stores through the row's `set`. Each `set` is wrapped in `PrettyChat.Batch` where the row is built, so a latch arm the write fires leaves its pass to the tail.
4. It writes the `[Set] <path> = <value>` line.
5. It runs `announce`.
6. It answers `true`.

The line comes before the re-apply (the library's order, its JC-4). A raising re-apply therefore cannot erase the trace of a write that landed.

### The conversion-signature gate

A `string_format` write is refused unless its conversion sequence is a **positional prefix** of the
shipped default's — never longer, never a different class at a position they share.
`NS.ConversionSequence(fmt)` (`modules/Override.lua`) is the walk both sides read; the refusal names
the path, both signatures and the Blizzard global, through `NS.Print`, refreshes the panel so the New
box snaps back to what is stored, and writes a `[Set] … refused` trace.

The gate is **each format row's `validate`**, not a wrapper in front of `Schema.Set`. The runtime
runs `validate` on every entry: a panel write, `/pc set`, `/pc reset` through `ApplyDefault`, and
both value-bound descriptors. A wrapper would be bypassed by `ApplyDefault`, which calls the
runtime's own `Set` (LibKa0s's `docs/api/Schema/version-1-docs.md`, "A gate in front of the seam").
`tests/test_schema.lua` drives the refusal through the `/pc set` dispatcher.

Dropping trailing conversions is allowed and deliberately so: `string.format` ignores surplus
*arguments*, so a shorter format is safe. Asking for one more conversion than the caller passes is the
raise this gate exists to stop, and nothing downstream can catch it — the Preview synthesizes its
sample arguments **from the format**, so it renders a surplus `%s` happily and reports success, and the
error then lands inside Blizzard's chat handler on every matching message.

The comparison is against **this addon's shipped default**, not Blizzard's live string.
`tests/test_defaults.lua` already pins every shipped default as a positional prefix of Blizzard's, so
prefix-of-default composes into prefix-of-Blizzard; and unlike `_G[GLOBALNAME]`, a default cannot have
been overwritten by this addon's own `ApplyStrings` by the time it is read. The cost is that a player
cannot restore a conversion one of the four sanctioned truncations dropped — lengthening the shipped
default is how to give that back.

The `NS.Debug("Set", …)` line is the single settings-change trace (debug-logging-§10): a no-op unless `/pc debug on`, and when on it logs exactly one `[Set] <path> = <value>` line per write (value via the shared `Schema.FormatValue`, so it reads like `/pc get`). The `ApplyStrings` re-apply it triggers is an implied consequence and is deliberately **not** re-echoed.

Both surfaces go through the same row's `set()`:

- **Panel widget callbacks** in `settings/Panel.lua` call `NS.Schema.Set(path, val)`.
- **`/pc set`** goes through `LibKa0s-Slash-1.0`'s `CliSet`, which parses the value through the descriptor's `parse` hook and then calls the descriptor's `set`, the runtime's `Set` itself.

Row `set()` closures are pure DB writes — they do **not** run `ApplyStrings` or `NotifyPanelChange` themselves. Both side effects are the write seam's `announce`, and `Schema.ResetRows` pays them once per batch instead of N times. Callers must therefore never invoke `row.set(value)` directly; always go through one of the two.

### The batched entry: `Schema.ResetRows(rows, label)`

```lua
function Schema.ResetRows(list, label)
    -- first: keep only the rows the runtime's index owns that pass the signature gate;
    --        none left -> return 0, no bracket, no line
    -- then, inside NS.SchemaRuntime.BulkRun("reset", label, walk):
    --   for each kept row: before = row.get(); row.set(row.default)
    --                      if row.get() ~= before then S.BulkAdd(1) end   -- N by read-back
    --   once: ApplyStrings (unless every row was session-only),
    --         NotifyPanelChange(the rows' shared category, or nil for every page)
    -- the bracket's close logs "[Set] reset <label>: N rows"; a raise anywhere in walk
    --        still gets that one line, ending " (stopped by an error)", then is raised again
end
```

It restores a list of rows to their defaults through the same `set()` step and the same gates `Schema.Set` uses, then pays the side effects once: one `ApplyStrings` pass, one panel refresh and one `[Set] reset <label>: N rows` line in place of a `[Set]` line per row (debug-logging-§10: a bulk reset is one `[Set]` line). N is the rows the reset actually changed. A row already at its default is still written, a no-op, but is not counted, and a reset with nothing to change still logs its one line as `: 0 rows`. Driving 170 rows through `Set` one at a time would cost 170 passes over 79 globals and 170 console lines. Returns N.

A reset that raises partway (a row's `set()`, the pass or the refresh) still writes its one line, counting the rows changed before the raise and ending in ` (stopped by an error)`, for example `[Set] reset Loot: 2 rows (stopped by an error)`. The error is then raised again. Both are the schema runtime's bulk bracket (`LibKa0s-Schema-1.0`'s `BulkRun` / `BulkAdd`, issue #18): the walk runs under a plain `pcall`, the bracket's close writes the marked line, and `BulkRun` re-raises the same error value unchanged. With LibKa0s absent the host's stub brackets and re-raises the same way and logs nothing, as the degraded `NS.Debug` does.

`Schema.NotifyPanelChange(category)` dispatches to a refresher closure that `settings/Panel.lua` registers for the category tab it has just drawn, via `Schema.RegisterRefresher(category, fn)`. The closure re-syncs every visible widget on that tab from the DB. Master-toggle changes (category `"General"` or `nil`) cascade to every registered refresher since per-string disabled state depends on the master. This keeps the panel and the slash UI from ever drifting — a `/pc set` while the panel is open updates both surfaces in the same frame. At most one category has an entry at a time: the visible tab. A tab that is not on screen has none, and that is correct — it is rebuilt from the live DB the moment it is selected, so it cannot show stale state.

### Auto-clear on default

Every stored row's `set` closure writes its default as an **absence**: a value equal to the row's default clears the key instead of storing it. For `string_format` rows that means the override entry:

```lua
if v == NS.Defaults[category].strings[globalName].default then
    local catDB = existingCategoryDB(category)            -- clearing never creates
    if catDB and catDB.strings then catDB.strings[globalName] = nil end
else
    local catDB = PrettyChat:EnsureCategoryDB(category)
    if not catDB.strings then catDB.strings = {} end
    catDB.strings[globalName] = v
end
pruneCategoryDB(category)
```

The same rule covers `General.enabled` (stored only as `false`), `General.visibility` (stored only when not `always`), `<Category>.enabled` (stored only when it differs from the shipped default) and `<Category>.<NAME>.enabled` (stored only as `disabledStrings[NAME] = true`). `pruneCategoryDB` then drops a `strings` or `disabledStrings` table the write emptied, and the category table once nothing is left in it.

So writing a format back to its default value via `/pc set` or the panel acts as a per-string reset: the override entry is removed from `db.profile.categories[Cat].strings`, and `GetStringValue` falls back to the default on next read. It is also why a reset through `Schema.ResetRows` leaves no category table at all, provided every stored key has a row. The load pass guarantees that: `Database.PruneOrphans` (see [Reset semantics](#reset-semantics)) drops any key no row owns. The `strings` table never collects "override that happens to equal the default".

## Public API

| Function | Purpose |
|----------|---------|
| `Schema.RowsByCategory(category)` | Filtered subset for one category. Used by `/pc list <Category>` and the no-arg `/pc list` (iterating `CATEGORY_ORDER`); also used by `schemaReady()` as the presence-check sentinel for "is the schema fully built?". |
| `NS.SchemaRuntime` | The `LibKa0s-Schema-1.0` instance over `rows` (or the host stub's, with LibKa0s absent). Its members are dot-called and are what the Options and Slash descriptors take as values. |
| `NS.SchemaLib` | The library the runtime came from: `LibStub("LibKa0s-Schema-1.0")`, or the host's write-completing, log-silent degradation stub. `tests/test_surface_parity.lua` pins the stub's surface against both levels of the library. |
| `Schema.FindByPath(path)` | The runtime's `FindRow`: an indexed lookup; returns the row or `nil`. First-registered wins on a duplicate path, and no path is declared twice (`tests/test_schema.lua` runs the library's `Validate` to zero). |
| `Schema.Get(path)` / `Schema.Set(path, value)` | The runtime's `Get` / `Set`: read/write through the row's closures. `Set` returns `false, err` if the path is unknown, `false, err, why` **if a `string_format` write fails the conversion-signature gate** (see [Single write path](#single-write-path)), and `true` when the write landed. No caller reads past the first value. |
| `Schema.AllRows()` | The runtime's `AllRows`: every row in **declaration** order — the order `/pc list` prints and the order the settings tree shows. Returned as the live table, not a copy. The `allRows` both the Slash and the Options descriptors are handed. |
| `Schema.ApplyDefault(row)` | The runtime's `ApplyDefault`: restore **one** row to a copy of `row.default` through `Set`, so the `[Set]` trace, the re-apply and the panel refresh are identical to a checkbox click. A row with no default is not restored, which is why the console row declares `false`. Deliberately **not** the implementation behind the Categories page's Defaults button or `/pc resetall` — both of those are bulk (see [Reset semantics](#reset-semantics)). |
| `Schema.ResetRows(rows, label)` | The write helper's **batched** entry: restores each row to `row.default` through its `set()` behind `Set`'s gates, then runs one `ApplyStrings` pass, one `NotifyPanelChange` and one `[Set] reset <label>: N rows` line, N the rows it changed (debug-logging-§10). A raise partway still writes that line, ending ` (stopped by an error)`, then raises again. Returns N. Called by `PrettyChat:ResetCategoriesPage` (the Categories page's Defaults button), `PrettyChat:ResetCategory` and `PrettyChat:ResetString`. |
| `Schema.CountChangedRows()` | The runtime's `CountOffDefault`. The rows a whole-profile reset would rewrite: every stored (non-`sessionOnly`) row whose value differs from its default. `PrettyChat:ResetAll` counts with it **before** `db:ResetProfile()`, because afterwards every row reads as its default. |
| `Schema.FormatValue(row, value)` | **The** value formatter, and there is exactly one of it (slash-commands-§5). The rendering is `LibKa0s-Slash-1.0`'s `FormatValue`; what is this addon's is the one thing the library cannot know — a Blizzard format string is full of `\|c…\|r` escapes, so `\|` is doubled to `\|\|` on the way out, matching what the panel's New box shows and accepts. Two consumers, and that is why it lives here rather than in `settings/Slash.lua`: every `list` / `get` / `set` / `reset` echo (as the Slash descriptor's `format` hook) **and** the `[Set]` debug trace at the write seam (debug-logging-§10), so a value cannot read one way in chat and another in the console log. With the library absent it falls back to the pre-library rendering — no color codes, no `key = value` shape. |
| `Schema.ResolveCategory(name)` | Case-insensitive PascalCase resolver — `/pc reset loot` finds `Loot`. Returns `nil` for unknowns. |
| `Schema.NotifyPanelChange(category?)` | Invokes the closure registered for `category` via `RegisterRefresher`. Pass `nil` (or `"General"`) to fire every registered refresher. Safe to call before any tab has been drawn — unregistered categories are no-ops. |
| `Schema.RegisterRefresher(category, fn)` | Registration hook: `settings/Panel.lua`'s `buildCategoryBody` registers one closure for the category tab it has just drawn, and `buildCategoriesBody` drops every category's entry (`fn = nil`) before it draws. The closure re-syncs every visible widget on that tab from the DB. |
| `Schema.CATEGORY_ORDER` | Display order array. Imported by `settings/Panel.lua` (tab-strip order on the Categories page, minus the virtual `General`), `modules/Override.lua`'s `Test()` and `settings/Slash.lua`'s `/pc list` (iteration order). The single source of truth — iterating `pairs(NS.Defaults)` would give a non-deterministic order. |

## Reset semantics

Three reset verbs on `PrettyChat`. The first two write through the helper's batched entry, `Schema.ResetRows`:

- **`PrettyChat:ResetString(category, globalName)`** resets **both** per-string rows for one string, `<Cat>.<NAME>.enabled` and `<Cat>.<NAME>.format`, so the custom format (`strings[NAME]`) and the disable flag (`disabledStrings[NAME]`) both clear. That matches the full-reset semantics of the two below. Resetting only the format would leave a previously-disabled string half-reset. One `ApplyStrings` pass, one `Schema.NotifyPanelChange(category)`, one `[Set] reset <Cat>.<NAME>: N rows` line.
- **`PrettyChat:ResetCategory(category)`** is the public per-category method; no panel button calls it and `/pc` never did. It resets every row of one category (`Schema.RowsByCategory`). A reset writes rows, so on its own it would leave behind any stored key no row owns, for example an override for a global string a later version removed. The load pass removes those keys first. `Database.RunMigrations` (`core/Database.lua`) runs `Database.PruneOrphans` at `OnInitialize` and on every profile change, copy and reset. It drops every `strings[NAME]` with no `<Cat>.<NAME>.format` row and every `disabledStrings[NAME]` with no `<Cat>.<NAME>.enabled` row, then prunes the tables that empties (savedvariables-§1). So a category reset leaves no `db.profile.categories[Cat]` table behind. Special case: `category == "General"` is the virtual category, which owns the two addon-wide keys and no entry under `db.profile.categories`. It resets the two stored rows `General.enabled` and `General.visibility` (never the session-only `state.debugConsole`), which clears `db.profile.enabled` and `db.profile.visibility` back to `nil` (default true / `always`). The visibility row's own `set()` re-runs `SyncCombatWatch`, which drops the combat watcher's events if the outgoing mode was a combat-scoped one. One `ApplyStrings` pass, one `Schema.NotifyPanelChange(category)`, one `[Set] reset <Cat>: N rows` line.
- **`PrettyChat:ResetAll()`** is a **profile reset** (`options-ui-§12`): one `db:ResetProfile()` on the active profile, never a second walk of the schema and never a touch on another profile. It clears nothing by hand — AceDB empties the profile in place, merges the defaults back and fires `OnProfileReset`, and it is `core/PrettyChat.lua`'s handler for that callback that re-runs the migrations, calls `SyncCombatWatch`, re-applies every string, calls `Schema.NotifyPanelChange()` (nil → every category) and emits the one `[Set] reset profile '<name>' to defaults (N rows)` line (debug-logging-§10). `ResetAll` counts N with `Schema.CountChangedRows()` before the wipe and parks it on `pendingReset` for the handler. A reset AceDB starts on its own logs the same line without the count. A profile copy is one `[Set] copied profile 'A' → 'B'` line from the `OnProfileCopied` handler. A reset or copy that raises still writes its one line, ending in ` (stopped by an error)`, and the error goes on up. The handler writes it when its reload raises, and marks `pendingReset` so `ResetAll` adds no second line. `ResetAll` writes it only when the raise comes from inside AceDB before the callback fires, counting what the wipe had changed by then. A stored key a later version adds beside `enabled` / `categories` is therefore reset too, which the old two-key hand-clear did not do.
- **`PrettyChat:ResetCategoriesPage()`** is the Categories page's **Defaults** button (and the footer control forwarded to it). It is page-wide (`options-ui-§13`): the rows of every category in `CATEGORY_ORDER` except the virtual `General`, handed to `Schema.ResetRows` as one batch under the label `Schema.CATEGORY_PAGE`. One `ApplyStrings` pass, one `Schema.NotifyPanelChange()` (the rows span categories, so every page), one `[Set] reset Categories: N rows` line.

They are reachable from:

- The per-string `Reset` button on each panel row (`ResetString` — always visible, a no-op when the string is already at default), the `Categories` page's `Defaults` button (`ResetCategoriesPage`, in the page header, acting on every category tab — no popup confirm), and the `Master controls` tab's composed "Reset all settings" button and the General page's header `Defaults` button (both gated by the `PRETTYCHAT_RESET_ALL` StaticPopup, through `PrettyChat:ConfirmResetAll`).
- `/pc reset <path>` (one row, through `Schema.ApplyDefault` → the single write seam) and `/pc resetall` (no in-chat confirmation — typing the command is itself the assertion). There is no category-scoped reset in chat or on the panel; `/pc reset` has taken a path rather than a category since `LIBKA0S-10`.

## SavedVariables shape

```
PrettyChatDB.profile.enabled                                         -- bool (addon-wide master toggle; nil = default true)
PrettyChatDB.profile.categories[catName].enabled                     -- bool (nil = default true, sourced from NS.Defaults[Cat].enabled)
PrettyChatDB.profile.categories[catName].strings[globalName]         -- string override (nil = use PrettyChat default)
PrettyChatDB.profile.categories[catName].disabledStrings[globalName] -- true = disabled (absent / nil = enabled)
```

**`enabled` defaults follow the `nil → true` contract.** Neither the addon-wide master toggle nor per-category `enabled` flags appear in the `defaults` table — they're created on first user write and read via `IsAddonEnabled` / `IsCategoryEnabled` which return `true` when the value is `nil`. This keeps SavedVariables empty until the user disables something, and it makes `ResetCategory` coherent: writing the default clears the flag (`= nil`), which genuinely returns it to default-true rather than relying on AceDB to re-merge a populated default.

Only user-modified values are stored. The schema's auto-clear keeps `strings[...]` lean — it never collects "override that happens to equal the default".

`db.profile.categories[catName]` is created lazily by `EnsureCategoryDB` on first write. `disabledStrings` and `strings` sub-tables are created lazily inside the row's `set()` closures, and dropped again by the same closures once a write empties them. So is the category table.

### Profiles

Profiles use AceDB with a single shared `Default` profile:

```lua
self.db = LibStub("AceDB-3.0"):New("PrettyChatDB", defaults, true)
```

The third arg (`true`) selects the `Default` profile name for every character. All characters on the account see the same configuration out of the box.

`AceDBOptions-3.0` (per-character / per-class / per-realm profile UI) is **not** wired in. Adding it is a small contribution: register the AceDBOptions table as a third `PrettyChat_Profiles` sub-page in `settings/Panel.lua` (library-drawn, and deliberately never tabbed). See [scope.md](./scope.md#out-of-scope) for why it isn't there today.

## Build sequence

Schema construction runs once at file-load (`settings/Schema.lua`). The order matters:

1. For each `category` in `CATEGORY_ORDER` (skipping `General`):
   - `buildCategoryRow(category)` — adds `<Cat>.enabled`.
   - For each `globalName` in `NS.Defaults[Cat].strings` (sorted alphabetically): `buildStringRows(...)` — adds `<Cat>.<NAME>.enabled` *and* `<Cat>.<NAME>.format`.
2. `Schema.InstallMasterControls(NS.Helpers)` — called from `settings/OptionsSetup.lua`, the **next** TOC entry, because the composers live on the Options instance and it does not exist yet while `settings/Schema.lua` is running. It calls `H.MasterControls(MASTER_SPEC)`, stamps each returned row with `category = "General"` and this addon's `kind` / `get` / `set`, and splices them in at the **head** of `rows` — which is what makes `Master controls` the General page's first tab and what puts those rows at the head of `/pc list`. The hook that draws the group's closing button comes back on `Schema.masterAfterGroup`. A canonical leaf the library emits that this addon has **not** wired is never installed as a control that reads and writes nothing; it is reported at load through the same channel an unresolved path takes.
3. `runValidation()` runs again after the splice, so `Schema.validation` describes the schema the addon actually runs rather than one three rows short of it.

Every row carries a `page` and a `group`; the group is the tab the row is drawn under (options-ui-§13). The category rows are not rendered through the flow engine — the `Categories` page hands `H.TabStrip` its tab list directly — but they declare the partition anyway, and `tests/test_schema.lua` asserts that no row is missing either field.

Closures bind to live values: `NS.Defaults` is populated by `defaults/Defaults.lua` (loaded earlier by the TOC) and the addon object exists (`core/PrettyChat.lua`'s `:NewAddon` ran before `settings/Schema.lua`).
