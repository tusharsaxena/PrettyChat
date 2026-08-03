-- tests/test_constants.lua — core/Constants.lua. The color palette and the
-- [PC] tag are the addon's brand mark and the slash-commands-§5 mandated
-- output palette: those exact hex codes are a MUST (they read identically
-- across every Ka0s addon), so they are pinned here rather than left to
-- drift silently. The layout constants are pinned as *shape* (positive
-- numbers, sane relations), not as pixel values.

local ctx = _G.PC_TEST
local t     = ctx.t
local test  = ctx.test
local inst  = ctx.loadAddon()
local NS    = inst.NS
local Const = NS.Const
local C     = Const.Color

test("every color escape is a well-formed |cRRGGBB code", function()
    for name, code in pairs(C) do
        if name ~= "reset" then
            t.truthy(code:match("^|c%x%x%x%x%x%x%x%x$") ~= nil,
                ("Color.%s is a |cAARRGGBB escape (got %q)"):format(name, code))
        end
    end
    t.eq(C.reset, "|r", "reset is the bare |r terminator")
end)

test("the slash-commands-§5 mandated palette is exact", function()
    -- These four MUST NOT be substituted — they are cross-addon constants.
    t.eq(C.listHead, "|cff33ff99", "list header green is 33ff99")
    t.eq(C.azure,    "|cff3399ff", "[category] group headers are azure 3399ff")
    t.eq(C.yellow,   "|cffffff00", "schema-path/key color is ffff00")
    t.eq(C.white,    "|cffffffff", "value color is ffffff")
end)

test("the brand colors are distinct from the mandated palette", function()
    -- The header green (33ff99) is deliberately NOT the brand green (40ff40).
    t.eq(C.green, "|cff40ff40", "brand green is 40ff40")
    t.neq(C.green, C.listHead, "brand green is not the list-header green")
    t.eq(C.cyan, "|cff00ffff", "the [PC] brand cyan is 00ffff")
end)

test("the [PC] chat tag is cyan-wrapped and trailing-spaced", function()
    t.eq(Const.PREFIX, C.cyan .. "[PC]" .. C.reset .. " ",
        "PREFIX is the cyan [PC] tag plus one separating space")
    t.eq(NS.PREFIX, Const.PREFIX, "NS.PREFIX aliases Const.PREFIX (one source)")
end)

test("the host's own layout constants are positive numbers", function()
    -- Only the three that are genuinely this addon's. The panel metrics that used
    -- to sit beside them are LibKa0s-Options-1.0's LAYOUT table now.
    for _, name in ipairs({
        "SECTION_TOP_SPACER", "SECTION_BOTTOM_SPACER", "STRING_VSPACER",
    }) do
        t.eq(type(Const[name]), "number", name .. " is a number")
        t.truthy((Const[name] or 0) > 0, name .. " is positive")
    end
end)

test("no host copy of a library layout constant has grown back", function()
    -- options-ui-§8: every Ka0s panel renders identically because every panel reads
    -- ONE set of values, and a host copy is the copy that goes stale. These seven
    -- lived here before the adoption; a re-added one is a silent divergence from
    -- every other addon in the collection.
    for _, name in ipairs({
        "PANEL_PADDING_X", "PANEL_HEADER_TOP", "PANEL_HEADER_HEIGHT",
        "PANEL_DEFAULTS_W", "BUTTON_PAIR_REL", "SECTION_HEADING_H", "ROW_VSPACER",
    }) do
        t.nilv(Const[name], name .. " is the library's, not a host copy")
    end
end)

test("the library publishes the layout constants a host page needs", function()
    -- The ones settings/Panel.lua reads off the instance for its own bespoke
    -- widgets. If the library stopped publishing one, the spacers in the
    -- per-string editor would silently collapse to nil-height.
    t.eq(type(NS.Helpers.ROW_VSPACER), "number", "ROW_VSPACER is on the instance")
    t.eq(type(NS.Helpers.SECTION_HEADING_H), "number", "so is SECTION_HEADING_H")
    t.eq(type(NS.Helpers.BUTTON_PAIR_REL), "number", "and BUTTON_PAIR_REL")
    t.truthy(NS.Helpers.BUTTON_PAIR_REL < 0.5, "the button pair still insets under half")
end)

test("FONT_MONO points inside the addon's own media folder", function()
    -- debug-logging-§2 accepted deviation: shipped font, no LSM registration.
    t.truthy(Const.FONT_MONO:find("Interface\\AddOns\\PrettyChat\\media\\fonts\\", 1, true) == 1,
        "FONT_MONO is a vendored media path under the addon folder")
    t.truthy(Const.FONT_MONO:match("%.ttf$") ~= nil, "FONT_MONO is a .ttf")
end)
