local _, NS = ...

local PrettyChat = LibStub("AceAddon-3.0"):GetAddon("PrettyChat")

local Schema = {}
NS.Schema = Schema

-- Display order shared with settings/Panel.lua. Iterating NS.Defaults via
-- pairs() would give a non-deterministic order; this keeps `/pc list`, `/pc test`
-- and the Categories page's tab strip in sync — the strip DERIVES its tab order
-- from this array rather than restating it. "General" is a virtual category
-- (no entry in NS.Defaults) that hosts addon-wide settings — listed first, and
-- the one entry the strip skips, because it is a page of its own rather than a
-- message category.
local CATEGORY_ORDER = {
    "General",
    "Loot", "Currency", "Money", "Reputation",
    "Experience", "Honor", "Tradeskill", "Misc",
}
Schema.CATEGORY_ORDER = CATEGORY_ORDER

-- The page key every message-category row declares, and the name settings/Panel.lua
-- registers that page under. Not a category: it is deliberately absent from
-- CATEGORY_ORDER, whose entries are schema path segments
-- (`/pc set Loot.enabled false`) and must stay resolvable by Schema.ResolveCategory.
local CATEGORY_PAGE = "Categories"
Schema.CATEGORY_PAGE = CATEGORY_PAGE

-- Seven row kinds. Path scheme:
--   General.enabled                     → addon-wide master toggle (bool)
--   General.visibility                  → addon-wide visibility mode (string enum)
--   state.debugConsole                  → the console window's own toggle (session only)
--   global.minimap.shown                → the minimap button, INVERTED onto LibDBIcon's
--                                         stored `hide` (stored, global; WS-06)
--   <Category>.enabled                  → category master toggle (bool)
--   <Category>.<GLOBALNAME>.enabled     → per-string enable toggle (bool)
--   <Category>.<GLOBALNAME>.format      → per-string format string
-- The first four are the composed Master controls block below; the last three
-- are this addon's own.
-- The dot path doesn't map 1:1 onto db.profile.categories[...], so each
-- row carries its own get/set closures rather than relying on a generic
-- dot-walker.

-- The rows array IS the schema runtime's `rows` (LibKa0s-Schema-1.0, bound at the
-- bottom of this file): held by reference and never copied, so `/pc list`, the
-- settings tree and the runtime's index all read one table. Built here in
-- declaration order, then indexed once when the runtime is made.
local rows = {}        -- ordered, used by /pc list

local function addRow(row)
    rows[#rows + 1] = row
    return row
end

-- Row `set` closures are pure DB writes — they do NOT call
-- PrettyChat:ApplyStrings() or Schema.NotifyPanelChange(). Both side
-- effects are the write seam's `announce` (Schema.Set), and its batched sibling
-- Schema.ResetRows, the runtime's own BulkRun bracket, pays them once per batch
-- instead of once per row. Callers must go through one of the two; never invoke
-- row.set(value) directly.
--
-- Each one is BATCHED where it is built, because the seam calls the row's `set`
-- itself and there is no host step left around the call to batch it from.
-- `General.enabled`'s `set` drives LibKa0s-Lifecycle-1.0, and an edge stands the
-- addon down or up: the arm's registration work runs inside the batch, and its
-- pass over the globals and its panel refresh do not, because `announce` is that
-- pass and that refresh, for this very write (modules/Override.lua's Batch). One
-- act, one pass, one [Set] line.
local function batched(set)
    return function(v) PrettyChat.Batch(function() set(v) end) end
end
--
-- Every stored closure writes the DEFAULT as an absence: a value equal to the
-- row's default clears its key, and an emptied `strings` / `disabledStrings` /
-- category table is dropped (pruneCategoryDB). SavedVariables therefore holds
-- only what a player has actually changed, and a reset that writes every row's
-- default through these closures leaves exactly the shape it always did: no
-- category table at all.

-- ---------------------------------------------------------------------
-- The Master controls block (options-ui-§15) — the General page's one tab.
--
-- COMPOSED, never hand-written. LibKa0s-Options-1.0's MasterControls composer
-- owns the canonical row set, its order and its wording; nine addons drawing the
-- same tab from nine hand-written copies is exactly the drift OptionsCompose.lua
-- was extracted to end. What stays here is the half a library cannot know: which
-- stored path each leaf keeps, and the get/set closure behind it.
--
-- PrettyChat is FRAMELESS — `grep -rn SetMovable core/ modules/ settings/`
-- returns nothing but the two comments that say so, and this addon draws no
-- positionable frame at all — so the composer omits EXACTLY master scale,
-- master alpha and lock frame, and the closing button is "Reset all settings"
-- alone rather than a pair. Nothing else is omitted: General visibility STAYS,
-- because this addon's display IS the chat text it rewrites, and `Never` is a
-- real, cheap master off-switch distinct from `Enable` (see
-- PrettyChat:IsVisible in modules/Override.lua, which honors all four modes).
--
-- Installed from settings/OptionsSetup.lua rather than run here: the composers
-- live ON the options instance, and that file is the NEXT TOC entry, so
-- NS.Helpers does not exist yet while this one is running.
-- ---------------------------------------------------------------------

local MASTER_SPEC = {
    prefix    = "",
    page      = "General",
    addonName = "PrettyChat",
    frameless = true,
    -- The stored paths this addon already ships, kept verbatim. A composer must
    -- change what is DECLARED and how it is laid out, never what is stored — so
    -- `General.enabled` stays where every SavedVariables file already has it.
    keys      = {
        enabled    = "General.enabled",
        visibility = "General.visibility",
    },
    -- Passed explicitly even though both match the composer's own, for the same
    -- reason `keys` is: the stored VALUE is the host's to declare, and saying so
    -- is what stops a later library minor from silently re-defaulting a setting
    -- players already have. It is also what lets the degraded stub in
    -- settings/OptionsSetup.lua answer without a copy of the library's defaults.
    defaults  = {
        -- Read from NS.GeneralDefaults (defaults/Profile.lua), the one place these
        -- two are declared (savedvariables-§2), never retyped here.
        enabled    = NS.GeneralDefaults.enabled,
        visibility = NS.GeneralDefaults.visibility,
        -- The console row's reset target. Session state, so nothing stores it; the
        -- default is what `/pc reset state.debugConsole` and a reset through
        -- ApplyDefault write, and LibKa0s-Schema-1.0 reads a nil default as NO
        -- RESTORE (its JC-5). Before the adoption the reset wrote nil, which the
        -- row's `set` read as hide; `false` is that same hide, said as a value.
        debugConsole = false,
    },
    -- VERBATIM and unprefixed: session state lives outside the block's own
    -- prefix, and this is the one row whose path the composer does not build.
    debugConsolePath = "state.debugConsole",
    -- The minimap button's visibility (launcher-§3, OptionsCompose minor 7).
    -- VERBATIM and unprefixed for a DIFFERENT reason than the console path's:
    -- this table lives in the GLOBAL store, outside this block's profile prefix
    -- entirely, because a minimap button belongs to the installation rather than
    -- to a profile (NS.GlobalDefaults in defaults/Profile.lua says why).
    --
    -- STORED, not session, and the composer emits it that way: a hidden button is
    -- furniture the player arranged once, not state a reload ends. The row's
    -- default is the row's OWN sense -- SHOWN -- and the inversion onto
    -- LibDBIcon's `hide` happens in the wiring below.
    --
    -- There is no `testModePath` beside it and there never will be: this addon is
    -- frameless and its display is the chat text it rewrites, so it has no preview
    -- to put a switch on. The composer renders the Minimap button row alone on its
    -- line, which is exactly what it does for either row without the other.
    --
    -- THE PATH NAMES THE ROW'S SENSE, THE STORE KEEPS THE LIBRARY'S (WS-06,
    -- launcher-§3, anti-pattern #81). `/pc get|set global.minimap.shown` reads
    -- the way the checkbox does, while the stored key stays LibDBIcon's own
    -- db.global.minimap.hide -- no SavedVariables change, no migration, and no
    -- `shown` key is ever written. The old `global.minimap.hide` path is simply
    -- an unknown setting now.
    minimapPath = "global.minimap.shown",
    -- options-ui-§12's global reset, through this addon's confirmation popup —
    -- the destructive path and its guard are one act (settings/Panel.lua).
    onResetAll = function() PrettyChat:ConfirmResetAll() end,
    -- THE ONE VERB THIS ADDON HAS THAT NO OTHER KA0S ADDON DOES, closing the tab
    -- beside the reset (LibKa0s v1.25.0, OptionsCompose minor 2). It is declared
    -- here rather than drawn in settings/Panel.lua because §15 fixes the reset's
    -- wording and the composer is the only thing that writes it: drawing the pair
    -- host-side would have put a second copy of "Reset all settings" in this
    -- addon, which is the drift the composer exists to end. A frameless addon has
    -- no "Reset position", so the pair's right half is free and the verb takes it.
    --
    -- Late-bound through PrettyChat for the same reason onResetAll is: the body
    -- lives in settings/Panel.lua, which loads after this file.
    leadButton = {
        text    = NS.L["Test"],
        tooltip = NS.L["Write a sample of every active format string to the debug console, so you can see what real loot/currency/XP messages will look like. `/pc test` writes the same report there."],
        onClick = function() PrettyChat:TestToConsole() end,
    },
}

-- The host half of every composed row: the `kind` the rest of this file
-- dispatches on, and the get/set pair the panel and the CLI both write through.
-- Keyed by the FINAL path, so a `keys` entry above and its wiring here cannot
-- drift apart without the install below reporting it.
local MASTER_WIRING = {
    ["General.enabled"] = {
        kind = "addon_enabled",
        -- The STORED path, not the latch. A `perf` hold stands the addon down over a
        -- stored `enabled = true`, and a checkbox that unticked itself for the
        -- duration of a capture would be reporting somebody else's decision as the
        -- player's (modules/Override.lua says which question is which).
        get  = function() return PrettyChat:IsAddonEnabled() end,
        -- Stored only when OFF: the default (true) is an absent key, which
        -- IsAddonEnabled already reads as enabled.
        --
        -- THE WRITE, THEN THE LATCH, and both live here so that every surface that
        -- can flip this setting drives the stand-down: the Enable checkbox, `/pc
        -- enable` / `/pc disable`, `/pc set General.enabled false`, `/pc reset
        -- General.enabled` and a page Defaults press all arrive through this one
        -- `set` (architecture-§5's single write seam). A latch poked from the verb
        -- instead would be a stand-down the checkbox does not perform.
        --
        -- `Set` is the library's own shape rather than a host-written
        -- `if v then Release else Hold` — a branch written eleven times is a branch
        -- one host writes backwards — and it fires the matching arm exactly once, on
        -- the edge. Schema.Set's own ApplyStrings below then runs a second,
        -- idempotent pass over settings the arm has already made the client agree
        -- with; one extra pass on a click is the price of the arms being complete on
        -- their own, which is what the load path and the profile callbacks need.
        set  = function(v)
            if v then
                PrettyChat.db.profile.enabled = nil
            else
                PrettyChat.db.profile.enabled = false
            end
            NS.Lifecycle:Set(NS.HOLD_DISABLED, not v)
        end,
    },
    ["General.visibility"] = {
        kind = "addon_visibility",
        get  = function() return PrettyChat:GetVisibility() end,
        -- Stored only when it differs from the default, exactly as the per-string
        -- format row clears itself: SavedVariables stays empty until a player has
        -- actually chosen something.
        set  = function(v)
            local default = NS.GeneralDefaults.visibility
            PrettyChat.db.profile.visibility = (v ~= default) and v or nil
            PrettyChat:SyncCombatWatch()
        end,
    },
    -- THE INVERSION, AND IT IS OURS RATHER THAN THE LIBRARY'S (launcher-§3).
    -- The row's label says SHOWN; LibDBIcon's key says HIDDEN. There is exactly
    -- one boolean -- the library writes it too, from its own right-click menu --
    -- so a second `show` key beside it would be one state kept in two records,
    -- free to disagree the first time either surface was used (anti-pattern #81).
    -- The whole cost of storing the library's own key is these two closures.
    --
    -- Both read and write the STORE, not the button: on an install with no
    -- LibDBIcon the checkbox still reflects what the player chose rather than
    -- reading `true` because nothing contradicted it, and the choice takes effect
    -- the day the library arrives. NS.Launcher:SetShown is what makes the button
    -- follow the checkbox NOW rather than at the next reload; it writes `hide`
    -- again with the same value, which is the library's documented shape.
    --
    -- The KEY here is the settings path, and it names the row's SHOWN sense
    -- (WS-06); the closures are what map it onto the stored `hide` leaf, so the
    -- path and the store may differ in sense without a second record.
    ["global.minimap.shown"] = {
        kind = "minimap_button",
        get  = function()
            local mm = PrettyChat.db and PrettyChat.db.global and PrettyChat.db.global.minimap
            return not (mm and mm.hide)
        end,
        set  = function(v)
            local on = v and true or false
            local mm = PrettyChat.db and PrettyChat.db.global and PrettyChat.db.global.minimap
            -- A leaf write onto the declared default's table, never a whole-section
            -- `minimap = {...}` assignment: LibDBIcon keeps `minimapPos` in here too
            -- and replacing the table would throw the player's dragged angle away
            -- every time they ticked the box (architecture-§5).
            if mm then mm.hide = not on end
            if NS.Launcher then NS.Launcher:SetShown(on) end
        end,
    },
    -- Session state, never persisted. It mirrors the console WINDOW's visibility
    -- and never touches the logging flag — the two are separate controls and a
    -- user who closes the console does not expect capture to stop. This is the
    -- bespoke SessionCheckbox settings/Panel.lua used to draw through `pairWith`,
    -- now a composed row like every other control on the tab.
    ["state.debugConsole"] = {
        kind = "debug_console",
        get  = function() return NS.DebugLog:IsShown() end,
        set  = function(v)
            if v then NS.DebugLog:Show() else NS.DebugLog:Hide() end
        end,
    },
}

-- Canonical leaves the composer emitted that this addon has not wired. Empty,
-- and it is the install below that keeps it so: a leaf the library adds in a
-- later minor must be wired here rather than silently dropped, so it is reported
-- through the same load-time channel an unresolved path takes.
local unwiredMasterPaths = {}

-- Drop what a row write has emptied: a `strings` or `disabledStrings` table with
-- no entries, then the category table itself once nothing is left in it. Part of
-- the row closures' own write step, so it never runs outside the helper.
local function pruneCategoryDB(category)
    local cats  = PrettyChat.db.profile.categories
    local catDB = cats and cats[category]
    if not catDB then return end
    if catDB.strings and next(catDB.strings) == nil then catDB.strings = nil end
    if catDB.disabledStrings and next(catDB.disabledStrings) == nil then
        catDB.disabledStrings = nil
    end
    if next(catDB) == nil then cats[category] = nil end
end

-- The category table, or nil when there is none. The clearing arm of a closure
-- reads through this rather than EnsureCategoryDB: clearing must not create.
local function existingCategoryDB(category)
    local cats = PrettyChat.db.profile.categories
    return cats and cats[category]
end

-- THE CONVERSION-SIGNATURE GATE (PC-R-01).
--
-- A format string is a contract with Blizzard's caller: it may drop trailing
-- conversions — string.format ignores surplus ARGUMENTS — but a conversion with
-- no argument behind it raises. Nothing downstream catches that. The Preview
-- cannot: `buildSampleArgs` synthesizes its arguments FROM the format, so it
-- renders a surplus `%s` happily and reports success, and the raise lands later
-- inside Blizzard's chat handler, on every matching message, in a stack trace
-- naming a Blizzard frame. So the check belongs at the write.
--
-- Compared against THIS ADDON'S SHIPPED DEFAULT rather than Blizzard's live
-- string, which sounds like the weaker check and is the sound one:
-- tests/test_defaults.lua already pins every shipped default as a positional
-- prefix of Blizzard's, so prefix-of-default composes into prefix-of-Blizzard,
-- and unlike `_G[globalName]` a default cannot have been overwritten by this
-- addon's own ApplyStrings by the time it is read. The cost is that a player
-- cannot restore a conversion one of the four SANCTIONED_TRUNCATIONS dropped;
-- lengthening the default is the way to give it back, and that is a change to
-- the shipped data where it belongs.
local function refusedBySignature(row, value)
    if row.kind ~= "string_format" or type(value) ~= "string" then return false end
    local asked    = NS.ConversionSequence(value)
    local supplied = NS.ConversionSequence(row.default)
    if NS.SequenceIsPrefix(asked, supplied) then return false end
    NS.Print(NS.L["Not saved — %s asks for %s; %s supplies %s. A format may drop trailing conversions but must not add or retype one."]
        :format(row.path, NS.DescribeSequence(asked),
                row.globalName, NS.DescribeSequence(supplied)))
    return true
end

-- The gate AS THE ROW'S `validate`, which the write seam runs on every entry: a
-- player's write, `/pc set`, `/pc reset` (ApplyDefault), a page reset and both
-- value-bound descriptors. It used to be a wrapper in front of Schema.Set, and a
-- wrapper is exactly what LibKa0s-Schema-1.0's ApplyDefault bypasses, because it
-- calls the runtime's own Set (docs/api/Schema/version-1-docs.md, "A gate in front
-- of the seam"). The refusal keeps its two side effects: the panel refresh that
-- snaps the New box back to what is actually stored (the `/pc set` echo re-reads
-- too), and the one debug line saying why.
local function formatAccepted(row, value)
    if not refusedBySignature(row, value) then return true end
    Schema.NotifyPanelChange(row.category)
    NS.Debug("Set", "%s refused: %s is not a prefix of %s", row.path,
        NS.DescribeSequence(NS.ConversionSequence(value)),
        NS.DescribeSequence(NS.ConversionSequence(row.default)))
    return false, "conversion signature"
end

-- EVERY ROW ON EVERY PAGE CARRIES A `group` (options-ui-§13). These rows are not
-- rendered through the flow engine — the Categories page hands H.TabStrip its tab
-- list directly, because a category tab is one schema row followed by a bespoke
-- 40/60 editor the engine cannot express — but the declaration is what an audit
-- reads and what would partition the page correctly the day that stops being
-- true. The group IS the category, which is the tab it is drawn under.
local function buildCategoryRow(category)
    local default = (NS.Defaults[category] and NS.Defaults[category].enabled) and true or false
    addRow({
        path     = category .. ".enabled",
        category = category,
        page     = CATEGORY_PAGE,
        group    = category,
        kind     = "category_enabled",
        type     = "bool",
        -- Routed through NS.L with a `%s` placeholder rather than concatenated
        -- (localization-§1): concatenation pins English word order, and a locale
        -- that puts the category first cannot express it. The category NAME
        -- interpolated here is still English — see the `localization-§1` row in
        -- docs/ARCHITECTURE.md's deviations register.
        label    = NS.L["Enable %s"]:format(category),
        tooltip  = NS.L["Enable or disable all %s string overrides."]:format(category),
        default  = default,
        get      = function() return PrettyChat:IsCategoryEnabled(category) end,
        set      = batched(function(v)
            local on = v and true or false
            if on ~= default then
                PrettyChat:EnsureCategoryDB(category).enabled = on
            else
                local catDB = existingCategoryDB(category)
                if catDB then catDB.enabled = nil end
            end
            pruneCategoryDB(category)
        end),
    })
end

local function buildStringRows(category, globalName, strData)
    addRow({
        path       = category .. "." .. globalName .. ".enabled",
        category   = category,
        page       = CATEGORY_PAGE,
        group      = category,
        globalName = globalName,
        kind       = "string_enabled",
        type       = "bool",
        label      = strData.label,
        default    = true,
        get        = function() return PrettyChat:IsStringEnabled(category, globalName) end,
        set        = batched(function(v)
            if v then
                local catDB = existingCategoryDB(category)
                if catDB and catDB.disabledStrings then
                    catDB.disabledStrings[globalName] = nil
                end
            else
                local catDB = PrettyChat:EnsureCategoryDB(category)
                if not catDB.disabledStrings then catDB.disabledStrings = {} end
                catDB.disabledStrings[globalName] = true
            end
            pruneCategoryDB(category)
        end),
    })

    local formatRow = addRow({
        path       = category .. "." .. globalName .. ".format",
        category   = category,
        page       = CATEGORY_PAGE,
        group      = category,
        globalName = globalName,
        kind       = "string_format",
        type       = "string",
        label      = strData.label,
        default    = strData.default,
        get        = function() return PrettyChat:GetStringValue(category, globalName) end,
        set        = batched(function(v)
            if v == NS.Defaults[category].strings[globalName].default then
                local catDB = existingCategoryDB(category)
                if catDB and catDB.strings then catDB.strings[globalName] = nil end
            else
                local catDB = PrettyChat:EnsureCategoryDB(category)
                if not catDB.strings then catDB.strings = {} end
                catDB.strings[globalName] = v
            end
            pruneCategoryDB(category)
        end),
    })
    formatRow.validate = function(v) return formatAccepted(formatRow, v) end
end

-- Build the schema once at file load. NS.Defaults is populated by
-- Defaults.lua (loaded earlier by the TOC) and the addon object exists
-- (PrettyChat.lua's :NewAddon call ran), so closures bind to live values. The
-- Master controls block is spliced in at the HEAD of this list a moment later,
-- by Schema.InstallMasterControls.
for _, category in ipairs(CATEGORY_ORDER) do
    local catData = NS.Defaults[category]
    if catData then
        buildCategoryRow(category)

        for _, globalName in ipairs(NS.SortedStringNames(category)) do
            buildStringRows(category, globalName, catData.strings[globalName])
        end
    end
end

-- ONE GLOBAL, ONE REGISTRATION (PRETTYCHAT-R-02). Two categories registering the
-- same GLOBALNAME build two format rows that write the same _G key, and
-- ApplyStrings' fixed CATEGORY_ORDER walk makes the later one win on every pass --
-- the earlier becomes a setting that saves and never applies. That was the Loot
-- copy of LOOT_ITEM_CREATED_SELF[_MULTIPLE] until migration v2 (core/Database.lua).
-- Collected here as `globalName -> { firstCategory, secondCategory, ... }` and
-- reported by runValidation below, loudly at load, without raising.
Schema.duplicateGlobals = {}
do
    local owners = {}
    for _, r in ipairs(rows) do
        if r.kind == "string_format" then
            owners[r.globalName] = owners[r.globalName] or {}
            local cats = owners[r.globalName]
            cats[#cats + 1] = r.category
            if #cats > 1 then Schema.duplicateGlobals[r.globalName] = cats end
        end
    end
end

-- ---------------------------------------------------------------------
-- Load-time integrity check (architecture-§5 / PC-15). Every row's path must
-- resolve to a backing default in NS.Defaults, so drift between the
-- schema and the defaults surfaces loudly at load instead of as a silent
-- nil at runtime. The checked/failed counts are stashed on Schema for
-- the test harness to assert.
-- ---------------------------------------------------------------------

-- The minimap row's backing default, which is the one that is NOT in NS.Defaults
-- and not carried on the row either: it is LibDBIcon's own table, declared in the
-- AceDB `global` defaults, NS.GlobalDefaults in defaults/Profile.lua
-- (launcher-§3). Checked there rather than waved through, so a default deleted from that table surfaces at load
-- through the same channel every other unresolved path takes, instead of as a nil
-- index the first time a player ticks the box.
--
-- Its own function rather than a fourth arm inline: the walk down to `.hide` is
-- four guards on its own and inlining them put resolveBackingDefault over the
-- CCN 15 the complexity gate holds every function in this repo to.
local function minimapDefaultDeclared()
    local global  = NS.GlobalDefaults
    local minimap = global and global.minimap
    return (type(minimap) == "table" and minimap.hide ~= nil) and true or false
end

-- Per-kind resolvers, so the dispatch below is a table lookup rather than a
-- ladder. A kind absent from this table falls through to the per-string arm,
-- which is where string_enabled and string_format both land.
local BACKING_DEFAULT = {
    -- The composed addon-wide rows. Their backing default is the composer's own,
    -- carried on the row, because "General" is a virtual category with no entry
    -- in NS.Defaults to resolve against.
    addon_enabled    = function(row) return row.default ~= nil end,
    addon_visibility = function(row) return row.default ~= nil end,
    -- Session state; nothing stored to back.
    debug_console    = function() return true end,
    minimap_button   = minimapDefaultDeclared,
    category_enabled = function(row) return NS.Defaults[row.category] ~= nil end,
}

local function resolveBackingDefault(row)
    local resolver = BACKING_DEFAULT[row.kind]
    if resolver then return resolver(row) end
    -- string_enabled / string_format both back onto a per-string default.
    local cat = NS.Defaults[row.category]
    return (cat and cat.strings and cat.strings[row.globalName] ~= nil) and true or false
end

-- Re-runnable rather than a bare load-time loop: the Master controls block is
-- spliced in after this file has finished (settings/OptionsSetup.lua), and a
-- validation that had already been taken would have reported on a schema that was
-- three rows short of the one the addon actually runs.
local function runValidation()
    Schema.validation = { checked = 0, failed = 0, misses = {} }
    local function miss(path)
        Schema.validation.failed = Schema.validation.failed + 1
        Schema.validation.misses[#Schema.validation.misses + 1] = path
        if NS.Print then
            NS.Print("schema: unresolved path (no backing default): " .. tostring(path))
        end
    end
    for _, r in ipairs(rows) do
        Schema.validation.checked = Schema.validation.checked + 1
        if not resolveBackingDefault(r) then miss(r.path) end
    end
    for _, path in ipairs(unwiredMasterPaths) do
        Schema.validation.checked = Schema.validation.checked + 1
        miss(path)
    end
    for globalName, cats in pairs(Schema.duplicateGlobals) do
        Schema.validation.failed = Schema.validation.failed + 1
        if NS.Print then
            NS.Print(("schema: %s is registered under more than one category (%s)")
                :format(globalName, table.concat(cats, ", ")))
        end
    end
end

runValidation()

-- ---------------------------------------------------------------------
-- The schema runtime (LibKa0s-Schema-1.0), and its degradation stub
-- ---------------------------------------------------------------------

-- THE DEGRADATION STUB, for a load with no LibKa0s (every major floors on Core, so
-- they are absent together). WRITE-COMPLETING AND LOG-SILENT, the class the
-- library's document names (docs/api/Schema/version-1-docs.md, "The degradation
-- stub"): reads, writes, the row's `validate` (so the PC-R-01 gate still refuses),
-- `announce` (so the re-apply still happens) and the sweep veto all work, because a
-- player still reaches them through `/pc enable` / `/pc disable` (slash-commands-§1)
-- and the Options stub's Reset All (options-ui-§1). What it does not reproduce is
-- what only feeds the debug console: the [Set] line, the bracket's tally and the
-- reset count. core/DebugLogSetup.lua's library-less sink discards those lines
-- anyway.
--
-- The instance id a caller passes is forwarded the way Schema minor 2 forwards it:
-- Get hands it to the row's own `get`, ApplyDefault(row, id) hands it to Set, and
-- Set hands it to validate, normalize, onChange and announce. This addon keeps one
-- instance and no row reads the id today, so this is shape, not behavior: a stub that
-- dropped it would be the one path where a future per-instance row reads nil.
--
-- A DELIBERATE, DOCUMENTED DUPLICATION of the library's reference stub
-- (tests/test_schema.lua upstream, `referenceStub`), kept close to it so the two
-- read alike. tests/test_surface_parity.lua pins its member set against a live
-- instance and against the library by name. Refusals are in this addon's own
-- words, not a copy of the library's STRINGS.
local function stubCopy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = stubCopy(x) end
    return out
end

local SchemaStub = {}

function SchemaStub.SplitPath(path)
    local parts = {}
    if path ~= nil then
        for seg in tostring(path):gmatch("[^%.]+") do parts[#parts + 1] = seg end
    end
    return parts
end

local function stubParts(p) return type(p) == "table" and p or SchemaStub.SplitPath(p) end

function SchemaStub.Read(root, p, first)
    local parts, node = stubParts(p), root
    first = first or 1
    if type(root) ~= "table" or #parts < first then return nil end
    for i = first, #parts do
        if type(node) ~= "table" then return nil end
        node = node[parts[i]]
    end
    return node
end

function SchemaStub.Write(root, p, value, first)
    local parts, node = stubParts(p), root
    first = first or 1
    if type(root) ~= "table" or #parts < first then return end
    for i = first, #parts - 1 do
        if type(node[parts[i]]) ~= "table" then node[parts[i]] = {} end
        node = node[parts[i]]
    end
    node[parts[#parts]] = value
end

function SchemaStub.SameValue(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for k, v in pairs(a) do if not SchemaStub.SameValue(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

-- The instance's reads and registry. Split from its writes only to keep each
-- builder under the CCN 15 the complexity gate holds this repo to.
local function stubReads(S, d, resolve)
    local held = d.rows
    function S.AllRows() return held end
    function S.FindRow(path)
        if type(path) ~= "string" then return nil end
        for _, row in ipairs(held) do
            if type(row) == "table" and row.path == path then return row end
        end
    end
    function S.AddRows(list, at)
        if type(list) ~= "table" then return 0 end
        at = type(at) == "number" and math.floor(at) or #held + 1
        if at > #held + 1 then at = #held + 1 elseif at < 1 then at = 1 end
        for i, row in ipairs(list) do table.insert(held, at + i - 1, row) end
        return #list
    end
    function S.Reindex() end
    function S.Get(path, id)
        local row = S.FindRow(path)
        if row and type(row.get) == "function" then return row.get(id) end
        if type(path) ~= "string" or (row and row.sessionOnly) then return nil end
        local parts = SchemaStub.SplitPath(path)
        local root, first = resolve(parts, id)
        if type(root) ~= "table" then return nil end
        return SchemaStub.Read(root, parts, first)
    end
end

-- Everything the stub checks before it stores, shared by Set and SetMany so a batch
-- refuses on exactly the rules a single write does: the row's validate, then its
-- normalize (which answers the value to store, or nil and why). Answers
-- `true, value` with the value to store, or `false, nil, err, why`.
local function stubPrepare(row, path, value, rid)
    if type(row.validate) == "function" then
        local ok, why = row.validate(value, rid)
        if not ok then return false, nil, "PrettyChat: invalid value for " .. path, why end
    end
    if type(row.normalize) == "function" then
        local out, why = row.normalize(value, rid)
        if out == nil then return false, nil, "PrettyChat: invalid value for " .. path, why end
        value = out
    end
    return true, value
end

-- Where a stored row's write lands: the split path, the root resolveRoot answers (nil
-- when it answers none) with its first segment, and the instance id resolveRoot may
-- rewrite. Split from stubSet, with stubStored, to hold every stub function at CCN
-- 10 or below.
local function stubStored(row) return type(row.set) ~= "function" and not row.sessionOnly end
local function stubTarget(path, id, resolve)
    local parts = SchemaStub.SplitPath(path)
    local r, f, got = resolve(parts, id)
    if type(r) ~= "table" then r, f = nil, nil end
    if got == nil then got = id end
    return parts, r, f, got
end

-- The write seam's order without its log and tally: refuse, validate and normalize,
-- store, react, announce.
local function stubSet(S, d, resolve)
    return function(path, value, id)
        local row = S.FindRow(path)
        if not row then return false, "PrettyChat: no setting " .. tostring(path) end
        local stored = stubStored(row)
        local parts, root, first, rid = nil, nil, nil, id
        if stored then parts, root, first, rid = stubTarget(path, id, resolve) end
        local ok, prepared, err, why = stubPrepare(row, path, value, rid)
        if not ok then return false, err, why end
        value = prepared
        if stored and not root then return false, "PrettyChat: nowhere to store " .. path end
        if type(row.set) == "function" then
            row.set(value)
        elseif stored then
            SchemaStub.Write(root, parts, stubCopy(value), first)
        end
        if type(row.onChange) == "function" then row.onChange(value, rid) end
        if type(d.announce) == "function" then d.announce(row, path, value, rid) end
        return true
    end
end

-- The all-or-nothing batch, without the library's announceBatch tail: this descriptor
-- declares none, so each write's own announce runs, as the live fallback does.
-- Phase 1 checks every entry before anything is stored; phase 2 writes through S.Set,
-- inside one bracket when opts.act is given.
local function stubSetMany(S)
    return function(entries, opts)
        if type(entries) ~= "table" then entries = {} end
        if type(opts) ~= "table" then opts = {} end
        local prepared = {}
        for i, e in ipairs(entries) do
            local row = type(e) == "table" and S.FindRow(e.path)
            if not row then return false, "PrettyChat: no setting " .. tostring(type(e) == "table" and e.path), nil, i end
            local ok, value, err, why = stubPrepare(row, e.path, e.value, opts.instanceId)
            if not ok then return false, err, why, i end
            prepared[i] = value
        end
        local function commit()
            for i, e in ipairs(entries) do S.Set(e.path, prepared[i], opts.instanceId) end
        end
        if opts.act ~= nil then S.BulkRun(opts.act, opts.scope, commit) else commit() end
        return true
    end
end

-- Colon-called like the library's own constructor (`SchemaLib:New{...}`); the
-- receiver is unused because the stub keeps no library-level state.
function SchemaStub.New(_, d)
    local S, depth = {}, 0
    local function resolve(parts, id)
        if type(d.resolveRoot) ~= "function" then return nil end
        return d.resolveRoot(parts, id)
    end
    stubReads(S, d, resolve)
    S.Set = stubSet(S, d, resolve)
    S.SetMany = stubSetMany(S)
    function S.Default(path)
        local row = S.FindRow(path)
        return row and stubCopy(row.default)
    end
    function S.ApplyDefault(row, id)
        if type(row) ~= "table" or type(row.path) ~= "string" or row.default == nil then return false end
        local exempt = d.resetExempt
        if depth > 0 and type(exempt) == "table" and exempt[row.path] then return false end
        return S.Set(row.path, stubCopy(row.default), id)
    end
    -- The bracket keeps its depth, because the sweep veto above reads it; it counts nothing.
    function S.BulkBegin() depth = depth + 1 end
    function S.BulkEnd() if depth > 0 then depth = depth - 1 end end
    function S.BulkRun(act, scope, fn)
        S.BulkBegin(act, scope)
        local ok, err = pcall(fn, { profileReset = false })
        S.BulkEnd(act, scope)
        if not ok then error(err, 0) end
    end
    function S.BulkAdd() end
    function S.InBulk() return depth > 0 end
    function S.CountOffDefault() return 0 end
    function S.ResetCounted(fn) fn() end
    function S.ConsumeResetCount() return nil end
    function S.Validate()
        if type(d.print) == "function" then
            d.print(NS.LIBKA0S_MISSING .. ", so the schema was not checked.")
        end
        return 0, 0, 0
    end
    return S
end

local SchemaLib = LibStub and LibStub("LibKa0s-Schema-1.0", true) or SchemaStub
NS.SchemaLib = SchemaLib

-- ONE INSTANCE, over the live `rows`. No `resolveRoot`: every row carries its own
-- get/set, because the dot path does not map onto db.profile (the path scheme above),
-- so the runtime never walks a stored tree here. Every field is read at call time, so
-- NS.Debug and NS.Print are resolved when a line is written, the way a suite that
-- swaps either one expects.
local S = SchemaLib:New({
    rows = rows,
    -- The write's tail, after the store and the [Set] line. A session-only row
    -- stores nothing and moves no override: showing the debug console must not drag
    -- a full pass over 79 Blizzard globals behind it. The panel refresh still runs,
    -- because the checkbox mirroring the window is what has to move.
    announce = function(row)
        if not row.sessionOnly then PrettyChat:ApplyStrings() end
        Schema.NotifyPanelChange(row.category)
    end,
    -- The single settings-change trace (debug-logging-§10): `[Set] <path> = <value>`,
    -- through the shared value formatter so it reads like `/pc get`. ApplyStrings'
    -- re-apply is an implied consequence and is deliberately not re-echoed.
    debug  = function(tag, fmt, ...) return NS.Debug(tag, fmt, ...) end,
    format = function(row, v) return Schema.FormatValue(row, v) end,
    print  = function(line) return NS.Print(line) end,
})
NS.SchemaRuntime = S

-- ---------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------

-- THE HOST'S NAMES, BOUND TO THE RUNTIME'S MEMBERS. Every caller in core/,
-- modules/ and settings/ keeps calling what it called before; the bodies are the
-- library's. Values, not wrappers, so each one IS the member.
--
--   FindByPath       the index, first-registered wins on a duplicate path (none is)
--   Get              row.get(); nil for a path with no row
--   Set              THE single write seam (architecture-§5), in the library's order:
--                    refuse an unknown path, validate (the PC-R-01 gate above), store
--                    through the row's batched `set`, the [Set] line, `announce`.
--                    Answers true, or false, err[, why].
--   AllRows          the live `rows` table, in declaration order
--   ApplyDefault     one row back to its default, through Set
--   CountChangedRows the stored rows that differ from their default (session-only
--                    rows skipped, because AceDB's profile reset never touches them)
Schema.FindByPath       = S.FindRow
Schema.Get              = S.Get
Schema.Set              = S.Set
Schema.AllRows          = S.AllRows
Schema.ApplyDefault     = S.ApplyDefault
Schema.CountChangedRows = S.CountOffDefault

--- Splice the composed Master controls block in at the HEAD of the schema.
---
--- Called once, from settings/OptionsSetup.lua, on BOTH of that file's paths — the
--- composers are the options instance's, and the instance (or its stub) is the
--- only thing that has them. Idempotent, because CreateOptionsPanel is public and
--- cheap to reach twice.
---
--- The rows land first in declaration order, which is what makes "Master controls"
--- the General page's FIRST tab and what puts them at the head of `/pc list`.
--- `H.MasterControls` also hands back the hook that draws the group's closing
--- button, which settings/Panel.lua wires as that group's `afterGroup`; the group
--- NAME is the hook key, so renaming the group would detach it silently.
function Schema.InstallMasterControls(H)
    if Schema.masterAfterGroup then return end

    local composed, tail = H.MasterControls(MASTER_SPEC)
    local wired = {}
    for _, row in ipairs(composed or {}) do
        local wiring = MASTER_WIRING[row.path]
        if wiring then
            row.category = "General"
            row.kind     = wiring.kind
            row.get      = wiring.get
            row.set      = batched(wiring.set)
            wired[#wired + 1] = row
        else
            -- A canonical leaf this addon has not wired. NOT installed as a
            -- control that reads and writes nothing; reported instead, loudly and
            -- at load, through the channel an unresolved path already takes.
            unwiredMasterPaths[#unwiredMasterPaths + 1] = row.path
        end
    end
    -- At the head, in declaration order, and re-indexed by the runtime.
    S.AddRows(wired, 1)

    Schema.masterAfterGroup = tail or function() end
    runValidation()
    return composed
end

-- THE value formatter, and there is exactly one of it (slash-commands-§5: the value
-- formatter and the colored `key = value` helper are one shared pair, and an addon
-- MUST NOT wrap either in a private variant).
--
-- It lives here, beside the rows it renders, rather than in settings/Slash.lua,
-- because it has two consumers that are not both CLI surfaces: every `list` / `get` /
-- `set` / `reset` echo, which reaches it as the Slash descriptor's `format` hook, and
-- the `[Set] <path> = <value>` debug trace at the write seam, which reaches it as the
-- schema runtime's `format` (debug-logging-§10). Two implementations would let a settings value read one way in
-- chat and another in the console log — for the same stored value, at the same
-- instant.
--
-- The rendering itself is `LibKa0s-Slash-1.0`'s; what is ours is the one thing it
-- cannot know: a Blizzard format string is full of `|c…|r` color escapes, and printed
-- raw they COLOR the line instead of appearing in it. Doubling is WoW's own escape
-- for a literal pipe, and it is the same convention the panel's New box shows and
-- accepts, so a value round-trips between the three surfaces unchanged.
local slashLib = LibStub and LibStub("LibKa0s-Slash-1.0", true)

function Schema.FormatValue(row, v)
    if slashLib then
        local out = slashLib.FormatValue(row, v)
        if type(v) == "string" and v ~= "" then
            out = out:gsub("|", "||")
        end
        return out
    end
    -- Library absent. The [Set] trace still has to say something, and this is the
    -- pre-library rendering rather than a copy of the library's — no color codes,
    -- no `key = value` shape, just the value.
    if v == nil then return "nil" end
    local vtype = row and row.type or type(v)
    if vtype == "bool" or type(v) == "boolean" then return tostring(v) end
    if type(v) == "string" then return (v:gsub("|", "||")) end
    return tostring(v)
end

-- Refresher dispatch. settings/Panel.lua registers a closure for the category
-- TAB it has just drawn via Schema.RegisterRefresher, and drops the previous
-- tab's on the way in; NotifyPanelChange invokes the matching closure (or every
-- closure when the master toggle moves — per-string disabled state depends on the
-- master). At most one category is registered at a time: the visible tab. A tab
-- that is not on screen has no entry, which is correct — it is rebuilt from the
-- live DB the moment it is selected, so it cannot show stale state.
Schema.refreshers = {}

function Schema.RegisterRefresher(category, fn)
    Schema.refreshers[category] = fn
end

function Schema.NotifyPanelChange(category)
    -- Two refresher registries coexist here on purpose, and this is the one place
    -- that has to know about both. The per-string editor is a bespoke three-row
    -- block the library's flow engine cannot express, so its widgets register
    -- through Schema.refreshers below; every widget the library's own makers built
    -- registered on its panel's ctx.refreshers instead. RefreshScalars is the
    -- in-place tier — refreshers only, no rebuild — which is exactly right for a
    -- value write, and it re-reads rather than writing, so it cannot recurse back
    -- into Schema.Set.
    if NS.Helpers and NS.Helpers.RefreshScalars then
        NS.Helpers.RefreshScalars()
    end

    if category == "General" or category == nil then
        for _, fn in pairs(Schema.refreshers) do pcall(fn) end
        return
    end
    local fn = Schema.refreshers[category]
    if fn then pcall(fn) end
end

-- Schema.ApplyDefault restores ONE row, through the same single write seam a panel
-- checkbox and a slash `set` take, so the debug line, the re-apply and the panel
-- refresh are identical on all three paths.
--
-- Deliberately NOT the implementation behind the Categories page's Defaults button
-- or `/pc resetall`. Both of those are bulk: driving them row by row through it
-- would run ApplyStrings once per row (170 passes over 79 globals) and emit one
-- [Set] line per row into a 1500-line console buffer, where debug-logging-§10 asks
-- a bulk reset for ONE [Set] line. The page-wide, per-category and per-string
-- resets take Schema.ResetRows below; `/pc resetall` is the profile reset (options-ui-§12).

-- Schema.CountChangedRows (the runtime's CountOffDefault, bound above) counts every
-- stored row that currently differs from its default. Session-only rows are
-- skipped, because AceDB's profile reset never touches them.
--
-- NOT, on its own, "the rows a profile reset would rewrite" — it used to be
-- described that way and the description was one row wrong. `global.minimap.shown`
-- (stored as db.global.minimap.hide) is stored, differs whenever the player has
-- hidden the button, and lives in the GLOBAL store, which a profile reset does not reach (launcher-§3). So this is one
-- half of a subtraction: PrettyChat:ResetAll takes it before the wipe, because
-- nothing can count a change after it has happened, and core/PrettyChat.lua's
-- OnProfileReset takes it again afterwards and reports the difference. A row the
-- reset cannot reach appears in both readings and cancels out, which is why
-- neither side needs a list of them.

-- THE BATCHED ENTRY (architecture-§5, #15). Restore a list of rows to their
-- defaults through the same write step Schema.Set takes, then pay the two side
-- effects ONCE: one ApplyStrings pass, one panel refresh, and ONE
-- `[Set] reset <label>: N rows` line in place of a [Set] line per row
-- (debug-logging-§10). PrettyChat:ResetCategoriesPage (the Categories page's
-- Defaults button), PrettyChat:ResetCategory and PrettyChat:ResetString are its
-- callers.
--
-- The act is the schema runtime's own (issue #18): one S.BulkRun('reset', label)
-- bracket, whose close writes the line, with S.BulkAdd(1) per row that reads back
-- changed after its write. That read-back is the runtime's own meaning of N: a row
-- already at its default is still written (a no-op) but not counted, and a reset
-- with nothing to change still runs its one pass and logs its one line, as
-- `: 0 rows`.
--
-- The gates are Set's, asked up front: a row this schema does not own is skipped,
-- and the conversion-signature gate is asked (a shipped default always passes it).
-- A list with no row past them is not an act: no bracket, no line, and 0 back.
-- A batch made only of session-only rows skips the re-apply. The refresh targets
-- the rows' category when they share one, and every page when they do not.
-- Returns N.
--
-- A raise partway (a row's set(), the pass or the refresh) happens INSIDE the
-- bracket, so its close still writes the one line, counting the rows changed
-- before the raise and ending in the library's ` (stopped by an error)` (the same
-- text as NS.Util.STOPPED), and BulkRun then raises the error again, unchanged.
local function eligibleRows(list)
    local out = {}
    for _, row in ipairs(list or {}) do
        if S.FindRow(row.path) == row and not refusedBySignature(row, row.default) then
            out[#out + 1] = row
        end
    end
    return out
end

local function resetWalk(eligible, counter)
    local reapply, category = false, nil
    for _, row in ipairs(eligible) do
        local before = row.get()
        -- Batched for the same reason Schema.Set's single write is: resetting
        -- `General.enabled` fires a latch arm, and the batch's one pass below
        -- is that arm's pass too. It has to be per ROW rather than around the
        -- whole loop, so the registration work of an arm fired by row N is done
        -- before row N+1 reads the state it left.
        PrettyChat.Batch(function() row.set(row.default) end)
        if row.get() ~= before then
            S.BulkAdd(1)
            counter.n = counter.n + 1
        end
        reapply = reapply or not row.sessionOnly
        if category == nil then
            category = row.category
        elseif category ~= row.category then
            category = false
        end
    end
    if reapply then PrettyChat:ApplyStrings() end
    Schema.NotifyPanelChange(category or nil)
end

function Schema.ResetRows(list, label)
    local eligible = eligibleRows(list)
    if #eligible == 0 then return 0 end
    local counter = { n = 0 }
    S.BulkRun("reset", label, function() resetWalk(eligible, counter) end)
    return counter.n
end

function Schema.RowsByCategory(category)
    local out = {}
    for _, r in ipairs(rows) do
        if r.category == category then out[#out + 1] = r end
    end
    return out
end

-- Case-insensitive category lookup. Returns the canonical PascalCase
-- name from CATEGORY_ORDER if found, nil otherwise. Used by slash
-- commands so `/pc reset loot` works the same as `/pc reset Loot`.
-- Falls back to an unambiguous case-insensitive prefix match (e.g.
-- `Loo` → `Loot`); ambiguous prefixes return nil so the caller surfaces
-- the same "unknown category" error rather than guessing.
function Schema.ResolveCategory(name)
    if type(name) ~= "string" or name == "" then return nil end
    local lower = name:lower()
    for _, c in ipairs(CATEGORY_ORDER) do
        if c:lower() == lower then return c end
    end
    local matched
    for _, c in ipairs(CATEGORY_ORDER) do
        if c:lower():find(lower, 1, true) == 1 then
            if matched then return nil end
            matched = c
        end
    end
    return matched
end
