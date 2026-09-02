local addonName, NS = ...

-- The override pipeline — PrettyChat's one feature module. Owns the enable-cascade
-- predicates, the ApplyStrings engine that rewrites _G[GLOBALNAME], the reset paths, and
-- the sample-render / Test engine. Methods hang off the shared PrettyChat AceAddon object
-- created in core/PrettyChat.lua; NS.RenderSample is published for the panel's Preview row.

local PrettyChat = LibStub("AceAddon-3.0"):GetAddon("PrettyChat")

local Color  = NS.Const.Color
local note   = NS.Util.note

-- Row labels for the `/pc test` report. Color is a load-time constant, so these
-- are built once here rather than per Test() call.
local LABEL = {
    name      = Color.green .. "Name: "      .. Color.reset,
    original  = Color.green .. "Original: "  .. Color.reset,
    formatted = Color.green .. "Formatted: " .. Color.reset,
}

function PrettyChat:GetStringValue(category, globalName)
    local catDB = self.db.profile.categories[category]
    if catDB and catDB.strings and catDB.strings[globalName] ~= nil then
        return catDB.strings[globalName]
    end
    return NS.Defaults[category].strings[globalName].default
end

function PrettyChat:IsAddonEnabled()
    if not (self.db and self.db.profile) then return true end
    if self.db.profile.enabled == nil then return true end
    return self.db.profile.enabled
end

-- ---------------------------------------------------------------------
-- General visibility (options-ui-§15) — the master switch's second dimension.
--
-- Every other addon in the collection reads this against a frame it draws. This
-- one draws no frame at all: its "display" is the chat text itself, so the four
-- canonical modes are honoured by what ApplyStrings writes to _G[GLOBALNAME].
-- `never` restores every Blizzard original exactly as `Enable` off does, and the
-- two combat modes restore or re-apply them at the combat boundary.
-- ---------------------------------------------------------------------

function PrettyChat:GetVisibility()
    if not (self.db and self.db.profile) then return "always" end
    return self.db.profile.visibility or "always"
end

function PrettyChat:IsVisible()
    local mode = self:GetVisibility()
    if mode == "never"       then return false end
    if mode == "inCombat"    then return UnitAffectingCombat("player") and true or false end
    if mode == "outOfCombat" then return not UnitAffectingCombat("player") end
    return true                            -- "always", and anything unrecognized
end

-- The combat watcher, and it exists ONLY while a combat-scoped mode is stored.
--
-- Two of the four modes need the combat boundary; the other two do not, and this
-- addon has never had a combat path — which is the whole ground of the
-- `performance-§12` exemption in docs/ARCHITECTURE.md. So the frame is created
-- lazily on the first combat-scoped write and its two events are dropped again
-- the moment the mode leaves that set: a default install registers nothing, runs
-- nothing in combat, and the exemption stands unchanged.
--
-- A plain event frame rather than AceEvent-3.0: this addon does not embed it and
-- adding a library for two events would be a dependency the DEPENDENCIES.md
-- ledger has to carry forever. It is not a display frame and never becomes one —
-- no size, no anchor, no SetMovable — so the composed Master controls tab stays
-- correctly `frameless`.
local COMBAT_SCOPED = { inCombat = true, outOfCombat = true }
local combatWatcher

function PrettyChat:SyncCombatWatch()
    local wanted = COMBAT_SCOPED[self:GetVisibility()] and true or false
    if not (wanted or combatWatcher) then return end

    if not combatWatcher then
        combatWatcher = CreateFrame("Frame", "PrettyChatCombatWatcher")
        combatWatcher:SetScript("OnEvent", function()
            local applied, restored = PrettyChat:ApplyStrings()
            -- Bulk mutation (debug-logging-§8): one summary per boundary, never
            -- one line per string.
            NS.Debug("Visibility", "%s → applied %d restored %d",
                PrettyChat:GetVisibility(), applied, restored)
        end)
    end

    for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
        if wanted then
            combatWatcher:RegisterEvent(event)
        else
            combatWatcher:UnregisterEvent(event)
        end
    end
end

function PrettyChat:IsCategoryEnabled(category)
    local catDB = self.db.profile.categories[category]
    if catDB and catDB.enabled ~= nil then
        return catDB.enabled
    end
    return NS.Defaults[category].enabled
end

function PrettyChat:IsStringEnabled(category, globalName)
    local catDB = self.db.profile.categories[category]
    if catDB and catDB.disabledStrings and catDB.disabledStrings[globalName] then
        return false
    end
    return true
end

function PrettyChat:EnsureCategoryDB(category)
    if not self.db.profile.categories[category] then
        self.db.profile.categories[category] = {}
    end
    return self.db.profile.categories[category]
end

function PrettyChat:ApplyStrings()
    -- The addon-wide toggle wins: when off, every Blizzard original is
    -- restored regardless of per-category / per-string state.
    --
    -- Iterate CATEGORY_ORDER (fixed order) and, within each category, a
    -- SORTED name list rather than pairs(NS.Defaults) (PC-16). A handful
    -- of globals are registered under more than one category (e.g.
    -- LOOT_ITEM_CREATED_SELF under Loot + Tradeskill); both write the same
    -- _G key, so the last category to run wins. Deterministic iteration
    -- makes that winner stable across /reload (documented last-writer:
    -- the later entry in CATEGORY_ORDER), instead of depending on
    -- non-deterministic hash order.
    -- The visibility mode rides the same gate as the master toggle: `never`, or a
    -- combat mode whose condition is not met, restores every original exactly as
    -- `Enable` off does. One gate rather than two, so there is one answer to
    -- "why is my chat unchanged".
    local addonEnabled = self:IsAddonEnabled() and self:IsVisible()
    local applied, restored = 0, 0
    for _, category in ipairs(NS.Schema.CATEGORY_ORDER) do
        local catData = NS.Defaults[category]
        if catData and catData.strings then
            local names = {}
            for globalName in pairs(catData.strings) do
                names[#names + 1] = globalName
            end
            table.sort(names)

            local catEnabled = addonEnabled and self:IsCategoryEnabled(category)
            for _, globalName in ipairs(names) do
                if catEnabled and self:IsStringEnabled(category, globalName) then
                    _G[globalName] = self:GetStringValue(category, globalName)
                    applied = applied + 1
                elseif self.originalStrings and self.originalStrings[globalName] then
                    _G[globalName] = self.originalStrings[globalName]
                    restored = restored + 1
                end
            end
        end
    end
    -- Return the pass counts so the caller (Schema.Set / a reset / boot) can fold them into
    -- its own single debug line — one summary per pass, never per string (debug-logging-§9).
    return applied, restored
end

function PrettyChat:ResetCategory(category)
    if category == "General" then
        -- The General virtual category owns the two addon-wide keys and nothing
        -- else (no entry in db.profile.categories). Resetting it clears both back
        -- to their defaults — enabled true, visibility "always".
        self.db.profile.enabled = nil
        self.db.profile.visibility = nil
        self:SyncCombatWatch()
    elseif self.db.profile.categories[category] then
        self.db.profile.categories[category] = nil
    end
    local applied, restored = self:ApplyStrings()
    if NS.Schema and NS.Schema.NotifyPanelChange then
        NS.Schema.NotifyPanelChange(category)
    end
    -- Bulk mutation (debug-logging-§8): a reset bypasses the Schema.Set `[Set]` seam, so it
    -- carries its own summary with the material effect (how many strings reverted).
    NS.Debug("Reset", "%s → applied %d restored %d", category, applied, restored)
end

--- The global reset, and it is a PROFILE reset (options-ui-§12).
---
--- `Reset all to defaults` and AceDBOptions' own `Reset Profile` are the same act
--- across the whole collection: `db:ResetProfile()` on the ACTIVE profile, never a
--- second walk of the schema, and never a touch on another profile.
---
--- It used to clear two keys by hand -- `enabled` and `categories` -- which was the
--- whole profile as this addon knew it in the moment the line was written, and is
--- the shape that quietly stops being true. Anything a later version stores beside
--- them survived a reset that took everything around it. AceDB empties the profile
--- IN PLACE (so anything holding db.profile keeps the live table), merges the
--- defaults back, and fires OnProfileReset -- which core/PrettyChat.lua answers by
--- re-running the migrations, re-applying every string and telling the panel.
---
--- The [Reset] summary therefore moves to that handler's path: ApplyStrings is what
--- knows how many overrides were applied and how many originals were restored, and
--- it is now reached through the callback rather than from here.
function PrettyChat:ResetAll()
    local db = self.db
    if db and db.ResetProfile then db:ResetProfile() end
end

-- Restore ONE string to its untouched default. A per-string reset must
-- clear BOTH per-string dimensions — the custom format AND the disable
-- flag — so it matches the full-reset semantics of ResetCategory /
-- ResetAll (which wipe every dimension at once). Resetting only the
-- format would leave a previously-disabled string half-reset.
function PrettyChat:ResetString(category, globalName)
    local catDB = self.db.profile.categories[category]
    if catDB then
        if catDB.strings then catDB.strings[globalName] = nil end
        if catDB.disabledStrings then catDB.disabledStrings[globalName] = nil end
    end
    local applied, restored = self:ApplyStrings()
    if NS.Schema and NS.Schema.NotifyPanelChange then
        NS.Schema.NotifyPanelChange(category)
    end
    -- Bulk mutation (debug-logging-§8): bypasses the Schema.Set `[Set]` seam,
    -- so it carries its own summary with the material effect.
    NS.Debug("Reset", "%s.%s → applied %d restored %d", category, globalName, applied, restored)
end

-- ---------------------------------------------------------------------
-- Test — synthesize sample chat messages from each active format string
-- ---------------------------------------------------------------------
--
-- Walks the format string for printf-style conversions (%[n$][flags]
-- [width][.precision]type) and returns a list of placeholder values
-- typed to match each conversion. `%%` escapes are stripped first so
-- they don't confuse the gmatch. Positional `%n$type` is honored so
-- non-enUS locales (which use positional rearrangement freely) preview
-- correctly instead of failing string.format.
local function sampleArg(conversion)
    conversion = conversion:lower()
    if conversion == "s" then
        return "Sample"
    elseif conversion == "d" or conversion == "i" or conversion == "u"
        or conversion == "x" or conversion == "o" then
        return 42
    elseif conversion == "f" or conversion == "g" or conversion == "e" then
        return 1.5
    elseif conversion == "c" then
        return 65  -- 'A'
    end
    return "?"
end

local function buildSampleArgs(fmt)
    local clean = fmt:gsub("%%%%", "")
    local args = {}
    local appendIdx = 0
    local maxIdx    = 0
    for posCap, ftype in clean:gmatch("%%(%d*%$?)[%-+ #0]*%d*%.?%d*([%a])") do
        local val = sampleArg(ftype)
        if posCap:sub(-1) == "$" then
            local idx = tonumber(posCap:sub(1, -2))
            if idx and idx > 0 then
                args[idx] = val
                if idx > maxIdx then maxIdx = idx end
            end
        else
            appendIdx = appendIdx + 1
            args[appendIdx] = val
            if appendIdx > maxIdx then maxIdx = appendIdx end
        end
    end
    -- Fill positional gaps so unpack delivers a dense range. Without
    -- this, `%3$s only` would leave args[1] and args[2] nil and
    -- string.format would receive nils for those slots.
    for i = 1, maxIdx do
        if args[i] == nil then args[i] = "?" end
    end
    return args, maxIdx
end

-- Render a single format string with synthesized sample args, returning
-- the rendered line (or nil + error message on string.format failure).
-- Shared by `PrettyChat:Test()` and the per-string sample row in the
-- settings panel — keeps both in lockstep on placeholder choices and
-- positional-arg handling.
function NS.RenderSample(fmt)
    if type(fmt) ~= "string" or fmt == "" then return nil, "(empty format)" end
    local args, n = buildSampleArgs(fmt)
    local ok, result = pcall(string.format, fmt, unpack(args, 1, n))
    if ok then return result end
    return nil, result
end

-- Render one format string for the report, turning a string.format failure into a
-- gray `(error: ...)` line rather than letting it propagate. Second return is the
-- errored flag, which feeds the report's error tally.
local function renderOrError(fmt)
    local rendered, err = NS.RenderSample(fmt)
    if rendered then return rendered, false end
    return Color.gray .. "(error: " .. tostring(err) .. ")" .. Color.reset, true
end

-- A nil filter matches every category; a formatstring filter is category-blind.
local function categoryMatches(filter, category)
    return not filter or filter.kind ~= "category" or filter.value == category
end

-- The sorted, filter-surviving global names of one category. Sorted rather than
-- pairs() order so the report is byte-stable across /reload (PC-16).
local function collectNames(catData, filter)
    local names = {}
    if not (catData and catData.strings) then return names end
    for globalName in pairs(catData.strings) do
        if not filter or filter.kind ~= "formatstring" or filter.value == globalName then
            names[#names + 1] = globalName
        end
    end
    table.sort(names)
    return names
end

-- Blizzard's pristine format for one global: the OnEnable snapshot first,
-- falling back to the live global for a key registered since the last /reload
-- (the snapshot is load-time — see ARCHITECTURE's Known Limitations).
--
-- ONE READER, TWO SURFACES. `/pc test`'s Original line and the settings panel's
-- read-only Original box are answers to the same question and used to consult
-- different sources — this snapshot here, the shipped GlobalStrings/ dump there
-- (PC-R-04) — which is drift by construction: the dump is a build artifact of
-- one client patch and the snapshot is what THIS client actually loaded, so on
-- any patch that reworded a string the panel showed a player something the game
-- no longer says. Both surfaces call this.
function NS.OriginalFormat(addon, globalName)
    return (addon and addon.originalStrings and addon.originalStrings[globalName])
           or _G[globalName]
end

-- One string's three-line block: name, the rendered Blizzard original, the
-- rendered configured value, then a blank separator. Returns true when either
-- render errored.
--
-- `emit` is the report's OUTPUT SINK, threaded from Test rather than read off NS:
-- the settings panel's Test button writes the whole report into the debug console
-- while `/pc test` keeps writing it to chat, and both must be the same report.
local function printStringRow(emit, addon, category, globalName)
    emit(LABEL.name .. globalName)

    local origFmt = NS.OriginalFormat(addon, globalName)
    local origLine, origErr = renderOrError(origFmt)
    emit(LABEL.original .. origLine)

    local newFmt = addon:GetStringValue(category, globalName)
    local newLine, newErr = renderOrError(newFmt)
    emit(LABEL.formatted .. newLine)

    emit("")

    return newErr or origErr
end

-- One category's block: the gold header, then every string row. Returns the
-- printed / errored counts this block contributed.
local function printCategoryBlock(emit, addon, category, names)
    emit(Color.gold .. "Category: " .. category .. Color.reset)
    emit("")

    local printed, errored = 0, 0
    for _, globalName in ipairs(names) do
        if printStringRow(emit, addon, category, globalName) then
            errored = errored + 1
        else
            printed = printed + 1
        end
    end
    return printed, errored
end

local function printFooter(emit, printed, errored)
    local footer = ("end of test output (%d %s shown"):format(
        printed, printed == 1 and "string" or "strings")
    if errored > 0 then
        footer = footer .. (", %d errored"):format(errored)
    end
    emit(note(footer .. ")"))
end

-- Print every format string in a per-category block. For each string
-- show the global name, the rendered Blizzard original (from the
-- snapshot taken in OnEnable), and the rendered PrettyChat-configured
-- value — so the user can diff side by side regardless of the master
-- / per-category / per-string toggles. The toggles ONLY affect what
-- ApplyStrings writes to live chat; this preview is for the user.
--
-- `filter` is nil (= every string) or one of:
--   { kind = "category",     value = <canonical category name> }
--   { kind = "formatstring", value = <UPPERCASE_GLOBAL_NAME> }
-- The slash dispatch (runTest) is responsible for canonicalizing the
-- value before calling — Test only does an equality check.
--
-- `sink` is where the report goes, and it DEFAULTS to NS.Print — so `/pc test`
-- still lands in chat, one [PC]-prefixed line at a time, visually distinct from
-- real traffic interleaved with it. The settings panel's Test button passes the
-- debug console's writer instead: a 500-line preview belongs in a window with a
-- scrollbar and a copy button, not in the chat frame the addon exists to keep
-- readable. NS.Print's own destination is untouched either way — the sink is a
-- parameter, not a redirection.
function PrettyChat:Test(filter, sink)
    local emit = sink or NS.Print
    emit(note("sample of every format string (preview ignores enable toggles):"))
    if not self:IsAddonEnabled() then
        emit(note("(addon is currently disabled — these formats aren't being applied to live chat)"))
    end

    local printed, errored = 0, 0
    local emittedAny = false
    for _, category in ipairs(NS.Schema.CATEGORY_ORDER) do
        if categoryMatches(filter, category) then
            local names = collectNames(NS.Defaults[category], filter)
            if #names > 0 then
                emittedAny = true
                local p, e = printCategoryBlock(emit, self, category, names)
                printed, errored = printed + p, errored + e
            end
        end
    end

    if not emittedAny then
        emit(note("(no matching strings)"))
        return
    end

    printFooter(emit, printed, errored)
end
