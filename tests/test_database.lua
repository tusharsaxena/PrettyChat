-- tests/test_database.lua — schema version + migration runner (PC-07).

local ctx = _G.PC_TEST
local t = ctx.t
local test = ctx.test
local inst = ctx.loadAddon()
local Database = inst.NS.Database
local db = inst.addon.db

test("NS.Database and the db.global namespace exist", function()
    t.truthy(Database, "NS.Database exists")
    t.truthy(db.global, "db.global namespace provisioned")
end)

test("a fresh DB is stamped at the current schema version", function()
    -- OnInitialize ran RunMigrations -> DB stamped at current version.
    t.eq(db.global.schemaVersion, Database.SCHEMA_VERSION,
        "fresh DB stamped at current schema version")
end)

test("re-running migrations is idempotent", function()
    Database.RunMigrations(db)
    t.eq(db.global.schemaVersion, Database.SCHEMA_VERSION,
        "re-running migrations keeps version stable")
end)

test("RunMigrations tolerates a db without a .global namespace", function()
    local ok = pcall(Database.RunMigrations, {})
    t.truthy(ok, "RunMigrations tolerates a db without .global")
end)

test("an older DB is upgraded to the current version", function()
    local old = { global = { schemaVersion = 0 } }
    Database.RunMigrations(old)
    t.eq(old.global.schemaVersion, Database.SCHEMA_VERSION,
        "old DB upgraded to current version")
end)

test("the schema version is a positive integer the defaults start below", function()
    t.eq(type(Database.SCHEMA_VERSION), "number", "SCHEMA_VERSION is a number")
    t.truthy(Database.SCHEMA_VERSION >= 1, "and at least 1")
    -- Declared in defaults/Profile.lua (savedvariables-§2), not in NS.Database.
    t.eq(inst.NS.GlobalDefaults and inst.NS.GlobalDefaults.schemaVersion, 0,
        "a brand-new DB starts at 0 so it runs cleanly up to current")
end)

test("a DB with no recorded version is treated as version 0", function()
    local fresh = { global = {} }
    Database.RunMigrations(fresh)
    t.eq(fresh.global.schemaVersion, Database.SCHEMA_VERSION,
        "an absent version migrates from the beginning")
end)

test("RunMigrations tolerates nil and a db without .global", function()
    t.truthy(pcall(Database.RunMigrations), "nil db is a no-op")
    t.truthy(pcall(Database.RunMigrations, {}), "a db with no namespaces is a no-op")
    t.truthy(pcall(Database.RunMigrations, { global = false }), "a non-table global is a no-op")
end)

test("the runner stamps the current version even with no steps to run", function()
    -- A stamp already ahead of the target has no step to run; the runner still
    -- normalizes it so the next release can rely on it.
    local ahead = { global = { schemaVersion = Database.SCHEMA_VERSION + 5 } }
    Database.RunMigrations(ahead)
    t.eq(ahead.global.schemaVersion, Database.SCHEMA_VERSION,
        "the stamp is written unconditionally")
end)

-- ---- the load-pass repair: stored keys with no schema row -------------
--
-- A reset writes rows, so a stored key no row owns (an override for a global
-- string a later version dropped) would outlive it. The load pass drops those
-- keys and prunes what that empties (savedvariables-§1).

local Schema = inst.NS.Schema
local function firstFormatRow(category)
    for _, row in ipairs(Schema.RowsByCategory(category)) do
        if row.kind == "string_format" then return row end
    end
end
local liveRow = firstFormatRow("Loot")
local liveCat, liveGlobal = liveRow.category, liveRow.globalName

test("the load pass drops strings/disabledStrings keys that have no schema row", function()
    db.profile.categories[liveCat] = {
        strings         = { NOT_A_GLOBAL_ANYMORE = "x", [liveGlobal] = "KEPT %s" },
        disabledStrings = { ALSO_GONE = true, [liveGlobal] = true },
    }
    Database.RunMigrations(db)
    local catDB = db.profile.categories[liveCat]
    t.nilv(catDB.strings.NOT_A_GLOBAL_ANYMORE, "an orphaned override is dropped")
    t.nilv(catDB.disabledStrings.ALSO_GONE, "an orphaned disabled flag is dropped")
    t.eq(catDB.strings[liveGlobal], "KEPT %s", "an override a row owns survives")
    t.eq(catDB.disabledStrings[liveGlobal], true, "a disabled flag a row owns survives")
    db.profile.categories[liveCat] = nil
end)

test("the load pass prunes the tables its repair empties", function()
    db.profile.categories[liveCat] = {
        enabled         = false,
        strings         = { NOT_A_GLOBAL_ANYMORE = "x" },
        disabledStrings = { ALSO_GONE = true },
    }
    Database.RunMigrations(db)
    local catDB = db.profile.categories[liveCat]
    t.nilv(catDB.strings, "an emptied strings table is pruned")
    t.nilv(catDB.disabledStrings, "an emptied disabledStrings table is pruned")
    t.eq(catDB.enabled, false, "a row-owned key in the same category is untouched")

    db.profile.categories[liveCat] = {
        strings         = { NOT_A_GLOBAL_ANYMORE = "x" },
        disabledStrings = { ALSO_GONE = true },
    }
    Database.RunMigrations(db)
    t.nilv(db.profile.categories[liveCat], "a category left with nothing is pruned whole")
end)

test("a category reset after the load pass leaves no category table", function()
    db.profile.categories[liveCat] = {
        strings         = { NOT_A_GLOBAL_ANYMORE = "x", [liveGlobal] = "CUSTOM %s" },
        disabledStrings = { ALSO_GONE = true },
    }
    Database.RunMigrations(db)
    inst.addon:ResetCategory(liveCat)
    t.nilv(db.profile.categories[liveCat], "nothing a row does not own is left for the reset to strand")
end)

test("a profile switch runs the repair on the incoming profile", function()
    db:SetProfile("RepairTarget")
    db.profile.categories = db.profile.categories or {}
    db.profile.categories[liveCat] = { strings = { NOT_A_GLOBAL_ANYMORE = "x" } }
    db:SetProfile("Default")
    db:SetProfile("RepairTarget")
    t.nilv(db.profile.categories[liveCat], "OnProfileChanged ran the load pass")
    db:SetProfile("Default")
end)

test("the repair traces once when it drops keys, and stays silent otherwise", function()
    inst.NS.State.debug = true
    inst.NS.DebugLog:Clear()
    Database.RunMigrations(db)
    t.eq(#inst.NS.DebugLog.buffer, 0, "a clean profile logs nothing")
    db.profile.categories[liveCat] = { strings = { NOT_A_GLOBAL_ANYMORE = "x" } }
    Database.RunMigrations(db)
    t.eq(#inst.NS.DebugLog.buffer, 1, "one [Migrate] line for the repair, never one per key")
    t.truthy((inst.NS.DebugLog.buffer[1] or ""):find("Migrate", 1, true), "tagged Migrate")
    inst.NS.State.debug = false
    inst.NS.DebugLog:Clear()
end)

test("the repair tolerates a db with no profile or no categories", function()
    t.truthy(pcall(Database.RunMigrations, { global = {} }), "no profile namespace")
    t.truthy(pcall(Database.RunMigrations, { global = {}, profile = {} }), "no categories table")
    t.truthy(pcall(Database.RunMigrations, { global = {}, profile = { categories = { Loot = false } } }),
        "a non-table category entry")
end)

test("migrating emits no debug noise when nothing ran", function()
    -- debug-logging-§8: the lifecycle trace fires only when a step actually
    -- executed, so a normal login stays quiet.
    inst.NS.State.debug = true
    inst.NS.DebugLog:Clear()
    Database.RunMigrations(db)
    t.eq(#inst.NS.DebugLog.buffer, 0, "a no-op migration logs nothing")
    inst.NS.State.debug = false
end)

-- ---- the runner's contract: scope, and a stamp that only moves past success ----
--
-- Each case boots its own instance and injects steps into NS.Database.migrations
-- under a test-local SCHEMA_VERSION, restoring both at the end (a shipped step the
-- injection shadowed included), so the shipped runner is what every other case sees.

local function withSteps(target, steps, body)
    local fresh = ctx.loadAddon()
    local D = fresh.NS.Database
    local saved, shadowed = D.SCHEMA_VERSION, {}
    D.SCHEMA_VERSION = target
    for v, step in pairs(steps) do
        shadowed[v] = D.migrations[v]
        D.migrations[v] = step
    end
    local ok, err = pcall(body, fresh, D, fresh.addon.db)
    for v in pairs(steps) do D.migrations[v] = shadowed[v] end
    D.SCHEMA_VERSION = saved
    if not ok then error(err, 0) end
end

-- Seeds two stored profiles carrying the v1 shape (`oldMarker`), stamped at v1.
local function seedTwoProfiles(pdb)
    pdb.sv.profiles.Default.oldMarker = "D"
    pdb.sv.profiles.Alt = { oldMarker = "A" }
    pdb.global.schemaVersion = 1
end

-- The v2 shape: `oldMarker` renamed to `newMarker`. Idempotent -- a profile
-- already carrying `newMarker` is left as it is.
local renameStep = {
    scope = "profile",
    run = function(profile)
        if profile.oldMarker ~= nil then
            profile.newMarker = profile.newMarker or profile.oldMarker
            profile.oldMarker = nil
        end
    end,
}

-- Captures NS.Print for the duration of `body`.
local function capturePrints(NS, body)
    local lines, orig = {}, NS.Print
    NS.Print = function(msg) lines[#lines + 1] = tostring(msg) end
    local ok, err = pcall(body)
    NS.Print = orig
    if not ok then error(err, 0) end
    return lines
end

test("a profile-scoped step lifts every stored profile, not only the active one", function()
    -- red under: runSteps calling step(db) once and RunMigrations stamping unconditionally
    withSteps(2, { [2] = renameStep }, function(_, D, pdb)
        seedTwoProfiles(pdb)
        D.RunMigrations(pdb)
        t.eq(pdb.sv.profiles.Default.newMarker, "D", "the active profile is lifted")
        t.eq(pdb.sv.profiles.Alt.newMarker, "A", "the inactive stored profile is lifted too")
        t.nilv(pdb.sv.profiles.Alt.oldMarker, "the old shape is gone from the inactive profile")
        t.eq(pdb.global.schemaVersion, 2, "the stamp advances past the step that succeeded")
        pdb:SetProfile("Alt")
        t.eq(pdb.profile.newMarker, "A", "switching to Alt reads the lifted shape")
        t.nilv(pdb.profile.oldMarker, "and never the old one")
    end)
end)

test("a raising step leaves the stamp where it was", function()
    -- red under: runSteps calling step(db) once and RunMigrations stamping unconditionally
    local boom = { scope = "global", run = function() error("boom") end }
    withSteps(2, { [2] = boom }, function(fresh, D, pdb)
        pdb.global.schemaVersion = 1
        local lines = capturePrints(fresh.NS, function() D.RunMigrations(pdb) end)
        t.eq(pdb.global.schemaVersion, 1, "the stamp does not move past a step that raised")
        local failed = 0
        for _, line in ipairs(lines) do
            if line:find("schema migration 2 failed", 1, true) then failed = failed + 1 end
        end
        t.eq(failed, 1, "one 'schema migration 2 failed' line is printed")
    end)
end)

test("a step after a failed one does not run", function()
    -- red under: runSteps calling step(db) once and RunMigrations stamping unconditionally
    local ranThree = false
    local steps = {
        [2] = { scope = "global", run = function() error("boom") end },
        [3] = { scope = "global", run = function() ranThree = true end },
    }
    withSteps(3, steps, function(fresh, D, pdb)
        pdb.global.schemaVersion = 1
        capturePrints(fresh.NS, function() D.RunMigrations(pdb) end)
        t.falsy(ranThree, "the v3 step never ran after v2 raised")
        t.eq(pdb.global.schemaVersion, 1, "the stamp stays at the last version that completed")
    end)
end)

test("a profile step runs again safely on an already-lifted profile", function()
    -- red under: runSteps calling step(db) once and RunMigrations stamping unconditionally
    withSteps(2, { [2] = renameStep }, function(_, D, pdb)
        seedTwoProfiles(pdb)
        D.RunMigrations(pdb)
        pdb.global.schemaVersion = 1   -- force the same step over the lifted profiles again
        D.RunMigrations(pdb)
        t.eq(pdb.sv.profiles.Default.newMarker, "D", "the active profile is unchanged by the re-run")
        t.eq(pdb.sv.profiles.Alt.newMarker, "A", "the inactive profile is unchanged by the re-run")
        t.nilv(pdb.sv.profiles.Alt.oldMarker, "no old key reappears")
        t.eq(pdb.global.schemaVersion, 2, "the re-run stamps the target again")
    end)
end)

-- ---- migration v2: the Loot copies of LOOT_ITEM_CREATED_SELF[_MULTIPLE] ----
--
-- Until v2 both globals were registered under Loot AND Tradeskill, and the Loot
-- copy was a dead setting: Tradeskill applies after Loot and always won. v2 drops
-- the Loot registration and lifts a Loot-only override onto Tradeskill, so a
-- player who customized the dead copy keeps what they typed.

local CREATED   = "LOOT_ITEM_CREATED_SELF"
local CREATED_M = "LOOT_ITEM_CREATED_SELF_MULTIPLE"

-- A fresh instance with its stored profiles replaced by `profiles` (name -> the
-- `categories` table), stamped at v1, then migrated. Returns the raw profiles.
local function migrateFromV1(profiles)
    local fresh = ctx.loadAddon()
    local pdb = fresh.addon.db
    for name, cats in pairs(profiles) do
        pdb.sv.profiles[name] = pdb.sv.profiles[name] or {}
        pdb.sv.profiles[name].categories = cats
    end
    pdb.global.schemaVersion = 1
    fresh.NS.Database.RunMigrations(pdb)
    return pdb.sv.profiles, fresh, pdb
end

test("migration v2 moves a Loot-only override onto Tradeskill", function()
    local profiles, _, pdb = migrateFromV1({
        Default = { Loot = { strings = { [CREATED] = "MINE %s" } } },
    })
    local cats = profiles.Default.categories
    t.eq(cats.Tradeskill and cats.Tradeskill.strings and cats.Tradeskill.strings[CREATED],
        "MINE %s", "the Loot override now lives under Tradeskill")
    t.nilv(cats.Loot, "the Loot table the copy emptied is pruned")
    t.eq(pdb.global.schemaVersion, 2, "the stamp reaches v2")
end)

test("migration v2 keeps an existing Tradeskill override and drops Loot's copy", function()
    local profiles = migrateFromV1({
        Default = {
            Loot       = { enabled = false, strings = { [CREATED] = "LOOT %s", [CREATED_M] = "LOOT %s x%d" } },
            Tradeskill = { strings = { [CREATED] = "TRADE %s" } },
        },
    })
    local cats = profiles.Default.categories
    t.eq(cats.Tradeskill.strings[CREATED], "TRADE %s", "Tradeskill's own override wins")
    t.eq(cats.Tradeskill.strings[CREATED_M], "LOOT %s x%d", "the other global still lifts")
    t.nilv(cats.Loot.strings, "Loot's strings table is gone")
    t.eq(cats.Loot.enabled, false, "a Loot key a row still owns is untouched")
end)

test("migration v2 does not lift a value equal to Tradeskill's default", function()
    local fresh = ctx.loadAddon()
    local tradeDefault = fresh.NS.Defaults.Tradeskill.strings[CREATED].default
    local profiles = migrateFromV1({
        Default = { Loot = { strings = { [CREATED] = tradeDefault } } },
    })
    t.nilv(profiles.Default.categories.Tradeskill,
        "a default value is stored as absence, so nothing is written")
end)

test("migration v2 drops Loot's disabledStrings and prunes what empties", function()
    local profiles = migrateFromV1({
        Default = { Loot = {
            strings         = { [CREATED] = "MINE %s" },
            disabledStrings = { [CREATED] = true, [CREATED_M] = true },
        } },
    })
    local cats = profiles.Default.categories
    t.nilv(cats.Loot, "Loot's strings and disabledStrings emptied, and so did Loot")
    t.nilv(cats.Tradeskill.disabledStrings, "the disabled flag is not carried across")
end)

test("migration v2 run a second time changes nothing", function()
    local profiles, fresh, pdb = migrateFromV1({
        Default = {
            Loot       = { enabled = false, strings = { [CREATED] = "LOOT %s" } },
            Tradeskill = { strings = { [CREATED_M] = "TRADE %s x%d" } },
        },
    })
    local snapshot = {
        lootEnabled = profiles.Default.categories.Loot.enabled,
        a = profiles.Default.categories.Tradeskill.strings[CREATED],
        b = profiles.Default.categories.Tradeskill.strings[CREATED_M],
    }
    pdb.global.schemaVersion = 1
    fresh.NS.Database.RunMigrations(pdb)
    local cats = profiles.Default.categories
    t.eq(cats.Loot.enabled, snapshot.lootEnabled, "Loot's own key is unchanged")
    t.nilv(cats.Loot.strings, "no Loot strings reappear")
    t.eq(cats.Tradeskill.strings[CREATED], snapshot.a, "the lifted override is unchanged")
    t.eq(cats.Tradeskill.strings[CREATED_M], snapshot.b, "Tradeskill's own override is unchanged")
end)

test("migration v2 lifts an inactive stored profile too", function()
    local profiles = migrateFromV1({
        Alt = { Loot = { strings = { [CREATED_M] = "ALT %s x%d" } } },
    })
    local cats = profiles.Alt.categories
    t.eq(cats.Tradeskill and cats.Tradeskill.strings and cats.Tradeskill.strings[CREATED_M],
        "ALT %s x%d", "the profile nobody activated is lifted")
    t.nilv(cats.Loot, "and its Loot copy is gone")
end)
