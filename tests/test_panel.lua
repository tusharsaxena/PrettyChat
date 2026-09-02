-- tests/test_panel.lua — settings/Panel.lua, the addon's largest module.
--
-- The panel's testable contract is *wiring*, not pixels: which widget exists,
-- what it is seeded from, which schema path its callback writes through, and
-- when it is built. The AceGUI/frame mocks model exactly that (widget type,
-- label, value, disabled, callbacks, child order, shown-ness), so these cases
-- drive the real registration + first-OnShow build path. Layout, fonts and
-- skinning stay in docs/smoke-tests.md.

local function panelFrame(env, name)
    for _, sub in ipairs(env._settings.subcategories) do
        if sub.name == name then return sub.frame end
    end
end

local function widgetsSince(env, mark)
    local out = {}
    for i = mark + 1, #env._widgets do out[#out + 1] = env._widgets[i] end
    return out
end

local function firstOfType(list, wtype)
    for _, w in ipairs(list) do
        if w.type == wtype then return w end
    end
end

local function byLabel(list, wtype, label)
    for _, w in ipairs(list) do
        if w.type == wtype and (w.labelText == label or w.text == label) then return w end
    end
end

-- The ONE per-string editor a category tab draws. Every string is a secondary
-- TAB now, so the page holds the selected string's three populated Flow rows and
-- nothing else. Spacers and the sub-strip's own host are childless SimpleGroups
-- and are skipped; the category Enable checkbox is added straight to the scroll
-- rather than into a row, so it is skipped too.
local function stringBlock(scroll)
    local rows = {}
    for _, child in ipairs(scroll.children) do
        if child.type == "SimpleGroup" and #child.children > 0 then
            rows[#rows + 1] = child
        end
    end
    return { rows = rows }
end

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

-- OnEnable already ran registerPanels; each page builds its body on first
-- OnShow, so the suite shows a page and then reads the widgets it created.
local generalPanel    = panelFrame(env, "General")
-- Every message category is a TAB on this one page now, and Loot is the first of
-- them, so a Categories page nobody has clicked is a Loot page.
local categoriesPanel = panelFrame(env, "Categories")
local parentPanel     = env._settings.categories[1] and env._settings.categories[1].frame

local generalWidgets, lootWidgets, lootScroll, lootBlock

-- The tab strip's buttons, in strip order, off the library's own ctx layout.
-- They are plain Blizzard frames rather than AceGUI widgets, so env._widgets
-- never sees them.
local function tabButtons(pageKey)
    local layout = NS.Helpers.__panelFor(pageKey).__tabLayout
    return layout and layout.buttons or {}
end

local function tabNames(pageKey)
    local names = {}
    for i, b in ipairs(tabButtons(pageKey)) do names[i] = b.text end
    return names
end

-- The SECONDARY strip's buttons, in strip order, off the library's own ledger.
-- Like the primary strip's they are plain Blizzard frames, so env._widgets never
-- sees them; unlike the primary strip's they live inside the scroll.
local function subTabButtons(pageKey)
    return NS.Helpers.__panelFor(pageKey).__subTabKids or {}
end

local function subTabNames(pageKey)
    local names = {}
    for i, b in ipairs(subTabButtons(pageKey)) do names[i] = b.text end
    return names
end

-- The category's global names in the order the strip offers them, which is the
-- order the blocks used to be stacked in: sorted.
local function sortedNames(category)
    local out = {}
    for globalName in pairs(NS.Defaults[category].strings) do out[#out + 1] = globalName end
    table.sort(out)
    return out
end

-- ---- registration -------------------------------------------------

test("registration builds the parent category and two sub-pages", function()
    -- The left rail used to carry nine rows, eight of which were the same page
    -- with a different noun on it. It carries two: the addon-wide switches, and
    -- everything this addon rewrites (one tab per message category).
    t.eq(#env._settings.categories, 1, "exactly one canvas parent category")
    t.eq(env._settings.categories[1].name, "Ka0s Pretty Chat", "the parent carries the brand title")
    t.eq(#env._settings.addonCategories, 1, "the parent is added to the AddOns list")
    t.eq(#env._settings.subcategories, 2, "two sub-pages, not one per category")
    t.eq(env._settings.subcategories[1].name, "General", "General leads the rail")
    t.eq(env._settings.subcategories[2].name, L["Categories"], "and Categories follows it")
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
    t.eq(#NS.Helpers.__panels(), 3, "one ctx per sub-page, plus the landing page")
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
    -- and writes there; `/pc test` is unchanged (the case below). Dies if the sink
    -- argument is dropped and Test falls back to NS.Print for both callers.
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

test("/pc test still prints the same report to chat", function()
    -- The sink is a PARAMETER on Test, not a redirection of NS.Print, so the slash
    -- verb is untouched. Dies if the console writer is wired into NS.Print or into
    -- Test's default.
    local before = #env.DEFAULT_CHAT_FRAME.messages
    NS.SlashCommands:OnSlash("test formatstring " .. Schema.FindByPath(
        "Loot." .. sortedNames("Loot")[1] .. ".format").globalName)
    t.truthy(#env.DEFAULT_CHAT_FRAME.messages > before, "the slash verb emits to chat")
    t.truthy(env.DEFAULT_CHAT_FRAME.messages[before + 1]
        :find("sample of every format string", 1, true), "and it is the same header")
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

test("the General page has no Defaults button", function()
    t.falsy(generalPanel.wantsDefaultsButton, "General opts out")
    t.nilv(generalPanel.defaultsBtn, "and none is built for it")
end)

test("the Defaults button resets the visible tab's category only", function()
    -- One button over eight tabs, so it has to resolve the tab at CLICK time. It
    -- is wired once, on the page's first show, and the strip moves underneath it.
    local fresh = ctx.loadAddon()
    fresh.NS.Schema.Set("Loot.enabled", false)
    fresh.NS.Schema.Set("Money.enabled", false)
    local panel = panelFrame(fresh.env, "Categories")
    panel:Show()
    panel.defaultsBtn:Fire("OnClick")
    t.eq(fresh.NS.Schema.Get("Loot.enabled"), fresh.NS.Defaults.Loot.enabled,
        "the visible tab's category is reset")
    t.eq(fresh.NS.Schema.Get("Money.enabled"), false, "other categories are untouched")

    -- Move the strip and the same button follows it.
    local pageCtx = fresh.NS.Helpers.__panelFor("Categories")
    for _, b in ipairs(pageCtx.__tabLayout.buttons) do
        if b.text == "Money" then b:FireScript("OnClick") end
    end
    t.eq(pageCtx.activeTab, "Money", "the click moved the strip")
    fresh.NS.Schema.Set("Loot.enabled", false)
    panel.defaultsBtn:Fire("OnClick")
    t.eq(fresh.NS.Schema.Get("Money.enabled"), fresh.NS.Defaults.Money.enabled,
        "the button now resets the tab the player is looking at")
    t.eq(fresh.NS.Schema.Get("Loot.enabled"), false, "and leaves the tab they left alone")
end)

-- ---- category sub-page + per-string rows ---------------------------

test("a category tab builds a toggle, a secondary strip, and ONE string block", function()
    local mark = #env._widgets
    -- Already shown by the strip case above, so re-render it the way a tab click
    -- does rather than relying on an OnShow that will not fire twice.
    NS.Helpers.RefreshPanel(NS.Helpers.__panelFor("Categories"), true)
    lootWidgets = widgetsSince(env, mark)
    -- Off the ctx, not out of the new widgets: the ScrollFrame is created once per
    -- page and REUSED across tab switches (ClearScroll releases its children, not
    -- the container), so a re-render adds no ScrollFrame to find.
    lootScroll  = NS.Helpers.__panelFor("Categories").scroll
    lootBlock   = stringBlock(lootScroll)

    local strings = #sortedNames("Loot")

    t.truthy(byLabel(lootWidgets, "CheckBox", "Enable Loot"), "the category master toggle")
    -- The nineteen editors this tab used to stack are nineteen SECONDARY TABS,
    -- and exactly one of them is drawn (options-ui-§13). Dies if the strip is
    -- removed and the blocks are stacked again.
    t.eq(#subTabButtons("Categories"), strings, "one secondary tab per registered string")
    t.eq(#lootBlock.rows, 3, "and one string block on screen, not nineteen")
    t.truthy(Schema.refreshers["Loot"], "the page registered its refresher")
end)

test("the category Enable stays ABOVE the secondary strip", function()
    -- It governs every string in the category rather than the one on screen, so it
    -- must not read as part of the selected string's block.
    local order = {}
    for _, child in ipairs(lootScroll.children) do order[#order + 1] = child end
    local enableAt, hostAt
    for i, child in ipairs(order) do
        if child.type == "CheckBox" and child.labelText == "Enable Loot" then enableAt = i end
        -- The strip's host: a full-width SimpleGroup with no AceGUI children and a
        -- height the strip measured, which no spacer has.
        if not hostAt and child.type == "SimpleGroup" and #child.children == 0
           and (child.height or 0) > 0 and enableAt then hostAt = i end
    end
    t.truthy(enableAt, "the category toggle is on the page")
    t.truthy(hostAt, "and so is the secondary strip")
    t.truthy(enableAt < hostAt, "with the toggle above it")
end)

test("secondary tabs are offered in sorted global-name order", function()
    local sorted = sortedNames("Loot")
    local labels = {}
    for i, globalName in ipairs(sorted) do
        labels[i] = NS.Defaults.Loot.strings[globalName].label
    end
    t.eq(table.concat(subTabNames("Categories"), "|"), table.concat(labels, "|"),
        "the strip is the same sorted order the stack of blocks used to be")
end)

test("clicking a secondary tab swaps the string block under it", function()
    -- The selection is the HOST's state — ctx.activeSubTab, a table keyed by the
    -- primary tab — and the library only reports the click. Dies if the key stops
    -- being per-category, or if onSelect stops re-rendering.
    local pageCtx = NS.Helpers.__panelFor("Categories")
    local sorted  = sortedNames("Loot")
    subTabButtons("Categories")[2]:FireScript("OnClick")

    t.eq(pageCtx.activeSubTab.Loot, sorted[2], "the pointer moved to the second string")
    local caption = stringBlock(pageCtx.scroll).rows[2].children[1]
    t.truthy(caption.text:find(sorted[2], 1, true), "and the block under it is that string's")

    -- Back to the first, which is what every case below reads.
    subTabButtons("Categories")[1]:FireScript("OnClick")
    lootScroll = pageCtx.scroll
    lootBlock  = stringBlock(lootScroll)
    t.eq(pageCtx.activeSubTab.Loot, sorted[1], "and back again")
end)

test("the string you were on is remembered per category, and heals when stale", function()
    local fresh = ctx.loadAddon()
    panelFrame(fresh.env, "Categories"):Show()
    local pageCtx = fresh.NS.Helpers.__panelFor("Categories")
    local lootSorted = {}
    for g in pairs(fresh.NS.Defaults.Loot.strings) do lootSorted[#lootSorted + 1] = g end
    table.sort(lootSorted)

    -- Move to Loot's third string, leave for Money, come back.
    local third = pageCtx.__subTabKids[3]
    third:FireScript("OnClick")
    t.eq(pageCtx.activeSubTab.Loot, lootSorted[3], "the pointer moved")
    for _, b in ipairs(pageCtx.__tabLayout.buttons) do
        if b.text == "Money" then b:FireScript("OnClick") end
    end
    t.eq(pageCtx.activeTab, "Money", "the primary strip moved")
    for _, b in ipairs(pageCtx.__tabLayout.buttons) do
        if b.text == "Loot" then b:FireScript("OnClick") end
    end
    t.eq(pageCtx.activeSubTab.Loot, lootSorted[3],
        "and Loot came back to the string it was left on")
    t.truthy(pageCtx.activeSubTab.Money, "Money kept a pointer of its own")

    -- A pointer at a string that no longer exists renders an empty tab under a
    -- strip, so it heals to the first rather than being trusted.
    pageCtx.activeSubTab.Loot = "PRETTYCHAT_NO_SUCH_GLOBAL"
    fresh.NS.Helpers.RefreshPanel(pageCtx, true)
    t.eq(pageCtx.activeSubTab.Loot, lootSorted[1], "a stale pointer heals to the first string")
end)

test("the string block is the documented three-row 40/60 editor", function()
    local block = lootBlock
    t.eq(#block.rows, 3, "three rows per string")

    local enable, orig = block.rows[1].children[1], block.rows[1].children[2]
    local caption, new = block.rows[2].children[1], block.rows[2].children[2]
    local reset, preview = block.rows[3].children[1], block.rows[3].children[2]

    t.eq(enable.type, "CheckBox",  "row 1 left: Enable checkbox")
    t.eq(orig.type,   "EditBox",   "row 1 right: Original")
    t.eq(caption.type, "Label",    "row 2 left: GLOBALNAME caption")
    t.eq(new.type,    "EditBox",   "row 2 right: New")
    t.eq(reset.type,  "Button",    "row 3 left: Reset")
    t.eq(preview.type, "EditBox",  "row 3 right: Preview")

    t.eq(enable.relativeWidth, 0.4, "left column is 40%")
    t.eq(orig.relativeWidth,   0.6, "right column is 60%")
    t.truthy(orig.disabled,    "Original is read-only")
    t.truthy(preview.disabled, "Preview is read-only")
    t.falsy(new.disabled,      "New is editable while the string is enabled")
end)

test("the read-only Original row shows this client's snapshot, or degrades without it", function()
    -- PC-R-04: the Original box and `/pc test`'s Original line answer the same
    -- question and used to read different sources — the box read the shipped
    -- GlobalStrings/ dump (a build artifact of one client patch), the slash verb
    -- read the OnEnable snapshot of what THIS client loaded. Both go through
    -- NS.OriginalFormat now. The harness seeds every registered global as
    -- "ORIG:<NAME>" before OnEnable, so that is what the box must show.
    local sorted = {}
    for globalName in pairs(NS.Defaults.Loot.strings) do sorted[#sorted + 1] = globalName end
    table.sort(sorted)
    local first = sorted[1]
    local orig = lootBlock.rows[1].children[2]

    t.eq(addon.originalStrings[first], "ORIG:" .. first, "the snapshot holds this client's value")
    t.eq(orig.text, (addon.originalStrings[first]:gsub("|", "||")),
        "the snapshot is what the box shows, pipe-doubled")
    -- "ORIG:<NAME>" is a sentinel only tests/loader.lua's seeding produces, so
    -- the assertion above cannot pass by reading anything else. And the dump the
    -- box used to read is not even loaded now — PrettyChat.toc dropped the 26
    -- chunks once nothing in the addon read them (PC-R-05).
    t.nilv(NS.GlobalStrings, "the shipped GlobalStrings/ dump is not loaded at all")

    -- Degradation: a string registered since the last /reload has no snapshot
    -- entry and no live global — the load-time-snapshot limitation ARCHITECTURE
    -- records. The box shows the localized placeholder rather than nil.
    local fresh = ctx.loadAddon()
    local LATE = "PRETTYCHAT_REGISTERED_AFTER_SNAPSHOT"
    fresh.NS.Defaults.Loot.strings[LATE] =
        { label = "Registered after the snapshot", default = "a format with no conversions" }
    t.nilv(fresh.addon.originalStrings[LATE], "the snapshot never saw it")
    t.nilv(fresh.env[LATE], "and no live global carries it either")

    panelFrame(fresh.env, "Categories"):Show()
    -- Its own secondary TAB now rather than its own block in a stack, so the tab
    -- has to be clicked before the block exists to read.
    local pageCtx = fresh.NS.Helpers.__panelFor("Categories")
    local lateLabel = fresh.NS.Defaults.Loot.strings[LATE].label
    for _, b in ipairs(pageCtx.__subTabKids) do
        if b.text == lateLabel then b:FireScript("OnClick") end
    end
    t.eq(pageCtx.activeSubTab.Loot, LATE, "the late registration was offered as its own tab")
    local lateOrig = stringBlock(pageCtx.scroll).rows[1].children[2]
    t.eq(lateOrig.text, L["(original not available)"], "the placeholder is shown instead")
end)

test("the per-string checkbox writes the string's enable path", function()
    local sorted = {}
    for globalName in pairs(NS.Defaults.Loot.strings) do sorted[#sorted + 1] = globalName end
    table.sort(sorted)
    local globalName = sorted[1]
    local enable = lootBlock.rows[1].children[1]

    enable:Fire("OnValueChanged", false)
    t.eq(Schema.Get("Loot." .. globalName .. ".enabled"), false, "the DB took the write")
    t.eq(env[globalName], "ORIG:" .. globalName, "and the Blizzard original was restored")

    enable:Fire("OnValueChanged", true)
    t.eq(env[globalName], Schema.Get("Loot." .. globalName .. ".format"),
        "re-enabling re-applies the override")
end)

test("the New edit box unescapes || to | before storing", function()
    -- The panel shows `||` for a literal pipe (the same convention /pc set
    -- accepts), so the stored format must be the single-pipe form.
    local sorted = {}
    for globalName in pairs(NS.Defaults.Loot.strings) do sorted[#sorted + 1] = globalName end
    table.sort(sorted)
    local globalName = sorted[1]
    local newInput = lootBlock.rows[2].children[2]

    newInput:Fire("OnEnterPressed", "||cffff0000Custom|| %s")
    t.eq(Schema.Get("Loot." .. globalName .. ".format"), "|cffff0000Custom| %s",
        "doubled pipes collapse to literal pipes on the way in")
    t.eq(newInput.text, "||cffff0000Custom|| %s",
        "and the refresh re-doubles them for display")
end)

test("the Preview box renders the live format with sample arguments", function()
    local newInput = lootBlock.rows[2].children[2]
    local preview  = lootBlock.rows[3].children[2]
    newInput:Fire("OnEnterPressed", "You got %s x%d")
    t.eq(preview.text, NS.RenderSample("You got %s x%d"), "preview matches the shared renderer")
    t.eq(preview.text, "You got Sample x42", "with the documented placeholder values")
end)

test("the Preview box surfaces an unrenderable format instead of blanking", function()
    local newInput = lootBlock.rows[2].children[2]
    local preview  = lootBlock.rows[3].children[2]
    newInput:Fire("OnEnterPressed", "%y")
    t.truthy((preview.text or ""):find("invalid", 1, true)
          or (preview.text or "") ~= "", "the format error is shown in the preview box")
end)

test("the per-string Reset button restores both dimensions", function()
    local sorted = {}
    for globalName in pairs(NS.Defaults.Loot.strings) do sorted[#sorted + 1] = globalName end
    table.sort(sorted)
    local globalName = sorted[1]
    local block = lootBlock

    block.rows[1].children[1]:Fire("OnValueChanged", false)
    block.rows[2].children[2]:Fire("OnEnterPressed", "CUSTOM %s")
    block.rows[3].children[1]:Fire("OnClick")

    t.truthy(addon:IsStringEnabled("Loot", globalName), "reset re-enables the string")
    t.eq(Schema.Get("Loot." .. globalName .. ".format"),
        NS.Defaults.Loot.strings[globalName].default, "and restores the default format")
    t.eq(block.rows[1].children[1].value, true, "the checkbox re-syncs")
    t.eq(block.rows[2].children[2].text,
        NS.Defaults.Loot.strings[globalName].default:gsub("|", "||"),
        "the New box re-syncs, pipe-doubled")
end)

test("disabling the category grays the per-string controls", function()
    local block  = lootBlock
    local catBox = byLabel(lootWidgets, "CheckBox", "Enable Loot")

    catBox:Fire("OnValueChanged", false)
    t.truthy(block.rows[1].children[1].disabled, "the per-string Enable box grays out")
    t.truthy(block.rows[2].children[2].disabled, "the New format box grays out")

    catBox:Fire("OnValueChanged", true)
    t.falsy(block.rows[1].children[1].disabled, "re-enabling restores them")
    t.falsy(block.rows[2].children[2].disabled, "including the format box")
end)

test("a master-toggle change refreshes every built page, not just its own", function()
    -- NotifyPanelChange(nil/"General") fans out to all refreshers because
    -- per-string disabled state depends on the master switch.
    local block = lootBlock
    Schema.Set("General.enabled", false)
    t.truthy(block.rows[1].children[1].disabled,
        "the Loot page grayed out from a General-page write")
    Schema.Set("General.enabled", true)
    t.falsy(block.rows[1].children[1].disabled, "and came back")
end)

test("a slash-command write re-syncs the open panel", function()
    -- The panel and /pc share one write path, so either surface updates the other.
    local sorted = {}
    for globalName in pairs(NS.Defaults.Loot.strings) do sorted[#sorted + 1] = globalName end
    table.sort(sorted)
    local globalName = sorted[1]

    NS.Schema.Set("Loot." .. globalName .. ".format", "FROM SLASH %s")
    t.eq(lootBlock.rows[2].children[2].text, "FROM SLASH %s",
        "the New box shows the value the slash command stored")
    addon:ResetAll()
end)

test("a cross-registered string warns about the shared Blizzard global", function()
    -- Two categories writing the same _G key is surfaced in-page rather
    -- than discovered through lost edits.
    local shared = next(Schema.crossRegisteredGlobals)
    t.truthy(shared, "the defaults register at least one shared global")

    local sorted = {}
    for globalName in pairs(NS.Defaults.Loot.strings) do sorted[#sorted + 1] = globalName end
    table.sort(sorted)
    local index
    for i, globalName in ipairs(sorted) do
        if Schema.crossRegisteredGlobals[globalName] then index = i break end
    end
    t.truthy(index, "one of them lives on the Loot page")

    -- One block on screen, so the shared string's secondary tab is selected first.
    local pageCtx = NS.Helpers.__panelFor("Categories")
    subTabButtons("Categories")[index]:FireScript("OnClick")
    local sharedBlock = stringBlock(pageCtx.scroll)

    env.GameTooltip.lines = nil
    sharedBlock.rows[1].children[1]:Fire("OnEnter")
    local joined = table.concat(env.GameTooltip.lines or {}, "\n")
    t.truthy(joined:find("Shared with", 1, true), "the tooltip names the conflict")
    t.truthy(joined:find("last category to apply wins", 1, true),
        "and explains the documented last-writer rule")
end)

test("the page says its controls are read only while the master switch is on", function()
    -- The footnote the strip earns: every switch and every format box on every tab
    -- is dead while the master Enable is off, and that toggle lives on another
    -- page. Above the controls, not after them.
    local labels = {}
    for _, child in ipairs(lootScroll.children) do
        if child.type == "Label" and child.text then labels[#labels + 1] = child.text end
    end
    t.truthy(labels[1] and labels[1]:find(
        L["Strings on these tabs are rewritten only while the master Enable on the General page is on."],
        1, true), "the note is the first thing on the page")
end)

test("clicking a tab swaps the body and drops the tab it left", function()
    -- The stale-refresher half is the one that bites in game rather than on
    -- screen: Schema.refreshers is keyed by CATEGORY, not by page, so an entry the
    -- previous tab left behind is a closure over released AceGUI widgets that the
    -- next master-toggle change would still fan out to.
    local money
    for _, b in ipairs(tabButtons("Categories")) do
        if b.text == "Money" then money = b end
    end
    t.truthy(money, "the strip carries a Money tab")

    local mark = #env._widgets
    money:FireScript("OnClick")
    t.eq(NS.Helpers.__panelFor("Categories").activeTab, "Money", "the strip moved")
    t.truthy(byLabel(widgetsSince(env, mark), "CheckBox", "Enable Money"),
        "and the body under it is Money's")
    t.eq(#subTabButtons("Categories"), 8, "with one secondary tab per Money string")
    t.eq(#stringBlock(lootScroll).rows, 3, "and one string block under them")
    t.nilv(Schema.refreshers["Loot"], "the tab we left unregistered its refresher")
    t.truthy(Schema.refreshers["Money"], "and the tab we arrived on registered one")

    -- Clicking the tab you are already on cannot re-render the page you are
    -- already looking at: the active tab is the DISABLED button, and the handler
    -- refuses a second time for a harness that can fire a disabled script anyway.
    local again = #env._widgets
    money:FireScript("OnClick")
    t.eq(#env._widgets, again, "re-clicking the active tab draws nothing")
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

test("the parent page shows the TOC tagline", function()
    local labels = {}
    for _, w in ipairs(env._widgets) do
        if w.type == "Label" and w.text then labels[#labels + 1] = w.text end
    end
    t.truthy(table.concat(labels, "\n"):find(ctx.mock.metadata.Notes, 1, true),
        "the TOC Notes line is rendered as the tagline")
end)
