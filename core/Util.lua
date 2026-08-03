local addonName, NS = ...

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
function Util.trim(s)
    return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

-- note() — white body text (slash help descriptions, notices).
function Util.note(s)
    return Color.white .. s .. Color.reset
end

-- cmd() — gold command text (slash-commands-§4: `/pc <verb>` renders gold).
function Util.cmd(s)
    return Color.yellow .. s .. Color.reset
end
