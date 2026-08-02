-- tests/test_libka0s.lua — the LibKa0s seams.
--
-- Unit coverage for what the library DOES lives in the library's own suite
-- (testing-§8); nothing here re-tests a formatter or a parser. What is pinned
-- here is the wiring this addon owns and nothing else can see:
--
--   * the descriptor is well-formed — the fields we pass are the ones we mean;
--   * every formatter that changed hands still renders the SAME BYTES;
--   * the degraded path, exercised by loading the addon with the library
--     genuinely ABSENT rather than by hand-stubbing the member under test;
--   * the `L` trap, in both halves — a rendered assertion where a module can
--     express it, and a tripwire on the library where it cannot.

local ctx = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local inst = ctx.loadAddon()
local NS   = inst.NS
local env  = inst.env

local function readFile(rel)
    local fh = io.open(ctx.root .. "/" .. rel, "r")
    if not fh then return nil end
    local body = fh:read("*a")
    fh:close()
    return body
end

-- Every file that hands a descriptor to a LibKa0s module. Listed rather than
-- globbed so a new seam is a deliberate addition to this list, not a silent one.
local SEAM_FILES = {
    "core/CoreSetup.lua",
}

-- ── the `L` trap: the matcher, and the matcher's own test ───────────────────
--
-- A descriptor field is not observable after `lib:New` returns, so the only way
-- to pin "we never handed a module the addon-wide locale table" is to read the
-- seam source. The obvious pattern is WRONG in two directions at once:
--
--   L = NS.L                       -- the table itself                       OFFENDER
--   L = NS.L or { ... }            -- NS.L is always truthy, so: the table   OFFENDER
--   L = NS.L and { ... } or nil    -- evaluates to the plain table           fine
--
-- An end-of-line-anchored `L = NS.L` misses the `or` spelling completely, and
-- never looks at the third line at all — which is the LEGITIMATE form, one
-- and/or typo away from being the live trap. So the rule is: flag any `L =`
-- whose value STARTS with the locale table, unless the next token is `and`.

local function localeTableOffenders(source)
    local hits = {}
    for line in (source or ""):gmatch("[^\r\n]+") do
        local rest = line:match("[,{%s]L%s*=%s*NS%.L(.*)$") or line:match("^L%s*=%s*NS%.L(.*)$")
        -- `NS.L[` / `NS.L.` is an INDEX into the table, not the table, so it is a
        -- value taken from the locale table and is fine.
        if rest and not rest:match("^[%[%.]") and not rest:match("^%s*and%f[%s]") then
            hits[#hits + 1] = line:match("^%s*(.-)%s*$")
        end
    end
    return hits
end

test("the locale-table matcher catches both offending spellings and clears the legal one", function()
    -- A matcher nothing tests can be narrowed back to a single anchored form while
    -- still reporting green, which is exactly how the anchored version got there.
    local offenders = localeTableOffenders(table.concat({
        '    L = NS.L,',
        '    L = NS.L or { LIST_HEADER = "x" },',
        '    L = NS.L and { LIST_HEADER = NS.L["Available settings"] } or nil,',
        '    L = { LIST_HEADER = NS.L["Available settings"] },',
    }, "\n"))
    t.eq(#offenders, 2, "exactly the two offending spellings are flagged")
    t.truthy(offenders[1]:find("L = NS.L,", 1, true), "the bare table is caught")
    t.truthy(offenders[2]:find("or {", 1, true), "the `or` spelling is caught too")
end)

test("no seam file hands a LibKa0s descriptor the addon-wide locale table", function()
    -- NS.L answers EVERY key with the key itself (the standard mandates the
    -- metatable fallback), so a descriptor holding it renders raw SCREAMING_SNAKE
    -- keys in place of English, for every key at once, visible only in game.
    for _, rel in ipairs(SEAM_FILES) do
        local src = readFile(rel)
        t.truthy(src, rel .. " is readable")
        local hits = localeTableOffenders(src)
        t.eq(#hits, 0, ("%s hands no descriptor NS.L (found: %s)")
            :format(rel, table.concat(hits, " | ")))
    end
end)

-- ── LibKa0s-Core-1.0 ───────────────────────────────────────────────────────

test("Core cannot express the L trap — the tripwire that stands in for a rendered case", function()
    -- Core ships no user-visible strings and reads no descriptor `L`, so a rendered
    -- assertion here would be a case that CANNOT FAIL — worse than no case, because
    -- it reads as coverage. This is the tripwire instead: it passes today and goes
    -- red the day Core grows either half, which is the moment a rendered assertion
    -- becomes both possible and necessary.
    local core = env.LibStub("LibKa0s-Core-1.0", true)
    t.truthy(core, "Core registered")
    t.nilv(core.STRINGS, "Core ships no STRINGS table")

    local src = readFile("libs/LibKa0s/Core.lua")
    t.truthy(src, "libs/LibKa0s/Core.lua is readable")
    t.falsy(src:find("STRINGS", 1, true), "Core.lua's source names no STRINGS table")
    t.falsy(src:find("d%.L%f[^%w_]"), "Core.lua reads no descriptor L")
end)

test("the secret-safe pair on NS.Util IS Core's, not a host copy beside it", function()
    -- Identity, not behaviour: two implementations that agree today are exactly the
    -- state the extraction exists to end, and only identity can see the difference.
    local core = env.LibStub("LibKa0s-Core-1.0", true)
    t.eq(NS.Util.SafeToString, core.SafeToString, "SafeToString is the library's function")
    t.eq(NS.Util.IsConcatSafe, core.IsConcatSafe, "IsConcatSafe is the library's function")
    t.eq(core.SECRET, "<secret>", "and the sentinel is the one the suite asserts on")
end)

test("the [PC] printer renders the same bytes it did before Core owned it", function()
    -- Const.PREFIX carries its own trailing space, so the descriptor passes sep = "".
    -- Without it every line would render with a double gap after the tag — a change
    -- nobody files a bug about and everybody sees.
    local msgs = env.DEFAULT_CHAT_FRAME.messages
    NS.Print("hello")
    t.eq(msgs[#msgs], NS.PREFIX .. "hello", "prefix, no separator of its own, then the body")
    t.falsy(msgs[#msgs]:find("|r  hello", 1, true), "specifically NOT a double space")

    NS.Print("")
    t.eq(msgs[#msgs], NS.PREFIX, "an empty body still emits the bare tag, as it always did")

    local secret = setmetatable({}, { __concat = function() error("secret") end })
    local ok = pcall(NS.Print, secret)
    t.truthy(ok, "a combat-protected value never reaches the chat frame raw")
    t.eq(msgs[#msgs], NS.PREFIX .. "<secret>", "it renders as the sentinel, in place")
end)

test("the printer is reclaimed from AceConsole's embed, not merely defined", function()
    -- NewAddon(NS, ...) stamps AceConsole's :Print over NS.Print. If core/CoreSetup.lua
    -- ever loads BEFORE core/PrettyChat.lua the embed wins and every line renders
    -- green with a trailing colon and no cyan tag.
    local msgs = env.DEFAULT_CHAT_FRAME.messages
    NS.Print("reclaimed")
    t.falsy(msgs[#msgs]:find("|cff33ff99", 1, true), "no AceConsole green")
    t.falsy(msgs[#msgs]:find("|r:", 1, true), "no AceConsole trailing colon")
    t.truthy(msgs[#msgs]:find("^" .. NS.PREFIX:gsub("([%|%[%]%(%)%.%%%+%-%*%?%^%$])", "%%%1")),
        "the cyan [PC] tag leads the line")
end)

-- ── the degraded install ───────────────────────────────────────────────────

test("with LibKa0s absent the addon still loads and still prints, saying so once", function()
    -- Loaded with the library genuinely missing from the file list, not hand-stubbed
    -- (testing-§8). Skipping Core.lua alone is the honest scenario: every other
    -- module returns before LibStub:NewLibrary when Core is absent, so one missing
    -- file takes the whole library out exactly as a broken vendor would.
    local bare = ctx.loadAddon({ skip = { "libs/LibKa0s/Core.lua" } })
    t.nilv(bare.env.LibStub("LibKa0s-Core-1.0", true), "Core did not register")
    for _, major in ipairs({ "LibKa0s-DebugLog-1.0", "LibKa0s-Slash-1.0",
                             "LibKa0s-Options-1.0", "LibKa0s-Perf-1.0" }) do
        t.nilv(bare.env.LibStub(major, true), major .. " is absent rather than half-wired")
    end

    local msgs = bare.env.DEFAULT_CHAT_FRAME.messages
    local before = #msgs
    bare.NS.Print("first line")
    t.eq(msgs[before + 1], bare.NS.PREFIX .. bare.NS.LIBKA0S_MISSING ..
        "; running on reduced built-in fallbacks.",
        "the notice rides the first line printed, in the shared cause clause's wording")
    t.eq(msgs[before + 2], bare.NS.PREFIX .. "first line", "and the line itself still lands")

    bare.NS.Print("second line")
    t.eq(#msgs, before + 3, "the notice is said once, not stapled to every line")
    t.eq(msgs[before + 3], bare.NS.PREFIX .. "second line", "the second line is just the line")
end)

test("the shared cause clause names the addon and where the library should be", function()
    -- A user with a broken install must see the same sentence about WHY from every
    -- Ka0s addon they have open; that is the whole reason the clause is shared.
    t.eq(NS.LIBKA0S_MISSING,
        "The LibKa0s library is missing from this installation of Ka0s Pretty Chat " ..
        "(expected in libs/LibKa0s)",
        "the clause is the collection's wording with this addon's name in it")
    t.falsy(NS.LIBKA0S_MISSING:find("%.$"), "it carries no terminal punctuation of its own")
end)

test("the degraded secret guard still neutralises a protected value", function()
    local bare = ctx.loadAddon({ skip = { "libs/LibKa0s/Core.lua" } })
    local secret = setmetatable({}, { __concat = function() error("secret") end })
    t.eq(bare.NS.Util.SafeToString(secret), "<secret>", "the fallback answers the same sentinel")
    t.falsy(bare.NS.Util.IsConcatSafe(secret), "and the fallback probe still refuses it")
end)
