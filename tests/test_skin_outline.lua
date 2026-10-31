-- tests/test_skin_outline.lua — the font outline (LibKa0s v1.82.0, Skin minor 9; PC-01 of
-- Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK, ruling D-06): stored as skin.outline
-- ("all", "hud", the default since LibKa0s v1.83.0 and ruling D-10, "off"), written only through the skin write seam (NS.WriteSkinChoice's
-- `media.outline`, the same seam the font and texture overrides go through), and applied with
-- Skin:SetOutline with the rest of the stored choice (load, every profile event) and on the row's
-- own write. The reference is LibKa0sSkinTester 7d736c2.

local ctx  = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local OWNER = "PrettyChat"

local function live()
    local inst = ctx.loadAddon()
    return inst, inst.env.LibStub("LibKa0s-Skin-1.0")
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

test("Skin outline: a fresh profile stores HUD text only, the library's default", function()
    local inst, Skin = live()
    t.eq(inst.NS.ProfileDefaults.profile.skin.outline, "hud")
    t.eq(inst.NS.db.profile.skin.outline, Skin.OUTLINE_DEFAULT)
    t.eq(Skin:GetOutline(OWNER), "hud", "the default mode is applied")
end)

test("Skin outline: the seam's own default is the library's, with no profile store", function()
    -- red under: core/SkinSetup.lua's fallback staying "all" when the library moved (D-10).
    local inst, Skin = live()
    local NS = inst.NS
    local db = NS.db
    NS.db = nil
    local got = NS.SkinOutline()
    NS.db = db
    t.eq(got, Skin.OUTLINE_DEFAULT)
end)

test("Skin outline: a stored All text stays, never migrated to the new default", function()
    -- D-10: the default only reaches an owner that never set one.
    local inst, Skin = live()
    inst.NS.db.profile.skin.outline = "all"
    inst.NS.ApplySkinChoice()
    t.eq(inst.NS.SkinOutline(), "all")
    t.eq(Skin:GetOutline(OWNER), "all")
    t.eq(inst.NS.Skin.Token("font.outline"), "OUTLINE", "window text keeps its outline")
end)

test("Skin outline: the schema row is a skipRender Skin-tab row with the library's three modes", function()
    local inst, Skin = live()
    local row = inst.NS.Schema.FindByPath("skin.outline")
    t.truthy(row ~= nil, "skin.outline is not a schema row")
    t.truthy(row.skipRender == true, "the Skin tab draws it")
    t.eq(row.group, "Appearance")
    t.truthy(row.noReapply == true, "a skin write re-applies no chat string (D8)")
    local got = {}
    for _, opt in ipairs(row.values) do got[#got + 1] = opt.value end
    t.eq(table.concat(got, ","), table.concat(Skin.OUTLINE_MODES, ","))
end)

test("Skin outline: the write seam stores media.outline, and leaves it alone when it is nil", function()
    -- red under: WriteSkinChoice dropping media.outline (the Skin tab's Font outline and another
    -- addon's copy would move the look and never store it).
    local inst = live()
    local NS = inst.NS
    NS.WriteSkinChoice(nil, nil, nil, { font = false, texture = false, outline = "hud" })
    t.eq(NS.db.profile.skin.outline, "hud")
    NS.WriteSkinChoice(nil, nil, nil, { font = false, texture = false })
    t.eq(NS.db.profile.skin.outline, "hud", "a media table without outline leaves it")
    NS.WriteSkinChoice(nil, nil, nil, { font = false, texture = false, outline = "off" })
    t.eq(NS.db.profile.skin.outline, "off")
end)

test("Skin outline: another addon's copy reaches the store through WriteChoice", function()
    local inst, Skin = live()
    Skin:WriteChoice(OWNER, "ka0s", "ember", nil, { font = false, texture = false, outline = "off" })
    t.eq(inst.NS.db.profile.skin.outline, "off")
end)

test("Skin outline: the row's write applies the mode live", function()
    local inst, Skin = live()
    inst.NS.Schema.Set("skin.outline", "hud")
    t.eq(Skin:GetOutline(OWNER), "hud")
    t.eq(inst.NS.Skin.Token("font.outline"), "", "window text loses its outline")
    t.eq(inst.NS.Skin.Token("hud.outline"), "OUTLINE", "the HUD keeps it")
    inst.NS.Schema.Set("skin.outline", "off")
    t.eq(inst.NS.Skin.Token("hud.outline"), "", "Off takes both")
    inst.NS.Schema.Set("skin.outline", "all")
    t.eq(inst.NS.Skin.Token("font.outline"), "OUTLINE")
end)

test("Skin outline: /pc set refuses a mode the library does not know", function()
    local inst = live()
    slash(inst, "set skin.outline thick")
    t.eq(inst.NS.db.profile.skin.outline, "hud")
end)

test("Skin outline: the stored mode is applied with the stored choice", function()
    -- OnInitialize and the profile events call NS.ApplySkinChoice() with no argument.
    -- red under: the whole-choice path applying the pair, Scope and overrides but not the outline.
    local inst, Skin = live()
    inst.NS.db.profile.skin.outline = "off"
    inst.NS.ApplySkinChoice()
    t.eq(Skin:GetOutline(OWNER), "off")
end)

test("Skin outline: a profile switch applies the incoming profile's mode, and back", function()
    local inst, Skin = live()
    local db = inst.addon.db
    inst.NS.Schema.Set("skin.outline", "off")
    db:SetProfile("OutlineProbe")
    t.eq(Skin:GetOutline(OWNER), "hud", "the new profile keeps the default")
    db:SetProfile("Default")
    t.eq(Skin:GetOutline(OWNER), "off", "Default's mode is back")
end)

test("Skin outline: without the skin engine the apply is a quiet no-op and the store still takes it", function()
    local bare = ctx.loadAddon({ skip = { "libs/LibKa0s/Core.lua" } })
    t.eq(bare.NS.ApplySkinOutline(), false)
    bare.NS.Schema.Set("skin.outline", "off")
    t.eq(bare.NS.db.profile.skin.outline, "off")
end)
