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
    t.eq(Database.defaults.global.schemaVersion, 0,
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
    -- There are no migrations yet; the runner still normalises the stamp so
    -- the next release can rely on it.
    local ahead = { global = { schemaVersion = Database.SCHEMA_VERSION + 5 } }
    Database.RunMigrations(ahead)
    t.eq(ahead.global.schemaVersion, Database.SCHEMA_VERSION,
        "the stamp is written unconditionally")
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
