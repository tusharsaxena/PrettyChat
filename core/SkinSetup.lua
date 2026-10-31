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
--   NS.PanelEscape(name)    the same for a settings-panel note: the token's Ka0s Default copy
--                           while the Scope's "Ignore settings panel" is ticked, so the notes stay
--                           in the client's look with the rest of the page.
--   NS.SKIN_SOURCE_OPTIONS  the source row's values, and NS.SKIN_OPTIONS the skin row's (every
--   NS.SKIN_OPTIONS         registered skin, in the library's order). settings/Schema.lua reads both.
--   NS.SkinChoice()         the stored (source, skin) pair, read through NS.Schema.Get; "ka0s",
--                           "ka0s" before AceDB has built the profile store.
--   NS.WriteSkinChoice(s,k,i,m) THE WRITE SEAM (architecture-§5): every half through NS.Schema.Set,
--                           the one seam `/pc set` and the panel already write through. `i`, the
--                           Scope's `{ panel, fonts }`, writes the two exceptions, and `m`, the Font
--                           and texture section's `{ font, texture }`, the two overrides ("" for the
--                           skin's own); its `outline`, when not nil, writes skin.outline.
--   NS.SkinOverride()       the stored overrides: font, texture, each an LSM key or false.
--   NS.ApplySkinChoice(s,k) moves the applied skin: `Skin:SetChoice`, which repaints every frame
--                           recorded for this owner and THEN fires OnLooksChanged. No argument
--                           applies the stored pair with the stored exceptions, overrides and outline
--                           (PrettyChat:OnInitialize, every profile event); a nil half keeps that
--                           half (each Skin tab row's onChange).
--   NS.ApplySkinIgnore(p,f) moves the applied exceptions (`Skin:SetIgnore`), live.
--   NS.ApplySkinOverride(f,t) moves the applied overrides (`Skin:SetOverride`), live.
--   NS.SkinOutline()        the stored font outline mode, "hud" until the profile store exists.
--   NS.ApplySkinOutline(m)  moves the applied font outline (`Skin:SetOutline`, LibKa0s v1.82.0,
--                           Skin minor 9, ruling D-06), live; no argument applies the stored mode.
--   NS.SKIN_OUTLINE_OPTIONS the outline row's values: "all", "hud", "off", the library's order.
--   NS.SkinPaintAce(w)      an AceGUI widget this addon acquired itself, painted for this owner
--   NS.SkinPaintAceTree(c)  (`Skin:PaintAce` / `Skin:PaintAceTree`, the owner bound); release
--                           restores stock.
--   NS.SkinOnRelease(w, fn) host release work chained onto the widget's own OnRelease.
--   NS.MaybeShowSkinPicker() the first-run skin picker (LibKa0s OptionsSkinPicker, owner ruling
--                           O3): `O.SkinPicker` while the profile's `skin.pickerSeen` is false, the
--                           addon stands up and the player is out of combat. Answers the frame, or
--                           nil, "queued" behind another Ka0s addon's picker, or nil.
--   NS.HideSkinPicker()     takes a shown picker down (its pending preview put back) or out of the
--                           queue WITHOUT marking it seen: the stand-down, a profile that has seen
--                           it, and first on every profile event.
--   NS.SkinPickerSpec()     the spec NS.MaybeShowSkinPicker hands O.SkinPicker.
--   NS.RunSkinVerb()        the reserved `/pc skin` verb's act (LibKa0s v1.82.0, ruling D-16):
--                           O.SkinVerb(NS.SkinPickerSpec()), the picker on demand whatever
--                           `pickerSeen` says; the library-absent line on nil, "absent".
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
local OUTLINE_PATH = "skin.outline"
local OUTLINE_DEFAULT = "hud"
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
--- call site wrote as a literal keeps its bytes on Ka0s Default. Every call site concatenates the
--- answer, so it is never nil: a token the facade does not resolve (an owner-token definition
--- RegisterOwner refused, or a skin entry that leaves the token alone) takes its Ka0s Default copy
--- in NS.SKIN_FALLBACK, and a token with no copy answers "" (the text in the frame's own color).
local function escape(r, g, b)
    local function byte(v) return math.floor(v * 255 + 0.5) end
    return ("|cff%02x%02x%02x"):format(byte(r), byte(g), byte(b))
end

function NS.SkinEscape(name)
    local r, g, b = NS.Skin.Color(name)
    if r == nil then
        local c = NS.SKIN_FALLBACK[name]
        if not c then return "" end
        r, g, b = c[1], c[2], c[3]
    end
    return escape(r, g, b)
end

--- A settings-panel note's escape. The notes are text on the settings pages, so the Scope's "Ignore
--- settings panel" (a new profile's default) keeps them in the client's look with every other
--- piece of the page: the token's Ka0s Default copy, today's #aaaaaa. Otherwise NS.SkinEscape.
--- Read at build time; a Scope change re-renders the open pages a frame later (OptionsScroll).
--- Not for the list tooltip's lines, which are Blizzard's GameTooltip and outside the Scope.
function NS.PanelEscape(name)
    local c = NS.SKIN_FALLBACK[name]
    if c and Skin and type(Skin.GetIgnore) == "function" and (Skin:GetIgnore(addonName)) then
        return escape(c[1], c[2], c[3])
    end
    return NS.SkinEscape(name)
end

NS.SKIN_SOURCE_OPTIONS = {
    { value = "ka0s", text = NS.L["Ka0s skins"] },
    { value = "eui",  text = "EllesmereUI" },
}

-- The font outline modes (LibKa0s-Skin-1.0 minor 9's OUTLINE_MODES, ruling D-06), with the Skin
-- tab's words: where the skin outlines this addon's text. `/pc set skin.outline` validates against
-- them.
NS.SKIN_OUTLINE_OPTIONS = {
    { value = "all", text = NS.L["All text"] },
    { value = "hud", text = NS.L["HUD text only"] },
    { value = "off", text = NS.L["Off"] },
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
        if media.outline ~= nil then S.Set(OUTLINE_PATH, media.outline) end
    end
end

--- The stored font outline mode: the default's until the profile store exists.
function NS.SkinOutline()
    return schemaGet(OUTLINE_PATH) or OUTLINE_DEFAULT
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

-- ── the first-run skin picker (LibKa0s OptionsSkinPicker, owner ruling O3, decision X6) ───────
--
-- WHEN. Once at login, from PrettyChat:OnEnable after the latch has its answer (OnInitialize
-- applied the stored skin), and again after every profile event (core/PrettyChat.lua's shared
-- adopt path), because a new, copied or reset profile carries its own `pickerSeen`. Never while
-- the addon stands down, and never in combat.
--
-- WHY NOT DEFERRED. LootHistory lights a two-second fuse at login and holds a start in combat for
-- PLAYER_REGEN_ENABLED on an AceEvent target. PrettyChat arms no timer and registers no event of
-- its own while running (core/LifecycleSetup.lua; tests/test_disabled.lua pins both), and it has
-- no AceEvent to embed. So it shows at OnEnable, the way the frameless LibKa0sSkinTester does, and
-- a login in combat (a /reload mid-fight) simply skips: `pickerSeen` is still false, so the next
-- login or profile event out of combat shows it.
--
-- SEEN. The library calls `onClose` once per showing, by any route the player takes (Apply, its
-- close control, the gear, Escape), and once for a picker still queued behind another Ka0s addon's
-- when that addon's "Apply to all Ka0s addons" dismisses it unshown; that is the one write of
-- `skin.pickerSeen`, through NS.Schema.Set. A close this addon makes itself (NS.HideSkinPicker:
-- the stand-down, a profile event) is not the player's and writes nothing.
--
-- NO EYE (decision X6). PrettyChat has no window and no test mode to preview in, so `onPreview`
-- is omitted: the library hides the eye, and only the `settings` icon is declared (CLAUDE.md).
-- A pick previews on the open settings pages and the debug console, which follow the skin live.
--
-- QUEUED. One picker is up at a time across every Ka0s addon: while another addon's is up,
-- O.SkinPicker queues this one and answers nil, "queued", which is passed through.

local PICKER_PATH = "skin.pickerSeen"
local quietClose = false -- true while NS.HideSkinPicker takes the picker down

--- The player's close: the picker seen, and nothing else. The library's put-back already wears the
--- stored choice (it reads `get` at the close), so the skin is not this callback's to move.
local function pickerClosed()
    if quietClose then return end
    local S = NS.Schema
    if not (NS.db and S and S.Set) then return end
    S.Set(PICKER_PATH, true)
end

function NS.SkinPickerSpec()
    return {
        owner = addonName, get = NS.SkinChoice, set = NS.WriteSkinChoice,
        -- The gear opens the General page (its own subcategory) on the Skin tab, whose key is
        -- "Appearance" (settings/Panel.lua's GENERAL_OPTS).
        page = "General", tab = "Appearance",
        onClose = pickerClosed,
    }
end

--- True while this profile has not closed the picker and the addon stands up.
local function pickerDue()
    if not (NS.db and NS.Schema and NS.Schema.Get) then return false end
    if NS.Lifecycle and NS.Lifecycle:IsDown() then return false end
    return schemaGet(PICKER_PATH) == false
end

function NS.HideSkinPicker()
    local O = NS.Helpers
    if not (O and type(O.HideSkinPicker) == "function") then return end
    quietClose = true
    local ok, err = pcall(O.HideSkinPicker)
    quietClose = false
    if not ok then error(err, 0) end
end

--- Show the picker when this profile has not seen it: answers O.SkinPicker's frame, or nil, "queued"
--- while another Ka0s addon's picker is up (it shows when that one closes), or nil.
function NS.MaybeShowSkinPicker()
    local O = NS.Helpers
    if not (O and type(O.SkinPicker) == "function") then return nil end
    if not pickerDue() then
        NS.HideSkinPicker()
        return nil
    end
    local inCombat = _G.InCombatLockdown
    if inCombat and inCombat() then return nil end
    return O.SkinPicker(NS.SkinPickerSpec())
end

--- The reserved `/pc skin` verb's act (LibKa0s v1.82.0, OptionsSkinPicker minor 3, ruling D-16):
--- O.SkinVerb with the spec the first-run start builds, so it shows the picker a new profile shows
--- whatever skin.pickerSeen says. The library prints its own lines (combat on every call, queued,
--- unavailable); without LibKa0s the stub answers nil, "absent" and this prints the library-absent
--- line. The dispatcher refuses the verb while the addon is disabled (a feature verb, not on the
--- live set). Answers the picker's frame, or nil and the reason.
function NS.RunSkinVerb()
    local O = NS.Helpers
    local win, why
    if O and type(O.SkinVerb) == "function" then
        win, why = O.SkinVerb(NS.SkinPickerSpec())
    else
        why = "absent"
    end
    if win == nil and why == "absent" and NS.Print then
        NS.Print(("%s is unavailable: the LibKa0s library did not load."):format("/pc skin"))
    end
    return win, why
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
        "BarTexture", "FontFlags", "HudFontSize",
    }) do S[name] = noop end
    -- The two answers a font setting draws with (LibKa0s v1.82.0, SkinPaintExtras minor 7), never
    -- nil, so a caller's SetFont never reads "no flags" or "no size": a picked flag as stored; From
    -- skin or nothing stored through the stored Font outline, as the library reads it ("OUTLINE"
    -- under "all", "" under "off", and under "hud" "OUTLINE" for the HUD but "" for
    -- `where == "window"`); a stored size above 0 as is, else 12. PrettyChat draws no font of its own.
    S.FontFlags = function(value, where)
        if type(value) == "string" and value ~= S.FROM_SKIN then return value end
        local mode = NS.SkinOutline()
        if mode == "off" or (mode == "hud" and where == "window") then return "" end
        return "OUTLINE"
    end
    S.HudFontSize = function(size)
        local n = tonumber(size)
        if n and n > 0 then return n end
        return 12
    end

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
    function NS.ApplySkinOutline() return false end
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

--- No argument applies the stored outline; the library reads an unknown mode as "hud".
function NS.ApplySkinOutline(mode)
    if type(Skin.SetOutline) ~= "function" then return false end
    if mode == nil then mode = NS.SkinOutline() end
    return Skin:SetOutline(addonName, mode)
end

--- No argument applies the stored pair AND the stored exceptions, overrides and outline; a nil half
--- keeps that half and leaves the rest alone (each Skin tab row).
function NS.ApplySkinChoice(source, skin)
    local whole = source == nil and skin == nil
    if whole then source, skin = NS.SkinChoice() end
    local changed, reload = Skin:SetChoice(addonName, source, skin)
    if reload and NS.Print then NS.Print(RELOAD_LINE) end
    if whole then
        NS.ApplySkinIgnore()
        NS.ApplySkinOverride()
        NS.ApplySkinOutline()
    end
    return changed, reload
end
