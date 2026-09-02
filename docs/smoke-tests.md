# Smoke tests

PrettyChat's automated coverage is the headless harness under `tests/` (`lua tests/run.lua` — see [testing.md](./testing.md)). It exercises the schema, sample renderer, apply pipeline and override engine, migration runner, slash dispatcher, debug console, and the settings panel's registration and widget wiring under stock Lua — but only against mocks. What it cannot reach is behavior that depends on the live client: real `_G[GLOBALNAME]` formats rendered by Blizzard's own chat code, the persisted AceDB profile across `/reload`, actual panel layout, fonts and third-party skinning, taint, and positional `%n$s` formats. This checklist is that second layer: manual, in-game validation of what stock Lua can't exercise.

Run the **quick recipe** for routine work. Run the **full suite** before tagging a release, after touching `OnEnable` / `ApplyStrings` / `settings/Schema.lua`, or after a WoW client patch.

If you can only reason about a change from code and cannot test it in WoW, say so explicitly — don't claim it works.

## Quick recipe

For a routine change (one new format string, a doc edit, a CSS-level panel tweak):

1. `/reload` — file-load-time builders re-run.
2. `/pc test` — dump a synthesized sample of every format string. Output ignores enable toggles, so this works even when the addon is disabled.
3. Trigger one real chat event (loot an item, gain XP, repair an item, etc.) and read the actual chat line.
4. Open `/pc config`, walk to Categories and the affected category's tab, exercise the toggle and edit boxes for the changed row.

If all four pass, you're good for routine work. The full suite below catches the rest.

## Full suite

Tests are grouped by subsystem. Each test has an ID (`T-NN`), a one-line **Why** line stating the invariant it guards, **Setup**, **Steps**, and **Expected**. A failing test means a regression — track down the cause before merging.

### B — Boot and load

#### T-01 — Clean load with default profile

> Why: `OnInitialize` + `OnEnable` run without errors and the snapshot captures every Blizzard original.

- Setup: delete `WTF/Account/<acct>/SavedVariables/PrettyChatDB.lua` (or use a fresh character).
- Steps: launch WoW with PrettyChat enabled. Observe the load-screen-to-character-select transition.
- Expected: no Lua errors. After login, `/pc test` prints sample lines for every category. No `[PC] schema not ready yet` messages.

#### T-02 — Reload on a populated profile

> Why: AceDB rehydrates user overrides + per-category enabled flags + disabledStrings without losing entries.

- Setup: starting from a clean profile, edit one Loot format via the panel and disable one string via its per-string toggle.
- Steps: `/reload`. Then `/pc list Loot`.
- Expected: the edited format and the disabled-string state are both still present. `_G[<edited>]` reflects the user's override; `_G[<disabled>]` matches Blizzard's original.

#### T-03 — Slash registration

> Why: `/pc` and `/prettychat` both dispatch through `OnSlashCommand`.

- Steps: `/pc help` and `/prettychat help`.
- Expected: identical output from both. Header shows `v<VERSION>` matching the TOC. All ten commands listed (`help`, `config`, `version`, `list`, `get`, `set`, `reset`, `resetall`, `test`, `debug`).

### O — Override pipeline (the three enable layers)

#### T-10 — Master toggle off restores every original

> Why: `General.enabled = false` short-circuits `ApplyStrings` to the restore branch for every string.

- Setup: enable PrettyChat normally.
- Steps:
  1. `/pc test` — note the formatted sample lines.
  2. `/pc set General.enabled false`.
  3. Loot an item, gain XP, repair gold.
  4. `/pc set General.enabled true`.
- Expected: between steps 2 and 4, every chat line uses Blizzard's original format (no `[PC]` color-coded layout). After step 4, formatting returns. Customizations persist (the master toggle does not erase them).

#### T-11 — Per-category toggle off

> Why: `<Category>.enabled = false` skips that category's strings only.

- Steps: `/pc set Loot.enabled false`. Loot one item AND gain XP.
- Expected: loot line uses Blizzard's original; XP line still uses PrettyChat's format. Re-enable: `/pc set Loot.enabled true` — loot reformatting returns.

#### T-12 — Per-string toggle off

> Why: `disabledStrings[NAME] = true` skips that one string only.

- Steps: `/pc set Loot.LOOT_ITEM_SELF.enabled false`. Loot an item *yourself*, then loot one as a *group member* (or `/pc test` and inspect both `LOOT_ITEM_SELF` and `LOOT_ITEM` lines).
- Expected: `LOOT_ITEM_SELF` reverts to Blizzard's original; `LOOT_ITEM` still uses PrettyChat's format. Re-enable: returns to formatted.

#### T-13 — Layer priority: addon > category > string

> Why: any layer being off wins; only "all three on" produces user-formatted output.

- Steps: turn off the master while the per-category and per-string are on. Then turn on the master but turn off one per-string. Then turn everything on.
- Expected: phase 1 — every line is Blizzard's original (master wins). Phase 2 — that one string is Blizzard's original, others are formatted. Phase 3 — every line is formatted.

#### T-14 — Snapshot persists across `/reload`

> Why: `originalStrings` is rebuilt at every `OnEnable`, so a `/reload` mid-session refreshes the snapshot from current `_G`.

- Steps: `/pc set General.enabled false` so every original is restored. `/reload`. Inspect chat behavior.
- Expected: chat lines still use Blizzard's originals. `/pc set General.enabled true` — formatting returns immediately.

### S — Settings panel

#### T-20 — `/pc config` lands on the parent landing page

> Why: `OpenConfig` delegates to `LibKa0s-Options-1.0`'s `OpenOptionsPanel`, which calls `Settings.OpenToCategory` against the parent category it registered.

- Steps: `/pc config`.
- Expected: panel opens with "Ka0s Pretty Chat" selected in the left rail and the parent landing page visible (logo + tagline + slash command list). The page header reads `Ka0s Pretty Chat` (no breadcrumb prefix).

#### T-21 — Sub-category tree auto-expands

> Why: the library's own `expandMainCategory` walks `SettingsPanel:GetCategoryList():GetCategoryEntry(cat):SetExpanded(true)` inside `pcall`. It reports nothing when the private API moves ([`LIBKA0S-04`](https://github.com/tusharsaxena/PrettyChat/issues/9)), so this test is the only thing that would notice.

- Steps: starting from the closed addon list, `/pc config`.
- Expected: the left rail shows both sub-pages (`General`, `Categories`) without the user clicking the disclosure arrow. The eight message categories are **tabs on the Categories page** and must not appear in the rail at all.
- Failure mode: tree stays collapsed. Cause: a future patch renamed `GetCategoryList` / `GetCategoryEntry` / `SetExpanded`. The `pcall` wrapper prevents an error, but the auto-expand silently no-ops. Falls back to manual click.

#### T-22 — Sub-page header breadcrumb

> Why: the library's `CreatePanel` builds sub-page titles as `parentTitle .. BREADCRUMB_SEP .. title`, where `BREADCRUMB_SEP` is `" |A:common-icon-forwardarrow:16:16|a "` — an inline-atlas chevron, not a font glyph, so it renders the same regardless of font or locale fallback.

- Steps: open each sub-page in turn.
- Expected: page header reads `Ka0s Pretty Chat ▸ General`, `Ka0s Pretty Chat ▸ Categories`, with the separator visibly rendered as a small gold right-arrow texture (not as a literal `▸` character or pipe). Atlas divider underneath in the same gold as the title.
- Failure mode: separator appears as raw escape text `|A:common-icon-forwardarrow:16:16|a`, or as a missing-texture box. Cause: the atlas was retired in a client patch. The separator is `BREADCRUMB_SEP` in `libs/LibKa0s/Options.lua` — a value shared by every Ka0s panel, so a change belongs upstream in `../LibKa0s`, never in the vendored copy.

#### T-23 — Per-string block layout

> Why: `buildStringRow` renders `Heading + 3 × Flow row (40/60)`.

- Steps: open Categories > Loot. Pick any string.
- Expected layout:
  ```
  ─── <strData.label> ───
  [Enable]            | Original [disabled EditBox]
  GLOBALNAME (gray)   | New      [editable EditBox]
  [Reset]             | Preview  [disabled EditBox]
  ```
  Left column = 40% width. Right column = 60%, EditBoxes have their `Original` / `New` / `Preview` labels above the input.

#### T-24 — Preview EditBox renders color escapes

> Why: `InputBoxTemplate`'s FontString processes `|c…|r` natively, so `previewInput:SetText(rendered)` shows colored output.

- Steps: open Categories > Loot, find `LOOT_ITEM_SELF`. Read the Preview row.
- Expected: the rendered sample shows colored (red `Loot`, green `You`, etc.), NOT raw `|cffff0000Loot|r` text.
- If you see the raw escape codes literally, `InputBoxTemplate`'s color-rendering behavior changed and we need a Label-in-a-frame fallback.

#### T-25 — Reset button is always visible

> Why: refresh closure removed the conditional `Show()` / `Hide()` — Reset always shown; clicking it when value already equals the default is a harmless no-op via the schema's auto-clear.

- Steps: open a fresh Categories > Loot tab. Note that every per-string row has a Reset button visible. Click Reset on a row whose value matches the default.
- Expected: button stays visible; nothing changes (no error, no panel re-render visible to the user).
- Note: this covers only the always-visible / no-op-at-default behavior. For the per-string Reset *restoring both format and enable state*, see **T-56** (which supersedes the reset-effect coverage this test used to imply).

#### T-26 — Defaults button acts on the visible tab (header)

> Why: the page parks `ctx.panel.defaultsOnClick = function() PrettyChat:ResetCategory(activeCategory(ctx)) end`, the library wires it onto the button it builds on first `OnShow`, and the canvas's `OnDefault` forwards to the same body — no popup. It resolves the tab at **click** time, because the button is wired once and the strip moves underneath it.

- Setup: edit one Loot format and disable one Loot string via the panel. Edit one Money format too.
- Steps: on Categories > Loot, click **Defaults** in the page header. Then click the **Money** tab and click **Defaults** again.
- Expected: each click reverts only the tab you were looking at; no popup confirmation appears. `/pc list Loot` and `/pc list Money` show everything at default, and no other category moved. Hovering **Defaults** reads "Reset the strings on the selected category tab to their defaults."
- Failure mode to watch for: the button resets **Loot** no matter which tab is showing. That is the handler having closed over one category instead of reading the active tab.

#### T-26a — The tab strip itself

> Why: `H.TabStrip` (options-ui-§13) draws the strip, and the addon hands it `CATEGORY_ORDER` minus the virtual `General`. The active tab is the **disabled** button, which is how the selection is marked.

- Steps: open Categories. Read the strip left to right. Click **Currency**, then **Misc**, then **Currency** again. Narrow the Settings window until the strip has to wrap.
- Expected: eight tabs, in the order `Loot, Currency, Money, Reputation, Experience, Honor, Tradeskill, Misc` — the same order `/pc list` and `/pc test` print. The selected tab reads as attached to the page below it and does not highlight on hover; the others do. Each click swaps the body under the strip to that category's Enable row, its secondary strip, and one string editor, with no flicker of the previous tab's rows. A wrapped strip lays out in two flush rows and the first row of controls sits **below** the whole strip, never underneath it.
- Failure mode: every tab on its own row (the strip read a zero width and never re-placed itself), or a second copy of a category's controls appearing under the first (the scroll was not cleared on the tab click).

#### T-26b — The page's footnote

> Why: every control on every tab is inert while the master Enable is off, and that switch is on the other page.

- Steps: open Categories.
- Expected: a gray line above the Enable checkbox reading "Strings on these tabs are rewritten only while the master Enable on the General page is on." It is there on every tab, and it is the first thing on the page.

#### T-27 — Reset all settings popup

> Why: General → Master controls → Reset all settings shows `PRETTYCHAT_RESET_ALL` StaticPopup; on Yes, `PrettyChat:ResetAll()` resets the active profile.

- Setup: edit two formats across two categories, disable one string, set master to false.
- Steps: open General → click "Reset all settings" → click Yes.
- Expected: popup appears with the confirm text. After Yes: master is back to true (default), every override is cleared, every disabled string is re-enabled. `/pc list` shows only defaults.

#### T-28 — Edit + commit on Enter

> Why: `newInput:SetCallback("OnEnterPressed", ...)` calls `NS.Schema.Set(formatPath, value:gsub("||", "|"))`.

- Steps: open Loot. Pick `LOOT_ITEM_SELF`. Edit its New EditBox to a new value (e.g. add a leading `LOOT |` prefix). Press Enter.
- Expected: the value commits. The Preview EditBox updates to show the new format rendered with sample args. Loot an item — the chat line uses the new format.

#### T-29 — `||` ↔ `|` escape boundary

> Why: panel UI shows `||` in edit boxes; saved value uses single `|`. This keeps panel display consistent with `/pc set` (where chat input requires double pipes).

- Steps: open Loot → `LOOT_ITEM_SELF`. Inspect the New EditBox value.
- Expected: the displayed format uses `||cffff0000` (double pipes), NOT `|cffff0000` (single pipe). Now `/pc get Loot.LOOT_ITEM_SELF.format` — chat output shows the format with single pipes (raw stored form). Both surfaces are consistent in their respective conventions.

#### T-29a — General-page Debug console checkbox (window visibility)

> Why: the General page's **Debug console** checkbox shows/hides the console **window** only (`NS.DebugLog:Show()`/`:Hide()`, mirroring bare `/pc debug`); it must NOT change the debug logging flag. The window's OnShow/OnHide fire `NotifyPanelChange("General")` so the checkbox tracks visibility from any surface.

- Setup: ensure debug logging is **on** first (`/pc debug on`) so the next steps can prove the checkbox leaves the flag alone.
- Steps:
  1. `/pc config` → **General** → the **Master controls** tab. Note **Enable PrettyChat** and **General visibility** sit side by side on the first row, and **Debug console** opens the second row on its own.
  2. Check **Debug console**. Expect: the console window **appears**. `/pc debug on` state is unchanged — the window header still reads `Debug: ON`, and no `debug logging ON/OFF` chat ack is printed by the checkbox.
  3. Uncheck **Debug console**. Expect: the window **hides**. Logging flag still unchanged (`NS.Debug` output would still be captured if the window were reopened).
  4. Re-check it, then close the window with its **×** button (or Esc). Expect: the General checkbox **unchecks itself live** (tracks the hide).
  5. `/pc debug` (bare) from chat to reopen the window. Expect: the checkbox **re-checks itself live**.
- Failure mode: checking/unchecking prints a `debug logging ON/OFF` ack or flips the header toggle ⇒ the box is wrongly driving `SetEnabled` instead of `Show`/`Hide`. Checkbox doesn't track the ×/Esc/`/pc debug` ⇒ the OnShow/OnHide `NotifyPanelChange("General")` sync regressed.

#### T-29b — Debug console scrollbar + line counter

> Why: the console log is a wheel-only `ScrollingMessageFrame`, so a thin right-edge `Slider` and a bottom `N / 1500 lines` counter are both a MUST (`debug-logging-§11`, anti-pattern #41). The Slider is driven by the Lua mixin API (`GetMaxScrollRange`/`GetScrollOffset`/`SetScrollOffset`) — the old C getters (`GetNumLinesDisplayed`/`GetCurrentScroll`) are `nil` on retail's mixin and would raise on first open. The initial sync runs LAST in the window build so a frame-API surprise can't blank the header or drop ESC-to-close.

- Setup: `/pc debug on` (start logging), then `/pc debug` to open the console.
- Steps:
  1. On first open, confirm the console is fully wired: the header toggle reads **`Debug: ON`** (green), the close mark and Esc both close it, and no Lua error fired. (A blank header or dead Esc ⇒ the initial sync wasn't run last / threw mid-build.)
  2. Read the footer: a right-aligned **`N / 1500 lines`** counter in the same monospace font as the log. Note N.
  3. Generate lines until the log overflows — e.g. `/pc test all` a few times, or toggle a handful of settings. Expect: N climbs on **every** append; once past 1500 it pins at **`1500 / 1500 lines`** (the buffer is capped).
  4. With the log overflowing, spin the **mouse wheel** up/down over the log. Expect: the scrollbar **thumb tracks the wheel** — moving up toward the **top = oldest** lines, down toward the **bottom = newest**.
  5. **Drag the thumb** up and down. Expect: the log scrolls to match — thumb top shows the oldest buffered line, thumb bottom the newest. No flicker/jitter loop (the `_syncing` re-entrancy guard holds).
  6. Click the **clear** mark (the middle of the three title-bar marks). Expect: the log empties, the counter resets to **`0 / 1500 lines`**, and the scrollbar goes **inert** (thumb parked, mouse disabled) but stays **visible** — the right gutter width is unchanged.
- Failure mode: `attempt to call a nil value` on first open ⇒ the old C getters are being called (#41). Thumb direction inverted (top = newest) ⇒ flip the `sliderValue ↔ offset` sign (`offset = maxOffset − value`). Counter never updates ⇒ `UpdateStatus` isn't wired into `Add`/`Clear`. Bar hidden when the log fits, or gutter width jumps ⇒ the always-shown/inert rule (`options-ui-§10`) regressed.

### L — Slash command surface

#### T-30 — `/pc list` no-arg

> Why: dumps every row across every category in `CATEGORY_ORDER` order.

- Steps: `/pc list`.
- Expected: ~170 lines starting with `[General]`, then `[Loot]`, etc. Each category section lists its `.enabled` row plus every `<NAME>.enabled` and `<NAME>.format` pair.

#### T-31 — `/pc list <Category>` (case-insensitive)

> Why: `Schema.ResolveCategory` lowercase-resolves to canonical PascalCase.

- Steps: `/pc list loot`, `/pc list LOOT`, `/pc list Loot`, `/pc list nope`.
- Expected: first three identical (Loot rows). Last shows `unknown category 'nope'. Valid: General, Loot, Currency, ...`.

#### T-31a — Reserved sub-keywords for `/pc list`

> Why: `category` and `formatstring` are intercepted before `ResolveCategory`, so they don't collide with category names.

- Steps:
  1. `/pc list category` — should print `Categories (9):` followed by every category name in alphabetical order (Currency, Experience, General, Honor, Loot, Misc, Money, Reputation, Tradeskill).
  2. `/pc list formatstring` — should print `Format strings (81):` followed by every `Category.GLOBALNAME` pair sorted by category then by global name (e.g. `Currency.CURRENCY_GAINED`, `Currency.CURRENCY_GAINED_MULTIPLE`, …, `Tradeskill.TRADESKILL_LOG_THIRDPERSON`).
- Expected: both forms succeed without falling through to the unknown-category error path. Counts in headers match the actual list lengths.

#### T-32 — `/pc get` for each row kind

> Why: schema row closures handle `addon_enabled`, `category_enabled`, `string_enabled`, `string_format`.

- Steps:
  - `/pc get General.enabled` → bool
  - `/pc get Loot.enabled` → bool
  - `/pc get Loot.LOOT_ITEM_SELF.enabled` → bool
  - `/pc get Loot.LOOT_ITEM_SELF.format` → quoted string with raw single pipes
  - `/pc get Nope.bogus.path` → `setting not found` error
- Expected: each returns the right value or the right error. No Lua errors.

#### T-33 — `/pc set` bool aliases

> Why: `setSetting` accepts `true/false/on/off/1/0/yes/no`.

- Steps: try each alias on `Loot.enabled`. Then try `/pc set Loot.enabled bogus`.
- Expected: all valid aliases land. `bogus` prints `invalid bool 'bogus' (expected true/false/on/off/1/0/yes/no)`.

#### T-34 — `/pc set` for format string

> Why: `string_format` rows accept the rest of the line literally.

- Steps: `/pc set Loot.LOOT_ITEM_SELF.format ||cff00ff00CustomLoot||r %s`. Then loot an item.
- Expected: format saves (echo confirms). The loot line displays `CustomLoot` in green followed by the item link.

#### T-35 — `/pc reset <path>`

> Why: `reset` is path-scoped collection-wide since the LibKa0s adoption (`LIBKA0S-10`); the category-scoped form is the settings page's **Defaults** button. The full breaking-change walk is T-93.

- Setup: edit two Loot formats, disable one Loot string.
- Steps: `/pc reset Loot.LOOT_ITEM_SELF.format`.
- Expected: chat echoes `Loot.LOOT_ITEM_SELF.format = <the default, pipe-doubled>`. `/pc list Loot` shows that one row at default and the **others still edited** — the point of a path-scoped reset.

#### T-36 — `/pc resetall`

> Why: `runResetAll` calls `ResetAll`, clearing master + every category.

- Setup: scatter changes across multiple categories, set master to false.
- Steps: `/pc resetall`.
- Expected: chat output `all settings reset to defaults`. `/pc get General.enabled` returns `true`. `/pc list` shows defaults everywhere.

#### T-37 — Combat lockdown guard on `/pc config`

> Why: `Settings.OpenToCategory` is taint-protected during combat. The guard lives in `PrettyChat:OpenConfig` itself (not just the slash dispatcher), so any caller is gated.

- Steps: enter combat (engage a target dummy or attack a mob). While in combat: `/pc config`. Then, still in combat, run `/run LibStub("AceAddon-3.0"):GetAddon("PrettyChat"):OpenConfig()` to exercise the programmatic path.
- Expected: both calls print `cannot open settings during combat — Blizzard's category-switch is protected` (gray). Panel does NOT open in either case. Leave combat — `/pc config` works.

#### T-38 — Unknown command + empty input

> Why: dispatcher falls back to `printHelp` for both.

- Steps: `/pc bogus`, then `/pc` (no args).
- Expected: `/pc bogus` prints `unknown command 'bogus'` followed by the help index. `/pc` (no args) prints just the help index.

### X — Cross-surface sync (panel ↔ slash)

#### T-40 — Slash mutation reflects in open panel

> Why: `Schema.Set` calls `Schema.NotifyPanelChange(category)` → invokes the closure registered via `Schema.RegisterRefresher(category, …)` → re-syncs visible widgets.

- Steps: open `/pc config`, navigate to Categories > Loot. Leave the panel open. From chat: `/pc set Loot.LOOT_ITEM_SELF.enabled false`. Look at the panel.
- Expected: the per-string Enable checkbox for `LOOT_ITEM_SELF` flips to unchecked without reopening the panel. The New input becomes disabled.

#### T-41 — Master change cascades to the visible tab and to the ones behind it

> Why: `NotifyPanelChange("General")` runs every registered refresher, and only the visible tab has one. The tabs behind it are rebuilt from the live DB when they are clicked, which is the other half of the same guarantee.

- Steps: open `/pc config`, walk to Categories > Loot. Leave it open. `/pc set General.enabled false`. Watch the Loot tab, then click through Currency, Money and the rest.
- Expected: the Loot tab grays out **without being clicked**; every tab you then click is already gray. Re-enable the master — the visible tab comes back live, and so does each tab you visit afterwards.

#### T-42 — Panel mutation reflects in `/pc get`

> Why: panel widget callbacks call `NS.Schema.Set` exactly the same way `/pc set` does.

- Steps: edit a value in the panel and press Enter. From chat: `/pc get` against the same path.
- Expected: chat output shows the new value. Panel and slash share one write path.

#### T-43 — Auto-clear on default match

> Why: `string_format` row's `set` closure stores `nil` when the new value equals the PrettyChat default.

- Steps: edit `LOOT_ITEM_SELF.format` to anything different. Inspect `/pc get` (returns custom value). Then set it back to the exact default text. Inspect saved variables: `/reload` and check `PrettyChatDB.profile.categories.Loot.strings`.
- Expected: after the second set, `Loot.strings.LOOT_ITEM_SELF` is absent (or the entire `strings` table is missing). The override entry is auto-cleared.

### P — Persistence and edge cases

#### T-50 — Saved variables shape

> Why: only user-modified values are stored; defaults stay implicit.

- Setup: clean profile, then change exactly one thing (e.g. disable `Loot.LOOT_ITEM`).
- Steps: `/reload`. Open `WTF/Account/<acct>/SavedVariables/PrettyChatDB.lua`.
- Expected: `PrettyChatDB.profiles.Default.categories.Loot.disabledStrings = { LOOT_ITEM = true }`. No other entries under Loot. No `enabled = true` keys (those are nil → default-true).

#### T-51 — Format-specifier mismatch

> Why: a wrong-signature replacement errors at `string.format`. The Test command's `pcall` skips it; live chat may drop the line.

- Setup: `/pc set Loot.LOOT_ITEM_SELF.format Wrong` (no `%s` where Blizzard uses one).
- Steps: `/pc test`, then loot an item.
- Expected: Test's footer reports `N strings shown` where `N` is one less than usual (the bad format is silently skipped). The actual loot line either drops or shows raw.

#### T-52 — Sample arg coverage in `/pc test`

> Why: `buildSampleArgs` should produce typed placeholders (`"Sample"` for `%s`, `42` for `%d/%i/%u/%x/%o`, `1.5` for `%f/%g/%e`, `65` for `%c`, `"?"` for unknowns).

- Steps: `/pc test`.
- Expected: every category prints a `Category: <name>` gold header followed by a 3-line block per string (green `Name:` / `Original:` / `Formatted:` labels, then a blank separator). Every line — header, category banner, body, blank separators, footer — carries the `[PC]` prefix.

#### T-52a — `/pc test` filters

> Why: `runTest` parses sub-keywords (`all`, `category`, `formatstring`) and forwards a typed filter table to `Test`. Each filter must restrict the output to the matching subset; bad input must surface a usage hint, not a Lua error.

- Steps:
  1. `/pc test all` — same output as bare `/pc test`.
  2. `/pc test category Loot` — only the Loot block prints. Footer count matches Loot's string count (19).
  3. `/pc test category loo` — same output as case 2 (case-insensitive prefix match via `Schema.ResolveCategory`).
  4. `/pc test category General` — emits `(no matching strings)` and skips the footer (General is virtual, no strings).
  5. `/pc test category nope` — chat prints `unknown category 'nope'. Valid: General, Loot, ...`. No test output.
  6. `/pc test formatstring CURRENCY_GAINED` — only the Currency category header prints, and only the `CURRENCY_GAINED` 3-line block under it. Footer count is `1`.
  7. `/pc test formatstring currency_gained` — same as case 6 (input is uppercased).
  8. `/pc test formatstring LOOT_ITEM_CREATED_SELF` — both Loot and Tradeskill headers print, each with a single block for that global. Footer count is `2` (one per registration).
  9. `/pc test formatstring NOPE_NOPE` — chat prints `unknown format string 'NOPE_NOPE' — try /pc list formatstring`. No test output.
  10. `/pc test bogus` — chat prints the four-line usage (no-arg, all, category, formatstring forms).
- Expected: all ten cases run without Lua errors; subset, no-match, and error cases each behave as listed.

#### T-53 — Cross-category shared global (`LOOT_ITEM_CREATED_SELF`)

> Why: this key is registered under both `Loot` and `Tradeskill`. `ApplyStrings` iterates `CATEGORY_ORDER` in fixed order (sorted names within each), so the last category wins **deterministically** (PC-16) — `Tradeskill` comes after `Loot`, so the Tradeskill format wins.

- Setup: edit `Loot.LOOT_ITEM_CREATED_SELF.format` and `Tradeskill.LOOT_ITEM_CREATED_SELF.format` to visibly different strings. `/reload` a few times and trigger creation events.
- Expected: live chat shows the **Tradeskill** format on *every* load (stable across reloads, not a coin-flip). Documented behavior — see [data-flow.md](./data-flow.md#known-quirk-globals-shared-across-categories). Do not "fix" without a triggering complaint.

#### T-54 — Disabled state propagates to UI inputs

> Why: when master OR category is off, per-string Enable should be disabled; when any of the three layers is off, New input is disabled.

- Steps: open Loot. Toggle `Enable Loot` off in the page body.
- Expected: every per-string Enable checkbox on the page becomes disabled (grayed). Every New EditBox becomes disabled. The Original EditBox remains as it was (already disabled). Reset button stays clickable.

#### T-55 — Unknown category name on slash reset

> Why: `runReset` validates against `CATEGORY_ORDER` via `ResolveCategory`.

- Steps: `/pc reset Bogus`.
- Expected: chat prints `unknown category 'Bogus'. Valid: General, Loot, ...`. No state change.

### R — Reset standardization

The four reset entry points — per-string **Reset** button, per-category **Defaults** button, `/pc reset <cat>`, `/pc resetall` — share one semantic: each wipes every dimension it owns (custom format *and* enable/disable flag), re-applies via `ApplyStrings`, re-syncs the panel via `NotifyPanelChange`, and emits a `NS.Debug("Reset", …)` summary.

#### T-56 — Per-string Reset restores format AND enable state

> Why: `PrettyChat:ResetString` (`modules/Override.lua`) must clear both `strings[name]` (custom format) and `disabledStrings[name]` (disable flag); resetting only the format would leave a previously-disabled string half-reset. Supersedes the reset-effect coverage T-25 used to imply.

- Setup: open `/pc config` → Loot → `LOOT_ITEM_SELF`. Do two things: (a) edit its New box to a visibly different format and press Enter, (b) uncheck its per-string **Enable**.
- Steps: click that row's **Reset** button. Then loot an item yourself.
- Expected: the Enable checkbox flips back to **checked**; the New box returns to the PrettyChat default text and becomes editable again; the Preview re-renders the default; the live loot line uses PrettyChat's default format (not Blizzard's original). `/pc get Loot.LOOT_ITEM_SELF.enabled` → `true`; `/pc get Loot.LOOT_ITEM_SELF.format` → the default.
- Failure mode: checkbox stays unchecked / line stays Blizzard-original ⇒ the `disabledStrings[name] = nil` clear regressed.

#### T-57 — Reset paths are semantically identical across all four entry points

> Why: per-string Reset, per-category **Defaults**, `/pc reset <cat>`, and `/pc resetall` should all wipe every dimension they own — no path may leave a stale disable flag or override.

- Setup: disable one Loot string via its toggle **and** edit its format.
- Steps: repeat the same setup four times, clearing it once each way: (1) row **Reset** button, (2) Loot header **Defaults** button, (3) `/pc reset loot`, (4) `/pc resetall`.
- Expected: all four leave `/pc list Loot` fully at default — no lingering `disabledStrings` entry, no lingering override. Confirm after a `/reload` too: `PrettyChatDB.profiles.Default.categories.Loot` is absent (or empty).

#### T-58 — Every reset emits a consistent debug summary

> Why: all three reset methods bypass the `Schema.Set` `[Set]` seam (debug-logging-§8), so each carries its own `NS.Debug("Reset", …)` line with the material effect (`applied` / `restored` counts).

- Setup: `/pc debug` to open the console and enable logging (toggle green).
- Steps: trigger each reset once — a row Reset, a category **Defaults**, `/pc resetall`.
- Expected: three `[Reset]` lines appear in the console, formatted respectively `Loot.LOOT_ITEM_SELF → applied N restored M`, `Loot → applied N restored M`, `all → applied N restored M`. Counts are non-zero when overrides existed.

#### T-59 — Reset reflects live in an open panel

> Why: each reset calls `NotifyPanelChange(category)` (or nil → all), re-syncing visible widgets without a reopen.

- Steps: open Categories > Loot, leave it open. From chat, after editing/disabling a couple of its strings: `/pc reset loot`.
- Expected: the visible Enable checkboxes re-check and New boxes repopulate to defaults live, no panel reopen. `/pc resetall` from chat similarly refreshes whichever tab is showing.

### M — Media (fonts, textures, borders)

Validates the media audit conclusion in-game: every font, texture, and border is a Blizzard default **except** the debug console's JetBrains Mono, the shared Ka0s marks on the console's title bar, and the addon's own logo. PrettyChat never restyles the chat frame itself.

Since the `LibKa0s-Media-1.0` adoption the font and the marks both come from **inside the vendored library payload** (`libs/LibKa0s/media/`), not from this addon's own `media/` — which now holds nothing but the logo and the project-page screenshots. Everything in this section therefore has a second failure mode worth naming up front: **the library was never told which addon folder is asking.** A texture path is absolute from `Interface\AddOns\`, a vendored copy cannot work out which folder it sits in, and a wrong or missing answer produces a path to a file that is not there — which draws nothing and raises nothing. Nothing goes red; the window just quietly goes back to the pre-icon spelling.

#### T-60 — Debug console renders with the vendored mono font + Blizzard chrome

> Why: the console is the one non-Blizzard font (`Const.FONT_MONO`, JetBrains Mono); its frame/border are Blizzard assets (`Interface\Buttons\WHITE8x8` backdrop, `Interface\Tooltips\UI-Tooltip-Border` edge). The face is resolved at load through `NS.MediaFont` (`core/MediaSetup.lua`) out of the LibKa0s payload — this addon no longer ships a copy of it.

- Steps: `/pc debug`. Add a few lines (trigger a reset or two so entries appear).
- Expected: log text is clearly **monospaced** (columns line up); the window has a dark backdrop with a thin tooltip-style border and no missing-texture boxes; the title bar reads "Pretty Chat — Debug" in a normal Blizzard font. Click the copy mark — the copy window's EditBox is also monospaced.
- Failure mode: log text is **proportional** ⇒ the seam answered nil and `Const.FONT_MONO` fell through to `STANDARD_TEXT_FONT`. That is the designed degradation and it is deliberately readable, so it will not announce itself — check that `libs/LibKa0s/media/fonts/JetBrainsMono-Regular.ttf` shipped, and that `core/MediaSetup.lua` precedes `core/Constants.lua` in the TOC. A pink-and-black checkerboard ⇒ backdrop asset renamed in a client patch. Log text missing **entirely** ⇒ someone replaced the `STANDARD_TEXT_FONT` fallback with a path; `SetFont` accepts a path to a file that is not there and simply draws nothing.

#### T-60a — The console title bar wears the collection's marks, not two words and a ×

> Why: `core/DebugLogSetup.lua`'s descriptor passes `addonName` **beside** `name`. `name` seeds the frame globals (`PrettyChatDebugWindow`); `addonName` is the folder name the library builds a texture path from, and it is the only way a vendored copy can find its own art. This addon draws no frames of its own, so this title bar and its copy window are the **only** places in PrettyChat a player sees the change at all.

- Steps: `/pc debug`. Look at the right-hand end of the title bar, then click the copy mark and look at the copy window's own title bar.
- Expected, left to right on the console: a **copy** mark, a **clear** mark, and a **close** mark — three small square icons of the same size and pitch, drawn in the same off-white and brightening on hover. The copy window carries the same close mark. The words **Copy** and **Clear** are gone, and **there is no tooltip on any of them** — that is by design, not an omission (a tooltip anchored under the strip covers the first line of the log, which is the thing the window exists to show).
- Failure mode — and this is the one to memorise: **a multiplication sign (×) on the close control, with the words "Copy" and "Clear" beside it, means the folder name stopped being passed.** That is the library's fallback, not a broken build: it is exactly what a host that never passes `addonName` gets. Check that `addonName = addonName` is still in the descriptor **and that `name = addonName` is still there too** — they answer different questions and this addon happens to answer both with the same string, which is precisely what hides a mix-up. If only *some* of the three marks are missing, the art did not ship: check `libs/LibKa0s/media/icons/{copy,clear,close}.tga`.
- Second failure mode: the marks are there but the two consoles you have open draw **different** art. One of the two addons is on an older LibKa0s payload; re-vendor it.

#### T-61 — Settings panel header uses Blizzard font objects + atlas divider

> Why: title is `GameFontNormalHuge`, divider is the `Options_HorizontalDivider` atlas tinted to the title's color — all Blizzard-default.

- Steps: `/pc config`, open any sub-page.
- Expected: the page title renders in the standard large gold Blizzard options font; a horizontal divider sits under it in the **same gold**; descriptions and section headings use normal Blizzard fonts. No custom typeface anywhere on the panel, no raw `|A…|a` escape text, no missing-texture box on the divider.

#### T-62 — Landing-page logo texture renders

> Why: the one intentional brand (non-Blizzard) texture — `media/logos/prettychat.logo.tga`.

- Steps: `/pc config` (lands on the parent page).
- Expected: the PrettyChat logo image displays at the top-left of the landing page (not a blank/checkerboard box), followed by the tagline and slash-command list.
- Failure mode: missing-texture box ⇒ the `.tga` wasn't packaged, or `LOGO_PATH` in `settings/Panel.lua` drifted.

#### T-63 — Chat output imposes no font/texture of its own

> Why: PrettyChat only injects `|c…|r` color escapes into `GlobalStrings` — it must never restyle the chat frame; font/texture there is inherited from the player's chat setup.

- Setup: note your chat frame's current font (Blizzard default, or via Prat/ElvUI if installed).
- Steps: enable PrettyChat, loot an item, gain XP.
- Expected: the reformatted lines appear in the **exact same font/size/backdrop** as every other chat line — only the coloring/layout of the text differs. PrettyChat adds no border, no background, and no font change to the chat window.

## When to run what

| Trigger | Run |
|---------|-----|
| Routine code change | Quick recipe |
| Touched `OnEnable` / `ApplyStrings` / `settings/Schema.lua` | Quick recipe + B + O groups |
| Touched `settings/Panel.lua` | Quick recipe + S + X + M groups |
| Touched slash command surface in `settings/Slash.lua` | Quick recipe + L + X groups |
| Touched the reset paths (`ResetString` / `ResetCategory` / `ResetAll` in `modules/Override.lua`, or a Reset/Defaults button) | Quick recipe + R group |
| Touched `core/DebugLogSetup.lua`, `media/`, or panel chrome (fonts/textures/borders) | Quick recipe + M + K groups |
| Re-vendored `libs/LibKa0s/`, or touched any of the six seam files | Quick recipe + **K group** |
| Pre-release / pre-tag | Full suite |
| Post WoW client patch | Full suite + regenerate `GlobalStrings/` per [global-strings.md](./global-strings.md#regenerating-chunks-after-a-wow-patch) |

## K — LibKa0s adoption

Everything in this group is invisible to the headless suite by construction: a rendered
`SCREAMING_SNAKE` key is a perfectly good string, a window's border only reads as wrong beside one
that has both lines, and a degraded install is a state the loader can only simulate.

Run the whole group after re-vendoring `libs/LibKa0s/`, after any change to the six seam files, or
before tagging.

#### T-90 — The degraded install: nothing errors, and the reason is said once

**Why:** four seams degrade rather than error, and each explains the same absence through one shared
cause clause. A user with a broken install must be told *why* once and *what* per surface — not a Lua
error, and not the same sentence stapled to every line.

**Setup:** exit the client. Rename `Interface/AddOns/PrettyChat/libs/LibKa0s` to `libs/_LibKa0s`.

**Steps:**
1. Launch, log in, and watch for Lua errors (`/console scriptErrors 1`, or BugSack).
2. Read the first `[PC]` line the addon prints.
3. `/pc list` — read the whole output.
4. `/pc debug on`, then `/pc debug` .
5. `/pc config`.
6. `/pc resetall`.

**Expected:**
- **Zero** Lua errors at load or on any of the above.
- The **first** line printed is exactly:
  `[PC] The LibKa0s library is missing from this installation of Ka0s Pretty Chat (expected in libs/LibKa0s); running on reduced built-in fallbacks.`
  — and that sentence appears **exactly once** for the whole session, not per line. Compare it word
  for word against the same line from another Ka0s addon with its library removed; the clause before
  the semicolon must be identical apart from the addon name.
- `/pc list` prints `…(expected in libs/LibKa0s), so the settings CLI is unavailable.` — one line,
  not a half-rendered listing.
- `/pc debug on` still prints the color-coded `debug logging ON` ack and still flips the flag; the
  window's absence is reported once with `…, so the debug console window is unavailable.`
- `/pc config` reports `…, so the settings panel is unavailable.`
- **`/pc resetall` still works** — the schema loaded fine, and a user whose panel will not open is
  exactly the user who needs "reset everything" (options-ui-§1).
- `/pc help`, `/pc version` and `/pc test` all still work: those verbs never went to the library.

**Then rename the folder back and `/reload` before continuing.**

#### T-91 — No raw locale key is on screen anywhere

**Why:** the `L` trap. A module handed the addon's locale table renders raw `SCREAMING_SNAKE` keys in
place of English — for every key at once, and only in game, because a synthesized key *is* a string
and no headless assertion can tell the difference. Current vendored copies resolve overrides with
`rawget` and are safe, but this is the check that would have caught a shipped one.

**Steps:** walk every surface and read every label:
1. `/pc config` — the landing page, both sub-pages and all eight tabs on Categories, including the page's **Defaults** button and the Categories footnote.
2. `/pc debug` — the console: the title bar, the `Debug: ON`/`Debug: OFF` toggle, the `N / 1500 lines`
   counter, and the copy window's own title. (The Copy and Clear controls are marks now and carry no
   text — if you can read a word on either of them, the folder name is not reaching the library and
   T-60a is the failing check, not this one.)
3. The General page's **Debug console** checkbox — hover it and read the tooltip.
4. `/pc help`, `/pc list`, `/pc get General.enabled`, `/pc set General.enabled maybe`,
   `/pc reset nonsense`.

**Expected:** not one string on screen matches `^[A-Z][A-Z0-9_]+$`. Specifically **not**
`DEFAULTS_LABEL`, `DEBUG_ON`, `DEBUG_OFF`, `CLEAR`, `COPY`, `COPY_TITLE`, `LINES`,
`CHECKBOX_LABEL`, `CHECKBOX_TOOLTIP`, `LIST_HEADER`, `LIST_GROUP`, `HELP_HEADER`, `NOT_FOUND`,
`INVALID`, `USAGE_GET`, `USAGE_SET`, `USAGE_RESET`, `ERR_BOOL` or `ERR_STRING`.

#### T-92 — The console wears the Ka0s window edge

**Why:** the console's skin changed hands (`LIBKA0S-03`). standalone-windows makes the edge
normative, and the failure mode is one that reads fine in a screenshot taken on its own — a
single-line border only looks wrong beside a window that has both lines.

**Steps:** `/pc debug`, then open a second Ka0s addon's debug console beside it.

**Expected:**
- A **hard black 1px outer border** with a **lighter gray 1px line just inside it** — two lines, not
  one. Background `0.06, 0.06, 0.08` at 92% alpha.
- The window title (`Pretty Chat — Debug`) renders **gold**; the divider under the title bar is
  **gray**, not black.
- The close control is the collection's **close mark**, and it is the **same** mark the other addon's
  console wears — not a multiplication sign on either. See T-60a for what a × there means.
- Click the copy mark — the copy window wears the identical edge, and the identical close mark.
- Side by side, the two consoles should be indistinguishable apart from their titles. Anything that
  differs is the finding.

#### T-93 — `/pc reset` takes a path, and the old form explains itself

**Why:** convergence #1 is a **breaking** change to a verb this addon has shipped since 1.0
(`LIBKA0S-10`). The old form still parses as something, so it must not be answered with
"Setting not found".

**Steps:**
1. `/pc set Loot.enabled false`
2. `/pc reset Loot.enabled`
3. `/pc set Loot.enabled false` again, then `/pc reset Loot`
4. `/pc reset loot` (lower case), and `/pc reset Curr` (an unambiguous prefix)
5. `/pc reset zzz`

**Expected:**
- (2) resets **only** that row and echoes `Loot.enabled = true`.
- (3) resets **nothing**, and prints three lines: that `reset` now takes a PATH not a category, the
  `/pc reset <path>` replacement with a pointer to `/pc list Loot`, and the **Defaults** button plus
  `/pc resetall` as the category- and global-scoped replacements.
- (4) behaves the same for both spellings — the deprecation resolves the category name the way
  `/pc list` does.
- (5) is a plain `Setting not found: zzz`; it is neither a path nor a category, so there is nothing
  to deprecate.

#### T-94 — Category reset still exists, on both entry points

**Why:** the capability moved rather than disappearing, and a settings button and a slash verb
reaching the same body are **two** paths. A check that only clicks the button proves nothing about
the other one.

**Steps:**
1. On the **Loot** page, uncheck two messages and edit one format. Click the header **Defaults**
   button.
2. Repeat, but this time use the Blizzard Settings window's **own footer defaults control** rather
   than the header button.
3. Repeat once more, and use `/pc resetall`.

**Expected:** all three restore Loot to defaults. (2) is the one that regressed silently before the
adoption — this addon shipped without `OnDefault` on its canvas frames, so the footer control did
nothing while the header button beside it worked.

#### T-95 — Nothing moved

**Why:** ~233 lines of panel scaffolding changed hands. The parity question is not "does it work" but
"is anything different", and anything that looks different is the finding.

**Steps:** open `/pc config` and compare against a screenshot taken before the adoption.

**Expected — unchanged:** the breadcrumb `Ka0s Pretty Chat ▸ <Page>` with its inline arrow atlas;
the title in `GameFontNormalHuge` with the gold divider tinted to it; the **Defaults** button top
right at the same inset; the scrollbar gutter reserved on every page, short or long, with the bar
grayed and inert where the content fits; the per-string 40/60 blocks.

**Expected — deliberately different:** the General page's controls sit at a true 50/50 rather
than 0.492 (label-inset controls, so the honest half is correct); the landing page's command rows
have **single** spaces around the em dash, no color span on the dash itself, and a white
description. Since the settings revamp the General page also carries a one-tab **Master controls**
strip it did not have, a **General visibility** dropdown beside Enable, and **Reset all settings** in
place of **Reset all to defaults** — see T-100 to T-103.

#### T-96 — The panel refuses to render under combat, from the sidebar too

**Why:** the Blizzard AddOns sidebar reaches a panel without going through the panel-open, so its
combat guard is bypassed on exactly the path a user is most likely to take mid-fight. This addon had
no guard on the render path before adopting.

**Steps:** pull a target. While in combat:
1. `/pc config`
2. Open the Settings window from the game menu and click **Ka0s Pretty Chat** in the AddOns list.

**Expected:** (1) refuses with the gray
`cannot open settings during combat — Blizzard's category-switch is protected` and does not open.
(2) closes the Settings window and prints the same line, rather than drawing a half-built page.

#### T-97 — The TOC still reaches this addon after the LibKa0s-Env seam

**Why:** `core/Compat.lua` is gone and its metadata reader is now `core/EnvSetup.lua` over
`LibKa0s-Env-1.0`. Three call sites read the TOC at FILE SCOPE — `NS.version`, `/pc version`'s
`VERSION`, and the About page's `TOC_NOTES` — so the seam's new TOC position is load-bearing and
only a live load proves the client agrees with the headless loader about that order. The three
strings below are what a player actually sees; all three come off the packaged manifest, and a
seam the client resolved late would show a stale version rather than an error.

**Setup:** a normal install of the packaged addon (not a source checkout with an edited TOC).

**Steps:**
1. `/reload`.
2. `/pc version`
3. `/pc` (the help index header line).
4. `/pc config` and read the top of the parent **Ka0s Pretty Chat** page.

**Expected:** no Lua error on load. (2) and (3) both print the version from the TOC's
`## Version:` line, and they agree with each other. (4) shows the tagline **Prettier chat
messages** — the TOC's `## Notes:` — above the command list. A missing tagline, or a version that
disagrees with the `.toc`, means a file-scope read did not reach the seam.

#### T-98 — A degraded install with no LibKa0s still knows its own version

**Why:** `core/EnvSetup.lua` writes its fallback ladder out in full so an install missing the
vendored payload reads its own TOC exactly as it did before the library existed. That arm is
covered headlessly, but only the client proves the addon still boots with the payload absent.

**Setup:** rename `Interface/AddOns/PrettyChat/libs/LibKa0s` to `libs/LibKa0s.off`. Restore it
afterwards.

**Steps:** launch, then `/pc version` and `/pc config`.

**Expected:** the addon loads. `/pc version` prints the same version as T-97 — not `?`, and not a
stale literal. The About tagline is still there. The debug console falls back to the client's own
proportional face and draws no title-bar icons, because the art and the mono face are inside the
missing payload — that is the media seam's contract, not this one's.

## Reporting a failure

If a test fails:

1. Capture the exact steps, the chat output, and any Lua error (BugSack or `/console scriptErrors 1`).
2. Note the WoW client build (`/dump GetBuildInfo()`).
3. Determine which invariant in [ARCHITECTURE.md](./ARCHITECTURE.md) (Settings Schema / Taint Notes / Known Limitations) the failure violates.
4. File or update an issue per [README.md § Issues and feature requests](../README.md#issues-and-feature-requests). Don't ship a "fix" that just makes the test pass — root-cause first.

#### T-100 — The General page's Master controls strip

**Why:** this page had no strip at all before the settings revamp — one group, one row, drawn
straight through `H.RenderRows`. A one-group page draws a one-tab strip now (options-ui-§13), and
the tab is the only thing naming the group once the heading is suppressed.

**Steps:** `/pc config` → **General**.

**Expected:** one tab, reading **Master controls**, drawn in the same band and the same art as the
Categories page's eight. Below it, in this order and two to a line:

```
[Enable PrettyChat]   [General visibility ▾]
[Debug console]
[Test]
[Reset all settings]
```

The explainer line sits above them. **Failure mode:** no strip (the page went back to `RenderRows`);
a strip with a tab named `General` (the group was renamed, which also detaches the closing button's
`afterGroup` hook silently); the Test or Reset button missing (the hook detached).

#### T-101 — General visibility, all four modes

**Why:** the setting is declared by the composed block and honoured by `ApplyStrings`. A declared
setting nothing reads is worse than an absent one.

**Steps:** with Loot enabled and a lootable target to hand:
1. Leave **General visibility** on *Always*. Loot something — the line is PrettyChat's.
2. Set it to *Never*. Loot again — the line is **Blizzard's original**, and every other category is
   too. `/pc get General.visibility` reads `never`.
3. Set it to *Only in combat*. Out of combat, loot — Blizzard's original. Pull a target, loot in
   combat — PrettyChat's. Drop combat, loot — Blizzard's original again.
4. Set it to *Only out of combat* and repeat step 3 with the expectations swapped.
5. Set it back to *Always*.

**Expected:** the change takes effect on the next chat line with no `/reload`, and the combat
transitions flip it live. **Failure mode:** nothing changes (the mode is not in the `ApplyStrings`
gate); the combat modes only take effect after a `/reload` (`SyncCombatWatch` never armed, or its
events were registered on the wrong frame).

#### T-102 — The secondary strip inside a category

**Why:** a category tab used to stack up to twenty three-row editors; it is one tab per string now,
drawn inside the scroll rather than as a second pinned band (options-ui-§13).

**Steps:** `/pc config` → **Categories** → **Loot**.

**Expected:** below the **Enable Loot** checkbox, a second strip of nineteen tabs, one per format
string, labelled with the friendly names and in the same sorted order the blocks used to be stacked
in. Hovering a tab shows its `GLOBALNAME`. Exactly **one** editor is drawn below the strip, and it
has **no heading** — the tab is its name. Click through several: the editor swaps, no stray tab
button is left behind, and the page does not shift downward. Now switch to **Experience**, pick a
string there, switch back to **Loot** — you land on the Loot string you left, not the first one.
Close the panel and reopen it: every category is back on its first string (the pointer is
session-only and deliberately not persisted).

**Failure mode:** stale tab buttons stacked on top of the new ones after switching category (the
`__subTabKids` ledger was not drained before `ReleaseChildren`); the whole page pushed down twice
(the strip was drawn as chrome instead of as content); a heading above the editor repeating the tab's
own name.

#### T-103 — Test writes to the console, `/pc test` writes to chat

**Why:** the full report is 500+ lines, and the chat frame is what this addon exists to keep
readable. The sink is a parameter on `Test`, not a redirection of `NS.Print`.

**Steps:**
1. `/pc config` → **General** → click **Test**.
2. Then, from chat, `/pc test formatstring LOOT_ITEM_SELF`.

**Expected:** (1) the debug console **opens** and fills with the report — `[Test]`-tagged lines,
`Category:` headers in gold, `Name:` / `Original:` / `Formatted:` in green, the counted footer at the
bottom — and **not one line lands in chat**. The console's **Copy** button gives you the whole
report. (2) the slash form prints to chat exactly as it always did, `[PC]`-prefixed, and does not
open the console.

**Failure mode:** the button prints into chat (the sink was dropped); `/pc test` stops printing to
chat (the sink was made the default rather than the caller's choice); the console opens empty (the
report was written before the window existed).
