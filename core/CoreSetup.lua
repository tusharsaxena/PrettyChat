local addonName, NS = ...

-- core/CoreSetup.lua — wires the addon into LibKa0s-Core-1.0.
--
-- The secret-value guard, the concat-safe stringifier and the prefixed [PC] chat
-- printer used to live in core/Util.lua and core/PrettyChat.lua. They are the same
-- three things in every Ka0s addon — and were subtly different in several of them —
-- so they now live in libs/LibKa0s/Core.lua and this file is only the part that is
-- ours: which tag the lines carry, and what happens when the library is not there.
--
-- ── Why this TOC slot ───────────────────────────────────────────────────────
--
-- Two constraints bind, and they bracket this file from both sides:
--
--   * it MUST load AFTER core/PrettyChat.lua. That file passes NS to
--     AceAddon:NewAddon (architecture-§2), so AceConsole-3.0 embeds its own
--     `:Print` onto the namespace and clobbers the cyan printer. The reclaim is
--     the assignment at the bottom of this file, and a seam that ran first would
--     be silently overwritten by the embed (anti-pattern #36);
--   * it MUST load BEFORE the first load-time NS.Print call, which is
--     settings/Schema.lua's unresolved-path report.
--
-- Nothing in this addon takes the printer as a file-scope upvalue — verified with
-- `grep -n "local print"` across the repo, which finds nothing — so the window
-- between those two is wide and this file sits at the near end of it, right
-- behind the clobber it exists to undo.

-- The one cause clause, shared by every seam that has to explain the same absence:
-- this file, core/DebugLogSetup.lua, settings/OptionsSetup.lua and
-- settings/Slash.lua. Each appends its own "so <what> is unavailable" and its own
-- terminal punctuation, so a degraded install says the same thing about WHY at
-- every site and a different thing about WHAT at each one. Set OUTSIDE the branch
-- below, because the later seams read it on both paths, and set HERE because
-- core/CoreSetup.lua is the first of the four the TOC loads.
NS.LIBKA0S_MISSING = "The LibKa0s library is missing from this installation of Ka0s Pretty Chat " ..
    "(expected in libs/LibKa0s)"

NS.Util = NS.Util or {}
local Util = NS.Util

local lib = LibStub and LibStub("LibKa0s-Core-1.0", true)

if not lib then
    -- A missing vendored lib must degrade, not error at load. Silence is not an
    -- option for this one the way it is for a diagnostics harness: every module in
    -- the addon prints through NS.Print, and ~57 call sites answering nil would take
    -- the whole slash surface down. So the fallbacks work — they are the
    -- pre-library implementations, kept short — and the honest "it is not installed"
    -- line is said ONCE, on the first line the addon prints, rather than stapled to
    -- every one of them.
    local function probeConcat(v) return table.concat({ v }) end
    function Util.IsConcatSafe(v)
        return (pcall(probeConcat, v)) and true or false
    end

    function Util.SafeToString(v)
        if v == nil then return "nil" end
        if type(v) == "boolean" then return tostring(v) end
        if Util.IsConcatSafe(v) then return tostring(v) end
        return "<secret>"
    end

    local announced = false
    function NS.Print(msg)
        if not DEFAULT_CHAT_FRAME then return end
        if not announced then
            announced = true
            DEFAULT_CHAT_FRAME:AddMessage(NS.PREFIX ..
                NS.LIBKA0S_MISSING .. "; running on reduced built-in fallbacks.")
        end
        DEFAULT_CHAT_FRAME:AddMessage(NS.PREFIX .. Util.SafeToString(msg))
    end
    return
end

-- Published under the keys the addon already reads. Bound to the library's own
-- function objects rather than wrapped, so `NS.Util.SafeToString` and the value
-- the console's descriptor forwards to are provably the same implementation.
Util.IsConcatSafe = lib.IsConcatSafe
Util.SafeToString = lib.SafeToString

-- `sep = ""` because Const.PREFIX already carries its own trailing space. Without
-- it every line would render "[PC]  message" with a double gap — a change nobody
-- would file a bug about and everybody would see.
--
-- The prefix is passed as a FUNCTION rather than as the value of NS.PREFIX. It
-- reads the same here, where core/Constants.lua has long since run, but the printer
-- is built once at load and the function form is what keeps a later change to
-- NS.PREFIX from being frozen out.
local printer = lib:New({
    prefix = function() return NS.PREFIX end,
    sep    = "",
})

-- The reclaim (anti-pattern #36). AceConsole's embed landed on NS.Print during
-- core/PrettyChat.lua's NewAddon call; this is the line that takes the name back,
-- and it is why this file sits where it does in the TOC.
NS.Print  = printer.Print
NS.Format = printer.Format
