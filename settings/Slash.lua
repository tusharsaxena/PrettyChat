local addonName, NS = ...

-- Slash command dispatch — KickCD-style ordered command table (Ka0s standard,
-- slash-commands). Each entry is {name, description, fn(self, rest)}. Help text is
-- generated from this same table so adding a command means adding one row. The
-- schema-driven get/set/list go through NS.Schema so the panel widgets and slash commands
-- share a single write path. Methods hang off the shared PrettyChat AceAddon object.

local PrettyChat = LibStub("AceAddon-3.0"):GetAddon("PrettyChat")

local L       = NS.L
local VERSION = NS.Compat.GetAddOnMetadata(addonName, "Version") or "?"
local Color   = NS.Const.Color
local cmd     = NS.Util.cmd
local note    = NS.Util.note
local trim    = NS.Util.trim

-- slash-commands-§5 shared `key = value` line: gold schema path, white value (the ` = `
-- separator stays default-coloured). The value string always comes from
-- NS.Schema.FormatValue, so the `list` rows and the `get`/`set` echo can never drift.
local function FormatKV(path, valueStr)
    return Color.yellow .. path .. Color.reset .. " = " .. Color.white .. valueStr .. Color.reset
end

local function schemaReady()
    if not (NS.Schema and NS.Schema.RowsByCategory) then
        NS.Print("schema not ready yet")
        return false
    end
    return true
end

local printHelp, listSettings, getSetting, setSetting, runReset, runResetAll, runTest, runDebug

local COMMANDS = {
    {"help",     L["List available commands"],
        function(self) printHelp(self) end},
    {"config",   L["Open the settings panel"],
        function(self) self:OpenConfig() end},
    {"version",  L["Print the addon version"],
        function() NS.Print("v" .. VERSION) end},
    {"list",     L["List settings — `/pc list [<Category> | category | formatstring]`"],
        function(self, rest) listSettings(self, rest) end},
    {"get",      L["Print a setting's current value — `/pc get <path>`"],
        function(self, rest) getSetting(self, rest) end},
    {"set",      L["Set a setting — `/pc set <path> <value>` (try /pc list)"],
        function(self, rest) setSetting(self, rest) end},
    {"reset",    L["Reset a category to defaults — `/pc reset <Category>`"],
        function(self, rest) runReset(self, rest) end},
    {"resetall", L["Reset every category to addon defaults"],
        function(self) runResetAll(self) end},
    {"test",     L["Print sample chat lines — `/pc test [all | category <name> | formatstring <NAME>]`"],
        function(self, rest) runTest(self, rest) end},
    {"debug",    L["Debug console — `/pc debug` shows it; `on`/`off` toggle logging"],
        function(self, rest) runDebug(self, rest) end},
}

-- Published so Panel.lua's parent panel can render the slash-command list
-- from the same source the /pc help dispatcher uses, keeping the two surfaces
-- from drifting.
NS.COMMANDS = COMMANDS

function printHelp(self)
    NS.Print(note("v" .. VERSION .. " slash commands (")
             .. cmd("/prettychat") .. note(" is an alias for ")
             .. cmd("/pc") .. note(")"))
    for _, entry in ipairs(COMMANDS) do
        NS.Print("  " .. cmd("/pc " .. entry[1]) .. " — " .. note(entry[2]))
    end
end

-- Two reserved sub-keywords intercepted before the category-name path:
--   `/pc list category`     → list every category name (alphabetical)
--   `/pc list formatstring` → list every Category.GLOBALNAME pair
-- Neither name is a valid category, so the existing ResolveCategory
-- branch could never have matched them — the keywords are unambiguous.

function listSettings(self, rest)
    if not schemaReady() then return end
    local arg = trim(rest)
    local lowered = arg:lower()

    if lowered == "category" then
        local sorted = {}
        for _, c in ipairs(NS.Schema.CATEGORY_ORDER) do sorted[#sorted + 1] = c end
        table.sort(sorted)
        NS.Print(Color.listHead .. "Categories (" .. #sorted .. ")" .. Color.reset)
        for _, c in ipairs(sorted) do NS.Print("  " .. c) end
        return
    end

    if lowered == "formatstring" then
        local pairs_ = {}
        for _, category in ipairs(NS.Schema.CATEGORY_ORDER) do
            local catData = NS.Defaults[category]
            if catData and catData.strings then
                for globalName in pairs(catData.strings) do
                    pairs_[#pairs_ + 1] = { category, globalName }
                end
            end
        end
        table.sort(pairs_, function(a, b)
            if a[1] == b[1] then return a[2] < b[2] end
            return a[1] < b[1]
        end)
        NS.Print(Color.listHead .. "Format strings (" .. #pairs_ .. ")" .. Color.reset)
        for _, p in ipairs(pairs_) do
            NS.Print(("  %s.%s"):format(p[1], p[2]))
        end
        return
    end

    -- No arg → dump every row across every category. With ~170 rows the
    -- output is long, but it's the only way the slash UI reaches parity
    -- with the panel (which exposes a toggle and a format edit-box per
    -- string). To filter, pass a category name (or one of the two
    -- reserved sub-keywords above).
    if arg == "" then
        -- slash-commands-§5: green "Available settings" header, azure [category] group
        -- headers, gold-key/white-value FormatKV rows via the shared value formatter.
        NS.Print(Color.listHead .. "Available settings" .. Color.reset)
        for _, category in ipairs(NS.Schema.CATEGORY_ORDER) do
            NS.Print("  " .. Color.azure .. "[" .. category .. "]" .. Color.reset)
            for _, row in ipairs(NS.Schema.RowsByCategory(category)) do
                NS.Print("    " .. FormatKV(row.path, NS.Schema.FormatValue(row, NS.Schema.Get(row.path))))
            end
        end
        return
    end

    local matched = NS.Schema.ResolveCategory(arg)
    if not matched then
        NS.Print(note("unknown category '" .. arg .. "'. Valid: ")
                 .. table.concat(NS.Schema.CATEGORY_ORDER, ", "))
        return
    end
    NS.Print("  " .. Color.azure .. "[" .. matched .. "]" .. Color.reset)
    for _, row in ipairs(NS.Schema.RowsByCategory(matched)) do
        NS.Print("    " .. FormatKV(row.path, NS.Schema.FormatValue(row, NS.Schema.Get(row.path))))
    end
end

function getSetting(self, rest)
    if not schemaReady() then return end
    local path = trim(rest):match("^(%S+)")
    if not path or path == "" then
        NS.Print("usage: " .. cmd("/pc get <path>"))
        return
    end
    local row = NS.Schema.FindByPath(path)
    if not row then
        NS.Print(note("setting not found: '" .. path .. "'"))
        return
    end
    NS.Print(FormatKV(row.path, NS.Schema.FormatValue(row, NS.Schema.Get(row.path))))
end

function setSetting(self, rest)
    if not schemaReady() then return end
    local path, value = trim(rest):match("^(%S+)%s*(.*)$")
    if not path or path == "" then
        NS.Print("usage: " .. cmd("/pc set <path> <value>"))
        return
    end
    local row = NS.Schema.FindByPath(path)
    if not row then
        NS.Print(note("setting not found: '" .. path .. "'"))
        return
    end

    local newVal
    if row.type == "bool" then
        local s = (value or ""):match("^(%S*)"):lower()
        if s == "true" or s == "1" or s == "on"  or s == "yes" then newVal = true
        elseif s == "false" or s == "0" or s == "off" or s == "no"  then newVal = false
        else
            NS.Print(note("invalid bool '" .. (value or "") .. "' (expected true/false/on/off/1/0/yes/no)"))
            return
        end
    elseif row.type == "string" then
        if value == nil or value == "" then
            NS.Print("usage: " .. cmd("/pc set " .. path .. " <value>"))
            return
        end
        newVal = value
    else
        NS.Print(note("unsupported type '" .. tostring(row.type) .. "'"))
        return
    end

    NS.Schema.Set(path, newVal)
    -- Echo the *stored* value (read back after Set) so any coercion is reflected.
    NS.Print(FormatKV(row.path, NS.Schema.FormatValue(row, NS.Schema.Get(row.path))))
end

function runReset(self, rest)
    local arg = trim(rest):match("^(%S+)")
    if not arg or arg == "" then
        NS.Print("usage: " .. cmd("/pc reset <Category>") .. note(". Valid: ")
                 .. table.concat(NS.Schema.CATEGORY_ORDER, ", "))
        return
    end
    local matched = NS.Schema.ResolveCategory(arg)
    if not matched then
        NS.Print(note("unknown category '" .. arg .. "'. Valid: ")
                 .. table.concat(NS.Schema.CATEGORY_ORDER, ", "))
        return
    end
    self:ResetCategory(matched)
    NS.Print(matched .. " reset to defaults")
end

function runResetAll(self)
    self:ResetAll()
    NS.Print(note("all settings reset to defaults"))
end

-- /pc debug        toggles the on-screen debug console window (logging state unchanged).
-- /pc debug on|off enables / disables session logging via the DebugLog:SetEnabled seam,
--                  which owns the chat ack + the header label + the console bracket line
--                  (debug-logging-§5). Bare-toggle and on/off are deliberately separate:
--                  capture can run with the window closed and be opened after the fact.
function runDebug(self, rest)
    local arg = trim(rest):lower()
    if arg == "on" or arg == "off" then
        if NS.DebugLog and NS.DebugLog.SetEnabled then
            NS.DebugLog:SetEnabled(arg == "on")
        else
            NS.State.debug = (arg == "on")
        end
        return
    end
    if arg == "" or arg == "toggle" then
        if NS.DebugLog and NS.DebugLog.Toggle then
            NS.DebugLog:Toggle()
        else
            NS.Print(note("debug console unavailable"))
        end
        return
    end
    NS.Print("usage: " .. cmd("/pc debug [on | off]"))
end

local function formatStringExists(globalName)
    for _, catData in pairs(NS.Defaults) do
        if catData.strings and catData.strings[globalName] then
            return true
        end
    end
    return false
end

function runTest(self, rest)
    local arg = trim(rest)
    if arg == "" or arg:lower() == "all" then
        self:Test()
        return
    end

    local kind, value = arg:match("^(%S+)%s*(.*)$")
    kind  = (kind or ""):lower()
    value = trim(value or "")

    if kind == "category" then
        if value == "" then
            NS.Print("usage: " .. cmd("/pc test category <name>") .. note(". Valid: ")
                     .. table.concat(NS.Schema.CATEGORY_ORDER, ", "))
            return
        end
        local matched = NS.Schema.ResolveCategory(value)
        if not matched then
            NS.Print(note("unknown category '" .. value .. "'. Valid: ")
                     .. table.concat(NS.Schema.CATEGORY_ORDER, ", "))
            return
        end
        self:Test({ kind = "category", value = matched })
        return
    end

    if kind == "formatstring" then
        if value == "" then
            NS.Print("usage: " .. cmd("/pc test formatstring <NAME>")
                     .. note(" — try ") .. cmd("/pc list formatstring"))
            return
        end
        local upper = value:upper()
        if not formatStringExists(upper) then
            NS.Print(note("unknown format string '" .. value .. "' — try ")
                     .. cmd("/pc list formatstring"))
            return
        end
        self:Test({ kind = "formatstring", value = upper })
        return
    end

    NS.Print("usage: " .. cmd("/pc test") .. note(", ")
             .. cmd("/pc test all") .. note(", ")
             .. cmd("/pc test category <name>") .. note(", or ")
             .. cmd("/pc test formatstring <NAME>"))
end

function PrettyChat:OnSlashCommand(input)
    local raw = trim(input)
    if raw == "" then return printHelp(self) end

    -- Lowercase the command name; preserve case in `rest` so dot paths
    -- like Loot.LOOT_ITEM_SELF.format survive intact through to set/get.
    local name, rest = raw:match("^(%S+)%s*(.*)$")
    name = (name or ""):lower()
    rest = rest or ""

    for _, entry in ipairs(COMMANDS) do
        if entry[1] == name then return entry[3](self, rest) end
    end

    NS.Print(note("unknown command '" .. name .. "'"))
    printHelp(self)
end
