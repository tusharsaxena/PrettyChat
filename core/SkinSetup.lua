local addonName, NS = ...

-- core/SkinSetup.lua — the LibKa0s-Skin-1.0 seam: which skin this addon wears (skinning-§1, §3).
--
-- ── WHAT IT PUBLISHES ────────────────────────────────────────────────────────────────────────
--
--   NS.Skin                 the owner's facade, `Skin:For("PrettyChat")`: the painting vocabulary
--                           and Token / Color / Resolve / OnLooksChanged. Every color this addon
--                           writes itself reads here.
--   NS.SKIN_TOKENS          this addon's owner tokens (skinning-§1, LibKa0s Skin minor 7), handed
--                           to RegisterOwner: the colors no library token holds exactly.
--   NS.SKIN_FALLBACK        the Ka0s Default tokens the DEGRADED facade answers.
--   NS.SkinColor(name)      a color token as a call site writes it (three components when opaque).
--   NS.SkinEscape(name)     a color token as a "|cffrrggbb" escape, rounded to the byte, so markup
--                           written as a literal keeps its bytes on Ka0s Default (|cffaaaaaa).
--   NS.SKIN_SOURCE_OPTIONS  the source row's values, and NS.SKIN_OPTIONS the skin row's (every
--   NS.SKIN_OPTIONS         registered skin, in the library's order). settings/Schema.lua reads both.
--   NS.SkinChoice()         the stored (source, skin) pair, read through NS.Schema.Get; "ka0s",
--                           "ka0s" before AceDB has built the profile store.
--   NS.WriteSkinChoice(s,k,i,m) THE WRITE SEAM (architecture-§5): every half through NS.Schema.Set,
--                           the one seam `/pc set` and the panel already write through. `i`, the
--                           Scope's `{ panel, fonts }`, writes the two exceptions, and `m`, the Font
--                           and texture section's `{ font, texture }`, the two overrides ("" for the
--                           skin's own).
--   NS.SkinOverride()       the stored overrides: font, texture, each an LSM key or false.
--   NS.ApplySkinChoice(s,k) moves the applied skin: `Skin:SetChoice`, which repaints every frame
--                           recorded for this owner and THEN fires OnLooksChanged. No argument
--                           applies the stored pair with the stored exceptions and overrides
--                           (PrettyChat:OnInitialize, every profile event); a nil half keeps that
--                           half (each Skin tab row's onChange).
--   NS.ApplySkinIgnore(p,f) moves the applied exceptions (`Skin:SetIgnore`), live.
--   NS.ApplySkinOverride(f,t) moves the applied overrides (`Skin:SetOverride`), live.
--   NS.SkinPaintAce(w)      an AceGUI widget this addon acquired itself, painted for this owner
--   NS.SkinPaintAceTree(c)  (`Skin:PaintAce` / `Skin:PaintAceTree`, the owner bound); release
--                           restores stock.
--   NS.SkinOnRelease(w, fn) host release work chained onto the widget's own OnRelease.
--
-- ── WHERE IT LOADS ───────────────────────────────────────────────────────────────────────────
--
-- After core/CoreSetup.lua (NS.Print, which the reload line goes through at call time) and before
-- settings/Schema.lua, which reads NS.SKIN_OPTIONS and NS.SKIN_SOURCE_OPTIONS at file load.
-- Registered at FILE LOAD (skinning-§1), so the EllesmereUI provider can offer the owner before
-- EllesmereUI dispatches its skins. RegisterOwner calls `get` once, before AceDB exists, and it
-- answers Ka0s Default; the profile's choice is applied by NS.ApplySkinChoice right after AceDB:New
-- (core/PrettyChat.lua).
--
-- ── WHY A ROW'S onChange PASSES ONE HALF ─────────────────────────────────────────────────────
--
-- The Skin tab and another addon's "Copy to every Ka0s addon" both call Skin:SetChoice FIRST and
-- write the store after, one half at a time. A row reaction that re-applied the whole stored pair
-- would apply the half-written one in between: a second repaint, to a skin the player never
-- picked. Applying only the row's own half against the applied choice makes each write a no-op
-- (SetChoice is idempotent), so a pick is ONE effective SetChoice and one repaint, while a bare
-- `/pc set skin.skin obsidian` still repaints.

local Skin = LibStub and LibStub("LibKa0s-Skin-1.0", true)

local SOURCE_PATH, SKIN_PATH = "skin.source", "skin.skin"
local PANEL_PATH, FONTS_PATH = "skin.ignorePanel", "skin.ignoreFonts"
local FONT_PATH, TEXTURE_PATH = "skin.font", "skin.texture"
local DEFAULT = "ka0s"
local LABEL = "Ka0s Pretty Chat"

-- This addon's owner tokens (skinning-§1; Ka0sAddonsCommonTasks docs/2026-10-29-SKINNING_ROLLOUT/
-- gap PC-G2, decisions X1, X2 and X12). The settings pages and the tooltip lines PrettyChat writes
-- draw their notes in #aaaaaa (NS.Const.Color.gray), and no library token holds that value: the
-- nearest, text.muted and gtip.subtle, would move Ka0s Default by nine levels a channel. So each is
-- a name of this addon's own, `default` today's exact pixel (170/255, so NS.SkinEscape answers
-- |cffaaaaaa), following the nearest library ROLE token in every other skin and under EllesmereUI.
-- Two names rather than one, because a tooltip line follows the gtip family, which no skin
-- darkens, and a page note the text family.
NS.SKIN_TOKENS = {
    ["pc.note"]    = { default = { 170 / 255, 170 / 255, 170 / 255, 1 }, follow = "text.muted" },
    ["pc.tipNote"] = { default = { 170 / 255, 170 / 255, 170 / 255, 1 }, follow = "gtip.subtle" },
}

-- The Ka0s Default tokens the DEGRADED facade answers, limited to the ones this addon reads: its
-- owner tokens' defaults, and the library tokens a call site names, each copied from the library's
-- Ka0s Default. tests/test_skinsetup.lua holds every entry to the live library's value for this
-- owner, so a copy that drifts goes red. A surface converted to a token adds it here in the same
-- change.
NS.SKIN_FALLBACK = NS.SKIN_FALLBACK or {}
for name, def in pairs(NS.SKIN_TOKENS) do NS.SKIN_FALLBACK[name] = def.default end
-- The list entry's tooltip title (settings/Panel.lua, decision D2): WHITE, the 1, 1, 1 it typed.
NS.SKIN_FALLBACK["gtip.value"] = { 1, 1, 1, 1 }

--- A color token's components AS A CALL SITE WRITES THEM: r, g, b for an opaque color and r, g, b,
--- a otherwise, so a site that passed three components before it read a token still passes three
--- on Ka0s Default. nil for a token the skin leaves alone. Read through NS.Skin at call time.
function NS.SkinColor(name)
    local r, g, b, a = NS.Skin.Color(name)
    if r == nil then return nil end
    if a == nil or a == 1 then return r, g, b end
    return r, g, b, a
end

--- A color token as a "|cffrrggbb" escape, each channel rounded to the nearest byte, so markup a
--- call site wrote as a literal keeps its bytes on Ka0s Default. nil for a token the skin leaves
--- alone.
function NS.SkinEscape(name)
    local r, g, b = NS.Skin.Color(name)
    if r == nil then return nil end
    local function byte(v) return math.floor(v * 255 + 0.5) end
    return ("|cff%02x%02x%02x"):format(byte(r), byte(g), byte(b))
end

NS.SKIN_SOURCE_OPTIONS = {
    { value = "ka0s", text = NS.L["Ka0s skins"] },
    { value = "eui",  text = "EllesmereUI" },
}

-- The skin row's values: every registered skin, Ka0s Default first. Without the library the one
-- skin the degraded facade can draw.
NS.SKIN_OPTIONS = NS.SKIN_OPTIONS or {}
if Skin and type(Skin.Skins) == "function" then
    for _, def in ipairs(Skin:Skins()) do
        NS.SKIN_OPTIONS[#NS.SKIN_OPTIONS + 1] = { value = def.key, text = def.label or def.key }
    end
end
if #NS.SKIN_OPTIONS == 0 then NS.SKIN_OPTIONS[1] = { value = DEFAULT, text = "Ka0s Default" } end

-- The schema's read and write, nil-safely: NS.Schema is settings/Schema.lua's and NS.db AceDB's,
-- and neither exists while this file loads. Dot calls: settings/Schema.lua binds the runtime's
-- members as values (Schema.Get = S.Get).
local function schemaGet(path)
    local S = NS.Schema
    if not (NS.db and S and S.Get) then return nil end
    return S.Get(path)
end

--- The stored pair: Ka0s Default until the profile store exists.
function NS.SkinChoice()
    return schemaGet(SOURCE_PATH) or DEFAULT, schemaGet(SKIN_PATH) or DEFAULT
end

--- A stored override as the profile keeps it: the LSM key, or "" for the skin's own.
local function storedKey(v)
    if type(v) == "string" and v ~= "" then return v end
    return ""
end

--- The write seam: every half through NS.Schema.Set (validate, store, the [Set] line, onChange).
function NS.WriteSkinChoice(source, skin, ignore, media)
    local S = NS.Schema
    if not (NS.db and S and S.Set) then return end
    if source ~= nil then S.Set(SOURCE_PATH, source) end
    if skin ~= nil then S.Set(SKIN_PATH, skin) end
    if type(ignore) == "table" then
        S.Set(PANEL_PATH, ignore.panel == true)
        S.Set(FONTS_PATH, ignore.fonts == true)
    end
    if type(media) == "table" then
        S.Set(FONT_PATH, storedKey(media.font))
        S.Set(TEXTURE_PATH, storedKey(media.texture))
    end
end

--- The stored overrides: each an LSM key, or false for the skin's own.
function NS.SkinOverride()
    local font, texture = storedKey(schemaGet(FONT_PATH)), storedKey(schemaGet(TEXTURE_PATH))
    return font ~= "" and font or false, texture ~= "" and texture or false
end

--- The stored exceptions: the defaults' own until the profile store exists.
local function storedIgnore()
    if not NS.db then return true, false end
    return schemaGet(PANEL_PATH) == true, schemaGet(FONTS_PATH) == true
end

-- AceGUI keeps ONE callback per event name (options-ui-§19). Without the library's chain there is
-- no skin restore to share the release with, so the host's work takes the callback.
local function releaseByCallback(widget, fn)
    if type(widget) ~= "table" or type(fn) ~= "function" or type(widget.SetCallback) ~= "function" then
        return nil
    end
    widget:SetCallback("OnRelease", function(w) fn(w) end)
    return fn
end

-- ── the degraded arm ─────────────────────────────────────────────────────────────────────────

if not Skin then
    local function color(name)
        local c = NS.SKIN_FALLBACK[name]
        if c then return c[1], c[2], c[3], c[4] or 1 end
    end
    local function noop() end
    local S = { owner = addonName, apiVersion = 3, FROM_SKIN = "@skin" }
    -- Every vocabulary name answers, as a no-op that never raises: this addon draws no frame of its
    -- own, so no primitive has a host meaning here. The list is LibKa0s-Skin-1.0's VOCAB;
    -- tests/test_skinsetup.lua holds this table to the live facade key for key.
    for _, name in ipairs({
        "Shell", "Panel", "Inset", "FadeRegions", "FadeNineSlice", "Button", "WhiteButtonLabel",
        "StateButtonLabel", "EditBox", "Checkbox", "Dropdown", "ScrollBar", "Tab", "SetTabSelection",
        "CloseButton", "PageButton", "SquareIcon", "SortHeaderBar", "Font", "White", "ApplyBarFill",
        "GetAccentColor", "GetPanelColor", "GetFont",
        "TitleBar", "Divider", "Footer", "Card", "Slider", "NavItem", "Drawer", "ListRow", "MenuFrame",
        "Tooltip", "Strip", "Cover", "Text", "ChartStyle", "BarStyle", "IconBorder", "GlowColor",
        "BarTexture",
    }) do S[name] = noop end

    S.Token = function(name) return NS.SKIN_FALLBACK[name] end
    S.Color = color
    S.Resolve = function(kind, value, fromSkin)
        if fromSkin or value == S.FROM_SKIN then return S.Token(kind) end
        return value
    end
    S.OnLooksChanged = function(fn) return fn end   -- the skin never changes without the library
    S.IsEnabled = function() return false end
    S.GetStyle = function() return "ka0s:" .. DEFAULT end

    NS.Skin = S
    function NS.ApplySkinChoice() return false, false end
    function NS.ApplySkinIgnore() return false, false end
    function NS.ApplySkinOverride() return false end
    -- Nothing to paint an AceGUI row with: stock AceGUI, as the client draws it.
    function NS.SkinPaintAce() return false end
    function NS.SkinPaintAceTree() return 0 end
    NS.SkinOnRelease = releaseByCallback
    return
end

-- ── the live seam ────────────────────────────────────────────────────────────────────────────

NS.Skin = Skin:For(addonName)
Skin:RegisterOwner(addonName, {
    label  = LABEL,
    get    = NS.SkinChoice,
    set    = NS.WriteSkinChoice,
    tokens = NS.SKIN_TOKENS,
    -- A refused owner-token definition is logged once, to the debug console rather than the
    -- client's error handler. Late-bound: NS.Debug is core/DebugLogSetup.lua's, a line below.
    log    = function(line) if NS.Debug then NS.Debug("Skin", "%s", tostring(line)) end end,
})

-- The one line a reload request earns on the path that has no popup of its own (a profile event
-- leaving an EllesmereUI that painted this session). The Skin tab raises the library's popup for
-- its own picks.
local RELOAD_LINE = NS.L["Reload your interface (/reload) to finish changing the skin."]

-- The AceGUI rows (SkinAce.lua). Each guards on the member, so a copy whose SkinAce secondary did
-- not attach paints nothing.
function NS.SkinPaintAce(widget)
    if type(Skin.PaintAce) ~= "function" then return false end
    return Skin:PaintAce(addonName, widget)
end

function NS.SkinPaintAceTree(container)
    if type(Skin.PaintAceTree) ~= "function" then return 0 end
    return Skin:PaintAceTree(addonName, container)
end

function NS.SkinOnRelease(widget, fn)
    if type(Skin.OnRelease) ~= "function" then return releaseByCallback(widget, fn) end
    return Skin:OnRelease(widget, fn)
end

--- No argument applies the stored exceptions; a nil half keeps that half.
function NS.ApplySkinIgnore(panel, fonts)
    if type(Skin.SetIgnore) ~= "function" then return false, false end
    if panel == nil and fonts == nil then panel, fonts = storedIgnore() end
    local changed, reload = Skin:SetIgnore(addonName, panel, fonts)
    if reload and NS.Print then NS.Print(RELOAD_LINE) end
    return changed, reload
end

--- No argument applies the stored overrides; a nil half keeps that half, false or "" clears it.
function NS.ApplySkinOverride(font, texture)
    if type(Skin.SetOverride) ~= "function" then return false end
    if font == nil and texture == nil then font, texture = NS.SkinOverride() end
    return Skin:SetOverride(addonName, font, texture)
end

--- No argument applies the stored pair AND the stored exceptions and overrides; a nil half keeps
--- that half and leaves the rest alone (each Skin tab row).
function NS.ApplySkinChoice(source, skin)
    local whole = source == nil and skin == nil
    if whole then source, skin = NS.SkinChoice() end
    local changed, reload = Skin:SetChoice(addonName, source, skin)
    if reload and NS.Print then NS.Print(RELOAD_LINE) end
    if whole then
        NS.ApplySkinIgnore()
        NS.ApplySkinOverride()
    end
    return changed, reload
end
