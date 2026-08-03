-- tests/test_util.lua — NS.Util secret-safe output helpers (events-frames-taint-§8).
-- A Blizzard combat "secret" raises when it hits `..` / string.format, so the shared
-- printer and debug sink route values through these: IsConcatSafe probes with
-- table.concat (never `..`, which would itself raise on a secret); SafeToString
-- returns a display string, substituting "<secret>" for anything the probe rejects.

local ctx = _G.PC_TEST
local t    = ctx.t
local test = ctx.test
local NS   = ctx.loadAddon().NS
local U    = NS.Util

test("SafeToString renders scalars and nil verbatim", function()
    t.eq(U.SafeToString("hi"),  "hi",    "string passes through")
    t.eq(U.SafeToString(42),    "42",    "number stringifies")
    t.eq(U.SafeToString(true),  "true",  "boolean true")
    t.eq(U.SafeToString(false), "false", "boolean false")
    t.eq(U.SafeToString(nil),   "nil",   "nil renders as the word nil")
end)

test("SafeToString substitutes <secret> for a value table.concat rejects", function()
    -- Stand-in for a combat "secret": a table whose use in a `..` / table.concat
    -- chain raises. SafeToString must neither throw nor leak the value.
    local secret = setmetatable({}, { __concat = function() error("secret") end })
    local ok, res = pcall(U.SafeToString, secret)
    t.truthy(ok, "SafeToString never raises on an unconcatenable value")
    t.eq(res, "<secret>", "unconcatenable value renders as <secret>")
end)

test("IsConcatSafe probes concatenability via table.concat, not ..", function()
    t.truthy(U.IsConcatSafe("s"), "strings are concat-safe")
    t.truthy(U.IsConcatSafe(7),   "numbers are concat-safe")
    t.falsy(U.IsConcatSafe(true), "booleans are not directly concat-safe")
    t.falsy(U.IsConcatSafe({}),   "tables are not concat-safe")
end)

test("IsConcatSafe never raises on the value it is probing", function()
    -- The whole point of probing with table.concat: `..` would itself raise.
    local secret = setmetatable({}, { __concat = function() error("secret") end })
    local ok, res = pcall(U.IsConcatSafe, secret)
    t.truthy(ok, "the probe absorbs the raise")
    t.eq(res, false, "and answers false")
    -- nil probes as safe ({nil} is an empty table, which concatenates
    -- fine); SafeToString short-circuits nil before it ever probes.
    t.truthy(U.IsConcatSafe(nil), "nil passes the probe")
    t.eq(U.SafeToString(nil), "nil", "but SafeToString handles it before probing")
end)

test("trim strips surrounding whitespace and is nil-safe", function()
    t.eq(U.trim("  padded  "), "padded", "both ends")
    t.eq(U.trim("lead   "),    "lead",   "trailing only")
    t.eq(U.trim("   trail"),   "trail",  "leading only")
    t.eq(U.trim("tight"),      "tight",  "nothing to strip")
    t.eq(U.trim("\t mixed \t"), "mixed", "tabs count as whitespace")
    t.eq(U.trim("   "),        "",       "whitespace-only collapses to empty")
    t.eq(U.trim(""),           "",       "empty stays empty")
    t.eq(U.trim(nil),          "",       "nil is treated as empty, not an error")
end)

test("trim keeps interior whitespace intact", function()
    -- Slash arguments (`/pc set <path> <value>`) carry meaningful spaces.
    t.eq(U.trim("  a  b  "), "a  b", "only the ends are touched")
end)

test("note and cmd wrap text in the documented slash colors", function()
    local Color = NS.Const.Color
    t.eq(U.note("body"), Color.white .. "body" .. Color.reset,
        "note() renders body text white")
    t.eq(U.cmd("/pc help"), Color.yellow .. "/pc help" .. Color.reset,
        "cmd() renders command text in the schema-path yellow (slash-commands-§4)")
    t.eq(U.note(""), Color.white .. Color.reset, "an empty string still terminates its color")
end)
