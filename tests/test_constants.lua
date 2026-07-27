-- tests/test_constants.lua — core/Constants.lua. The colour palette and the
-- [PC] tag are the addon's brand mark and the slash-commands-§5 mandated
-- output palette: those exact hex codes are a MUST (they read identically
-- across every Ka0s addon), so they are pinned here rather than left to
-- drift silently. The layout constants are pinned as *shape* (positive
-- numbers, sane relations), not as pixel values.

return function(ctx)
    local t     = ctx.t
    local test  = ctx.test
    local inst  = ctx.loadAddon()
    local ns    = inst.ns
    local Const = ns.Const
    local C     = Const.Color

    test("every colour escape is a well-formed |cRRGGBB code", function()
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
        t.eq(C.yellow,   "|cffffff00", "schema-path/key colour is ffff00")
        t.eq(C.white,    "|cffffffff", "value colour is ffffff")
    end)

    test("the brand colours are distinct from the mandated palette", function()
        -- The header green (33ff99) is deliberately NOT the brand green (40ff40).
        t.eq(C.green, "|cff40ff40", "brand green is 40ff40")
        t.neq(C.green, C.listHead, "brand green is not the list-header green")
        t.eq(C.cyan, "|cff00ffff", "the [PC] brand cyan is 00ffff")
    end)

    test("the [PC] chat tag is cyan-wrapped and trailing-spaced", function()
        t.eq(Const.PREFIX, C.cyan .. "[PC]" .. C.reset .. " ",
            "PREFIX is the cyan [PC] tag plus one separating space")
        t.eq(ns.PREFIX, Const.PREFIX, "ns.PREFIX aliases Const.PREFIX (one source)")
    end)

    test("layout constants are positive numbers", function()
        for _, name in ipairs({
            "PANEL_PADDING_X", "PANEL_HEADER_TOP", "PANEL_HEADER_HEIGHT",
            "PANEL_DEFAULTS_W", "SECTION_TOP_SPACER", "SECTION_BOTTOM_SPACER",
            "SECTION_HEADING_H", "ROW_VSPACER", "STRING_VSPACER",
        }) do
            t.eq(type(Const[name]), "number", name .. " is a number")
            t.truthy((Const[name] or 0) > 0, name .. " is positive")
        end
    end)

    test("the header block leaves room between title and divider", function()
        t.truthy(Const.PANEL_HEADER_HEIGHT > Const.PANEL_HEADER_TOP,
            "the divider sits below the title inset")
    end)

    test("the button-pair width stays under half so the pair shares one row", function()
        -- Slightly under 0.5 so AceGUI's inter-widget padding can't wrap the
        -- second button onto a new line.
        t.truthy(Const.BUTTON_PAIR_REL < 0.5, "BUTTON_PAIR_REL is under 0.5")
        t.truthy(Const.BUTTON_PAIR_REL > 0.4, "BUTTON_PAIR_REL is still nearly half")
    end)

    test("FONT_MONO points inside the addon's own media folder", function()
        -- debug-logging-§2 accepted deviation: shipped font, no LSM registration.
        t.truthy(Const.FONT_MONO:find("Interface\\AddOns\\PrettyChat\\media\\fonts\\", 1, true) == 1,
            "FONT_MONO is a vendored media path under the addon folder")
        t.truthy(Const.FONT_MONO:match("%.ttf$") ~= nil, "FONT_MONO is a .ttf")
    end)
end
