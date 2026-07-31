-- tests/test_slash.lua — settings/Slash.lua. Two things are under test: the
-- dispatcher itself (verb lookup, case handling, usage/error paths for every
-- verb) and slash-commands-§5 output conformance — the shared schema-driven
-- value formatter, the FormatKV gold/white `get` echo, and the green-header /
-- azure-group `list` colours. Most cases drive the real `/pc` entry point so
-- the COMMANDS table and the dispatcher are exercised together.

local function run(NS, addon, name, rest)
    for _, e in ipairs(NS.COMMANDS) do
        if e[1] == name then return e[3](addon, rest or "") end
    end
    error("no '" .. name .. "' command in NS.COMMANDS")
end

local function last(env) return env.DEFAULT_CHAT_FRAME.messages[#env.DEFAULT_CHAT_FRAME.messages] end
local function has(env, needle)
    for _, m in ipairs(env.DEFAULT_CHAT_FRAME.messages) do
        if m:find(needle, 1, true) then return true end
    end
    return false
end

return function(ctx)
    local t     = ctx.t
    local test  = ctx.test
    local inst  = ctx.loadAddon()
    local NS    = inst.NS
    local addon = inst.addon
    local env   = inst.env
    local C      = NS.Const.Color
    local PREFIX = NS.PREFIX
    local Schema = NS.Schema

    -- Drive the real entry point, and return only the lines it emitted.
    local function slash(input)
        local from = #env.DEFAULT_CHAT_FRAME.messages
        addon:OnSlashCommand(input)
        local out = {}
        for i = from + 1, #env.DEFAULT_CHAT_FRAME.messages do
            out[#out + 1] = env.DEFAULT_CHAT_FRAME.messages[i]
        end
        return out
    end

    local function joined(input) return table.concat(slash(input), "\n") end

    local formatPath = "Loot.LOOT_ITEM_SELF.format"
    local formatRow  = Schema.FindByPath(formatPath)

    -- ---- the shared value formatter ------------------------------------

    test("Schema.FormatValue formats bools and doubles pipes in strings", function()
        -- bool → true/false; string → the raw format with `|` doubled.
        local boolRow = Schema.FindByPath("General.enabled")
        t.eq(Schema.FormatValue(boolRow, true),  "true",  "bool true formats as `true`")
        t.eq(Schema.FormatValue(boolRow, false), "false", "bool false formats as `false`")
        t.eq(Schema.FormatValue({ type = "string" }, "|cffff0000%s|r"),
            "||cffff0000%s||r", "string value doubles pipes so colour escapes show as text")
    end)

    test("NS.Print emits the cyan [PC] tag (reclaimed after the AceConsole embed)", function()
        -- architecture-§2 / anti-pattern #36: NewAddon is passed the NS table, so
        -- AceConsole's :Print embed lands on NS and would clobber the cyan printer.
        -- core/PrettyChat.lua reclaims NS.Print right after registration — assert it
        -- still prepends the [PC] PREFIX, not AceConsole's |cff33ff99Name|r: tag.
        NS.Print("hello")
        local line = last(env)
        t.eq(line, PREFIX .. "hello", "NS.Print prepends the cyan [PC] prefix")
        t.falsy(line:find("|cff33ff99", 1, true), "AceConsole's embed did not win")
    end)

    -- ---- dispatch -------------------------------------------------------

    test("a bare /pc prints the help index", function()
        local out = slash("")
        t.truthy(#out > #NS.COMMANDS, "help emits a header plus one line per command")
        t.truthy(out[1]:find("slash commands", 1, true), "the header names the surface")
    end)

    test("/pc help lists every command with its description", function()
        local text = joined("help")
        for _, entry in ipairs(NS.COMMANDS) do
            t.truthy(text:find("/pc " .. entry[1], 1, true),
                ("help lists /pc %s"):format(entry[1]))
            t.truthy(text:find(entry[2], 1, true),
                ("help carries the description for /pc %s"):format(entry[1]))
        end
        t.truthy(text:find("/prettychat", 1, true), "help documents the alias")
    end)

    test("an unknown verb says so and then prints the help index", function()
        local out = slash("nonsense")
        t.truthy(out[1]:find("unknown command 'nonsense'", 1, true), "the verb is echoed back")
        t.truthy(#out > #NS.COMMANDS, "and the help index follows")
    end)

    test("the verb is lower-cased but the argument keeps its case", function()
        -- Dot paths like Loot.LOOT_ITEM_SELF.format must survive intact.
        local text = joined("GET " .. formatPath)
        t.truthy(text:find(formatPath, 1, true), "the mixed-case path resolved")
        t.falsy(text:find("setting not found", 1, true), "the verb matched despite its casing")
    end)

    test("extra whitespace around the verb is tolerated", function()
        local text = joined("   version   ")
        t.truthy(text:find("v" .. ctx.mock.metadata.Version, 1, true), "the padded verb dispatched")
    end)

    test("/pc version prints the tagged version line", function()
        run(NS, addon, "version")
        t.eq(last(env), PREFIX .. "v" .. ctx.mock.metadata.Version,
            "/pc version prints the tagged version line")
    end)

    test("/pc config routes to the combat-gated panel opener", function()
        local opens = #env._settings.opened
        slash("config")
        t.eq(#env._settings.opened, opens + 1, "the Settings panel was asked to open")
    end)

    -- ---- get ------------------------------------------------------------

    test("/pc get echoes the gold-key/white-value FormatKV line", function()
        run(NS, addon, "get", "General.enabled")
        t.eq(last(env),
            PREFIX .. C.yellow .. "General.enabled" .. C.reset .. " = " .. C.white .. "true" .. C.reset,
            "/pc get echoes the gold-key/white-value FormatKV line")
    end)

    test("/pc get with no path prints usage", function()
        t.truthy(joined("get"):find("usage: ", 1, true), "the usage line is printed")
    end)

    test("/pc get on an unknown path reports it as not found", function()
        t.truthy(joined("get Nope.nope"):find("setting not found: 'Nope.nope'", 1, true),
            "the unknown path is echoed back")
    end)

    test("/pc get doubles the pipes in a format string so escapes read as text", function()
        local text = joined("get " .. formatPath)
        t.truthy(text:find((formatRow.default:gsub("|", "||")), 1, true),
            "the echoed value is the pipe-doubled format")
    end)

    -- ---- set ------------------------------------------------------------

    test("/pc set accepts every documented truthy bool spelling", function()
        for _, word in ipairs({ "true", "1", "on", "yes", "TRUE", "On" }) do
            Schema.Set("General.enabled", false)
            slash("set General.enabled " .. word)
            t.eq(Schema.Get("General.enabled"), true, ("%q sets the bool true"):format(word))
        end
    end)

    test("/pc set accepts every documented falsy bool spelling", function()
        for _, word in ipairs({ "false", "0", "off", "no", "FALSE", "Off" }) do
            Schema.Set("General.enabled", true)
            slash("set General.enabled " .. word)
            t.eq(Schema.Get("General.enabled"), false, ("%q sets the bool false"):format(word))
        end
        Schema.Set("General.enabled", true)
    end)

    test("/pc set rejects an unparseable bool without touching the value", function()
        Schema.Set("General.enabled", true)
        local text = joined("set General.enabled maybe")
        t.truthy(text:find("invalid bool 'maybe'", 1, true), "the bad word is echoed back")
        t.truthy(text:find("expected true/false/on/off/1/0/yes/no", 1, true),
            "the accepted spellings are listed")
        t.eq(Schema.Get("General.enabled"), true, "the stored value is unchanged")
    end)

    test("/pc set stores a format string and echoes the stored value", function()
        local out = slash("set " .. formatPath .. " CUSTOM %s here")
        t.eq(Schema.Get(formatPath), "CUSTOM %s here", "the whole remainder is the value")
        t.eq(out[#out],
            PREFIX .. C.yellow .. formatPath .. C.reset .. " = " .. C.white .. "CUSTOM %s here" .. C.reset,
            "the echo is a FormatKV line reading back from the DB")
    end)

    test("/pc set echoes the value the DB actually kept, not the input", function()
        -- Setting a format back to its default clears the override; the echo is
        -- read back after the write so any coercion shows.
        slash("set " .. formatPath .. " " .. formatRow.default)
        local catDB = addon.db.profile.categories["Loot"]
        t.falsy(catDB and catDB.strings and catDB.strings["LOOT_ITEM_SELF"],
            "writing the default cleared the stored override")
        t.truthy(last(env):find((formatRow.default:gsub("|", "||")), 1, true),
            "and the echo still shows the effective value")
    end)

    test("/pc set with no path, and with no value, both print usage", function()
        t.truthy(joined("set"):find("usage: ", 1, true), "no path prints usage")
        local text = joined("set " .. formatPath)
        t.truthy(text:find("usage: ", 1, true), "a string row with no value prints usage")
        t.truthy(text:find(formatPath, 1, true), "and the usage names the path")
    end)

    test("/pc set on an unknown path reports it as not found", function()
        t.truthy(joined("set Nope.nope true"):find("setting not found", 1, true),
            "an unknown path is rejected before any write")
    end)

    -- ---- list -----------------------------------------------------------

    test("/pc list prints the green header and azure category groups", function()
        run(NS, addon, "list", "")
        t.truthy(has(env, C.listHead .. "Available settings" .. C.reset),
            "/pc list prints the green Available settings header")
        t.truthy(has(env, C.azure .. "[General]" .. C.reset),
            "/pc list prints azure [category] group headers")
    end)

    test("/pc list emits every schema row exactly once", function()
        local out = slash("list")
        local expected = 1                                  -- the header
        for _, category in ipairs(Schema.CATEGORY_ORDER) do
            expected = expected + 1 + #Schema.RowsByCategory(category)  -- group + rows
        end
        t.eq(#out, expected, "header + one group header and row set per category")
    end)

    test("/pc list category lists the category names alphabetically", function()
        local out = slash("list category")
        t.truthy(out[1]:find(("Categories (%d)"):format(#Schema.CATEGORY_ORDER), 1, true),
            "the header counts the categories")
        local names = {}
        for i = 2, #out do names[#names + 1] = (out[i]:gsub("^.*%s", "")) end
        for i = 2, #names do
            t.truthy(names[i - 1] < names[i], "the listing is alphabetical")
        end
    end)

    test("/pc list formatstring lists every Category.GLOBALNAME pair", function()
        local out = slash("list formatstring")
        local total = 0
        for _, catData in pairs(NS.Defaults) do
            for _ in pairs(catData.strings) do total = total + 1 end
        end
        t.truthy(out[1]:find(("Format strings (%d)"):format(total), 1, true),
            "the header counts every registration, including cross-registered ones")
        t.eq(#out, total + 1, "one line per registration under the header")
        t.truthy(out[2]:find("Currency.", 1, true),
            "the listing is sorted by category then global name")
    end)

    test("/pc list <Category> narrows to that category's rows", function()
        local out = slash("list Loot")
        t.eq(#out, 1 + #Schema.RowsByCategory("Loot"), "group header plus that category's rows")
        t.truthy(out[1]:find(C.azure .. "[Loot]" .. C.reset, 1, true), "the azure group header")
    end)

    test("/pc list resolves a category case-insensitively and by prefix", function()
        t.truthy(joined("list loot"):find("[Loot]", 1, true), "lower-case name resolves")
        t.truthy(joined("list Curr"):find("[Currency]", 1, true), "an unambiguous prefix resolves")
    end)

    test("/pc list on an unknown category lists the valid ones", function()
        local text = joined("list zzz")
        t.truthy(text:find("unknown category 'zzz'", 1, true), "the bad name is echoed back")
        t.truthy(text:find(table.concat(Schema.CATEGORY_ORDER, ", "), 1, true),
            "and every valid category is offered")
    end)

    -- ---- reset ----------------------------------------------------------

    test("/pc reset <Category> resets it and confirms", function()
        Schema.Set("Loot.enabled", false)
        local text = joined("reset loot")
        t.eq(Schema.Get("Loot.enabled"), NS.Defaults.Loot.enabled, "the category is back to default")
        t.truthy(text:find("Loot reset to defaults", 1, true), "the canonical name is confirmed")
    end)

    test("/pc reset with no argument prints usage and the valid categories", function()
        local text = joined("reset")
        t.truthy(text:find("usage: ", 1, true), "usage is printed")
        t.truthy(text:find(table.concat(Schema.CATEGORY_ORDER, ", "), 1, true),
            "with the category list")
    end)

    test("/pc reset on an unknown category changes nothing", function()
        Schema.Set("Loot.enabled", false)
        t.truthy(joined("reset zzz"):find("unknown category 'zzz'", 1, true), "rejected by name")
        t.eq(Schema.Get("Loot.enabled"), false, "no category was reset")
    end)

    test("/pc resetall clears every override and confirms", function()
        Schema.Set("General.enabled", false)
        Schema.Set(formatPath, "CUSTOM %s")
        local text = joined("resetall")
        t.nilv(addon.db.profile.enabled, "the master override is cleared")
        t.truthy(next(addon.db.profile.categories) == nil, "every category table is cleared")
        t.truthy(text:find("all settings reset to defaults", 1, true), "and the reset is confirmed")
    end)

    -- ---- test -----------------------------------------------------------

    test("/pc test routes every line through the [PC] printer", function()
        -- PC-35 / events-frames-taint-§8: Test() prints through NS.Print, never
        -- straight to the chat frame, so every emitted line carries the [PC] tag.
        local before = #env.DEFAULT_CHAT_FRAME.messages
        run(NS, addon, "test", "category Loot")
        local msgs = env.DEFAULT_CHAT_FRAME.messages
        t.truthy(#msgs > before, "/pc test emits output")
        local allTagged = true
        for i = before + 1, #msgs do
            if msgs[i]:sub(1, #PREFIX) ~= PREFIX then allTagged = false end
        end
        t.truthy(allTagged, "every /pc test line begins with the [PC] prefix")
    end)

    test("/pc test and /pc test all preview the whole surface", function()
        local bare = #slash("test")
        local all  = #slash("test all")
        t.eq(bare, all, "the bare verb and `all` are the same report")
        t.truthy(bare > 10, "the full report covers the string surface")
    end)

    test("/pc test category resolves the name and narrows the report", function()
        local text = joined("test category loot")
        t.truthy(text:find("Category: Loot", 1, true), "the canonical category is previewed")
        t.falsy(text:find("Category: Money", 1, true), "other categories are excluded")
    end)

    test("/pc test formatstring upper-cases the name before matching", function()
        local text = joined("test formatstring loot_item_self")
        t.truthy(text:find("LOOT_ITEM_SELF", 1, true), "the lower-case name resolved")
        t.truthy(text:find("1 string shown", 1, true), "and exactly one string was previewed")
    end)

    test("/pc test surfaces usage for each malformed filter", function()
        t.truthy(joined("test nonsense"):find("usage: ", 1, true), "an unknown filter kind")
        t.truthy(joined("test category"):find("usage: ", 1, true), "category with no name")
        t.truthy(joined("test formatstring"):find("usage: ", 1, true), "formatstring with no name")
    end)

    test("/pc test rejects unknown filter values by name", function()
        t.truthy(joined("test category zzz"):find("unknown category 'zzz'", 1, true),
            "an unknown category is named")
        local text = joined("test formatstring NOPE_NOPE")
        t.truthy(text:find("unknown format string 'NOPE_NOPE'", 1, true),
            "an unknown format string is named")
        t.truthy(text:find("/pc list formatstring", 1, true), "with a pointer to the listing")
    end)

    -- ---- debug ----------------------------------------------------------

    test("/pc debug rejects an argument that is neither on, off, nor a toggle", function()
        local text = joined("debug sideways")
        t.truthy(text:find("usage: ", 1, true), "usage is printed")
        t.truthy(text:find("/pc debug [on | off]", 1, true),
            "and it names the accepted arguments")
    end)

    test("every slash line carries the cyan [PC] tag", function()
        -- No module prints raw: one tagged seam for the whole surface.
        for _, input in ipairs({ "", "help", "version", "list category", "get General.enabled",
                                 "reset zzz", "test nonsense", "debug sideways", "nonsense" }) do
            for _, line in ipairs(slash(input)) do
                t.truthy(line:sub(1, #PREFIX) == PREFIX,
                    ("/pc %s emits only tagged lines"):format(input))
            end
        end
    end)
end
