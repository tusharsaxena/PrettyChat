# Analysis — GlobalStrings re-validation, Retail 12.1.5.70783 (2026-11-15)

Hand-written. The first run of `/dev-copilot:validate-seeds PrettyChat retail`
(Ka0sAddonsCommonTasks#1), against wago.tools product `wow`, build `12.1.5.70783`, the live Retail
build on 2026-11-15.

## What was checked

- **The 79 keys `defaults/Defaults.lua` depends on.** All 79 are on the build as FrameXML strings
  (`Flags` bit `0x1`), and each one's text is identical to the copy's once the escapes are decoded.
  So no key is gone, no conversion sequence moved, and no default stopped being a positional prefix
  of Blizzard's. The four sanctioned truncations in `tests/test_defaults.lua` are still the only
  truncations. **0 flags, so nothing to rule.**
- **The copy, `GlobalStrings/GlobalStrings.lua`.** It was taken by hand from townlong-yak on
  2026-02-15 (commit `014496a`). It last matched a pre-Midnight build. Against 12.1.5.70783:
  - **925 new keys.** Most are new feature areas: `HOUSING_*` (180), `SOCIAL_*` (105), `ITEM_*`
    (77), `NARRATION_*` (65), `ERR_*` (46), `SLASH_*` and `SPELL_*` (38 each).
  - **33 gone.** The `WOWHACK_*` / `QUEUE_STATUS_WOWHACK_*` / `BINDING_NAME_WOWHACKITEM*` event
    strings (21), the old `OUTFITTER_*` frame (8), and four single keys, among them
    `ERR_CHARTER_NEIGHBORHOOD_RENAME_NOTIFICATION_S`, which became `..._SS`.
  - **120 changed.** Mostly wording: *Blizzard Group* became *Battle.net Group* across the
    `ERROR_CLUB_*` and `COMMUNITIES_*` strings, *Real ID and BattleTag* became *Battle.net*, and the
    housing, ping, photo-sharing and Great Vault texts were rewritten. Some conversions changed too
    (`BCSHORTDATENOYEAR`, `HOUSING_CORNERSTONE_*_DIALOG`, `JOURNEYS_LEVEL_LABEL`), but none of
    them is a key the addon depends on.

  None of the new or changed keys shares a prefix with a key the addon restyles (`LOOT_*`,
  `CURRENCY_*`, `FACTION_STANDING_*`, `COMBATLOG_*`, `CREATED_ITEM*`, `TRADESKILL_LOG_*`, `OPEN_LOCK_*`,
  `ERR_QUEST_*`, `ERR_ZONE_*`, `GENERIC_MONEY_*`, `YOU_LOOT_*`). So this build brings no new chat
  format string for any category.

## What was applied

`apply` regenerated the copy from `raw/GlobalStrings.csv.gz`: 24,732 entries, and 24,736 lines with
the banner and the `glyph: data` pair. The splitter then re-cut it into 27 chunks of 880 to 882 lines
(23,771 entries in the bare `KEY = "...";` form the splitter reads; it was 26 chunks and 22,879).
The diff is exactly the delta: 1,045 lines added (925 new and 120 changed) and 153 removed (33 gone
and 120 changed). Every unchanged key kept its line byte for byte, so the DB2 source reproduces the
townlong-yak file's format exactly. A second `apply` changed nothing.

**Why a regeneration and not rulings.** The copy is generated data. Its exemption from the
1500-line cap rests on that, and a copy curated key by key would lose it
(`docs/validate-seeds.md`, Rules). So the 925 new keys are not candidates to accept or reject: the
copy takes the build whole.

Follow-on edits, all mechanical:

- `tests/prose_waivers.lua`: the same four British spellings of Blizzard's (the waiver file names
  them), re-listed against the new chunk boundaries. No new British word arrived with the build.
- The glyph guard found no new character outside the safe set, so `GLYPH_DATA_KEYS` is unchanged
  (the euro string only).
- The line and chunk counts in the docs.

No default changed and the copy is not shipped, so no smoke check is added.

## What a later run should re-check

- **The four sanctioned truncations.** A build that drops the trailing argument of
  `LOOT_DISENCHANT_CREDIT`, `COMBATLOG_DISHONORGAIN`, `OPEN_LOCK_OTHER` or `OPEN_LOCK_SELF` turns the
  truncation into an equality, and `tests/test_defaults.lua` asks for the register entry to go.
- **The `ERR_CHARTER_NEIGHBORHOOD_RENAME_NOTIFICATION_S` → `_SS` pattern.** Blizzard renames a key
  when its conversions change. A dependent key that goes away this way shows up as `gone`, and its
  replacement is in `DIFF.md`'s *New* list: look there before ruling.
- **`Flags` bit `0x1`.** The copy is the FrameXML rows. If a build starts counting rows differently
  (the copy's key count jumping or halving), the coverage gate's 20,000-row floor is the first thing
  to trip. Check the bit's meaning before touching the floor.
