local _, NS = ...

-- settings/Slash.lua — the addon's own verbs, and the descriptor that hands the
-- rest to LibKa0s-Slash-1.0.
--
-- What moved: the dispatcher, the help header and rows, the landing-page rows, the
-- `key = value` and command-row formatters, the type-aware value parser and the
-- list/get/set/reset schema verbs. What stayed: the COMMANDS table itself — a host
-- owns its verbs, and the table crossing to the library as plain DATA is what keeps
-- an options library and a slash library from having to resolve each other
-- (slash-commands-§3) — plus the four verbs whose behavior is genuinely this
-- addon's: `list`'s two reserved sub-keywords and its category filter, `resetall`,
-- `test` and `debug`.

local PrettyChat = LibStub("AceAddon-3.0"):GetAddon("PrettyChat")

local L       = NS.L
-- The version banner, resolved ONCE at file load through the core/EnvSetup.lua seam.
-- NS.Version() is the whole ladder (slash-commands-§3): the packaged TOC first so this
-- cannot drift from the manifest, then NS.version — core/Namespace.lua's literal, set
-- from the same metadata — and only then "?". A bare "?" here would make `/pc version`
-- answer with a question mark on the one client where the metadata cannot be read,
-- which is precisely when a user is being asked what version they are running.
local VERSION = NS.Version()
local Color   = NS.Const.Color
local cmd     = NS.Util.cmd
local note    = NS.Util.note
local trim    = NS.Util.trim

local Sl                    -- forward-declared: the handlers below reach it at call time
local listSettings, runReset, runResetAll, runTest, runDebug, setEnabled
local formatValue           -- the `||` display codec; nil when the library is absent

local function schemaReady()
    if not (NS.Schema and NS.Schema.RowsByCategory) then
        NS.Print(L["schema not ready yet"])
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
    {"resetall", L["Reset every setting to defaults"],
        function() runResetAll() end},
    {"test",     L["Print sample chat lines to the debug console — `/pc test [all | category <name> | formatstring <NAME>]`"],
        function(rest) runTest(rest) end},
    {"debug",    L["Debug console — `/pc debug` shows it; `on`/`off` toggle logging"],
        function(rest) runDebug(rest) end},
    -- The two reserved ALIASES (slash-commands-§2). They are the LAST entries
    -- rather than sorted in beside `config`, because `/pc help` and the landing
    -- page both render this table in declaration order and the schema verbs are
    -- what a user is usually looking for.
    {"enable",   L["Enable the addon"],
        function() setEnabled(true) end},
    {"disable",  L["Disable the addon"],
        function() setEnabled(false) end},
}

-- Published for the suite, which pins the host-owns-its-verbs contract against it; no
-- production caller reads it — settings/Panel.lua's landing page reaches the same rows
-- through NS.SlashCommands:LandingRows(). It crosses as plain data; neither library
-- resolves the other.
NS.COMMANDS = COMMANDS

-- ---------------------------------------------------------------------
-- THE DISABLED GATE (slash-commands-§2 and §7) — THE LIBRARY'S, NOT OURS
--
-- WHAT THE DISABLED SURFACE IS. Every reserved verb answers normally: `help`,
-- `config`, `version`, `enable`, `disable`, `debug`, `perf`, and the whole schema
-- CLI — `get`, `set`, `list`, `reset`, `resetall` — and the BARE `/pc` opens the
-- settings panel exactly as it does when the addon is running. The reasoning is the
-- player's rather than the addon's: they must be able to READ AND REPAIR SETTINGS
-- and to REACH THE PANEL while the addon is off, which is precisely when they are
-- most likely to need to, and `enable` above all or the pair is one-way again.
--
-- THIS IS ALSO THE ANSWER TO A RULE THAT MOVED AND MOVED BACK. The standard
-- narrowed this surface to `enable` and `help` at v2.56.0 and REVERSED it at
-- v2.57.0 (Slash minor 13), on the first thing anyone tried: `/pc` on a disabled
-- addon answered with a refusal instead of opening the one panel the player uses to
-- switch it back on by hand. This addon never shipped the narrowing, and the live
-- set is not restated here in any case — `lib.LIVE_VERBS` carries it, and a host
-- copy would be the thing that went stale the next time it moved.
--
-- SO THE GATE REFUSES EXACTLY ONE VERB HERE: `test`, the preview no other Ka0s
-- addon has. §2 keeps the refusal a SHOULD partly because an addon with a single
-- feature verb may reasonably read the line as noise — here it is not noise,
-- because `/pc test` renders every format string to show what LIVE CHAT will look
-- like, and while the addon is disabled live chat is Blizzard's wording. The
-- panel's Test button is NOT gated and must not be: it is not a verb, it sits on
-- the page beside the switch that turned the addon off, and its report already says
-- so on its second line (modules/Override.lua's PrettyChat:Test).
--
-- NO `liveVerbs` IS PASSED, and the omission is the whole decision. That field
-- WIDENS the live set — it is how a host declares that a feature verb of its own
-- should act rather than refuse — and this addon wants its one feature verb
-- refused. It is emphatically not a place to narrow anything: §7 is explicit that
-- what a host MUST NOT do is refuse something on the library's live set.
--
-- THE WORDING IS THE COLLECTION'S. `lib.DISABLED_LINE_FORMAT` is the one shape and
-- `cli:DisabledLine()` builds it, so a player running six of these addons reads one
-- answer to one question instead of six. The host-rolled line this addon used to
-- print — "`/pc test` does nothing while the addon is disabled" — was a second
-- spelling of a sentence the collection owns, and its locale key went with it.
--
-- THE DEGRADED PATH BUILDS THE LINE BUT STILL REFUSES NOTHING. With no LibKa0s
-- there is no gate, and the stub does not grow one: re-implementing it would mean
-- a host copy of the live set, which `lib.LIVE_VERBS` exists to keep in one place.
-- What the stub DOES carry is the one library string slash-commands-§1 (v2.65.0)
-- lets a degradation stub copy verbatim, `DISABLED_LINE_FORMAT`, so its
-- `DisabledLine` answers the collection's sentence rather than nil — the shape the
-- LibKa0s Slash version-15 document's "The degradation stub" prescribes, pinned
-- against the live library by tests/test_surface_parity.lua. Nothing on the
-- degraded arm prints it today: `enable` and `disable` write through the
-- stub-composed General.enabled row (setEnabled, below), which is route (a) of
-- that document, and `/pc test` prints its preview, a report about format strings
-- that reaches no write seam.
-- ---------------------------------------------------------------------

local lib = LibStub and LibStub("LibKa0s-Slash-1.0", true)

-- The plain-text `Ka0s <Name>` both arms name the addon by: the live descriptor's
-- `brandName` and the degraded DisabledLine's subject. One local, so the two lines
-- cannot disagree about whose addon is disabled.
local BRAND_NAME = "Ka0s Pretty Chat"

-- The verbatim bytes of LibKa0s-Slash-1.0's `lib.DISABLED_LINE_FORMAT` (the em dash
-- is \226\128\148). The ONE library string the degraded stub may carry
-- (slash-commands-§1); tests/test_surface_parity.lua pins it byte for byte with
-- Kit.assertLibraryConstant, so a library rewording turns that case red here.
local STUB_DISABLED_LINE_FORMAT = "%s is disabled \226\128\148 enable it with |cFFFFFF00%s|r"

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
    local function findCommand(name)
        for _, entry in ipairs(COMMANDS) do
            if entry[1] == name then return entry end
        end
    end

    Sl = {
        OnSlash = function(_, msg)
            local raw = trim(msg)
            -- A bare `/pc` opens the settings panel through the `config` verb when one
            -- is registered, and prints help only when none is, the same as the
            -- library's dispatcher since Slash minor 11 (slash-commands-§4).
            if raw == "" then
                local config = findCommand("config")
                if config then return config[3]("") end
                return Sl:PrintHelp()
            end
            local name, rest = raw:match("^(%S+)%s*(.*)$")
            name = (name or ""):lower()
            local entry = findCommand(name)
            if entry then return entry[3](rest or "") end
            NS.Print(L["unknown command '%s'"]:format(name))
            Sl:PrintHelp()
        end,
        -- Declared with the leading `_` these three are METHODS, matching the
        -- library's `function Sl:PrintHelp()` / `:HelpRows()` / `:LandingRows()`
        -- and the `Text` stub below. Every caller uses a colon; a stub whose
        -- shape differs from the live surface is a degraded path that only
        -- happens to work (PC-R-08).
        PrintHelp = function(_)
            NS.Print(L["v%s slash commands"]:format(VERSION))
            for _, entry in ipairs(COMMANDS) do
                NS.Print("  /pc " .. entry[1] .. " — " .. entry[2])
            end
        end,
        HelpRows    = function(_)
            local out = {}
            for i, entry in ipairs(COMMANDS) do out[i] = "  /pc " .. entry[1] .. " — " .. entry[2] end
            return out
        end,
        LandingRows = function(_)
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
        -- The collection's one sentence, built the way `cli:DisabledLine()` builds
        -- it: the plain-text brand, then `/pc enable`. From the verbatim copy above,
        -- never a host spelling, so a degraded build words the refusal exactly as a
        -- live one does (slash-commands-§1, the Slash version-15 degradation stub).
        -- The degraded arm still refuses nothing (see the gate's header): its
        -- `enable` and `disable` take the WS-02 route and write through the
        -- stub-composed General.enabled row in setEnabled below.
        DisabledLine    = function(_) return STUB_DISABLED_LINE_FORMAT:format(BRAND_NAME, "/pc enable") end,
        -- Published for tests/test_surface_parity.lua's assertLibraryConstant pin.
        -- The `__` prefix keeps it out of Kit.publicMembers, so the parity case
        -- does not ask the live instance to carry it.
        __disabledLineFormat = STUB_DISABLED_LINE_FORMAT,
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

-- The counterpart, through the `parse` seam (slash-commands-§6). The library does
-- the parsing: since Slash minor 10 lib.ParseValue gives a string row the WHOLE
-- value, trimmed at both edges with its interior spacing verbatim, and refuses a
-- blank one with its own "expected a value". Every format string in this addon
-- contains spaces, which is why this hook once took the remainder itself; minor 9
-- kept only the first word. What stays here is the one thing the library does not
-- do: `||` unescapes to `|` on the way in, mirroring `formatValue` on the way out
-- and the panel's New box on both, so a value copied out of `/pc get` and pasted
-- back into `/pc set` round-trips to the same stored string.
--
-- The edge trim costs nothing: the dispatcher trims the whole input before any verb
-- runs, so an edge space typed in chat never reached this hook at minor 9 either.
local function parseValue(row, text)
    local v, err = lib.ParseValue(row, text)
    if v ~= nil and row and row.type == "string" then v = v:gsub("||", "|") end
    return v, err
end

Sl = lib:New({
    slash        = "/pc",
    slashAliases = { "/prettychat" },
    commands     = COMMANDS,

    print   = function(line) NS.Print(line) end,
    version = function() return VERSION end,

    -- THE GATE'S TWO FIELDS (Slash minor 12, live set restored at 13).
    --
    -- `isEnabled` is asked at DISPATCH time and never cached, so the command after
    -- an `/pc enable` acts rather than refusing. It reads the STORED path and not
    -- the latch, because the line it decides to print names `/pc enable`: that is
    -- the true and useful answer for the hold a player took, and it would be the
    -- wrong one for a `perf` hold nobody can release with that verb. This addon
    -- takes no `perf` hold at all (core/LifecycleSetup.lua says why), so the two
    -- questions have one answer here today; they are still different questions.
    --
    -- `brandName` is the plain-text `Ka0s <Name>` — the SAME string
    -- core/LauncherSetup.lua gives the LDB object as `label`, and the same string
    -- for the same reason: launcher-§1 forbids escape sequences there, which is
    -- what makes it safe to drop into a colored line. NOT the TOC's `## Title`,
    -- which is this addon's rainbow brand mark and a ratified toc-file-§1 deviation.
    isEnabled = function() return PrettyChat:IsAddonEnabled() end,
    brandName = BRAND_NAME,

    -- The single write seam again — the same schema-runtime members settings/OptionsSetup.lua
    -- hands the options module, as values, so a CLI change and a checkbox click take one
    -- path. `/pc set` of a format crosses the PC-R-01 gate because the gate is the row's
    -- `validate`, which the runtime's Set runs (settings/Schema.lua).
    get          = NS.SchemaRuntime.Get,
    set          = NS.SchemaRuntime.Set,
    findRow      = NS.SchemaRuntime.FindRow,
    allRows      = NS.SchemaRuntime.AllRows,
    applyDefault = NS.SchemaRuntime.ApplyDefault,

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
        NS.Print(Color.listHead .. L["Categories (%d)"]:format(#sorted) .. Color.reset)
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
        NS.Print(Color.listHead .. L["Format strings (%d)"]:format(#pairs_) .. Color.reset)
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
        NS.Print(note(L["unknown category '%s'. Valid: "]:format(arg))
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
-- deliberate: a page is a property of a settings panel, not of the data. The
-- Categories page's Defaults button resets every category tab at once (it is
-- page-wide, options-ui-§13), and one row at a time is `/pc reset <path>`.
-- The replacements below say so rather than promising a per-category reset.
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
            NS.Print(note("  To reset every category: the ") .. cmd("Defaults")
                     .. note(" button on the Categories settings page, or ") .. cmd("/pc resetall")
                     .. note(" for everything."))
            return
        end
    end
    Sl:CliReset(rest)
end

-- ---------------------------------------------------------------------
-- `/pc enable` and `/pc disable` — ALIASES, NEVER A SECOND SWITCH
-- (slash-commands-§2).
--
-- This addon already carries an addon-wide switch: `General.enabled`, the first
-- row of General > Master controls, wired in settings/Schema.lua's MASTER_WIRING
-- and stored only when OFF. These two verbs write THAT path, through THAT seam,
-- and hold nothing of their own — no second key, no session flag, no `NS.enabled`
-- local — so the checkbox and the verbs can never show a player two answers, and
-- whichever surface was used runs the same ApplyStrings pass and the same panel
-- refresh. `/pc set General.enabled false` is the same write by its long name and
-- still works; these are the short spellings the collection reserves.
--
-- THE ECHO IS THE LIBRARY'S, not a second copy of it. CliSet renders the
-- confirmation in slash-commands-§5's `set` shape, so `/pc disable` and
-- `/pc set General.enabled false` answer byte for byte.
--
-- THE VERBS MUST SURVIVE THE DISABLED STATE, or the pair is one-way: a player
-- turns the addon off and the verb that turns it back on is gone. Nothing here
-- can take them away — core/PrettyChat.lua's OnInitialize registers `/pc` and
-- `/prettychat` unconditionally and nothing unregisters them, and the COMMANDS
-- table above is built at file load and never rebuilt. Disabled means this addon
-- stands its OVERRIDES down, and that a verb DRIVING those overrides refuses (the
-- disabled gate above, which asks the stored path through `IsAddonEnabled`, while
-- ApplyStrings asks the lifecycle latch through `IsStoodDown`); the dispatcher, the settings panel and
-- the launcher are SETUP and come up in either state, and these two verbs are
-- named in the live set so the gate can never reach them.
-- tests/test_slash.lua and tests/test_launcher.lua pin that.
local ENABLED_PATH = "General.enabled"

function setEnabled(on)
    if not schemaReady() then return end
    if lib then
        Sl:CliSet(ENABLED_PATH .. " " .. tostring(on))
        return
    end
    -- Library absent. The CLI renderer went with it, but the SCHEMA did not —
    -- settings/OptionsSetup.lua's stub still composes the Master controls leaves,
    -- so the row and its write seam are both here — and slash-commands-§2 names
    -- `enable` as the verb that MUST keep working above all others. So the write
    -- happens and the line is the pre-library rendering, the same one
    -- Schema.FormatValue falls back to: no color, no `key = value` helper, just
    -- the path and the value it now holds.
    NS.Schema.Set(ENABLED_PATH, on)
    local row = NS.Schema.FindByPath(ENABLED_PATH)
    NS.Print(ENABLED_PATH .. " = "
             .. NS.Schema.FormatValue(row, NS.Schema.Get(ENABLED_PATH)))
end

-- Kept host-owned rather than delegated to CliResetAll, for the same reason the
-- Categories page's Defaults button is: PrettyChat:ResetAll wipes the profile and
-- re-applies in ONE pass, and its OnProfileReset handler logs the ONE
-- `[Set] reset profile '<name>' to defaults (N rows)` line (debug-logging-§10),
-- where the library's row-by-row form would run ApplyStrings 170 times.
function runResetAll()
    PrettyChat:ResetAll()
    NS.Print(note(L["all settings reset to defaults"]))
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
            NS.Print(note(L["debug console unavailable"]))
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
        PrettyChat:TestToConsole()
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
            NS.Print(note(L["unknown category '%s'. Valid: "]:format(value))
                     .. table.concat(NS.Schema.CATEGORY_ORDER, ", "))
            return
        end
        PrettyChat:TestToConsole({ kind = "category", value = matched })
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
            NS.Print(note(L["unknown format string '%s' — try "]:format(value))
                     .. cmd("/pc list formatstring"))
            return
        end
        PrettyChat:TestToConsole({ kind = "formatstring", value = upper })
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
