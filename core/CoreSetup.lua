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

    -- Published on BOTH paths, not just the library one. Nothing calls it today,
    -- which is exactly why it would go unnoticed: the first caller added later
    -- would work in every install that has the library and be nil in the one this
    -- branch exists for.
    function NS.Format(fmt, ...)
        if select("#", ...) == 0 then return NS.Print(fmt) end
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = Util.SafeToString((select(i, ...))) end
        NS.Print(Util.SafeToString(fmt):format(unpack(parts)))
    end
    return
end

-- Published under the keys the addon already reads. Bound to the library's own
-- function objects rather than wrapped, so `NS.Util.SafeToString` and the value
-- the console's descriptor forwards to are provably the same implementation.
Util.IsConcatSafe = lib.IsConcatSafe
Util.SafeToString = lib.SafeToString

-- WRAPPED, TO SAY WHO IS ASKING — the one seam here that is not a direct bind.
-- LibKa0s draws this collection's own `close` mark when it is told which addon
-- folder to build a texture path from, and it cannot work that out for itself: the
-- library is vendored, so there is no one path to it and a copy cannot know which
-- folder it was copied into. `addonName` is that answer and this file has it as its
-- first vararg. Without it the library falls back to a multiplication sign, which is
-- what a degraded install should get and not what this one should.
--
-- TWO ARGUMENTS IN, THREE OUT, and the asymmetry is the whole point (anti-pattern
-- #64): the wrapper exists to supply the argument a caller cannot know. A
-- two-argument passthrough onto the three-argument target is a perfectly good button
-- with the wrong glyph — no error, no red suite, and the only witness is someone
-- looking at two windows side by side. It cost a sibling addon a release.
--
-- PrettyChat builds no window of its own today, so nothing calls this yet; the
-- console's close is LibKa0s' own and is told the folder name through
-- core/DebugLogSetup.lua's descriptor instead. This is the seam that keeps the NEXT
-- window this addon builds from having to remember the folder name at its call site.
NS.MakeCloseButton = function(parent, onClick)
    return lib.MakeCloseButton(parent, onClick, addonName)
end

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
