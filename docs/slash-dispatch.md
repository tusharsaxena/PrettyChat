# Slash commands

`/pc` and `/prettychat` are aliases for the same dispatcher. Dispatch, the help renderer, the landing rows, the `key = value` and command-row formatters, the type-aware parser and the `list`/`get`/`set`/`reset` verbs are **`LibKa0s-Slash-1.0`'s** (`settings/Slash.lua` builds one instance from a descriptor); what stays here is the `COMMANDS` table and four verbs. All chat output is prefixed with the cyan `[PC]` tag via `NS.Print`.

This doc covers: the dispatch shape, the full command reference, and the `||` ↔ `|` chat-input escape that bites users on `/pc set` for format strings.

## The `COMMANDS` table

`settings/Slash.lua` defines an ordered table near the top of the file:

```lua
local COMMANDS = {
    {"help",     "...", function()     Sl:PrintHelp()   end},
    {"config",   "...", function()     PrettyChat:OpenConfig() end},
    {"version",  "...", function()     Sl:CliVersion()  end},
    {"list",     "...", function(rest) listSettings(rest) end},
    {"get",      "...", function(rest) Sl:CliGet(rest)  end},
    {"set",      "...", function(rest) Sl:CliSet(rest)  end},
    {"reset",    "...", function(rest) runReset(rest)   end},
    {"resetall", "...", function()     runResetAll()    end},
    {"test",     "...", function(rest) runTest(rest)    end},
    {"debug",    "...", function(rest) runDebug(rest)   end},
}
```

Entries are **positional triples** — the library reads `entry[1]` / `[2]` / `[3]`, and a table of named fields is silently invisible to it: every verb becomes unknown and the help block renders empty. The handler takes `rest` alone.

The table drives **both** dispatch and help, and the settings landing page renders the same table through `Sl:LandingRows()`. Adding a command means adding one row — help text, dispatch and the panel never drift.

**Why the table stays the host's** (slash-commands-§3): the addon's landing page renders it, so a library that owned it would force the options library to consume the slash library — a real dependency cycle between two majors at load time. The table crossing between them as plain data is what keeps them independent.

`Sl:OnSlash(input)` parses `<verb> <rest>`, lowercases **only the verb**, and preserves case *and* internal spacing in `rest` — so dot paths like `Loot.LOOT_ITEM_SELF.format` survive, and so do the spaces inside a format string. Unknown verbs print `unknown command '<verb>'` and then the help index.

## The two descriptor hooks

Two of this addon's shapes are not the library's default, and both are handled at the one descriptor seam rather than by forking anything:

- **`format`** (Slash minor 5) doubles `|` to `||` on every list/get/set/reset echo. A Blizzard format string is full of `|c…|r` color escapes; printed raw they *color* the chat line instead of appearing in it, so `/pc get Loot.LOOT_ITEM_SELF.format` would show a colored fragment rather than the text the user is editing. The hook delegates to `lib.FormatValue` first and only post-processes strings, so bools and the empty-string `(none)` case stay the library's.
- **`parse`** keeps the whole remainder for a `string` row. `lib.ParseValue` splits on whitespace and takes `args[1]`, so `/pc set <path> You receive loot: %s` would store `"You"`. It also unescapes `||` → `|`, mirroring `format` on the way out and the panel's New box on both, so a value copied out of `/pc get` and pasted into `/pc set` round-trips.

## Command reference

| Command | Effect |
|---------|--------|
| `/pc` / `/pc help` | Print the help index via `NS.Print`. Header line includes the addon version (`v<VERSION>`, read from TOC `## Version:` at file load via `NS.Version()` — the `core/EnvSetup.lua` seam over `LibKa0s-Env-1.0`, falling back to `NS.version` and then `"?"`). |
| `/pc config` | Open the Blizzard settings panel to the parent page and auto-expand the addon's sub-category tree so both sub-pages (General, Categories) are visible in the left rail without clicking the disclosure arrow. **Refuses during combat** (`InCombatLockdown()`) — Blizzard's category-switch is protected and would taint the panel. Prints a notice and stops if combat is active. |
| `/pc version` | Print `v<version>` via `NS.Print`. |
| `/pc list` | List every setting and its current value, grouped by category (~170 lines). Output follows the mandated color scheme (slash-commands-§5): a green "Available settings" header, azure `[Category]` group headers, and gold-key `=` white-value rows via the shared `FormatKV` + `Schema.FormatValue`. With ~170 rows the output is long, but it's the only way the slash UI reaches parity with the panel (which exposes a toggle and a format edit-box per string). |
| `/pc list <Category>` | Filter to one category. Case-insensitive (`/pc list loot` works). Prints the category toggle + every per-string `.enabled` and `.format` row. Unknown categories print the valid list. |
| `/pc list category` | Reserved sub-keyword: print every category name in alphabetical order, with a count header. The two reserved keywords (`category`, `formatstring`) are intercepted **before** the category-name path — neither is a valid category name, so the lookup is unambiguous. |
| `/pc list formatstring` | Reserved sub-keyword: print every `Category.GLOBALNAME` pair, sorted by category then by global name, with a count header. Useful for finding the exact case-sensitive name to pass to `/pc test formatstring <NAME>` or `/pc set <Cat>.<NAME>.format ...`. |
| `/pc get <path>` | Print one row's current value as the single-line `path = value` form (e.g. `/pc get Loot.LOOT_ITEM_SELF.enabled` or `/pc get General.enabled`), via the shared `FormatKV` + `Schema.FormatValue`. |
| `/pc set <path> <value>` | Write one row through `NS.Schema.Set`, then echo the stored value back in the same `path = value` form. `bool` accepts `true/false/on/off/yes/no/1/0`; `string` consumes the rest of the line literally. For `string_format` rows, setting `<value>` to the row's PrettyChat default clears the override (see [schema.md](./schema.md#auto-clear-on-default)). |
| `/pc reset <path>` | Reset **one** setting to its default, through the same write seam a panel checkbox takes, and echo the stored value. **Breaking change (`LIBKA0S-10`):** this verb used to take a *category*. A page is a property of a settings panel, not of the data, and every category page already carries a **Defaults** button that resets it — so the capability did not move, only its CLI route (slash-commands-§2). Typing the old form is intercepted and answered with both replacements rather than with "Setting not found". |
| `/pc resetall` | Reset the **active profile** to the addon's defaults — `PrettyChat:ResetAll()` is `db:ResetProfile()` (options-ui-§12), so every category's overrides, the addon-wide `enabled` flag, the stored `General.visibility` and anything a later version stores beside them go together. Other profiles are untouched. No in-chat confirmation — typing the command is itself the assertion. |
| `/pc test` / `/pc test all` | Print a per-category Original-vs-Formatted diff for every format string. Output ignores enable toggles (same action as the General page's Test button). See [settings-panel.md](./settings-panel.md#the-test-preview). |
| `/pc test category <name>` | Filter the diff to one category. Case-insensitive name with the same unambiguous-prefix lookup as `/pc reset` (`Schema.ResolveCategory`). |
| `/pc test formatstring <NAME>` | Filter the diff to a single global. Input is uppercased then validated against `NS.Defaults`. Globals registered under more than one category (e.g. `LOOT_ITEM_CREATED_SELF`) print under each — both registrations are shown. |
| `/pc debug` / `/pc debug on` / `/pc debug off` | Drive the on-screen debug console (`core/DebugLogSetup.lua`). **Bare `/pc debug` toggles the console window** (the session logging state is unchanged) so capture can run with the window closed and be opened after the fact. `on` / `off` set the session logging flag `NS.State.debug` (default off, never persisted) through the single `NS.DebugLog:SetEnabled(on)` seam. Gates `NS.Debug(tag, fmt, …)`, which is a zero-alloc no-op when off and otherwise appends to the console. |
| unknown command | Print the help index (with an "unknown command" warning first). |

Output is colored: yellow (`|cffffff00`) for command names via the shared `NS.Util.cmd()` helper, white (`|cffffffff`) for explanatory notes via `NS.Util.note()`. The header line includes the version banner.

## Edit-box pipe escaping

WoW chat input interprets `|c…|r` as inline color escapes the moment the user presses Enter. To send a literal `|` through `/pc set`, the user must type `||`. So setting a format string from chat looks like:

```
/pc set Loot.LOOT_ITEM_SELF.format ||cffff0000Loot||r | ||cff93c47dYou||r | + %s
```

The settings panel's format input box wraps this internally — `settings/Panel.lua`'s edit-box `get` does `:gsub("|", "||")` and `set` does `:gsub("||", "|")`, so users see double-escaped strings while editing but `NS.Schema` always stores raw single-`|` format strings. `/pc set` users still have to **type** `||`, but the value is un-escaped on the way in by the descriptor's `parse` hook (`settings/Slash.lua`, `text:gsub("||", "|")`) — the mirror of the `format` hook on the way out — so what lands in `NS.Schema` is the same raw single-`|` string the panel stores, and a value copied out of `/pc get` pastes back into `/pc set` unchanged.

`/pc get` output renders with colors applied (single `|` is sent through `NS.Print` → `DEFAULT_CHAT_FRAME:AddMessage`, which interprets the escapes).

This is why the settings panel is the recommended editing surface for format strings — the `||` boundary is hostile to direct chat editing. `/pc set` is a power-user path.

## Per-command internals

Each command body is a small file-local function in `settings/Slash.lua`:

| Function | Responsibility |
|----------|----------------|
| `Sl:PrintHelp()` | The library's. Header (`v<ver> — slash commands`, plus the alias clause) then `HelpRows()` — one `lib.FormatRow` line per `COMMANDS` entry, indented two spaces. |
| `Sl:CliList()` / `Sl:CliGet` / `Sl:CliSet` | The library's. Green header, azure `[group]` headings from the descriptor's `groupKey` (this addon's `row.category`), and gold-key `=` white-value rows via `lib.FormatKV`. Values render through the descriptor's `format` hook, so a stored `\|` shows as `\|\|`; input parses through the `parse` hook, so a value keeps its spaces. `set` re-reads after writing so any coercion is reflected. |
| `listSettings(rest)` | Host-owned, for the three forms `CliList` cannot express. Two reserved sub-keywords are intercepted before category resolution: `category` prints a sorted list of category names, `formatstring` prints every `Category.GLOBALNAME` pair sorted by category then by name. An empty `rest` **delegates to `Sl:CliList()`**; a category name resolves via `NS.Schema.ResolveCategory` and renders through `Sl:Text("LIST_GROUP")` and `lib.FormatKV` — the same renderer, never a second copy of the shape. |
| `runReset(rest)` | Intercepts a bare **category** name and answers with the deprecation plus both replacements (`LIBKA0S-10`); everything else goes to `Sl:CliReset(rest)`, which resets one row through `Schema.ApplyDefault` and echoes it. |
| `runResetAll()` | Call `PrettyChat:ResetAll()` — the bulk implementation: one `db:ResetProfile()`, and the re-apply plus the single `[Reset] all → applied N restored M` summary land on `core/PrettyChat.lua`'s `OnProfileReset` handler. Deliberately **not** `Sl:CliResetAll`, which is row-by-row over ~170 rows and would emit one `[Set]` line each into a 1500-line console buffer (debug-logging-§9). No in-chat confirmation. |
| `runTest(rest)` | Parse the first whitespace-separated token. Empty or `all` → `PrettyChat:Test()` (every string). `category <name>` → resolve via `Schema.ResolveCategory`, then `Test({kind="category", value=matched})`. `formatstring <NAME>` → uppercase input, validate against `NS.Defaults`, then `Test({kind="formatstring", value=upper})`. Bad sub-token prints a four-line usage. |
| `runDebug(rest)` | Bare / `toggle` → `NS.DebugLog:Toggle()` (show/hide the console window, logging state unchanged). `on` / `off` → `NS.DebugLog:SetEnabled(true/false)` (session logging flag). Other input prints a `usage:` hint. |

`schemaReady()` guards each schema-touching command — prints `"schema not ready yet"` if `NS.Schema` hasn't loaded (shouldn't happen in practice given the TOC load order, but cheap to check).

## Why no chat-side confirm popup for resets

The slash command itself is the assertion. In the panel, the per-category **Defaults** header button has no popup confirm (a category reset is one click, recoverable by editing back), and the **Reset all settings** button on the `Master controls` tab is gated by the `PRETTYCHAT_RESET_ALL` StaticPopup because the global reset is destructive. Chat reset commands take more typing and rarely fire by accident, so they skip the confirm. If the asymmetry ever bites, add a `StaticPopupDialogs` confirmation in `runResetAll` — but don't add one mid-feature without a triggering complaint.

## What lives in the panel but NOT in the slash UI

Two things you can't reach via `/pc`:

- **Live sample of a saved value.** The panel's per-row Preview EditBox always renders `NS.RenderSample(currentValue)` and re-syncs on every commit. Slash users get an equivalent dump *after* `/pc set` lands, via `/pc test` (which prints every format, not just the changed one — narrow it with `/pc test formatstring <NAME>`).
- **Visual diff between Original and New.** The panel renders both side-by-side per row. Chat users would need `/pc get` against the format row plus an external GlobalStrings reference.

The per-string **Reset** button (always visible on the row; `PrettyChat:ResetString`, clearing both the custom format and the disable flag) is reachable from chat as `/pc reset <path>`. The per-category **Defaults** header button is **not** — it is now the only category-scoped reset, which is where a page-scoped concept belongs (slash-commands-§2). These remaining gaps are by design — the panel is the editing surface, slash is for scripted / power-user workflows.
