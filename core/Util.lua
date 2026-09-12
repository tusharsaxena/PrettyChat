local _, NS = ...

-- NS.Util — tiny pure string helpers shared by the slash dispatcher (settings/Slash.lua)
-- and any other module. Kept here so the color-wrap helpers have a single home instead
-- of being re-declared per file. Loads after Constants so NS.Const.Color exists.
--
-- The secret-safe pair that used to live here — IsConcatSafe and SafeToString — is now
-- LibKa0s-Core-1.0's, published onto this same table by core/CoreSetup.lua. Every
-- Ka0s addon carried its own copy and they had drifted (one probed with `..`, which
-- reports a combat secret as SAFE); one implementation is the whole point of the
-- extraction, so do not re-add them here (anti-pattern #47).
NS.Util = NS.Util or {}
local Util  = NS.Util
local Color = NS.Const.Color

-- Trim leading/trailing whitespace; nil-safe.
-- The WHOLE call is parenthesized so gsub's second return — the substitution
-- count — is truncated away. Unparenthesized, `trim(x)` is a two-value
-- expression and any caller that passes it straight into another call silently
-- appends an integer argument (PC-R-10).
function Util.trim(s)
    return ((s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- note() — white body text (slash help descriptions, notices).
function Util.note(s)
    return Color.white .. s .. Color.reset
end

-- cmd() — gold command text (slash-commands-§4: `/pc <verb>` renders gold).
function Util.cmd(s)
    return Color.yellow .. s .. Color.reset
end

-- The marker a bulk act's one debug line carries when the act raised partway
-- (debug-logging-§10): the line still counts the rows changed before it stopped.
Util.STOPPED = " (stopped by an error)"

-- xpcall's message handler. It runs at the raise, before the stack unwinds, so
-- the stack it appends is the ORIGINAL one; a pcall + error(err, 0) keeps only the
-- message, and the report then points at the re-raise. The client reads its stack
-- with debugstack and has no `debug` library; the harness is plain Lua 5.1.
local function withStack(err)
    if type(err) ~= "string" then return err end
    local stack = (debugstack and debugstack(2))
        or (debug and debug.traceback and debug.traceback("", 2))
    return stack and (err .. "\n" .. stack) or err
end

-- Run one bulk act. If fn raises, onRaise() runs first (it writes the act's one
-- line, ending in Util.STOPPED) and the error is raised again, carrying the stack
-- of the original raise. fn takes no arguments: Lua 5.1's xpcall passes none.
function Util.RunAct(fn, onRaise)
    local ok, err = xpcall(fn, withStack)
    if ok then return end
    onRaise()
    error(err, 0)
end
