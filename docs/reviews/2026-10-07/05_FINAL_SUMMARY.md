# PrettyChat review — 2026-10-07 — 05 Final summary (projected)

This is written on the assumption that everything in `04` has landed and `03` has passed. Until then it is a projection, not a record.

## Headline

The review found PrettyChat in good health: lint, the 572-case suite and the complexity gate are all clean, and the 11-addon cross-addon checks are clean too. The most serious defect is in a sibling addon. LootHistory caches loot and currency patterns built from the chat strings PrettyChat rewrites, so it silently stops recording loot whenever PrettyChat's wording changes mid-session. That is fixed in LootHistory. In PrettyChat, the cycle:

- closes the panel's acceptance of blank format strings
- makes the one-click Categories reset ask first
- stops a downgrade from deleting a newer build's saved formats
- corrects a wrong taint statement and several stale comment figures

The testkit's inventory now counts skips the way `testing-§5` requires.

## Counts

- **Critical fixed:** 0
- **High fixed:** 1 (F-001, in LootHistory)
- **Medium fixed:** 6 (F-002 to F-007)
- **Low fixed:** 2 (F-010, F-011)
- **Deferred:**
  - F-008: a standards question; the stubs stay.
  - F-009: at the cap, not over it.
  - F-012: the name is kept on purpose.
  - F-013: optional.

## Changes by theme

- **Cross-addon parsing (F-001; U-1).** LootHistory rebuilds its patterns whenever a source global changes, so it no longer misses loot after PrettyChat's settings or visibility change. Files: `LootHistory/core/Util.lua` and one LootHistory test.
- **One gate for every write (F-002; C-02).** A blank or whitespace-only format is refused at the row's `validate`, the same on the panel and the CLI. Files: `settings/Schema.lua`, `locales/enUS.lua`, `tests/test_schema.lua`.
- **Destructive acts ask first (F-003; C-03).** The Categories page's Defaults button confirms through a popup. Files: `settings/Panel.lua`, `locales/enUS.lua`, `tests/test_panel.lua`.
- **No backward migration (F-004; C-04).** A schema stamp written by a newer build is left alone, along with its keys. Files: `core/Database.lua`, `tests/test_database.lua`.
- **True documentation (F-005, F-006, F-010; C-05, C-06, C-10).** Files: `docs/data-flow.md`, `docs/ARCHITECTURE.md`, and comments in `settings/Panel.lua`, `modules/Override.lua` and `settings/Schema.lua`.
- **Honest inventory (F-007; U-2).** The LibKa0s testkit excludes skips from Total. PrettyChat re-vendors `tests/_kit/` whole.

## API and behavior changes

- Blank formats are refused, with a new chat line.
- The Categories Defaults button shows a confirmation popup.
- `/pc test category General` is now "unknown category".
- A stamp newer than the code is no longer rewritten downward.
- New locale keys: two.

## SavedVariables

There is no schema bump and no migration. `SCHEMA_VERSION` stays at 2.

## Test and complexity movement

- **Before:** 572 passed, 1 skipped, 573 registered.
- **After:** grows by the cases added in T2.1, T2.2, T2.3 and T2.4. `docs/test-cases.md` and the README badge move in each of those commits. After U-2 the inventory's Total excludes the skip.
- **Complexity watch list:** `listSettings` (CCN 15) is not expected to move. The next release's regeneration should confirm max CCN ≤ 15.

## Known follow-ups

- U-3: the WowAddonStandards degradation-stub question.
- `docs/automated-tests/RESULTS.md` is regenerated at the next release, not here.

## Verification evidence

- `03_SMOKE_TESTS.md`, with the sign-off table filled in.
- The commit ranges on `feat/2026-10-07-review-audit-remediation` in PrettyChat, LootHistory and LibKa0s.

## Suggested PR description

```
PrettyChat review remediation (2026-10-07)

- F-002: refuse blank format strings at the row gate (panel == CLI)
- F-003: confirm the Categories page Defaults reset
- F-004: leave a newer schema stamp and its keys untouched on load
- F-005/F-006/F-010: correct the taint sentence, stale comment figures and LootHistory cites
- F-011: keep General out of /pc test category
- F-007: re-vendor LibKa0s testkit (inventory Total excludes skips)
Cross-repo: F-001 fixed in LootHistory (pattern rebuild on global change).
Tests: inventory and badge regenerated in each counting commit.
```
