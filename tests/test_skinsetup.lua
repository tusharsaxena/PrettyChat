-- tests/test_skinsetup.lua — the LibKa0s-Skin-1.0 seam (core/SkinSetup.lua, skinning-§1 to §3).
--
-- What this addon owes the skin engine, and nothing the library pins itself: the owner is
-- registered under the folder name with this addon's read and write seams and its two owner
-- tokens; the seven skin.* keys default to Ka0s Default and are skipRender schema rows on the
-- General page's Skin tab (group "Appearance"); a skin write changes no chat string, so it skips
-- the ApplyStrings pass (decision D8); the profile's skin is applied right after AceDB exists and
-- on every profile event; one pick, from this addon's tab or from another addon's copy, is ONE
-- effective SetChoice (one OnLooksChanged), however many store writes follow it; and the degraded
-- facade answers every name the live one carries, with Ka0s Default's values.
--
-- Every case builds its own instance (tests/loader.lua), so no case inherits another's skin.

local ctx  = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local OWNER = "PrettyChat"

--- A fresh live instance, its Skin library, and a repaint counter on its facade.
local function live()
    local inst = ctx.loadAddon()
    local Skin = inst.env.LibStub("LibKa0s-Skin-1.0")
    local counter = { looks = 0 }
    inst.NS.Skin.OnLooksChanged(function() counter.looks = counter.looks + 1 end)
    return inst, Skin, counter
end

--- Run a `/pc` line with the chat transcript silenced.
local function slash(inst, line)
    local cf = inst.env.DEFAULT_CHAT_FRAME
    local add = cf.AddMessage
    cf.AddMessage = function() end
    local ok, err = pcall(inst.addon.OnSlashCommand, inst.addon, line)
    cf.AddMessage = add
    if not ok then error(err, 0) end
end

local SKIN_PATHS = {
    "skin.source", "skin.skin", "skin.ignorePanel", "skin.ignoreFonts", "skin.font", "skin.texture",
    "skin.pickerSeen",
}

-- ── the owner ────────────────────────────────────────────────────────────────────────────────

test("Skin seam: the owner is the folder name, and NS.Skin is its facade", function()
    -- red under: registering under the brand or a typo (the library keys every frame and every
    -- listener by owner), or publishing a facade of some other owner.
    local inst, Skin = live()
    t.truthy(Skin:IsOwner(OWNER), "core/SkinSetup.lua did not register the owner")
    t.truthy(rawequal(inst.NS.Skin, Skin:For(OWNER)), "NS.Skin is not Skin:For(\"PrettyChat\")")
    t.eq(inst.NS.Skin.owner, OWNER)
    t.eq(Skin:OwnerLabel(OWNER), "Ka0s Pretty Chat", "the copy confirmation names the addon by its brand")
end)

test("Skin seam: the read answers Ka0s Default before the profile store exists", function()
    -- RegisterOwner calls `get` at FILE LOAD, before AceDB:New; a getter that raised there would be
    -- a visible Lua error on every login.
    local inst = live()
    local NS = inst.NS
    local db = NS.db
    NS.db = nil
    local ok, source, skin = pcall(NS.SkinChoice)
    NS.db = db
    t.truthy(ok, "NS.SkinChoice raised without a store: " .. tostring(source))
    t.eq(source, "ka0s")
    t.eq(skin, "ka0s")
end)

test("Skin seam: the owner tokens keep Ka0s Default's #aaaaaa and follow the skin elsewhere", function()
    -- X1/X2/X12: pc.note and pc.tipNote are today's exact gray on Ka0s Default, and the nearest
    -- library ROLE token in every other skin. red under: a token snapped to text.muted on Ka0s
    -- Default (|cffb3b3b8), a name the library refuses (a library family), or no follow.
    local inst, Skin = live()
    local NS = inst.NS
    t.eq(NS.SkinEscape("pc.note"), "|cffaaaaaa", "the page note on Ka0s Default")
    t.eq(NS.SkinEscape("pc.tipNote"), "|cffaaaaaa", "the tooltip note on Ka0s Default")
    local r, g, b = NS.SkinColor("pc.note")
    t.eq(select("#", NS.SkinColor("pc.note")), 3, "an opaque token is three components")
    t.truthy(math.abs(r - 170 / 255) < 1e-6 and r == g and g == b, "pc.note is 170/255 gray")
    Skin:SetChoice(OWNER, "ka0s", "obsidian")
    local obsidian = Skin:ResolveSkin("obsidian")
    local pr, pg, pb = NS.Skin.Color("pc.note")
    local m = obsidian["text.muted"]
    t.truthy(pr == m[1] and pg == m[2] and pb == m[3], "pc.note follows text.muted under Obsidian")
    local tr, tg, tb = NS.Skin.Color("pc.tipNote")
    local s = obsidian["gtip.subtle"]
    t.truthy(tr == s[1] and tg == s[2] and tb == s[3], "pc.tipNote follows gtip.subtle under Obsidian")
end)

-- ── the keys and the rows ────────────────────────────────────────────────────────────────────

test("Skin seam: the seven skin keys default to Ka0s Default, as skipRender Skin-tab rows", function()
    -- red under: a default other than today's look, a row that renders itself on top of the
    -- library's tab, or a row on some other page or tab.
    local inst = live()
    local NS = inst.NS
    local d = NS.ProfileDefaults.profile.skin
    t.eq(d.source, "ka0s")
    t.eq(d.skin, "ka0s")
    t.eq(d.ignorePanel, true, "a new profile leaves the settings panel the client's")
    t.eq(d.ignoreFonts, false, "and skins the fonts")
    t.eq(d.font, "")
    t.eq(d.texture, "")
    t.eq(d.pickerSeen, false, "O3: the first-run picker shows on every profile")
    for _, path in ipairs(SKIN_PATHS) do
        local row = NS.Schema.FindByPath(path)
        t.truthy(row ~= nil, path .. " is not a schema row")
        t.eq(row.page, "General", path .. ": page")
        t.eq(row.group, "Appearance", path .. ": group, the key O.AppearanceTab answers")
        t.eq(row.category, "General", path .. ": category")
        t.truthy(row.skipRender == true, path .. ": the tab draws it, so it must be skipRender")
        t.eq(NS.Schema.Get(path), row.default, path .. ": reads its default on a fresh profile")
    end
end)

test("Skin seam: the skin row's values are every registered skin, in the library's order", function()
    local inst, Skin = live()
    local values = inst.NS.Schema.FindByPath("skin.skin").values
    local skins = Skin:Skins()
    t.eq(#values, #skins, "one value per registered skin")
    for i, def in ipairs(skins) do t.eq(values[i].value, def.key, "value " .. i) end
    t.eq(values[1].value, "ka0s", "Ka0s Default first")
end)

test("Skin seam: /pc list category never offers skin as a message category", function()
    -- D7: the rows are stored under the virtual General category, so the category list is
    -- CATEGORY_ORDER's and nothing else.
    local inst = live()
    for _, c in ipairs(inst.NS.Schema.CATEGORY_ORDER) do
        t.neq(c:lower(), "skin", "CATEGORY_ORDER carries a skin category")
    end
end)

-- ── the write seam ───────────────────────────────────────────────────────────────────────────

test("Skin seam: /pc set refuses an unknown skin and applies a registered one, one repaint", function()
    local inst, Skin, counter = live()
    local NS = inst.NS
    slash(inst, "set skin.skin no-such-skin")
    t.eq(NS.db.profile.skin.skin, "ka0s", "an unknown skin was stored")
    t.eq(counter.looks, 0, "a refused set repainted")
    slash(inst, "set skin.skin obsidian")
    t.eq(NS.db.profile.skin.skin, "obsidian", "a registered skin was refused")
    t.eq(select(2, Skin:GetChoice(OWNER)), "obsidian", "a bare set must move the applied skin")
    t.eq(counter.looks, 1, "one set, one repaint")
end)

test("Skin seam: a skin write re-applies no chat string (D8), and still refreshes the panel", function()
    -- red under: the announce tail running ApplyStrings for a skin.* row, a pass over every
    -- format global for a write that changes none of them.
    local inst = live()
    local NS, addon = inst.NS, inst.addon
    local apply, applied = addon.ApplyStrings, 0
    addon.ApplyStrings = function(...) applied = applied + 1; return apply(...) end
    local notify, notified = NS.Schema.NotifyPanelChange, 0
    NS.Schema.NotifyPanelChange = function(...) notified = notified + 1; return notify(...) end
    local ok, err = pcall(function()
        NS.Schema.Set("skin.skin", "glass")
        NS.Schema.Set("skin.ignoreFonts", true)
        t.eq(applied, 0, "a skin write ran ApplyStrings")
        t.truthy(notified >= 2, "a skin write must still refresh the panel")
        NS.Schema.Set("General.enabled", true)
    end)
    addon.ApplyStrings, NS.Schema.NotifyPanelChange = apply, notify
    if not ok then error(err, 0) end
end)

test("Skin seam: WriteSkinChoice writes every half through the schema, and the overrides as keys", function()
    local inst, Skin = live()
    local NS = inst.NS
    local set, seen = NS.Schema.Set, {}
    NS.Schema.Set = function(path, v) seen[#seen + 1] = path; return set(path, v) end
    local ok, err = pcall(NS.WriteSkinChoice, "ka0s", "ember", { panel = false, fonts = true },
        { font = "Oxanium", texture = false })
    NS.Schema.Set = set
    if not ok then error(err, 0) end
    t.eq(table.concat(seen, ","),
        "skin.source,skin.skin,skin.ignorePanel,skin.ignoreFonts,skin.font,skin.texture",
        "every half lands through NS.Schema.Set, the seam /pc set writes through")
    local s = NS.db.profile.skin
    t.eq(s.skin, "ember")
    t.eq(s.ignorePanel, false)
    t.eq(s.ignoreFonts, true)
    t.eq(s.font, "Oxanium")
    t.eq(s.texture, "", "false is the skin's own, stored as \"\"")
    t.eq(select(2, Skin:GetChoice(OWNER)), "ember", "the skin row's onChange applied its half")
    local font, texture = NS.SkinOverride()
    t.eq(font, "Oxanium")
    t.eq(texture, false)
end)

-- ── the tab ──────────────────────────────────────────────────────────────────────────────────

--- Show General, click its Skin tab, and answer the CheckBox whose label ends with `name`.
local function skinTabChoice(inst, name)
    local env = inst.env
    for _, sub in ipairs(env._settings.subcategories) do
        if sub.name == "General" then sub.frame:Show() end
    end
    local page = inst.NS.Helpers.__panelFor("General")
    local mark = #env._widgets
    for _, b in ipairs(page.__tabLayout.buttons) do
        if b.text == "Skin" then b:FireScript("OnClick") end
    end
    t.eq(page.activeTab, "Appearance", "the Skin tab opened")
    for i = mark + 1, #env._widgets do
        local w = env._widgets[i]
        local label = tostring(w.labelText or "")
        if w.type == "CheckBox" and label:sub(-#name) == name then return w end
    end
end

test("Skin seam: one Skin tab pick is one effective SetChoice and one repaint", function()
    -- The tab calls SetChoice first, then the write seam, which writes both rows through
    -- NS.Schema.Set; each row's onChange applies only its own half and finds it applied already.
    -- red under: an onChange that re-applies the whole stored pair (two repaints, the first to a
    -- half-written skin), or a seam that writes the profile around NS.Schema.Set.
    local inst, Skin, counter = live()
    local cb = skinTabChoice(inst, "Obsidian")
    t.truthy(cb ~= nil, "the Skin tab drew no Obsidian choice")
    cb:SetValue(true)
    cb:Fire("OnValueChanged", true)
    t.eq(counter.looks, 1, "one pick must repaint exactly once")
    local source, skin = Skin:GetChoice(OWNER)
    t.eq(source, "ka0s")
    t.eq(skin, "obsidian", "the pick did not move the applied skin")
    t.eq(inst.NS.db.profile.skin.skin, "obsidian", "the pick did not reach the profile")
end)

test("Skin seam: another addon's copy to every Ka0s addon repaints PrettyChat once", function()
    -- The library's copy calls SetChoice for each other owner, then WriteChoice, which reaches this
    -- addon's registered setter.
    local inst, Skin, counter = live()
    Skin:SetChoice(OWNER, "ka0s", "ember")
    t.truthy(Skin:WriteChoice(OWNER, "ka0s", "ember"), "the copy's write did not reach this addon's setter")
    t.eq(counter.looks, 1, "a copy must repaint this addon exactly once")
    t.eq(inst.NS.db.profile.skin.skin, "ember", "the copy did not land in the profile")
end)

-- ── the profile events ───────────────────────────────────────────────────────────────────────

test("Skin seam: a profile switch, copy and reset each apply the incoming profile's skin", function()
    -- skinning-§2. red under: a profile callback that never re-applies the choice.
    local inst, Skin, counter = live()
    local db = inst.addon.db
    db:SetProfile("SkinProbe")
    db.profile.skin.skin = "glass"
    db:SetProfile("Default")
    t.eq(select(2, Skin:GetChoice(OWNER)), "ka0s", "back on Default, Default's skin")
    counter.looks = 0
    db:SetProfile("SkinProbe")
    t.eq(select(2, Skin:GetChoice(OWNER)), "glass", "the switch did not move the applied skin")
    t.eq(counter.looks, 1, "one switch, one repaint")
    db:SetProfile("Default")
    db:CopyProfile("SkinProbe")
    t.eq(select(2, Skin:GetChoice(OWNER)), "glass", "the copy did not apply the copied skin")
    db:ResetProfile()
    t.eq(select(2, Skin:GetChoice(OWNER)), "ka0s", "the reset did not put Ka0s Default back")
end)

test("Skin seam: a profile's stored exceptions and overrides are applied with its skin", function()
    -- OnInitialize and the profile events call NS.ApplySkinChoice() with no argument.
    -- red under: applying the stored pair and not the Scope or the overrides.
    local inst, Skin = live()
    local s = inst.NS.db.profile.skin
    s.ignorePanel, s.ignoreFonts, s.font = false, true, "Oxanium"
    inst.NS.ApplySkinChoice()
    local panel, fonts = Skin:GetIgnore(OWNER)
    t.eq(panel, false, "the stored panel exception")
    t.eq(fonts, true, "the stored fonts exception")
    t.eq((Skin:GetOverride(OWNER)), "Oxanium", "the stored font override")
end)

test("Skin seam: a skin write still lands while the addon is stood down", function()
    -- The skin is setup, not a feature (the stand-down latch, slash-commands-§7).
    local inst, Skin = live()
    inst.NS.Schema.Set("General.enabled", false)
    slash(inst, "set skin.skin ember")
    t.eq(select(2, Skin:GetChoice(OWNER)), "ember", "a stood-down addon refused a skin")
    inst.NS.Schema.Set("General.enabled", true)
end)

-- ── the degraded arm ─────────────────────────────────────────────────────────────────────────

local bare = ctx.loadAddon({ skip = { "libs/LibKa0s/Core.lua" } })

test("Skin seam: the library-absent load has no Skin major and falls back to the host facade", function()
    t.nilv(bare.env.LibStub("LibKa0s-Skin-1.0", true), "the degraded arm has no Skin major")
    t.truthy(type(bare.NS.Skin) == "table", "and NS.Skin is the host's table")
    t.eq(bare.NS.Skin.owner, OWNER)
    t.eq(bare.NS.SkinEscape("pc.note"), "|cffaaaaaa", "the degraded facade answers Ka0s Default")
end)

test("Skin seam: the degraded facade answers every name the live facade carries", function()
    -- A facade is per owner and built by `For`, so this is the two-table form, key for key, with
    -- nothing ignored: a vocabulary name the library adds fails here until the stub answers it.
    local inst = live()
    ctx.assertSurfaceParity(inst.NS.Skin, bare.NS.Skin, "Skin facade vs host stub", {})
end)

test("Skin seam: the seam publishes the same NS members on both paths", function()
    local inst = live()
    for _, name in ipairs({
        "Skin", "SKIN_TOKENS", "SKIN_FALLBACK", "SkinColor", "SkinEscape", "PanelEscape", "SKIN_SOURCE_OPTIONS",
        "SKIN_OPTIONS", "SkinChoice", "WriteSkinChoice", "SkinOverride", "ApplySkinChoice",
        "ApplySkinIgnore", "ApplySkinOverride", "SkinPaintAce", "SkinPaintAceTree", "SkinOnRelease",
    }) do
        t.truthy(inst.NS[name] ~= nil, "live: NS." .. name)
        t.eq(type(bare.NS[name]), type(inst.NS[name]), "degraded: NS." .. name)
    end
    t.eq(bare.NS.SkinChoice(), "ka0s", "the degraded read answers Ka0s Default")
    t.falsy((bare.NS.ApplySkinChoice()), "nothing to apply without the library")
end)

test("Skin seam: each host-copy skin token is the live library's Ka0s Default value", function()
    -- The degraded facade answers Ka0s Default from NS.SKIN_FALLBACK. A copy is the thing that
    -- drifts, so every entry is held to the library's value for THIS owner (its owner tokens
    -- resolve only for a registered owner).
    local inst = live()
    local n = 0
    for name, c in pairs(bare.NS.SKIN_FALLBACK) do
        n = n + 1
        local want = inst.NS.Skin.Token(name)
        t.truthy(type(want) == "table", name .. " is not a Ka0s Default color token for this owner")
        for i = 1, 4 do
            local a, b = c[i] or 1, want[i] or 1
            t.truthy(math.abs(a - b) < 1e-6, ("%s[%d]: host copy %s, library %s"):format(name, i, a, b))
        end
    end
    t.truthy(n > 0, "the host copy is empty, so this case asserts nothing")
end)
