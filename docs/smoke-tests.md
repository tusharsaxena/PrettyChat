# Smoke tests — Ka0s Pretty Chat

These are the in-client checks the headless suite (`lua tests/run.lua`, see [testing.md](./testing.md))
cannot make. The harness runs the schema, the sample renderer, the override engine, the migrations,
the slash dispatcher, the debug console and the panel's wiring, all against mocks. It cannot see
Blizzard's chat code render a real `_G[GLOBALNAME]` format, an AceDB profile survive a `/reload`, real
panel layout, fonts, skinning, taint, a non-English client or a positional `%n$s` format. Run the
checks from a clean `/reload`, and turn logging on (`/pc debug on`) only where a step says so. Each
check says what to do and what must happen; anything that does not match is a bug. Write the outcome
on the check's `Result:` line: pass, or what you saw instead. IDs are `<THEME>-<n>` and stay stable: a
new check takes the next free number in its theme, and a retired one leaves its number unused. If you
can only reason about a change from code and cannot run it in a client, say so rather than claim it
works.

## Index

| ID range | Theme | What it covers |
|---|---|---|
| INSTALL-1 – 7 | Install, load and persistence | First load, the TOC version, reload persistence, the SavedVariables shape, the schema v2 move |
| SLASH-1 – 10 | Slash commands | Help, bare `/pc`, `list`, `get`, `set`, the format-string write gate |
| PANEL-1 – 21 | Settings panel | Landing page, rail, header, General, the Categories strip, string list and editor, panel and CLI sync |
| PROFILE-1 – 10 | Profiles | The Profiles page, per-profile settings, the `/pc profile` verb |
| STATE-1 – 6 | Enable and stand-down | `/pc enable` / `/pc disable`, what answers while disabled, the combat watcher standing down |
| COMBAT-1 – 4 | Combat | The panel's combat refusal and cover, the launcher in combat, diagnostics in combat |
| OVR-1 – 10 | Override pipeline | The three enable layers, General visibility, one-category registration, the chat text other addons read, a real line for a changed string |
| TEST-1 – 6 | Test preview | `/pc test` and the Test button, the filters |
| RESET-1 – 13 | Resets | Row Reset, the Defaults buttons, `/pc reset <path>`, reset all, the one log line |
| LAUNCH-1 – 7 | Launcher | The minimap button, its menu and tooltip, the Minimap button row, broker displays |
| DIAG-1 – 19 | Debug and diagnostics | The diagnostics report, the console and its chrome, raw locale keys |
| DEGRADED-1 – 10 | Library-absent install | `libs/LibKa0s` renamed aside: fallbacks, refusals, restore |
| LOC-1 – 5 | Non-English client | The snapshot and restore on a localized client, one real line per category, missing globals |

## Before you start

- Error display on: `/console scriptErrors 1` (or BugSack). Every check assumes it.
- A character that can loot, gain XP and reputation, take money, craft and repair, and a training
  dummy nearby for COMBAT and the combat halves of other checks.
- A second Ka0s addon installed for PANEL-6, DIAG-18 and DEGRADED-1 (BankLedger or PanelMaster, which
  both draw wide AceGUI groups). Ka0s Loot History for OVR-9. A broker display (Titan Panel, Bazooka or
  ElvUI's data texts) for LAUNCH-7; skip that check if you run none.
- Back up `WTF/Account/<acct>/SavedVariables/PrettyChatDB.lua` before INSTALL-1 (it deletes the file)
  and keep a pre-v2 copy for INSTALL-7.
- Unless a check says otherwise, start on the `Default` profile, enabled, with every setting at its
  default (`/pc resetall`). Most steps use `LOOT_ITEM_SELF` (Categories ▸ Loot ▸ *Item Looted (Self)*):
  loot an item yourself to see its chat line.
- For DEGRADED, quit the game and rename `Interface/AddOns/PrettyChat/libs/LibKa0s` to
  `libs/LibKa0s.off`; DEGRADED-10 renames it back.

Which checks to run. Every row after the first also runs the routine row's four checks.

| What changed | Run |
|---|---|
| Routine (one format string, a doc edit, a small panel tweak) | INSTALL-2, TEST-1, OVR-10 for the changed string, PANEL-16 on its row |
| `OnEnable`, `ApplyStrings` or `settings/Schema.lua` | INSTALL, STATE, OVR, SLASH-1 |
| `settings/Panel.lua` | PANEL, RESET, DIAG-9 – 18, INSTALL-6, LAUNCH-6, OVR-8 |
| The slash surface in `settings/Slash.lua` | SLASH, STATE-3 – 4, PANEL-19 – 21, INSTALL-6, RESET-5, RESET-10, COMBAT-1, COMBAT-4, DIAG-1 – 8 |
| `modules/Diagnostics.lua`, the `diagnostics` row or the `debug` word | DIAG-1 – 8, DIAG-11 – 15, COMBAT-4 |
| A reset path (`ResetString` / `ResetCategory` / `ResetAll`) or a Reset / Defaults button | RESET |
| `core/DebugLogSetup.lua`, `media/`, or panel chrome (fonts, textures, borders) | DEGRADED, DIAG-9 – 19, PANEL-1 – 9, PANEL-14, RESET-3 – 7, RESET-10, COMBAT-1 – 2, INSTALL-2, OVR-8 |
| `core/LauncherSetup.lua`, the minimap row, `media/logos/` or the TOC's `## IconTexture` | LAUNCH, STATE, COMBAT-3 |
| The Profiles page or `/pc profile` | PROFILE, LAUNCH-6 |
| A re-vendor of `libs/LibKa0s/`, or a `core/*Setup.lua` seam file | DEGRADED, DIAG-16 – 19, PANEL-1 – 9, PANEL-14, RESET-3 – 7, RESET-10, COMBAT-1 – 2, INSTALL-2 |
| `ApplyStrings`, the combat watcher or `General.visibility`, or a sibling addon that parses loot or currency chat | OVR-4 – 6, OVR-9, STATE-5 – 6 |
| Before a tag, or after a client patch | Everything; after a patch also regenerate `GlobalStrings/` per [global-strings.md](./global-strings.md#regenerating-chunks-after-a-wow-patch) |

When a check fails, capture the exact steps, the chat output and any Lua error, note the client build
(`/dump GetBuildInfo()`), name the invariant in [ARCHITECTURE.md](./ARCHITECTURE.md) it breaks, and
file or update an issue per [README.md § Issues and feature requests](../README.md#issues-and-feature-requests).
Find the cause before changing anything; a fix that only makes the check pass is not a fix.

## INSTALL

- **INSTALL-1. Clean first load.** Quit, delete `PrettyChatDB.lua` (backed up), log in → no Lua error
  and no `[PC] schema not ready yet` line. `/pc test` fills the debug console with a block for every
  category. Result:
- **INSTALL-2. The version comes from the TOC.** `/reload` → no Lua error. Then `/pc version` and
  `/pc help` → both print the version on the TOC's `## Version:` line and agree with each other.
  **Fail:** a stale version rather than an error, which means a file-scope read ran before
  `core/EnvSetup.lua`. Result:
- **INSTALL-3. Overrides survive a reload.** Edit one Loot format on the panel and untick one Loot
  string's Enable, `/reload`, `/pc list Loot` → both changes are still there; the edited string's chat
  line uses the override and the unticked one uses Blizzard's wording. Result:
- **INSTALL-4. The master switch survives a reload.** `/pc set General.enabled false`, `/reload` → chat
  lines are still Blizzard's wording. `/pc set General.enabled true` → formatting returns at once,
  with no second reload. Result:
- **INSTALL-5. Only changes are stored.** From defaults, untick *Item Looted (Other)* (`LOOT_ITEM`)
  and nothing else. `/reload` and open `PrettyChatDB.lua` →
  `profiles.Default.categories.Loot.disabledStrings = { LOOT_ITEM = true }`, nothing else under Loot,
  and no `enabled = true` key anywhere (a nil reads as on). Result:
- **INSTALL-6. A value set back to its default is cleared.** On Loot ▸ `LOOT_ITEM_SELF` copy the New
  box's text, change it and press Enter (`/pc get Loot.LOOT_ITEM_SELF.format` returns the change),
  then paste the copied text back and press Enter. `/reload` and open the file →
  `profiles.Default.categories.Loot.strings` has no `LOOT_ITEM_SELF` entry, or there is no `strings`
  table at all. Result:
- **INSTALL-7. Schema v2 moves a Loot-only override onto Tradeskill.** Put back a pre-v2
  `PrettyChatDB.lua` whose Loot category holds an override for `LOOT_ITEM_CREATED_SELF` and has nothing
  under Tradeskill, log in → the override shows on the Tradeskill tab, and
  `/pc get Tradeskill.LOOT_ITEM_CREATED_SELF.format` returns it. Result:

## SLASH

- **SLASH-1. Both prefixes and the help index.** `/pc help`, then `/prettychat help` → identical
  output; the header reads `v<version> — slash commands (/prettychat is an alias for /pc)`; fourteen
  commands in this order: `help`, `config`, `version`, `list`, `get`, `set`, `reset`, `resetall`,
  `profile`, `test`, `debug`, `diagnostics`, `enable`, `disable`. Result:
- **SLASH-2. Bare `/pc` and an unknown verb.** `/pc`, then `/pc` followed by a few spaces → each opens
  the settings panel on the Ka0s Pretty Chat landing page, as `/pc config` does, and prints no help.
  `/pc bogus` → `unknown command 'bogus'` and then the help index. Result:
- **SLASH-3. `/pc list`.** → `Available settings`, then nine bracketed group headings and 170 setting
  rows, 180 lines in all: `[General]` first with its four Master controls rows, then `[Loot]` and the
  rest in category order, each category its `.enabled` row and then an `.enabled` and a `.format` row
  per string. Result:
- **SLASH-4. `/pc list <Category>`.** `/pc list loot`, `/pc list LOOT`, `/pc list Loot` → three
  identical Loot listings. `/pc list nope` → `unknown category 'nope'. Valid: General, Loot, Currency, …`.
  Result:
- **SLASH-5. `/pc list category` and `/pc list formatstring`.** `/pc list category` → `Categories (9)`
  then the nine names in alphabetical order (Currency, Experience, General, Honor, Loot, Misc, Money,
  Reputation, Tradeskill). `/pc list formatstring` → `Format strings (79)` then 79
  `Category.GLOBALNAME` pairs sorted by category and then name, from `Currency.CURRENCY_GAINED` to
  `Tradeskill.TRADESKILL_LOG_THIRDPERSON`. Neither falls through to the unknown-category line, and each
  header's count matches its list. Result:
- **SLASH-6. `/pc get` for every row kind.** `/pc get General.enabled`, `/pc get Loot.enabled`,
  `/pc get Loot.LOOT_ITEM_SELF.enabled` → `General.enabled = true`, `Loot.enabled = true` and
  `Loot.LOOT_ITEM_SELF.enabled = true`. `/pc get Loot.LOOT_ITEM_SELF.format` →
  `Loot.LOOT_ITEM_SELF.format = ` and then the format, unquoted, with single pipes
  (`|cffff0000Loot|cffffffff | …`). `/pc get Nope.bogus.path` → `Setting not found: Nope.bogus.path`.
  No Lua error. Result:
- **SLASH-7. `/pc set` boolean spellings.** `/pc set Loot.enabled` with each of `true`, `false`, `on`,
  `off`, `1`, `0`, `yes`, `no` → each lands and echoes `Loot.enabled = …`. `/pc set Loot.enabled bogus`
  → `Invalid value for Loot.enabled` with `expected true/false/on/off/1/0/yes/no` under it, and the
  value is unchanged. Finish on `/pc set Loot.enabled true`. Result:
- **SLASH-8. `/pc set` takes a format string.** `/pc set Loot.LOOT_ITEM_SELF.format ||cff00ff00CustomLoot||r %s`,
  then loot an item → the echo confirms it, and the chat line shows `CustomLoot` in green followed by
  the item link. `/pc reset Loot.LOOT_ITEM_SELF.format`. Result:
- **SLASH-9. A surplus conversion is refused.** `/pc set Loot.LOOT_ITEM_SELF.format Loot: %s %s` (one
  `%s` more than the default) → `Not saved — Loot.LOOT_ITEM_SELF.format asks for [string,string];
  LOOT_ITEM_SELF supplies [string]. …`, then `Invalid value for Loot.LOOT_ITEM_SELF.format` with
  `conversion signature` under it, in place of the echo. `/pc get Loot.LOOT_ITEM_SELF.format` →
  unchanged. On the panel, type a format with an extra conversion into the New box and press Enter →
  refused the same way, and the box snaps back to the stored format. **Fail:** a surplus conversion
  that saves; some write path bypasses `Schema.Set`, and the raise would then land in Blizzard's chat
  handler on every matching message. Result:
- **SLASH-10. Fewer conversions are allowed.** `/pc set Loot.LOOT_ITEM_SELF.format Loot: %s`, loot → it
  saves and the line renders. `/pc set Loot.LOOT_ITEM_SELF.format Loot happened` (no conversion at
  all), loot → it saves and the line reads `Loot happened`; `/pc test formatstring LOOT_ITEM_SELF`
  renders it with no `errored` count in the footer. **Fail:** a refusal here means the gate tests
  equality rather than a positional prefix. `/pc reset Loot.LOOT_ITEM_SELF.format`. Result:

## PANEL

- **PANEL-1. The landing page.** `/pc config` → Ka0s Pretty Chat selected in the left list and its
  landing page shown, headed `Ka0s Pretty Chat` with no breadcrumb. The logo sits top left (not blank,
  not a checkerboard), then the tagline **Prettier chat messages** (the TOC's `## Notes:`), then every
  slash command, `profile` included. Each command row has single spaces around the em dash, no color
  on the dash and a white description. **Fail:** a missing-texture box means the `.tga` was not
  packaged or `LOGO_PATH` in `settings/Panel.lua` drifted; a missing tagline means a file-scope TOC
  read missed the Env seam. Result:
- **PANEL-2. The tree expands itself.** With the AddOns list collapsed, `/pc config` → the rail shows
  General, Categories, then Profiles last, without a click on the arrow. The eight message categories
  are tabs on the Categories page and do not appear in the rail. **Fail:** a collapsed tree; a patch
  renamed `GetCategoryList` / `GetCategoryEntry` / `SetExpanded` and the `pcall` hides it
  ([`LIBKA0S-04`](https://github.com/tusharsaxena/PrettyChat/issues/9)). Result:
- **PANEL-3. The sub-page header.** Open each sub-page → `Ka0s Pretty Chat ▸ General`,
  `Ka0s Pretty Chat ▸ Categories`, `Ka0s Pretty Chat ▸ Profiles`, the separator a small gold arrow
  texture, and under the title a divider in the same gold. **Fail:** raw
  `|A:common-icon-forwardarrow:16:16|a` text or a missing-texture box means the atlas was retired; the
  fix is `BREADCRUMB_SEP` upstream in LibKa0s, never the vendored copy. Result:
- **PANEL-4. Blizzard fonts only.** On any sub-page → the title in the large gold options font
  (`GameFontNormalHuge`), descriptions and headings in normal Blizzard fonts, no custom typeface
  anywhere on the panel and no raw `|A…|a` text. Result:
- **PANEL-5. The scrollbar gutter.** Visit every page, short or long → the scrollbar gutter is reserved
  on each, with the bar grayed and inert where the content fits, and the Defaults button sits top right
  at the same inset on every page that has one. Result:
- **PANEL-6. The landing logo stays on its own page.** With another addon's AceGUI panel loaded, open
  the landing page, page to the other addon's settings without closing the window, and go back and
  forth three or four times through every page of both. Close, `/reload`, repeat once → the logo is on
  PrettyChat's landing page and nowhere else, with no ghost image and no unexplained 300px gap on any
  page of either addon. **Fail:** the landing body is drawing its own logo again instead of
  `H.BuildLandingPage`, or the library's `OnRelease` is no longer set (AceGUI pools that frame across
  every addon). Result:
- **PANEL-7. The General page.** Open General → one tab, **Master controls**, in the same band and art
  as the Categories strip, and below it: *Enable PrettyChat · General visibility*, then *Debug
  console*, then *Minimap button*, then **Test** · **Reset all settings** on one row with Test on the
  left. The paired controls sit at a true 50/50, and nothing but the strip is above them. **Fail:** no
  strip; a tab named `General`; Test or Reset missing; Test and Reset on separate rows. Result:
- **PANEL-8. The Categories tab strip.** Open Categories → eight tabs in the order Loot, Currency,
  Money, Reputation, Experience, Honor, Tradeskill, Misc (the order `/pc list` and `/pc test` print).
  The selected tab reads as attached to the page and does not highlight on hover; the others do. Click
  Currency, Misc, Currency → the body swaps to that category's Enable row, string list and editor, with
  no flicker of the previous tab's rows. Narrow the Settings window until the strip wraps → two flush
  rows, and the first control sits below the whole strip. **Fail:** every tab on its own row, or a
  second copy of a category's controls under the first. Result:
- **PANEL-9. The tab strip survives pooling.** On Categories cycle every tab three times, ending on
  the first, watching the label (the tab's own), the selection (the tab you pressed) and the band
  height (it does not move). Esc, reopen `/pc config` and walk the strip once more. **Fail:** a label
  carried over, a highlight on the wrong button, a body under the wrong tab, or a band that changes
  height; each is the library's pool handing back a frame it did not finish dressing. Result:
- **PANEL-10. The Categories footnote.** Open Categories → the first thing on every tab, above the
  Enable checkbox, is a gray line: "Strings on these tabs are rewritten only while the master Enable on
  the General page is on." Result:
- **PANEL-11. The string list.** Categories ▸ Loot → below *Enable Loot*, a bordered two-pane box
  (AceGUI's `TreeGroup`, as in any AceConfig window). The 200px left pane lists 17 entries by friendly
  name in sorted order, and the selected one carries a highlight bar. The right pane holds one editor
  with no heading. Click through several entries → the editor swaps, the highlight follows and the
  page does not shift. **Fail:** a wrapping strip of buttons; a bare column of colored text with no
  box; the longest label clipped (AceGUI's 175px default came back); a heading repeating the entry's
  name. Result:
- **PANEL-12. The box fills the page.** On a fresh login open Categories before any other page → the
  box takes about 90% of the space under the Enable row, with a margin at the bottom. Drag the Settings
  window's edge → both panes follow, and the tree's scrollbar comes and goes with the height. **Fail:**
  a box stuck near 260px with the page empty below it (the next-frame fit is not running, or
  `SetAutoAdjustHeight(false)` was dropped), or an editor clipped at the bottom. Result:
- **PANEL-13. Long lists and the remembered string.** Open Experience (twenty entries) → one column,
  and the tree pane scrolls itself rather than growing the page. Pick a string there, go to Loot → the
  Loot string you left is selected. Close and reopen the panel → every category is back on its first
  string (the pointer is session-only by design). Result:
- **PANEL-14. The editor layout.** Pick any string → `[Enable]` beside the gray `GLOBALNAME` caption
  (30% and 70% of the pane), then **Original** (disabled), **New** and **Preview** (disabled), each
  full pane width with its label above, then **Reset** on its own row at 40% of the pane. **Fail:**
  format boxes narrower than the pane. Result:
- **PANEL-15. The Preview renders color.** Loot ▸ `LOOT_ITEM_SELF`, read Preview → colored text (red
  `Loot`, green `You`), not raw `|cffff0000Loot|r`. **Fail:** raw escape codes; `InputBoxTemplate`'s
  color handling changed and the Preview needs a label-in-a-frame fallback. Result:
- **PANEL-16. Enter commits, and the row's Enable acts at once.** In `LOOT_ITEM_SELF`'s New box add a
  word at the front and press Enter → the Preview re-renders with the new format, and the next item you
  loot uses it. Untick the row's **Enable** and loot again → that line is Blizzard's own
  `You receive loot: …` at once, with no `/reload`. Tick it again and loot → your edited format is
  back. Press the row's Reset. **Fail:** the looted line keeps PrettyChat's format after the untick
  until a `/reload`, or the edit is gone after the re-tick. Result:
- **PANEL-17. The pipe convention.** Read `LOOT_ITEM_SELF`'s New box → color codes show doubled pipes
  (`||cffff0000`). `/pc get Loot.LOOT_ITEM_SELF.format` → single pipes (`|cffff0000`), the stored form.
  Result:
- **PANEL-18. A disabled category grays its strings.** On Loot untick *Enable Loot* → the string's
  Enable checkbox and New box are disabled, Original stays disabled, and Reset stays clickable. Tick it
  again. Result:
- **PANEL-19. A master change reaches every tab.** Leave Categories ▸ Loot open and
  `/pc set General.enabled false` → the Loot tab grays without a click, and every tab you then click is
  already gray. `/pc set General.enabled true` → the visible tab is live again, and so is each tab you
  visit after. Result:
- **PANEL-20. A slash write reaches the open panel.** Leave Loot ▸ `LOOT_ITEM_SELF` open and
  `/pc set Loot.LOOT_ITEM_SELF.enabled false` → its Enable checkbox unticks and New is disabled
  without a reopen. Set it back to `true`. Result:
- **PANEL-21. A panel write reaches the CLI.** Change a value on the panel and press Enter, then
  `/pc get` its path → the new value. Result:

## PROFILE

- **PROFILE-1. The Profiles page.** Settings ▸ AddOns ▸ Ka0s Pretty Chat ▸ Profiles → last in the rail,
  under the breadcrumb header, with no Defaults button and no tab strip. AceDB's profile controls are
  drawn inside the page, not in a floating window: the current profile (`Default`), New, Existing
  Profiles, Copy From, Delete a Profile and Reset Profile. Result:
- **PROFILE-2. A new profile starts from defaults.** On `Default` set a custom `LOOT_ITEM_SELF` format
  and untick *Enable Loot*. On the Profiles page type `Alt` into New and press Enter → at once, with no
  `/reload`, looted items use PrettyChat's default format and Categories ▸ Loot shows Enable ticked and
  the default text. Choose `Default` under Existing Profiles → the custom format and the unticked
  Enable are back. Keep `Alt` for PROFILE-3 to 10. Result:
- **PROFILE-3. Enable is per profile.** Choose `Alt` and untick *Enable PrettyChat* → chat goes back to
  Blizzard's wording. Choose `Default` → formatted again. Choose `Alt` → Blizzard's wording. Tick it on
  `Alt` and choose `Default`. Result:
- **PROFILE-4. One debug line per profile act.** `/pc debug on`, open the console. Switch profile on the
  page → exactly one `[Profile] switched → applied N restored M` line. Create `Scratch`, and on it use
  Copy From ▸ `Default` → exactly one `[Set] copied profile 'Default' → 'Scratch'` line. Press Reset
  Profile → exactly one `[Set] reset profile 'Scratch' to defaults` line. `/pc resetall` → exactly one
  `[Set] reset profile 'Scratch' to defaults (N rows)` line. Choose `Default`, delete `Scratch`,
  `/pc debug off`. Result:
- **PROFILE-5. `/pc profile` lists.** With `Default` and `Alt` present, `/pc profile` → a `Profiles`
  header, one row per profile sorted without regard to case with the current one suffixed
  `(current)`, then `/pc profile <name> switches profile`. No line ends in a colon. Result:
- **PROFILE-6. `/pc profile <name>` switches.** On `Alt` give `LOOT_ITEM_SELF` a visibly different
  format, then choose `Default`. With Categories ▸ Loot ▸ `LOOT_ITEM_SELF` open, `/pc profile Alt` →
  `Switched to profile 'Alt'.`; the New box shows `Alt`'s format without a reopen, and the next loot
  line uses it, exactly as choosing `Alt` on the page does. `/pc profile Alt` again →
  `Already on profile 'Alt'.` and nothing changes. The Profiles page shows `Alt` as current.
  `/pc profile Default` to go back. Result:
- **PROFILE-7. An unknown name is refused, never created.** `/pc profile Nope` →
  `No profile named 'Nope'.` then the list, and Existing Profiles on the page has no `Nope`.
  `/pc profile alt` → refused the same way, with `Did you mean 'Alt'?` before the list (names are
  case-sensitive). Result:
- **PROFILE-8. Quotes and spaces.** Create `My Alt` on the page and choose `Default`.
  `/pc profile "My Alt"` → switched to `My Alt`. `/pc profile 'Default'` → switched back. Delete
  `My Alt`. Result:
- **PROFILE-9. The verb answers while disabled.** On `Default`, `/pc disable`. `/pc profile` → the list,
  not the disabled line. `/pc profile Alt` → switched, and looted items are formatted again (`Alt` is
  enabled, so the addon comes back up). `/pc profile Default` → stood down again. `/pc enable`.
  Result:
- **PROFILE-10. No switch in combat.** Pull the training dummy. `/pc profile Alt` →
  `Can't switch profiles in combat.` and the profile does not change. `/pc profile` → the list still
  prints. Leave combat and delete `Alt`. Result:

## STATE

- **STATE-1. Disabling restores every original.** With a custom `LOOT_ITEM_SELF` format set,
  `/pc disable` (the same write as `/pc set General.enabled false`) → the echo
  `General.enabled = false`, in the shape `/pc set` uses. Loot an item and gain XP → both lines are
  Blizzard's wording. `/pc enable` → formatting returns and the custom format is still there. Result:
- **STATE-2. The verbs are the checkbox.** After `/pc disable`, open General → *Enable PrettyChat* is
  unticked. Tick it → formatting returns at once, as after `/pc enable`, and nothing prints to chat
  (the `General.enabled = true` echo belongs to the verbs; the panel writes through the schema).
  Result:
- **STATE-3. Settings verbs answer while disabled.** `/pc disable`, then `/pc`, `/pc help`,
  `/pc version`, `/pc get General.visibility`, `/pc list Loot`, `/pc set Loot.enabled true`,
  `/pc reset Loot.enabled` → each answers as it does when enabled (bare `/pc` opens the panel), and the
  minimap button is still there. `/pc enable`. **Fail:** any of these going quiet makes the switch
  one-way, reachable only through the panel. Result:
- **STATE-4. `/pc test` is refused while disabled.** `/pc disable`, `/pc test` → exactly one line,
  `Ka0s Pretty Chat is disabled — enable it with /pc enable` with the command in gold, and nothing is
  written to the console. `/pc enable`. **Fail:** the console opens and fills after the refusal.
  Result:
- **STATE-5. Disabled means not running.** Set *General visibility* to *Only out of combat*,
  `/pc debug on`, and `/dump PrettyChatCombatWatcher:IsEventRegistered("PLAYER_REGEN_DISABLED")` →
  `true`. `/pc disable`, dump again → `false`. Enter and leave combat twice → no `[Visibility]` line in
  the console and no change in chat wording. `/pc enable`, dump → `true`. **Fail:** `true` while
  disabled means a draw gate, not a stand-down. Result:
- **STATE-6. Re-enabling reads the current setting.** `/pc disable`, set *General visibility* to *Only
  in combat*, `/pc enable` → out of combat loot is Blizzard's wording, in combat it is PrettyChat's.
  **Fail:** the watcher armed for the mode you left (the stand-up replayed a snapshot). Set it back to
  *Always*. Result:

## COMBAT

- **COMBAT-1. `/pc config` is refused in combat.** In combat, `/pc config`, then
  `/run LibStub("AceAddon-3.0"):GetAddon("PrettyChat"):OpenConfig()` → both print the gray
  `cannot open settings during combat — Blizzard's category-switch is protected` and open nothing.
  Leave combat → `/pc config` works. Result:
- **COMBAT-2. A page opened from the sidebar in combat is covered.** In combat, open the Settings window
  from the game menu and click Ka0s Pretty Chat in the AddOns list → the window stays open; the page
  shows a dim cover reading *Settings are locked during combat.*, nothing under it can be clicked or
  scrolled, and chat gets one gray `settings are locked during combat — changes are refused until it
  ends` (clicking General as well adds no second line). No `ADDON_ACTION_BLOCKED` or taint error. Drop
  combat → the cover goes and the page draws from current state without a reopen. Result:
- **COMBAT-3. The minimap button in combat.** In combat, left-click the minimap button → the same gray
  refusal as COMBAT-1, and nothing opens. Result:
- **COMBAT-4. Diagnostics in combat.** In combat, `/pc diagnostics` → no Lua error, and the report's
  identity header reads `InCombatLockdown=true`. Result:

## OVR

- **OVR-1. A category off.** `/pc set Loot.enabled false`, then loot an item and gain XP → the loot line
  is Blizzard's, the XP line PrettyChat's. `/pc set Loot.enabled true` → loot formatting returns.
  Result:
- **OVR-2. One string off.** `/pc set Loot.LOOT_ITEM_SELF.enabled false`, then loot an item yourself and
  watch a group member loot one → `LOOT_ITEM_SELF` is Blizzard's wording while `LOOT_ITEM` is still
  PrettyChat's. Set it back to `true` → formatted again. Result:
- **OVR-3. The layers: addon over category over string.** Turn the master off with the category and
  string on → every line is Blizzard's. Master on, one string off → that string is Blizzard's, the rest
  formatted. Everything on → every line formatted. Result:
- **OVR-4. General visibility, Always and Never.** On *Always*, loot → PrettyChat's line. Set *Never*
  → the next loot line and every other category's are Blizzard's, with no `/reload`, and
  `/pc get General.visibility` reads `never`. Set *Always*. Result:
- **OVR-5. Only in combat.** Set *Only in combat*. Out of combat, loot → Blizzard's. In combat (open a
  container from your bags) → PrettyChat's. Drop combat, loot → Blizzard's again; each flip happens
  live at the combat boundary. Set *Always*. Result:
- **OVR-6. Only out of combat.** Set *Only out of combat* and repeat OVR-5 → the reverse: PrettyChat's
  out of combat, Blizzard's in combat. **Fail:** a combat mode that only takes effect after a
  `/reload` (`SyncCombatWatch` never armed, or its events went on the wrong frame). Set *Always*.
  Result:
- **OVR-7. `LOOT_ITEM_CREATED_SELF` lives under Tradeskill only.** Give
  `Tradeskill.LOOT_ITEM_CREATED_SELF.format` a visible custom format and create an item → the chat line
  uses it. `/pc test category Tradeskill` lists `LOOT_ITEM_CREATED_SELF` once, `/pc test category Loot`
  does not list it, and the Loot tab has no entry for it. Its Enable tooltip on Tradeskill is one line
  with no note naming another category. Result:
- **OVR-8. The chat frame keeps its own look.** Note your chat font (Blizzard's, or Prat's or ElvUI's),
  then loot an item and gain XP → the rewritten lines are in the same font, size and backdrop as every
  other chat line; only their colors and layout differ. PrettyChat adds no border, background or font
  change to the chat window. Result:
- **OVR-9. The chat text other addons read.** With Ka0s Loot History installed and its browser open on
  the current session, `/pc set General.visibility inCombat` and `/etrace` filtered to
  `CHAT_MSG_LOOT`. Loot one item out of combat, one in combat (open a container at the dummy), and one
  after combat → `CHAT_MSG_LOOT`'s arg1 is Blizzard's wording (`You receive loot: …`) out of combat and
  PrettyChat's (`Loot | You | + …`) in combat. Before Loot History's H-1 fix it records only the items
  looted in the state its first loot happened in, which is the known limitation and not a PrettyChat
  regression; after the fix it records all three. **Fail:** arg1 that does not change with combat
  state (the watcher is not re-applying the globals). `/pc set General.visibility always`. Result:
- **OVR-10. A real line for the string you changed.** Trigger the chat event the changed string
  formats (loot an item, gain XP, take money, and so on) and read the line in chat → PrettyChat's
  layout with the real values filled in, the shape the Preview and `/pc test` show, with no literal
  `%s` or `%d` and no Lua error. Result:

## TEST

- **TEST-1. `/pc test` writes to the console.** `/pc test` → the debug console opens and fills: the line
  `sample of every format string (preview ignores enable toggles):`, then per category a gold
  `Category: <name>` header and a three-line block per string (green `Name:`, `Original:`,
  `Formatted:`) followed by a blank line, then the footer `end of test output (N strings shown)`. Every
  line is `[Test]`-tagged, and nothing reaches the chat frame. **Fail:** the report in chat (the sink
  was dropped). Result:
- **TEST-2. The Test button.** General ▸ **Test** → the same report in the console, not in chat, and the
  console's copy mark gives you all of it. **Fail:** the console opens empty (the report was written
  before the window existed). Result:
- **TEST-3. The preview ignores the toggles.** Untick *Enable Loot*, `/pc test category Loot` → the Loot
  block still prints with its `Formatted:` lines. Tick it again. `/pc disable`, then General ▸ **Test**
  → the report still writes, and its second line is `(addon is currently disabled — these formats
  aren't being applied to live chat)`. `/pc enable`. Result:
- **TEST-4. The category filter.** `/pc test all` → the same as bare `/pc test`.
  `/pc test category Loot` → only the Loot block, footer count 17, with no `LOOT_ITEM_CREATED_SELF`.
  `/pc test category loo` → the same (case-insensitive prefix). `/pc test category General` →
  `(no matching strings)` and no footer. Result:
- **TEST-5. The format-string filter.** `/pc test formatstring CURRENCY_GAINED` → only the Currency
  header and the `CURRENCY_GAINED` block, footer count 1. `/pc test formatstring currency_gained` → the
  same. `/pc test formatstring LOOT_ITEM_CREATED_SELF` → only the Tradeskill header with that one block,
  footer count 1. Result:
- **TEST-6. Bad filters.** `/pc test category nope` → `unknown category 'nope'. Valid: General, Loot, …`
  and no report. `/pc test formatstring NOPE_NOPE` →
  `unknown format string 'NOPE_NOPE' — try /pc list formatstring` and no report. `/pc test bogus` → the
  usage line naming the four forms. No Lua error in any. Result:

## RESET

Every reset wipes each dimension it owns (a custom format and the enable flag), re-applies through
`ApplyStrings`, refreshes the panel, and writes one `[Set]` line counting the rows it changed
(debug-logging-§10).

- **RESET-1. The row Reset is always there.** Open Categories ▸ Loot → every string's editor shows
  Reset. Click it on a string already at its default → it stays visible, nothing changes, no error.
  Result:
- **RESET-2. The row Reset restores format and Enable.** On `LOOT_ITEM_SELF` edit New and press Enter,
  then untick its Enable. Click Reset → Enable is ticked again, New holds the default text and is
  editable, Preview re-renders it, and your own loot line uses PrettyChat's default (not Blizzard's).
  `/pc get Loot.LOOT_ITEM_SELF.enabled` → `true`, `.format` → the default. **Fail:** Enable stays
  unticked; the `disabledStrings` clear regressed. Result:
- **RESET-3. The Categories Defaults button covers every tab.** Edit a Loot format, untick a Loot string
  and edit a Money format. On Loot click the header **Defaults** → Loot and Money both revert, with no
  popup; `/pc list Loot` and `/pc list Money` read all defaults. Hovering Defaults reads "Reset the
  strings on every category tab to their defaults." **Fail:** Money keeps its edit (the handler narrowed
  to the visible tab). Result:
- **RESET-4. The Settings window's footer control does the same.** Set the RESET-3 edits up again and
  use the Blizzard Settings window's own footer defaults control → the same result as RESET-3. **Fail:**
  nothing happens (the canvas lost its `OnDefault`). Result:
- **RESET-5. `/pc reset <path>` resets one row.** Edit two Loot formats and untick one Loot string.
  `/pc reset Loot.LOOT_ITEM_SELF.format` → `Loot.LOOT_ITEM_SELF.format = ` and then the default, with
  single pipes as `/pc get` shows it, and `/pc list Loot` shows that row at default and the others
  still changed. `/pc set Loot.enabled false`, `/pc reset Loot.enabled` → only that row resets,
  echoing `Loot.enabled = true`. Result:
- **RESET-6. A category name explains the change.** `/pc set Loot.enabled false`, then `/pc reset Loot` →
  nothing resets, and three lines print: that `reset` now takes a setting path, not a category; the
  `/pc reset <path>` replacement with a pointer to `/pc list Loot`; and the Categories page's Defaults
  button and `/pc resetall` as the wider ones. `/pc reset loot` and `/pc reset Curr` → the same answer,
  resolving the name as `/pc list` does. `/pc set Loot.enabled true`. Result:
- **RESET-7. An unknown path.** `/pc reset zzz` and `/pc reset Bogus` → `Setting not found: zzz` and
  `Setting not found: Bogus`; nothing changes. Result:
- **RESET-8. Reset all settings asks first.** Edit formats in two categories, untick a string and
  `/pc disable`. General ▸ **Reset all settings** → a popup: *Reset this profile to the addon's
  defaults? Everything you have configured or added in it is discarded — your other profiles are not
  affected.* Nothing changes until you accept. **Yes** → the addon is enabled, every override cleared,
  every string ticked; `/pc list` reads all defaults. Result:
- **RESET-9. General's Defaults button is the same reset.** Edit a Loot format and set *General
  visibility* to *Never*. On General click the header **Defaults** → the same popup as RESET-8, and
  **Yes** → Loot at default, visibility *Always*. Hovering Defaults reads "Reset every setting to its
  default." **Fail:** no popup. Result:
- **RESET-10. `/pc resetall`.** Scatter changes across categories and `/pc disable`, then
  `/pc resetall` → `all settings reset to defaults`, `/pc get General.enabled` → `true`, and
  `/pc list` reads all defaults. Result:
- **RESET-11. Nothing lingers after a reset.** Untick `LOOT_ITEM_SELF` and edit its format, clear both
  with the row Reset, and `/reload`. Repeat three times, clearing them with the Categories Defaults
  button, with `/pc reset Loot.LOOT_ITEM_SELF.enabled` followed by
  `/pc reset Loot.LOOT_ITEM_SELF.format`, and with `/pc resetall` → each time, before the `/reload`,
  `/pc list Loot` reads all defaults, and after it `profiles.Default.categories.Loot` in
  `PrettyChatDB.lua` is absent or empty. **Fail:** a leftover `disabledStrings` entry or override
  after any one of the four. Result:
- **RESET-12. One log line per reset.** `/pc debug on`, open the console, then a row Reset, the
  Categories Defaults button, the Settings window's footer defaults control and `/pc resetall` →
  exactly one line each and nothing else: `[Set] reset Loot.LOOT_ITEM_SELF: N rows`,
  `[Set] reset Categories: N rows` (for the button and again for the footer control), and
  `[Set] reset profile 'Default' to defaults (N rows)`. N counts only rows that differed, so a reset of
  untouched rows reads `0 rows`. No `[Reset]` line. **Fail:** a line ending ` (stopped by an error)`;
  the reset raised partway, and the error it names is a bug. Result:
- **RESET-13. A reset shows in an open panel.** Leave Categories ▸ Loot ▸ `LOOT_ITEM_SELF` open, untick
  its Enable and edit its format, then from chat `/pc reset Loot.LOOT_ITEM_SELF.enabled` and
  `/pc reset Loot.LOOT_ITEM_SELF.format` → the checkbox ticks and New shows the default, with no reopen.
  Change it again and `/pc resetall` → the visible tab refreshes the same way. Result:

## LAUNCH

- **LAUNCH-1. The button wears the logo.** Log in and look at the minimap ring → a PrettyChat button
  showing the addon's logo, not a blank square, a Blizzard icon or a question mark. The same art is
  beside Ka0s Pretty Chat in the AddOns list. **Fail:** a blank or checkerboard button means
  `media/logos/prettychat.logo.128.tga` is missing or not TGA type 2, 32 bpp (layout-§4's recipe
  regenerates it). Result:
- **LAUNCH-2. Left-click opens settings.** Left-click the button → the settings panel on its landing
  page, as `/pc config` opens it; nothing is toggled or printed. Result:
- **LAUNCH-3. The options menu.** Right-click the button → a menu titled Ka0s Pretty Chat with one
  ticked checkbox, Enabled, and nothing else (no Locked, Test mode or Show window). Untick it → chat
  prints `General.enabled = false` exactly as `/pc disable` does, chat lines go back to Blizzard's
  wording, and General's *Enable PrettyChat* is unticked. Right-click again → Enabled unticked and still
  clickable; tick it → the same line `/pc enable` prints, and formatting returns. **Fail:** right-click
  opens the panel; a grayed Enabled while disabled; an echo that differs from `/pc disable`'s. Result:
- **LAUNCH-4. The tooltip.** Hover the button → `Ka0s Pretty Chat  v<version>`, `Enabled: Yes` in
  green, `Left-click: Open settings`, `Right-click: Options menu`, and nothing else. `/pc disable`,
  hover → the same four lines with `Enabled: No` in red. `/pc enable`. **Fail:** no tooltip, a second
  title or second set of hints, or an Enabled line that lags until `/reload`. Result:
- **LAUNCH-5. The Minimap button row.** General ▸ untick *Minimap button* → the button goes at once.
  `/reload` → still gone. Tick it → back at the angle it had. Drag it a third of the way round the ring,
  untick and tick → it returns where you dragged it. Result:
- **LAUNCH-6. A hidden button stays hidden.** Create `Alt` on the Profiles page. Untick *Minimap
  button*, `/reload`. `/pc profile Alt`, then `/pc profile Default`, then General ▸ **Reset all
  settings** ▸ Yes, then General's header **Defaults** ▸ Yes → the button stays hidden through every
  one. Tick it again and delete `Alt`. Result:
- **LAUNCH-7. Broker displays.** With a broker display installed, add PrettyChat from its plugin list →
  the row wears the same logo and the label Ka0s Pretty Chat, with no empty value cell (the object is a
  `launcher`, not a data source). Left-click opens the settings panel and right-click the same Enabled
  menu. Result:

## DIAG

- **DIAG-1. The report lands after the trace.** `/reload` with the console closed. `/pc debug on`,
  `/pc test category Loot`, then `/pc diagnostics` → in the console the trace is still there, above
  `[Diag] ==== Ka0s Pretty Chat diagnostics begin ====`; the report ends with
  `[Diag] ==== Ka0s Pretty Chat diagnostics end: N line(s) ====`; one chat line says
  `Diagnostic report written to the debug console: N lines. Use Copy to share it.` with the same N. The
  sections run in the order [debug.md](./debug.md) lists, `[State]` to `[Addons]`, and none reads
  `section <name> failed`. **Fail:** the trace is gone (the report path cleared the console). Result:
- **DIAG-2. The globals line.** Read the report's `[Globals]` line → `mismatch=0` on a clean install.
  With another chat addon loaded, any mismatching names are ones it rewrites, and `[Addons]` names it.
  **Fail:** a mismatch with no other chat addon; `ApplyStrings` and the report disagree about `_G`.
  Result:
- **DIAG-3. Pipes survive the paste.** `/pc set Loot.LOOT_ITEM_SELF.format ||cff00ff00Loot:||r %s`, then
  `/pc diagnostics` → the `[Set]` row for that path shows the pipes doubled (`||cff00ff00`), neither
  stripped nor rendered as color. Press the copy mark and paste into a text editor → the trace, both
  reports and both markers, and no `|c` escape except the doubled ones. Paste the doubled value back
  into `/pc set` → it round-trips. `/pc reset Loot.LOOT_ITEM_SELF.format`. Result:
- **DIAG-4. The report ignores the logging flag.** `/pc debug off`, `/pc diagnostics` → the whole report
  lands; the console header still reads `Debug: OFF`, and changing a setting writes no `[Set]` line.
  **Fail:** a missing report, or a header that flipped to `Debug: ON`. Result:
- **DIAG-5. Every spelling of the report.** `/pc debug diagnostics`, `/prettychat diagnostics` and
  `/prettychat debug diagnostics` → each writes the same report. Result:
- **DIAG-6. No short alias.** `/pc debug diag` → `usage: /pc debug [on | off | diagnostics]` and no
  report. `/pc diag` → `unknown command 'diag'` and the help index, no report. Result:
- **DIAG-7. The report while disabled.** `/pc disable`, then `/pc diagnostics` and
  `/pc debug diagnostics` → both write a full report rather than the disabled line; `[State]` reads
  `enabled(stored)=false stoodDown=true`, and the combat-watcher line says it is stood down.
  `/pc enable`. Result:
- **DIAG-8. The README's bug-report steps.** `/reload`, leave the console closed, and follow the
  README's `## Reporting a bug` word for word → every step works as written, and the paste holds the
  trace and the whole report. Result:
- **DIAG-9. The Debug console checkbox drives the window only.** `/pc debug on`. On General tick *Debug
  console* → the window appears, its header still reads `Debug: ON`, and no `debug logging ON/OFF` ack
  prints. Untick it → the window hides and logging stays on. **Fail:** an ack, or a flipped header (the
  box is driving `SetEnabled` rather than show and hide). Result:
- **DIAG-10. The checkbox follows the window.** Tick *Debug console*, then close the window with its
  close mark or Esc → the checkbox unticks itself. `/pc debug` → the window opens and the checkbox ticks
  itself. Result:
- **DIAG-11. The console's first open.** `/pc debug on`, then `/pc debug` → the header toggle reads
  `Debug: ON` in green, the close mark and Esc both close it, and no Lua error fires. **Fail:** a blank
  header or a dead Esc (the initial sync threw mid-build). Result:
- **DIAG-12. The line counter.** Read the footer → a right-aligned `N / 3000 lines` in the log's
  monospace font. Run `/pc test all` a few times → N climbs on every append and pins at
  `3000 / 3000 lines`. **Fail:** a counter that never moves. Result:
- **DIAG-13. The scrollbar.** With the log overflowing, spin the wheel over it → the thumb tracks, top
  for the oldest lines and bottom for the newest. Drag the thumb → the log follows, with no jitter.
  **Fail:** `attempt to call a nil value` on open (old C getters, anti-pattern #41), or top meaning
  newest. Result:
- **DIAG-14. Copy at a full buffer.** With the counter at `3000 / 3000 lines`, click the copy mark → the
  copy window opens without a noticeable hitch, holds all 3000 lines, and Ctrl+A, Ctrl+C and scrolling
  stay responsive. Result:
- **DIAG-15. Clear.** Click the clear mark (the middle of the three) → the log empties, the counter
  reads `0 / 3000 lines`, and the scrollbar goes inert but stays visible, with the gutter width
  unchanged. Result:
- **DIAG-16. The console's font and chrome.** `/pc debug` and make a few lines → the log is monospaced
  (columns line up), the window has a dark backdrop and a thin border with no missing-texture boxes, and
  the title reads `Pretty Chat — Debug`. The copy window's text is monospaced too. **Fail:**
  proportional text means `NS.MediaFont` answered nil and the font fell back to `STANDARD_TEXT_FONT`
  (check `libs/LibKa0s/media/fonts/JetBrainsMono-Regular.ttf` shipped and `core/MediaSetup.lua` loads
  before `core/Constants.lua`); no text at all means the fallback was replaced by a path. Result:
- **DIAG-17. The title-bar marks.** Look at the right end of the console's title bar → copy, clear and
  close marks, three small square icons of one size and pitch, off-white, brightening on hover, with no
  tooltip on any of them (by design: it would cover the first log line). The copy window has the same
  close mark. **Fail:** a × with the words Copy and Clear means `addonName` is no longer passed beside
  `name` in `core/DebugLogSetup.lua`'s descriptor; some marks missing means
  `libs/LibKa0s/media/icons/{copy,clear,close}.tga` did not ship. Result:
- **DIAG-18. The window edge matches the collection's.** Open another Ka0s addon's console beside this
  one → a hard black 1px outer border with a lighter gray 1px line inside it, background
  `0.06, 0.06, 0.08` at 92% alpha, a gold title and a gray divider under the title bar, and the same
  close mark on both; the copy window wears the same edge. Side by side the two differ only in title.
  **Fail:** different art on the two means one addon is on an older LibKa0s payload. Result:
- **DIAG-19. No raw locale key on screen.** Walk `/pc config` (landing page, General, Categories and
  its eight tabs with the Defaults button and footnote, Profiles), the console (title, the
  `Debug: ON` / `Debug: OFF` toggle, the counter, the copy window's title), the *Debug console*
  checkbox's tooltip, and `/pc help`, `/pc list`, `/pc get General.enabled`,
  `/pc set General.enabled maybe`, `/pc reset nonsense` → no string matches `^[A-Z][A-Z0-9_]+$`, in
  particular none of `DEFAULTS_LABEL`, `DEBUG_ON`, `DEBUG_OFF`, `CLEAR`, `COPY`, `COPY_TITLE`, `LINES`,
  `CHECKBOX_LABEL`, `CHECKBOX_TOOLTIP`, `LIST_HEADER`, `LIST_GROUP`, `HELP_HEADER`, `NOT_FOUND`,
  `INVALID`, `USAGE_GET`, `USAGE_SET`, `USAGE_RESET`, `ERR_BOOL`, `ERR_STRING`. Result:

## DEGRADED

- **DEGRADED-1. Nothing errors, and the reason is said once.** With `libs/LibKa0s` renamed aside, log
  in → no Lua error at load or in any DEGRADED step. The first `[PC]` line is exactly
  `[PC] The LibKa0s library is missing from this installation of Ka0s Pretty Chat (expected in libs/LibKa0s); running on reduced built-in fallbacks.`,
  once for the whole session. Its clause before the semicolon matches another Ka0s addon's in the same
  state apart from the name. Result:
- **DEGRADED-2. `/pc list`.** → one line ending `…(expected in libs/LibKa0s), so the settings CLI is
  unavailable.`, not a half-rendered listing. Result:
- **DEGRADED-3. `/pc debug`.** `/pc debug on` → the color-coded `debug logging ON` ack, the flag
  flips, and one `…, so the debug console window is unavailable.` line. `/pc debug on` again → the ack
  alone. `/pc debug` → the unavailable line once more (each entry point says it once), and a second
  `/pc debug` prints nothing. Result:
- **DEGRADED-4. `/pc config`.** → `…, so the settings panel is unavailable.` Result:
- **DEGRADED-5. `/pc resetall` still works.** Change a setting with `/pc disable`, then `/pc resetall` →
  the reset runs and chat formatting returns; the player whose panel will not open is the one who
  needs it (options-ui-§1). Result:
- **DEGRADED-6. Verbs that never needed the library.** `/pc help` → the index. `/pc test` → the report,
  in chat this time (there is no console), every line `[PC]`-prefixed. Result:
- **DEGRADED-7. The version survives.** `/pc version` → the TOC's version, not `?` and not a stale
  literal (`core/EnvSetup.lua`'s fallback reads the TOC through `C_AddOns.GetAddOnMetadata`). Result:
- **DEGRADED-8. Diagnostics.** `/pc diagnostics` → exactly
  `[PC] /pc diagnostics is unavailable: the LibKa0s library did not load.`, and nothing is written.
  Result:
- **DEGRADED-9. `/pc profile`.** `/pc profile` and `/pc profile Default` → each the one
  `…, so the settings CLI is unavailable.` line; no profile changes. Result:
- **DEGRADED-10. Restore.** Quit, rename `libs/LibKa0s.off` back, log in → no missing-library line,
  `/pc list` prints the full listing, and the console is monospaced with its three marks. Result:

## Non-English client

Run on a client set to **deDE or frFR**, the two the collection's other locale checks use
(ConsumableMaster LOC-1, KickCD LOC-1).

This addon's whole job is overwriting localized `_G` chat format strings, which is why it needs this
section more than most. `tests/test_defaults.lua` checks every override against Blizzard's real
signature, an override may ask for fewer conversions than Blizzard passes and never more, but the
signatures come from `GlobalStrings/`, an **enUS** dump. A locale whose string for the same global
carries fewer conversions, or orders them positionally, is checked against nothing. That file's
header records what the defect looks like in the wild: `FACTION_STANDING_INCREASED_GUARDIAN` put a
name into `%d` and raised for every user on a routine reputation gain.

English output is the design, not a defect: every override replaces the client's sentence with
PrettyChat's layout, and its labels (`Loot`, `Bonus`, `You`, `Money`) are hardcoded English. On a
German client the overridden lines read in English; do not file that. What these checks look for is
an error, an artifact, or the wrong original.

- **LOC-1. The snapshot holds the client's own strings.** `PrettyChat:SnapshotOriginals`
  (`core/PrettyChat.lua:190-199`) reads `_G[globalName]` at `OnEnable`. `/pc test formatstring
  LOOT_ITEM_SELF` → the `Original:` line is the client's own German (or French) sentence. **Fail:** an
  English `Original:` line; the snapshot reads something other than `_G`, and every restore hands
  players text their client never wrote. Record the `Original:` line verbatim for `LOOT_ITEM_SELF`,
  `CURRENCY_GAINED`, `LOOT_MONEY`, `FACTION_STANDING_INCREASED_GUARDIAN`,
  `COMBATLOG_XPGAIN_FIRSTPERSON`, `COMBATLOG_HONORGAIN`, `CREATED_ITEM` and `ERR_QUEST_REWARD_EXP_I`:
  their signatures on this locale exist nowhere in this repository. Result:
- **LOC-2. Disabling gives the client's strings back.** `/pc set General.enabled false`, then loot, gain
  reputation and take money → all three lines are the client's untouched German.
  `/pc set General.enabled true` and trigger them again → PrettyChat's layout. The restore arm is
  `ApplyStrings` (`modules/Override.lua:332-341`). **Fail:** English lines while disabled; the same
  defect as LOC-1 seen from the other end. Result:
- **LOC-3. One real line per category, watching for the raise.** With every category enabled, trigger
  one line from each: loot an item, receive a currency, take money, gain reputation, gain XP while
  grouped (so the guardian and exhaustion variants fire), gain honor, craft something, complete a quest
  for its XP. Watch chat and the error frame together → eight lines in PrettyChat's layout and no Lua
  error. **Fail:** `bad argument #N to 'format'` (this locale passes fewer arguments than the enUS
  signature); a literal `%s`, `%d` or `%1$s` left in a line (a conversion nothing filled, or a
  positional form the override does not carry); a line in the client's own sentence while its category
  is enabled (see LOC-4). Result:
- **LOC-4. Globals this client does not define.** General ▸ **Test** and scan every `Original:` line →
  none reads the gray `(original not available)`. **Fail:** any `Original:` line that reads
  `(original not available)`; the panel's Original box shows the same placeholder for that string. It
  does not crash: the override writes a global nothing reads, silently, while the panel shows it
  enabled. Record every global that shows the placeholder; the list is the finding. Result:
- **LOC-5. Nothing else moved.** Run INSTALL-1, INSTALL-3, STATE-1 and TEST-4 to TEST-6 on this client →
  the same behavior as on English. **Fail:** any Lua error (a localized string reached code that
  assumed English). Result:

No sign-off exists for LOC-1 to LOC-4 without a non-English client: `tests/test_defaults.lua` compares
against an enUS dump by construction, `tests/test_locale.lua` checks this addon's own `NS.L` manifest
and never the client's string table, and the mock defines whatever globals the cases need, in English.
Until the pass runs, record this section as unrun, not as coverage.

## Pending sign-off

A check is listed here until a client run records a pass for it in its current form: every check new
in the 2026-09-29 rework, every check whose expectation the rework corrected against the code, and
every check carried over from the old numbering (`T-NN`, the quick recipe, `SMK-F001`) with no
recorded pass. The old document had no Result lines, so most checks are here. Sign one off on its own
`Result:` line, then remove its ID from this table.

Not listed, because a recorded pass covers them and the rework did not change what they expect:
DIAG-1, DIAG-3 – 8, DIAG-14, COMBAT-4 and DEGRADED-8 (T-39 steps 1–2 and 4–10, T-29b step 6 and T-90
step 7, passed in the owner's run of 2026-09-26 as rows PC-S1 – PC-S11 and PC-X1 of the diagnostics
rollout's report), and LAUNCH-2 – 4 (T-65 and T-65a, passed in the owner's minimap re-check of
2026-09-25 on the launcher-menu builds, step X1.4 of the 2026-09-23 remediation's checklist). Both
records are in the Ka0sAddonsCommonTasks repository.

| ID | Origin | Why it is owed |
|---|---|---|
| PROFILE-1 – 10 | New: the Profiles page (`SP-PC-01`) and the `/pc profile` verb (`SP-PC-02`) | New in this rework; never run |
| DEGRADED-9 | New: `/pc profile` on the library-absent stub (`SP-PC-02`) | New in this rework; never run |
| SLASH-1 | T-03, T-38 | Corrected: the help header ends with the `/prettychat` alias note |
| SLASH-3 | T-30 | Corrected: 170 setting rows and 180 lines, not "about 170 lines" |
| SLASH-5 | T-31a | Corrected: neither header ends in a colon |
| SLASH-6 | T-32 | Corrected: the library's `Setting not found` wording, and `get` echoes `<path> = <value>` with the format unquoted |
| SLASH-7 | T-33 | Corrected: the library's refusal wording |
| SLASH-10 | T-34a steps 3–4 and 6, T-51 | Corrected: a format with fewer conversions saves and renders |
| INSTALL-6 | T-43 | Corrected: the SavedVariables key is `profiles.Default` |
| PANEL-7 | T-29a step 1, T-100 | Corrected: the layout gained the Minimap button row |
| PANEL-11 | T-102 | Corrected: Loot lists 17 strings, not nineteen |
| PANEL-16 | T-28, quick recipe step 4 | Corrected: the row's Enable toggle half was added |
| STATE-2 | T-68 | Corrected: the checkbox prints nothing; only the verbs echo |
| TEST-1 | Quick recipe step 2, T-52, T-103 (2) | Corrected: the report goes to the debug console, not chat |
| RESET-5 | T-35, T-93 (1)–(2) | Corrected: the reset echo shows single pipes, as `/pc get` does |
| RESET-7 | T-55, T-93 (5) | Corrected: `/pc reset Bogus` answers `Setting not found: Bogus` |
| RESET-11 | T-57 | Corrected: the third arm resets by path |
| RESET-12 | T-58, T-26 | Corrected: the footer control writes its own line |
| RESET-13 | T-59 | Corrected: resets by path and `/pc resetall` |
| LAUNCH-6 | T-67, T-26b (first) | Corrected: the profile switch uses the Profiles page and `/pc profile` |
| DEGRADED-3 | T-90 step 4 | Corrected: the missing window is reported once per entry point |
| DEGRADED-6 | T-90, T-52 | Corrected: the `/pc test` chat form lives here now |
| DEGRADED-7 | T-90, T-98 | Corrected: the tagline and console halves went; T-98 was also listed as recorded but not run (the 2026-08-24 LibKa0s modules execution record) |
| LOC-4 | T-106 | Corrected: fails on `(original not available)`; also never run (below) |
| LOC-1 – 3, LOC-5 | T-104, T-105, T-107 | Marked NOT YET RUN since the 2026-09-07 remediation (session 6, `M5-08`); needs a deDE or frFR client |
| PANEL-9 | T-99 | Marked NOT YET RUN since the LibKa0s v1.27.0 re-vendor (session 3, `M4-01`) |
| INSTALL-2 | Quick recipe step 1, T-97 steps 1–3 | T-97 listed as recorded but not run (the 2026-08-24 LibKa0s modules execution record); no later pass |
| PANEL-1 | T-20, T-62, T-95, T-97 step 4 | As INSTALL-2 for T-97; no pass recorded for the rest |
| PANEL-6 | T-29c | On the 2026-09-07 cycle's owed checklist; no result recorded |
| OVR-9 | SMK-F001 | Session Q.12 of the 2026-09-23 checklist, whose sign-off table is empty |
| DIAG-2 | T-39 step 3 | The 2026-09-26 diagnostics run recorded the other T-39 steps, not this one |
| INSTALL-1, INSTALL-3 – 5, INSTALL-7 | T-01, T-02, T-14, T-50, T-53 (expected 4) | No recorded result |
| SLASH-2, SLASH-4, SLASH-8, SLASH-9 | T-38, T-31, T-34, T-34a steps 1–2 and 5 | No recorded result |
| PANEL-2 – 5, PANEL-8, PANEL-10, PANEL-12 – 15, PANEL-17 – 21 | T-21, T-22, T-23, T-24, T-26a, T-26b (second), T-29, T-40 – T-42, T-54, T-61, T-95, T-102 | No recorded result |
| STATE-1, STATE-3 – 6 | T-10, T-68, T-68a | No recorded result |
| COMBAT-1 – 3 | T-37, T-96, T-65 (the in-combat line) | No recorded result |
| OVR-1 – 8, OVR-10 | T-11 – T-13, T-53 (expected 1–3), T-63, T-101, quick recipe step 3 | No recorded result |
| TEST-2 – 6 | Quick recipe step 2, T-52a, T-103 (1) | No recorded result |
| RESET-1 – 4, RESET-6, RESET-8 – 10 | T-25 – T-27, T-26b (first), T-36, T-56, T-93 (3)–(4), T-94 | No recorded result |
| LAUNCH-1, LAUNCH-5, LAUNCH-7 | T-64, T-66, T-69 | No recorded result |
| DIAG-9 – 13, DIAG-15 – 19 | T-29a steps 2–5, T-29b steps 1–5 and 7, T-60, T-60a, T-91, T-92 | No recorded result |
| DEGRADED-1, DEGRADED-2, DEGRADED-4, DEGRADED-5, DEGRADED-10 | T-90 steps 1–3, 5 and 6, and its restore | No recorded result |
