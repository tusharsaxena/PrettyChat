-- tests/test_schema.lua — path resolution, Get/Set, and the single
-- write-path side effects (ApplyStrings runs on every Set).

local function firstFormatRow(Schema, category)
    for _, row in ipairs(Schema.RowsByCategory(category)) do
        if row.kind == "string_format" then return row end
    end
end

local ctx = _G.PC_TEST
local t = ctx.t
local test = ctx.test
local inst   = ctx.loadAddon()
local Schema = inst.NS.Schema
local env    = inst.env
local row    = firstFormatRow(Schema, "Loot")

test("resolves known setting paths and returns nil for unknown ones", function()
    t.truthy(Schema.FindByPath("General.enabled"), "General.enabled resolves")
    t.truthy(Schema.FindByPath("Loot.enabled"),    "Loot.enabled resolves")
    t.falsy(Schema.FindByPath("Nope.nope"),        "unknown path is nil")
    t.nilv(Schema.Get("Nope.nope"),               "Get on unknown path is nil")
end)

test("resolves categories case-insensitively and by prefix", function()
    t.eq(Schema.ResolveCategory("loot"), "Loot", "case-insensitive category")
    t.eq(Schema.ResolveCategory("Curr"), "Currency", "prefix category")
    t.nilv(Schema.ResolveCategory("zzz"), "unknown category is nil")
end)

test("master toggle round-trips through the single write path", function()
    Schema.Set("General.enabled", false)
    t.eq(Schema.Get("General.enabled"), false, "master set false")
    Schema.Set("General.enabled", true)
    t.eq(Schema.Get("General.enabled"), true, "master set true")
end)

test("Set on a format pushes the override to _G via ApplyStrings", function()
    t.truthy(row, "found a Loot format row")
    Schema.Set(row.path, "CUSTOM %s")
    t.eq(Schema.Get(row.path), "CUSTOM %s", "Get returns stored override")
    t.eq(env[row.globalName], "CUSTOM %s", "ApplyStrings pushed override to _G")
end)

test("re-setting a format to its default auto-clears the stored override", function()
    Schema.Set(row.path, row.default)
    t.eq(Schema.Get(row.path), row.default, "reset to default via Set")
    local catDB = inst.addon.db.profile.categories[row.category]
    t.truthy(not (catDB and catDB.strings and catDB.strings[row.globalName]),
        "default value auto-clears the stored override")
end)

test("Set on an unknown path is a no-op returning false", function()
    t.falsy(Schema.Set("Nope.nope", true), "Set unknown path returns false")
end)

test("load-time schema path validation resolved every path", function()
    t.truthy(Schema.validation, "schema validation stashed at load")
    t.truthy(Schema.validation.checked > 0, "validator checked rows")
    t.eq(Schema.validation.failed, 0, "every schema path resolves to a backing default")
    t.eq(#Schema.validation.misses, 0, "and nothing was reported as unresolved")
end)

-- ---- rows -----------------------------------------------------------

test("the four row kinds are built with their documented shape", function()
    local addonRow = Schema.FindByPath("General.enabled")
    t.eq(addonRow.kind, "addon_enabled", "General.enabled is the addon-wide row")
    t.eq(addonRow.type, "bool",     "and it is a bool")
    t.eq(addonRow.default, true,    "defaulting to on")

    local catRow = Schema.FindByPath("Loot.enabled")
    t.eq(catRow.kind, "category_enabled", "<Category>.enabled is the category row")
    t.eq(catRow.default, inst.NS.Defaults.Loot.enabled, "seeded from the defaults table")

    local enRow = Schema.FindByPath(row.category .. "." .. row.globalName .. ".enabled")
    t.eq(enRow.kind, "string_enabled", "<Category>.<GLOBAL>.enabled is the per-string toggle")
    t.eq(enRow.type, "bool", "which is a bool")

    t.eq(row.kind, "string_format", "<Category>.<GLOBAL>.format is the format row")
    t.eq(row.type, "string", "which is a string")
    t.eq(row.globalName, row.globalName, "carrying the Blizzard global it writes")
end)

test("exactly one addon-wide row exists, under the virtual General category", function()
    local addonRows = 0
    for _, r in ipairs(Schema.RowsByCategory("General")) do
        if r.kind == "addon_enabled" then addonRows = addonRows + 1 end
    end
    t.eq(addonRows, 1, "one master switch, not one per category")
    t.eq(#Schema.RowsByCategory("General"), 1, "and General hosts nothing else")
end)

test("RowsByCategory returns only that category, in registration order", function()
    local rows = Schema.RowsByCategory("Loot")
    t.truthy(#rows > 1, "the category has rows")
    for _, r in ipairs(rows) do
        t.eq(r.category, "Loot", "every returned row belongs to the category")
    end
    t.eq(rows[1].kind, "category_enabled", "the category toggle is built first")
    t.eq(#Schema.RowsByCategory("Nope"), 0, "an unknown category yields no rows")
end)

test("a cross-registered global carries one format row per category", function()
    for globalName, cats in pairs(Schema.crossRegisteredGlobals) do
        for _, c in ipairs(cats) do
            local r = Schema.FindByPath(c .. "." .. globalName .. ".format")
            t.truthy(r, ("%s.%s has its own row"):format(c, globalName))
            t.eq(r.globalName, globalName, "and both rows target the same Blizzard global")
        end
    end
end)

-- ---- category resolution ---------------------------------------------

test("an exact category name beats any prefix interpretation", function()
    t.eq(Schema.ResolveCategory("Misc"), "Misc", "exact match resolves")
    t.eq(Schema.ResolveCategory("MISC"), "Misc", "in any casing")
end)

test("an ambiguous prefix resolves to nothing rather than guessing", function()
    -- "M" prefixes both Money and Misc.
    t.nilv(Schema.ResolveCategory("M"), "an ambiguous prefix is refused")
    t.eq(Schema.ResolveCategory("Mo"), "Money", "one more letter disambiguates")
end)

test("a non-string or empty category name resolves to nothing", function()
    t.nilv(Schema.ResolveCategory(""),   "empty resolves to nil")
    t.nilv(Schema.ResolveCategory(nil),  "nil resolves to nil")
    t.nilv(Schema.ResolveCategory(42),   "a number resolves to nil")
end)

-- ---- the value formatter ---------------------------------------------

test("FormatValue renders nil, bools, strings and numbers", function()
    t.eq(Schema.FormatValue(row, nil), "nil", "an unset value reads as nil")
    t.eq(Schema.FormatValue(nil, true), "true", "no row falls back to the value's own type")
    t.eq(Schema.FormatValue(nil, 42), "42", "a number stringifies")
    t.eq(Schema.FormatValue({ type = "string" }, "no pipes"), "no pipes",
        "a pipe-free string passes through untouched")
end)

-- ---- the write path ---------------------------------------------------

test("Set returns true and coerces bool rows to real booleans", function()
    t.truthy(Schema.Set("General.enabled", "truthy string"), "Set reports success")
    t.eq(Schema.Get("General.enabled"), true, "a truthy value stores as boolean true")
    Schema.Set("General.enabled", nil)
    t.eq(Schema.Get("General.enabled"), false, "a falsy value stores as boolean false")
    Schema.Set("General.enabled", true)
end)

test("row.set closures are pure DB writes with no side effects", function()
    -- Documented contract: ApplyStrings + NotifyPanelChange live in
    -- Schema.Set so a future SetMany can batch them. Calling a row's set
    -- directly must therefore NOT reach _G.
    local before = env[row.globalName]
    row.set("BYPASSED %s")
    t.eq(env[row.globalName], before, "the raw setter did not touch the Blizzard global")
    Schema.Set(row.path, row.default)
    t.eq(env[row.globalName], row.default, "going through Set does apply")
end)

-- ---- panel refresher dispatch ------------------------------------------

test("NotifyPanelChange calls only the affected category's refresher", function()
    local calls = {}
    Schema.RegisterRefresher("Loot",  function() calls[#calls + 1] = "Loot" end)
    Schema.RegisterRefresher("Money", function() calls[#calls + 1] = "Money" end)

    Schema.NotifyPanelChange("Loot")
    t.eq(#calls, 1, "one refresher ran")
    t.eq(calls[1], "Loot", "and it was the matching one")
end)

test("a General or unscoped change refreshes every registered page", function()
    -- Per-string disabled state depends on the master switch, so a General
    -- write has to fan out.
    local calls = {}
    Schema.RegisterRefresher("Loot",  function() calls[#calls + 1] = "Loot" end)
    Schema.RegisterRefresher("Money", function() calls[#calls + 1] = "Money" end)

    Schema.NotifyPanelChange("General")
    t.eq(#calls, 2, "General fans out to every refresher")

    calls = {}
    Schema.NotifyPanelChange()
    t.eq(#calls, 2, "so does an unscoped notify")
end)

test("a refresher that errors cannot break the write path", function()
    Schema.RegisterRefresher("Loot", function() error("panel exploded") end)
    local ok = pcall(Schema.Set, "Loot.enabled", false)
    t.truthy(ok, "the exception is contained by the pcall dispatch")
    t.eq(Schema.Get("Loot.enabled"), false, "and the write still landed")
    Schema.refreshers["Loot"] = nil
    Schema.Set("Loot.enabled", true)
end)

test("an unregistered category is a silent no-op, not an error", function()
    local ok = pcall(Schema.NotifyPanelChange, "NeverOpened")
    t.truthy(ok, "notifying a page that was never opened is safe")
end)
