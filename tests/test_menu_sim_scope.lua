-- tests/test_menu_sim_scope.lua — round 2 of the 2026-11-24 feedback batch (FB2-PC-01 of
-- Ka0sAddonsCommonTasks docs/2026-11-24-FEEDBACK_BATCH/R2_SMOKE_FEEDBACK.md; standard v2.120.0),
-- the two audits that found nothing to change here, held so the finding stays true.
--
-- D2, EVERY SIM START SHOWS THE STEP PANEL (preview-mode, *The in-game simulator*). PrettyChat has
-- no simulation: it rewrites chat lines the client prints and has no event stream to replay, so no
-- `sim` verb, no `LibKa0s-Sim-1.0` session and no Sim mode row on the Master controls (RV-89). An
-- addon that grows one owes the rule and a test per start path.
--
-- D3, A SELECTED ENTRY READS APART (skinning-§4, anti-pattern #127). Every dropdown PrettyChat has
-- is an AceGUI settings-page pullout (the schema's General visibility, Skin source, Skin and Font
-- outline rows, and AceDBOptions' profile lists), which the rule leaves to AceGUI's check mark, and
-- its launcher menu is the client's own (MenuUtil, drawn by LibKa0s Launcher). It builds no
-- `W.Dropdown` or `W.ContextMenu` and paints no menu row itself. An addon that grows one paints its
-- selection in `W.SelectedColor(owner)` and owes the test that proves it.

local ctx  = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local SOURCE_DIRS = { "core/", "settings/", "modules/", "defaults/", "locales/" }

local SIM_PATTERNS = { "LibKa0s%-Sim%-1%.0", "Sim:New", "toggleSim", "ShowPanel%(" }
local MENU_PATTERNS = { "%.Dropdown%s*%(", "ContextMenu%s*%(", "MenuUtil", "UIDropDownMenu", "EasyMenu",
                        "SelectedColor", "menu%.textSel" }

--- `text` with every `--` comment cut off its line, so prose that names a surface is not a use.
local function code(text)
    local out = {}
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        out[#out + 1] = (line:gsub("%-%-.*$", ""))
    end
    return table.concat(out, "\n")
end

local function hits(text, patterns)
    local found = {}
    local body = code(text)
    for _, pat in ipairs(patterns) do
        if body:find(pat) then found[#found + 1] = pat end
    end
    return found
end

local function addonSources()
    t.truthy(io.popen ~= nil, "io.popen is available, so the guard can look")
    local p = io.popen("git -C '" .. ctx.root .. "' ls-files '*.lua' 2>/dev/null")
    t.truthy(p ~= nil, "git ls-files ran")
    local out = {}
    for path in p:lines() do
        for _, dir in ipairs(SOURCE_DIRS) do
            if path:sub(1, #dir) == dir then out[#out + 1] = path break end
        end
    end
    p:close()
    t.truthy(#out >= 15, "the guard reads the addon's own Lua, got " .. #out)
    return out
end

local function scan(patterns)
    local found = {}
    for _, path in ipairs(addonSources()) do
        local fh = io.open(ctx.root .. "/" .. path, "rb")
        if fh then
            local text = fh:read("*a")
            fh:close()
            for _, pat in ipairs(hits(text, patterns)) do found[#found + 1] = path .. ":" .. pat end
        end
    end
    return found
end

test("menu/sim scope: the guards see a use and skip a comment that names it", function()
    -- red under: a pattern that cannot match, so the two guards below would pass on anything.
    t.eq(table.concat(hits('local dd = W.Dropdown(parent, 120, {})', MENU_PATTERNS), ","), "%.Dropdown%s*%(")
    t.eq(table.concat(hits('fs:SetTextColor(W.SelectedColor("PrettyChat"))', MENU_PATTERNS), ","), "SelectedColor")
    t.eq(table.concat(hits('local Sim = LibStub("LibKa0s-Sim-1.0")', SIM_PATTERNS), ","), "LibKa0s%-Sim%-1%.0")
    t.eq(#hits("-- a W.Dropdown would paint W.SelectedColor; LibKa0s-Sim-1.0", MENU_PATTERNS), 0)
    t.eq(#hits('widget = "Dropdown", values = NS.SKIN_OPTIONS', MENU_PATTERNS), 0, "a schema row is AceGUI's")
end)

test("menu/sim scope: PrettyChat runs no simulation, so no start path owes the step panel (D2)", function()
    -- red under: a sim session, a sim verb or a Sim mode toggle added without the start-path tests.
    t.eq(table.concat(scan(SIM_PATTERNS), "; "), "", "a simulation surface in the addon's Lua")
    local NS = ctx.loadAddon().NS
    for _, entry in ipairs(NS.COMMANDS) do
        t.truthy(entry[1] ~= "sim", "no /pc sim verb")
    end
end)

test("menu/sim scope: PrettyChat builds or paints no menu that marks a selection (D3)", function()
    -- red under: a W.Dropdown, a W.ContextMenu, a client menu or a hand-painted selection added
    -- without the selected-row color test (skinning-§4, *A selected entry reads apart*).
    t.eq(table.concat(scan(MENU_PATTERNS), "; "), "", "a menu the addon builds or paints")
end)
