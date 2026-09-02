# Settings panel

`settings/Panel.lua` builds the settings panel directly on Blizzard's modern `Settings.RegisterCanvasLayoutCategory` / `Settings.RegisterCanvasLayoutSubcategory` API and renders body content with AceGUI. PrettyChat appears under **Ka0s Pretty Chat**; the parent page hosts the logo, tagline, and slash-command list (read-only orientation), and **two** sub-pages hold the actionable controls.

**Every page draws a strip** (options-ui-§13), and the `Categories` page draws two — a primary strip of message categories, and inside each of those, a secondary strip with one tab per format string.

| Page | Primary tabs (strip order) | Secondary tabs | Rows |
|---|---|---|---|
| `General` | `Master controls` | — | 3 |
| `Categories` | Loot (39), Currency (9), Money (17), Reputation (29), Experience (41), Honor (13), Tradeskill (17), Misc (5) | one per format string: Loot 19, Currency 4, Money 8, Reputation 14, Experience 20, Honor 6, Tradeskill 8, Misc 2 | 170 |

Row counts are schema rows (`Schema.RowsByCategory`), i.e. one category `enabled` plus two per format string, and are pinned by the page/tab partition case in `tests/test_schema.lua`. Every tab's controls are the same shape, so the numbers are the only thing that differs between them. **Every row carries a `page` and a `group`** — the group IS the tab it is drawn under — which `tests/test_schema.lua` also pins; a page whose rows carry no group is reported by the library and rendered strip-less.

The primary strip is `H.TabStrip`'s and the secondary one is `H.SubTabStrip`'s (options-ui-§13). The primary strip replaced eight sub-pages — one per category — in the pass recorded in [scope.md](./scope.md#resolved-decisions); what survived of that decision, and what did not, is written out there.

The `General` page drew **no strip at all** until this pass: one group, one row, `H.RenderRows`. A one-group page draws a one-tab strip as of `OptionsWidgets` minor 13, and this page is why the rule matters — it was the page that read as broken beside `Categories` rather than as simpler.

This doc covers: the canvas-layout framework, the unified per-page header, the `General` page's `Master controls` tab, the `Categories` page's two strips, the per-string editor, the Test button, and the color palette.

## Canvas-layout framework

The panel does not go through `AceConfigDialog:AddToBlizOptions` (the older path that auto-renders an AceConfig options table inside the addon's right pane). It is plain Blizzard `Frame`s with a unified header and an AceGUI `ScrollFrame` body — and since the LibKa0s adoption, all of that is **`LibKa0s-Options-1.0`'s**, reached through `NS.Helpers` (`settings/OptionsSetup.lua`). Every category (parent + sub-pages) shares the same header design and right-edge gutter as every other Ka0s addon, not merely as every other page here.

Registration: `settings/Panel.lua` queues one builder **per page** — two of them, `General` and `Categories` — with `H.RegisterOptionsPage(key, name, builder)` at **file load**. `NS.Config.RegisterPanels` is the library's `CreateOptionsPanel`, called from `PrettyChat:OnEnable`; it resolves AceGUI, registers the parent canvas category, and drains the queue. Each builder creates its canvas with `H.CreatePanel(nil, category, opts)`, declares how the page draws itself with `H.SetRenderer(ctx, fn)`, and returns its `Settings.RegisterCanvasLayoutSubcategory` handle.

The category handle is the library's own business now — `PrettyChat.optionsCategory` / `optionsCategoryID` are gone, and `PrettyChat:OpenConfig()` is a one-line delegate to `H.OpenOptionsPanel()`, which owns the combat gate and the left-tree expansion ([`LIBKA0S-04`](https://github.com/tusharsaxena/PrettyChat/issues/9)). A host needing a live page context uses the `H.__panelFor(pageKey)` test seam.

`SetRenderer` owns **when** a page draws: its first `OnShow` — at registration time the body's frame width is zero, and AceGUI's `List` layout sizes children against the container's current width, so building too early produces a stack of misaligned widgets — and again after a refresh flagged it dirty while hidden. It also builds the Defaults button on **every** `OnShow` (outside the rendered guard) and refuses to render under combat lockdown.

## Unified per-page header

The library's `CreatePanel` stamps every page with the same layout, and hosts **MUST NOT** hand-build a header (options-ui-§5):

| Element | How |
|---------|-----|
| Title FontString | `GameFontNormalHuge`, anchored TOPLEFT at `(PADDING_X, -HEADER_TOP)` |
| Atlas divider | `Options_HorizontalDivider`, full-width minus padding, tinted with `titleFS:GetTextColor()` so future theme retunes follow |
| Defaults button (optional) | AceGUI `Button`, anchored TOPRIGHT at `(-PADDING_X, -HEADER_TOP)`, width `DEFAULTS_W` |

The parent page renders its title plain (`"Ka0s Pretty Chat"`) via `opts.isMain = true`. Sub-pages prefix the title to read as a breadcrumb: `"Ka0s Pretty Chat ▸ Loot"`. The chevron is an inline-atlas escape (` |A:common-icon-forwardarrow:16:16|a `) so it renders as a real texture, not a font glyph — font-agnostic and locale-safe. If a future client retires the atlas, swap to `NPE_RightClick` or `chevron-collapse` (same escape syntax, just the atlas name changes). The Blizzard left-tree label always stays unprefixed (driven by `panel.name`) so the indented tree doesn't repeat the parent name.

All panel layout dimensions live in **`LibKa0s-Options-1.0`'s `LAYOUT` table**, not in this addon — options-ui-§8 forbids a host copy, because every Ka0s panel renders identically only if every panel reads one set of values, and a host copy is the copy that goes stale. Where `settings/Panel.lua` needs one for a widget it draws itself it reads it off the instance (`NS.Helpers.ROW_VSPACER` and `NS.Helpers.SECTION_HEADING_H` today; `BUTTON_PAIR_REL` is published too, and is applied for it by `InlineButtonPair`). The tab strip's own geometry (`CHROME_GAP`, `TAB_H`, `BANNER_H`) is published on the instance for a host that lays out a strip by hand; this addon lays out none — it hands `TabStrip` a tab list and the library places the buttons — so it reads none of the three. `core/Constants.lua` keeps only `SECTION_TOP_SPACER` / `SECTION_BOTTOM_SPACER` (the landing page's own body, which is the host's half) and `STRING_VSPACER` (the bespoke 40/60 editor, which the library has no equivalent for).

## Always-visible scrollbar

`NS.Helpers.PatchAlwaysShowScrollbar(scroll)` — the library's `OptionsScroll.lua`, applied automatically by `EnsureScroll` — rebinds the AceGUI ScrollFrame's `FixScroll` so:

- The scrollbar (and its 20 px right-side gutter) is shown on every page, regardless of overflow. Short pages (General) and long tabs (Experience, 20 strings) line up at the same right edge.
- When content fits, the thumb parks at the top, the scrollbar grays out, and mousewheel input is inert. When content overflows, the upstream FixScroll logic runs unchanged.
- On widget release, the original FixScroll / MoveScroll / OnRelease are restored so the AceGUI pool returns clean for any subsequent acquirer.

## The `General` sub-page and its `Master controls` tab

`General` is a *virtual category* — no entry in `NS.Defaults`, no per-string rows. It is built by `buildGeneralBody(ctx)`, which draws one explainer line and then hands the page to `H.RenderTabbedSchema`. Its one tab is `Master controls`, and **every control on it is composed, not hand-written**: `H.MasterControls` (`OptionsCompose 1`) owns the row set, its order and its wording, and `settings/Schema.lua` splices the result in at the head of the schema with the stored paths and defaults this addon already shipped.

**PrettyChat is frameless.** `grep -rn SetMovable core/ modules/ settings/` is empty — the addon draws no positionable frame of any kind — so the composer omits **exactly** master scale, master alpha and lock frame, and the closing button is `Reset all settings` alone with no `Reset position` beside it. Nothing else is omitted.

| Control | Stored path | Wire-up |
|---------|-------------|---------|
| Explainer label | — | One line, above the strip's content: Enable and General visibility are the two master dimensions. |
| **Enable PrettyChat** (left) | `General.enabled` | Master switch — when off, every Blizzard original is restored regardless of per-category settings. |
| **General visibility** (right) | `General.visibility` | The four canonical modes, `Always` / `Only in combat` / `Only out of combat` / `Never`. This addon's *display* is the chat text it rewrites, so the mode rides the same gate as Enable inside `ApplyStrings`: `Never` restores every original, and the two combat modes restore or re-apply at the combat boundary. Honoured by `PrettyChat:IsVisible` and `PrettyChat:SyncCombatWatch` in `modules/Override.lua`; stored only when it differs from `always`. |
| **Debug console** | `state.debugConsole` (session only) | Shows/hides the debug console **window** only (`NS.DebugLog:Show()` / `:Hide()`) — the same effect as bare `/pc debug`. It does **not** touch the debug logging flag; logging on/off stays owned by the window's header toggle and `/pc debug on\|off`. `Schema.Set` skips its `ApplyStrings` re-apply for this row because it is `sessionOnly`. The window's OnShow/OnHide fire `Schema.NotifyPanelChange("General")` so the checkbox tracks visibility however it changes (this box, `/pc debug`, the close button, Esc). |
| **Test** button | — | Runs `PrettyChat:Test(nil, sink)` with the debug console's writer, and opens the console. See [The Test preview](#the-test-preview). |
| **Reset all settings** button | — | The composer's own closing button, drawn by `Schema.masterAfterGroup`. Calls `PrettyChat:ConfirmResetAll()`, which raises the `PRETTYCHAT_RESET_ALL` StaticPopup; on confirm, `PrettyChat:ResetAll()` resets the active profile (options-ui-§12). |

`Test` sits **between** the composed rows and the canonical closing button, which is the one deviation this tab carries — recorded as the `options-ui-§15` row in [ARCHITECTURE.md](./ARCHITECTURE.md#documented-deviations).

**What moved here, and what was deleted to make room.** `Enable PrettyChat` was a hand-written row in `settings/Schema.lua`; it is composed now, at the same stored path. The `Debug console` checkbox was a bespoke `H.SessionCheckbox` drawn through `buildGeneralBody`'s `pairWith` seam and wired to `NS.DebugLog:ConsoleCheckbox()`; that declaration is **deleted**, and the console toggle is an ordinary schema row with exactly one declaration. `Reset all to defaults` was a hand-written half of an `H.InlineButtonPair`; it is the composer's `Reset all settings` now. Four locale keys left `locales/enUS.lua` with them.

The General sub-page does not show a `Defaults` button in the header — the in-body reset with its popup confirm is the only addon-wide reset surface, and showing both would be redundant.

## The `Categories` sub-page and its two strips

`buildCategoriesBody(ctx)` draws the whole page:

1. **The primary strip** — `H.TabStrip(ctx, { tabs, value, onSelect })`, one tab per message category, in `CATEGORY_ORDER` minus the virtual `General`. The tab order is *derived* from that array rather than restated, so the strip, `/pc list` and `/pc test` cannot disagree about what comes first. Loot leads because it is what a player opens the page to change; Misc trails because it is the drawer.
2. **One footnote line**, gray, above the controls: *"Strings on these tabs are rewritten only while the master Enable on the General page is on."* Every switch and every format box on every tab is inert while the master is off, and that toggle lives on the other page — a player who enables a category, sees nothing change in chat and has no sentence to explain it has been misled by the page rather than by the setting.
3. **The active tab's body**, `buildCategoryBody(ctx, scroll, category, catData)`:
   1. **Enable `<Category>`** checkbox, bound to the `<Cat>.enabled` schema row. It stays **above** the secondary strip, because it governs every string in the category rather than the one on screen.
   2. A 2× row spacer.
   3. **The secondary strip** — `H.SubTabStrip(ctx, host.frame, { tabs, value, onSelect })`, one tab per format string in `catData.strings`, sorted by global name, labelled with the string's friendly label and tooltipped with its `GLOBALNAME`.
   4. **One** per-string editor: the selected string's, and only that one.

### Why a second strip

A category tab used to be a vertical stack of up to twenty three-row editors — Experience is twenty, Loot is nineteen — so finding one string meant scrolling past every string sorted before it, and the page was a wall of identical boxes. One tab per string turns that into one click, and the tab *is* the block's name, which is why the `Heading` each block used to open with is gone (a heading repeating the tab you are standing on is the second name for one thing that `options-ui-§7` warns about).

It is drawn as **ordinary content inside the scroll**, not as a second pinned band: a division that is not page-wide must not push the whole page down twice, and the primary strip above it is the one thing that is page-wide. The buttons are parented to an empty full-width `SimpleGroup` the page adds as an AceGUI child; `H.ClearScroll` drains the library's `__subTabKids` ledger **before** `ReleaseChildren` returns that group to AceGUI's pool, so no button ever outlives the frame it was parented to.

**The selection is the host's state.** The library reads `spec.value`, calls `spec.onSelect`, and never looks at either again. `settings/Panel.lua` keeps it as `ctx.activeSubTab`, a **table keyed by the primary tab's category** — so leaving Loot for Experience and coming back returns you to the string you were on, and each category heals its own stale pointer to its first string. Session-only, never persisted: which string you last looked at is not a setting.

**Why not `H.RenderTabbedSchema` here.** That helper partitions a page's *schema rows* by `group` and hands each partition to the flow engine. A category tab is one schema row (the Enable) followed by a bespoke 40/60 editor the flow engine cannot express — the `options-ui-§6` deviation in [ARCHITECTURE.md](./ARCHITECTURE.md#documented-deviations). So the page takes both **strips** from the library and keeps generating its bodies per category, exactly as it did when each was a page. Every row on the page still *declares* its `page` and `group` (`settings/Schema.lua`), so the partition is readable and assertable even though the flow engine never sees it — and the day the editor can be expressed by the flow engine, the switch is a one-line change. The `General` page does go through `RenderTabbedSchema`. The tab click re-renders through the same `ClearScroll`-then-draw path `RenderTabbedSchema`'s own `onSelect` takes, and carries no combat guard for the same reason it does not: redrawing widgets inside an already-open panel was never a protected action.

**Refresher hygiene.** `Schema.refreshers` is keyed by *category*, not by page, so an entry left behind by the tab the player just left is a closure over released AceGUI widgets that the next master-toggle fan-out would still reach. `buildCategoriesBody` drops every category's entry before it draws, and the body it draws re-registers the one now on screen.

**The Defaults button** in the header resolves the **active tab** at click time — it is wired once, on the page's first show, and the strip moves underneath it — and calls `PrettyChat:ResetCategory(...)` directly, no popup confirm. Its tooltip therefore names the selected tab rather than a category: one button cannot carry eight wordings that are fixed at panel-build time. Per-row reset is preserved via the per-string `Reset` button (see below), and the master `Reset all settings` on General has the popup, so a Defaults click is a single recoverable action.

## Per-string block

The selected format string renders as a 3-row × 2-column grid inside the category panel. Its **`Heading` is gone** — the secondary tab that selects the string is its name now:

```
[Enable]            | Original [disabled EditBox]
GLOBALNAME (gray)   | New      [editable EditBox]
[Reset]             | Preview  [disabled EditBox]
```

| Row | Left (40%) | Right (60%) |
|-----|------------|-------------|
| 1 | `[Enable]` checkbox | Original format `EditBox` (disabled, `:SetLabel("Original")`), seeded from `NS.OriginalFormat(PrettyChat, globalName)` — the `OnEnable` snapshot of this client's `_G`, the same source `/pc test` prints (PC-R-04) |
| 2 | `GLOBALNAME` caption (gray) | New format `EditBox` (editable, `:SetLabel("New")`, commits on Enter) |
| 3 | `[Reset]` button | Preview `EditBox` (disabled, `:SetLabel("Preview")`, `NS.RenderSample` output) |

Each row is its own AceGUI `SimpleGroup` with `Flow` layout; the left child uses `:SetRelativeWidth(LEFT_W)` (`0.4`) and the right uses `:SetRelativeWidth(RIGHT_W)` (`0.6`), so the two columns align across all three rows. The right-column EditBox labels (`Original` / `New` / `Preview`) sit above each input via AceGUI's built-in label slot — left-column widgets vertically align with the EditBox itself, not the label.

State derived per block in the block's `refresh()` closure (run on first build and on every `Schema.NotifyPanelChange`):

- `[Enable]` checkbox: `enable:SetValue(strEnabled)` and disabled when master OR category is off.
- New format `EditBox`: `:SetText` from the schema; disabled when master, category, or per-string is off.
- Preview `EditBox`: always shows `NS.RenderSample(current)` — the rendered sample with sample args substituted in. The backing `InputBoxTemplate` FontString renders WoW `|c…|r` color escapes, so the preview shows with its formatting intact. On `string.format` failure, the error message is shown instead.
- `[Reset]` button: always visible. Clicking when the value already equals the default is a harmless no-op (the schema's auto-clear-on-default short-circuits to nil).

The new-format `EditBox` commits on `OnEnterPressed` through `NS.Schema.Set(formatPath, …)` after un-escaping `||` → `|`. The schema runs `PrettyChat:ApplyStrings()` and calls `Schema.NotifyPanelChange(category)`, which dispatches to the category's refresher (see below).

## Edit-box pipe escaping

WoW's chat input interprets `|c…|r` as inline color escapes the moment Enter is pressed, so a raw `|` typed into the edit box would be eaten. The new-format input wraps `|` ↔ `||` at the UI boundary:

```lua
:SetText(current:gsub("|", "||"))                         -- on read
NS.Schema.Set(formatPath, value:gsub("||", "|"))          -- on commit
```

`NS.Schema` always stores raw single-`|` format strings. The disabled Original input shows the doubled form too (read-only — the user never sends it back through chat input). `/pc set` users have to type `||` themselves; see [slash-dispatch.md](./slash-dispatch.md#edit-box-pipe-escaping).

## NotifyPanelChange refresh dispatch

**Two refresher registries coexist, and `Schema.NotifyPanelChange` is the one place that knows about both.**

- Every widget the library's own makers built registered a closure on its page's `ctx.refreshers`. `NS.Helpers.RefreshScalars()` runs those — the *in-place* tier: re-read the value, `SetValue` it, no rebuild.
- The bespoke 40/60 per-string blocks are drawn by hand and are invisible to that registry, so `buildCategoryBody` registers one closure per category through `Schema.RegisterRefresher`.

```lua
-- settings/Schema.lua
function Schema.NotifyPanelChange(category)
    -- The library's tier first: in place, re-reads only, so it cannot recurse back
    -- into Schema.Set.
    if NS.Helpers and NS.Helpers.RefreshScalars then
        NS.Helpers.RefreshScalars()
    end

    if category == "General" or category == nil then
        for _, fn in pairs(Schema.refreshers) do pcall(fn) end
        return
    end
    local fn = Schema.refreshers[category]
    if fn then pcall(fn) end
end
```

A `Schema.Set` from a panel widget or from `/pc set` reaches `Schema.NotifyPanelChange(row.category)`, which re-syncs both. `General` (or `nil`) fans out to every host refresher, because per-string disabled state depends on the master switch.

Master-toggle (`General.enabled`) changes cascade to both sub-pages because per-string disabled state depends on the master. Only the visible tab has a host refresher registered; the tabs behind it are rebuilt from the live DB the moment they are clicked, so there is nothing stale for them to show.

A tab that has never been drawn has no entry in `Schema.refreshers`. That's correct: it is built from the live DB the moment it is selected, so it cannot show stale state — there is nothing to refresh until it is on screen.

Programmatic `:SetValue`/`:SetText` on AceGUI widgets do **not** re-fire the user callbacks, so refresh is safe to call from inside a callback chain.

## The Test preview

Both the General page's "Test" button and the `/pc test` slash command call `PrettyChat:Test(filter, sink)` (in `modules/Override.lua`). The button calls it with no filter (every category, every string); the slash dispatcher (`runTest`) forwards `{kind="category", value=…}` or `{kind="formatstring", value=…}` for the subcommand variants. See [slash-dispatch.md](./slash-dispatch.md#command-reference) for the user-facing forms.

**They differ in exactly one thing: where the report lands.** `sink` is the output function every line goes through, and it **defaults to `NS.Print`** — so `/pc test` still writes to chat, one `[PC]`-prefixed line at a time, unchanged. The settings button passes the debug console's writer instead (`function(line) NS.DebugLog:Add("Test", line) end`) and opens the console first, because the full report is 500+ lines with every category enabled and the chat frame is the thing this addon exists to keep readable — a window with a scrollbar and a Copy button is what a report that long actually needs. `NS.Print`'s own destination is untouched: the sink is a parameter, not a redirection, which is why the two surfaces cannot drift into two different reports. `tests/test_override.lua` asserts the sunk report is byte-for-byte the printed one, header to footer.

The function:

1. Walks `Schema.CATEGORY_ORDER` (so output order matches the Categories page's tab strip). Per category, the strings table is sorted alphabetically by global name. The `filter` argument is applied at both layers — a category filter skips non-matching categories before iterating their strings, a formatstring filter is applied per-string and shows the global under every category it's registered in (so `LOOT_ITEM_CREATED_SELF` prints under both Loot and Tradeskill).
2. For each emitted string, prints a 3-line block: `Name: <GLOBALNAME>`, `Original: <rendered Blizzard original>`, `Formatted: <rendered PrettyChat-configured value>`. Labels are green; the category header above each block (`Category: <name>`) is gold. The Original is rendered from `NS.OriginalFormat(self, globalName)` — the snapshot taken in `OnEnable`, falling back to the live `_G` — which is the same one reader the panel's Original box uses, so the two surfaces cannot disagree (PC-R-04). The Formatted side is rendered from `self:GetStringValue(category, globalName)`.
3. Both renders go through `NS.RenderSample(fmt)` — the same path the per-row Preview EditBox uses, so test output and panel preview can never drift on placeholder choices or positional-arg handling. `RenderSample` walks `%[n$][flags][width][.precision]type` conversions (positional `%n$type` is honored), produces typed placeholders (`"Sample"` for `%s`, `42` for integer types, `1.5` for floats, `65` for `%c`, `"?"` for unknowns), strips `%%` escapes first, and `pcall`s `string.format`. On failure the rendered cell is replaced by an inline gray `(error: <msg>)` and the row counts toward the errored tally.
4. **Every line — header, category banner, body lines, blank-line separators, footer — carries the `[PC]` prefix**, so the report stays distinguishable from real chat traffic interleaved with it. Header includes a notice when `IsAddonEnabled()` is false. Footer reports both counts: `"end of test output (N strings shown, K errored)"` (the `K errored` clause is omitted when zero). When the filter matches no strings (e.g. `/pc test category General` — the virtual category has no strings) the function emits `(no matching strings)` and skips the footer.

Test output ignores the master / per-category / per-string enable toggles — the preview is for *seeing what your formats look like*, not for verifying which ones are currently applied to live chat. The toggles only affect what `ApplyStrings` writes to live `_G[GLOBALNAME]`.

`NS.RenderSample(fmt)` (also exposed from `modules/Override.lua`) is the single-string version used by the per-row Preview EditBox: returns `(rendered_string)` on success or `(nil, err)` on `string.format` failure.

## Color palette

The default formats in `defaults/Defaults.lua` use this palette. Edit `defaults/Defaults.lua` directly if you want to add a category or shift a hue.

| Color (`ff…`) | Usage |
|--------------|-------|
| `ff0000` | Loot category label |
| `ff9900` | Currency category label |
| `ffff00` | Money category label |
| `00ff00` | Reputation category label |
| `00ffff` | Experience category label; also the `[PC]` chat-output prefix |
| `4a86e8` | Honor category label |
| `ff00ff` | Tradeskill category label |
| `93c47d` | "You" / self-referencing |
| `f6b26b` | Other player names / sources |
| `76a5af` | Bonus / Standing context |
| `e06666` | Negative / Refund / Lost |
| `cccccc` | Generic / secondary labels |
| `ffffff` | Default / value text |
| `ffd700` | Gold — panel string labels (per-string title) |
| `aaaaaa` | Gray — panel captions, slash alias note, default-state sample line |

WoW color escapes use `|cAARRGGBB...|r` (AA = alpha, always `ff`). The house style for new defaults is `Category | Context | Source | +/- value`, each segment color-coded.

Addon UI escapes (slash output, `[PC]` prefix, panel gray captions, command-list colors, `/pc test` block markers) are centralized in `NS.Const.Color` (`core/Constants.lua`) — `cyan`/`reset` build the `[PC]` prefix, `yellow`/`white` color the slash-help command names + descriptions (and the gold-key / white-value `/pc list` / `get` / `set` rows), `gray` colors the alias note and the per-string GLOBALNAME caption, `gold` is used for the `Category:` header in `/pc test` output, `green` is used for the `Name:` / `Original:` / `Formatted:` labels in the same. The mandated slash-commands-§5 output palette adds `listHead` (green "Available settings" / count headers) and `azure` (the `[Category]` group headers) — these exact codes are fixed across every Ka0s addon and must not be substituted. Edit `core/Constants.lua` to retune the addon UI palette; this table above governs the chat-message palette.
