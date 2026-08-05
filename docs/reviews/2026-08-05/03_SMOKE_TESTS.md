# 03 — Manual smoke tests (in-client)

Execute **after** the changes in `02_PROPOSED_CHANGES.md` are applied. Everything that runs headless
(luacheck, `tests/run.lua`, `--list`, lizard) already ran in Step 0 of the review and is recorded in
`01_FINDINGS.md`; it is **not** repeated here.

**Single pre-flight command line** (run once, from the repo root, before you log in):

```
luacheck . && lua5.1 tests/run.lua
```

Expect `0 warnings / 0 errors in 17 files` and `256 passed, 0 failed, 256 total` (255 → 256 because
C-02 adds a case). If either is red, stop — nothing below is meaningful.

---

## Pre-flight (in-client)

1. Install the working tree as `Interface/AddOns/PrettyChat/`. Confirm `PrettyChat.toc` still reads
   `## Interface: 120007` and that the client's build matches (`/run print(select(4, GetBuildInfo()))`).
2. `/console scriptErrors 1` — **required**. F-001 and F-002 manifest as Lua errors raised inside
   Blizzard's chat code; with error display off you will see a missing chat line and nothing else.
3. Take a backup of `WTF/Account/<ACCOUNT>/SavedVariables/PrettyChat.lua`. Several checks below need a
   **fresh** SavedVariables and one needs the **pre-existing** one.
4. Character requirements: any level; needs access to a faction that grants reputation (see T-01/T-02)
   and, for the guardian check, a hunter/warlock pet or a guardian-type NPC (see T-02's fallback).
5. Locale: the default arm is enUS. Section **L-01** repeats a subset on deDE or frFR.

---

## T-01 — `FACTION_STANDING_DECREASED_GENERIC` no longer errors

**Change covered:** C-01 — the generic reputation-decrease override matches Blizzard's one-argument
signature (`F-001`).

**Setup:** fresh SavedVariables (delete `PrettyChat.lua` from `WTF`, then log in). Confirm the
Reputation category is on: `/pc get Reputation.enabled` → `true`.

**Steps:**

1. `/pc get Reputation.FACTION_STANDING_DECREASED_GENERIC.format` — note the value; it must contain
   exactly one conversion (`%s`) and **no** `%d`.
2. Trigger a generic reputation loss. Easiest reliable route: attack a neutral faction NPC whose
   reputation loss is reported without an amount (e.g. a Steamwheedle Cartel or Booty Bay guard on a
   character not already hated by them). If no such target is available, force the code path with
   `/run DEFAULT_CHAT_FRAME:AddMessage(format(FACTION_STANDING_DECREASED_GENERIC, "Booty Bay"))` — this
   is the exact call shape Blizzard makes.
3. Observe the chat line.

**Expected:** a formatted PrettyChat line naming the faction. **No** red
`Interface\FrameXML\… bad argument #3 to 'format'` error, and no error popup.

**Pass / Fail:** PASS only if the line renders **and** no Lua error is raised. Before C-01, step 2
raises. Re-run step 2 three times to be sure the error is not merely being suppressed after the first.

---

## T-02 — `FACTION_STANDING_INCREASED_GUARDIAN` no longer errors

**Change covered:** C-01 (`F-002`).

**Setup:** same session as T-01.

**Steps:**

1. `/pc get Reputation.FACTION_STANDING_INCREASED_GUARDIAN.format` — the first conversion must be a
   **string** slot (`%1$s` or `%s`), not `%d`.
2. Force the Blizzard call shape:
   `/run DEFAULT_CHAT_FRAME:AddMessage(format(FACTION_STANDING_INCREASED_GUARDIAN, "Ulfar", 25))`
3. If you can generate it naturally (guardian-experience gain), do that too and compare.

**Expected:** a line containing both `Ulfar` and `25`, correctly ordered. No Lua error.

**Pass / Fail:** PASS only if both substituted values appear and no error is raised. Before C-01,
step 2 raises `number expected, got string`.

---

## T-03 — no other default broke under the corrected arity rule

**Change covered:** C-01 + C-02 (regression sweep over the four *safe* mismatches the new test allows).

**Setup:** same session.

**Steps:**

1. `/pc test` — the full before/after report for every string.
2. Scroll the whole report. Look specifically at the four entries the new test tolerates:
   `Honor.COMBATLOG_DISHONORGAIN`, `Loot.LOOT_DISENCHANT_CREDIT`, `Tradeskill.OPEN_LOCK_OTHER`,
   `Tradeskill.OPEN_LOCK_SELF`.
3. Read the footer line.

**Expected:** the footer reads `end of test output (N strings shown)` with **no** `, M errored`
clause. Every `Formatted:` row renders text, not a gray `(error: …)` line.

**Pass / Fail:** PASS if the errored count is absent/zero. A non-zero count names the offending
string in the block above it.

---

## T-04 — the panel's Original row shows this client's string

**Change covered:** C-03 (`F-004`).

**Setup:** enUS client, fresh SavedVariables, `/reload` after login completes.

**Steps:**

1. `/pc config` → left rail → **Loot**.
2. Find the block for `LOOT_ITEM_SELF` (the `GLOBALNAME` caption is in the gray left column of row 2).
3. Read the **Original** box (row 1, right column, greyed out).
4. Compare against `/run print(LOOT_ITEM_SELF)` — but **before** doing that, note that PrettyChat has
   already overwritten `_G`. Instead compare against `/pc test formatstring LOOT_ITEM_SELF`, whose
   `Original:` row reads the same snapshot.
5. Repeat for one string in **Currency** and one in **Tradeskill**.

**Expected:** the panel's Original box and `/pc test`'s `Original:` row describe the **same** Blizzard
format, with the panel showing it pipe-doubled (`||cff…`) because it is an editable-style box.

**Pass / Fail:** PASS if the two surfaces agree for all three strings. Before C-03 they can agree on
enUS by coincidence — the real discriminator is L-01.

---

## T-05 — the four newly-translatable strings still read correctly in English

**Change covered:** C-04 (`F-006`).

**Setup:** enUS client.

**Steps:**

1. `/pc config` → **Loot**. Hover the top **Enable Loot** checkbox.
2. Hover the **Defaults** button in the page header.
3. Find the `LOOT_ITEM_CREATED_SELF` block (registered under both Loot and Tradeskill) and hover its
   **Enable** checkbox.

**Expected, verbatim:**

* checkbox label `Enable Loot`; tooltip body `Enable or disable all Loot string overrides.`
* Defaults tooltip `Reset all Loot strings to defaults.`
* the cross-registration tooltip's gray second paragraph begins `Shared with Tradeskill — both
  registrations write the same Blizzard global; the last category to apply wins on /reload.`

**Pass / Fail:** PASS only if all four strings are byte-identical to the pre-change wording. `%s`
interpolation must not have introduced a doubled space or a missing one.

---

## T-06 — the landing page still lists every command

**Change covered:** C-05 (`F-008` — the dot → colon call on `LandingRows`).

**Setup:** any.

**Steps:**

1. `/pc config` (the parent page, not a category).
2. Scroll to **Slash Commands**.
3. Compare the list against `/pc help` in chat.

**Expected:** ten rows — `help`, `config`, `version`, `list`, `get`, `set`, `reset`, `resetall`,
`test`, `debug` — in the same order and with the same descriptions as `/pc help`, differing only in
leading indentation. No Lua error on opening the page.

**Pass / Fail:** PASS if all ten render and the two surfaces agree. A `nil`-index error here is the
exact failure C-05 pre-empts.

---

## L-01 — Localization sanity (deDE or frFR)

**Applies because the review raised locale findings (F-004, F-006).**

**Setup:** switch the client to deDE (or frFR) and restart. Keep the **same** SavedVariables.

**Steps:**

1. `/pc config` → **Loot** → the `LOOT_ITEM_SELF` block. Read the **Original** box.
2. `/pc test formatstring LOOT_ITEM_SELF` and read the `Original:` row.
3. Hover **Enable Loot** and read the tooltip.

**Expected:**

* **(1) and (2) both show the GERMAN/FRENCH Blizzard format**, and they agree with each other. This
  is the whole point of C-03 — before it, (1) showed English while (2) showed German.
* (3) renders the English text (this addon ships only `locales/enUS.lua`); what matters is that it
  renders as one coherent sentence with the category name interpolated, not as visibly stitched
  fragments.

**Pass / Fail:** PASS only if (1) and (2) match and are in the client's language.

---

## Regression suite (not tied to one change)

| # | Check | Expected |
|---|---|---|
| R-1 | `/reload` with the panel open | No error, panel reopens to the same page, values unchanged |
| R-2 | Fresh login with **deleted** SavedVariables | `PrettyChatDB` is created; every category renders defaults; `/pc get General.enabled` → `true` |
| R-3 | Login with the **pre-change** SavedVariables backup | Loads clean. Any row the user had overridden keeps that override — including the two `FACTION_STANDING_*` rows, whose stored text is now an explicit override rather than an auto-cleared default (see C-01's risk note). `/pc reset Reputation.FACTION_STANDING_DECREASED_GENERIC.format` restores the corrected default |
| R-4 | `ADDON_LOADED` → `PLAYER_LOGIN` → `PLAYER_ENTERING_WORLD` | No Lua error at any stage (`/console scriptErrors 1` still on) |
| R-5 | Enter combat, then `/pc config` | Refuses with the gray notice naming combat; **no** taint error. Leave combat, `/pc config` opens normally |
| R-6 | Esc → Options → find **Ka0s Pretty Chat** in the left rail | Opens the same parent page `/pc config` opens; sub-categories are expanded |
| R-7 | Toggle every control on the **General** page once | Master Enable off → every Blizzard original returns to chat; on → overrides return. Debug console checkbox opens/closes the window without starting logging |
| R-8 | Per-category **Defaults** button on Loot | Every Loot row returns to default in one pass; the debug console (if logging on) shows exactly **one** `[Reset]` line, not one per string |
| R-9 | `/pc resetall` | Same, across every category, one `[Reset]` line |
| R-10 | AceDB profile switch (if a second profile exists) | Panel and chat both follow the new profile; no stale values in the open panel |
| R-11 | `/pc debug on` → reproduce T-01 → `/pc debug` → **Copy** | The console holds the `[Set]`/`[Reset]` traces; Copy box populates |

---

## Performance spot-check

This addon ships **no** perf harness — `tests/perf.lua`, `docs/performance.md` and `docs/perf-runs/`
are all absent by a recorded decision (`docs/pending/LEDGER.md:66`, LIBKA0S-12), so there is no
`/<addon> perf` two-arm capture protocol to run and no bucket figures to read. The fallback applies,
and only if F-005 is ever acted on:

1. `/run collectgarbage("collect"); print(collectgarbage("count"))` immediately after
   `PLAYER_ENTERING_WORLD`, with PrettyChat enabled.
2. Repeat with PrettyChat disabled in the AddOns list.
3. The difference is dominated by `NS.GlobalStrings` (22,879 entries, 2.0 MB of source). Record both
   numbers before and after any change that touches the eager GlobalStrings load.

Not applicable to C-01…C-05, none of which change allocation.

---

## Sign-off

| ID | Tested? | Pass/Fail | Notes |
|---|---|---|---|
| T-01 | | | |
| T-02 | | | |
| T-03 | | | |
| T-04 | | | |
| T-05 | | | |
| T-06 | | | |
| L-01 | | | |
| R-1 … R-11 | | | |
