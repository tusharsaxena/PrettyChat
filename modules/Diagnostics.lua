local _, NS = ...

-- modules/Diagnostics.lua — the sections of the diagnostics report (debug-logging-§14):
-- `/pc diagnostics` and `/pc debug diagnostics` write one report into the debug console, after
-- whatever trace the player just reproduced, so one Copy carries both.
--
-- WHAT IS OURS AND WHAT IS NOT. The markers, the identity header (the [Init] summary, the client
-- build, the locale, the logging flag, the two combat reads and the running LibKa0s minors), the
-- per-section pcall, the cap, the escape strip and the append are LibKa0s-DebugLog-1.0's
-- (DebugLogDiagnostics.lua); core/DebugLogSetup.lua hands this file's Sections to it through the
-- descriptor's `diagnostics` field. What is here is what only PrettyChat knows: the state of the
-- apply gate, which settings moved, and whether the Blizzard globals this addon rewrites hold what
-- it thinks it wrote.
--
-- THE REPORT IS A READ. Nothing below writes a global, the store, a registration or a hold:
-- no ApplyStrings, no Reapply, no SyncCombatWatch, no Schema.Set. Its whole value is describing
-- the state a player is in, and a report that repaired the state would describe one they are not
-- in. It never clears the console either; the library appends. tests/test_diagnostics.lua pins
-- all of it.
--
-- FORMAT STRINGS KEEP THEIR ESCAPES. Every other value is stripped of color codes by the library,
-- so the Copy text reads cleanly; a format string's `|c...|r` codes are what is being reported, so
-- it goes through out:escape (`|` doubled to `||`) and pastes back into `/pc set` unchanged. A
-- format string is only ever an ARGUMENT, never the `fmt` of out:add, so a `%` in a player's
-- format cannot consume the line's own arguments.
--
-- The report body is English diagnostic text and does not go through NS.L, like every trace line
-- (debug-logging-§14); the one chat line the library prints after it is the localizable one.

local PrettyChat = LibStub("AceAddon-3.0"):GetAddon("PrettyChat")

NS.Diagnostics = NS.Diagnostics or {}
local Diagnostics = NS.Diagnostics

-- The two rows printed whatever their value (DX-PC's always-print rows): the first two things a
-- maintainer asks about a PrettyChat bug report, and both at their default on most installs.
local ALWAYS = { "General.enabled", "General.visibility" }

-- Addons known to rewrite chat lines or to replace the chat frame. Loaded beside PrettyChat, one
-- of them can overwrite a global after ApplyStrings or format the line before it reaches the
-- global at all, which is the first explanation to rule out for "my format does not show".
local CHAT_ADDONS = { "Prat-3.0", "Chatter", "ElvUI", "Chattynator", "BasicChatMods", "Glass" }

-- ── walks ──────────────────────────────────────────────────────────────────

--- `fn(category, globalName)` for every registered string, in the order ApplyStrings walks them.
local function eachString(fn)
    for _, category in ipairs(NS.Schema.CATEGORY_ORDER) do
        local catData = NS.Defaults[category]
        if catData and catData.strings then
            for _, name in ipairs(NS.SortedStringNames(category)) do fn(category, name) end
        end
    end
end

--- The gate ApplyStrings asks first: running, and the visibility mode allows the overrides now.
local function gateOpen()
    return (not PrettyChat:IsStoodDown()) and PrettyChat:IsVisible()
end

--- What ApplyStrings would do with one global, from the same three questions in the same order:
--- `true, value` when it would write the override, `false, original` when it would restore the
--- snapshot, and nil when it would leave the global alone.
local function expectation(open, category, name)
    local addon = PrettyChat
    if open and addon:IsCategoryEnabled(category) and addon:IsStringEnabled(category, name) then
        return true, addon:GetStringValue(category, name)
    end
    if addon.snapshotKeys and addon.snapshotKeys[name] then
        return false, addon.originalStrings[name]
    end
    return nil
end

--- The stored override for one string, read raw: nil when the player has none.
local function storedOverride(category, name)
    local db = PrettyChat.db
    local catDB = db and db.profile and db.profile.categories and db.profile.categories[category]
    return catDB and catDB.strings and catDB.strings[name]
end

-- ── state: the master switch, the latch, the apply gate and the combat watcher ─

local function holdsText()
    local holds = NS.Lifecycle:Holds()
    return #holds > 0 and table.concat(holds, ",") or "-"
end

local function watcherLine(out)
    local frame, events, wanted = PrettyChat.CombatWatchState()
    local parts = {}
    for i, event in ipairs(events) do
        parts[i] = event .. "=" .. tostring(frame ~= nil and frame:IsEventRegistered(event) or false)
    end
    out:add("State", "combat watcher: built=%s wanted=%s %s", frame ~= nil, wanted,
        table.concat(parts, " "))
    if PrettyChat:IsStoodDown() then
        out:add("State", "combat watcher: stood down, so nothing should be registered")
    end
end

local function pendingLine(out)
    local pending = PrettyChat.pendingReset
    if type(pending) ~= "table" then
        out:add("State", "pending reset: none")
        return
    end
    out:add("State", "pending reset: rows=%s logged=%s", pending.rows, pending.logged)
end

local function state(out)
    local addon = PrettyChat
    out:add("State", "state: enabled(stored)=%s stoodDown=%s holds=%s", addon:IsAddonEnabled(),
        addon:IsStoodDown(), holdsText())
    out:add("State", "visibility: mode=%s visible=%s applyGate=%s", addon:GetVisibility(),
        addon:IsVisible(), gateOpen() and "open" or "closed")
    local db = addon.db
    out:add("State", "schema: stored=%s code=%s profile=%s", db.global.schemaVersion,
        NS.Database.SCHEMA_VERSION, db:GetCurrentProfile())
    watcherLine(out)
    out:list("State", "rejected events:", NS.RejectedEvents)
    local v = NS.Schema.validation or {}
    out:add("State", "schema check: checked=%s failed=%s", v.checked, v.failed)
    out:list("State", "unresolved paths:", v.misses)
    pendingLine(out)
end

-- ── settings: what moved from its default ──────────────────────────────────

local function disabledLists()
    local cats, strs = {}, {}
    for _, category in ipairs(NS.Schema.CATEGORY_ORDER) do
        if NS.Defaults[category] then
            if not PrettyChat:IsCategoryEnabled(category) then cats[#cats + 1] = category end
            local n = 0
            for _, name in ipairs(NS.SortedStringNames(category)) do
                if not PrettyChat:IsStringEnabled(category, name) then n = n + 1 end
            end
            if n > 0 then strs[#strs + 1] = category .. "=" .. n end
        end
    end
    return cats, strs
end

local function settings(out)
    out:add("Set", "changed rows: %s", NS.Schema.CountChangedRows())
    local cats, strs = disabledLists()
    out:list("Set", "disabled categories:", cats)
    out:list("Set", "disabled strings:", strs)
    -- A string value is a format string (or a visibility mode, which has no pipe to double):
    -- escaped, never stripped. Anything else prints as plain text.
    local function shown(_, v)
        if type(v) == "string" then return out:escape(v) end
        return out:str(v)
    end
    local function get(row) return NS.Schema.Get(row.path) end
    out:nonDefaults(NS.Schema.AllRows(), get, nil, shown, { always = ALWAYS })
end

-- ── globals: does _G hold what the addon wrote? ────────────────────────────

local function globals(out)
    local open = gateOpen()
    local expected, match, bad = 0, 0, {}
    eachString(function(category, name)
        local kind, want = expectation(open, category, name)
        if kind == nil then return end
        expected = expected + 1
        -- rawequal: a secret or any other table must not reach an __eq it could raise from.
        if rawequal(_G[name], want) then match = match + 1 else bad[#bad + 1] = name end
    end)
    out:add("Globals", "live globals: expected=%s match=%s mismatch=%s", expected, match, #bad)
    out:list("Globals", "mismatching globals:", bad)
end

local function apply(out)
    local open = gateOpen()
    local applied, restored = 0, 0
    eachString(function(category, name)
        local kind = expectation(open, category, name)
        if kind == true then applied = applied + 1 elseif kind == false then restored = restored + 1 end
    end)
    out:add("Apply", "would apply=%s restore=%s", applied, restored)
end

-- ── the snapshot, the client's own strings and the format signatures ───────

local function snapshot(out)
    local keys = PrettyChat.snapshotKeys
    if type(keys) ~= "table" then
        out:add("Snapshot", "snapshot: not taken")
        return
    end
    local n, missing = 0, {}
    eachString(function(_, name)
        if keys[name] then
            n = n + 1
            if PrettyChat.originalStrings[name] == nil then missing[#missing + 1] = name end
        end
    end)
    out:add("Snapshot", "snapshot: taken=yes keys=%s client-missing=%s", n, #missing)
    out:list("Snapshot", "globals this client does not define:", missing)
    local dups = {}
    for name in pairs(NS.Schema.duplicateGlobals or {}) do dups[#dups + 1] = name end
    table.sort(dups)
    out:list("Snapshot", "duplicate globals:", dups)
end

--- One string's two signature checks: the shipped default against the client's pristine original
--- (patch drift: Blizzard changed the string under the default), and the stored override against
--- the default (a value the write gate would refuse today, from an older SavedVariables file).
local function checkSignatures(category, name, drifted, refused)
    local seqDefault = NS.ConversionSequence(NS.Defaults[category].strings[name].default)
    local original = PrettyChat.originalStrings and PrettyChat.originalStrings[name]
    if type(original) == "string" then
        local seqClient = NS.ConversionSequence(original)
        if not NS.SequenceIsPrefix(seqDefault, seqClient) then
            drifted[#drifted + 1] = name .. " default=" .. NS.DescribeSequence(seqDefault)
                .. " client=" .. NS.DescribeSequence(seqClient)
        end
    end
    local stored = storedOverride(category, name)
    if type(stored) == "string"
       and not NS.SequenceIsPrefix(NS.ConversionSequence(stored), seqDefault) then
        refused[#refused + 1] = category .. "." .. name
    end
end

local function drift(out)
    local drifted, refused = {}, {}
    eachString(function(category, name) checkSignatures(category, name, drifted, refused) end)
    out:add("Drift", "patch drift: %s", #drifted)
    out:list("Drift", "drifted:", drifted)
    out:list("Drift", "stored overrides the signature gate would refuse:", refused)
end

local function render(out)
    local ok, bad = 0, {}
    eachString(function(_, name)
        local live = _G[name]
        if type(live) ~= "string" then return end
        local rendered, err = NS.RenderSample(live)
        if rendered then ok = ok + 1 else bad[#bad + 1] = name .. ": " .. out:str(err) end
    end)
    out:add("Render", "render check: ok=%s failed=%s", ok, #bad)
    out:list("Render", "unrenderable:", bad)
end

-- ── the surfaces around the engine ─────────────────────────────────────────

local function ui(out)
    local H = NS.Helpers
    local pages = "unavailable"
    if H and type(H.__pages) == "function" then pages = #H.__pages() end
    out:add("UI", "ui: settings pages built=%s console shown=%s", pages, NS.DebugLog:IsShown())
    local registered = "unavailable"
    if NS.Launcher then registered = NS.Launcher:IsRegistered() end
    local db = PrettyChat.db
    local minimap = db and db.global and db.global.minimap
    out:add("UI", "launcher: registered=%s minimap hidden=%s", registered,
        type(minimap) == "table" and minimap.hide or "?")
end

local function addonLoaded()
    -- C_AddOns alone: this addon's Interface is Retail's, where the bare global is gone.
    local api = C_AddOns and C_AddOns.IsAddOnLoaded
    if type(api) ~= "function" then return nil end
    return function(name)
        local ok, loaded = pcall(api, name)
        return ok and loaded and true or false
    end
end

local function addons(out)
    local loaded = addonLoaded()
    if not loaded then
        out:add("Addons", "chat addons loaded: unavailable")
        return
    end
    local found = {}
    for _, name in ipairs(CHAT_ADDONS) do
        if loaded(name) then found[#found + 1] = name end
    end
    out:list("Addons", "chat addons loaded:", found)
end

--- The host's sections, in report order, for the DebugLog descriptor's `diagnostics` field.
--- Each runs under the library's own pcall, so a raise costs that section one line.
function Diagnostics.Sections()
    return {
        { "state",    state },
        { "settings", settings },
        { "globals",  globals },
        { "apply",    apply },
        { "snapshot", snapshot },
        { "drift",    drift },
        { "render",   render },
        { "ui",       ui },
        { "addons",   addons },
    }
end
