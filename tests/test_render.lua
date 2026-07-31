-- tests/test_render.lua — NS.RenderSample: positional args, %% escapes,
-- and string.format error surfacing.

return function(ctx)
    local t = ctx.t
    local test = ctx.test
    local inst = ctx.loadAddon()
    local render = inst.NS.RenderSample

    test("renders basic %s + %d and collapses %% escapes", function()
        t.eq(render("%s got %d"), "Sample got 42", "basic %s + %d")
        t.eq(render("100%% done"), "100% done", "%% escape collapses")
    end)

    test("positional %n$s formats degrade gracefully under stock Lua", function()
        -- Positional specifiers (%n$s) are a WoW Lua extension; stock Lua 5.1
        -- (this harness) can't render them, but RenderSample must degrade
        -- gracefully (nil + error) rather than throw. In-game these render;
        -- see docs/smoke-tests.md for the manual positional check.
        local ok = pcall(render, "%2$s then %1$s")
        t.truthy(ok, "positional format never throws (graceful under stock Lua)")
    end)

    test("empty or nil format returns nil", function()
        t.nilv(render(""), "empty format returns nil")
        t.nilv(render(nil), "nil format returns nil")
    end)

    test("malformed conversion surfaces as nil + error string", function()
        local r3, e3 = render("%y")
        t.nilv(r3, "bad conversion returns nil")
        t.truthy(e3, "bad conversion yields an error message")
    end)

    test("each conversion class gets a correctly typed sample argument", function()
        -- sampleArg types the placeholder per conversion: strings, integers,
        -- floats and characters each have to satisfy string.format.
        t.eq(render("%s"), "Sample", "%s takes a word")
        t.eq(render("%d"), "42",     "%d takes an integer")
        t.eq(render("%i"), "42",     "%i takes an integer")
        t.eq(render("%u"), "42",     "%u takes an integer")
        t.eq(render("%x"), "2a",     "%x takes an integer, rendered hex")
        t.eq(render("%o"), "52",     "%o takes an integer, rendered octal")
        t.eq(render("%c"), "A",      "%c takes a character code")
        t.truthy(render("%f"):find("^1%.5"), "%f takes a float")
        t.eq(render("%g"), "1.5",    "%g takes a float")
        t.truthy(render("%e"):find("^1%.5"), "%e takes a float")
    end)

    test("upper-case conversions are typed from their lower-case form", function()
        t.eq(render("%X"), "2A", "%X is an integer conversion too")
        t.truthy(render("%E"):find("^1%.5"), "%E is a float conversion too")
    end)

    test("flags, width and precision are parsed, not mistaken for arguments", function()
        t.eq(render("%05d"),   "00042",  "zero-padded width")
        t.eq(render("%-6s|"),  "Sample|", "left-justified width")
        t.eq(render("%.2f"),   "1.50",   "precision")
        t.eq(render("%+d"),    "+42",    "sign flag")
    end)

    test("multiple conversions are filled in order", function()
        t.eq(render("%s got %d for %s"), "Sample got 42 for Sample",
            "each conversion gets its own argument, left to right")
    end)

    test("a format with no conversions renders as itself", function()
        t.eq(render("no conversions here"), "no conversions here", "literal text passes through")
        t.eq(render("100%% sure"), "100% sure", "an escape-only format still collapses")
    end)

    test("%% is not mistaken for a conversion next to a real one", function()
        t.eq(render("%d%% of %s"), "42% of Sample",
            "the escape is stripped before the conversions are counted")
    end)

    test("a non-string format is rejected like an empty one", function()
        local r, e = render(42)
        t.nilv(r, "a number is not a format string")
        t.eq(e, "(empty format)", "and reports the same reason as an empty one")
        local r2 = render({})
        t.nilv(r2, "a table is not a format string either")
    end)

    test("a real Blizzard-style default renders without error", function()
        local rows = inst.NS.Schema.RowsByCategory("Loot")
        local fmt
        for _, row in ipairs(rows) do
            if row.kind == "string_format" then fmt = row.default break end
        end
        t.truthy(fmt, "found a Loot format default")
        t.truthy(render(fmt), "real default renders")
    end)
end
