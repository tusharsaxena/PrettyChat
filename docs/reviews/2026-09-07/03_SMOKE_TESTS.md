# 03 — In-client smoke tests

Executed **after** the changes in `02_PROPOSED_CHANGES.md` have landed. Everything here needs a
logged-in game client; every headless suite already ran in Step 0 and is recorded in
`01_FINDINGS.md`'s measurement block — do not repeat it here.

**One pre-flight command, not a suite:** from the repo root, confirm the gate is still green before
you log in.

```sh
luacheck . && lua5.1 tests/run.lua
```

Expected after PC-C-02 and PC-C-04: `0 warnings / 0 errors`, and a pass count **above 300** with
`docs/test-cases.md` and the README badge already moved in the same commit.

---

## Pre-flight (in-client)

1. **Build.** Copy the repo to `World of Warcraft/_retail_/Interface/AddOns/PrettyChat/`, or symlink
   it. Confirm `PrettyChat.toc` reads `## Interface: 120007` and matches the client's build
   (`/run print((select(4, GetBuildInfo())))`).
2. **Errors visible.** `/console scriptErrors 1`, then `/reload`. Every step below assumes a red Lua
   error popup would be seen.
3. **Character.** Any retail character. One step (SMOKE-04) needs combat, so pick one that can reach
   a target dummy — Stormwind (Trade District), Orgrimmar (Valley of Honor).
4. **Fresh saved variables for SMOKE-05 only.** For every other test, start from your existing
   `WTF/Account/<ACCT>/SavedVariables/PrettyChat.lua`.
5. **A second AceGUI consumer installed** for SMOKE-02's pool check — any AceConfig-based addon
   (e.g. BugSack/!BugGrabber's options, or another Ka0s addon).

---

## SMOKE-01 — A wrong format is refused, and says why

**Change covered:** PC-C-02 — the write path validates a format's conversion sequence against
Blizzard's. **Findings:** `PRETTYCHAT-R-01`, `PRETTYCHAT-R-08`.

**Setup.** Logged in, out of combat. `/pc config` → **Categories** → **Loot** tab. Select
`LOOT_ITEM_SELF` in the string list (label *"Item Looted (Self)"*).

**Steps.**

1. Read the **Original** box and note how many `%` conversions it shows (Blizzard's
   `LOOT_ITEM_SELF` takes one `%s`).
2. In the **New** box, type `Loot: %s %s %s` and press **Enter**.
3. Read the chat frame.
4. Re-open the tab (click **Currency**, then **Loot** again) and re-select `LOOT_ITEM_SELF`.
5. Now type `Loot: %s` and press **Enter**.
6. Loot anything — vendor trash from a nearby mob, or open your bags and use a container.
7. Run `/pc set Loot.LOOT_ITEM_SELF.format Loot: %s %s %s` and read the chat frame.

**Expected.**

- Step 3: one `[PC]`-prefixed line refusing the write and naming what Blizzard passes — e.g.
  *"That format cannot be used: it asks for 3 conversions but Blizzard passes 1."* **No Lua error.**
- Step 4: the **New** box shows the previous value, not `Loot: %s %s %s` — nothing was stored.
- Step 5: accepted silently (the normal `[Set]` path).
- Step 6: the loot line renders as `Loot: <item link>` with **no** Lua error and no repeated error
  spam.
- Step 7: the same refusal as step 3, on the CLI surface, through the same `[PC]` printer.

**Pass / Fail.** PASS iff both surfaces refuse, nothing is stored on a refusal, the accepted format
renders live loot cleanly, and **no red Lua error popup appears at any point**. FAIL on any error
popup, on a silent acceptance of `%s %s %s`, or on a refusal message that does not say what the
expected sequence is.

---

## SMOKE-02 — The landing logo does not follow you around

**Change covered:** PC-C-03 — the landing page is `H.BuildLandingPage`, whose logo texture hides on
release. **Findings:** `PRETTYCHAT-R-02`.

**Setup.** Fresh `/reload`. Do **not** open the settings panel before starting.

**Steps.**

1. `/pc config`. The landing page opens: logo at top-left, the TOC tagline under it, then
   **Slash Commands** with the `/prettychat` alias line and ten command rows.
2. Compare the vertical spacing against the screenshot in `media/screenshots/` — logo, one-liner,
   heading, alias, rows. Note any change (a few pixels is expected and acceptable; a missing block is
   not).
3. Click **Categories** in the left rail. Scroll the whole page top to bottom.
4. Click through **all eight** category tabs, and inside **Loot**, click five different strings in
   the list.
5. Click **General**, then back to **Categories**, then back to the PrettyChat landing page. Repeat
   the landing → Categories cycle **five times**.
6. Close the settings window. Open the other AceGUI addon's options window. Scroll it fully.
7. `/reload`, then repeat steps 1–5 once.

**Expected.**

- Step 1: exactly **one** logo, at the top of the landing page.
- Steps 3–5: **no** logo anywhere on the Categories page — not behind a checkbox row, not behind the
  Reset button row, not overlapping the string list or the editor. This is the specific defect.
- Step 5: still exactly one logo on the landing page after five cycles — never two stacked.
- Step 6: **no** PrettyChat logo anywhere in the other addon's window.
- Step 7: identical to the first pass.

**Pass / Fail.** PASS iff exactly one logo is ever on screen and it is only ever on PrettyChat's
landing page. FAIL on any logo appearing on the Categories page, in another addon's window, or twice
on the landing page. Screenshot any failure — this defect is intermittent and depends on AceGUI pool
order, so a single clean pass is weaker evidence than five cycles.

---

## SMOKE-03 — The `/pc test` report and the panel Test button still agree

**Change covered:** PC-C-01, PC-C-03 (both touch code the report reads). **Findings:**
`PRETTYCHAT-R-08` regression guard.

**Setup.** Out of combat. `/pc debug on` (so the console is capturing).

**Steps.**

1. `/pc test formatstring LOOT_ITEM_SELF` — read the three lines in chat.
2. `/pc config` → **General** → **Master controls** → click **Test**.
3. In the debug console that opens, find the `LOOT_ITEM_SELF` block.
4. Compare the **Original** and **Formatted** lines against step 1's, character for character.
5. Scroll the console to the bottom and read the footer.
6. `/pc test category loot` and confirm only Loot strings appear.

**Expected.** Steps 1 and 3 render identically (the sink is a parameter, not a redirection). The
console footer reads `end of test output (N strings shown)`, with `, M errored` only if a stored
format genuinely fails to render. `/pc test` still writes to **chat**; the Test button still writes
to the **console**.

**Pass / Fail.** PASS iff the two surfaces are byte-identical for the same string and no Lua error
appears. FAIL if the Test button now prints to chat, or the two reports differ.

---

## SMOKE-04 — Combat: the watcher, the panel guard, and no taint

**Change covered:** PC-C-06's disposition claim (the `C_Timer.After` cannot fire in combat) plus a
standing regression check. **Findings:** `PRETTYCHAT-R-03`.

**Setup.** Stand at a target dummy. `/console scriptErrors 1`. Close the settings window.

**Steps.**

1. `/pc set General.visibility inCombat`. Confirm the chat ack.
2. Attack the dummy to enter combat. Watch chat.
3. While **still in combat**, press **Esc → Options → AddOns → Ka0s Pretty Chat → Categories**.
4. While still in combat, type `/pc config`.
5. Drop combat. Now open `/pc config` → **Categories** → **Experience** (the twenty-string category).
6. Confirm the string list box is sized to the page — tall, ending short of the bottom edge, not
   collapsed to ~260px and not overflowing.
7. Re-enter combat with the settings window **open** on the Experience tab. Watch for errors.
8. Drop combat. `/pc set General.visibility always`.
9. Click any action bar button. Look for `Interface action failed because of an AddOn`.

**Expected.**

- Step 2: loot/XP lines render with PrettyChat formats while in combat (that is what `inCombat`
  means); no error.
- Step 3: the page **refuses to draw its body** — the Defaults button is present, the content area is
  empty, and a `[PC]` line reads *"cannot open settings during combat"*. This is the second guard,
  and it is the reason `C_Timer.After` cannot be scheduled in combat.
- Step 4: refused with the same gray notice; the panel does not open.
- Step 6: the tree fills the space under the controls — this is `fitTree`'s deferred pass, and it is
  the code PC-C-06 dispositions.
- Step 7: no error, no re-render, no visual collapse.
- Step 9: **no** `Interface action failed because of an AddOn` message.

**Pass / Fail.** PASS iff both combat paths refuse cleanly, the tree sizes correctly out of combat,
and no taint message appears in step 9. FAIL on any Lua error, on a half-drawn page in combat, or on
a taint message.

---

## SMOKE-05 — First run, migration and profile reset

**Change covered:** PC-C-04, PC-C-05, and the standing saved-variable path. **Findings:**
`PRETTYCHAT-R-07`, `PRETTYCHAT-R-12`.

**Setup.** Log out. Delete `WTF/Account/<ACCT>/SavedVariables/PrettyChat.lua` **and** `.lua.bak`.
Log in.

**Steps.**

1. On login, watch for any error. `/pc version` — confirm it reports `1.4.0` (or the current TOC
   version), not `?`.
2. `/pc debug on` and read the `[Init]` summary line in the console: it must carry
   `PrettyChat v<ver>, schema v1, profile '<key>'` — **schema v1**, not v0.
3. Change three settings across two categories: `/pc set Loot.enabled false`,
   `/pc set Currency.CURRENCY_GAINED.enabled false`, and a valid format edit via the panel.
4. `/reload`. Confirm all three survived (`/pc get` each).
5. `/pc resetall` and accept the confirmation popup. Read its wording: it must be the collection's
   verbatim *"Reset this profile to the addon's defaults? Everything you have configured or added in
   it is discarded — your other profiles are not affected."*
6. `/pc get Loot.enabled` → `true`. Open the panel and confirm the Loot tab shows the default format
   in the **New** box.
7. In the console, confirm exactly **one** `[Reset] all → applied N restored M` line — not one line
   per string.
8. Loot something. Confirm live chat now shows PrettyChat's default formats again.

**Expected.** No error at any step; schema stamped at v1 on a brand-new DB; the reset is a **profile**
reset that re-applies in one pass with one summary line; the panel re-reads the reset values without
a `/reload`.

**Pass / Fail.** PASS iff all eight expectations hold. FAIL on a `?` version, a `schema v0`, more than
one `[Reset]` line, or a panel still showing pre-reset values.

---

## SMOKE-06 — Localization spot-check (only if PC-C-08 landed)

**Change covered:** PC-C-08 — slash error and usage lines become routed sentences.
**Findings:** `PRETTYCHAT-R-06`.

**Setup.** Client on enUS first, then repeat on **deDE**
(Battle.net → game settings → language → German; `/reload` after switching).

**Steps.**

1. `/pc list Lot` (a bad prefix) — read the line.
2. `/pc test foo` — read the usage line.
3. `/pc reset Loot` — read the three-line deprecation notice.
4. `/pc debug maybe` — read the usage line.
5. `/pc list category` and `/pc list formatstring` — read the two headers.
6. Repeat 1–5 on deDE.

**Expected.** On enUS every line reads exactly as it did before PC-C-08 — the wording is unchanged,
only its wrapping. On deDE every line still renders in English (the addon ships English only under a
ratified `localization-§1` row) with **no** raw `SCREAMING_SNAKE` key, no `%s` left unsubstituted, and
no truncated or doubled fragment.

**Pass / Fail.** PASS iff the enUS wording is byte-identical to before and deDE shows complete English
sentences. FAIL on any visible format placeholder, raw key, or missing fragment.

---

## Regression suite (run regardless of which changes landed)

| # | Check | Expected |
|---|---|---|
| R1 | `/reload` three times in a row | No error; settings intact each time |
| R2 | Cold login: `ADDON_LOADED` → `PLAYER_LOGIN` → `PLAYER_ENTERING_WORLD` | No error; `/pc version` answers |
| R3 | `/pc help` | Ten verbs, each on its own `[PC]` line, gold verb + white description |
| R4 | Landing page command list vs. `/pc help` | Same ten verbs, same descriptions, differing only in indentation |
| R5 | `/pc list` with no argument | Grouped by category in `CATEGORY_ORDER`, `Master controls` rows first |
| R6 | Toggle **every** control on the General page's Master controls tab, and one on each of the eight Categories tabs | Each writes, each echoes one `[Set]` line, no error |
| R7 | Open the debug console with `/pc debug`, close it with **Esc**, re-open the General page | The **Debug console** checkbox tracks the window's state |
| R8 | `/pc set General.visibility never`, loot something, then `always` | Blizzard originals while `never`; PrettyChat formats while `always` |
| R9 | Set `General.visibility` to `outOfCombat`, enter and leave combat twice | One `[Visibility]` line per boundary, never one per string |
| R10 | Profile switch via the Blizzard Settings **Profiles** page | Chat formats change with the profile; the open panel re-reads; one `[Profile]` line |
| R11 | Disable the addon entirely (`/pc set General.enabled false`), loot something | Blizzard's original chat lines, all 81 restored |
| R12 | Re-enable it, loot again | PrettyChat formats back, no `/reload` needed |
| R13 | Resize the settings window (drag the Blizzard Settings frame edge) on the Experience tab | The string list re-fits; no runaway resize, no freeze |

---

## Performance spot-check

The addon **brackets nothing** under a ratified `performance-§12` exemption, so there is no
`/pc perf` verb and no two-arm capture protocol to run — do not invent one. The offline scenarios do
not exist either. What is worth one measurement, because PC-C-02 adds work to the write path:

1. `/run collectgarbage("collect"); PC_BEFORE = collectgarbage("count")`
2. Change ten settings in a row through the panel.
3. `/run collectgarbage("collect"); print(collectgarbage("count") - PC_BEFORE)`

**Expected:** a small, non-growing delta — the validation parses one format per write and keeps
nothing. A delta that grows with each repetition of steps 1–3 means the parser is retaining
something, which is a finding.

Do **not** read the Blizzard CPU profiler's number as this addon's cost; its shared-frame attribution
makes it unusable here, and there is no `OnUpdate` handler for it to measure anyway.

---

## Sign-off

| Change ID | Headline | Tested? | Pass/Fail | Notes |
|---|---|---|---|---|
| PC-C-01 | One published conversion-sequence parser | | | |
| PC-C-02 | Write path refuses a mismatched format | | | |
| PC-C-03 | Landing page adopts `H.BuildLandingPage` | | | |
| PC-C-04 | Restore on `~= nil` | | | |
| PC-C-05 | Non-mutating defaults merge | | | |
| PC-C-06 | Corrected `performance-§12` sweep | | | (doc only — no in-client step) |
| PC-C-07 | Corrected localization claims | | | (doc only — no in-client step) |
| PC-C-08 | Routed slash sentences | | | |
| PC-C-09 | Complexity note for the next release | | | (no work now) |
| — | Regression suite R1–R13 | | | |
