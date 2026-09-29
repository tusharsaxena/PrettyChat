local _, NS = ...

-- settings/Profiles.lua — the Profiles sub-page (options-ui-§3): AceDBOptions' own create /
-- switch / copy / reset / delete UI, plus its per-character / per-class / per-realm /
-- per-faction / default choices, drawn by AceConfigDialog into this addon's canvas.
--
-- WHAT A PROFILE HOLDS. Everything PrettyChat stores as a setting: the master Enable, General
-- visibility, and every category's Enable, per-string Enable and format override. The minimap
-- button's shown/hidden choice is in db.global (launcher-§3) and the debug console's visibility
-- is session state; neither moves when a profile does. docs/profiles.md has the whole list.
--
-- THE ONE PLACE AceConfig IS USED (options-ui-§3, library-stack-§2). Every other page is drawn
-- from the schema; this one is the exception because the options table is not ours. AceDBOptions
-- generates it, and re-expressing it as schema rows would be a copy of AceDB's profile model that
-- goes stale the first time AceDB adds a scope. The exception is scoped to CONTENT: the canvas,
-- the header, the breadcrumb and the combat cover are H.CreatePanel and H.SetRenderer, as on
-- every other page. It carries no schema rows, so it draws no tab strip -- one of the two pages
-- options-ui-§13 exempts, the landing page being the other.
--
-- NO DEFAULTS BUTTON. "Restore defaults" here would mean deleting the player's profiles. The
-- panel is created with `defaultsButton = false`, and the global reset's veto names this page a
-- second time (Schema.VetoedFromResetAll, handed to the library as `skipRestoreAll`).
--
-- WHEN THE PAGE REDRAWS. The widget tree is AceConfigDialog's, and it re-reads the active profile
-- only when it is fed again. A change made ON this page needs nothing -- AceConfigDialog re-opens
-- its own container after every control it activates. A profile changed from anywhere else --
-- `/pc resetall`, Reset all settings, a `/run` -- reaches core/PrettyChat.lua's one adopt path,
-- which calls NS.Config.RefreshProfilesPage below: the page redraws now if it is on screen, and
-- on its next show if not (H.RefreshPanel). It redraws on THAT and on nothing else: SetRenderer
-- also puts the page on the library's structural fan-out, and a renderer that re-opened on each
-- of those would tear AceConfigDialog's tree down under an open dropdown (options-ui-§11). So the
-- renderer draws once per profile event, counted.
--
-- Optional dependency: without AceDBOptions, AceConfig, AceConfigDialog or AceGUI the page opts
-- out (a nil return) and nothing else is lost. Every lookup is silent (library-stack-§4).

local H = NS.Helpers
local L = NS.L

local PAGE = NS.Schema.PROFILES_PAGE
local APP  = "PrettyChat-Profiles"

-- Bumped by every profile event. The page redraws when the count it last drew at is behind
-- this one; the first show counts as behind.
local profileEvents = 0
local page

--- The four libraries this page needs, or nil when any is missing.
local function aceLibs()
    if not LibStub then return nil end
    local libs = {
        dbOptions = LibStub("AceDBOptions-3.0",    true),
        config    = LibStub("AceConfig-3.0",       true),
        dialog    = LibStub("AceConfigDialog-3.0", true),
        gui       = LibStub("AceGUI-3.0",          true),
    }
    if not (libs.dbOptions and libs.config and libs.dialog and libs.gui) then return nil end
    return libs
end

--- An AceGUI SimpleGroup parented to the page body. AceConfigDialog:Open accepts any AceGUI
--- container as its target, so the AceDBOptions widgets land inside this canvas instead of a
--- second floating window over the Settings panel. Built on first show, never in the builder
--- (options-ui-§5).
local function newContainer(gui, ctx)
    local container = gui:Create("SimpleGroup")
    container:SetLayout("Fill")
    container.frame:SetParent(ctx.body)
    container.frame:ClearAllPoints()
    container.frame:SetPoint("TOPLEFT",     ctx.body, "TOPLEFT",      8, -8)
    container.frame:SetPoint("BOTTOMRIGHT", ctx.body, "BOTTOMRIGHT", -8,  8)
    return container
end

local function Build(mainCategory)
    if not (Settings and Settings.RegisterCanvasLayoutSubcategory) then return nil end
    local libs = aceLibs()
    if not libs then return nil end

    -- An options table built over a nil db raises inside AceDBOptions instead of here, so a db
    -- that failed to initialize costs this page, not the panel.
    if not (NS.db and NS.db.profile) then return nil end

    -- Registered once per build. The table AceDBOptions returns reads NS.db live, so a profile
    -- change does not need it rebuilt -- only redrawn.
    libs.config:RegisterOptionsTable(APP, libs.dbOptions:GetOptionsTable(NS.db))

    local ctx = H.CreatePanel(nil, L["Profiles"], {
        pageKey        = PAGE,
        defaultsButton = false,
    })

    local container, drawnAt
    H.SetRenderer(ctx, function()
        if drawnAt == profileEvents then return end
        drawnAt = profileEvents
        container = container or newContainer(libs.gui, ctx)
        -- SHOWN EXPLICITLY, every draw. AceGUI:Release hides a frame before pooling it, and
        -- neither AceGUI:Create nor AceConfigDialog:Open shows it again; whenever the
        -- process-wide SimpleGroup pool is non-empty (any AceGUI page, in any addon, released
        -- one earlier) this group comes back hidden, and AceConfigDialog would fill a frame
        -- nobody can see: a blank Profiles page.
        container.frame:Show()
        libs.dialog:Open(APP, container)
    end)
    page = ctx

    return Settings.RegisterCanvasLayoutSubcategory(mainCategory, ctx.panel, L["Profiles"])
end

--- The redraw a profile event asks for, called from core/PrettyChat.lua's shared adopt path.
--- Safe before the page is built and on an install where it never is: the count still moves,
--- and there is no page to mark.
NS.Config = NS.Config or {}
NS.Config.RefreshProfilesPage = function()
    profileEvents = profileEvents + 1
    if page then H.RefreshPanel(page, true) end
end

-- LAST of the three registrations (settings/Panel.lua registers General and Categories), so the
-- page closes the rail as options-ui-§3 has it.
H.RegisterOptionsPage(PAGE, L["Profiles"], Build)
