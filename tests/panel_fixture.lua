-- tests/panel_fixture.lua — the helpers tests/test_panel.lua and
-- tests/test_panel_categories.lua both read the settings panel through.
--
-- Not a suite: it registers no case and is not in tests/run.lua's list. The two
-- suites were one file until it reached the 1000-1500 band's third release
-- (anti-pattern #53), and only the helpers BOTH halves call live here; the ones
-- a single suite needs stayed in that suite. Called with the instance's NS,
-- because the strip and the string list are read off the live instance.

return function(NS)
    local function panelFrame(env, name)
        for _, sub in ipairs(env._settings.subcategories) do
            if sub.name == name then return sub.frame end
        end
    end

    local function widgetsSince(env, mark)
        local out = {}
        for i = mark + 1, #env._widgets do out[#out + 1] = env._widgets[i] end
        return out
    end

    local function byLabel(list, wtype, label)
        for _, w in ipairs(list) do
            if w.type == wtype and (w.labelText == label or w.text == label) then return w end
        end
    end

    -- The tab strip's buttons, in strip order, off the library's own ctx layout.
    -- They are plain Blizzard frames rather than AceGUI widgets, so env._widgets
    -- never sees them.
    local function tabButtons(pageKey)
        local layout = NS.Helpers.__panelFor(pageKey).__tabLayout
        return layout and layout.buttons or {}
    end

    -- The category's global names in the order the strip offers them, which is the
    -- order the blocks used to be stacked in: sorted.
    local function sortedNames(category)
        local out = {}
        for globalName in pairs(NS.Defaults[category].strings) do out[#out + 1] = globalName end
        table.sort(out)
        return out
    end

    return {
        panelFrame   = panelFrame,
        widgetsSince = widgetsSince,
        byLabel      = byLabel,
        tabButtons   = tabButtons,
        sortedNames  = sortedNames,
    }
end
