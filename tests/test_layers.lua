-- tests/test_layers.lua — frame layering (frame-layering-§5): PrettyChat is a frameless addon.
--
-- WHAT IT PINS. Its only visual surfaces are the Settings canvas (every widget inherits it), the
-- library's windows (debug console, copy window) and Blizzard or Ace3 popups and tooltips. So it owns
-- no strata, and frame-layering-§5 says such an addon MUST NOT call SetFrameStrata, SetFrameLevel,
-- SetToplevel or Raise itself, and SHOULD pin that with a static test. This is that test (PRC-Z04 of
-- the 2026-10-24 strata analysis), plus the layers table's frameless shape and the one frame the
-- addon creates, recorded through the kit's frame-layer recorder (tests/_kit/mock_layers.lua).
--
-- WHAT IT DELIBERATELY DOES NOT PIN. Where the library's windows sit (the console DIALOG and
-- toplevel, the copy window FULLSCREEN). That is library behavior, pinned in LibKa0s's own suite,
-- and a consumer must not duplicate a library pin (testing-§8).

local ctx  = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local function readFile(path)
    local f = io.open(ctx.root .. "/" .. path, "r")
    if not f then return nil end
    local body = f:read("*a")
    f:close()
    return body
end

-- Every layering write the client has. `[:.]` in front, so a name that merely ends in one
-- (core/Util.lua's `onRaise`) is not a hit.
local FORBIDDEN = {
    "SetFrameStrata", "SetFixedFrameStrata", "SetFrameLevel", "SetFixedFrameLevel",
    "SetToplevel", "Raise", "Lower",
}

test("the addon's own code makes no strata, level, toplevel or raise call", function()
    t.truthy(io.popen ~= nil, "io.popen is available, so the source can be listed")
    local pipe = io.popen("git -C '" .. ctx.root .. "' ls-files 'core/*.lua' 'settings/*.lua' 'modules/*.lua'")
    t.truthy(pipe ~= nil, "git ls-files answered a handle")
    local scanned = 0
    for f in pipe:lines() do
        scanned = scanned + 1
        local body = (readFile(f) or ""):gsub("%-%-[^\r\n]*", "")
        for _, name in ipairs(FORBIDDEN) do
            t.falsy(body:find("[:.]" .. name .. "%s*%(") ~= nil,
                ("%s calls %s: a frameless addon owns no strata (frame-layering-§5)"):format(f, name))
        end
    end
    pipe:close()
    t.truthy(scanned > 0, "the source scan found files to read")
end)

test("the layers table declares the frameless shape: no strata, no level band", function()
    local LAYERS = ctx.loadAddon().NS.Const.LAYERS
    t.eq(type(LAYERS), "table", "NS.Const.LAYERS exists (frame-layering-§5's one table)")
    t.eq(type(LAYERS.STRATA), "table", "it carries a STRATA map")
    t.eq(type(LAYERS.LEVEL), "table", "and a LEVEL map")
    t.eq(next(LAYERS.STRATA), nil, "STRATA is empty: the addon sets no strata of its own")
    t.eq(next(LAYERS.LEVEL), nil, "LEVEL is empty: the addon sets no frame level of its own")
end)

test("the combat watcher, the one frame the addon creates, is a T0 frame", function()
    local inst = ctx.loadAddon({ mock = function(M) dofile("tests/_kit/mock_layers.lua")(M) end })
    inst.NS.Schema.Set("General.visibility", "inCombat")
    local f = inst.env._frames.byName["PrettyChatCombatWatcher"]
    t.truthy(f ~= nil, "a combat mode creates the watcher")
    t.truthy(rawget(f, "SetFrameStrata") ~= nil, "the frame-layer recorder is installed on it")
    t.eq(rawget(f, "__strata"), nil, "the watcher is given no strata")
    t.eq(rawget(f, "__level"), nil, "nor a frame level")
    local layers = inst.env.__layers(f)
    t.falsy(layers.toplevel, "it is not toplevel")
    t.eq(layers.raised, 0, "and it is never raised")
    inst.NS.Schema.Set("General.visibility", "always")
end)

test("docs/ARCHITECTURE.md carries the Frame layering section and points at the table", function()
    local doc = readFile("docs/ARCHITECTURE.md")
    t.truthy(doc ~= nil, "docs/ARCHITECTURE.md is readable")
    local section = (doc or ""):match("\n## Frame layering\r?\n(.-)\n## ")
    t.truthy(section ~= nil, "a `## Frame layering` section exists")
    t.truthy((section or ""):find("NS.Const.LAYERS", 1, true) ~= nil,
        "the section points at NS.Const.LAYERS rather than copying a tier table")
end)
