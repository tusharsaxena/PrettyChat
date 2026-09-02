local addonName, NS = ...

-- settings/Panel.lua — the page BODIES, and nothing else.
--
-- The canvas factory, the header and its breadcrumb, the lazily-built Defaults
-- button, the AceGUI ScrollFrame with its always-shown-scrollbar patch, the
-- tooltip helper, the spacer helper, the page registry, the panel-open with its
-- combat gate and the refresh fan-out all live in LibKa0s-Options-1.0 now and are
-- reached through NS.Helpers (settings/OptionsSetup.lua). What is left here is the
-- part that is genuinely PrettyChat's: what each of its three kinds of page draws.
--
-- The landing page, the General page and BOTH of the Categories page's strips are
-- the library's own shapes: the primary one through H.TabStrip, the secondary one
-- (a tab per format string, inside the scroll) through H.SubTabStrip. The
-- per-string editor under a secondary tab is not, and that is the documented
-- deviation this file has carried since PC-23 — see buildStringRow.

local PrettyChat = LibStub("AceAddon-3.0"):GetAddon("PrettyChat")
local AceGUI = LibStub("AceGUI-3.0")

local H      = NS.Helpers
local Const  = NS.Const
local Color  = Const.Color
local Schema = NS.Schema
local L      = NS.L
local CATEGORY_ORDER = Schema.CATEGORY_ORDER

local TOC_NOTES = NS.Meta("Notes") or ""

local LOGO_PATH = "Interface\\AddOns\\" .. addonName
                  .. "\\media\\logos\\prettychat.logo.tga"
local LOGO_SIZE = 300

-- ---------------------------------------------------------------------
-- Reset-all popup. The OnAccept body lives in PrettyChat:ResetAll so the
-- popup, the General > "Reset all to defaults" button, and the
-- /pc resetall slash command share a single implementation.
-- ---------------------------------------------------------------------

StaticPopupDialogs["PRETTYCHAT_RESET_ALL"] = {
    -- THE COLLECTION'S ONE WORDING (options-ui-§12), verbatim. Addon-agnostic on
    -- purpose -- no addon enumerates its own nouns -- and explicit about the
    -- destruction. Eight phrasings of one act is how a collection reads as eight
    -- addons.
    text         = L["Reset this profile to the addon's defaults? Everything you have configured or added in it is discarded — your other profiles are not affected."],
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
    OnAccept     = function() PrettyChat:ResetAll() end,
}

-- The one way into the destructive path, so the confirmation cannot be walked
-- around. The composed Master controls block's `onResetAll` calls this
-- (settings/Schema.lua) rather than naming the popup, which is registered here.
function PrettyChat:ConfirmResetAll()
    StaticPopup_Show("PRETTYCHAT_RESET_ALL")
end

-- ---------------------------------------------------------------------
-- General sub-page — one tab, `Master controls`, and every addon-wide control on
-- it (options-ui-§15).
--
-- Nothing is drawn by hand here any more. The three rows — Enable PrettyChat,
-- General visibility, Debug console — are the COMPOSED block settings/Schema.lua
-- splices in at the head of this page (H.MasterControls), so this body is a strip
-- plus the group's closing acts. The bespoke SessionCheckbox that used to arrive
-- through `pairWith` is gone with it: the console toggle is a composed row like
-- every other control on the tab, and there is exactly one declaration of it.
--
-- A ONE-GROUP PAGE STILL DRAWS ITS STRIP. RenderTabbedSchema has done that since
-- OptionsWidgets minor 13, and this page is why the rule matters here: it used to
-- be the one page in the addon with no strip at all, which read as broken beside
-- the Categories page rather than as simpler.
-- ---------------------------------------------------------------------

-- The report the Test button writes, and where it writes it.
--
-- To the DEBUG CONSOLE, not to chat: `PrettyChat:Test()` prints one line per
-- format string plus a header and a footer — 500+ lines with every category
-- enabled — into the chat frame this addon exists to keep readable. The console
-- is a window with a scrollbar and a copy button, which is what a report that
-- long actually needs. `/pc test` is unchanged and still prints to chat, because
-- the sink is a PARAMETER on Test rather than a redirection of NS.Print.
local function runTestIntoConsole()
    NS.DebugLog:Show()
    PrettyChat:Test(nil, function(line) NS.DebugLog:Add("Test", line) end)
end

-- The Master controls group's closing acts, wired as its `afterGroup`. The
-- composer's own hook (Schema.masterAfterGroup) draws options-ui-§15's closing
-- button — "Reset all settings", ALONE, because a frameless addon has no "Reset
-- position" to pair it with — and Test sits above it: a preview verb no other
-- Ka0s addon has, which is exactly why the canonical block does not carry it.
local function generalAfterGroup(ctx)
    H.InlineButtonPair(ctx, {
        text    = L["Test"],
        tooltip = L["Print a sample of every active format string to the debug console, so you can see what real loot/currency/XP messages will look like. `/pc test` prints the same report to chat."],
        onClick = runTestIntoConsole,
    })
    Schema.masterAfterGroup(ctx)
end

local function buildGeneralBody(ctx)
    H.ClearScroll(ctx)
    local scroll = H.EnsureScroll(ctx)
    if not scroll then return end

    H.TextRow(ctx, L["Addon-wide controls. Enable is the master switch and General visibility is its second dimension — with either off, every Blizzard original is restored regardless of per-category settings."],
        { fontObject = "GameFontHighlight" })
    H.AddSpacer(scroll, H.ROW_VSPACER)

    -- The group NAME is the hook key (options-ui-§15). Renaming the group would
    -- detach the closing button and nothing would error, which is why the name
    -- comes off the library rather than being spelled out again here.
    H.RenderTabbedSchema(ctx, "General", { [H.MASTER_GROUP] = generalAfterGroup }, nil)
end

-- ---------------------------------------------------------------------
-- Per-string block.
--   [Enable]              | Original  [disabled EditBox]
--   GLOBALNAME (gray)     | New       [editable EditBox]
--   [Reset]               | Preview   [disabled EditBox, color rendered]
--
-- The Heading this block used to open with is GONE, replaced by the secondary
-- tab that selects it (options-ui-§13): one tab per string, drawn by
-- buildCategoryBody below. A heading repeating the name of the tab you are
-- standing on is the label options-ui-§7 calls a second name for one thing.
--
-- Two-column 40/60 split, drawn by hand rather than by the library's flow
-- engine. This is the documented deviation from options-ui-§6's 50/50 grid
-- (PC-23), and adopting LibKa0s-Options-1.0 did not change the reasoning: the
-- block is a domain-specific three-row CONTROL, not a row of independent
-- settings. The right column holds full format strings with their color
-- escapes and needs the extra width to stay legible; the left column only ever
-- holds a checkbox, a short GLOBALNAME caption and a Reset button.
--
-- RenderGrid is the library's caller-driven sibling of RenderRows and was
-- re-checked here before this was written: it lays items out two per row at
-- HALF (0.5) or full width and offers no third ratio, so it cannot express
-- 40/60 either. The makers are still used for what they fit — the category's
-- own Enable row above these blocks goes through RenderField — and
-- AttachTooltip, AddSpacer and EnsureScroll are the library's throughout.
--
-- Reset restores BOTH per-string dimensions (custom format + enable state) via
-- PrettyChat:ResetString, matching the category/all resets. The Preview EditBox
-- uses InputBoxTemplate, whose backing FontString renders WoW `|c…|r` color
-- escapes, so the rendered sample shows with its formatting intact.
-- ---------------------------------------------------------------------

local LEFT_W  = 0.4
local RIGHT_W = 0.6

local function buildStringRow(scroll, category, globalName, refreshers)
    local enabledPath = category .. "." .. globalName .. ".enabled"
    local formatPath  = category .. "." .. globalName .. ".format"

    -- Row 1: Enable | Original (disabled)
    local row1 = AceGUI:Create("SimpleGroup")
    row1:SetLayout("Flow")
    row1:SetFullWidth(true)

    local enable = AceGUI:Create("CheckBox")
    enable:SetLabel(L["Enable"])
    enable:SetRelativeWidth(LEFT_W)
    enable:SetCallback("OnValueChanged", function(_, _, value)
        NS.Schema.Set(enabledPath, value and true or false)
    end)

    local enableTooltip =
        L["Use the rewritten format for this message. When unchecked, Blizzard's original is used."]
    local sharedCats = Schema.crossRegisteredGlobals
                       and Schema.crossRegisteredGlobals[globalName]
    if sharedCats then
        local others = {}
        for _, c in ipairs(sharedCats) do
            if c ~= category then others[#others + 1] = c end
        end
        if #others > 0 then
            -- One localized sentence with a `%s`, not four concatenated
            -- fragments (localization-§1). The color escapes stay outside it so
            -- a translator never has to carry `|cff…|r` through.
            enableTooltip = enableTooltip
                .. "\n\n" .. Color.gray
                .. L["Shared with %s — both registrations write the same Blizzard global; the last category to apply wins on /reload."]
                     :format(table.concat(others, ", "))
                .. Color.reset
        end
    end
    H.AttachTooltip(enable, L["Enable"], enableTooltip)
    row1:AddChild(enable)

    local origInput = AceGUI:Create("EditBox")
    origInput:SetLabel(L["Original"])
    origInput:SetRelativeWidth(RIGHT_W)
    origInput:SetDisabled(true)
    -- The LIVE snapshot this client took at OnEnable, through the one reader
    -- `/pc test` also uses — not the shipped GlobalStrings/ dump, which is a
    -- build artifact of one client patch and drifts from what the game says
    -- (PC-R-04).
    local origValue = NS.OriginalFormat(PrettyChat, globalName)
                     or L["(original not available)"]
    -- Parenthesized: gsub returns (string, count) and SetText would otherwise be
    -- handed the count as a second argument (PC-R-10).
    origInput:SetText((origValue:gsub("|", "||")))
    H.AttachTooltip(origInput, L["Original Format String"],
        L["Blizzard's original format. Read-only."])
    row1:AddChild(origInput)
    scroll:AddChild(row1)

    -- Row 2: GLOBALNAME caption | New (editable)
    local row2 = AceGUI:Create("SimpleGroup")
    row2:SetLayout("Flow")
    row2:SetFullWidth(true)

    local captionLbl = AceGUI:Create("Label")
    captionLbl:SetRelativeWidth(LEFT_W)
    captionLbl:SetText(Color.gray .. globalName .. Color.reset)
    row2:AddChild(captionLbl)

    local newInput = AceGUI:Create("EditBox")
    newInput:SetLabel(L["New"])
    newInput:SetRelativeWidth(RIGHT_W)
    newInput:SetCallback("OnEnterPressed", function(_, _, value)
        NS.Schema.Set(formatPath, (value or ""):gsub("||", "|"))
    end)
    H.AttachTooltip(newInput, L["New Format String"],
        L["Your replacement. Type `||` for a literal `|` (color codes use this)."])
    row2:AddChild(newInput)
    scroll:AddChild(row2)

    -- Row 3: Reset | Preview (disabled, rendered with color escapes)
    local row3 = AceGUI:Create("SimpleGroup")
    row3:SetLayout("Flow")
    row3:SetFullWidth(true)

    local resetBtn = AceGUI:Create("Button")
    resetBtn:SetText(L["Reset"])
    resetBtn:SetRelativeWidth(LEFT_W)
    resetBtn:SetCallback("OnClick", function()
        PrettyChat:ResetString(category, globalName)
    end)
    H.AttachTooltip(resetBtn, L["Reset"],
        L["Restore this string to its default."])
    row3:AddChild(resetBtn)

    local previewInput = AceGUI:Create("EditBox")
    previewInput:SetLabel(L["Preview"])
    previewInput:SetRelativeWidth(RIGHT_W)
    previewInput:SetDisabled(true)
    H.AttachTooltip(previewInput, L["Preview"],
        L["The current format rendered with sample arguments."])
    row3:AddChild(previewInput)
    scroll:AddChild(row3)

    H.AddSpacer(scroll, Const.STRING_VSPACER)

    -- Refresh closure: re-syncs every widget in this block from the DB.
    -- Called on category-level changes (Enable toggled, Defaults pressed,
    -- /pc set, /pc reset). Programmatic SetValue/SetText on AceGUI
    -- widgets do NOT re-fire the user callbacks, so this is safe to call
    -- from within a callback chain.
    local function refresh()
        local current = NS.Schema.Get(formatPath)
        local addonEnabled = PrettyChat:IsAddonEnabled()
        local catEnabled   = PrettyChat:IsCategoryEnabled(category)
        local strEnabled   = PrettyChat:IsStringEnabled(category, globalName)

        enable:SetValue(strEnabled)
        enable:SetDisabled(not (addonEnabled and catEnabled))
        newInput:SetText(((current or ""):gsub("|", "||")))  -- parenthesized: no count
        newInput:SetDisabled(not (addonEnabled and catEnabled and strEnabled))

        local rendered, err = NS.RenderSample(current)
        previewInput:SetText(rendered or tostring(err))
    end

    refreshers[#refreshers + 1] = refresh
    refresh()
end

-- ---------------------------------------------------------------------
-- One category's body — the category's own Enable row, then a SECONDARY tab
-- strip with one tab per format string, then the selected string's editor.
--
-- The Enable row is a schema row and goes through the library's checkbox maker
-- at full width; it stays ABOVE the secondary strip, because it governs every
-- string in the category rather than the one on screen.
--
-- WHY A SECOND STRIP (options-ui-§13). A category tab used to be a vertical
-- stack of up to twenty three-row editors — Experience is twenty, Loot is
-- nineteen — so finding one string meant scrolling past every string sorted
-- before it, and the page was a wall of identical boxes. One tab per string
-- turns that into one click. It is drawn with H.SubTabStrip as ordinary content
-- INSIDE the scroll rather than as a second pinned band: a division that is not
-- page-wide must not push the whole page down twice, and the primary strip above
-- it is the one thing that is page-wide.
--
-- The selection is the HOST's state — the library reads `value` and calls
-- `onSelect` and never looks at either again — kept as ctx.activeSubTab, a TABLE
-- keyed by the primary tab's category. That is what makes leaving Loot for
-- Experience and coming back return to the string you were on. Session-only, and
-- never persisted: which string you last looked at is not a setting.
--
-- The scroll is the CALLER's, not this function's. It used to own the
-- ClearScroll/EnsureScroll pair because it was a whole page; it is one tab of
-- the Categories page today, drawn under a strip and under that page's footnote,
-- and a body that cleared the scroll itself would wipe the line above it.
-- ---------------------------------------------------------------------

-- Forward-declared: the secondary strip's onSelect re-renders the whole page,
-- which is the function that draws this one.
local buildCategoriesBody

-- The string on screen for one category, healed against a global that no longer
-- exists — the same stale-pointer guard activeCategory applies to the primary
-- strip, and for the same reason: a pointer at a missing string renders an empty
-- tab under a strip.
local function activeString(ctx, category, catData, sortedNames)
    ctx.activeSubTab = ctx.activeSubTab or {}
    local key = ctx.activeSubTab[category]
    if not (key and catData.strings[key]) then
        key = sortedNames[1]
    end
    ctx.activeSubTab[category] = key
    return key
end

local function buildCategoryBody(ctx, scroll, category, catData)
    local refreshers = {}

    -- relativeWidth nil => full width. The category toggle governs everything
    -- below it, so it reads as a page-level switch rather than as the left half
    -- of a pair.
    H.RenderField(ctx, Schema.FindByPath(category .. ".enabled"), scroll, nil)
    H.AddSpacer(scroll, H.ROW_VSPACER * 2)

    local sortedNames = {}
    for globalName in pairs(catData.strings) do
        sortedNames[#sortedNames + 1] = globalName
    end
    table.sort(sortedNames)

    local selected = activeString(ctx, category, catData, sortedNames)

    -- The strip's buttons are plain frames and need a frame to be parented to, so
    -- they ride an empty full-width SimpleGroup added to the scroll. Layout nil,
    -- because the library places every button itself and an AceGUI layout would
    -- fight it. ClearScroll drains the library's own ledger BEFORE it releases
    -- this group, so no button ever outlives the pooled frame it was parented to.
    local host = AceGUI:Create("SimpleGroup")
    host:SetLayout(nil)
    host:SetFullWidth(true)
    scroll:AddChild(host)

    local tabs = {}
    for i, globalName in ipairs(sortedNames) do
        -- The friendly label names the tab; the Blizzard GLOBALNAME is the
        -- tooltip, because it is what `/pc set` and `/pc test formatstring` take
        -- and the caption inside the block is no longer the only place to read it.
        tabs[i] = {
            key     = globalName,
            label   = catData.strings[globalName].label,
            tooltip = globalName,
        }
    end

    local _, stripHeight = H.SubTabStrip(ctx, host.frame, {
        tabs     = tabs,
        value    = selected,
        onSelect = function(key)
            if key == ctx.activeSubTab[category] then return end
            ctx.activeSubTab[category] = key
            buildCategoriesBody(ctx)
        end,
    })
    host:SetHeight(stripHeight or 0)
    H.AddSpacer(scroll, H.ROW_VSPACER)

    if selected then
        buildStringRow(scroll, category, selected, refreshers)
    end

    -- The bespoke block is invisible to the library's ctx.refreshers, so it
    -- registers through the schema's own dispatch. Schema.NotifyPanelChange drives
    -- both registries; see the comment there.
    Schema.RegisterRefresher(category, function()
        for _, fn in ipairs(refreshers) do pcall(fn) end
    end)
end

-- ---------------------------------------------------------------------
-- Categories sub-page — one PRIMARY tab per message category, and inside each,
-- one SECONDARY tab per format string (options-ui-§13).
--
-- Every category used to be a sub-page of its own: nine rows in the Blizzard
-- left rail for one addon, eight of which were the same page with a different
-- noun on it. They are one page and one tab strip now, and the rail carries
-- General, Categories and nothing else.
--
-- NOT H.RenderTabbedSchema, and that is the one thing to understand before
-- editing this. RenderTabbedSchema partitions a page's SCHEMA ROWS by `group`
-- and hands each partition to the flow engine; a category tab is one schema row
-- (the Enable) followed by a bespoke 40/60 editor the flow engine cannot express
-- (the options-ui-§6 deviation in docs/ARCHITECTURE.md). So the strip is taken
-- from the library directly through H.TabStrip and the body under it is still
-- buildCategoryBody, generated per category exactly as before. Every row on this
-- page still DECLARES its page and its group (settings/Schema.lua), so the
-- partition is readable and assertable even though the flow engine never sees it.
-- The tab click re-renders through the same ClearScroll-then-draw path
-- RenderTabbedSchema's own onSelect takes, for the same reason: redrawing
-- widgets inside an already-open panel was never a protected action, so the tab
-- click needs no combat guard and carries none.
-- ---------------------------------------------------------------------

-- The page KEY, which is the untranslated form of its display name (the rail and
-- the header show L["Categories"]). Taken off the schema rather than restated
-- here: every message-category row declares this page and this tab, and the two
-- spellings drifting apart is the kind of thing nothing would say out loud.
local CATEGORY_PAGE = Schema.CATEGORY_PAGE

-- The tabs, in strip order: CATEGORY_ORDER minus the virtual "General", which
-- is a page rather than a message category. Derived rather than restated, so
-- the strip, `/pc list` and `/pc test` cannot disagree about what comes first —
-- Loot leads because it is what a player opens this page to change, and Misc
-- trails because it is the drawer.
local TAB_ORDER = {}
for _, category in ipairs(CATEGORY_ORDER) do
    if category ~= "General" and NS.Defaults[category] then
        TAB_ORDER[#TAB_ORDER + 1] = category
    end
end

-- The visible tab, healed against a category that no longer exists — the same
-- stale-pointer guard RenderTabbedSchema applies to ctx.activeTab, and for the
-- same reason: a pointer at a missing group renders an empty page under a strip.
local function activeCategory(ctx)
    local key = ctx.activeTab
    if key and NS.Defaults[key] then return key end
    return TAB_ORDER[1]
end

function buildCategoriesBody(ctx)
    H.ClearScroll(ctx)
    local scroll = H.EnsureScroll(ctx)
    if not scroll then return end

    local category = activeCategory(ctx)
    ctx.activeTab = category

    -- Every tab's blocks close over widgets this render is about to release, and
    -- Schema.refreshers is keyed by CATEGORY rather than by page, so an entry left
    -- behind by the tab we just left is a closure pointed at released AceGUI
    -- widgets that a master-toggle change would still fan out to. Dropped here, at
    -- the one place that knows a tab is being replaced; buildCategoryBody
    -- re-registers the one that is now on screen.
    for _, name in ipairs(TAB_ORDER) do
        Schema.RegisterRefresher(name, nil)
    end

    local tabs = {}
    for i, name in ipairs(TAB_ORDER) do
        tabs[i] = { key = name, label = name }
    end
    H.TabStrip(ctx, {
        tabs     = tabs,
        value    = category,
        onSelect = function(key)
            if key == ctx.activeTab then return end
            ctx.activeTab = key
            buildCategoriesBody(ctx)
        end,
    })

    -- The page's one footnote, above the controls rather than after them: every
    -- switch and every format box on every tab is read only while the master
    -- Enable is on, and that switch is on another page. A player who turns a
    -- category on, sees nothing change in chat and has no sentence to explain it
    -- has been misled by the page.
    H.TextRow(ctx, Color.gray
        .. L["Strings on these tabs are rewritten only while the master Enable on the General page is on."]
        .. Color.reset)
    H.AddSpacer(scroll, H.ROW_VSPACER)

    buildCategoryBody(ctx, scroll, category, NS.Defaults[category])
end

-- ---------------------------------------------------------------------
-- Landing page — logo + tagline + slash-command list. Read-only, and the
-- host's half of the panel by design (options-ui-§5): the logo and the
-- command list are the two things about a Ka0s landing page that are
-- genuinely per-addon.
-- ---------------------------------------------------------------------

local function buildParentBody(ctx)
    H.ClearScroll(ctx)
    local scroll = H.EnsureScroll(ctx)
    if not scroll then return end

    -- Logo at native size, anchored TOPLEFT in a full-width SimpleGroup
    -- so AceGUI's List layout left-aligns it regardless of panel width.
    local logoGroup = AceGUI:Create("SimpleGroup")
    logoGroup:SetLayout(nil)
    logoGroup:SetFullWidth(true)
    logoGroup:SetHeight(LOGO_SIZE)

    -- Created ONCE PER FRAME, and stashed on it. This body used to run exactly once
    -- per session behind a `rendered` flag; under the library's renderer it runs
    -- again whenever the page is re-shown after being flagged dirty. A Texture is
    -- not an AceGUI child, so ReleaseChildren does not take it with it — and AceGUI
    -- POOLS the SimpleGroup's frame, so an un-owned Texture rides that frame into
    -- whichever widget acquires it next, in this addon or another. Re-texturing the
    -- one we already put there is both correct and free.
    local logoTex = logoGroup.frame.pcLogo
    if not logoTex then
        logoTex = logoGroup.frame:CreateTexture(nil, "ARTWORK")
        logoGroup.frame.pcLogo = logoTex
    end
    logoTex:SetTexture(LOGO_PATH)
    logoTex:SetSize(LOGO_SIZE, LOGO_SIZE)
    logoTex:ClearAllPoints()
    logoTex:SetPoint("TOPLEFT", logoGroup.frame, "TOPLEFT", 0, 0)
    logoTex:Show()
    scroll:AddChild(logoGroup)
    H.AddSpacer(scroll, H.ROW_VSPACER)

    if TOC_NOTES ~= "" then
        local tagline = AceGUI:Create("Label")
        tagline:SetFullWidth(true)
        tagline:SetText(TOC_NOTES)
        if tagline.label and tagline.label.SetFontObject and _G.GameFontHighlight then
            tagline.label:SetFontObject(_G.GameFontHighlight)
        end
        scroll:AddChild(tagline)
        H.AddSpacer(scroll, Const.SECTION_TOP_SPACER)
    end

    local heading = AceGUI:Create("Heading")
    heading:SetFullWidth(true)
    heading:SetHeight(H.SECTION_HEADING_H)
    heading:SetText(L["Slash Commands"])
    if heading.label and heading.label.SetFontObject and _G.GameFontNormalLarge then
        heading.label:SetFontObject(_G.GameFontNormalLarge)
    end
    scroll:AddChild(heading)
    H.AddSpacer(scroll, Const.SECTION_BOTTOM_SPACER)

    local alias = AceGUI:Create("Label")
    alias:SetFullWidth(true)
    alias:SetText(Color.gray .. L["/prettychat is an alias for /pc"] .. Color.reset)
    scroll:AddChild(alias)
    H.AddSpacer(scroll, H.ROW_VSPACER)

    -- Convergence #2: the landing page and the chat help index render the same
    -- COMMANDS table through the SAME formatter, differing only in indentation
    -- (slash-commands-§4). This page used to carry its own — double spaces either
    -- side of the em dash, the dash explicitly white-wrapped, the description bare —
    -- which is the silent drift between settings/Panel.lua and settings/Slash.lua
    -- that every addon in the collection had. Collapsing it changes what a user
    -- sees: single spaces, no color span on the dash, and a white description.
    -- Colon: LibKa0s-Slash-1.0 declares `function Sl:LandingRows()`, so a dot
    -- call passes no `self` and works only because today's body ignores it
    -- (PC-R-08). The degradation stub in settings/Slash.lua is a method too.
    for _, line in ipairs(NS.SlashCommands:LandingRows()) do
        local row = AceGUI:Create("Label")
        row:SetFullWidth(true)
        row:SetText(line)
        scroll:AddChild(row)
    end
end

-- ---------------------------------------------------------------------
-- Page registration
--
-- Each page registers its builder at FILE LOAD; the library drains the queue at
-- CreateOptionsPanel time, after the DB is ready. Each builder creates its
-- canvas, declares how the page renders itself through SetRenderer — which owns
-- the first-OnShow deferral, the every-OnShow Defaults button and the combat
-- refusal — and hands the frame to Blizzard.
-- ---------------------------------------------------------------------

-- Two pages, registered in rail order: the addon-wide switches first, then
-- everything this addon rewrites. The eight per-category registrations this loop
-- used to run are one page with eight tabs (buildCategoriesBody above).
H.RegisterOptionsPage("General", "General", function(mainCategory)
    local ctx = H.CreatePanel(nil, "General", {
        pageKey        = "General",
        defaultsButton = false,
    })
    H.SetRenderer(ctx, buildGeneralBody)
    return Settings.RegisterCanvasLayoutSubcategory(mainCategory, ctx.panel, "General")
end)

H.RegisterOptionsPage(CATEGORY_PAGE, CATEGORY_PAGE, function(mainCategory)
    local ctx = H.CreatePanel(nil, L["Categories"], {
        pageKey        = CATEGORY_PAGE,
        defaultsButton = true,
        -- One button, eight tabs, so the sentence names the SELECTED tab rather
        -- than a category. It replaces the per-page `Reset all %s strings to
        -- defaults.` this addon carried while every category was its own page:
        -- that string is built at CreatePanel time and the button is built once,
        -- on first show, so a per-category wording here could only ever name the
        -- tab the page happened to open on.
        defaultsTooltip = L["Reset the strings on the selected category tab to their defaults."],
    })

    -- Parked for the library to wire onto the Defaults button on first OnShow,
    -- and forwarded to by the panel's OnDefault so the Settings window's own
    -- footer control reaches the same body (options-ui-§1). It reads the ACTIVE
    -- tab at click time rather than closing over one category, because the button
    -- is wired once and the strip moves underneath it.
    --
    -- PrettyChat:ResetCategory rather than the library's row-by-row
    -- RestoreDefaults: it wipes the category's table and re-applies in ONE pass
    -- with ONE [Reset] summary line, where the row-by-row form would run
    -- ApplyStrings once per row and emit one [Set] line per row into a 1500-line
    -- console buffer (debug-logging-§9).
    ctx.panel.defaultsOnClick = function()
        PrettyChat:ResetCategory(activeCategory(ctx))
    end

    H.SetRenderer(ctx, buildCategoriesBody)
    return Settings.RegisterCanvasLayoutSubcategory(mainCategory, ctx.panel, L["Categories"])
end)

NS.Config = NS.Config or {}
NS.Config.BuildMain      = buildParentBody
NS.Config.RegisterPanels = function() H.CreateOptionsPanel() end
