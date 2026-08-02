local addonName, NS = ...

-- settings/OptionsSetup.lua — wires the addon into LibKa0s-Options-1.0.
--
-- What moved: the canvas factory and its header, the breadcrumb, the lazily-built
-- Defaults button, the always-shown-scrollbar patch, the AceGUI ScrollFrame, the
-- tooltip helper, the spacer helper, the page registry, the panel-open with its
-- combat gate, and the refresh fan-out. All of that was ~233 lines of
-- settings/Panel.lua and is now shared.
--
-- What stayed the host's, and why, is recorded per item below the descriptor.
--
-- TOC slot: after settings/Schema.lua, whose Get/Set/RowsByCategory the descriptor
-- reads, and before settings/Panel.lua, which takes this instance as a file-scope
-- upvalue and registers its pages at file load (options-ui-§1).

local lib = LibStub and LibStub("LibKa0s-Options-1.0", true)

if not lib then
    -- The ONE documented exception to the member-answering stub every other Ka0s
    -- setup file uses (options-ui-§1). The rule there is about WHEN the missing
    -- code is reached: a page file that calls a helper inside a schema-row literal
    -- at FILE LOAD raises with the member nil, its rows never register, and a third
    -- of the schema silently disappears — taking `list`, `get`, `set` and `reset`
    -- with it.
    --
    -- PrettyChat's measured load-time set is EMPTY. settings/Schema.lua builds the
    -- whole schema from defaults/Defaults.lua and touches nothing here;
    -- settings/Panel.lua reaches this table only inside page builders, which run at
    -- CreateOptionsPanel time. tests/test_libka0s.lua pins that by loading with the
    -- library absent and comparing the row count against a full load — those two
    -- numbers agreeing is the whole thing standing between this stub and a silent
    -- half-load, and the reason the set is measured rather than reasoned about.
    --
    -- So everything here is a no-op or one honest line, and NOTHING copies a widget
    -- maker, the flow engine, the header or a layout constant (anti-pattern #47).
    local missing = NS.LIBKA0S_MISSING .. ", so the settings panel is unavailable."
    local announced = false
    local function sayOnce()
        if announced then return end
        announced = true
        if NS.Print then NS.Print(missing) end
    end

    NS.Helpers = {
        CreatePanel          = function() return { refreshers = {} } end,
        EnsureDefaultsButton = function() end,
        EnsureScroll         = function() return nil end,
        ClearScroll          = function() end,
        AddSpacer            = function() end,
        Section              = function() end,
        AttachTooltip        = function() end,
        InlineButtonPair     = function() end,
        RenderField          = function() end,
        SessionCheckbox      = function() end,
        RenderRows           = function() end,
        RenderSchema         = function() end,
        RenderGrid           = function() end,
        SetRenderer          = function() end,
        RegisterOptionsPage  = function() end,
        RefreshAllPanels     = function() end,
        RefreshScalars       = function() end,
        LSMValues            = function() return function() return {} end end,
        __pages              = function() return {} end,
        __panels             = function() return {} end,
        __panelFor           = function() return nil end,
        CreateOptionsPanel   = function() sayOnce() end,
        OpenOptionsPanel     = function() sayOnce() end,
        -- Kept REAL even though it is call-time (options-ui-§1 SHOULD): a user whose
        -- panel will not open is exactly the user who needs "reset everything", and
        -- the schema loaded fine, so the reset still works with no panel at all.
        RestoreAllDefaults   = function()
            local addon = LibStub and LibStub("AceAddon-3.0", true)
            addon = addon and addon:GetAddon("PrettyChat", true)
            if addon and addon.ResetAll then addon:ResetAll() end
        end,
        -- No ROW_VSPACER / SECTION_HEADING_H / BUTTON_PAIR_REL here. options-ui-§1
        -- forbids carrying the library's layout constants into the stub and
        -- options-ui-§8 forbids a host copy of them anywhere, precisely because a
        -- host copy is the copy that goes stale. Every consumer of them in
        -- settings/Panel.lua sits behind a maker that is a no-op on this path, so a
        -- nil reaches nothing.
    }
    return
end

-- The instance IS the namespace member (options-ui-§1), decorated in place rather
-- than copied across: settings/Panel.lua's own page code calls NS.Helpers.RenderRows
-- beside NS.Helpers.EnsureScroll, and a suite that swaps a member out to spy on it
-- must be swapping the one the library's own callers see.
NS.Helpers = lib:New({
    parentTitle = "Ka0s Pretty Chat",

    -- The main canvas gains a frame name, where settings/Panel.lua deliberately left
    -- every panel anonymous. That comment was right about sub-pages and wrong about
    -- this one: an anonymous main canvas is a frame /framestack cannot attribute to
    -- this addon, and two addons can collide on it. It is the only descriptor field
    -- the library validates, and it raises rather than defaulting, for exactly that
    -- reason. Sub-pages stay anonymous — settings/Panel.lua passes nil.
    mainPanelName = "PrettyChatOptionsPanel",

    print = function(line) NS.Print(line) end,
    debug = function(tag, fmt, ...) NS.Debug(tag, fmt, ...) end,

    -- The single write seam (options-ui-§1). A panel checkbox takes exactly the path
    -- `/pc set` takes: the same [Set] debug line, the same ApplyStrings re-apply, the
    -- same panel refresh. Two-argument by construction, so no adapter is needed.
    get          = function(path) return NS.Schema.Get(path) end,
    set          = function(path, value) NS.Schema.Set(path, value) end,
    applyDefault = function(row) NS.Schema.ApplyDefault(row) end,

    -- The page key IS the category name, so no translation layer is needed.
    rowsForPage = function(pageKey) return NS.Schema.RowsByCategory(pageKey) end,
    allRows     = function() return NS.Schema.AllRows() end,

    -- The landing page's body — the logo, the tagline and the command list — is the
    -- host's half by design (options-ui-§5), handed over as a hook so the library
    -- still owns WHEN it draws (first OnShow, against a container that has a width
    -- by then).
    buildMain = function(ctx)
        if NS.Config and NS.Config.BuildMain then NS.Config.BuildMain(ctx) end
    end,

    -- Deliberately NOT passed, each for a reason worth writing down rather than
    -- leaving as an absence:
    --
    --   colorDecode / colorEncode — this addon has no colour rows at all. The schema
    --     is bool and string only, so there is no stored colour shape to declare.
    --   getLSM / scheduleTimer    — no media pickers, no colour pickers, no sliders,
    --     so nothing reaches either.
    --   skipRestoreAll / afterRestoreAll — the global reset is PrettyChat:ResetAll,
    --     which wipes the profile in one pass; the library's row-by-row
    --     RestoreAllDefaults is not on the path (see settings/Panel.lua).
    --   validate                  — settings/Schema.lua already runs its integrity
    --     check at file load and stashes the counts on Schema.validation, which the
    --     suite asserts. A second pass at panel-build time would report the same
    --     thing later and quieter.
    --   onAceGUI                  — settings/Panel.lua resolves AceGUI itself, at
    --     file load, and has since before the adoption.
})
