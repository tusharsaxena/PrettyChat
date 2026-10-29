-- tests/test_skin_surfaces.lua — the colors PrettyChat writes itself on the surfaces it does not
-- draw (PC-02 of Ka0sAddonsCommonTasks docs/2026-10-29-SKINNING_ROLLOUT/, anti-pattern #107).
--
-- PrettyChat draws no frame of its own: the settings chrome, the debug console and the picker are
-- the library's, and follow the skin once the owner is registered. What is left is the text it
-- colors itself: the gray notes on the settings pages (the GLOBALNAME caption, the Categories
-- footnote, the landing alias row) and the lines it writes onto GameTooltip for a list entry.
-- Each reads a token through the facade, so it is today's exact pixel under Ka0s Default and the
-- skin's own under any other: pc.note (follows text.muted), pc.tipNote (follows gtip.subtle) and
-- gtip.value for the tooltip title (decision D2).
--
-- Not here, by decision: chat output and the /pc test report (X7, D3, the report's gray is
-- report content shared with chat), the player's own formats and their rendered samples (E7).

local ctx  = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local OWNER = "PrettyChat"
local SKIN  = "obsidian"

--- A fresh live instance with its Categories page built, the skin switched to `skin` first.
local function categories(skin)
    local inst = ctx.loadAddon()
    local Skin = inst.env.LibStub("LibKa0s-Skin-1.0")
    if skin then Skin:SetChoice(OWNER, "ka0s", skin) end
    local fixture = dofile(ctx.root .. "/tests/panel_fixture.lua")(inst.NS)
    fixture.panelFrame(inst.env, "Categories"):Show()
    local scroll = inst.NS.Helpers.__panelFor("Categories").scroll
    local tree
    for _, child in ipairs(scroll.children) do
        if child.type == "TreeGroup" then tree = child end
    end
    return inst, scroll, tree, fixture
end

local function labelsOf(list)
    local out = {}
    for _, w in ipairs(list) do
        if w.type == "Label" and w.text then out[#out + 1] = w.text end
    end
    return out
end

-- ── the page notes ──────────────────────────────────────────────────────────────────────────

test("Skin surfaces: the page notes are today's #aaaaaa under Ka0s Default", function()
    -- red under: a note snapped to text.muted (|cffb3b3b8), which moves Ka0s Default (X1).
    local inst, scroll, tree = categories()
    local caption = tree.children[1].children[2]
    t.truthy(caption.text:find("|cffaaaaaa", 1, true), "the GLOBALNAME caption is #aaaaaa")
    t.truthy(labelsOf(scroll.children)[1]:find("|cffaaaaaa", 1, true), "the footnote is #aaaaaa")
    t.eq(inst.NS.SkinEscape("pc.note"), "|cffaaaaaa")
end)

test("Skin surfaces: under another skin the page notes take that skin's pc.note", function()
    -- red under: a typed Color.gray at the call site (anti-pattern #107), which stays #aaaaaa in
    -- every skin.
    local inst, scroll, tree = categories(SKIN)
    local want = inst.NS.SkinEscape("pc.note")
    t.truthy(want ~= "|cffaaaaaa", "the test skin must move pc.note, or this case asserts nothing")
    local caption = tree.children[1].children[2]
    t.truthy(caption.text:find(want, 1, true), "the GLOBALNAME caption follows the skin: " .. caption.text)
    t.falsy(caption.text:find("|cffaaaaaa", 1, true), "and carries no typed gray")
    local footnote = labelsOf(scroll.children)[1]
    t.truthy(footnote:find(want, 1, true), "the Categories footnote follows the skin")
end)

test("Skin surfaces: the landing page's alias row takes the skin's pc.note", function()
    local inst = ctx.loadAddon()
    inst.env.LibStub("LibKa0s-Skin-1.0"):SetChoice(OWNER, "ka0s", SKIN)
    local fixture = dofile(ctx.root .. "/tests/panel_fixture.lua")(inst.NS)
    local mark = #inst.env._widgets
    inst.env._settings.categories[1].frame:Show()
    local alias
    for _, text in ipairs(labelsOf(fixture.widgetsSince(inst.env, mark))) do
        if text:find("/prettychat is an alias for /pc", 1, true) then alias = text end
    end
    t.truthy(alias, "the alias row is on the landing page")
    t.truthy(alias:find(inst.NS.SkinEscape("pc.note"), 1, true), "in the skin's note color: " .. alias)
    t.falsy(alias:find("|cffaaaaaa", 1, true), "and no typed gray")
end)

-- ── the tooltip lines ───────────────────────────────────────────────────────────────────────

--- Hover the n-th list entry and read back the title, its color and the lines.
local function hoverEntry(inst, tree, fixture, n)
    local tip = inst.env.GameTooltip
    local set = tip.SetText
    local color
    tip.SetText = function(self, text, r, g, b, ...)
        color = { r, g, b }
        return set(self, text, r, g, b, ...)
    end
    tip.lines, tip.text = nil, nil
    local g = fixture.sortedNames("Loot")[n]
    tree:Fire("OnButtonEnter", g, inst.env.CreateFrame("Button"))
    tip.SetText = set
    return g, color, tip.lines or {}
end

test("Skin surfaces: a list entry's tooltip lines are Ka0s Default's exact values", function()
    -- D2: the title was SetText(label, 1, 1, 1); gtip.value is WHITE on Ka0s Default.
    local inst, _, tree, fixture = categories()
    local g, color, lines = hoverEntry(inst, tree, fixture, 2)
    t.truthy(color[1] == 1 and color[2] == 1 and color[3] == 1, "the title is white")
    t.truthy(lines[1]:find("|cffaaaaaa" .. g, 1, true), "the GLOBALNAME line is #aaaaaa")
end)

test("Skin surfaces: under another skin the tooltip lines take gtip.value and pc.tipNote", function()
    local inst, _, tree, fixture = categories(SKIN)
    local g, color, lines = hoverEntry(inst, tree, fixture, 2)
    local r, gg, b = inst.NS.Skin.Color("gtip.value")
    t.truthy(color[1] == r and color[2] == gg and color[3] == b, "the title is the skin's gtip.value")
    local want = inst.NS.SkinEscape("pc.tipNote")
    t.truthy(want ~= "|cffaaaaaa", "the test skin must move pc.tipNote, or this case asserts nothing")
    t.truthy(lines[1]:find(want .. g, 1, true), "the GLOBALNAME line follows the skin: " .. lines[1])
end)

-- ── nothing typed is left ───────────────────────────────────────────────────────────────────

test("Skin surfaces: settings/ writes no typed gray and no typed tooltip color", function()
    -- The convention, held at the source: Color.gray is chat and report markup (X7, D3), never a
    -- settings surface. red under: a new settings site that reaches for the constant.
    local f = assert(io.open(ctx.root .. "/settings/Panel.lua", "r"))
    local src = f:read("*a")
    f:close()
    t.falsy(src:find("Color.gray", 1, true), "settings/Panel.lua still types Color.gray")
    t.falsy(src:find("cffaaaaaa", 1, true), "settings/Panel.lua still types |cffaaaaaa")
    t.falsy(src:find("SetText%([^)]*, 1, 1, 1%)"), "settings/Panel.lua still types a tooltip title color")
end)
