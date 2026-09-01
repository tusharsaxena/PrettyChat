# Settings panel

`settings/Panel.lua` builds the settings panel directly on Blizzard's modern `Settings.RegisterCanvasLayoutCategory` / `Settings.RegisterCanvasLayoutSubcategory` API and renders body content with AceGUI. PrettyChat appears under **Ka0s Pretty Chat**; the parent page hosts the logo, tagline, and slash-command list (read-only orientation), and **two** sub-pages hold the actionable controls.

| Page | Tabs (strip order) | Rows |
|---|---|---|
| `General` | *(none — a single-group page draws no strip)* | 1 |
| `Categories` | Loot (39), Currency (9), Money (17), Reputation (29), Experience (41), Honor (13), Tradeskill (17), Misc (5) | 170 |

Row counts are schema rows (`Schema.RowsByCategory`), i.e. one category `enabled` plus two per format string, and are pinned by the page/tab partition case in `tests/test_schema.lua`. Every tab's controls are the same shape, so the numbers are the only thing that differs between them.

The strip is `H.TabStrip`'s (options-ui-§13). It replaced eight sub-pages — one per category — in the pass recorded in [scope.md](./scope.md#resolved-decisions); what survived of that decision, and what did not, is written out there.

This doc covers: the canvas-layout framework, the unified per-page header, the virtual `General` sub-page, the `Categories` tab strip, the per-string row, the Test button, and the color palette.

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

## The virtual `General` sub-page

`General` is a *virtual category* — no entry in `NS.Defaults`, no per-string rows. It's built by `buildGeneralBody(ctx)` and hosts every actionable addon-wide control:

| Control | Wire-up |
|---------|---------|
| Description label | One-line explainer: master toggle behavior. |
| **Enable PrettyChat** toggle (50% row) | Bound to the `General.enabled` schema row. Master switch — when off, every Blizzard original is restored regardless of per-category settings. |
| **Debug console** toggle (50% row, beside Enable) | *Not* schema-backed. Shows/hides the debug console **window** only (`NS.DebugLog:Show()` / `:Hide()`) — the same effect as bare `/pc debug`. It does **not** touch the debug logging flag; logging on/off stays owned by the window's header toggle and `/pc debug on\|off`. Reads `NS.DebugLog:IsShown()`, and the window's OnShow/OnHide fire `Schema.NotifyPanelChange("General")` so the checkbox tracks visibility however it changes (this box, `/pc debug`, the close button, Esc). |
| **Test** button (50% row) | Calls `PrettyChat:Test()`. Synthesizes a sample chat line from every format string regardless of enable toggles, so the preview works even when the addon is disabled. |
| **Reset all to defaults** button (50% row) | Opens the `PRETTYCHAT_RESET_ALL` StaticPopup; on confirm, calls `PrettyChat:ResetAll()`. |

The General sub-page does not show a `Defaults` button in the header — the in-body "Reset all to defaults" with its popup confirm is the only addon-wide reset surface, and showing both would be redundant.

## The `Categories` sub-page and its tab strip

`buildCategoriesBody(ctx)` draws the whole page:

1. **The strip** — `H.TabStrip(ctx, { tabs, value, onSelect })`, one tab per message category, in `CATEGORY_ORDER` minus the virtual `General`. The tab order is *derived* from that array rather than restated, so the strip, `/pc list` and `/pc test` cannot disagree about what comes first. Loot leads because it is what a player opens the page to change; Misc trails because it is the drawer.
2. **One footnote line**, gray, above the controls: *"Strings on these tabs are rewritten only while the master Enable on the General page is on."* Every switch and every format box on every tab is inert while the master is off, and that toggle lives on the other page — a player who enables a category, sees nothing change in chat and has no sentence to explain it has been misled by the page rather than by the setting.
3. **The active tab's body**, `buildCategoryBody(ctx, scroll, category, catData)`:
   1. **Enable `<Category>`** checkbox, bound to the `<Cat>.enabled` schema row.
   2. A 2× row spacer.
   3. One per-string row block per format string in `catData.strings`, sorted by global name.

**Why not `H.RenderTabbedSchema`.** That helper partitions a page's *schema rows* by `group` and hands each partition to the flow engine. A category tab is one schema row (the Enable) followed by N bespoke 40/60 editors the flow engine cannot express — the `options-ui-§6` deviation in [ARCHITECTURE.md](./ARCHITECTURE.md#documented-deviations). So the page takes the **strip** from the library and keeps generating its bodies per category, exactly as it did when each was a page. The tab click re-renders through the same `ClearScroll`-then-draw path `RenderTabbedSchema`'s own `onSelect` takes, and carries no combat guard for the same reason it does not: redrawing widgets inside an already-open panel was never a protected action.

**Refresher hygiene.** `Schema.refreshers` is keyed by *category*, not by page, so an entry left behind by the tab the player just left is a closure over released AceGUI widgets that the next master-toggle fan-out would still reach. `buildCategoriesBody` drops every category's entry before it draws, and the body it draws re-registers the one now on screen.

**The Defaults button** in the header resolves the **active tab** at click time — it is wired once, on the page's first show, and the strip moves underneath it — and calls `PrettyChat:ResetCategory(...)` directly, no popup confirm. Its tooltip therefore names the selected tab rather than a category: one button cannot carry eight wordings that are fixed at panel-build time. Per-row reset is preserved via the per-string `Reset` button (see below), and the master `Reset all to defaults` on General has the popup, so a Defaults click is a single recoverable action.

## Per-string block

Each format string renders as a `Heading` + a 3-row × 2-column grid inside the category panel:

```
─── strData.label ───                          ← AceGUI Heading, full width
[Enable]            | Original [disabled EditBox]
GLOBALNAME (gray)   | New      [editable EditBox]
[Reset]             | Preview  [disabled EditBox]
```

| Row | Left (40%) | Right (60%) |
|-----|------------|-------------|
| Heading | Friendly label, `GameFontNormalLarge` flanked by side dividers | — |
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

Both the General sub-page's "Test" button and the `/pc test` slash command call `PrettyChat:Test(filter)` (in `modules/Override.lua`). The button calls it with no filter (every category, every string); the slash dispatcher (`runTest`) forwards `{kind="category", value=…}` or `{kind="formatstring", value=…}` for the subcommand variants. See [slash-dispatch.md](./slash-dispatch.md#command-reference) for the user-facing forms.

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
