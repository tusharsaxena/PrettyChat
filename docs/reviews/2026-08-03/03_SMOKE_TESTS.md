# Smoke tests — post-implementation checklist (2026-08-03)

Run this **after** the changes in `02_PROPOSED_CHANGES.md` are applied. Every step is literal: type
what is written, look for what is described.

## Pre-flight

1. **Build/install.** Copy the repo folder to `World of Warcraft/_retail_/Interface/AddOns/PrettyChat`
   (or symlink it). Confirm `PrettyChat.toc` still reads `## Interface: 120007` (single latest-Retail
   line — toc-file-§3) and `## Version:` matches what you expect `/pc version` to print.
2. **Headless gate first.** From the repo root: `lua tests/run.lua` → expect `N passed, 0 failed`
   (baseline before this work was `255 passed, 0 failed`; the count will grow). Then `luacheck .` →
   `0 warnings / 0 errors`. Do not enter the game on red.
3. **Make failures visible.** In-game: `/console scriptErrors 1`, then `/reload`. Keep the chat
   window where system messages land visible.
4. **Character/realm requirements.** Retail, any character. You need: a character that can gain and
   lose reputation with a generic faction (C-01), a training dummy or any mob for the combat tests,
   and one non-enUS client install for the localization section.
5. **Fresh-SavedVariables baseline.** For the first pass, exit the game and move
   `WTF/Account/<ACCT>/SavedVariables/PrettyChat.lua` aside so the addon provisions defaults from
   scratch.

---

## C-01 — Corrected reputation templates

**Change covered:** the two templates whose conversion signature disagreed with Blizzard's.

**Setup:** fresh SavedVariables (or `/pc reset Reputation.FACTION_STANDING_DECREASED_GENERIC.format`
and the guardian equivalent). `/console scriptErrors 1`.

**Steps:**
1. `/pc get Reputation.FACTION_STANDING_DECREASED_GENERIC.format` — note the value.
2. Trigger a generic reputation **decrease** (any quest/turn-in or kill that lowers a faction with no
   specific message, e.g. an opposing-faction reputation in a zone that pairs two factions).
3. Trigger a reputation **increase on a guardian-type faction** if reachable; if not reachable in a
   reasonable time, simulate the exact call Blizzard makes:
   `/run print(format(FACTION_STANDING_INCREASED_GUARDIAN, "Testfaction", 25))`
   and `/run print(format(FACTION_STANDING_DECREASED_GENERIC, "Testfaction"))`.

**Expected:** both lines print PrettyChat-formatted text. **No** red Lua error, no
`bad argument #N to 'format'` popup, no `Interface action failed` text.

**Pass/Fail:** PASS only if both `/run` calls print a formatted line and neither raises.

---

## C-02 — Write-seam validation + truthful preview

**Change covered:** `Schema.Set` refuses a signature-incompatible format; Preview/`/pc test` render
against Blizzard's argument list.

**Setup:** settings panel open at **Loot** (`/pc config` → Loot).

**Steps:**
1. In any string's **New** box type a value with an extra conversion the original does not have —
   e.g. for `LOOT_ITEM_PUSHED_SELF` append ` x%d` beyond what the original declares — and press
   Enter.
2. Read chat.
3. `/pc get Loot.LOOT_ITEM_PUSHED_SELF.format`.
4. From chat: `/pc set Loot.LOOT_ITEM_PUSHED_SELF.format You got %s and %d and %d`.
5. Now type a **valid** replacement (same conversions as the original, different wording/colors) and
   press Enter.
6. Look at that string's **Preview** box; then run `/pc test formatstring LOOT_ITEM_PUSHED_SELF`.
7. Type a value that drops a *trailing* conversion (the F-011 shape) and press Enter.

**Expected:**
- Steps 1–2: one `[PC]`-tagged refusal line naming the path and what was expected. No trailing colon
  on that line. No Lua error.
- Step 3: the value is **unchanged** — the rejected write did not land.
- Step 4: same refusal, same wording, from the CLI.
- Step 5: accepted, echoed as `path = value` with the gold key / white value coloring and `||`-doubled
  pipes.
- Step 6: Preview and `/pc test` both render the line with sample arguments **in Blizzard's argument
  order**; the "Original" and "Formatted" lines both render without `(error: …)`.
- Step 7: accepted (truncation at the tail is allowed).

**Pass/Fail:** PASS only if the extra-conversion write is refused on **both** surfaces with identical
wording, the stored value is untouched, and the trailing-truncation write is accepted.

---

## C-03 — Original read from the live snapshot; GlobalStrings retired

**Change covered:** the "Original Format String" box, and the removal of the eager enUS dump.

**Setup:** enUS client first. `/reload`.

**Steps:**
1. `/pc config` → **Loot**. Read the **Original** box of the first string.
2. `/run print(_G.PrettyChat and "ns leak" or "ok")` — expect `ok` (no `_G` namespace).
3. Toggle the category off (Enable unchecked), then on again. Re-read the same **Original** box.
4. `/reload`, reopen the panel, re-read it.
5. Confirm the ten `GlobalStrings_0NN.lua` entries are gone from `PrettyChat.toc` and that the addon
   still loads with no error.

**Expected:** the Original box shows Blizzard's real template (with `||`-doubled pipes) at every
step, **including after the override has been applied and removed** — never blank, never the
PrettyChat value, never `(original not available)` for a key that exists.

**Pass/Fail:** PASS only if the Original text is identical at steps 1, 3 and 4.

---

## C-04 — Snapshot taken once, sentinel for absent keys

**Change covered:** `OnEnable` re-entry no longer records overrides as originals.

**Setup:** panel open, addon enabled, a visibly customized string.

**Steps:**
1. `/run LibStub("AceAddon-3.0"):GetAddon("PrettyChat"):Disable()`
2. `/run LibStub("AceAddon-3.0"):GetAddon("PrettyChat"):Enable()`
3. Open `/pc config` → the customized string's page and read its **Original** box.
4. `/pc set General.enabled false` then `/pc test` and read the `Original:` lines.
5. `/pc set General.enabled true`.

**Expected:** at steps 3 and 4 the original is still **Blizzard's** text, not PrettyChat's. Step 4's
report prints without error while the addon is disabled.

**Pass/Fail:** PASS only if no `Original` anywhere shows PrettyChat-formatted text.

---

## C-05 — Ordering index

**Change covered:** one ordered name list / category partition in the schema.

**Steps:**
1. `/pc list Tradeskill` — note the exact row order.
2. `/pc config` → **Tradeskill** — compare the on-page block order top to bottom.
3. `/reload`, repeat 1 and 2.
4. `/pc list` (full listing) — confirm groups appear in `General, Loot, Currency, Money, Reputation,
   Experience, Honor, Tradeskill, Misc` order.

**Expected:** chat order and panel order are identical, and stable across `/reload`. Cross-registered
strings (`LOOT_ITEM_CREATED_SELF`, `LOOT_ITEM_CREATED_SELF_MULTIPLE`) still appear under both Loot
and Tradeskill, and the Enable tooltip on each still carries the "Shared with …" note.

**Pass/Fail:** PASS only if steps 1/2 match before and after the reload.

---

## C-06 — Batch reset seam

**Change covered:** `ResetCategory` / `ResetAll` / `ResetString` through one tail.

**Setup:** `/pc debug on`, then `/pc debug` to open the console. Customize at least three Loot
strings and disable one of them.

**Steps:**
1. Panel → **Loot** → **Defaults** button.
2. Read the debug console.
3. Panel → **General** → **Reset all to defaults** → confirm **Yes** in the popup.
4. Read the debug console again.
5. `/pc resetall` from chat.
6. A single string's **Reset** button on any page.

**Expected:** each bulk action emits **exactly one** `[Reset]` console line with its applied/restored
counts — never one line per string. The panel repaints immediately (checkbox states, New boxes and
Previews all back to defaults). The popup appears for step 3 and resetting only happens on **Yes**.

**Pass/Fail:** PASS only if the console shows one line per bulk action and the panel is visibly
in sync afterwards without a reload.

---

## C-07 — Locale coverage and the trailing colon

**Steps:**
1. `/pc test` — read the first line.
2. Panel → any category page, hover the category **Enable** checkbox and the **Defaults** button.
3. Hover the Enable checkbox of `LOOT_ITEM_CREATED_SELF` (a cross-registered string).

**Expected:** step 1's header does **not** end in `:`. Step 2's label reads `Enable Loot` and the
tooltips render as complete sentences with the category name substituted. Step 3's tooltip still
carries the "Shared with Tradeskill …" note.

**Pass/Fail:** PASS only if no printed chat line in the whole `/pc test` report ends in a colon.

---

## C-08 — Naming/doc hygiene

**Steps:**
1. `/pc version` — compare to `## Version:` in the TOC.
2. `/pc help` — compare row-for-row with the README command table.
3. `/pc config` → landing page — compare the command list with `/pc help` (same rows, no leading
   indent).

**Expected:** identical in all three comparisons; the help header names `/prettychat` as the alias.

**Pass/Fail:** PASS only if all three agree.

---

## Regression suite (not tied to one change)

| # | Check | Expected |
|---|---|---|
| R-01 | `/reload` with the panel open | no Lua error; panel reopens and repaints |
| R-02 | Fresh login with SavedVariables removed | defaults populate; `/pc list` shows every row; no error |
| R-03 | Login sequence with `/etrace` open (ADDON_LOADED → PLAYER_LOGIN → PLAYER_ENTERING_WORLD) | no error at any stage |
| R-04 | `/pc config` **while in combat** (attack a dummy first) | a gray `[PC]` refusal line, panel does **not** open, no `Interface action failed` red text |
| R-05 | Leave combat, `/pc config` again | opens to Ka0s Pretty Chat, left tree expanded to show all nine sub-pages |
| R-06 | Open every one of the nine sub-pages, toggle each page's Enable off and on | each toggle repaints its own page; the General master toggle grays every page's controls |
| R-07 | `/pc list`, `/pc list category`, `/pc list formatstring`, `/pc list Loot`, `/pc get`, `/pc set`, `/pc reset`, `/pc resetall`, `/pc test`, `/pc test category Loot`, `/pc test formatstring LOOT_ITEM`, `/pc debug`, `/pc debug on`, `/pc debug off`, `/pc version`, `/pc help`, `/pc bogus` | every one answers; `bogus` prints `unknown command 'bogus'` then the help index |
| R-08 | `/pc reset Loot` (the retired category form) | the deprecation notice naming both replacements, not a "setting not found" |
| R-09 | Rename `libs/LibKa0s` aside, `/reload` | addon loads; one honest "LibKa0s is missing" line; `/pc help`, `/pc test`, `/pc debug on` still work; `/pc config` and `/pc list` each say what is unavailable **once**; no Lua error. Restore the folder afterwards |
| R-10 | Blizzard Settings window → the addon's page → the window's own footer **Defaults** control | resets that category (same as the header button) |
| R-11 | Debug console: open, `/pc debug on`, generate lines, scroll, **Copy**, close with Esc | scrollbar and line counter track; the General page's Debug console checkbox follows the window's visibility |

## Localization sanity (C-03, C-07 touched user-facing text)

Switch the client to **deDE** (or frFR) and re-run:

1. C-03 steps 1–4. **Expected:** the Original box now shows the **German** Blizzard template — this
   is the whole point of C-03. Before the change it showed English.
2. C-07 steps 1–3. **Expected:** English text (no deDE locale file ships), rendered from the
   metatable fallback — never a raw key, never a half-substituted sentence like `Enable %s`.
3. `/pc test` on a few categories. **Expected:** originals render in German, PrettyChat values render
   with their color codes, no `(error: …)` lines.

## Performance spot-checks (C-03 and C-05 are perf-tagged)

1. **Memory, before/after C-03.** With the pre-change build: `/run collectgarbage("collect"); print(collectgarbage("count"))`
   right after login. Repeat with the post-change build. **Expected:** a drop on the order of a
   couple of MB (the 22,879-entry table is gone). Record both numbers.
2. **Login time.** `/console scriptProfile 1` → `/reload` → `/run UpdateAddOnCPUUsage(); print(GetAddOnCPUUsage("PrettyChat"))`.
   Record before/after. **Expected:** lower after C-03 (ten fewer files parsed).
3. **Write cost, C-05.** `/run local t=debugprofilestop() for i=1,50 do PrettyChatDBTest=nil end` is
   not meaningful here; instead time 50 writes:
   `/run local S=LibStub("AceAddon-3.0"):GetAddon("PrettyChat"); local t=debugprofilestop(); for i=1,50 do PrettyChat_TestSet() end; print(debugprofilestop()-t)`
   — or simply toggle one category Enable 20 times and confirm no visible stall. **Expected:** no
   perceptible hitch; the number should improve versus the pre-change build.

## Sign-off

| ID | Tested? | Pass/Fail | Notes |
|---|---|---|---|
| C-01 | | | |
| C-02 | | | |
| C-03 | | | |
| C-04 | | | |
| C-05 | | | |
| C-06 | | | |
| C-07 | | | |
| C-08 | | | |
| Regression R-01…R-11 | | | |
| Localization sanity | | | |
| Perf spot-checks | | | |
| U-01 (after re-vendor) | | | `diff -r` empty; panel unchanged |
