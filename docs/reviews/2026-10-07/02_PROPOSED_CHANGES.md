# PrettyChat review — 2026-10-07 — 02 Proposed changes

These proposals were vetted against the Ka0s WoW Addon Standard **v2.76.1 (2026-10-07)**. No change below edits a path under `libs/` or `tests/_kit/`.

## Disposition: does each finding need fixing?

| Finding | Severity | Needs addressing? | Why |
|---|---|---|---|
| F-001 | High | **Yes, in LootHistory** | It loses real records on ordinary actions. The fix belongs to the reader; PrettyChat changes nothing. |
| F-002 | Medium | **Yes** | One-line gate. The panel and CLI currently disagree, and the failure mode is invisible. |
| F-003 | Medium | **Should** (owner's call) | Not a standards deviation, but the cost of a misclick is high and a confirmation is cheap. |
| F-004 | Medium | **Should** | Narrow reach, but permanent loss. A small guard fixes it. |
| F-005 | Medium | **Yes (doc), plus an in-client check** | The doc states something false. Correcting it is cheap. |
| F-006 | Medium | **Partly** | Fix the wrong figures. A wholesale comment trim is the owner's taste, not a defect, so it is not proposed. |
| F-007 | Medium | **Yes, upstream** | The generated inventory contradicts `testing-§5` in every consumer that has a skip. |
| F-008 | Medium | **No local change** | Removing the stubs would deviate from `library-stack`. Raise it with the standard as a question. |
| F-009 | Low | **No** | It is at the cap, not over it. The next release's run will confirm. |
| F-010 | Low | **Yes** | Trivial doc fix. Do it alongside the LootHistory change. |
| F-011 | Low | **Optional** | Cosmetic. |
| F-012 | Low | **No** | The name is deliberate, documented and useful in `/etrace`. |
| F-013 | Low | **Optional** | A pin test would be cheap, but the fallback is effectively unreachable. |

## HLD (themes)

1. **Write-path gates refuse what the CLI refuses (F-002).** Blank-value refusal moves into the format row's `validate`, so the panel, `/pc set`, `ApplyDefault` and batches all go through one gate (`architecture-§5`). I rejected adding a guard in `Panel.lua`'s `OnEnterPressed`, because a host-side wrapper in front of the seam is exactly what `ApplyDefault` bypasses (see the comment at `settings/Schema.lua:353-360`).
2. **Destructive acts ask first (F-003).** Route the Categories page's Defaults button through a `StaticPopupDialogs` entry, the way General's does. Trade-off: the Settings window's footer **Defaults** forwards to the same `defaultsOnClick` and Blizzard already asks there, so that one path would ask twice. The owner can instead choose to leave the current behavior (README `:63` documents it).
3. **Migrations never run backwards (F-004).** When the stored stamp is ahead of the code, the load pass leaves both the stamp and the stored keys alone. That is a read-only "newer data" state, not a repair.
4. **Documentation says what is true (F-005, F-006, F-010).** Correct the taint sentence, the three report-length figures, the "nine addons" count and the LootHistory line citations. No other comment rewriting.
5. **Cross-repo work goes to the repo that owns it (F-001, F-007, F-008).**

## Upstream and cross-repo change-set (separate)

- **U-1 (F-001): LootHistory, `core/Util.lua`.**
  - `BuildLootPatterns` and `BuildCurrencyPatterns` record the source strings they compiled (`s.g`).
  - `ParseSelfLoot` and `ParseSelfCurrency` compare those against the live globals first and rebuild on any difference: about 10 string compares per parse. Treat `RollWonPattern` the same way.
  - Add a LootHistory test: build, swap `_G.LOOT_ITEM_SELF` to a new format, and assert that a line in the new format parses.
  - Open a LootHistory issue that cites PrettyChat handoff H-1.
  - PrettyChat needs no code change. F-010's doc line moves with it.
- **U-2 (F-007): LibKa0s, `testkit/framework.lua` `renderTotals`.**
  - Count skipped cases separately: `| **Total** | **N** |` covers passes and failures only, plus a `| skipped | K |` row.
  - Reword the header (`:576-577`) to match.
  - Bump `Kit.VERSION`, release, then re-vendor the whole `tests/_kit/` into every consumer as its own commit (`/dev-copilot:wow-revendor-libka0s`).
  - In PrettyChat the re-vendor regenerates `docs/test-cases.md` (Total 572 plus 1 skipped) in the same commit.
- **U-3 (F-008): WowAddonStandards, `standards/standards/library-stack.md`.**
  - Proposal (an open-evolutions entry): should a host whose packaging can never strip a library (`enable-nolib-creation: no`, vendored whole) still owe a full degradation stub per major, or only a one-line "library missing" refusal at the entry points?
  - No PrettyChat change until the standard decides.

## LLD (local changes)

### C-02 (F-002): refuse a blank format at the gate. File: `settings/Schema.lua`, `refusedBySignature` / `formatAccepted`

Before (`:342-346`):

```lua
local function refusedBySignature(row, value)
    if row.kind ~= "string_format" or type(value) ~= "string" then return false end
    local asked    = NS.ConversionSequence(value)
```

After:

```lua
local function refusedBySignature(row, value)
    if row.kind ~= "string_format" or type(value) ~= "string" then return false end
    if not value:find("%S") then
        NS.Print(NS.L["Not saved — a format cannot be blank. Untick Enable to show Blizzard's original, or press Reset."])
        return true
    end
    local asked    = NS.ConversionSequence(value)
```

- Add the key to `locales/enUS.lua`, which keeps `tests/test_locale.lua`'s manifest honest.
- Add one case to `tests/test_schema.lua`: `Set(<fmt path>, "")` and `Set(<fmt path>, "   ")` return false and leave the store empty.
- **That moves the pass count** (+1 or +2). Regenerate `docs/test-cases.md` with `--list` and update the README badge **in the same commit** (`testing-§5`).
- Risk: a player who had saved `""` keeps it until they reset. The load pass does not migrate it, by design, because pruning a valid-but-odd value is not a repair.

### C-03 (F-003): confirm the Categories page reset. File: `settings/Panel.lua`

- Add `StaticPopupDialogs["PRETTYCHAT_RESET_CATEGORIES"]` beside the existing reset popup. Its text is `L["Reset the strings on every category tab to their defaults?"]` (new key in `locales/enUS.lua`), and its `OnAccept` calls `PrettyChat:ResetCategoriesPage()`.
- `ctx.panel.defaultsOnClick = function() StaticPopup_Show("PRETTYCHAT_RESET_CATEGORIES") end`.
- Tests: `tests/test_panel.lua:384` (`setLines(fresh, function() panel.defaultsOnClick() end)`) drives the Categories page's button straight into a reset. Change it to assert that a popup is shown, then accept it (the mock records `StaticPopup_Show`). The count may move; badge and inventory move in the same commit.
- Standards: `options-ui-§12`'s verbatim wording binds only the global reset, so this new wording is free. `options-ui-§13` (page-wide blast radius) is unchanged.

### C-04 (F-004): no backward migration. File: `core/Database.lua`, `RunMigrations`

Before (`:194-204`): the stamp is normalized down, and `PruneOrphans` always runs.

After:

```lua
function Database.RunMigrations(db)
    if not (db and db.global) then return end
    local from = db.global.schemaVersion or 0
    if from > Database.SCHEMA_VERSION then
        -- Written by a newer build: leave its stamp and its keys alone (no repair on data we do not understand).
        if NS.Debug then NS.Debug("Migrate", "stamp v%d is newer than code v%d; repair skipped", from, Database.SCHEMA_VERSION) end
        return
    end
    local ran, reached = runSteps(db, from)
    db.global.schemaVersion = reached
    traceLoadPass(from, reached, ran, Database.PruneOrphans(db))
end
```

- `tests/test_database.lua:61-65` pins today's normalize-down (`t.eq(ahead.global.schemaVersion, Database.SCHEMA_VERSION, …)`). Update it **deliberately**, because this is a behavior change rather than a test weakened to go green, and say so in the commit. Add a case: stamp 99, an unknown `strings` key survives, and the stamp stays 99.
- The profile callbacks call `RunMigrations` too, so they get the same guard.

### C-05 (F-005): correct the taint sentence. File: `docs/data-flow.md:141`

Replace "`_G` writes don't taint" with this: the writes **do** taint each overridden global (`issecurevariable` answers `false, "PrettyChat"`). The readers are Blizzard's non-protected chat formatting, so no protected call inherits the taint. That claim is checked in-client by `03` C-05.

### C-06 (F-006): fix the wrong figures

- `settings/Panel.lua:89-90` and `modules/Override.lua:752` → "about 335 lines" (4 × 79 + 2 × 8 + 2).
- `settings/Panel.lua:109` → the same figure.
- `settings/Schema.lua:104-105` → "every addon drawing the same tab from its own hand-written copy". This removes the count rather than restating a roster figure that would drift again.

### C-10 (F-010): fix the LootHistory citations

`docs/ARCHITECTURE.md:202`: change `LootHistory/core/Util.lua:118/147/187/210` → `:124/152/193/215`. Better, cite the function names, which survive edits. Do it in the same change as U-1, because U-1 moves those lines.

### C-11 (F-011): stop offering `General` to `/pc test category`. File: `settings/Slash.lua`, `runTest`

- After `ResolveCategory`, treat `matched == "General"` as unknown.
- Build the "Valid:" list from `CATEGORY_ORDER` without `General`.
- Add one case to `tests/test_slash.lua`. The count moves; badge and inventory move in the same commit.

### C-13 (F-013), optional: pin the version literal

Add a `tests/test_envsetup.lua` case asserting that `core/Namespace.lua`'s literal equals the TOC's `## Version`. The count moves, as above.

Not proposed: F-008 (standards question), F-009 (no action; the next release regeneration should show `listSettings` still at 15 or lower), F-012 (keep the name).

## Standards conformance

Each change was checked against the standard. The relevant rules:

- **C-02** keeps the single write seam (`architecture-§5`). The refusal is localized (`localization-§1`), and the CLI parse path is unchanged (`slash-commands-§6`).
- **C-03** adds a confirmation where `options-ui` does not require one. That introduces no deviation, and the page-wide scope is kept (`options-ui-§13`).
- **C-04** keeps `savedvariables-§1`'s "the load pass may repair": repairing data the code does not understand is skipped, not forbidden.
- **C-05, C-06 and C-10** are doc and comment only.
- **C-11** leaves the reserved verbs untouched (`slash-commands-§2`).
- **U-2** is a re-vendor of the whole folder, never an edit in place (`library-stack-§5`, `testing-§1`).
- **Considered and rejected:**
  - Fixing F-001 in PrettyChat with a bus message or a chat filter. `architecture-§4` puts PrettyChat below the bus threshold, and a chat filter would change the addon's compatibility contract (`ARCHITECTURE.md` `## Event Subscriptions`).
  - Deleting the stubs for F-008. `library-stack.md:110` mandates them.
