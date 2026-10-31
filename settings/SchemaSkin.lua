local _, NS = ...

-- settings/SchemaSkin.lua — the skin.* rows of the settings schema. Peeled out of
-- settings/Schema.lua, which calls Schema.InstallSkinRows at the point these rows have always
-- been declared, so the row order did not move.

local PrettyChat = LibStub("AceAddon-3.0"):GetAddon("PrettyChat")

NS.Schema = NS.Schema or {}
local Schema = NS.Schema

-- ---------------------------------------------------------------------
-- General ▸ Skin (the tab keyed "Appearance", skinning-§3)
--
-- The skin this addon wears, per profile (core/SkinSetup.lua). The tab is the library's
-- O.AppearanceTab (settings/Panel.lua), which draws every skin.* row itself, so each carries
-- `skipRender`: a host tab keyed by a group's name replaces that group's tab. They stay schema
-- rows so the defaults resolve, every reset reaches them, and `/pc get|set skin.skin` validates
-- against `values`. Stored at db.profile.skin, declared in defaults/Profile.lua; category
-- "General", so `/pc list` shows them under General and `/pc list category` never offers `skin`
-- as a message category.
--
-- `noReapply` (decision D8 of the rollout): a skin write changes no chat string, so the write
-- seam's `announce` skips the ApplyStrings pass over every format global and keeps the panel
-- refresh. Each onChange applies ONLY its own half (core/SkinSetup.lua says why).
--
-- Declared AFTER the message categories, so the General page's groups read in strip order, Master
-- controls (spliced in at the head) and then Skin. `/pc list` groups by first appearance, so these
-- still list under General, after the Master controls rows.
-- ---------------------------------------------------------------------

local SKIN_DEFAULTS = NS.ProfileDefaults.profile.skin

local function skinStore()
    local db = PrettyChat.db
    return db and db.profile and db.profile.skin
end

--- Adds the eight skin.* rows through settings/Schema.lua's addRow.
function Schema.InstallSkinRows(addRow)
    local function addSkinRow(leaf, row)
        row.path      = "skin." .. leaf
        row.leaf      = leaf
        row.category  = "General"
        row.page      = "General"
        row.group     = "Appearance"
        row.kind      = "skin"
        row.skipRender = true
        row.noReapply = true
        row.default   = SKIN_DEFAULTS[leaf]
        row.get       = function()
            local store = skinStore()
            local v = store and store[leaf]
            if v == nil then return SKIN_DEFAULTS[leaf] end
            return v
        end
        row.set       = function(v)
            local store = skinStore()
            if store then store[leaf] = v end
        end
        return addRow(row)
    end

    addSkinRow("source", {
        type = "string", widget = "Dropdown", values = NS.SKIN_SOURCE_OPTIONS,
        label = NS.L["Skin source"],
        tooltip = NS.L["Where this addon's look comes from: the Ka0s skin chosen below, or EllesmereUI."],
        onChange = function(v) NS.ApplySkinChoice(v, nil) end,
    })
    addSkinRow("skin", {
        type = "string", widget = "Dropdown", values = NS.SKIN_OPTIONS,
        label = NS.L["Skin"],
        tooltip = NS.L["The Ka0s skin this addon wears. Changes its settings pages and the debug console right away."],
        onChange = function(v) NS.ApplySkinChoice(nil, v) end,
    })
    -- The Scope's two exceptions (LibKa0s-Skin-1.0 minor 5), drawn by the same tab as check boxes.
    addSkinRow("ignorePanel", {
        type = "bool", widget = "CheckBox",
        label = NS.L["Ignore settings panel"],
        tooltip = NS.L["Keep this addon's settings panel in the game's own look. The debug console still wears the skin."],
        onChange = function(v) NS.ApplySkinIgnore(v, nil) end,
    })
    addSkinRow("ignoreFonts", {
        type = "bool", widget = "CheckBox",
        label = NS.L["Ignore fonts"],
        tooltip = NS.L["Keep every font in this addon as the game draws it. The skin still colors the text."],
        onChange = function(v) NS.ApplySkinIgnore(nil, v) end,
    })
    -- The font and texture overrides (LibKa0s-Skin-1.0 minor 6), drawn by the same tab as the library's
    -- previewing pickers of LibSharedMedia keys (options-ui-§23). Free text, not `values`: a media pack may register its keys after this file
    -- loads, and `/pc set` takes any key. "" is the skin's own.
    addSkinRow("font", {
        type = "string", widget = "EditBox",
        label = NS.L["Font"],
        tooltip = NS.L["The font this addon's text uses, over the skin's own. Empty keeps the skin's."],
        onChange = function(v) NS.ApplySkinOverride(v, nil) end,
    })
    addSkinRow("texture", {
        type = "string", widget = "EditBox",
        label = NS.L["Texture"],
        tooltip = NS.L["The texture this addon's bars use, over the skin's own. Empty keeps the skin's."],
        onChange = function(v) NS.ApplySkinOverride(nil, v) end,
    })
    -- The font outline (LibKa0s-Skin-1.0 minor 9, ruling D-06), drawn by the same tab as its "Font
    -- outline" dropdown, which hands the mode to the write seam as media.outline. The library's three
    -- modes, in its order; `/pc set skin.outline` validates against them. Its onChange applies only
    -- its own half.
    addSkinRow("outline", {
        type = "string", widget = "Dropdown", values = NS.SKIN_OUTLINE_OPTIONS,
        label = NS.L["Font outline"],
        tooltip = NS.L["Where the skin outlines this addon's text: all of it, its HUD text only, or nowhere."],
        onChange = function(v) NS.ApplySkinOutline(v) end,
    })
    -- The first-run skin picker's memory: set when the picker closes, so it shows once per profile
    -- (owner ruling O3: false on every profile, old and new). Drawn by nothing; a reset puts it back.
    addSkinRow("pickerSeen", {
        type = "bool", widget = "CheckBox",
        label = NS.L["Skin picker seen"],
        tooltip = NS.L["Whether the first-run skin picker was closed on this profile."],
    })
end
