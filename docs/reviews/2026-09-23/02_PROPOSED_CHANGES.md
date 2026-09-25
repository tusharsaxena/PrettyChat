# 02 — Proposed changes (PrettyChat, 2026-09-23)

The standard version I checked every change against is **Ka0s WoW Addon Standard v2.64.0
(2026-09-23)**. I fetched the index and every section file it links. The finding IDs are the ones in
`01_FINDINGS.md`.

---

## HLD: themes

### T1. Treat the chat text as a contract other addons read (F-001)

PrettyChat's whole mechanism is to rewrite the text of `CHAT_MSG_*` for every listener, not just for
the chat frame. That makes it an input to every parser in the session. The collection has exactly one
such parser, LootHistory's self-loot and self-currency matcher, and that matcher assumes the globals
never change.

- **Chosen:**
  - PrettyChat documents the contract.
  - LootHistory recompiles its patterns whenever a source global's value changes. That is a cheap
    string-identity check per parse, and it is a cross-repo handoff.
  - An in-client check proves the mechanism.
- **Rejected:**
  - (a) A PrettyChat public API or bus message saying "globals changed". `public-api` needs a `_G`
    export. AceEvent is not vendored, and `library-stack-§1` makes it mandatory only when used. It would
    also be a notification that only one consumer needs, which a self-validating cache avoids entirely.
  - (b) Making LootHistory snapshot the Blizzard originals at file scope. While PrettyChat is enabled,
    those originals never match the live text, so this is worse than today.
  - (c) Freezing PrettyChat's globals once LootHistory is detected. That is a coupling one way, and it
    would break PrettyChat's own visibility feature.
- **Trade-off:** the actual fix lands in another repository. This addon's exit criterion is the
  documentation plus a recorded handoff.

### T2. One global, one registration (F-002, F-003)

Collapse the two dead Loot-tab copies into the Tradeskill registration, which is already what the game
shows. Move any stored Loot-copy value across in the addon's first real migration, and harden the
migration runner first so that migration is correct for every profile.

- **Rejected:**
  - Keeping both copies and "syncing" them. That is two records for one state (anti-pattern #81's
    shape).
  - Moving the string to Loot. That changes what every player whose Tradeskill copy is live currently
    sees.
  - Leaving the orphans to `PruneOrphans`. That would silently drop a player's typed value, which is a
    real value even if it was never applied.

### T3. Accuracy of what the addon says about itself (F-004, F-005, F-006)

Three small truth fixes:

- the Original box and the report must never show our own text as Blizzard's;
- a degraded `/pc test` must print where the code says it prints;
- tooltips, help rows and comments must describe current behaviour.

### T4. Hygiene (F-007, F-008, F-009)

- Parenthesize the leaked `gsub` count.
- Drop the dead lint globals.
- Replace four copies of the sorted-names loop with one load-time table.

---

## Upstream change-set

**None.** No finding targets `libs/LibKa0s/` or `tests/_kit/`. **Nothing in this document edits a path
under `libs/` or `tests/_kit/`.**

## Cross-repo handoff (not an upstream library change)

**H-1 (LootHistory, F-001).** In `LootHistory/core/Util.lua`, change `Util.ParseSelfLoot` (:145) and
`Util.ParseSelfCurrency` (:208) so the pattern cache records the source strings it was compiled from,
and rebuilds when any of them differs:

```lua
-- sketch, LootHistory core/Util.lua
local lootSources            -- the global string values the cache was built from
local function lootSourcesChanged()
  if not lootSources then return true end
  for i, g in ipairs(LOOT_GLOBALS) do if _G[g] ~= lootSources[i] then return true end end
  return false
end
-- in ParseSelfLoot:  if lootSourcesChanged() then Util.BuildLootPatterns() end
```

- `LOOT_GLOBALS` is the ordered list of names that `BuildLootPatterns` already reads. Currency gets the
  same treatment.
- Cost: about ten string-identity compares per loot line. There is no allocation on the unchanged path.
- The change is filed as a LootHistory issue, and a LootHistory test pins it: flip a global between two
  parses and assert both are recognized.

---

## LLD: changes by finding

### C-01 (F-001): document the chat-text contract

- `docs/ARCHITECTURE.md` → `## Known Limitations`: add a bullet saying that PrettyChat changes the
  `CHAT_MSG_LOOT` / `CHAT_MSG_CURRENCY` / `CHAT_MSG_MONEY` / `CHAT_MSG_COMBAT_*` text that **every**
  addon receives, not only what the chat frame shows. The bullet should:
  - say that parsers must build their patterns from the live global at parse time, or revalidate them;
  - note that visibility modes `inCombat` and `outOfCombat` change these globals at every combat
    boundary;
  - name LootHistory's handoff (H-1).
- `docs/scope.md`: one sentence under what PrettyChat deliberately affects.
- `docs/smoke-tests.md`: add the SMK-F001 in-client check as a new cross-addon case.
- **Risk:** none. This is documentation only.
- **Standards:** documentation topic docs; no code change.

### C-02 (F-003): harden the migration runner first

- File: `core/Database.lua`, functions `runSteps` and `Database.RunMigrations`.

```lua
-- before: stamp unconditionally after runSteps; profile steps gated on global stamp
-- after:
local profileSteps = {}          -- idempotent, shape-detecting; run on EVERY load-pass entry
local globalSteps  = {}          -- migrations[v] for global-scope shape; gated by the stamp
function Database.RunMigrations(db)
    if not (db and db.global) then return end
    local from = db.global.schemaVersion or 0
    local ok = runSteps(globalSteps, db, from)          -- returns false if any step raised
    for _, step in ipairs(profileSteps) do pcall(step, db) end   -- report failures as today
    if ok then db.global.schemaVersion = Database.SCHEMA_VERSION end
    ...PruneOrphans unchanged...
end
```

- Rewrite the comment at core/PrettyChat.lua:54-56 to describe what now happens.
- **Tests:** new cases in `tests/test_database.lua`:
  - a profile-scoped step runs on `OnProfileChanged` into a second profile after the stamp has moved;
  - a raising global step leaves the stamp unmoved.

  Each carries a `-- red under:` note naming the pre-change behaviour.
- **Risk:** low. `migrations` is empty today, so the observable behaviour is identical until C-03.
- **Standards:** `savedvariables` keeps `schemaVersion` in `global`, as the MUST requires. A per-profile
  stamp was rejected because it would introduce a new deviation from that MUST.

### C-03 (F-002, needs C-02): one registration per global

- `defaults/Defaults.lua`: delete the Loot entries at :39-46 (`LOOT_ITEM_CREATED_SELF`,
  `LOOT_ITEM_CREATED_SELF_MULTIPLE`).
- `core/Database.lua`: bump `SCHEMA_VERSION` to 2, and add a **profile-scoped, idempotent** step (the
  profile-step list from C-02). For each of the two names:
  - if `categories.Loot.strings[G]` exists and `categories.Tradeskill.strings[G]` does not, move it
    across;
  - then drop `categories.Loot.strings[G]` and `categories.Loot.disabledStrings[G]` (the flag never had
    an effect);
  - prune empty tables, and emit one `[Migrate]` line.
- Delete the `settings/Schema.lua:446-468` `crossRegisteredGlobals` block. Replace it with a load-time
  **assertion**: if any global is registered twice, print via the existing `schema:` channel. That keeps
  `events-frames-taint-§5`'s determinism by construction rather than by ordering.
- `settings/Panel.lua:228-247`: drop the "Shared with" tooltip branch. `locales/enUS.lua:58`: drop the
  key.
- **Docs:**
  - ARCHITECTURE Known Limitations (:186): remove the cross-registered bullet.
  - `docs/data-flow.md:145`, `docs/slash-dispatch.md:77`, `docs/module-map.md:153`: update.
  - `docs/smoke-tests.md` T-53 (:416): retire it and replace it with a migration check.
- **Tests (the inventory moves):**
  - Remove or replace the four cases listed in F-002.
  - Add "no GLOBALNAME is registered under two categories".
  - Add "migration v2 moves a Loot-copy override to Tradeskill, keeps an existing Tradeskill override,
    and is idempotent across two runs".
  - `docs/test-cases.md` (regenerated by `--list`) and the README `Tests` badge **must move in the same
    commit** (`testing-§7`).
- **Risk:** medium. This is a SavedVariables migration. It is mitigated by idempotency and the tests.
  There is no visible change for anyone, because the Loot copy was never live.
- **Standards:**
  - `savedvariables`: migration in `core/Database.lua`, stamp in `global`.
  - `events-frames-taint-§5` is satisfied more strongly.
  - The rejected "keep both and document harder" option leaves a UX defect that the register cannot
    ratify.

### C-04 (F-004): Original never falls through to our own override

- File: `modules/Override.lua` `NS.OriginalFormat`.

```lua
function NS.OriginalFormat(addon, globalName)
    if addon and addon.snapshotKeys and addon.snapshotKeys[globalName] then
        return addon.originalStrings[globalName]      -- may be nil: the client has no such string
    end
    return _G[globalName]                             -- registered since the last /reload
end
```

- The panel already shows `L["(original not available)"]` on nil (settings/Panel.lua:268-269).
  `renderOrError(nil)` gives `(error: (empty format))`. That is acceptable, or it could print the same
  "not available" note.
- **Tests:** a case in `tests/test_render.lua` or `test_override.lua`: a snapshot key with a nil original
  answers nil after `ApplyStrings`. **red under:** the current `or _G[...]`.

### C-05 (F-005): make the degraded Test print where the code says

- File: `settings/Panel.lua` `PrettyChat:TestToConsole`. Resolve
  `LibStub("LibKa0s-DebugLog-1.0", true)` once at file load. When it is absent, call
  `PrettyChat:Test(filter)` with **no sink**, so the existing `NS.Print` default serves it. Leave the
  stub's member set unchanged, because `test_surface_parity` pins it.
- Update the claims in `docs/settings-panel.md:231` and `docs/module-map.md:236` so they match (they
  become true).
- **Tests:** a case in `tests/test_libka0s.lua` that loads with the library absent. The case asserts that
  `/pc test category Loot` puts a `Category: Loot` line into the chat mock. It is falsifiable against
  today's code.

### C-06 (F-006): correct stale text

- settings/Schema.lua:162: change the tooltip to "Write a sample of every active format string to the
  debug console, so you can see what real loot/currency/XP messages will look like. `/pc test` does the
  same from chat." Also update the matching key in `locales/enUS.lua`.
- settings/Slash.lua:60: change the text to `L["Reset every setting to defaults"]`, with its enUS key.
- Comment fixes: settings/Panel.lua:86-88 and :551-552, settings/Schema.lua:450-451.
- **Standards:** `localization-§1` (keys routed through `L`); `slash-commands-§4` (help rows come from
  the table). `test_locale` keeps the manifest honest.

### C-07 (F-007): parenthesize

- settings/Panel.lua:281 becomes
  `NS.Schema.Set(formatPath, ((value or ""):gsub("||", "|")))`.
- **Test:** a spy on `Schema.Set` in `tests/test_panel.lua` asserts `select("#", ...) == 2`.

### C-08 (F-008): trim `.luacheckrc`

- Delete the 12 entries at .luacheckrc:55, 64, 65, 67, 70, 71, 78 and 82-86. This was verified with
  lint still at 0/0.
- **Standards:** `lint` (no blanket suppression). `tests/test_lintconfig.lua` continues to pass.

### C-09 (F-009): one sorted-names table

- In `modules/Override.lua`, publish
  `NS.SortedStringNames(category)`. It is memoized on first call per category. `NS.Defaults` is static
  after load, so there is no invalidation. The existing ordering comment (PC-16) moves onto it.
- Replace the loops at modules/Override.lua:283-287 and :566-575 (keep the filter inside
  `collectNames`), settings/Schema.lua:434-438 (Schema loads after Override, so this works) and
  settings/Panel.lua:454-458.
- **Anti-pattern #55 check:** four consumers with identical semantics, no per-consumer flags, and a
  stable shape. The extraction qualifies.
- **Risk:** low. Callers must not mutate the returned array. Document that at the definition.
- **Evidence:** there is no perf runner, so the cheaper claim is **unmeasured**, and it is labelled as
  such in 05.

---

## Standards conformance summary (per change)

| Change | New deviation? | Rules that shaped it |
|---|---|---|
| C-01 | no | documentation (topic docs); `public-api` and `library-stack-§1` are why no API or bus was proposed |
| C-02 | no | `savedvariables` (stamp stays in `global`) |
| C-03 | no | `savedvariables`, `events-frames-taint-§5`, `testing-§7` (inventory and badge move in the same change) |
| C-04 | no | none |
| C-05 | no | `testing-§8` and `options-ui-§1` (stub member set unchanged, no re-implementation) |
| C-06 | no | `localization-§1`, `slash-commands-§4` |
| C-07 | no | none |
| C-08 | no | `lint` |
| C-09 | no | anti-pattern #55 (the extraction qualifies) |

**Expected movement at the next release regeneration** (a note for release; the tool is not run here):

- `Database.RunMigrations` gains branches. It is currently CCN 12 and should stay under 15; if it does
  not, split the global and profile loops into two helpers.
- The test count moves up by roughly 5–7 net.
