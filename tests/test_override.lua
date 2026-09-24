-- tests/test_override.lua — modules/Override.lua beyond the enable cascade
-- (which test_apply.lua owns): the value-resolution predicates, the reset
-- family's DB effects, the ApplyStrings pass counters, and the `Test` preview
-- engine's report shape (header, per-category blocks, Name/Original/Formatted
-- triplets, footer counts, and the filtered / empty / erroring paths).

local function firstFormatRow(Schema, category)
    for _, row in ipairs(Schema.RowsByCategory(category)) do
        if row.kind == "string_format" then return row end
    end
end

local function lines(env, from)
    local out = {}
    for i = from + 1, #env.DEFAULT_CHAT_FRAME.messages do
        out[#out + 1] = env.DEFAULT_CHAT_FRAME.messages[i]
    end
    return out
end

local function countMatching(list, pattern)
    local n = 0
    for _, line in ipairs(list) do
        if line:find(pattern) then n = n + 1 end
    end
    return n
end

-- Plain (non-pattern) variant, for needles carrying `|c…` color escapes.
local function countPlain(list, needle)
    local n = 0
    for _, line in ipairs(list) do
        if line:find(needle, 1, true) then n = n + 1 end
    end
    return n
end

local ctx = _G.PC_TEST
local t      = ctx.t
local test   = ctx.test
local inst   = ctx.loadAddon()
local NS     = inst.NS
local addon  = inst.addon
local env    = inst.env
local Schema = NS.Schema

local row  = firstFormatRow(Schema, "Loot")
local cat  = row.category
local g    = row.globalName
local def  = row.default

local function mark() return #env.DEFAULT_CHAT_FRAME.messages end

-- ---- value resolution --------------------------------------------

test("GetStringValue falls back to the defaults table until overridden", function()
    addon:ResetAll()
    t.eq(addon:GetStringValue(cat, g), def, "unset string resolves to its default")
    -- No conversion in the sentinel: `g` is whatever sorts first in Loot, and the
    -- write gate refuses a format asking for more than that row's default supplies.
    Schema.Set(cat .. "." .. g .. ".format", "CUSTOM")
    t.eq(addon:GetStringValue(cat, g), "CUSTOM", "stored override wins")
    addon:ResetAll()
end)

test("IsAddonEnabled treats an absent flag as default-true", function()
    addon:ResetAll()
    t.nilv(addon.db.profile.enabled, "resetting leaves the flag absent, not false")
    t.truthy(addon:IsAddonEnabled(), "absent master flag reads as enabled")
    addon.db.profile.enabled = false
    t.falsy(addon:IsAddonEnabled(), "an explicit false disables")
    addon.db.profile.enabled = true
    t.truthy(addon:IsAddonEnabled(), "an explicit true enables")
    addon:ResetAll()
end)

test("IsCategoryEnabled falls back to the category's shipped default", function()
    t.eq(addon:IsCategoryEnabled(cat), NS.Defaults[cat].enabled,
        "unset category follows the defaults table")
    Schema.Set(cat .. ".enabled", false)
    t.falsy(addon:IsCategoryEnabled(cat), "stored category flag wins")
    addon:ResetCategory(cat)
    t.eq(addon:IsCategoryEnabled(cat), NS.Defaults[cat].enabled,
        "reset restores the shipped default")
end)

test("IsStringEnabled is true unless the string is explicitly disabled", function()
    t.truthy(addon:IsStringEnabled(cat, g), "strings start enabled")
    Schema.Set(cat .. "." .. g .. ".enabled", false)
    t.falsy(addon:IsStringEnabled(cat, g), "explicit disable is honored")
    Schema.Set(cat .. "." .. g .. ".enabled", true)
    t.truthy(addon:IsStringEnabled(cat, g), "re-enabling clears the flag")
    local catDB = addon.db.profile.categories[cat]
    t.falsy(catDB and catDB.disabledStrings and catDB.disabledStrings[g],
        "re-enabling stores nil rather than false (SavedVariables stay lean)")
end)

test("EnsureCategoryDB creates the sub-table once and reuses it", function()
    addon:ResetAll()
    t.nilv(addon.db.profile.categories[cat], "no category table before first write")
    local first = addon:EnsureCategoryDB(cat)
    t.truthy(first, "EnsureCategoryDB returns a table")
    first.marker = "kept"
    t.eq(addon:EnsureCategoryDB(cat).marker, "kept", "a second call reuses the same table")
    addon:ResetAll()
end)

-- ---- ApplyStrings counters ---------------------------------------

test("ApplyStrings returns applied/restored counts that sum to the surface", function()
    addon:ResetAll()
    local applied, restored = addon:ApplyStrings()
    t.truthy(applied > 0, "a default pass applies overrides")
    t.eq(restored, 0, "nothing is restored while everything is enabled")

    Schema.Set("General.enabled", false)
    local applied2, restored2 = addon:ApplyStrings()
    t.eq(applied2, 0, "master off applies nothing")
    t.eq(restored2, applied, "master off restores exactly what it had applied")
    addon:ResetAll()
end)

test("a disabled category shifts its own strings from applied to restored", function()
    addon:ResetAll()
    local baseApplied = addon:ApplyStrings()
    local catStrings = 0
    for _ in pairs(NS.Defaults[cat].strings) do catStrings = catStrings + 1 end

    Schema.Set(cat .. ".enabled", false)
    local applied, restored = addon:ApplyStrings()
    t.eq(applied, baseApplied - catStrings, "the category's strings stop applying")
    t.eq(restored, catStrings, "and are restored instead")
    addon:ResetAll()
end)

-- ---- General visibility -------------------------------------------
--
-- The setting is DECLARED by the composed Master controls block and HONORED
-- here, and these are the cases that make the second half true. A declared
-- setting nothing reads is worse than an absent one (options-ui-§15).

local function watcher() return env._frames.byName["PrettyChatCombatWatcher"] end

test("visibility `never` restores every original, exactly as Enable off does", function()
    addon:ResetAll()
    local applied = addon:ApplyStrings()
    t.truthy(applied > 0, "the default pass applies overrides")

    Schema.Set("General.visibility", "never")
    local applied2, restored2 = addon:ApplyStrings()
    t.eq(applied2, 0, "never applies nothing")
    t.eq(restored2, applied, "and restores exactly what it had applied")
    t.eq(env[g], "ORIG:" .. g, "the Blizzard original is back in _G")

    Schema.Set("General.visibility", "always")
    t.eq(env[g], addon:GetStringValue(cat, g), "and `always` puts the override back")
    addon:ResetAll()
end)

test("the two combat modes read the player's combat state, in both directions", function()
    addon:ResetAll()
    env.__inCombat = false

    Schema.Set("General.visibility", "inCombat")
    t.falsy(addon:IsVisible(), "inCombat is invisible out of combat")
    t.eq(env[g], "ORIG:" .. g, "so the originals are the ones in _G")
    env.__inCombat = true
    addon:ApplyStrings()
    t.truthy(addon:IsVisible(), "and visible in it")
    t.eq(env[g], addon:GetStringValue(cat, g), "with the overrides applied")

    Schema.Set("General.visibility", "outOfCombat")
    t.falsy(addon:IsVisible(), "outOfCombat is the mirror image")
    env.__inCombat = false
    addon:ApplyStrings()
    t.truthy(addon:IsVisible(), "visible once combat drops")
    t.eq(env[g], addon:GetStringValue(cat, g), "and the overrides come back")

    Schema.Set("General.visibility", "always")
    addon:ResetAll()
end)

test("the combat watcher is armed only while a combat mode is stored", function()
    -- This addon has no combat path at all by default, which is the ground of the
    -- performance-§12 exemption in docs/ARCHITECTURE.md. Dies if SyncCombatWatch
    -- registers unconditionally.
    local fresh = ctx.loadAddon()
    t.nilv(fresh.env._frames.byName["PrettyChatCombatWatcher"],
        "a default install creates no watcher frame at all")

    fresh.NS.Schema.Set("General.visibility", "inCombat")
    local f = fresh.env._frames.byName["PrettyChatCombatWatcher"]
    t.truthy(f, "a combat mode creates it")
    t.truthy(f._events.PLAYER_REGEN_DISABLED, "and registers the combat-entry event")
    t.truthy(f._events.PLAYER_REGEN_ENABLED,  "and the combat-exit event")

    fresh.NS.Schema.Set("General.visibility", "always")
    t.nilv(f._events.PLAYER_REGEN_DISABLED, "leaving the combat modes drops the first")
    t.nilv(f._events.PLAYER_REGEN_ENABLED,  "and the second")
end)

test("the combat boundary re-applies the strings", function()
    addon:ResetAll()
    Schema.Set("General.visibility", "inCombat")
    env.__inCombat = false
    t.eq(env[g], "ORIG:" .. g, "out of combat, the originals stand")

    env.__inCombat = true
    watcher():FireScript("OnEvent", "PLAYER_REGEN_DISABLED")
    t.eq(env[g], addon:GetStringValue(cat, g), "entering combat applies the overrides")

    env.__inCombat = false
    watcher():FireScript("OnEvent", "PLAYER_REGEN_ENABLED")
    t.eq(env[g], "ORIG:" .. g, "and leaving it restores the originals")

    Schema.Set("General.visibility", "always")
    addon:ResetAll()
end)

test("a stored visibility arms the watcher at login, not only on a write", function()
    Schema.Set("General.visibility", "outOfCombat")
    local saved = addon.db.profile.visibility
    t.eq(saved, "outOfCombat", "the mode is stored")
    -- OnEnable is what a fresh session runs; re-run it and the watcher must come
    -- back armed rather than waiting for the player to touch the dropdown.
    watcher():UnregisterEvent("PLAYER_REGEN_DISABLED")
    addon:SyncCombatWatch()
    t.truthy(watcher()._events.PLAYER_REGEN_DISABLED, "the stored mode arms it")
    Schema.Set("General.visibility", "always")
    addon:ResetAll()
end)

-- ---- the watcher's registration (events-frames-taint-§1) -----------
--
-- Both names go through NS.Util.SafeRegisterEvents (LibKa0s-Core), so a name the
-- client no longer knows costs only itself and is recorded in NS.RejectedEvents
-- rather than raising through SyncCombatWatch or silently deafening the watcher.

-- A fresh instance whose client refuses `name` at the frame's RegisterEvent and,
-- with C_EventUtils absent, has no front gate: the older-client shape.
local function refusingInstance(name)
    return ctx.loadAddon({ mock = function(m)
        m.__badEvents = { [name] = true }
        m.C_EventUtils = nil
    end })
end

local function watcherEvents(instEnv)
    local out = {}
    local f = instEnv._frames.byName["PrettyChatCombatWatcher"]
    for _, reg in ipairs(instEnv.__registrations()) do
        if reg.target == f and reg.kind == "frame" then out[reg.event] = true end
    end
    return out
end

test("a rejected combat event is recorded and the other still registers", function()
    local fresh = refusingInstance("PLAYER_REGEN_DISABLED")
    local ok, err = pcall(fresh.NS.Schema.Set, "General.visibility", "inCombat")
    t.truthy(ok, "an unknown event name must not raise through SyncCombatWatch: " .. tostring(err))
    local live = watcherEvents(fresh.env)
    t.truthy(live.PLAYER_REGEN_ENABLED, "the other event still registers")
    t.nilv(live.PLAYER_REGEN_DISABLED, "the refused one is not registered")
    t.eq(table.concat(fresh.NS.RejectedEvents or {}, ","), "PLAYER_REGEN_DISABLED",
        "and the refused name is recorded, once")
end)

test("IsEventValid rejects a name without calling RegisterEvent", function()
    -- The frame itself would accept the name (no __badEvents), so the only way it
    -- can be missing from the registrations is that the front gate refused it first.
    local fresh = ctx.loadAddon({ mock = function(m)
        m.__badEvents = {}
        m.C_EventUtils = {
            IsEventValid = function(name) return name ~= "PLAYER_REGEN_ENABLED" end,
        }
    end })
    fresh.NS.Schema.Set("General.visibility", "outOfCombat")
    local live = watcherEvents(fresh.env)
    t.truthy(live.PLAYER_REGEN_DISABLED, "the valid name registers")
    t.nilv(live.PLAYER_REGEN_ENABLED, "the gated name never reached RegisterEvent")
    t.eq(table.concat(fresh.NS.RejectedEvents or {}, ","), "PLAYER_REGEN_ENABLED",
        "and it is recorded as rejected")
end)

test("toggling visibility twice does not duplicate a rejected name", function()
    local fresh = refusingInstance("PLAYER_REGEN_DISABLED")
    local S = fresh.NS.Schema
    S.Set("General.visibility", "inCombat")
    S.Set("General.visibility", "always")
    S.Set("General.visibility", "outOfCombat")
    S.Set("General.visibility", "always")
    S.Set("General.visibility", "inCombat")
    t.eq(#(fresh.NS.RejectedEvents or {}), 1, "one refused name, recorded once across re-arms")
    t.truthy(watcherEvents(fresh.env).PLAYER_REGEN_ENABLED, "and the other is live again")
end)

test("the [Init] summary names a rejected event", function()
    local fresh = refusingInstance("PLAYER_REGEN_DISABLED")
    t.falsy(fresh.NS.DebugLog.SessionSummary():find("rejected events", 1, true),
        "no tail while nothing has been refused")
    pcall(fresh.NS.Schema.Set, "General.visibility", "inCombat")
    t.truthy(fresh.NS.DebugLog.SessionSummary():find(
        ", rejected events: PLAYER_REGEN_DISABLED", 1, true),
        "the refused name surfaces in the summary")
end)

-- ---- resets -------------------------------------------------------

test("ResetCategory drops the whole category table", function()
    Schema.Set(cat .. ".enabled", false)
    Schema.Set(cat .. "." .. g .. ".format", "CUSTOM")
    t.truthy(addon.db.profile.categories[cat], "category table exists before reset")
    addon:ResetCategory(cat)
    t.nilv(addon.db.profile.categories[cat], "reset removes the category table")
    t.eq(env[g], def, "and re-applies the default override to live chat")
end)

test("ResetCategory('General') clears only the addon-wide keys", function()
    Schema.Set("General.enabled", false)
    Schema.Set("General.visibility", "never")
    Schema.Set(cat .. "." .. g .. ".format", "CUSTOM")
    addon:ResetCategory("General")
    t.nilv(addon.db.profile.enabled, "the master override is cleared")
    t.nilv(addon.db.profile.visibility, "and so is the visibility override")
    t.eq(Schema.Get(cat .. "." .. g .. ".format"), "CUSTOM",
        "per-category overrides survive a General reset")
    addon:ResetAll()
end)

test("ResetAll clears the master flag and every category at once", function()
    Schema.Set("General.enabled", false)
    Schema.Set(cat .. "." .. g .. ".format", "CUSTOM")
    Schema.Set("Money.enabled", false)
    addon:ResetAll()
    t.nilv(addon.db.profile.enabled, "master flag cleared")
    t.truthy(next(addon.db.profile.categories) == nil, "every category table cleared")
    t.eq(env[g], def, "live chat is back on the shipped defaults")
end)

-- ---- reset characterization (#15) -----------------------------------
--
-- What a per-category and a per-string reset must leave behind, whatever writes it:
-- the stored shape, the live `_G` globals, exactly ONE ApplyStrings pass and exactly
-- ONE [Set] line of the shape `[Set] reset <scope>: N rows`, N the rows the reset
-- actually changed (debug-logging-§10: a bulk reset is one [Set] line, never one
-- per row, and a row already at its default is not counted).

-- A second Loot format row, so a reset of `g` can be shown to leave its neighbor alone.
local row2
for _, r in ipairs(Schema.RowsByCategory(cat)) do
    if r.kind == "string_format" and r.globalName ~= g then row2 = r; break end
end
local g2 = row2.globalName

-- Run fn with ApplyStrings and Schema.NotifyPanelChange counted and the debug
-- console capturing, and hand back the pass count, the [Set] line count, the
-- [Reset] line count, the log and the panel-notify count.
--
-- WARMED FIRST. The first line a fresh instance logs builds the console frame, and
-- the frame's visibility hook notifies "General" -- a notify that belongs to the
-- console, not to the reset. So one line is logged before the counters go in.
local function probeReset(fn)
    local D = NS.DebugLog
    local wasDebug = NS.State.debug
    NS.State.debug = true
    NS.Debug("Test", "warm-up")
    local origApply, origNotify = addon.ApplyStrings, Schema.NotifyPanelChange
    local passes, notifies = 0, 0
    addon.ApplyStrings = function(self, ...)
        passes = passes + 1
        return origApply(self, ...)
    end
    Schema.NotifyPanelChange = function(...)
        notifies = notifies + 1
        return origNotify(...)
    end
    D:Clear()
    local ok, err = pcall(fn)
    addon.ApplyStrings, Schema.NotifyPanelChange = origApply, origNotify
    NS.State.debug = wasDebug
    if not ok then error(err, 0) end
    local sets, resets = 0, 0
    for _, line in ipairs(D.buffer) do
        if line:find("[Set]", 1, true) then sets = sets + 1 end
        if line:find("[Reset]", 1, true) then resets = resets + 1 end
    end
    return passes, sets, resets, table.concat(D.buffer, "\n"), notifies
end

-- Run fn with the console capturing and hand back pcall's (ok, err) and a copy of
-- the buffer, without re-raising, so a test can read the line a raise left.
local function probeRaise(fn)
    local D = NS.DebugLog
    local wasDebug = NS.State.debug
    NS.State.debug = true
    D:Clear()
    local ok, err = pcall(fn)
    NS.State.debug = wasDebug
    local buf = {}
    for i, line in ipairs(D.buffer) do buf[i] = line end
    return ok, err, buf
end

test("ResetCategory: one pass, one [Set] reset line counting the rows written", function()
    addon:ResetAll()
    Schema.Set(cat .. ".enabled", false)
    Schema.Set(cat .. "." .. g .. ".format", "CUSTOM")
    Schema.Set(cat .. "." .. g2 .. ".enabled", false)
    Schema.Set("Money.enabled", false)
    t.eq(env[g], "ORIG:" .. g, "a disabled category shows the original before the reset")

    local passes, sets, resets, log, notifies = probeReset(function() addon:ResetCategory(cat) end)

    t.nilv(addon.db.profile.categories[cat], "the category stores nothing afterwards")
    t.eq(addon.db.profile.categories.Money.enabled, false, "another category is untouched")
    t.eq(env[g], def, "the default override is live in _G again")
    t.eq(env[g2], row2.default, "and so is the re-enabled neighbor")
    t.eq(passes, 1, "exactly one ApplyStrings pass")
    t.eq(notifies, 1, "exactly one NotifyPanelChange")
    t.eq(sets, 1, "exactly one [Set] line for the whole reset")
    t.eq(resets, 0, "and no [Reset] line")
    t.truthy(log:find("[Set] reset " .. cat .. ": 3 rows", 1, true),
        "the line names the category and counts its three changed rows")
    addon:ResetAll()
end)

test("ResetCategory('General'): one pass, one [Set] reset line, the watcher disarmed", function()
    addon:ResetAll()
    Schema.Set(cat .. "." .. g .. ".format", "CUSTOM")
    -- ARMED WHILE THE ADDON IS UP, THEN DISABLED — and the order is the whole
    -- point now. This block used to disable first and still assert the watcher
    -- armed, which is precisely the draw gate slash-commands-§7 ended: a disabled
    -- addon that goes on registering PLAYER_REGEN_DISABLED has not stopped
    -- watching, it has stopped reacting, and the client still pays the dispatch on
    -- every combat boundary.
    Schema.Set("General.visibility", "inCombat")
    t.truthy(watcher()._events.PLAYER_REGEN_DISABLED, "a combat mode armed the watcher")
    Schema.Set("General.enabled", false)
    t.nilv(watcher()._events.PLAYER_REGEN_DISABLED,
        "and disabling the addon UNREGISTERED it, rather than gating its handler")

    local passes, sets, resets, log, notifies = probeReset(function() addon:ResetCategory("General") end)

    t.nilv(addon.db.profile.enabled, "the master flag stores nothing")
    t.nilv(addon.db.profile.visibility, "nor does visibility")
    t.eq(addon.db.profile.categories[cat].strings[g], "CUSTOM",
        "a category override survives a General reset")
    t.eq(env[g], "CUSTOM", "and is live in _G again, with the master back on")
    t.nilv(watcher()._events.PLAYER_REGEN_DISABLED, "the watcher drops combat entry")
    t.nilv(watcher()._events.PLAYER_REGEN_ENABLED, "and combat exit")
    t.eq(passes, 1, "exactly one ApplyStrings pass")
    t.eq(notifies, 1, "exactly one NotifyPanelChange")
    t.eq(sets, 1, "exactly one [Set] line for the whole reset")
    t.eq(resets, 0, "and no [Reset] line")
    t.truthy(log:find("[Set] reset General: 2 rows", 1, true),
        "the line names General and counts its two stored rows")
    addon:ResetAll()
end)

test("ResetString: one pass, one [Set] reset line, both of the string's rows cleared", function()
    addon:ResetAll()
    Schema.Set(cat .. "." .. g .. ".enabled", false)
    Schema.Set(cat .. "." .. g .. ".format", "CUSTOM")
    Schema.Set(cat .. "." .. g2 .. ".format", "CUSTOM2")
    t.eq(env[g], "ORIG:" .. g, "a disabled string shows the original before the reset")

    local passes, sets, resets, log, notifies = probeReset(function() addon:ResetString(cat, g) end)

    local catDB = addon.db.profile.categories[cat]
    t.falsy(catDB.strings[g], "the format override is gone")
    t.falsy(catDB.disabledStrings and catDB.disabledStrings[g], "and so is the disable flag")
    t.eq(catDB.strings[g2], "CUSTOM2", "the neighboring string keeps its override")
    t.eq(env[g], def, "the default override is live in _G again")
    t.eq(env[g2], "CUSTOM2", "and the neighbor's is unchanged")
    t.eq(passes, 1, "exactly one ApplyStrings pass")
    t.eq(notifies, 1, "exactly one NotifyPanelChange")
    t.eq(sets, 1, "exactly one [Set] line for the whole reset")
    t.eq(resets, 0, "and no [Reset] line")
    t.truthy(log:find("[Set] reset " .. cat .. "." .. g .. ": 2 rows", 1, true),
        "the line names the string and counts both of its rows")
    addon:ResetAll()
end)

test("a reset counts only the rows it changed, and still logs once when none", function()
    -- debug-logging-§10: N is the rows actually written, so a row already at its
    -- default is not counted. A reset with nothing to change is still one act.
    addon:ResetAll()
    Schema.Set(cat .. "." .. g .. ".format", "CUSTOM")

    local passes, sets, _, log, notifies = probeReset(function() addon:ResetString(cat, g) end)
    t.eq(passes, 1, "one pass")
    t.eq(notifies, 1, "one NotifyPanelChange")
    t.eq(sets, 1, "one [Set] line")
    t.truthy(log:find("[Set] reset " .. cat .. "." .. g .. ": 1 rows", 1, true),
        "the enable row was already at its default and is not counted")

    passes, sets, _, log, notifies = probeReset(function() addon:ResetCategory(cat) end)
    t.eq(passes, 1, "a reset of a clean category still runs its one pass")
    t.eq(notifies, 1, "and its one NotifyPanelChange")
    t.eq(sets, 1, "and logs its one [Set] line")
    t.truthy(log:find("[Set] reset " .. cat .. ": 0 rows", 1, true),
        "counting nothing, because nothing differed from its default")
end)

-- debug-logging-§10, failure marker: a bulk act that raises partway still writes
-- its one line, counting the rows changed before the raise and ending in
-- ` (stopped by an error)`, and the error still reaches the caller.

test("a reset that raises between its writes logs one marked line, then raises", function()
    addon:ResetAll()
    Schema.Set(cat .. "." .. g .. ".enabled", false)
    Schema.Set(cat .. "." .. g .. ".format", "CUSTOM")
    -- ResetString writes the enable row, then the format row: fail the second.
    local fmtRow = Schema.FindByPath(cat .. "." .. g .. ".format")
    local origSet = fmtRow.set
    fmtRow.set = function() error("boom mid-batch") end
    local ok, err, buf = probeRaise(function() addon:ResetString(cat, g) end)
    fmtRow.set = origSet

    t.falsy(ok, "the error reaches the caller")
    t.truthy(tostring(err):find("boom mid-batch", 1, true), "with its own message")
    t.truthy(tostring(err):find("stack traceback", 1, true),
        "and the stack of the original raise, not the re-raise")
    t.eq(#buf, 1, "exactly one line")
    t.truthy(buf[1]:find("[Set] reset " .. cat .. "." .. g .. ": 1 rows (stopped by an error)", 1, true),
        "counting the one row written before the raise, and saying it stopped")
    addon:ResetAll()
end)

test("a reset whose re-apply raises logs one marked line counting every row written", function()
    addon:ResetAll()
    Schema.Set(cat .. ".enabled", false)
    Schema.Set(cat .. "." .. g .. ".format", "CUSTOM")
    local origApply = addon.ApplyStrings
    addon.ApplyStrings = function() error("boom in the pass") end
    local ok, err, buf = probeRaise(function() addon:ResetCategory(cat) end)
    addon.ApplyStrings = origApply

    t.falsy(ok, "the error reaches the caller")
    t.truthy(tostring(err):find("boom in the pass", 1, true), "with its own message")
    t.eq(#buf, 1, "exactly one line")
    t.truthy(buf[1]:find("[Set] reset " .. cat .. ": 2 rows (stopped by an error)", 1, true),
        "both writes landed before the pass raised")
    t.nilv(addon.db.profile.categories[cat], "and they stay written")
    addon:ResetAll()
end)

test("both resets write through the helper's batched entry, Schema.ResetRows", function()
    -- architecture-§5: a reset that touches schema rows goes through the one write
    -- helper. Dies if a reset clears row-backed storage itself.
    t.eq(type(Schema.ResetRows), "function", "the helper has a batched entry")
    local seen = {}
    local orig = Schema.ResetRows
    Schema.ResetRows = function(list, ...)
        local paths = {}
        for i, r in ipairs(list) do paths[i] = r.path end
        seen[#seen + 1] = table.concat(paths, ",")
        return orig(list, ...)
    end
    local ok, err = pcall(function()
        addon:ResetCategory(cat)
        addon:ResetCategory("General")
        addon:ResetString(cat, g)
    end)
    Schema.ResetRows = orig
    if not ok then error(err, 0) end
    t.eq(#seen, 3, "each reset makes exactly one batched call")
    local catPaths = {}
    for i, r in ipairs(Schema.RowsByCategory(cat)) do catPaths[i] = r.path end
    t.eq(seen[1], table.concat(catPaths, ","), "a category reset covers every row of the category")
    t.eq(seen[2], "General.enabled,General.visibility",
        "General covers its two stored rows, never the session-only console")
    t.eq(seen[3], cat .. "." .. g .. ".enabled," .. cat .. "." .. g .. ".format",
        "a string reset covers exactly that string's two rows")
end)

-- issue #18: Schema.ResetRows is the schema runtime's own bulk act, a BulkRun
-- bracket whose tally is BulkAdd'd per changed row, not a hand-rolled line.

test("ResetRows runs inside the runtime's bracket", function()
    addon:ResetAll()
    local S = NS.SchemaRuntime
    local orig = S.BulkRun
    local calls = {}
    S.BulkRun = function(act, scope, walk)
        calls[#calls + 1] = { act = act, scope = scope }
        return orig(act, scope, walk)
    end
    local ok, err = pcall(function() addon:ResetCategory("Loot") end)
    S.BulkRun = orig
    if not ok then error(err, 0) end
    t.eq(#calls, 1, "one bracket for the whole reset")
    t.eq(calls[1] and calls[1].act, "reset", "the act is 'reset'")
    t.eq(calls[1] and calls[1].scope, "Loot", "and the scope is the reset's label")
end)

test("an all-already-default reset still logs `[Set] reset Loot: 0 rows`", function()
    addon:ResetAll()
    local _, sets, _, log = probeReset(function() addon:ResetCategory("Loot") end)
    t.eq(sets, 1, "one [Set] line")
    t.truthy(log:find("[Set] reset Loot: 0 rows", 1, true), "counting nothing")
end)

test("a reset list with no eligible row logs nothing and returns 0", function()
    addon:ResetAll()
    -- Carries a real path, but is not the row the runtime indexes under it.
    local foreign = { path = cat .. "." .. g .. ".format", default = "X",
                      get = function() return "Y" end, set = function() end }
    local n
    local passes, sets, _, _, notifies = probeReset(function()
        n = Schema.ResetRows({ foreign }, "Nothing")
    end)
    t.eq(n, 0, "returns 0")
    t.eq(sets, 0, "logs no [Set] line")
    t.eq(passes, 0, "runs no pass")
    t.eq(notifies, 0, "and refreshes nothing")
end)

test("a reset counts a row by read-back: General.enabled stored false counts 1", function()
    addon:ResetAll()
    Schema.Set("General.enabled", false)
    local n
    local _, _, _, log = probeReset(function()
        n = Schema.ResetRows({ Schema.FindByPath("General.enabled") }, "General")
    end)
    t.nilv(addon.db.profile.enabled, "its set stores nil")
    t.eq(n, 1, "yet the row reads back changed, so it counts")
    t.truthy(log:find("[Set] reset General: 1 rows", 1, true), "and the line says so")
    addon:ResetAll()
end)

test("a visibility equal to the default stores nothing at all", function()
    addon:ResetAll()
    Schema.Set("General.visibility", "never")
    t.eq(addon.db.profile.visibility, "never", "a real choice is stored")
    Schema.Set("General.visibility", "always")
    t.nilv(addon.db.profile.visibility,
        "and choosing the default clears the key rather than writing it")
    t.eq(addon:GetVisibility(), "always", "which still reads back as the default")
end)

-- ---- the Test preview engine -------------------------------------

test("Test prints a header, a per-category block, and a counted footer", function()
    addon:ResetAll()
    local at = mark()
    addon:Test({ kind = "category", value = cat })
    local out = lines(env, at)

    t.truthy(out[1]:find("sample of every format string", 1, true),
        "the report opens with the preview header")
    t.truthy(countMatching(out, "Category: " .. cat) == 1,
        "exactly one category block for a category filter")

    local strings = 0
    for _ in pairs(NS.Defaults[cat].strings) do strings = strings + 1 end
    t.eq(countMatching(out, "Name: "), strings, "one Name line per string in the category")
    t.eq(countMatching(out, "Original: "), strings, "one Original line per string")
    t.eq(countMatching(out, "Formatted: "), strings, "one Formatted line per string")
    t.truthy(out[#out]:find(("end of test output %%(%d strings shown%%)"):format(strings)),
        "the footer counts the strings shown")
end)

test("Test writes every line to the sink it is given, and nothing to chat", function()
    -- The settings panel's Test button hands in the debug console's writer; the
    -- slash verb hands in nothing and gets NS.Print. Both must produce the SAME
    -- report, which is why the sink is a parameter rather than two report bodies.
    addon:ResetAll()
    local chatAt, sunk = mark(), {}
    addon:Test({ kind = "category", value = cat }, function(line) sunk[#sunk + 1] = line end)

    t.eq(mark(), chatAt, "not one line reached the chat frame")
    t.truthy(sunk[1]:find("sample of every format string", 1, true),
        "the header went to the sink")
    t.truthy(sunk[#sunk]:find("end of test output", 1, true), "and so did the footer")

    -- Byte-for-byte the same report as the default sink's, header to footer.
    local at = mark()
    addon:Test({ kind = "category", value = cat })
    local printed = lines(env, at)
    t.eq(#printed, #sunk, "the two reports are the same length")
    for i, line in ipairs(sunk) do
        t.eq(NS.PREFIX .. line, printed[i], ("line %d is the same text"):format(i))
    end
end)

test("Test previews the Blizzard original from the OnEnable snapshot", function()
    local at = mark()
    addon:Test({ kind = "formatstring", value = g })
    local out = lines(env, at)
    local sawOriginal = false
    for _, line in ipairs(out) do
        if line:find("Original: ", 1, true) and line:find("ORIG:" .. g, 1, true) then
            sawOriginal = true
        end
    end
    t.truthy(sawOriginal, "the Original line renders the snapshotted Blizzard string")
end)

-- A client that never defined LOOT_ITEM_SELF: the snapshot records nil for it,
-- and ApplyStrings then writes PrettyChat's override into the live global. The
-- global is cleared and the addon's own snapshot pass re-run, rather than the
-- loader's `mock` hook, because the loader seeds every registered global with
-- "ORIG:<NAME>" after that hook and before OnEnable.
local function loadWithoutGlobal(globalName)
    local fresh = ctx.loadAddon()
    fresh.env[globalName] = nil
    fresh.addon:SnapshotOriginals()
    fresh.addon:ApplyStrings()
    return fresh
end

test("OriginalFormat answers nil for a global the client never defined, even after ApplyStrings", function()
    -- red under: `originalStrings[g] or _G[g]`
    local fresh = loadWithoutGlobal("LOOT_ITEM_SELF")
    t.truthy(fresh.addon.snapshotKeys.LOOT_ITEM_SELF, "the snapshot pass looked at it")
    t.nilv(fresh.addon.originalStrings.LOOT_ITEM_SELF, "and recorded that it was not there")
    t.eq(fresh.env.LOOT_ITEM_SELF, fresh.addon:GetStringValue("Loot", "LOOT_ITEM_SELF"),
        "the live global now holds PrettyChat's override")
    t.nilv(fresh.NS.OriginalFormat(fresh.addon, "LOOT_ITEM_SELF"),
        "the original is the snapshot's nil, not the override sitting in _G")
end)

test("/pc test's Original line for that global reads (original not available)", function()
    local fresh = loadWithoutGlobal("LOOT_ITEM_SELF")
    local sunk = {}
    fresh.addon:Test({ kind = "formatstring", value = "LOOT_ITEM_SELF" },
        function(line) sunk[#sunk + 1] = line end)
    local original
    for _, line in ipairs(sunk) do
        if line:find("Original: ", 1, true) then original = line end
    end
    t.truthy(original and original:find(fresh.NS.L["(original not available)"], 1, true),
        "the Original line carries the panel's placeholder")
    t.falsy(original and original:find("(error: ", 1, true), "not an error line")
    t.truthy(sunk[#sunk]:find("1 string shown", 1, true),
        "and a missing original is not counted as an errored string")
end)

test("a formatstring filter narrows the report to one string", function()
    local at = mark()
    addon:Test({ kind = "formatstring", value = g })
    local out = lines(env, at)
    t.eq(countPlain(out, "Name: " .. NS.Const.Color.reset .. g), 1,
        "the filtered string is shown")
    t.truthy(out[#out]:find("1 string shown", 1, true),
        "the footer singularizes for a single string")
end)

test("a filter that matches nothing says so instead of printing an empty report", function()
    local at = mark()
    addon:Test({ kind = "category", value = "General" })   -- virtual, no strings
    local out = lines(env, at)
    t.truthy(out[#out]:find("(no matching strings)", 1, true),
        "an empty result is reported explicitly")
    t.eq(countMatching(out, "Category: "), 0, "no category block is emitted")
end)

test("Test warns when the addon is disabled but still previews", function()
    Schema.Set("General.enabled", false)
    local at = mark()
    addon:Test({ kind = "formatstring", value = g })
    local out = lines(env, at)
    t.truthy(out[2]:find("addon is currently disabled", 1, true),
        "the disabled notice follows the header")
    t.eq(countPlain(out, "Name: " .. NS.Const.Color.reset .. g), 1,
        "the preview ignores the enable toggles and still renders")
    addon:ResetAll()
end)

test("an unrenderable override is reported as an error line, not a crash", function()
    -- Written straight into the DB rather than through Schema.Set, because the
    -- write gate (PC-R-01) refuses this format now. The case is about what the
    -- REPORT does with an unrenderable value that is ALREADY STORED, which is
    -- still reachable: a SavedVariables file written before the gate existed, or
    -- hand-edited since. The report must not stop being able to show it.
    local catDB = addon:EnsureCategoryDB(cat)
    catDB.strings = catDB.strings or {}
    catDB.strings[g] = "%y bad conversion"
    local at = mark()
    local ok = pcall(function() addon:Test({ kind = "formatstring", value = g }) end)
    local out = lines(env, at)
    t.truthy(ok, "Test never propagates a string.format failure")
    t.truthy(countMatching(out, "%(error: ") == 1, "the failing string renders an error line")
    t.truthy(out[#out]:find("0 strings shown, 1 errored", 1, true),
        "the footer separates errored strings from shown ones")
    addon:ResetAll()
end)

test("every Test line routes through the [PC] printer", function()
    local at = mark()
    addon:Test()
    for _, line in ipairs(lines(env, at)) do
        t.truthy(line:sub(1, #NS.PREFIX) == NS.PREFIX, "line carries the [PC] prefix")
    end
end)

-- ---- the memoized sorted name list (PRETTYCHAT-R-09) -------------

local function sortedKeys(category)
    local keys = {}
    local catData = NS.Defaults[category]
    for name in pairs((catData and catData.strings) or {}) do keys[#keys + 1] = name end
    table.sort(keys)
    return keys
end

test("the /pc test report lists each category's strings in sorted order", function()
    addon:ResetAll()
    local sunk = {}
    addon:Test(nil, function(line) sunk[#sunk + 1] = line end)
    local seen = {}
    for _, line in ipairs(sunk) do
        if line:find("Name: ", 1, true) then seen[#seen + 1] = line:match("|r([%w_]+)$") end
    end
    local want = {}
    for _, category in ipairs(Schema.CATEGORY_ORDER) do
        for _, name in ipairs(sortedKeys(category)) do want[#want + 1] = name end
    end
    t.eq(#seen, #want, "one Name: line per shipped string")
    for i, name in ipairs(want) do
        t.eq(seen[i], name, ("Name: line %d is the sorted key"):format(i))
    end
end)

test("SortedStringNames answers the same sorted table on every call", function()
    t.eq(type(NS.SortedStringNames), "function", "NS.SortedStringNames is published")
    for _, category in ipairs(Schema.CATEGORY_ORDER) do
        local first = NS.SortedStringNames(category)
        t.truthy(first == NS.SortedStringNames(category),
            category .. ": the second call answers the cached table")
        local want = sortedKeys(category)
        t.eq(#first, #want, category .. ": every shipped name is listed")
        for i, name in ipairs(want) do
            t.eq(first[i], name, ("%s: entry %d is in sorted order"):format(category, i))
        end
    end
end)

test("a formatstring-filtered report does not shrink the cached list", function()
    local full = #NS.SortedStringNames(cat)
    t.truthy(full > 1, "the category has more than the one filtered string")
    addon:Test({ kind = "formatstring", value = g }, function() end)
    t.eq(#NS.SortedStringNames(cat), full, "the filter built a new table, not a shrunk cache")
end)
