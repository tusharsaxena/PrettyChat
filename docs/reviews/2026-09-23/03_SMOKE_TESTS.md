# 03 — Smoke tests (PrettyChat, in-client, after the changes in 02 land)

Every headless suite (lint, tests, `--list`, lizard, vendor sync, cross-addon greps) already ran in
Step 0; see `01_FINDINGS.md`. The one headless pre-flight line after the changes land:

`~/.claude/wow-addon/bin/ka0s-bounded lua5.1 tests/run.lua && ~/.claude/wow-addon/bin/ka0s-bounded luacheck .`
must be green, and `lua tests/run.lua --list` must equal `docs/test-cases.md` with the README badge updated.

## Pre-flight

1. Retail client, `## Interface: 120100`. Install PrettyChat from this branch **and LootHistory** (for
   SMK-F001) into `Interface\AddOns\`. Keep the rest of the Ka0s set loaded as usual.
2. `/console scriptErrors 1`, then `/reload`. Keep BugSack or the default error frame visible.
3. `/pc debug on`, then `/pc debug`, so the debug console is open and logging.
4. Use a character that can loot a mob and craft one item (any profession with a trivial recipe), near a
   target dummy.
5. Back up `WTF\Account\<acct>\SavedVariables\PrettyChat.lua` before SMK-C03.

---

## SMK-F001: the chat text contract with LootHistory (C-01, H-1)

- **Change covered:** C-01 (docs), plus proof of the mechanism that H-1 fixes in LootHistory.
- **Setup:** PrettyChat defaults, then `/pc set General.visibility inCombat`. LootHistory is enabled,
  and its browser is open on the current session.
- **Steps:**
  1. `/etrace`, filtered to `CHAT_MSG_LOOT`.
  2. Out of combat, kill a mob and loot one item. In `/etrace`, read arg1 of `CHAT_MSG_LOOT`.
  3. Pull the target dummy (you are now in combat) and loot one item, for example by opening a container
     from your bags. Read arg1 again.
  4. Leave combat and loot again.
  5. Check LootHistory's browser for all three items.
- **Expected:**
  - Out of combat, arg1 is Blizzard's wording ("You receive loot: …").
  - In combat, arg1 is PrettyChat's (`Loot | You | + …`).
  - **Before H-1 lands:** LootHistory records only the items looted in the state the first loot happened
    in.
  - **After H-1:** LootHistory records all three.
- **Pass / Fail:**
  - PASS if the arg1 wording changes with combat state. That proves the mechanism F-001 describes.
  - After H-1 is released, PASS only if all three items are recorded.
  - Otherwise FAIL.

## SMK-C02 / SMK-C03: migration v2 collapses the Loot copy (C-02, C-03)

- **Change covered:** C-03 (one registration per global) on top of C-02 (runner hardening).
- **Setup:**
  - On the **old build**, set `/pc set Loot.LOOT_ITEM_CREATED_SELF.format MIGRATED %s` and
    `/pc set Loot.LOOT_ITEM_CREATED_SELF_MULTIPLE.enabled false`.
  - Create a second AceDB profile holding the same Loot override. If the addon exposes no profile UI,
    hand-edit a `profiles["Alt"]` entry in the SavedVariables file while logged out.
  - `/logout`, then install the new build.
- **Steps:**
  1. Log in. Read the console.
  2. `/pc get Tradeskill.LOOT_ITEM_CREATED_SELF.format`
  3. `/pc list Loot`
  4. Craft one item.
  5. `/pc test formatstring LOOT_ITEM_CREATED_SELF`
  6. `/reload` and repeat step 1. Then switch to the `Alt` profile, if you created one, and repeat step 2.
- **Expected:**
  - One `[Migrate] v1→v2 (1 step)` line on the first login, and no migrate line after the `/reload`.
  - Step 2 prints `MIGRATED %s`.
  - `/pc list Loot` has no `LOOT_ITEM_CREATED_SELF*` rows.
  - Crafting prints `MIGRATED <item>`.
  - The test report shows exactly one block, under Tradeskill.
  - The `Alt` profile also reads `MIGRATED %s` after the switch.
  - No Lua errors.
- **Pass / Fail:** PASS only if every one of those holds, including the second profile.

## SMK-C04: the Original box never shows our own text (C-04)

- **Setup:** defaults, then `/reload`.
- **Steps:**
  1. Open Settings → Ka0s Pretty Chat → Categories → Loot → *Item Looted (Self)*. Read **Original**.
  2. `/pc test formatstring LOOT_ITEM_SELF`, and read the `Original:` line in the console.
- **Expected:** both show Blizzard's "You receive loot: %s." wording, never a `Loot | You` string.
- **Pass / Fail:** PASS if neither surface shows a PrettyChat-colored string as the original.

## SMK-C05: degraded `/pc test` prints to chat (C-05)

- **Setup:** log out. Rename `Interface\AddOns\PrettyChat\libs\LibKa0s` to `LibKa0s.off`, then log in.
- **Steps:** `/pc test category Loot`, twice.
- **Expected:**
  - The first run prints one `[PC] The LibKa0s library is missing … unavailable.` line, then the report
    in chat.
  - The second run prints the report in chat again.
  - No Lua errors.
- **Pass / Fail:** PASS if the report appears in chat both times.
- **Cleanup:** restore the folder name.

## SMK-C06: corrected wording (C-06)

- **Steps:**
  1. Hover over the **Test** button on General → Master controls.
  2. `/pc help`.
- **Expected:**
  - The tooltip says the report goes to the debug console and that `/pc test` does the same.
  - The help row for `resetall` reads "Reset every setting to defaults".
- **Pass / Fail:** exact text match.

## SMK-C07: New box still round-trips `||` (C-07)

- **Steps:**
  1. In any string's **New** box, type `||cff00ff00X||r %s` and press Enter.
  2. `/pc get <that path>`.
- **Expected:**
  - The Preview renders a green `X`.
  - `/pc get` echoes the value with `||` doubled.
  - The console shows one `[Set]` line.
- **Pass / Fail:** exact behaviour as described, with no error.

## SMK-C09: order and output unchanged after the sorted-names refactor (C-09)

- **Steps:** `/pc list formatstring`, `/pc test`, then open the Experience tab.
- **Expected:**
  - The list is alphabetical within each category, identical to the pre-change output (paste both into
    a diff).
  - The Experience tree lists the strings in the same order as before.
- **Pass / Fail:** the diff is empty.

C-01 and C-08 have no separate in-client step: C-01 is documentation and is covered by SMK-F001, and C-08
is lint configuration only.

---

## Regression suite

1. **Load:** `/reload` produces no errors. The console `[Init]` line (after `/pc debug on`) reads
   `PrettyChat v1.5.x, schema v2, profile 'Default'`.
2. **Fresh install:** move `PrettyChat.lua` out of SavedVariables, then log in. Defaults apply, and
   looting shows `Loot | You | + …`.
3. **Disable / enable:**
   - `/pc disable`, then loot. Blizzard wording appears.
   - `/pc test` prints one refusal line naming `/pc enable`.
   - `/pc` still opens the panel.
   - `/pc enable` restores PrettyChat's wording.
4. **Combat:** with visibility `inCombat`, enter and leave combat at the dummy. The console shows one
   `[Visibility]` line per boundary. There is no `Interface action failed` text.
5. **Settings panel:**
   - Open it from `/pc config`, from Esc → Options → AddOns, and from the minimap button (left and right
     click).
   - Toggle every Master-controls row once, one category Enable, and one string Enable.
   - Press Defaults on the Categories page, then **Reset all settings** and confirm.
6. **In combat:** `/pc config` is refused with one gray line, and the page is covered, not closed.
7. **Profile reset:** after the global reset, the console shows exactly one
   `[Set] reset profile 'Default' to defaults (N rows)` line. The minimap button's hidden or shown state
   survives the reset.
8. **Cross-addon (collection-wide):**
   - Type each of the ten roots (`/at /am /bl /cm /kcd /lh /mm /pm /pc /wg`) and confirm each reaches
     its own addon.
   - Open Settings → AddOns. Each addon appears exactly once, and PrettyChat shows exactly the
     `General` and `Categories` sub-pages.

## Localization sanity

This bundle raises no locale findings. The one wording change (C-06) is enUS-only, which is consistent
with the ratified `localization-§1` row. There is no non-enUS step.

## Performance spot-checks

The addon holds the `performance-§12` exemption, so there is no `/pc perf` capture to take. C-09's
"cheaper" claim is unmeasured and is recorded as such in `05_FINAL_SUMMARY.md`. There is no
frame-time check to run, because the path is not on a per-frame loop.

---

## Sign-off

| ID | Tested? | Pass/Fail | Notes |
|---|---|---|---|
| SMK-F001 (C-01, H-1) | | | |
| SMK-C02/C03 | | | |
| SMK-C04 | | | |
| SMK-C05 | | | |
| SMK-C06 | | | |
| SMK-C07 | | | |
| SMK-C09 | | | |
| Regression 1–8 | | | |
