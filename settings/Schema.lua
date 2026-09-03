local addonName, NS = ...

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

-- Six row kinds. Path scheme:
--   General.enabled                     → addon-wide master toggle (bool)
--   General.visibility                  → addon-wide visibility mode (string enum)
--   state.debugConsole                  → the console window's own toggle (session only)
--   <Category>.enabled                  → category master toggle (bool)
--   <Category>.<GLOBALNAME>.enabled     → per-string enable toggle (bool)
--   <Category>.<GLOBALNAME>.format      → per-string format string
-- The first three are the composed Master controls block below; the last three
-- are this addon's own.
-- The dot path doesn't map 1:1 onto db.profile.categories[...], so each
-- row carries its own get/set closures rather than relying on a generic
-- dot-walker.

local rows = {}        -- ordered, used by /pc list
local byPath = {}      -- O(1) lookup by path string

local function addRow(row)
    rows[#rows + 1] = row
    byPath[row.path] = row
end

-- Row `set` closures are pure DB writes — they do NOT call
-- PrettyChat:ApplyStrings() or Schema.NotifyPanelChange(). Both side
-- effects live in Schema.Set so a future Schema.SetMany / preset-load
-- can apply once per batch instead of once per row. Callers must go
-- through Schema.Set; never invoke row.set(value) directly.

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
-- PrettyChat:IsVisible in modules/Override.lua, which honours all four modes).
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
        enabled    = true,
        visibility = "always",
    },
    -- VERBATIM and unprefixed: session state lives outside the block's own
    -- prefix, and this is the one row whose path the composer does not build.
    debugConsolePath = "state.debugConsole",
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
        tooltip = NS.L["Print a sample of every active format string to the debug console, so you can see what real loot/currency/XP messages will look like. `/pc test` prints the same report to chat."],
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
        get  = function() return PrettyChat:IsAddonEnabled() end,
        set  = function(v)
            PrettyChat.db.profile.enabled = v and true or false
        end,
    },
    ["General.visibility"] = {
        kind = "addon_visibility",
        get  = function() return PrettyChat:GetVisibility() end,
        -- Stored only when it differs from the default, exactly as the per-string
        -- format row clears itself: SavedVariables stays empty until a player has
        -- actually chosen something.
        set  = function(v)
            PrettyChat.db.profile.visibility = (v ~= "always") and v or nil
            PrettyChat:SyncCombatWatch()
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

-- EVERY ROW ON EVERY PAGE CARRIES A `group` (options-ui-§13). These rows are not
-- rendered through the flow engine — the Categories page hands H.TabStrip its tab
-- list directly, because a category tab is one schema row followed by a bespoke
-- 40/60 editor the engine cannot express — but the declaration is what an audit
-- reads and what would partition the page correctly the day that stops being
-- true. The group IS the category, which is the tab it is drawn under.
local function buildCategoryRow(category)
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
        default  = (NS.Defaults[category] and NS.Defaults[category].enabled) and true or false,
        get      = function() return PrettyChat:IsCategoryEnabled(category) end,
        set      = function(v)
            PrettyChat:EnsureCategoryDB(category).enabled = v and true or false
        end,
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
        set        = function(v)
            local catDB = PrettyChat:EnsureCategoryDB(category)
            if not catDB.disabledStrings then catDB.disabledStrings = {} end
            catDB.disabledStrings[globalName] = (not v) or nil
        end,
    })

    addRow({
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
        set        = function(v)
            local catDB = PrettyChat:EnsureCategoryDB(category)
            if not catDB.strings then catDB.strings = {} end
            if v == NS.Defaults[category].strings[globalName].default then
                catDB.strings[globalName] = nil
            else
                catDB.strings[globalName] = v
            end
        end,
    })
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

        local sortedNames = {}
        for globalName in pairs(catData.strings) do
            sortedNames[#sortedNames + 1] = globalName
        end
        table.sort(sortedNames)

        for _, globalName in ipairs(sortedNames) do
            buildStringRows(category, globalName, catData.strings[globalName])
        end
    end
end

-- Globals that NS.Defaults registers under more than one category
-- (today: LOOT_ITEM_CREATED_SELF and LOOT_ITEM_CREATED_SELF_MULTIPLE
-- under both Loot and Tradeskill). Each registration produces a separate
-- string_format row, both writing the same _G[GLOBALNAME] in
-- ApplyStrings — the last category to iterate wins on /reload, and
-- pairs() order is non-deterministic. The panel reads this map to
-- decorate the per-string enable checkbox tooltip so the user can see
-- the conflict in-page rather than discovering it via lost edits.
Schema.crossRegisteredGlobals = {}
do
    local seen = {}
    for _, r in ipairs(rows) do
        if r.kind == "string_format" then
            seen[r.globalName] = seen[r.globalName] or {}
            seen[r.globalName][#seen[r.globalName] + 1] = r.category
        end
    end
    for globalName, cats in pairs(seen) do
        if #cats > 1 then
            Schema.crossRegisteredGlobals[globalName] = cats
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

local function resolveBackingDefault(row)
    if row.kind == "addon_enabled" or row.kind == "addon_visibility" then
        -- The composed addon-wide rows. Their backing default is the composer's
        -- own, carried on the row, because the "General" category is virtual and
        -- has no entry in NS.Defaults to resolve against.
        return row.default ~= nil
    end
    if row.kind == "debug_console" then
        return true                        -- session state; nothing stored to back
    end
    if row.kind == "category_enabled" then
        return NS.Defaults[row.category] ~= nil
    end
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
end

runValidation()

-- ---------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------

function Schema.FindByPath(path)
    return byPath[path]
end

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
    local at = 0
    for _, row in ipairs(composed or {}) do
        local wiring = MASTER_WIRING[row.path]
        if wiring then
            row.category = "General"
            row.kind     = wiring.kind
            row.get      = wiring.get
            row.set      = wiring.set
            at = at + 1
            table.insert(rows, at, row)
            byPath[row.path] = row
        else
            -- A canonical leaf this addon has not wired. NOT installed as a
            -- control that reads and writes nothing; reported instead, loudly and
            -- at load, through the channel an unresolved path already takes.
            unwiredMasterPaths[#unwiredMasterPaths + 1] = row.path
        end
    end

    Schema.masterAfterGroup = tail or function() end
    runValidation()
    return composed
end

function Schema.Get(path)
    local row = byPath[path]
    if not row then return nil end
    return row.get()
end

-- THE value formatter, and there is exactly one of it (slash-commands-§5: the value
-- formatter and the colored `key = value` helper are one shared pair, and an addon
-- MUST NOT wrap either in a private variant).
--
-- It lives here, beside the rows it renders, rather than in settings/Slash.lua,
-- because it has two consumers that are not both CLI surfaces: every `list` / `get` /
-- `set` / `reset` echo, which reaches it as the Slash descriptor's `format` hook, and
-- the `[Set] <path> = <value>` debug trace at the write seam below
-- (debug-logging-§10). Two implementations would let a settings value read one way in
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

-- Set is the single write path for all schema-backed values. Both the
-- panel widgets and the /pc set slash command go through here, so
-- a value change in either surface notifies the other. Owns the two
-- post-write side effects (ApplyStrings + NotifyPanelChange) so row
-- closures can stay pure DB writes.
function Schema.Set(path, value)
    local row = byPath[path]
    if not row then return false end
    row.set(value)
    -- A session-only row stores nothing and moves no override: showing the debug
    -- console must not drag a full pass over 79 Blizzard globals behind it. The
    -- panel refresh below still runs, because the checkbox mirroring the window
    -- is what has to move.
    if not row.sessionOnly then
        PrettyChat:ApplyStrings()
    end
    Schema.NotifyPanelChange(row.category)
    -- The single settings-change trace (debug-logging-§10): logged once here, at the write
    -- seam, as `[Set] <path> = <value>` (shared value formatter, so it reads like /pc get).
    -- ApplyStrings' re-apply is an implied consequence and is deliberately not re-echoed.
    NS.Debug("Set", "%s = %s", path, Schema.FormatValue(row, value))
    return true
end

-- Every row, in DECLARATION order — which is the order `/pc list` prints and the
-- order the settings tree shows, so the two can never disagree. Returned as the
-- live table rather than a copy: callers iterate it, and a per-call copy of 173
-- rows on every `list` would be a real cost for no safety nobody asked for.
function Schema.AllRows()
    return rows
end

-- Restore ONE row to its default, through the same single write seam a panel
-- checkbox and a slash `set` take, so the debug line, the re-apply and the panel
-- refresh are identical on all three paths.
--
-- Deliberately NOT the implementation behind the per-category Defaults button or
-- `/pc resetall`. Both of those are bulk: driving them row by row through here
-- would run ApplyStrings once per row (173 passes over 79 globals) and emit one
-- [Set] line per row into a 1500-line console buffer, which is exactly the per-item
-- spam debug-logging-§9 forbids. PrettyChat:ResetCategory and PrettyChat:ResetAll
-- stay the bulk implementations, each one pass and one summary line.
function Schema.ApplyDefault(row)
    if not row then return false end
    return Schema.Set(row.path, row.default)
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
