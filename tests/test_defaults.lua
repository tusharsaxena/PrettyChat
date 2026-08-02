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

test("the schema builds exactly the rows the defaults imply", function()
    -- 1 addon-wide row + 1 row per backed category + 2 rows per string
    -- registration. Any drift means Schema and Defaults disagree.
    local backedCategories = 0
    for _, c in ipairs(ORDER) do
        if NS.Defaults[c] then backedCategories = backedCategories + 1 end
    end
    local expected = 1 + backedCategories + (#entries * 2)

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
