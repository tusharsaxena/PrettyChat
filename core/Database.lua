local _, NS = ...

-- NS.Database — SavedVariables schema version + migration runner.
--
-- The addon's live settings are keyed by Blizzard GLOBALNAME constants,
-- which are stable; what moves is which CATEGORY owns a global. The runner gives
-- such a storage-shape change (a global moved between categories, a renamed key,
-- a restructured category table) a versioned home instead of ad-hoc
-- `if db.x then` patches. v2 is the first step (see migrations[2] below).
--
-- THE CONTRACT, which a first step can rely on:
--
--   * SCHEMA_VERSION is the runner's TARGET. A step migrations[v] lifts a DB
--     from v-1 to v, and the runner walks from the stamp up to the target.
--   * THE RUNNER OWNS THE STAMP. `global.schemaVersion` advances only past a
--     step that completed: a step that raises is printed, the walk STOPS, and the
--     stamp stays at the last version that succeeded, so the next load retries.
--   * The stamp's declared default is 0 (NS.GlobalDefaults in defaults/Profile.lua,
--     which says why it survives AceDB's removeDefaults).
--   * A PROFILE-scoped step is run on EVERY stored profile (db.sv.profiles), not
--     only the active one, because the stamp is global: an inactive profile the
--     runner skipped would never be lifted, since a later switch sees the stamp
--     already at target. A GLOBAL-scoped step runs once, on db.global.
--   * Every step is idempotent against a fresh default profile and against one
--     it already lifted, because a profile created after the stamp moved is
--     built from the (current) defaults, and a retried walk re-runs a step.
NS.Database = NS.Database or {}
local Database = NS.Database

-- The runner's target. Bump when the stored shape changes AND add a
-- migrations[N] entry that upgrades a DB at version N-1 to version N.
Database.SCHEMA_VERSION = 2

-- The AceDB `global` defaults -- the declared 0 stamp and LibDBIcon's minimap
-- table -- are NS.GlobalDefaults in defaults/Profile.lua, the one declaration site
-- savedvariables-§2 names (PRETTYCHAT-A-19); the reasoning for both lives there.

-- migrations[v] = { scope = "profile" | "global", run = function(target, db, profileName) end }
-- upgrades a DB from version v-1 to v. `target` is one raw stored profile table
-- (scope "profile", run once per stored profile, with its name) or db.global
-- (scope "global", run once). Published so a suite can inject steps on a fresh
-- instance.
local migrations = {}
Database.migrations = migrations

-- v2 (PRETTYCHAT-R-02): LOOT_ITEM_CREATED_SELF and _MULTIPLE were registered under
-- BOTH Loot and Tradeskill, and the Loot copy was a dead setting -- ApplyStrings
-- walks CATEGORY_ORDER, Tradeskill comes after Loot, so Tradeskill always won.
-- The Loot registration is gone; this step carries a Loot-only override across to
-- Tradeskill (unless Tradeskill already has its own, or the value is Tradeskill's
-- default, which the setters store as absence), drops Loot's strings and
-- disabledStrings entries for the two globals, and prunes what that empties.
-- Idempotent: a lifted profile has no Loot entry left to move.
local LIFTED_TO_TRADESKILL = { "LOOT_ITEM_CREATED_SELF", "LOOT_ITEM_CREATED_SELF_MULTIPLE" }

local function pruneEmpty(parent, key)
    if type(parent[key]) == "table" and next(parent[key]) == nil then parent[key] = nil end
end

local function liftOne(cats, loot, globalName)
    local value = type(loot.strings) == "table" and loot.strings[globalName] or nil
    local trade = NS.Defaults.Tradeskill.strings[globalName]
    if value ~= nil and value ~= trade.default then
        if type(cats.Tradeskill) ~= "table" then cats.Tradeskill = {} end
        cats.Tradeskill.strings = cats.Tradeskill.strings or {}
        if cats.Tradeskill.strings[globalName] == nil then
            cats.Tradeskill.strings[globalName] = value
        end
    end
    if type(loot.strings) == "table" then loot.strings[globalName] = nil end
    if type(loot.disabledStrings) == "table" then loot.disabledStrings[globalName] = nil end
end

local function liftLootCreatedSelf(profile)
    local cats = profile.categories
    local loot = type(cats) == "table" and cats.Loot
    if type(loot) ~= "table" then return end
    for _, globalName in ipairs(LIFTED_TO_TRADESKILL) do liftOne(cats, loot, globalName) end
    pruneEmpty(loot, "strings")
    pruneEmpty(loot, "disabledStrings")
    pruneEmpty(cats, "Loot")
end

migrations[2] = { scope = "profile", run = liftLootCreatedSelf }

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

-- Run one profile-scoped step over every stored profile. The RAW SavedVariables
-- profiles (db.sv.profiles, which real AceDB and the kit's fake both expose) are
-- walked, so a profile nobody has activated this session is lifted too; db.profile
-- is the fallback only when there is no db.sv. Names are walked sorted, so a
-- failure is reported against the same profile every time. Returns false, err on
-- the first raise.
local function byName(a, b) return tostring(a) < tostring(b) end

local function runProfileStep(db, step)
    local profiles = db.sv and db.sv.profiles
    if type(profiles) ~= "table" then
        if type(db.profile) ~= "table" then return true end
        return pcall(step.run, db.profile, db, db.GetCurrentProfile and db:GetCurrentProfile())
    end
    local names = {}
    for name, profile in pairs(profiles) do
        if type(profile) == "table" then names[#names + 1] = name end
    end
    table.sort(names, byName)
    for _, name in ipairs(names) do
        local ok, err = pcall(step.run, profiles[name], db, name)
        if not ok then return false, err end
    end
    return true
end

local function runStep(db, step)
    if step.scope == "profile" then return runProfileStep(db, step) end
    return pcall(step.run, db.global, db)
end

-- Walk the steps above `from`, in order. A step that raises is printed and the
-- walk STOPS there, so no later step runs over a shape it was not written for.
-- A version with no step advances `reached` as if it had run. Returns how many
-- steps ran and the last version that completed.
local function runSteps(db, from)
    local ran, reached = 0, from
    for v = from + 1, Database.SCHEMA_VERSION do
        local step = migrations[v]
        if step then
            local ok, err = runStep(db, step)
            if not ok then
                if NS.Print then
                    NS.Print("schema migration " .. v .. " failed: " .. tostring(err))
                end
                return ran, reached
            end
            ran = ran + 1
        end
        reached = v
    end
    return ran, reached
end

-- The load pass's two [Migrate] traces (debug-logging-§8). The walk's line only
-- when a step actually ran; the repair's line only when it dropped something,
-- once for the pass and never once per key.
local function plural(n) return n == 1 and "" or "s" end

local function traceLoadPass(from, reached, ran, dropped)
    if not NS.Debug then return end
    if ran > 0 then
        NS.Debug("Migrate", "v%d→v%d (%d step%s)", from, reached, ran, plural(ran))
    end
    if dropped > 0 then
        NS.Debug("Migrate", "pruned %d stored key%s with no schema row", dropped, plural(dropped))
    end
end

-- Run every pending migration in order, stamp the last version that completed,
-- then run the orphan repair above. A stamp already ahead of SCHEMA_VERSION (a
-- DB written by a newer build) is normalized down to it. Idempotent: a DB
-- already at SCHEMA_VERSION runs no steps, and a clean profile has nothing to
-- prune.
function Database.RunMigrations(db)
    if not (db and db.global) then return end
    local from = db.global.schemaVersion or 0
    local ran, reached = runSteps(db, from)
    if from < Database.SCHEMA_VERSION then
        db.global.schemaVersion = reached
    else
        db.global.schemaVersion = Database.SCHEMA_VERSION
    end
    traceLoadPass(from, reached, ran, Database.PruneOrphans(db))
end
