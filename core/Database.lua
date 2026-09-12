local _, NS = ...

-- NS.Database — SavedVariables schema version + migration runner.
--
-- The addon's live settings are keyed by Blizzard GLOBALNAME constants,
-- which are stable, so no migration is needed yet — the runner exists so
-- a future storage-shape change (renamed key, restructured category
-- table) has a versioned home instead of ad-hoc `if db.x then` patches.
NS.Database = NS.Database or {}
local Database = NS.Database

-- Bump when the stored shape changes AND add a migrations[N] entry that
-- upgrades a DB at version N-1 to version N.
Database.SCHEMA_VERSION = 1

-- Defaults merged into AceDB (PrettyChat.lua adds `profile`). `global`
-- carries the persisted schema version. Starts at 0 so a brand-new DB
-- runs cleanly up to SCHEMA_VERSION (a no-op while migrations is empty).
Database.defaults = {
    global = {
        schemaVersion = 0,
    },
}

-- migrations[v](db) upgrades a DB from version v-1 to v. Empty today.
local migrations = {}

-- Drop every stored key no schema row owns, then prune what that empties
-- (savedvariables-§1: the load pass may repair). Resets write ROWS, so a key
-- with no row -- an override for a global string a later version removed --
-- would otherwise outlive every reset and keep its category table alive.
-- `strings[G]` is owned by the `<Cat>.<G>.format` row and `disabledStrings[G]`
-- by `<Cat>.<G>.enabled`. Returns the number of keys dropped.
local SUBTABLES = { strings = "format", disabledStrings = "enabled" }

function Database.PruneOrphans(db)
    local Schema = NS.Schema
    local cats = db and type(db.profile) == "table" and db.profile.categories
    if type(cats) ~= "table" or not (Schema and Schema.FindByPath) then return 0 end
    local dropped = 0
    for category, catDB in pairs(cats) do
        if type(catDB) == "table" then
            for field, leaf in pairs(SUBTABLES) do
                local sub = catDB[field]
                if type(sub) == "table" then
                    for globalName in pairs(sub) do
                        local path = tostring(category) .. "." .. tostring(globalName) .. "." .. leaf
                        if not Schema.FindByPath(path) then
                            sub[globalName] = nil   -- clearing a visited key is safe under pairs
                            dropped = dropped + 1
                        end
                    end
                    if next(sub) == nil then catDB[field] = nil end
                end
            end
            if next(catDB) == nil then cats[category] = nil end
        end
    end
    return dropped
end

-- Run every pending migration in order, then stamp the current version, then
-- run the orphan repair above. Idempotent: a DB already at SCHEMA_VERSION runs
-- no steps, and a clean profile has nothing to prune.
function Database.RunMigrations(db)
    if not (db and db.global) then return end
    local from = db.global.schemaVersion or 0
    local ran = 0
    for v = from + 1, Database.SCHEMA_VERSION do
        local step = migrations[v]
        if step then
            local ok, err = pcall(step, db)
            if not ok and NS.Print then
                NS.Print("schema migration " .. v .. " failed: " .. tostring(err))
            end
            ran = ran + 1
        end
    end
    db.global.schemaVersion = Database.SCHEMA_VERSION
    -- Lifecycle trace (debug-logging-§8): only when a migration step actually ran.
    if ran > 0 and NS.Debug then
        NS.Debug("Migrate", "v%d→v%d (%d step%s)",
            from, Database.SCHEMA_VERSION, ran, ran == 1 and "" or "s")
    end
    -- The repair, and its one trace: silent on a clean profile, one line (never
    -- one per key) when it dropped something.
    local dropped = Database.PruneOrphans(db)
    if dropped > 0 and NS.Debug then
        NS.Debug("Migrate", "pruned %d stored key%s with no schema row",
            dropped, dropped == 1 and "" or "s")
    end
end
