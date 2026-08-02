local addonName, NS = ...

-- settings/Panel.lua — the three page BODIES, and nothing else.
--
-- The canvas factory, the header and its breadcrumb, the lazily-built Defaults
-- button, the AceGUI ScrollFrame with its always-shown-scrollbar patch, the
-- tooltip helper, the spacer helper, the page registry, the panel-open with its
-- combat gate and the refresh fan-out all live in LibKa0s-Options-1.0 now and are
-- reached through NS.Helpers (settings/OptionsSetup.lua). What is left here is the
-- part that is genuinely PrettyChat's: what each of its three kinds of page draws.
--
-- Two of the three are the library's own shapes. The third is not, and that is the
-- documented deviation this file has carried since PC-23 — see buildStringRow.

local PrettyChat = LibStub("AceAddon-3.0"):GetAddon("PrettyChat")
local AceGUI = LibStub("AceGUI-3.0")

local H      = NS.Helpers
local Const  = NS.Const
local Color  = Const.Color
local Schema = NS.Schema
local L      = NS.L
local CATEGORY_ORDER = Schema.CATEGORY_ORDER

local TOC_NOTES = NS.Compat.GetAddOnMetadata(addonName, "Notes") or ""

local LOGO_PATH = "Interface\\AddOns\\" .. addonName
                  .. "\\media\\logos\\prettychat.logo.v2.tga"
local LOGO_SIZE = 300

-- ---------------------------------------------------------------------
-- Reset-all popup. The OnAccept body lives in PrettyChat:ResetAll so the
-- popup, the General > "Reset all to defaults" button, and the
-- /pc resetall slash command share a single implementation.
-- ---------------------------------------------------------------------

StaticPopupDialogs["PRETTYCHAT_RESET_ALL"] = {
    text         = L["Reset every category and string to defaults?"],
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
    OnAccept     = function() PrettyChat:ResetAll() end,
}

-- ---------------------------------------------------------------------
-- General sub-page — addon-wide controls: the master Enable, the console
-- visibility checkbox, and the Test / Reset-all pair.
--
-- Drawn entirely through the library. The master toggle is a schema row, so
-- it goes through the flow engine; the console checkbox is NOT a setting and
-- must never become one, so it arrives as the right half of that row through
-- the pairWith seam, wired to LibKa0s-DebugLog-1.0's ConsoleCheckbox() data
-- contract rather than to a path.
-- ---------------------------------------------------------------------

local function buildGeneralBody(ctx)
    H.ClearScroll(ctx)
    local scroll = H.EnsureScroll(ctx)
    if not scroll then return end

    local desc = AceGUI:Create("Label")
    desc:SetFullWidth(true)
    desc:SetText(L["Addon-wide controls. The Enable toggle is the master switch — disable it and every Blizzard original is restored regardless of per-category settings."])
    if desc.label and desc.label.SetFontObject and _G.GameFontHighlight then
        desc.label:SetFontObject(_G.GameFontHighlight)
    end
    scroll:AddChild(desc)
    H.AddSpacer(scroll, H.ROW_VSPACER)

    -- The console box mirrors the WINDOW's visibility and never touches the
    -- logging flag; the two are separate controls and a user who closes the
    -- console does not expect capture to stop. Both facts are the library's, in
    -- the checkbox spec it hands over — including the tooltip, which composes
    -- this addon's own slash from the console descriptor.
    local pairWith = {
        ["General.enabled"] = function(pairCtx, rowGroup)
            H.SessionCheckbox(pairCtx, rowGroup, 0.5, NS.DebugLog:ConsoleCheckbox())
        end,
    }
    H.RenderRows(ctx, { Schema.FindByPath("General.enabled") }, nil, pairWith)

    H.InlineButtonPair(ctx,
        {
            text    = L["Test"],
            tooltip = L["Print a sample of every active format string to chat so you can see what real loot/currency/XP messages will look like."],
            onClick = function() PrettyChat:Test() end,
        },
        {
            text    = L["Reset all to defaults"],
            tooltip = L["Reset every category and string to its default value."],
            -- Through the popup, never straight to the reset: this is the
            -- destructive path and its confirmation is the guard.
            onClick = function() StaticPopup_Show("PRETTYCHAT_RESET_ALL") end,
        })
end

-- ---------------------------------------------------------------------
-- Per-string block.
--   ─── <strData.label> ───                          (Heading, full width)
--   [Enable]              | Original  [disabled EditBox]
--   GLOBALNAME (grey)     | New       [editable EditBox]
--   [Reset]               | Preview   [disabled EditBox, color rendered]
--
-- Two-column 40/60 split, drawn by hand rather than by the library's flow
-- engine. This is the documented deviation from options-ui-§6's 50/50 grid
-- (PC-23), and adopting LibKa0s-Options-1.0 did not change the reasoning: the
-- block is a domain-specific three-row CONTROL, not a row of independent
-- settings. The right column holds full format strings with their colour
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
-- uses InputBoxTemplate, whose backing FontString renders WoW `|c…|r` colour
-- escapes, so the rendered sample shows with its formatting intact.
-- ---------------------------------------------------------------------

local LEFT_W  = 0.4
local RIGHT_W = 0.6

local function buildStringRow(scroll, category, globalName, strData, refreshers)
    local enabledPath = category .. "." .. globalName .. ".enabled"
    local formatPath  = category .. "." .. globalName .. ".format"

    -- Heading: friendly label as section divider for this string
    local heading = AceGUI:Create("Heading")
    heading:SetText(strData.label)
    heading:SetFullWidth(true)
    heading:SetHeight(H.SECTION_HEADING_H)
    if heading.label and heading.label.SetFontObject and _G.GameFontNormalLarge then
        heading.label:SetFontObject(_G.GameFontNormalLarge)
    end
    scroll:AddChild(heading)

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
            enableTooltip = enableTooltip
                .. "\n\n" .. Color.grey
                .. "Shared with " .. table.concat(others, ", ")
                .. " — both registrations write the same Blizzard global; the last category to apply wins on /reload."
                .. Color.reset
        end
    end
    H.AttachTooltip(enable, L["Enable"], enableTooltip)
    row1:AddChild(enable)

    local origInput = AceGUI:Create("EditBox")
    origInput:SetLabel(L["Original"])
    origInput:SetRelativeWidth(RIGHT_W)
    origInput:SetDisabled(true)
    local origValue = (NS.GlobalStrings and NS.GlobalStrings[globalName])
                     or L["(original not available)"]
    origInput:SetText(origValue:gsub("|", "||"))
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
    captionLbl:SetText(Color.grey .. globalName .. Color.reset)
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
        newInput:SetText((current or ""):gsub("|", "||"))
        newInput:SetDisabled(not (addonEnabled and catEnabled and strEnabled))

        local rendered, err = NS.RenderSample(current)
        previewInput:SetText(rendered or tostring(err))
    end

    refreshers[#refreshers + 1] = refresh
    refresh()
end

-- ---------------------------------------------------------------------
-- Category sub-page — the category's own Enable row, then one per-string
-- block. The Enable row is a schema row and goes through the library's
-- checkbox maker at full width; the blocks below it are bespoke.
-- ---------------------------------------------------------------------

local function buildCategoryBody(ctx, category, catData)
    H.ClearScroll(ctx)
    local scroll = H.EnsureScroll(ctx)
    if not scroll then return end
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

    for _, globalName in ipairs(sortedNames) do
        buildStringRow(scroll, category, globalName, catData.strings[globalName], refreshers)
    end

    -- The bespoke blocks are invisible to the library's ctx.refreshers, so they
    -- register through the schema's own dispatch. Schema.NotifyPanelChange drives
    -- both registries; see the comment there.
    Schema.RegisterRefresher(category, function()
        for _, fn in ipairs(refreshers) do pcall(fn) end
    end)
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

    local logoTex = logoGroup.frame:CreateTexture(nil, "ARTWORK")
    logoTex:SetTexture(LOGO_PATH)
    logoTex:SetSize(LOGO_SIZE, LOGO_SIZE)
    logoTex:SetPoint("TOPLEFT", logoGroup.frame, "TOPLEFT", 0, 0)
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
    alias:SetText(Color.grey .. L["/prettychat is an alias for /pc"] .. Color.reset)
    scroll:AddChild(alias)
    H.AddSpacer(scroll, H.ROW_VSPACER)

    for _, entry in ipairs(NS.COMMANDS or {}) do
        local row = AceGUI:Create("Label")
        row:SetFullWidth(true)
        row:SetText(("%s/pc %s%s  %s—%s  %s"):format(
            Color.yellow, entry[1], Color.reset,
            Color.white, Color.reset, entry[2]))
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

for _, category in ipairs(CATEGORY_ORDER) do
    H.RegisterOptionsPage(category, category, function(mainCategory)
        local isGeneral = (category == "General")
        local ctx = H.CreatePanel(nil, category, {
            pageKey         = category,
            defaultsButton  = not isGeneral,
            defaultsTooltip = (not isGeneral)
                and ("Reset all " .. category .. " strings to defaults.")
                or nil,
        })

        if isGeneral then
            H.SetRenderer(ctx, buildGeneralBody)
        else
            local catData = NS.Defaults[category]
            if not catData then return nil end
            -- Parked for the library to wire onto the Defaults button on first
            -- OnShow, and forwarded to by the panel's OnDefault so the Settings
            -- window's own footer control reaches the same body (options-ui-§1).
            --
            -- PrettyChat:ResetCategory rather than the library's row-by-row
            -- RestoreDefaults: it wipes the category's table and re-applies in ONE
            -- pass with ONE [Reset] summary line, where the row-by-row form would
            -- run ApplyStrings once per row and emit one [Set] line per row into a
            -- 500-line console buffer (debug-logging-§9).
            ctx.panel.defaultsOnClick = function() PrettyChat:ResetCategory(category) end
            H.SetRenderer(ctx, function(pageCtx)
                buildCategoryBody(pageCtx, category, catData)
            end)
        end

        return Settings.RegisterCanvasLayoutSubcategory(mainCategory, ctx.panel, category)
    end)
end

NS.Config = NS.Config or {}
NS.Config.BuildMain      = buildParentBody
NS.Config.RegisterPanels = function() H.CreateOptionsPanel() end
