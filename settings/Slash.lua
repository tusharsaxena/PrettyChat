local addonName, NS = ...

-- settings/Slash.lua — the addon's own verbs, and the descriptor that hands the
-- rest to LibKa0s-Slash-1.0.
--
-- What moved: the dispatcher, the help header and rows, the landing-page rows, the
-- `key = value` and command-row formatters, the type-aware value parser and the
-- list/get/set/reset schema verbs. What stayed: the COMMANDS table itself — a host
-- owns its verbs, and the table crossing to the library as plain DATA is what keeps
-- an options library and a slash library from having to resolve each other
-- (slash-commands-§3) — plus the four verbs whose behaviour is genuinely this
-- addon's: `list`'s two reserved sub-keywords and its category filter, `resetall`,
-- `test` and `debug`.

local PrettyChat = LibStub("AceAddon-3.0"):GetAddon("PrettyChat")

local L       = NS.L
-- TOC metadata first so it cannot drift from the packaged manifest, then the
-- in-code constant (slash-commands-§3) — NS.version, which core/Namespace.lua sets
-- from the same metadata with its own literal fallback. A bare "?" here would make
-- `/pc version` answer with a question mark on the one client where the metadata
-- shim comes back empty, which is precisely when a user is being asked what version
-- they are running.
local VERSION = NS.Compat.GetAddOnMetadata(addonName, "Version") or NS.version or "?"
local Color   = NS.Const.Color
local cmd     = NS.Util.cmd
local note    = NS.Util.note
local trim    = NS.Util.trim

local Sl                    -- forward-declared: the handlers below reach it at call time
local listSettings, runReset, runResetAll, runTest, runDebug
local formatValue           -- the `||` display codec; nil when the library is absent

local function schemaReady()
    if not (NS.Schema and NS.Schema.RowsByCategory) then
        NS.Print("schema not ready yet")
        return false
    end
    return true
end

-- Positional triples, the shape the library reads (entry[1] / [2] / [3]); a table
-- of named fields is silently invisible to it. The handler takes `rest` alone —
-- everything after the verb, case and internal spacing preserved.
local COMMANDS = {
    {"help",     L["List available commands"],
        function() Sl:PrintHelp() end},
    {"config",   L["Open the settings panel"],
        function() PrettyChat:OpenConfig() end},
    {"version",  L["Print the addon version"],
        function() Sl:CliVersion() end},
    {"list",     L["List settings — `/pc list [<Category> | category | formatstring]`"],
        function(rest) listSettings(rest) end},
    {"get",      L["Print a setting's current value — `/pc get <path>`"],
        function(rest) Sl:CliGet(rest) end},
    {"set",      L["Set a setting — `/pc set <path> <value>` (try /pc list)"],
        function(rest) Sl:CliSet(rest) end},
    {"reset",    L["Reset one setting to its default — `/pc reset <path>`"],
        function(rest) runReset(rest) end},
    {"resetall", L["Reset every category to addon defaults"],
        function() runResetAll() end},
    {"test",     L["Print sample chat lines — `/pc test [all | category <name> | formatstring <NAME>]`"],
        function(rest) runTest(rest) end},
    {"debug",    L["Debug console — `/pc debug` shows it; `on`/`off` toggle logging"],
        function(rest) runDebug(rest) end},
}

-- Published so settings/Panel.lua's landing page renders the same table the help
-- index does. It crosses as plain data; neither library resolves the other.
NS.COMMANDS = COMMANDS

local lib = LibStub and LibStub("LibKa0s-Slash-1.0", true)

-- The one sentence every lost verb says. Hoisted out of the branch below because
-- `list`'s category filter reads it on the degraded path too.
local CLI_MISSING = NS.LIBKA0S_MISSING .. ", so the settings CLI is unavailable."

if not lib then
    -- `/pc` is registered unconditionally, so something has to answer it. The host
    -- verbs never went to the library, so they keep working; what is lost is the
    -- schema CLI and the shared rendering, and each lost verb names the missing
    -- library rather than going quiet (slash-commands-§1).
    --
    -- Nothing here re-implements a row formatter, a `key = value` shape or the
    -- parser. A degraded help row renders plainly and says so.
    local function unavailable() NS.Print(CLI_MISSING) end

    Sl = {
        OnSlash = function(_, msg)
            local raw = trim(msg)
            if raw == "" then return Sl:PrintHelp() end
            local name, rest = raw:match("^(%S+)%s*(.*)$")
            name = (name or ""):lower()
            for _, entry in ipairs(COMMANDS) do
                if entry[1] == name then return entry[3](rest or "") end
            end
            NS.Print("unknown command '" .. name .. "'")
            Sl:PrintHelp()
        end,
        PrintHelp = function()
            NS.Print("v" .. VERSION .. " slash commands")
            for _, entry in ipairs(COMMANDS) do
                NS.Print("  /pc " .. entry[1] .. " — " .. entry[2])
            end
        end,
        HelpRows    = function()
            local out = {}
            for i, entry in ipairs(COMMANDS) do out[i] = "  /pc " .. entry[1] .. " — " .. entry[2] end
            return out
        end,
        LandingRows = function()
            local out = {}
            for i, entry in ipairs(COMMANDS) do out[i] = "/pc " .. entry[1] .. " — " .. entry[2] end
            return out
        end,
        CliList         = unavailable,
        CliGet          = unavailable,
        CliSet          = unavailable,
        CliReset        = unavailable,
        CliResetAll     = unavailable,
        CliVersion      = function() NS.Print("v" .. VERSION) end,
        BuildListLines  = function() return { CLI_MISSING } end,
        SetRowAnnotator = function() end,
        Text            = function(_, key) return key end,
    }
    NS.SlashCommands = Sl
else

-- The `format` hook (Slash minor 5), applied to a row type the library CAN already
-- render. Its body is `NS.Schema.FormatValue` and NOT a second copy of it: the same
-- renderer serves every CLI echo here and the `[Set]` debug trace at the write seam,
-- so a settings value cannot read one way in chat and another in the console log
-- (slash-commands-§5, debug-logging-§10). See the comment on it in settings/Schema.lua.
formatValue = function(row, stored) return NS.Schema.FormatValue(row, stored) end

-- The counterpart, and the reason it exists is a genuine gap in the lib-level
-- parser rather than an exotic row type: lib.ParseValue splits the remainder on
-- whitespace and a string row takes args[1], so `/pc set <path> You receive loot: %s`
-- would store "You". Every format string in this addon contains spaces, so the whole
-- remainder is the value. `parse` is the sanctioned seam for exactly this
-- (slash-commands-§6), and using it keeps the override at one place instead of
-- forking the dispatcher.
--
-- `||` unescapes to `|` on the way in, mirroring `formatValue` on the way out and
-- the panel's New box on both — so a value copied out of `/pc get` and pasted back
-- into `/pc set` round-trips to the same stored string.
local function parseValue(row, text)
    if row and row.type == "string" then
        if text == nil or text == "" then return nil, lib.STRINGS.ERR_STRING end
        return (text:gsub("||", "|"))
    end
    return lib.ParseValue(row, text)
end

Sl = lib:New({
    slash        = "/pc",
    slashAliases = { "/prettychat" },
    commands     = COMMANDS,

    print   = function(line) NS.Print(line) end,
    version = function() return VERSION end,

    -- The single write seam again — the same functions settings/OptionsSetup.lua
    -- hands the options module, so a CLI change and a checkbox click take one path.
    get          = function(path) return NS.Schema.Get(path) end,
    set          = function(path, value) NS.Schema.Set(path, value) end,
    findRow      = function(path) return NS.Schema.FindByPath(path) end,
    allRows      = function() return NS.Schema.AllRows() end,
    applyDefault = function(row) NS.Schema.ApplyDefault(row) end,

    -- A row's page IS its category here, and rows are declared in CATEGORY_ORDER, so
    -- `list` groups in the order the settings tree shows.
    groupKey = function(row) return row.category end,

    format = formatValue,
    parse  = parseValue,

    -- No `L`: this addon translates none of the dispatcher's strings. Its own verb
    -- DESCRIPTIONS are localized, and they travel in the COMMANDS table above rather
    -- than through the descriptor, which is exactly why that table stays the host's.
})
NS.SlashCommands = Sl

end

-- Two reserved sub-keywords are intercepted before the schema listing, and a bare
-- category name narrows it. None of the three is expressible through CliList, so
-- `list` is the one schema verb that stays host-owned — but its no-argument form
-- DELEGATES, so the header, the group headings and every row come from the one
-- shared renderer rather than a second copy of it here.
function listSettings(rest)
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

    -- No arg → the whole schema, through the library's own list renderer.
    if arg == "" then
        Sl:CliList()
        return
    end

    local matched = NS.Schema.ResolveCategory(arg)
    if not matched then
        NS.Print(note("unknown category '" .. arg .. "'. Valid: ")
                 .. table.concat(NS.Schema.CATEGORY_ORDER, ", "))
        return
    end
    -- The narrowed listing is the library's rendering too, so it cannot drift from
    -- the unfiltered one. With the library absent there is nothing to render it
    -- with, and copying the shape in would be the duplication the extraction ended.
    if not lib then
        NS.Print(CLI_MISSING)
        return
    end
    NS.Print(Sl:Text("LIST_GROUP"):format(matched))
    for _, row in ipairs(NS.Schema.RowsByCategory(matched)) do
        NS.Print("    " .. lib.FormatKV(row.path, formatValue(row, NS.Schema.Get(row.path))))
    end
end

-- ---------------------------------------------------------------------
-- `reset` takes a PATH, not a category (slash-commands-§2, convergence #1).
--
-- This is a BREAKING change to a verb this addon has shipped since 1.0, and it is
-- deliberate: a page is a property of a settings panel, not of the data, and every
-- category page already carries a Defaults button that resets it. The capability
-- did not move — only its CLI route.
--
-- It ships with a deprecation message rather than silently, because the old form
-- still PARSES as something: `/pc reset Loot` would otherwise reach the library and
-- come back "Setting not found: Loot", which tells a user their category is gone
-- rather than that the verb changed. So a bare category name is intercepted here and
-- answered with both of its replacements.
-- ---------------------------------------------------------------------
function runReset(rest)
    if not schemaReady() then return end
    local arg = trim(rest):match("^(%S+)")
    if arg and arg ~= "" and not NS.Schema.FindByPath(arg) then
        local matched = NS.Schema.ResolveCategory(arg)
        if matched then
            NS.Print(note("`") .. cmd("/pc reset " .. arg)
                     .. note("` now takes a setting PATH, not a category."))
            NS.Print(note("  To reset one setting: ") .. cmd("/pc reset <path>") .. note(" (try ")
                     .. cmd("/pc list " .. matched) .. note(")"))
            NS.Print(note("  To reset all of ") .. matched .. note(": the ") .. cmd("Defaults")
                     .. note(" button on its settings page, or ") .. cmd("/pc resetall")
                     .. note(" for everything."))
            return
        end
    end
    Sl:CliReset(rest)
end

-- Kept host-owned rather than delegated to CliResetAll, for the same reason the
-- per-category Defaults button is: PrettyChat:ResetAll wipes the profile and
-- re-applies in ONE pass with ONE [Reset] summary line, where the library's
-- row-by-row form would run ApplyStrings ~171 times and emit ~171 [Set] lines into
-- a 500-line console buffer (debug-logging-§9).
function runResetAll()
    PrettyChat:ResetAll()
    NS.Print(note("all settings reset to defaults"))
end

-- /pc debug        toggles the on-screen debug console window (logging state unchanged).
-- /pc debug on|off enables / disables session logging via the DebugLog:SetEnabled seam,
--                  which owns the chat ack + the header label + the console bracket line
--                  (debug-logging-§5). Bare-toggle and on/off are deliberately separate:
--                  capture can run with the window closed and be opened after the fact.
function runDebug(rest)
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

function runTest(rest)
    local arg = trim(rest)
    if arg == "" or arg:lower() == "all" then
        PrettyChat:Test()
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
        PrettyChat:Test({ kind = "category", value = matched })
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
        PrettyChat:Test({ kind = "formatstring", value = upper })
        return
    end

    NS.Print("usage: " .. cmd("/pc test") .. note(", ")
             .. cmd("/pc test all") .. note(", ")
             .. cmd("/pc test category <name>") .. note(", or ")
             .. cmd("/pc test formatstring <NAME>"))
end

-- AceConsole registers both chat commands; the library registers none of its own,
-- which is what keeps every verb's output flowing through the tagged printer
-- (slash-commands-§1).
function PrettyChat:OnSlashCommand(input)
    Sl:OnSlash(input)
end
