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
    -- The sentinel carries no conversion on purpose. `row` is whatever sorts first
    -- in Loot, and the write gate below refuses a format asking for more than the
    -- shipped default supplies — a bare word is a valid write for every row.
    t.truthy(row, "found a Loot format row")
    Schema.Set(row.path, "CUSTOM")
    t.eq(Schema.Get(row.path), "CUSTOM", "Get returns stored override")
    t.eq(env[row.globalName], "CUSTOM", "ApplyStrings pushed override to _G")
end)

test("re-setting a format to its default auto-clears the stored override", function()
    Schema.Set(row.path, row.default)
    t.eq(Schema.Get(row.path), row.default, "reset to default via Set")
    local catDB = inst.addon.db.profile.categories[row.category]
    t.truthy(not (catDB and catDB.strings and catDB.strings[row.globalName]),
        "default value auto-clears the stored override")
end)

-- ---- the conversion-signature gate (PC-R-01) ----------------------
--
-- LOOT_ITEM_SELF by name rather than firstFormatRow's: the gate compares a write
-- against the SHIPPED DEFAULT's signature, so a case about surplus conversions
-- needs a row whose default actually carries one. The first Loot row
-- alphabetically is BATTLE_PET_LOOT_RECEIVED, whose default (like Blizzard's) has
-- none at all, and every write below would be refused for the wrong reason.
local sigRow = Schema.FindByPath("Loot.LOOT_ITEM_SELF.format")

local function saidSince(at, needle)
    for i = at + 1, #env.DEFAULT_CHAT_FRAME.messages do
        if env.DEFAULT_CHAT_FRAME.messages[i]:find(needle, 1, true) then return true end
    end
    return false
end

test("a format write with a surplus conversion is refused", function()
    -- The defect this closes: the Preview synthesizes its arguments FROM the format,
    -- so it renders a surplus %s happily and reports success; the raise happens later,
    -- inside Blizzard's chat handler, on every matching message.
    t.truthy(sigRow, "the reference row resolves")
    local stored = Schema.Get(sigRow.path)
    local at = #env.DEFAULT_CHAT_FRAME.messages

    t.falsy(Schema.Set(sigRow.path, "Loot | %s %s"), "a surplus conversion is refused")
    t.eq(Schema.Get(sigRow.path), stored, "and nothing was stored")
    t.eq(env[sigRow.globalName], stored, "and nothing reached _G")
    t.truthy(saidSince(at, sigRow.path), "the refusal names the path it refused")

    t.falsy(Schema.Set(sigRow.path, "Loot | %d"), "so is a class mismatch at a position")
    t.eq(Schema.Get(sigRow.path), stored, "still nothing stored")
end)

test("a format whose conversions prefix the default's is stored", function()
    t.truthy(Schema.Set(sigRow.path, "Loot | %s"), "the same signature is accepted")
    t.eq(Schema.Get(sigRow.path), "Loot | %s", "and stored")
    -- Dropping trailing conversions is safe — string.format ignores surplus
    -- ARGUMENTS — so a truncating format is a prefix and passes.
    t.truthy(Schema.Set(sigRow.path, "Loot happened"), "dropping the conversion is accepted")
    t.eq(Schema.Get(sigRow.path), "Loot happened", "and stored")
    Schema.Set(sigRow.path, sigRow.default)
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
    -- Four now, and all four are the composed Master controls block
    -- (options-ui-§15). None of them was added beside what was already drawn: the
    -- console toggle used to be a bespoke SessionCheckbox settings/Panel.lua drew
    -- through `pairWith`, and the Minimap button row is the composer's own at
    -- minor 7. There is exactly one declaration of each.
    t.eq(#Schema.RowsByCategory("General"), 4, "and General hosts the whole block")
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
        "General.enabled,General.visibility,state.debugConsole,global.minimap.shown",
        "enable, visibility, console, minimap — the frameless block, in that order")

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

test("no color row exists, and none may appear without its class-color companion", function()
    -- options-ui-§17 requires every non-palette color swatch to carry a
    -- `useClassColor<Surface>` companion IMMEDIATELY after it, and forbids
    -- `disabledIf` on a swatch outright (the swatch is still read for its alpha, so
    -- graying it would say something untrue). PrettyChat has NONE — the schema is
    -- bool and string only, which is why `colorDecode`/`colorEncode` are the two
    -- descriptor fields settings/OptionsSetup.lua deliberately does not pass.
    --
    -- Not a vacuous loop: the count is asserted, so this case dies the moment a
    -- color row is hand-written into the schema instead of composed through
    -- H.ColorPair (which supplies the companion and the `startsLine` for free).
    local rows, colors = Schema.AllRows(), 0
    for i, r in ipairs(rows) do
        if r.type == "color" then
            colors = colors + 1
            t.falsy(r.disabledIf, r.path .. " must never carry disabledIf")
            local companion = rows[i + 1]
            t.truthy(companion and companion.type == "bool"
                and companion.label == "Use class color",
                r.path .. " is followed by its Use class color companion")
            t.truthy(r.classColorSource, r.path .. " declares which class it means")
        end
    end
    t.eq(colors, 0, "this addon ships no color rows at all")
end)

test("the visibility row is the canonical four-mode dropdown, not a boolean", function()
    -- options-ui-§15: a boolean can only ever answer two of the four. PrettyChat
    -- never shipped a "show only in combat" checkbox, so there is no stored shape
    -- to migrate — what there is instead is this row, with all four modes honored
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
    -- `sessionOnly` guard in the write seam's `announce` is removed.
    local consoleRow = Schema.FindByPath("state.debugConsole")
    t.truthy(consoleRow.sessionOnly, "the row declares itself session-only")
    -- Re-pinned at the LibKa0s-Schema-1.0 adoption (its JC-5). The default is what a
    -- reset writes, never what is stored, and the library reads a nil default as
    -- "no restore". It used to be nil, and a reset wrote nil, which the row's `set`
    -- read as hide. `false` is the same hide, and the seam case below
    -- ("resetting the console row ... closes the console") pins that it still happens.
    t.eq(consoleRow.default, false, "and its reset target is closed")

    Schema.Set(row.path, "SENTINEL")
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

test("the load-time duplicate check finds no global registered twice", function()
    t.eq(type(Schema.duplicateGlobals), "table", "the duplicate check publishes its result")
    t.nilv(next(Schema.duplicateGlobals), "no Blizzard global is registered under two categories")
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
    -- Schema.Set, so its batched sibling Schema.ResetRows can pay them once
    -- per batch. Calling a row's set directly must therefore NOT reach _G.
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
        { tab = "Master controls", category = "General", rows = 4 },
    } },
    { page = "Categories", tabs = {
        { tab = "Loot",       category = "Loot",       rows = 35 },
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

-- ---- the write seam, characterized (LibKa0s-Schema-1.0 adoption) ----------
--
-- Written BEFORE the seam moved onto the library's instance, and green against the
-- host-owned seam it replaced, so each case below is a statement that the adoption
-- did not change what a player or a caller can observe: what is stored, what reaches
-- _G, how many passes and refreshes a write costs, the lines it prints, and what the
-- seam returns. A fresh instance of its own, because the refresher cases above leave
-- registrations behind.

local seam   = ctx.loadAddon()
local SS     = seam.NS.Schema
local SD     = seam.NS.DebugLog
local SIG    = "Loot.LOOT_ITEM_SELF.format"

-- Run `fn` with the pass and the refresh counted and the debug console capturing.
-- Returns the pcall result, the lines written, and the two counts.
local function observed(fn)
    local addon = seam.addon
    local wasDebug = seam.NS.State.debug
    seam.NS.State.debug = true
    -- The console's frame is built by its first line, and building it fires the
    -- window's own visibility callback (a General refresh). Warmed before the spies
    -- go in, so the refresh count below is the write's and not the frame's.
    seam.NS.Debug("Test", "warm-up")
    local origApply, origNotify = addon.ApplyStrings, SS.NotifyPanelChange
    local passes, notifies = 0, 0
    addon.ApplyStrings = function(self, ...)
        passes = passes + 1
        return origApply(self, ...)
    end
    SS.NotifyPanelChange = function(...)
        notifies = notifies + 1
        return origNotify(...)
    end
    SD:Clear()
    local ok, err = pcall(fn)
    seam.NS.State.debug = wasDebug
    addon.ApplyStrings, SS.NotifyPanelChange = origApply, origNotify
    local lines = {}
    for i, line in ipairs(SD.buffer) do lines[i] = line end
    return ok, err, lines, passes, notifies
end

local function countMatching(lines, needle)
    local n = 0
    for _, line in ipairs(lines) do
        if line:find(needle, 1, true) then n = n + 1 end
    end
    return n
end

local function packed(...) return { n = select("#", ...), ... } end

local function chatSince(at)
    local out, msgs = {}, seam.env.DEFAULT_CHAT_FRAME.messages
    for i = at + 1, #msgs do out[#out + 1] = msgs[i] end
    return out
end

test("seam: one write stores, re-applies once, refreshes once, logs one [Set] line, answers true", function()
    seam.addon:ResetAll()
    local results
    local ok, err, lines, passes, notifies = observed(function()
        results = packed(SS.Set("Loot.enabled", false))
    end)
    if not ok then error(err, 0) end
    t.eq(results.n, 1, "a successful write answers exactly one value")
    t.eq(results[1], true, "and it is true")
    t.eq(SS.Get("Loot.enabled"), false, "the value is stored")
    t.eq(seam.addon.db.profile.categories.Loot.enabled, false, "in the category's own table")
    t.eq(passes, 1, "one ApplyStrings pass")
    t.eq(notifies, 1, "one panel refresh")
    t.eq(countMatching(lines, "[Set] Loot.enabled = "), 1, "one [Set] line naming the path")
    SS.Set("Loot.enabled", true)
    t.nilv(seam.addon.db.profile.categories.Loot, "writing the default back clears to absence")
end)

test("seam: a format write renders its [Set] value through the shared formatter", function()
    seam.addon:ResetAll()
    local ok, err, lines = observed(function() SS.Set(SIG, "|cffff0000Loot|r %s") end)
    if not ok then error(err, 0) end
    t.eq(countMatching(lines, "[Set] " .. SIG .. " = "), 1, "one line")
    t.eq(countMatching(lines, "||cffff0000Loot||r %s"), 1,
        "the value's pipes doubled, exactly as /pc get renders it")
    t.eq(seam.env.LOOT_ITEM_SELF, "|cffff0000Loot|r %s", "and the override reached _G")
    SS.Set(SIG, SS.FindByPath(SIG).default)
end)

test("seam: a session-only write refreshes the panel but re-applies nothing", function()
    local ok, err, lines, passes, notifies = observed(function()
        SS.Set("state.debugConsole", true)
        SS.Set("state.debugConsole", false)
    end)
    if not ok then error(err, 0) end
    t.eq(passes, 0, "no pass over the globals for the console toggle")
    -- Four: the seam refreshes once per write, and the window's own OnShow / OnHide
    -- refreshes the General page once more each (core/DebugLogSetup.lua).
    t.eq(notifies, 4, "one seam refresh per write, plus the window's own on show and hide")
    t.eq(countMatching(lines, "[Set] state.debugConsole = "), 2, "and each write is logged")
end)

test("seam: a raising row store propagates, and nothing after it runs", function()
    seam.addon:ResetAll()
    local r = SS.FindByPath("Money.enabled")
    local origSet = r.set
    r.set = function() error("boom in the store") end
    local ok, err, lines, passes, notifies = observed(function() SS.Set("Money.enabled", false) end)
    r.set = origSet
    t.falsy(ok, "the error reaches the caller")
    t.truthy(tostring(err):find("boom in the store", 1, true), "with its own message")
    t.eq(passes, 0, "no pass ran after the failed store")
    t.eq(notifies, 0, "no refresh ran")
    t.eq(countMatching(lines, "[Set] Money.enabled = "), 0, "and no [Set] line claims the write")
end)

test("seam: /pc set of a surplus-conversion format is refused once and stores nothing", function()
    -- The PC-R-01 gate driven through the CLI, the path a value-bound descriptor takes.
    -- Dies if the gate sits anywhere the dispatcher's `set` does not cross.
    seam.addon:ResetAll()
    local r = SS.FindByPath(SIG)
    local stored, inG = SS.Get(SIG), seam.env.LOOT_ITEM_SELF
    local at = #seam.env.DEFAULT_CHAT_FRAME.messages
    local ok, err, lines = observed(function()
        seam.addon:OnSlashCommand("set " .. SIG .. " Loot | %s %s")
    end)
    if not ok then error(err, 0) end
    t.eq(SS.Get(SIG), stored, "the stored format is unchanged")
    t.eq(seam.env.LOOT_ITEM_SELF, inG, "and nothing reached _G")
    local chat = chatSince(at)
    t.eq(countMatching(chat, "Not saved"), 1, "the refusal is printed exactly once")
    t.eq(countMatching(chat, SIG), 2, "naming the path, and the echo re-reads the stored value")
    t.eq(countMatching(lines, "[Set] " .. SIG .. " = "), 0, "and no [Set] line claims a write")
    t.eq(r.default, stored, "the row still reads its shipped default")

    -- Non-vacuity: the same verb with a valid value writes, and says so.
    local ok2, err2, lines2 = observed(function()
        seam.addon:OnSlashCommand("set " .. SIG .. " Loot | %s")
    end)
    if not ok2 then error(err2, 0) end
    t.eq(SS.Get(SIG), "Loot | %s", "a valid format through the same verb is stored")
    t.eq(countMatching(lines2, "[Set] " .. SIG .. " = "), 1, "and logged")
    SS.Set(SIG, r.default)
end)

test("seam: /pc reset of a format row restores the shipped default", function()
    seam.addon:ResetAll()
    local r = SS.FindByPath(SIG)
    SS.Set(SIG, "Loot happened")
    local ok, err, lines, passes = observed(function()
        seam.addon:OnSlashCommand("reset " .. SIG)
    end)
    if not ok then error(err, 0) end
    t.eq(SS.Get(SIG), r.default, "the default is back")
    t.eq(seam.env.LOOT_ITEM_SELF, r.default, "and in _G")
    t.eq(passes, 1, "one pass")
    t.eq(countMatching(lines, "[Set] " .. SIG .. " = "), 1, "one [Set] line, as for any write")
    t.nilv(seam.addon.db.profile.categories.Loot, "a reset to default leaves no category table")
end)

test("seam: resetting the console row through ApplyDefault or /pc reset closes the console", function()
    local consoleRow = SS.FindByPath("state.debugConsole")
    SS.Set("state.debugConsole", true)
    t.truthy(SD:IsShown(), "the console is open")
    SS.ApplyDefault(consoleRow)
    t.falsy(SD:IsShown(), "ApplyDefault closes it")
    SS.Set("state.debugConsole", true)
    seam.addon:OnSlashCommand("reset state.debugConsole")
    t.falsy(SD:IsShown(), "and so does /pc reset")
end)

test("seam: CountChangedRows counts stored rows off their default, never the console", function()
    seam.addon:ResetAll()
    t.eq(SS.CountChangedRows(), 0, "a fresh profile has nothing off default")
    SS.Set("Loot.enabled", false)
    SS.Set(SIG, "Loot happened")
    SS.Set("General.visibility", "never")
    SS.Set("state.debugConsole", true)
    t.eq(SS.CountChangedRows(), 3, "three stored rows moved; the session-only row is not counted")
    SS.Set("state.debugConsole", false)
    seam.addon:ResetAll()
    t.eq(SS.CountChangedRows(), 0, "and the reset brings it back to zero")
end)

test("seam: FindByPath, Get and AllRows answer the one schema", function()
    t.truthy(SS.FindByPath(SIG), "a row resolves")
    t.nilv(SS.FindByPath(nil), "a nil path resolves to nothing")
    t.nilv(SS.FindByPath(42), "and so does a number")
    t.nilv(SS.Get("Loot"), "a path with no row reads nil: rows are not path-mapped")
    t.eq(SS.AllRows(), SS.AllRows(), "AllRows is the live table, not a copy")
    local seen = {}
    for i, r in ipairs(SS.AllRows()) do
        t.falsy(seen[r.path], r.path .. " is declared once (row #" .. i .. ")")
        seen[r.path] = true
        t.eq(SS.FindByPath(r.path), r, r.path .. " resolves to its own row")
    end
end)

-- ---- the write seam, after the adoption ------------------------------------

test("seam: the host's names ARE the library instance's members", function()
    local S = seam.NS.SchemaRuntime
    t.eq(seam.NS.SchemaLib, seam.env.LibStub("LibKa0s-Schema-1.0", true),
        "the live load runs LibKa0s-Schema-1.0, not the host stub")
    t.eq(SS.Set, S.Set, "Schema.Set is the runtime's Set")
    t.eq(SS.Get, S.Get, "Schema.Get is the runtime's Get")
    t.eq(SS.FindByPath, S.FindRow, "Schema.FindByPath is the runtime's FindRow")
    t.eq(SS.AllRows, S.AllRows, "Schema.AllRows is the runtime's AllRows")
    t.eq(SS.ApplyDefault, S.ApplyDefault, "Schema.ApplyDefault is the runtime's ApplyDefault")
    t.eq(SS.CountChangedRows, S.CountOffDefault, "Schema.CountChangedRows is CountOffDefault")
end)

test("seam: the schema passes the library's shape check with nothing to report (JC-13)", function()
    -- Every row a table with a path, a known type, one of the two pages and a group,
    -- and no path declared twice. No `defaultsRoot`: the rows are not path-mapped, so
    -- the per-kind resolver in runValidation stays the resolution check.
    local printed = {}
    local origPrint = seam.NS.Print
    seam.NS.Print = function(line) printed[#printed + 1] = line end
    local errors, resolved, missing = seam.NS.SchemaRuntime.Validate({
        types = { bool = true, string = true },
        pages = { General = true, Categories = true },
    })
    seam.NS.Print = origPrint
    t.eq(errors, 0, "no shape error: " .. table.concat(printed, " / "))
    t.eq(resolved, 0, "no resolution check was asked for")
    t.eq(missing, 0, "so none missed")
end)

test("seam: the [Set] line is written before the re-apply (JC-4)", function()
    -- LibKa0s-Schema-1.0 logs before the reaction, so a raising re-apply cannot erase
    -- the trace of a write that landed. Before the adoption the line came last.
    seam.addon:ResetAll()
    local linesAtPass
    local origApply = seam.addon.ApplyStrings
    local ok, err, lines = observed(function()
        local inner = seam.addon.ApplyStrings
        seam.addon.ApplyStrings = function(self, ...)
            linesAtPass = #SD.buffer
            return inner(self, ...)
        end
        SS.Set("Loot.enabled", false)
    end)
    seam.addon.ApplyStrings = origApply
    if not ok then error(err, 0) end
    t.eq(countMatching(lines, "[Set] Loot.enabled = "), 1, "one line")
    t.eq(linesAtPass, 1, "and it was already in the console when the pass ran")
    SS.Set("Loot.enabled", true)
end)

-- ---- library absent: the writes a player can still make ------------------
--
-- options-ui-§1 keeps Reset All real and slash-commands-§1 keeps the host verbs,
-- so a load with no LibKa0s still writes. One case per writer kind: the host verb,
-- a panel-less category reset, and the seam itself with its gate.
local bareSeam = ctx.loadAddon({ skip = { "libs/LibKa0s/Core.lua" } })

test("seam, library absent: /pc disable and /pc enable still write the master switch", function()
    local B = bareSeam
    B.addon:OnSlashCommand("disable")
    t.eq(B.addon:IsAddonEnabled(), false, "/pc disable stored the switch")
    t.eq(B.addon.db.profile.enabled, false, "in the profile")
    B.addon:OnSlashCommand("enable")
    t.eq(B.addon:IsAddonEnabled(), true, "/pc enable brought it back")
    t.nilv(B.addon.db.profile.enabled, "clearing to absence")
end)

test("seam, library absent: a category reset and the format gate still work", function()
    local B, BS = bareSeam, bareSeam.NS.Schema
    t.truthy(BS.Set(SIG, "Loot | %s"), "a valid format lands")
    t.eq(B.env.LOOT_ITEM_SELF, "Loot | %s", "and reaches _G")
    t.truthy(BS.Set("Loot.enabled", false), "a toggle write lands")
    t.falsy(BS.Set(SIG, "Loot | %s %s"), "a surplus conversion is still refused")
    t.eq(BS.Get(SIG), "Loot | %s", "and stores nothing")
    B.addon:ResetCategory("Loot")
    t.eq(BS.Get("Loot.enabled"), B.NS.Defaults.Loot.enabled, "the category reset restored the toggle")
    t.eq(BS.Get(SIG), BS.FindByPath(SIG).default, "and the format")
    t.nilv(B.addon.db.profile.categories.Loot, "leaving no category table")
end)
