local addonName, NS = ...

-- core/DebugLogSetup.lua — wires the addon into LibKa0s-DebugLog-1.0.
--
-- The console window, the copy window, the two line formatters, the ring buffer,
-- the scrollbar sync, the line counter and the enable seam all lived in
-- core/DebugLog.lua and are now the library's, shared across the collection. This
-- file supplies only the part that is ours: the frame-name prefix, the human
-- title, the monospace font path, where the debug flag actually lives, what the
-- [Init] session summary says, and who to tell when the window opens or closes.
--
-- TOC slot: core/DebugLog.lua's old one, which puts it after core/Constants.lua
-- (FONT_MONO), core/State.lua (the flag), core/CoreSetup.lua (NS.Print and the
-- secret-safe stringifier) and before every module that calls NS.Debug
-- (debug-logging-§1).

-- One line naming the build, the schema version and the active profile, for the
-- [Init] bracket. The library owns WHEN it is emitted — on enable, because the
-- flag is session-only and off at login, so a load-time summary would always be
-- gated off and never render — and only we can know what it says
-- (debug-logging-§5/§8).
local function sessionSummary()
    local name    = NS.name or "PrettyChat"
    local version = NS.version or "?"
    local schema, profile = "?", "?"
    local db = NS.db
    if db then
        if db.global and db.global.schemaVersion ~= nil then
            schema = tostring(db.global.schemaVersion)
        end
        if type(db.GetCurrentProfile) == "function" then
            local ok, p = pcall(db.GetCurrentProfile, db)
            if ok and p then profile = tostring(p) end
        end
    end
    return ("%s v%s, schema v%s, profile '%s'"):format(name, version, schema, profile)
end

local lib = LibStub and LibStub("LibKa0s-DebugLog-1.0", true)

if not lib then
    -- A missing vendored lib must degrade, not error at load. The stub covers every
    -- member the addon calls — settings/Slash.lua's `/pc debug`, settings/Panel.lua's
    -- console checkbox — and the FLAG itself still works, because NS.State.debug is
    -- ours and a user who types `/pc debug on` must not be told nothing happened.
    -- What is lost is the window, and the stub says so once, honestly.
    local missing = NS.LIBKA0S_MISSING .. ", so the debug console window is unavailable."

    -- ONE announce per ENTRY POINT. A single shared token is spent by whichever
    -- path the user happens to take first — `/pc debug on` burns it, and then the
    -- very next `/pc debug`, which is the verb that actually asks for the WINDOW,
    -- says nothing at all. Each surface that silently does less than it looks like
    -- it does explains itself once.
    local function announcer()
        local said = false
        return function()
            if said then return end
            said = true
            if NS.Print then NS.Print(missing) end
        end
    end
    local sayOnEnable, sayOnWindow, sayOnCopy = announcer(), announcer(), announcer()

    -- No formatters here, deliberately. Nothing in the addon calls them — they exist
    -- only inside the library's own Add — and hand-copying the exact strings whose
    -- seven-way drift this extraction exists to end is the one duplicate
    -- testing-§8 most specifically forbids (debug-logging-§3/§7).
    NS.DebugLog = {
        buffer          = {},
        Add             = function() end,
        Debug           = function() end,
        Clear           = function() end,
        Show            = function() sayOnWindow() end,
        Hide            = function() end,
        Toggle          = function() sayOnWindow() end,
        IsShown         = function() return false end,
        IsEnabled       = function() return (NS.State and NS.State.debug) and true or false end,
        RefreshHeader   = function() end,
        ShowCopy        = function() sayOnCopy() end,
        UpdateScrollBar = function() end,
        UpdateStatus    = function() end,
        BufferSize      = function() return 0 end,
        LastLine        = function() return nil end,
        FindLine        = function() return nil end,
        CopyText        = function() return "" end,
        -- Three parameters it never reads, so the degraded shape matches the live one
        -- (PC-R-08, below). A zero-arity stub in front of a three-argument target is the
        -- shape anti-pattern #64 punishes, and it is the shape a future caller would copy.
        MakeCloseButton = function(_parent, _onClick, _addonName) return nil end,
        SessionSummary  = sessionSummary,
        SetEnabled      = function(_, on)
            on = not not on
            if NS.State then NS.State.debug = on end
            if NS.Print then
                NS.Print("debug logging " .. (on and "|cff40ff40ON|r" or "|cffff4040OFF|r"))
            end
            if on then sayOnEnable() end
        end,
        ConsoleCheckbox = function()
            return {
                label   = "Debug console",
                tooltip = missing,
                get     = function() return false end,
                set     = function() sayOnWindow() end,
            }
        end,
    }
    NS.Debug = NS.DebugLog.Debug
    return
end

NS.DebugLog = lib:New({
    -- Seeds PrettyChatDebugWindow / PrettyChatDebugCopyWindow /
    -- PrettyChatDebugCopyScroll — the same three frame globals the hand-written
    -- console used, so /framestack and any Esc-close muscle memory are unchanged.
    name  = addonName,
    -- THE FOLDER NAME, which is a different question from the one above even though
    -- this addon answers both with the same string. `name` seeds the frame globals;
    -- `addonName` is what the library builds a texture path from, so its own copy,
    -- clear and close controls draw this collection's art instead of two words and a
    -- multiplication sign. A vendored library cannot work that out for itself -- there
    -- is no one path to it -- and a host where the two strings diverge would hand it a
    -- path into nowhere, which draws nothing and raises nothing. Passed explicitly for
    -- that reason, BESIDE `name` and never instead of it.
    addonName = addonName,
    -- The library appends its own " — Debug", so this is the bare brand.
    title = "Pretty Chat",
    font  = NS.Const.FONT_MONO,
    slash = "/pc",

    -- The flag stays ours. NS.State.debug is session-only (debug-logging-§5) and is
    -- read by the settings panel and the slash verb as well as by the console, so a
    -- second copy inside the library would be a second truth.
    isEnabled  = function() return (NS.State and NS.State.debug) and true or false end,
    setEnabled = function(on) if NS.State then NS.State.debug = on end end,

    -- Thin call-time forwarders, never captured references (debug-logging-§1). Both
    -- of these are published by core/CoreSetup.lua, and freezing either at load
    -- would mean acknowledging through whatever happened to exist at that instant.
    print        = function(line) NS.Print(line) end,
    safeToString = function(v) return NS.Util.SafeToString(v) end,

    initSummary = sessionSummary,

    -- The General page's console checkbox mirrors the window's visibility, so a
    -- console closed with Esc or the × has to move a checkbox on a panel that is
    -- already open. Guarded because settings/ loads after core/.
    onVisibilityChanged = function()
        if NS.Schema and NS.Schema.NotifyPanelChange then
            NS.Schema.NotifyPanelChange("General")
        end
    end,

    -- No `L`: this addon translates none of the console's strings, so omitting the
    -- field is both the common case and the safe one (README, "The `L` trap").
    --
    -- `addonName` above is the one identity field the library needs beyond `name`.
    --
    -- No `skin`, no `applySkin`, no `makeCloseButton` either, and that is a
    -- decision rather than an omission. The flat 1px black edge with its gray inner
    -- highlight, the gold title and the gray divider are now the NORMATIVE Ka0s
    -- window edge (standalone-windows, Core minor 3), and the × on a window the
    -- library draws is the library's — a host must not push its own onto them.
    -- The console therefore looks slightly different from the one this addon
    -- shipped, and that is the point: it now matches every other Ka0s console.
})

-- The global gated sink (debug-logging-§4), published under the name the addon's
-- existing call sites already use. Bound BARE rather than wrapped: it is a plain
-- function precisely so `NS.Debug("Set", "%s = %s", path, value)` keeps working.
NS.Debug = NS.DebugLog.Debug

-- Republished because the [Init] line is not the only reader: tests/test_debuglog.lua
-- asserts the summary's shape directly, and it is the one piece of the console's
-- content that is genuinely this addon's.
NS.DebugLog.SessionSummary = sessionSummary
