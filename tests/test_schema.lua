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
    -- Three now, and all three are the composed Master controls block
    -- (options-ui-§15). MOVED here rather than added beside what was already
    -- drawn: the console toggle used to be a bespoke SessionCheckbox
    -- settings/Panel.lua drew through `pairWith`, and there is exactly one
    -- declaration of it.
    t.eq(#Schema.RowsByCategory("General"), 3, "and General hosts the whole block")
end)

test("the Master controls block is the composed one, in canonical order", function()
    -- Not hand-written (options-ui-§15): these rows are H.MasterControls' own, so
    -- what is pinned here is the LEAVES, their ORDER, and PrettyChat's frameless
    -- omission — master scale, master alpha and lock frame. Dies if a leaf is
    -- added by hand, reordered, or if `frameless` is dropped from the spec.
    local generalRows = Schema.RowsByCategory("General")
    local paths = {}
    for i, r in ipairs(generalRows) do paths[i] = r.path end
    t.eq(table.concat(paths, ","),
        "General.enabled,General.visibility,state.debugConsole",
        "enable, visibility, console — the frameless block, in that order")

    for _, path in ipairs({ "General.scale", "General.alpha", "General.locked" }) do
        t.nilv(Schema.FindByPath(path), path .. " is omitted: this addon draws no frame")
    end

    -- The block leads the whole schema, which is what makes Master controls the
    -- General page's FIRST tab and what puts it at the head of `/pc list`.
    t.eq(Schema.AllRows()[1].path, "General.enabled", "and it is spliced in at the head")
end)

test("every schema row on every page carries a group", function()
    -- A page whose rows carry no `group` is REPORTED and rendered untabbed by the
    -- library (options-ui-§13), which is a strip-less page nobody asked for. Dies
    -- the moment a row is added without one.
    for _, r in ipairs(Schema.AllRows()) do
        t.truthy(r.group, r.path .. " declares the tab it is drawn on")
        t.truthy(r.page,  r.path .. " declares the page it belongs to")
    end
end)

test("no colour row exists, and none may appear without its class-colour companion", function()
    -- options-ui-§17 requires every non-palette colour swatch to carry a
    -- `useClassColor<Surface>` companion IMMEDIATELY after it, and forbids
    -- `disabledIf` on a swatch outright (the swatch is still read for its alpha, so
    -- graying it would say something untrue). PrettyChat has NONE — the schema is
    -- bool and string only, which is why `colorDecode`/`colorEncode` are the two
    -- descriptor fields settings/OptionsSetup.lua deliberately does not pass.
    --
    -- Not a vacuous loop: the count is asserted, so this case dies the moment a
    -- colour row is hand-written into the schema instead of composed through
    -- H.ColorPair (which supplies the companion and the `startsLine` for free).
    local rows, colours = Schema.AllRows(), 0
    for i, r in ipairs(rows) do
        if r.type == "color" then
            colours = colours + 1
            t.falsy(r.disabledIf, r.path .. " must never carry disabledIf")
            local companion = rows[i + 1]
            t.truthy(companion and companion.type == "bool"
                and companion.label == "Use class color",
                r.path .. " is followed by its Use class color companion")
            t.truthy(r.classColorSource, r.path .. " declares which class it means")
        end
    end
    t.eq(colours, 0, "this addon ships no colour rows at all")
end)

test("the visibility row is the canonical four-mode dropdown, not a boolean", function()
    -- options-ui-§15: a boolean can only ever answer two of the four. PrettyChat
    -- never shipped a "show only in combat" checkbox, so there is no stored shape
    -- to migrate — what there is instead is this row, with all four modes honoured
    -- by modules/Override.lua (tests/test_override.lua pins that end).
    local visRow = Schema.FindByPath("General.visibility")
    t.eq(visRow.type, "string", "a string enum")
    t.eq(visRow.default, "always", "defaulting to always")
    local modes = {}
    for key in pairs(visRow.values or {}) do modes[#modes + 1] = key end
    table.sort(modes)
    t.eq(table.concat(modes, ","), "always,inCombat,never,outOfCombat",
        "and it offers exactly the four canonical modes")
end)

test("the debug console row is session-only and re-applies nothing", function()
    -- It stores nothing — the console's visibility is not a setting — and it must
    -- not drag a pass over ~170 Blizzard globals behind it. Dies if the
    -- `sessionOnly` guard in Schema.Set is removed.
    local consoleRow = Schema.FindByPath("state.debugConsole")
    t.truthy(consoleRow.sessionOnly, "the row declares itself session-only")
    t.nilv(consoleRow.default, "and carries no stored default")

    Schema.Set(row.path, "SENTINEL %s")
    env[row.globalName] = "UNTOUCHED"
    Schema.Set("state.debugConsole", true)
    t.eq(env[row.globalName], "UNTOUCHED", "toggling the console re-applied nothing")
    Schema.Set("state.debugConsole", false)
    Schema.Set(row.path, row.default)
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

-- ---- the page -> tab -> row partition ----------------------------------
--
-- The DESIGNED shape of the settings panel, written out as numbers. It is the
-- case that catches a row drifting into the wrong tab, which is invisible in
-- game until a player goes looking for a control that is no longer where the
-- docs say it is. Every count here is also the count docs/settings-panel.md and
-- docs/module-map.md print, so a disagreement between the schema and the docs
-- surfaces here rather than at a reader's desk.
--
-- Two pages, and BOTH draw a strip (options-ui-§13). "General" is the virtual
-- category and holds exactly the composed Master controls block, on a ONE-TAB
-- strip — a single tab is still a strip as of OptionsWidgets minor 13, and this
-- page is why the rule matters: it was the one page in the addon without one.
-- "Categories" holds one tab per message category, in CATEGORY_ORDER, and owns no
-- rows of its own — its page key is deliberately not a category, so
-- Schema.ResolveCategory("Categories") must stay nil.
--
-- `tab` is the GROUP the rows declare; `category` is where they are stored. They
-- differ on exactly one tab, and listing both is the point: the General page's
-- rows are stored under the virtual "General" category and drawn under a tab
-- called "Master controls".
local PARTITION = {
    { page = "General", tabs = {
        { tab = "Master controls", category = "General", rows = 3 },
    } },
    { page = "Categories", tabs = {
        { tab = "Loot",       category = "Loot",       rows = 39 },
        { tab = "Currency",   category = "Currency",   rows =  9 },
        { tab = "Money",      category = "Money",      rows = 17 },
        { tab = "Reputation", category = "Reputation", rows = 29 },
        { tab = "Experience", category = "Experience", rows = 41 },
        { tab = "Honor",      category = "Honor",      rows = 13 },
        { tab = "Tradeskill", category = "Tradeskill", rows = 17 },
        { tab = "Misc",       category = "Misc",       rows =  5 },
    } },
}

test("every page's tabs hold the designed number of rows", function()
    for _, page in ipairs(PARTITION) do
        for _, tab in ipairs(page.tabs) do
            t.eq(#Schema.RowsByCategory(tab.category), tab.rows,
                ("%s > %s holds %d rows"):format(page.page, tab.tab, tab.rows))
            for _, r in ipairs(Schema.RowsByCategory(tab.category)) do
                t.eq(r.group, tab.tab, r.path .. " declares the tab it is drawn on")
                t.eq(r.page, page.page, r.path .. " declares the page it is drawn on")
            end
        end
    end
end)

test("the partition is total and disjoint — every row on exactly one tab", function()
    local seen, total = {}, 0
    for _, page in ipairs(PARTITION) do
        for _, tab in ipairs(page.tabs) do
            t.falsy(seen[tab.category], tab.tab .. " appears on exactly one tab")
            seen[tab.category] = true
            total = total + tab.rows
        end
    end
    t.eq(total, #Schema.AllRows(), "the tabs account for every schema row, and no more")
    for _, r in ipairs(Schema.AllRows()) do
        t.truthy(seen[r.category], r.path .. " belongs to a tab the panel draws")
    end
end)

test("the Categories tabs are CATEGORY_ORDER minus the virtual General", function()
    -- Derived rather than restated in settings/Panel.lua, so the strip, `/pc list`
    -- and `/pc test` cannot disagree about what comes first.
    local designed = {}
    for _, tab in ipairs(PARTITION[2].tabs) do designed[#designed + 1] = tab.tab end
    local expected = {}
    for _, c in ipairs(Schema.CATEGORY_ORDER) do
        if c ~= "General" then expected[#expected + 1] = c end
    end
    t.eq(table.concat(designed, ","), table.concat(expected, ","),
        "tab order follows the one display order")
    t.nilv(Schema.ResolveCategory("Categories"),
        "and the page name is not itself a category — no row is stored under it")
end)
