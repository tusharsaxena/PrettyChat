# PrettyChat review — 2026-10-07 — 03 In-client smoke tests

These are in-client checks for the changes in `02_PROPOSED_CHANGES.md`. The headless suites already ran today (see the measurement block in `01_FINDINGS.md`); this checklist does not repeat them.

## Pre-flight

1. Headless gate after the changes land: `ka0s-bounded lua5.1 tests/run.lua` (0 failed) and `ka0s-bounded luacheck .` (0/0). Confirm that `docs/test-cases.md` and the README badge moved in the same commit as any count change.
2. Use a Retail client, `## Interface: 120100`. The game loads `GIT/PrettyChat` through its symlink, so test from that checkout only and never from a side worktree.
3. Run `/console scriptErrors 1`.
4. For C-05 only: `/console taintLog 1`, then `/reload`.
5. For U-1, load **LootHistory and PrettyChat together**. For every other test, PrettyChat alone is fine.

## Per-change tests

### U-1 (F-001): LootHistory survives PrettyChat rewrites (OVR-9)

- **Setup:** LootHistory build with U-1 applied, plus PrettyChat. A character near lootable mobs or a vendor (buy and sell for currency or money).
- **Steps:**
  1. Loot one item and confirm LootHistory records it.
  2. `/pc set General.visibility inCombat`.
  3. Loot one item out of combat.
  4. Enter combat with a training dummy, leave combat, then loot again.
  5. `/pc disable`, loot, then `/pc enable` and loot.
  6. Change `Loot.LOOT_ITEM_SELF.format` in the panel, then loot.
- **Expected:** Every loot after step 1 appears in LootHistory's browser with the correct item and quantity, and there are no Lua errors.
- **Pass if:** all five post-change loots are recorded. Before U-1, steps 3 to 6 drop records.

### C-02 (F-002): blank format refused

- **Steps:**
  1. `/pc config` → Categories → Loot → select any string.
  2. Clear the **New** box and press Enter.
  3. Type three spaces and press Enter.
- **Expected:** Each attempt prints one `[PC] Not saved — a format cannot be blank…` line. The New box snaps back to the stored value, and `/pc get Loot.<NAME>.format` is unchanged.
- **Pass if:** nothing is stored and chat lines of that type still render.

### C-03 (F-003): Categories reset confirms

- **Steps:**
  1. Edit two strings in different tabs.
  2. Click the Categories page header **Defaults** and choose **No**.
  3. Click it again and choose **Yes**.
- **Expected:** **No** leaves both edits in place. **Yes** resets both, and one `[Set] reset Categories: 2 rows` line appears if logging is on.
- **Pass if:** both outcomes match.
- **Also check:** the Settings window footer **Defaults** path. Record whether it double-prompts, which is the accepted trade-off in `02`.

### C-04 (F-004): newer stamp left alone

- **Setup:** In `WTF/Account/<acct>/SavedVariables/PrettyChatDB.lua`, with the client closed, set `["schemaVersion"] = 99` and add `["Loot"] = { ["strings"] = { ["FUTURE_GLOBAL"] = "x" } }` under the active profile's `categories`.
- **Steps:** Log in, then `/reload`, then exit the client.
- **Expected:** The file still holds `schemaVersion = 99` and the `FUTURE_GLOBAL` key, and there are no errors.
- **Pass if:** both survive.

### C-05 (F-005): taint claim verified

- **Steps:**
  1. `/dump issecurevariable("LOOT_ITEM_SELF")`
  2. Loot items in and out of combat. Open the world map and the talent UI in combat, and use action bars.
  3. Exit the client and read `Logs/taint.log`.
- **Expected:** Step 1 answers `false` and `PrettyChat`. `taint.log` has no `ADDON_ACTION_BLOCKED` or `ADDON_ACTION_FORBIDDEN` attributed to PrettyChat.
- **Pass if:** no blocked action names PrettyChat. If one does, reopen F-005 as a `[taint]` runtime finding.

### C-06 and C-10: comment and doc fixes

No in-client step. Covered by review of the diff.

### C-11 (F-011): `General` not offered to `/pc test category`

- **Steps:**
  1. `/pc test category General`
  2. `/pc test category`
- **Expected:** Step 1 prints the "unknown category" usage line. The "Valid:" list in both lines omits `General`.
- **Pass if:** true.

### C-13 (F-013), optional

No in-client step.

## Regression suite

- `/reload` is clean, and a fresh-SavedVariables login populates the defaults.
- `/pc`, `/prettychat`, `/pc help`, `/pc test` (output goes to the debug console) and `/pc diagnostics` all work.
- Loot, money, currency, XP, reputation and honor lines render in PrettyChat's format with the addon on, and in Blizzard's with it off.
- Switch profile on the Profiles page: strings follow the incoming profile.
- `/pc resetall` → confirm → defaults.
- Enter and leave combat with the panel open: the page is covered, then redraws.
- **Cross-addon:** type each of the 11 roots (`at`, `am`, `bl`, `cm`, `kcd`, `lh`, `mm`, `pm`, `pfe`, `pc`, `wg`) and confirm each reaches its own addon. In Settings → AddOns, each addon should appear once, and PrettyChat's General, Categories and Profiles pages once each.

## Sign-off

| ID | Tested? | Pass/Fail | Notes |
|---|---|---|---|
| U-1 | | | |
| C-02 | | | |
| C-03 | | | |
| C-04 | | | |
| C-05 | | | |
| C-11 | | | |
| Regression | | | |
