-- tests/test_defaults.lua — integrity of defaults/Defaults.lua, the addon's
-- bulk reference data (every category, every Blizzard GLOBALNAME, every
-- replacement format string). Nothing here re-states the data; each case is a
-- shape/consistency invariant that a hand-edit to the ~170-entry table could
-- silently break — a missing label, a lower-cased global name, a format
-- string whose conversions don't render, or drift between the defaults and
-- the schema built on top of them.

local ctx = _G.PC_TEST
local t      = ctx.t
local test   = ctx.test
local inst   = ctx.loadAddon()
local NS     = inst.NS
local Schema = NS.Schema

local ORDER = Schema.CATEGORY_ORDER

local function inOrder(name)
    for _, c in ipairs(ORDER) do
        if c == name then return true end
    end
    return false
end

-- Flat { category, globalName, strData } list over the whole table.
local entries = {}
for category, catData in pairs(NS.Defaults) do
    for globalName, strData in pairs(catData.strings or {}) do
        entries[#entries + 1] = { category, globalName, strData }
    end
end

test("the defaults table is non-empty and carries real entries", function()
    t.truthy(next(NS.Defaults) ~= nil, "NS.Defaults is populated")
    t.truthy(#entries > 50, "the reference data carries the full string surface")
end)

test("every defaults category appears in CATEGORY_ORDER", function()
    for category in pairs(NS.Defaults) do
        t.truthy(inOrder(category),
            ("category %q is listed in CATEGORY_ORDER"):format(category))
    end
end)

test("every ordered category except the virtual General has backing data", function()
    for _, category in ipairs(ORDER) do
        if category == "General" then
            t.nilv(NS.Defaults[category], "General is virtual — no defaults entry")
        else
            t.truthy(NS.Defaults[category],
                ("ordered category %q has a defaults entry"):format(category))
        end
    end
end)

test("CATEGORY_ORDER lists General first and has no duplicates", function()
    t.eq(ORDER[1], "General", "General sorts to the top of the addon list")
    local seen = {}
    for _, c in ipairs(ORDER) do
        t.falsy(seen[c], ("category %q appears once"):format(c))
        seen[c] = true
    end
end)

test("every category declares a boolean enabled flag and a strings table", function()
    for category, catData in pairs(NS.Defaults) do
        t.eq(type(catData.enabled), "boolean",
            ("%s.enabled is a boolean"):format(category))
        t.eq(type(catData.strings), "table",
            ("%s.strings is a table"):format(category))
        t.truthy(next(catData.strings) ~= nil,
            ("%s registers at least one string"):format(category))
    end
end)

test("every key is a Blizzard-style UPPERCASE global name", function()
    for _, e in ipairs(entries) do
        local globalName = e[2]
        t.truthy(globalName:match("^%u[%u%d_]*$") ~= nil,
            ("%q is an UPPERCASE_GLOBAL_NAME"):format(globalName))
    end
end)

test("every entry carries a non-empty label and default", function()
    for _, e in ipairs(entries) do
        local category, globalName, strData = e[1], e[2], e[3]
        local where = category .. "." .. globalName
        t.eq(type(strData.label), "string", where .. " has a string label")
        t.truthy((strData.label or "") ~= "", where .. " label is non-empty")
        t.eq(type(strData.default), "string", where .. " has a string default")
        t.truthy((strData.default or "") ~= "", where .. " default is non-empty")
    end
end)

test("labels are unique within their category", function()
    local byCategory = {}
    for _, e in ipairs(entries) do
        local category, globalName, strData = e[1], e[2], e[3]
        byCategory[category] = byCategory[category] or {}
        local clash = byCategory[category][strData.label]
        t.falsy(clash, ("%s: label %q is not reused (clashes with %s)")
            :format(category, strData.label, tostring(clash)))
        byCategory[category][strData.label] = globalName
    end
end)

test("every default format string renders with sample arguments", function()
    -- A default whose conversions can't be filled would show as an error
    -- line in the panel preview and in /pc test for every user.
    for _, e in ipairs(entries) do
        local rendered, err = NS.RenderSample(e[3].default)
        t.truthy(rendered, ("%s.%s renders (%s)"):format(e[1], e[2], tostring(err)))
    end
end)

-- ---------------------------------------------------------------------
-- The positional-prefix rule (PC-R-01 / PC-R-02, testing-§12).
--
-- The case ABOVE renders each default against arguments synthesized FROM THAT
-- SAME STRING, so it can only ever agree with itself: a default asking for
-- `%s %d` gets a string and a number and renders happily, whatever Blizzard
-- actually passes at that call site. That is why it stayed green while
-- FACTION_STANDING_DECREASED_GENERIC asked for an argument the game never sends
-- and FACTION_STANDING_INCREASED_GUARDIAN put the guardian's NAME into `%d`.
-- Both raised in a live client, for every user, on a routine reputation gain.
--
-- The check below compares against the SHIPPED BLIZZARD SIGNATURE in
-- GlobalStrings/ instead — the same 22,879-entry dump the settings panel reads
-- to show the "Original" box — so the arguments are the ones the game really
-- hands over.
--
-- THE RULE IS A PREFIX, NOT AN EQUALITY. Lua's string.format ignores surplus
-- arguments: string.format("a %s", "x", "extra") is "a x". So an override may
-- stop early and drop trailing conversions it does not want to display, and
-- that is safe. What is never safe is asking for MORE than Blizzard passes (the
-- missing argument raises) or asking for a DIFFERENT TYPE at a position (a name
-- into %d raises). Written to equality this case is red on six rows on the day
-- it lands; four of those six are deliberate:
--
--   LOOT_DISENCHANT_CREDIT   [s]    of Blizzard's [s,s]
--   COMBATLOG_DISHONORGAIN   []     of Blizzard's [s]
--   OPEN_LOCK_OTHER          [s,s]  of Blizzard's [s,s,s]
--   OPEN_LOCK_SELF           [s]    of Blizzard's [s,s]
--
-- THESE FOUR ARE SANCTIONED AND MUST NOT BE "FIXED". They are named in
-- SANCTIONED_TRUNCATIONS below and the case asserts the set is exactly those
-- four, in both directions: a NEW truncation is red (it wants a decision), and
-- lengthening one of these four back to Blizzard's full list is also red —
-- harmless in itself, but it means this register is stale and the name should
-- be removed from it in the same change.
-- ---------------------------------------------------------------------

local SANCTIONED_TRUNCATIONS = {
    LOOT_DISENCHANT_CREDIT = "shows the item only; Blizzard's second %s is the disenchanter",
    COMBATLOG_DISHONORGAIN = "shows the tag only; Blizzard's %s is the dishonored unit",
    OPEN_LOCK_OTHER        = "shows opener + object; Blizzard's third %s is the key used",
    OPEN_LOCK_SELF         = "shows the object only; Blizzard's second %s is the key used",
}

-- Conversion type -> the class an argument must belong to. Only the class
-- matters: %d and %x both need a number, and swapping one for the other cannot
-- raise. `s` versus `int` is what raises.
local CONVERSION_CLASS = {
    s = "string",
    d = "int", i = "int", u = "int", x = "int", X = "int", o = "int", c = "int",
    f = "float", g = "float", e = "float", G = "float", E = "float",
}

-- The ordered conversion sequence of a format string, honoring WoW's positional
-- `%n$type` form. Same walk as buildSampleArgs in modules/Override.lua: strip
-- `%%` escapes first, then read [flags][width][.precision]type. A positional
-- specifier lands at its index; a gap left by `%3$s` with no `%1$`/`%2$` is
-- recorded as "gap" so it can never silently match Blizzard's real type.
local function conversionSequence(fmt)
    local clean = fmt:gsub("%%%%", "")
    local seq, appendIdx, maxIdx = {}, 0, 0
    for posCap, ftype in clean:gmatch("%%(%d*%$?)[%-+ #0]*%d*%.?%d*([%a])") do
        local class = CONVERSION_CLASS[ftype] or ("unknown:" .. ftype)
        if posCap:sub(-1) == "$" then
            local idx = tonumber(posCap:sub(1, -2))
            if idx and idx > 0 then
                seq[idx] = class
                if idx > maxIdx then maxIdx = idx end
            end
        else
            appendIdx = appendIdx + 1
            seq[appendIdx] = class
            if appendIdx > maxIdx then maxIdx = appendIdx end
        end
    end
    for i = 1, maxIdx do seq[i] = seq[i] or "gap" end
    seq.n = maxIdx
    return seq
end

local function showSequence(seq)
    local parts = {}
    for i = 1, seq.n do parts[i] = seq[i] end
    return "[" .. table.concat(parts, ",") .. "]"
end

-- The shipped Blizzard signatures, loaded HERE and directly rather than read off
-- the namespace. PrettyChat.toc no longer carries the GlobalStrings/ chunks
-- (PC-R-05): after PC-R-04 the panel reads this client's OnEnable snapshot, so
-- the client was parsing 1.89 MB at every login to serve zero lookups. The
-- chunks stay in the repo as the reference data THIS case compares against, and
-- .pkgmeta keeps them out of the shipped zip. Loading them here is what makes
-- that split honest: the data is a test fixture now, and the file that needs it
-- is the file that loads it.
local function loadShippedGlobalStrings()
    local box, n = {}, 0
    while true do
        local chunk = loadfile(("%s/GlobalStrings/GlobalStrings_%03d.lua"):format(ctx.root, n + 1))
        if not chunk then break end
        n = n + 1
        chunk("PrettyChat", box)
    end
    return box.GlobalStrings, n
end

test("every default's conversion sequence is a positional prefix of Blizzard's", function()
    local shipped, chunkCount = loadShippedGlobalStrings()
    -- Guards on the guard: a fixture that failed to load would make every
    -- comparison below vacuous, and the first assertion in the loop the only
    -- thing left standing.
    t.truthy(chunkCount > 20, ("the GlobalStrings/ chunks loaded (%d found)"):format(chunkCount))
    t.truthy(shipped, "the chunks populated a reference table")
    t.nilv(NS.GlobalStrings, "and the addon itself no longer loads that table (PC-R-05)")

    local truncated = {}
    for _, e in ipairs(entries) do
        local category, globalName, strData = e[1], e[2], e[3]
        local blizzard = shipped and shipped[globalName]

        -- A default overriding a global the dump has never heard of cannot be
        -- checked at all, which is a worse state than a mismatch.
        t.truthy(type(blizzard) == "string",
            ("%s.%s has a shipped Blizzard original to compare against"):format(category, globalName))

        if type(blizzard) == "string" then
            local ovr  = conversionSequence(strData.default)
            local blz  = conversionSequence(blizzard)

            t.truthy(ovr.n <= blz.n, ("%s.%s asks for %d conversions but Blizzard passes %d — %s vs %s; the surplus has no argument and string.format raises")
                :format(category, globalName, ovr.n, blz.n, showSequence(ovr), showSequence(blz)))

            for i = 1, math.min(ovr.n, blz.n) do
                t.eq(ovr[i], blz[i], ("%s.%s conversion #%d takes a %s but Blizzard passes a %s (%s vs %s)")
                    :format(category, globalName, i, tostring(ovr[i]), tostring(blz[i]),
                            showSequence(ovr), showSequence(blz)))
            end

            if ovr.n < blz.n then
                truncated[globalName] = true
                t.truthy(SANCTIONED_TRUNCATIONS[globalName],
                    ("%s.%s stops at %d of Blizzard's %d conversions. Dropping trailing arguments is SAFE — string.format ignores surplus — but an unlisted truncation is an undecided one: either restore the conversions or add the key to SANCTIONED_TRUNCATIONS with the reason")
                        :format(category, globalName, ovr.n, blz.n))
            end
        end
    end

    -- The other direction: the register must not outlive the truncations.
    for globalName in pairs(SANCTIONED_TRUNCATIONS) do
        t.truthy(truncated[globalName],
            ("%s is listed in SANCTIONED_TRUNCATIONS but its default no longer truncates — drop the entry in the same change that lengthened it")
                :format(globalName))
    end
end)

test("no default carries a raw newline or tab", function()
    for _, e in ipairs(entries) do
        t.falsy(e[3].default:find("[\n\t]"),
            ("%s.%s has no raw newline/tab"):format(e[1], e[2]))
    end
end)

test("cross-registered globals are identified with their real categories", function()
    local shared = Schema.crossRegisteredGlobals
    t.truthy(shared, "the cross-registration map is published")
    for globalName, cats in pairs(shared) do
        t.truthy(#cats > 1, globalName .. " is listed only because it is shared")
        for _, c in ipairs(cats) do
            t.truthy(NS.Defaults[c] and NS.Defaults[c].strings[globalName],
                ("%s really is registered under %s"):format(globalName, c))
        end
    end
end)

-- The composed Master controls block, which is the whole of the General page:
-- Enable PrettyChat, General visibility, Debug console. Written out as a number
-- because it is what the defaults table CANNOT imply — those three rows are
-- LibKa0s-Options-1.0's canonical block rather than this addon's data
-- (options-ui-§15), and the frameless omission of master scale, master alpha and
-- lock frame is what makes it three rather than six.
local MASTER_ROWS = 3

test("the schema builds exactly the rows the defaults imply", function()
    -- the Master controls block + 1 row per backed category + 2 rows per string
    -- registration. Any drift means Schema and Defaults disagree.
    local backedCategories = 0
    for _, c in ipairs(ORDER) do
        if NS.Defaults[c] then backedCategories = backedCategories + 1 end
    end
    local expected = MASTER_ROWS + backedCategories + (#entries * 2)

    local actual = 0
    for _, c in ipairs(ORDER) do
        actual = actual + #Schema.RowsByCategory(c)
    end
    t.eq(actual, expected, "schema row count matches the defaults surface")
    t.eq(Schema.validation.checked, expected, "the load-time validator saw every row")
end)

test("every string registration has both of its schema rows", function()
    for _, e in ipairs(entries) do
        local base = e[1] .. "." .. e[2]
        t.truthy(Schema.FindByPath(base .. ".enabled"), base .. ".enabled row exists")
        t.truthy(Schema.FindByPath(base .. ".format"), base .. ".format row exists")
    end
end)

test("each format row's schema default is the defaults-table default", function()
    for _, e in ipairs(entries) do
        local row = Schema.FindByPath(e[1] .. "." .. e[2] .. ".format")
        t.eq(row.default, e[3].default,
            ("%s.%s format row carries the defaults value"):format(e[1], e[2]))
    end
end)
