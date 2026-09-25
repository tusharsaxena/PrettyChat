# 05 — Final summary (PrettyChat, 2026-09-23 review cycle)

> This file is written on the assumption that every change in `02_PROPOSED_CHANGES.md` has landed and
> every check in `03_SMOKE_TESTS.md` has passed. Before pasting it into a PR, reconcile it against the
> real commit range. Anything not implemented moves to **Known follow-ups**.

## Headline

This cycle made PrettyChat's settings mean what they say, and wrote down a cross-addon contract that
used to be implicit.

- Two Loot-tab entries that looked editable, but could never affect chat, were folded into the single
  Tradeskill registration that actually runs. A migration carries any typed value across, and that
  migration now reaches every profile, not just the active one.
- The Original box, the Test tooltip, the `resetall` help row and the degraded `/pc test` all now
  report the truth.
- PrettyChat now states that it changes the chat-event text every addon receives. The one sibling that
  parses that text, LootHistory, has an issue filed to revalidate its cached patterns.

## Counts

Critical fixed: 0 · High fixed: 1 (F-001, by documentation plus handoff; the code fix is H-1 in LootHistory) ·
Medium fixed: 2 (F-002, F-003) · Low fixed: 6 (F-004 to F-009).

Deferred: nothing in this repo. H-1 is tracked in LootHistory.

## Changes by theme

### T1: The chat text is a contract

- **What changed:** ARCHITECTURE's Known Limitations, `scope.md` and `smoke-tests.md` now say that
  PrettyChat rewrites the `CHAT_MSG_*` payload for every listener. They also say that combat-scoped
  visibility rewrites it at each combat boundary.
- **Why it mattered:** LootHistory compiled its loot patterns once. With PrettyChat's visibility set to
  `inCombat` or `outOfCombat`, or after any mid-session edit, it silently stopped recording loot.
- **Findings:** F-001. **Changes:** C-01 (plus handoff H-1).
- **Files:** `docs/ARCHITECTURE.md`, `docs/scope.md`, `docs/smoke-tests.md`.

### T2: One global, one registration

- **What changed:**
  - `LOOT_ITEM_CREATED_SELF` and `_MULTIPLE` now live only under Tradeskill.
  - Schema v2 moves any stored Loot-copy override across.
  - A load-time check reports any global registered twice.
  - The migration runner runs profile-scoped steps on every profile load and stamps the version only
    after every step succeeded.
- **Why it mattered:** Loot-copy edits were saved and never applied. Disabling the Tradeskill copy
  switched the message off entirely. The runner could not have migrated an inactive profile.
- **Findings:** F-002, F-003. **Changes:** C-02, C-03.
- **Files:** `defaults/Defaults.lua`, `core/Database.lua`, `core/PrettyChat.lua`, `settings/Schema.lua`,
  `settings/Panel.lua`, `locales/enUS.lua`, `tests/test_database.lua`, `tests/test_apply.lua`,
  `tests/test_panel.lua`, `tests/test_schema.lua`, `tests/test_defaults.lua`, `docs/*.md`,
  `docs/test-cases.md`, `README.md`.

### T3: Accurate self-report

- **What changed:**
  - The Original readout returns "not available" rather than our own override for a global this client
    lacks.
  - A degraded install prints `/pc test` to chat.
  - The Test tooltip, the `resetall` help row and three comments describe current behaviour.
- **Why it mattered:** players were told to copy the signature from a box that could show PrettyChat's
  own text, and the UI described behaviour the code no longer had.
- **Findings:** F-004, F-005, F-006. **Changes:** C-04, C-05, C-06.
- **Files:** `modules/Override.lua`, `settings/Panel.lua`, `settings/Schema.lua`, `settings/Slash.lua`,
  `locales/enUS.lua`, `tests/test_override.lua`, `tests/test_libka0s.lua`, `docs/settings-panel.md`,
  `docs/module-map.md`.

### T4: Hygiene

- **What changed:** the `gsub` count no longer leaks into `Schema.Set`; twelve dead lint globals are
  gone; one memoized sorted-names table replaces four loops.
- **Findings:** F-007, F-008, F-009. **Changes:** C-07, C-08, C-09.
- **Files:** `settings/Panel.lua`, `.luacheckrc`, `modules/Override.lua`, `settings/Schema.lua`,
  `tests/test_panel.lua`.

## API and behaviour changes

- **Settings paths removed:** `Loot.LOOT_ITEM_CREATED_SELF.{enabled,format}` and
  `Loot.LOOT_ITEM_CREATED_SELF_MULTIPLE.{enabled,format}`. `/pc get` or `/pc set` on them now answers
  "Setting not found". The Tradeskill paths are unchanged.
- **Locale keys:**
  - removed: `"Shared with %s — both registrations write the same Blizzard global; the last category to apply wins on /reload."`
  - changed: the Test button tooltip key and the `resetall` help-row key (C-06).
- **Namespace:** `NS.SortedStringNames(category)` added. `Schema.crossRegisteredGlobals` removed.
- **Degraded install:** `/pc test` prints to chat.
- **No slash verbs added or renamed. No defaults changed.**

## SavedVariables and migration notes

- `SCHEMA_VERSION` goes from 1 to 2. `global.schemaVersion` stays in `global`, as `savedvariables`
  requires.
- The profile step (idempotent, and run on every load-pass entry) does this, per profile:

  ```
  categories.Loot.strings[G]  ─▶ categories.Tradeskill.strings[G]   (only if Tradeskill has none)
  categories.Loot.strings[G], categories.Loot.disabledStrings[G]  ─▶ dropped
  ```

- Existing profiles migrate automatically, inactive ones included, when they are next loaded. No
  `/pc resetall` is needed.

## Deprecated-API migrations

None. No deprecated API was found in loaded source.

## Performance impact

**Not measured.** C-09 removes eight table allocations and sorts per `ApplyStrings` pass. There is no
offline runner (the `performance-§12` exemption) and no capture, so no number is claimed.

## Test and complexity movement

- **Pass count:** 438 before, to be confirmed after (about +5–7 net: four cross-registration cases
  replaced; new cases for migration, OriginalFormat, degraded Test, `Set` arity, and "no double
  registration").
- `docs/test-cases.md` and the README badge moved in the commit that moved the count.
- **Watch list (confirm at the next release regeneration):** `Database.RunMigrations` (CCN 12) gains
  branches and should stay under 15. Max CCN is expected to stay at 14.

## Known follow-ups

- **H-1 (LootHistory):** revalidate the cached loot and currency patterns against the live globals. It
  is tracked in LootHistory, because that is where the defect lives.
- **`RESULTS.md` is stale by date** (newest bundle 2026-09-16, 385 tests). It regenerates at the next
  release, per the automated-tests checkpoint, and is not regenerated here.

## Verification evidence

- `docs/reviews/2026-09-23/03_SMOKE_TESTS.md`, with its sign-off table filled in.
- Commit range: `<fill in>` on `feat/2026-09-23-review-audit-remediation`.

## Suggested commit message / PR description

```
PrettyChat: make settings mean what they say; document the chat-text contract

- One registration per Blizzard global: LOOT_ITEM_CREATED_SELF(_MULTIPLE) live
  under Tradeskill only; schema v2 migrates any stored Loot-copy override (F-002)
- Migration runner: profile steps run on every profile, stamp only on success (F-003)
- Original readout never shows our own override as Blizzard's (F-004)
- Degraded /pc test prints to chat, as documented (F-005)
- Correct Test tooltip, resetall help row, stale comments (F-006)
- Parenthesize gsub into Schema.Set (F-007); drop 12 dead lint globals (F-008)
- One memoized sorted-names table for every category walk (F-009)
- Document that PrettyChat rewrites the CHAT_MSG_* payload every addon reads;
  LootHistory handoff filed (F-001)

Review: docs/reviews/2026-09-23/
```
