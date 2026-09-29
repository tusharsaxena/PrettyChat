-- tests/test_panel.lua — settings/Panel.lua, the addon's largest module.
--
-- The panel's testable contract is *wiring*, not pixels: which widget exists,
-- what it is seeded from, which schema path its callback writes through, and
-- when it is built. The AceGUI/frame mocks model exactly that (widget type,
-- label, value, disabled, callbacks, child order, shown-ness), so these cases
-- drive the real registration + first-OnShow build path. Layout, fonts and
-- skinning stay in docs/smoke-tests.md.
--
-- The Categories page's per-string editor cases live in
-- tests/test_panel_categories.lua, and the helpers both suites read the panel
-- through in tests/panel_fixture.lua.

local ctx = _G.PC_TEST
local t      = ctx.t
local test   = ctx.test
local inst   = ctx.loadAddon()
local NS     = inst.NS
local addon  = inst.addon
local env    = inst.env
local Schema = NS.Schema
local L      = NS.L
local C      = NS.Const.Color

local fixture      = dofile(ctx.root .. "/tests/panel_fixture.lua")(NS)
local panelFrame   = fixture.panelFrame
local widgetsSince = fixture.widgetsSince
local byLabel      = fixture.byLabel
local tabButtons   = fixture.tabButtons
local sortedNames  = fixture.sortedNames

-- OnEnable already ran registerPanels; each page builds its body on first
-- OnShow, so the suite shows a page and then reads the widgets it created.
local generalPanel    = panelFrame(env, "General")
-- Every message category is a TAB on this one page now, and Loot is the first of
-- them, so a Categories page nobody has clicked is a Loot page.
local categoriesPanel = panelFrame(env, "Categories")
local parentPanel     = env._settings.categories[1] and env._settings.categories[1].frame

local generalWidgets

local function tabNames(pageKey)
    local names = {}
    for i, b in ipairs(tabButtons(pageKey)) do names[i] = b.text end
    return names
end

-- ---- registration -------------------------------------------------

test("registration builds the parent category and three sub-pages", function()
    -- The left rail used to carry nine rows, eight of which were the same page
    -- with a different noun on it. It carries two: the addon-wide switches, and
    -- everything this addon rewrites (one tab per message category), and then the
    -- Profiles page, last (options-ui-§3; tests/test_profiles.lua owns its detail).
    t.eq(#env._settings.categories, 1, "exactly one canvas parent category")
    t.eq(env._settings.categories[1].name, "Ka0s Pretty Chat", "the parent carries the brand title")
    t.eq(#env._settings.addonCategories, 1, "the parent is added to the AddOns list")
    t.eq(#env._settings.subcategories, 3, "three sub-pages, not one per category")
    t.eq(env._settings.subcategories[1].name, "General", "General leads the rail")
    t.eq(env._settings.subcategories[2].name, L["Categories"], "and Categories follows it")
    t.eq(env._settings.subcategories[3].name, L["Profiles"], "and Profiles closes it")
    for _, category in ipairs(Schema.CATEGORY_ORDER) do
        if category ~= "General" then
            t.falsy(panelFrame(env, category),
                category .. " is a tab now, not a page of its own")
        end
    end
end)

test("the strip carries one tab per message category, in CATEGORY_ORDER", function()
    categoriesPanel:Show()
    local expected = {}
    for _, category in ipairs(Schema.CATEGORY_ORDER) do
        if category ~= "General" then expected[#expected + 1] = category end
    end
    t.eq(table.concat(tabNames("Categories"), ","), table.concat(expected, ","),
        "the strip order IS the order /pc list and /pc test print")
    t.eq(NS.Helpers.__panelFor("Categories").activeTab, "Loot",
        "and the page opens on the first tab")
end)

test("the panel registry holds one ctx per page, reachable by page key", function()
    -- The category handle used to be stashed on the addon for OpenConfig to read;
    -- OpenConfig delegates to the library now and the handle is the library's own
    -- business. What a host (and this suite) still needs is a handle on a live ctx,
    -- which is what the __panelFor test seam exists for.
    t.nilv(addon.optionsCategoryID, "the host no longer keeps a copy of the ID")
    t.eq(#NS.Helpers.__panels(), 4, "one ctx per sub-page, plus the landing page")
    -- Keyed by PAGE KEY, titled by the localized display name: the two are the same
    -- word on enUS and must not be assumed to be the same word anywhere else.
    for _, page in ipairs({ { "General", "General" }, { "Categories", L["Categories"] } }) do
        local pageCtx = NS.Helpers.__panelFor(page[1])
        t.truthy(pageCtx, page[1] .. " has a registered ctx")
        t.eq(pageCtx.panel.titleText,
            "Ka0s Pretty Chat |A:common-icon-forwardarrow:16:16|a " .. page[2],
            page[1] .. " renders the shared breadcrumb header")
    end
end)

test("sub-page frames start hidden and unbuilt", function()
    local fresh = ctx.loadAddon()
    local panel = panelFrame(fresh.env, "Categories")
    t.falsy(panel:IsShown(), "a registered page is hidden until Blizzard shows it")
    t.eq(#fresh.env._widgets, 0, "registration creates no AceGUI widgets at all")
end)

test("registration is a no-op on a client without the canvas Settings API", function()
    -- Built with the registrars missing from the START, not stripped afterwards:
    -- the library's CreateOptionsPanel is idempotent, so a post-hoc assignment plus
    -- a second call would return at the "already built" guard and the case would
    -- pass without ever reaching the branch it names.
    local fresh = ctx.loadAddon({
        mock = function(m) m.Settings = {} end,   -- API present, registrars absent
    })
    t.eq(#fresh.env._settings.categories, 0, "no canvas category was registered")
    t.eq(#fresh.env._settings.subcategories, 0, "and no sub-pages either")
    local ok = pcall(fresh.NS.Config.RegisterPanels)
    t.truthy(ok, "and calling it again never raises on such a client")
end)

test("a second CreateOptionsPanel is a no-op, not a second Blizzard category", function()
    -- The call is public and cheap to reach twice (a login plus a profile change).
    -- Re-running it would register a SECOND category for the same addon and append a
    -- second ctx per page, permanently doubling the refresh fan-out.
    local before  = #env._settings.categories
    local panels  = #NS.Helpers.__panels()
    NS.Config.RegisterPanels()
    t.eq(#env._settings.categories, before, "still exactly one parent category")
    t.eq(#NS.Helpers.__panels(), panels, "and no duplicate page contexts")
end)

-- ---- General sub-page ---------------------------------------------

test("the General page builds its controls on first show", function()
    local mark = #env._widgets
    generalPanel:Show()
    generalWidgets = widgetsSince(env, mark)

    t.truthy(#generalWidgets > 0, "showing the page built widgets")
    -- The three composed Master controls rows, by the labels the composer gives
    -- them. Nothing here is drawn by hand any more (options-ui-§15).
    t.truthy(byLabel(generalWidgets, "CheckBox", "Enable PrettyChat"), "master Enable checkbox")
    t.truthy(byLabel(generalWidgets, "Dropdown", "General visibility"), "visibility dropdown")
    t.truthy(byLabel(generalWidgets, "CheckBox", "Debug console"), "Debug console checkbox")
    t.truthy(byLabel(generalWidgets, "Button", L["Test"]), "Test button")
    t.truthy(byLabel(generalWidgets, "Button", "Reset all settings"), "the closing reset button")
    -- Every widget on this page is library-made, so their refreshers live on the
    -- page's ctx rather than in Schema.refreshers. General is the only page with no
    -- bespoke widgets at all.
    t.nilv(Schema.refreshers["General"], "no host refresher is registered for it")
    t.truthy(#NS.Helpers.__panelFor("General").refreshers > 0,
        "the library registered a refresher per widget it built")
end)

-- TEST AND RESET ALL SETTINGS ARE ONE ROW. Test used to sit on a row of its own
-- above the reset, because §15 fixes the reset's wording and the composer is the
-- only thing that writes it -- so putting them side by side meant either drawing
-- the pair here (a second copy of "Reset all settings" in this addon, which is
-- the drift the composer exists to end) or a seam in the library. It is the seam:
-- `leadButton` on MASTER_SPEC, shipped in LibKa0s v1.25.0 (OptionsCompose minor
-- 2), which puts the host's verb in the pair's empty right half -- the one cell
-- §15 leaves a frameless addon.
--
-- red under: drawing the pair in settings/Panel.lua again, or putting Test on the
-- right (the reset closes the tab).
test("the General page closes with [Test] [Reset all settings] on ONE row", function()
    local pair
    for _, w in ipairs(generalWidgets) do
        if w.type == "SimpleGroup" and w.children then
            local texts = {}
            for _, child in ipairs(w.children) do
                if child.type == "Button" then texts[#texts + 1] = child.text end
            end
            if #texts == 2 then pair = texts end
        end
    end
    t.truthy(pair, "the tab's closing buttons are not on one row")
    t.eq(pair[1], L["Test"], "the host's verb leads")
    t.eq(pair[2], "Reset all settings", "and the reset still closes the tab")
end)

test("the General page draws a strip whose first tab is Master controls", function()
    -- It used to draw NO strip at all: one group, one row, H.RenderRows. A page
    -- with one group still draws a one-tab strip (options-ui-§13), and this is the
    -- page the rule was written for. Dies if the page goes back to RenderRows or
    -- if the group is renamed out from under the afterGroup hook.
    t.eq(table.concat(tabNames("General"), ","), "Master controls",
        "one tab, and it is the canonical name")
    t.eq(NS.Helpers.__panelFor("General").activeTab, "Master controls",
        "and the page opens on it")
end)

test("the Debug console toggle is a schema row, not a bespoke session checkbox", function()
    -- MOVED, not duplicated. It was drawn through `pairWith` as an
    -- H.SessionCheckbox wired to the DebugLog descriptor; it is a composed row
    -- with one declaration now, and `grep -rn SessionCheckbox settings` finds only
    -- the degradation stub's no-op. Dies if a second declaration comes back.
    local box = byLabel(generalWidgets, "CheckBox", "Debug console")
    t.truthy(box, "the checkbox is on the page")
    local seen = 0
    for _, w in ipairs(generalWidgets) do
        if w.type == "CheckBox" and w.labelText == "Debug console" then seen = seen + 1 end
    end
    t.eq(seen, 1, "exactly one control over the console's visibility")
    t.truthy(Schema.FindByPath("state.debugConsole"), "and it is backed by a schema row")
end)

test("a second show does not rebuild the page", function()
    local mark = #env._widgets
    generalPanel:Show()
    t.eq(#env._widgets, mark, "the build is guarded by its rendered flag")
end)

test("the master checkbox is seeded from the schema, not assumed true", function()
    local fresh = ctx.loadAddon()
    fresh.NS.Schema.Set("General.enabled", false)
    local mark = #fresh.env._widgets
    panelFrame(fresh.env, "General"):Show()
    local enable = byLabel(widgetsSince(fresh.env, mark), "CheckBox", "Enable PrettyChat")
    t.eq(enable.value, false, "the checkbox opens showing the stored value")
end)

test("toggling the master checkbox writes through the single Schema path", function()
    local enable = byLabel(generalWidgets, "CheckBox", "Enable PrettyChat")
    local row = Schema.FindByPath("Loot.LOOT_ITEM_SELF.format")

    enable:Fire("OnValueChanged", false)
    t.eq(Schema.Get("General.enabled"), false, "the DB took the write")
    t.eq(env[row.globalName], "ORIG:" .. row.globalName,
        "and ApplyStrings restored the Blizzard originals")

    enable:Fire("OnValueChanged", true)
    t.eq(Schema.Get("General.enabled"), true, "toggling back re-enables")
    t.eq(env[row.globalName], row.default, "and re-applies the overrides")
end)

test("the Debug console checkbox drives the window, never the logging flag", function()
    local debugBox = byLabel(generalWidgets, "CheckBox", "Debug console")
    NS.State.debug = false

    debugBox:Fire("OnValueChanged", true)
    t.truthy(NS.DebugLog:IsShown(), "checking it shows the console window")
    t.falsy(NS.State.debug, "showing the window does not start logging")

    debugBox:Fire("OnValueChanged", false)
    t.falsy(NS.DebugLog:IsShown(), "unchecking hides it")
    t.falsy(NS.State.debug, "hiding it does not touch the flag either")
end)

test("the checkbox re-syncs when the console is opened another way", function()
    -- The console notifies the General page on show/hide, so the box mirrors
    -- window state however it was toggled (/pc debug, the × button, Esc).
    local debugBox = byLabel(generalWidgets, "CheckBox", "Debug console")
    NS.DebugLog:Show()
    t.eq(debugBox.value, true, "opening the window ticks the box")
    NS.DebugLog:Hide()
    t.eq(debugBox.value, false, "closing it unticks the box")
end)

test("the Test button writes the report to the console, never into chat", function()
    -- The report is 500+ lines with every category enabled, and the chat frame is
    -- the thing this addon exists to keep readable. The button opens the console
    -- and writes there -- and so does `/pc test` now (the case below). Dies if the
    -- sink argument is dropped and Test falls back to NS.Print for both callers.
    NS.DebugLog:Hide()
    NS.DebugLog:Clear()
    local before = #env.DEFAULT_CHAT_FRAME.messages
    byLabel(generalWidgets, "Button", L["Test"]):Fire("OnClick")

    t.eq(#env.DEFAULT_CHAT_FRAME.messages, before, "not one line went to chat")
    t.truthy(NS.DebugLog:IsShown(), "the console is opened, so the report is visible")
    t.truthy(NS.DebugLog:FindLine("sample of every format string"),
        "and the report's header is in the console buffer")
    t.truthy(NS.DebugLog:FindLine("end of test output"), "along with its footer")
    NS.DebugLog:Hide()
end)

test("/pc test writes the same report to the same place the button does", function()
    -- This case used to say the verb still printed the report to chat, and pinned the two callers
    -- DISAGREEING: the button opened the console, the verb put eighty-odd lines into the
    -- chat frame. One name, two acts. The sink is still a PARAMETER on Test rather than a
    -- redirection of NS.Print -- both callers simply pass the console writer now
    -- (settings/Panel.lua's PrettyChat:TestToConsole, which the verb routes through).
    -- Dies if the verb is pointed back at NS.Print, or if the filter stops reaching Test.
    NS.DebugLog:Hide()
    NS.DebugLog:Clear()
    local before = #env.DEFAULT_CHAT_FRAME.messages
    local name = Schema.FindByPath(
        "Loot." .. sortedNames("Loot")[1] .. ".format").globalName
    NS.SlashCommands:OnSlash("test formatstring " .. name)

    t.eq(#env.DEFAULT_CHAT_FRAME.messages, before, "not one line went to chat")
    t.truthy(NS.DebugLog:IsShown(), "the console is opened, as the button opens it")
    t.truthy(NS.DebugLog:FindLine("sample of every format string"),
        "and it is the same header the button produces")
    t.truthy(NS.DebugLog:FindLine(name),
        "the filter still narrows the report to the named format string")
    NS.DebugLog:Hide()
end)

test("Reset all asks for confirmation instead of resetting immediately", function()
    Schema.Set("Loot.enabled", false)
    byLabel(generalWidgets, "Button", "Reset all settings"):Fire("OnClick")
    t.eq(env._popupsShown[#env._popupsShown], "PRETTYCHAT_RESET_ALL",
        "the confirmation popup is raised")
    t.eq(Schema.Get("Loot.enabled"), false, "nothing is reset until the user accepts")

    local dialog = env.StaticPopupDialogs["PRETTYCHAT_RESET_ALL"]
    t.truthy(dialog, "the dialog is registered")
    t.eq(dialog.button1, env.YES, "accept button")
    t.eq(dialog.button2, env.NO, "decline button")
    dialog.OnAccept()
    t.eq(Schema.Get("Loot.enabled"), NS.Defaults.Loot.enabled,
        "accepting runs the same ResetAll the slash command does")
end)

-- ---- the lazily-built Defaults button ------------------------------

test("the Defaults button is deferred to first show, not built at registration", function()
    -- The deferral dodges the AceGUI skinning race (a button created during
    -- ADDON_LOADED keeps Blizzard's stock art for the session).
    local fresh = ctx.loadAddon()
    local panel = panelFrame(fresh.env, "Categories")
    t.truthy(panel.wantsDefaultsButton, "the page recorded the intent to have one")
    t.nilv(panel.defaultsBtn, "but no button exists before the first show")
    panel:Show()
    t.truthy(panel.defaultsBtn, "the first show builds it")
    t.eq(panel.defaultsBtn.type, "Button", "as an AceGUI Button (options-ui-§5)")
    t.eq(panel.defaultsBtn.text, L["Defaults"], "labeled Defaults")
end)

-- options-ui-§5 and §12: the General page has a header Defaults button, and it is
-- the same reset-all path as `Reset all settings` and `/pc resetall`, confirmation
-- included. A General-only reset would be a Defaults button doing less than the
-- reset beside it, which §12 forbids.
test("the General page declares a Defaults button whose click opens the reset-all popup", function()
    local fresh = ctx.loadAddon()
    local panel = panelFrame(fresh.env, "General")
    t.truthy(panel.wantsDefaultsButton, "General asks for a Defaults button")
    t.eq(panel.defaultsTooltip, fresh.NS.L["Reset every setting to its default."],
        "with the reset-all tooltip")
    panel:Show()
    t.truthy(panel.defaultsBtn, "the first show builds it")

    fresh.NS.Schema.Set("Loot.enabled", false)
    panel.defaultsBtn:Fire("OnClick")
    t.eq(fresh.env._popupsShown[#fresh.env._popupsShown], "PRETTYCHAT_RESET_ALL",
        "the click raises the reset-all confirmation")
    t.eq(fresh.NS.Schema.Get("Loot.enabled"), false, "and resets nothing until it is accepted")
end)

-- Run fn on a fresh instance's console and hand back its [Set] lines.
local function setLines(fresh, fn)
    local D = fresh.NS.DebugLog
    local wasDebug = fresh.NS.State.debug
    fresh.NS.State.debug = true
    fresh.NS.Debug("Test", "warm-up")
    D:Clear()
    local ok, err = pcall(fn)
    fresh.NS.State.debug = wasDebug
    if not ok then error(err, 0) end
    local out = {}
    for _, line in ipairs(D.buffer) do
        if line:find("[Set]", 1, true) then out[#out + 1] = line end
    end
    return out
end

-- options-ui-§13: the per-page Defaults button stays page-wide, and its blast
-- radius MUST NOT narrow to the visible tab. One batch over every category's
-- rows, so one pass and one `[Set] reset Categories: N rows` line.
--
-- red under: defaultsOnClick calling ResetCategory(activeCategory(ctx)).
test("the Categories Defaults button resets every category, not only the selected tab", function()
    local fresh = ctx.loadAddon()
    local S = fresh.NS.Schema
    local panel = panelFrame(fresh.env, "Categories")
    panel:Show()
    t.eq(fresh.NS.Helpers.__panelFor("Categories").activeTab, "Loot", "the Loot tab is selected")
    local lootG = sortedNames("Loot")[1]
    S.Set("Loot." .. lootG .. ".format", "CUSTOM")
    S.Set("Money.enabled", false)

    local lines = setLines(fresh, function() panel.defaultsOnClick() end)

    t.nilv(fresh.addon.db.profile.categories.Loot, "the selected tab's override is cleared")
    t.nilv(fresh.addon.db.profile.categories.Money, "and so is the other tab's")
    t.eq(#lines, 1, "exactly one [Set] line for the whole page")
    t.truthy(lines[1] and lines[1]:find("[Set] reset Categories: 2 rows", 1, true),
        "naming the page and counting the two changed rows: " .. tostring(lines[1]))
    t.eq(panel.defaultsBtn.text, fresh.NS.L["Defaults"], "the header button is the one wired")
    t.eq(panel.defaultsTooltip,
        fresh.NS.L["Reset the strings on every category tab to their defaults."],
        "and its tooltip names every tab")
end)

test("the footer OnDefault forwards to the same page-wide body", function()
    local fresh = ctx.loadAddon()
    local S = fresh.NS.Schema
    local panel = panelFrame(fresh.env, "Categories")
    panel:Show()
    S.Set("Loot.enabled", false)
    S.Set("Misc.enabled", false)

    local lines = setLines(fresh, function() panel.OnDefault() end)

    t.eq(S.Get("Loot.enabled"), fresh.NS.Defaults.Loot.enabled, "the selected tab is reset")
    t.eq(S.Get("Misc.enabled"), fresh.NS.Defaults.Misc.enabled, "and so is a tab never opened")
    t.eq(#lines, 1, "through the one batch")
    t.truthy(lines[1] and lines[1]:find("[Set] reset Categories:", 1, true), tostring(lines[1]))
end)

-- ---- parent page ----------------------------------------------------

test("the parent page lists every slash command through the one row formatter", function()
    local mark = #env._widgets
    parentPanel:Show()
    local widgets = widgetsSince(env, mark)

    local labels = {}
    for _, w in ipairs(widgets) do
        if w.type == "Label" and w.text then labels[#labels + 1] = w.text end
    end
    local joined = table.concat(labels, "\n")

    for _, entry in ipairs(NS.COMMANDS) do
        t.truthy(joined:find("/pc " .. entry[1], 1, true),
            ("the parent page lists /pc %s"):format(entry[1]))
        t.truthy(joined:find(entry[2], 1, true),
            ("with its description (/pc %s)"):format(entry[1]))
    end
    t.truthy(joined:find("/prettychat is an alias for /pc", 1, true), "the alias is documented")
    t.truthy(byLabel(widgets, "Heading", L["Slash Commands"]), "under a Slash Commands heading")

    -- Convergence #2. The panel row and the chat help row are now ONE formatter,
    -- differing only in the chat form's two-space indent — where this page used to
    -- carry double spaces around the dash, an explicitly white-wrapped dash and a
    -- bare description. Asserted as bytes, because the whole point is that the two
    -- surfaces can no longer drift.
    local slashLib = env.LibStub("LibKa0s-Slash-1.0", true)
    local first = NS.COMMANDS[1]
    local expected = slashLib.FormatRow("/pc " .. first[1], first[2])
    t.truthy(joined:find(expected, 1, true), "the row is lib.FormatRow's output verbatim")
    t.eq(NS.SlashCommands:HelpRows()[1], "  " .. expected,
        "and the chat form is the same row plus its two-space indent")
    t.falsy(joined:find("|r  " .. C.white, 1, true),
        "the old double-spaced, white-wrapped dash is gone")
end)

-- The whole reason the landing body is the library's renderer and not a copy of
-- it. A Texture is not an AceGUI child, so ReleaseChildren does not take it with
-- the group -- and AceGUI POOLS the group's frame. Without an OnRelease that
-- hides the texture, the next widget to acquire that frame inherits a 300px logo,
-- and the pool is shared with every other addon in the session, so the widget that
-- inherits it is very often not ours. The cross-addon half is docs/smoke-tests.md
-- PANEL-6; what a case can pin is that the release hook exists and does hide it.
test("the landing logo is hidden when its group goes back to AceGUI's pool", function()
    parentPanel:Show()

    local logoGroup
    for _, w in ipairs(env._widgets) do
        if w.type == "SimpleGroup" and w.height == 300 then logoGroup = w end
    end
    t.truthy(logoGroup, "the landing page draws a full-size group to carry the logo")

    local onRelease = logoGroup.callbacks and logoGroup.callbacks["OnRelease"]
    t.eq(type(onRelease), "function", "and registers an OnRelease on it")

    -- The mock's CreateTexture answers the frame itself, so the frame's shown-ness
    -- IS the texture's.
    t.truthy(logoGroup.frame:IsShown(), "the logo is shown while the page is up")
    logoGroup:Fire("OnRelease")
    t.falsy(logoGroup.frame:IsShown(), "and hidden the moment AceGUI takes the group back")
end)
test("the parent page shows the TOC tagline", function()
    local labels = {}
    for _, w in ipairs(env._widgets) do
        if w.type == "Label" and w.text then labels[#labels + 1] = w.text end
    end
    t.truthy(table.concat(labels, "\n"):find(ctx.mock.metadata.Notes, 1, true),
        "the TOC Notes line is rendered as the tagline")
end)
