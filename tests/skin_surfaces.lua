-- tests/skin_surfaces.lua — the skin-switch test's facts (Kit.skinSwitch, kit revision 50): every
-- surface this addon paints itself, off one instance with its Categories page open.
--
-- WHAT IS DECLARED. PrettyChat draws no frame of its own, so what it paints is text: the three page
-- notes in pc.note, the list entry's GameTooltip lines in gtip.value, gtip.line and pc.tipNote, the
-- debug console, the one library window it opens, and the `/pc test` report written into it, whose
-- labels read pc.reportLabel, pc.reportHead and pc.note (owner ruling U-25, 2026-11-20).
--
-- THE REPORT IS READ THROUGH A MIRROR TOO. Its lines are text with their colors in escapes, baked
-- when the report is written, so each flip writes the report afresh through the sink
-- PrettyChat:TestToConsole hands Test, and the mirror takes the lines joined: what the spy reads is
-- exactly what the console receives.
--
-- NO FAMILY HOLD AND NO `expect`. PrettyChat draws no StatusBar and no Texture (no data fill, no
-- art), and every surface's text color follows the skin, so no ruling keeps a family fixed here.
--
-- A NOTE IS READ THROUGH A MIRROR. A skin switch re-renders the page a frame later, so a label is a
-- new widget each flip and spying on one would watch the widget the render threw away. Each note's
-- `paint` runs the re-render and hands the label's real text to one plain object the test keeps,
-- which is what the spy reads. The second tooltip line is overwritten by the body's AddLine in the
-- spy's log, so it takes a mirror too.
--
-- LEFT OUT. The kit's AceGUI is a stub with no widget parts, so a painter has nothing to reach and
-- no setter runs: the Categories TreeGroup and its editor, and the Profiles page.
-- tests/test_skin_picker.lua pins that each of them is handed to PaintAceTree for this owner, and
-- that the Profiles page re-opens on a skin switch. Everything else on the settings pages is the
-- library's, and pinned there.
--
-- It answers a function of the runner's `loadAddon`, because the instance has to exist when the kit
-- reads the facts: a surface repaints only through that instance's own library.

local OWNER = "PrettyChat"

return function(loadAddon, root)
    local inst = loadAddon()
    local env, NS, addon = inst.env, inst.NS, inst.addon
    local fixture = dofile(root .. "/tests/panel_fixture.lua")(NS)

    fixture.panelFrame(env, "Categories"):Show()
    env._settings.categories[1].frame:Show()

    -- Where this flip's re-render starts in the widget log: the landing page has no handle to find a
    -- row by, so its alias row is read from what the re-render acquired.
    local aliasMark = 0

    local function scroll() return NS.Helpers.__panelFor("Categories").scroll end

    local function tree()
        for _, child in ipairs(scroll().children) do
            if child.type == "TreeGroup" then return child end
        end
    end

    local function firstLabel(list, plain)
        for _, w in ipairs(list) do
            if w.type == "Label" and w.text and (not plain or w.text:find(plain, 1, true)) then return w.text end
        end
    end

    --- A surface that re-renders the page and hands `read()`'s text to one kept object.
    local function note(name, read)
        return {
            name = name, scope = "panel",
            build = function() return { SetText = function(self, text) self.text = text end } end,
            paint = function(mirror)
                aliasMark = #env._widgets
                env.__fireTimers()
                mirror:SetText(read())
            end,
        }
    end

    --- Hover a list entry, afresh, so the tooltip's lines are only this hover's.
    local function hover()
        local tip = env.GameTooltip
        tip.lines, tip.text = nil, nil
        env.__fireTimers()
        tree():Fire("OnButtonEnter", fixture.sortedNames("Loot")[2], env.CreateFrame("Button"))
    end

    local function aliasRow()
        return firstLabel(fixture.widgetsSince(env, aliasMark), "/prettychat is an alias for /pc")
    end

    return {
        owner = OWNER,
        skin  = function() return env.LibStub("LibKa0s-Skin-1.0") end,
        surfaces = {
            note("the GLOBALNAME caption", function() return tree().children[1].children[2].text end),
            note("the Categories footnote", function() return firstLabel(scroll().children) end),
            note("the landing page's alias row", aliasRow),
            {
                name = "the list hover's title and body",
                build = function() return env.GameTooltip end,
                paint = hover,
            },
            {
                name = "the list hover's GLOBALNAME line",
                build = function() return { SetText = function(self, text) self.text = text end } end,
                paint = function(mirror)
                    hover()
                    mirror:SetText(env.GameTooltip.lines[1])
                end,
            },
            {
                name = "the /pc test report in the debug console",
                build = function() return { SetText = function(self, text) self.text = text end } end,
                paint = function(mirror)
                    local lines = {}
                    addon:Test({ kind = "category", value = "Loot" },
                        function(line) lines[#lines + 1] = line end)
                    mirror:SetText(table.concat(lines, "\n"))
                end,
            },
            {
                name = "the debug console",
                build = function()
                    NS.DebugLog:Show()
                    return env._frames.byName["PrettyChatDebugWindow"]
                end,
            },
        },
    }
end
