-- tests/test_skin_preview.lua — the skin picker's eye (LibKa0s OptionsSkinPicker minor 11's
-- `spec.preview`; R6-PV of Ka0sAddonsCommonTasks docs/2026-11-03-SMOKE_ROUND6/, the owner's answer
-- "Debug console sample", which replaces decision X6's no-eye).
--
-- PrettyChat's preview mode is "console": the debug console filled with `/pc test`'s sample lines,
-- through the same act the Test button and the verb run (PrettyChat:TestToConsole). The mode is on
-- while the console is shown. What this addon owes, and the library does not pin itself: the hook
-- it hands the picker, that the enter reaches the console through the existing test path, that the
-- eye toggles the console, that every close takes back a console the picker or its eye opened, and
-- that a console the player already had open is left alone, its lines untouched.
--
-- Every case logs in, takes the first-run picker down (which takes back the console it opened),
-- then opens the picker with `/pc skin`'s act (NS.RunSkinVerb), so each starts from one state.

local ctx  = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local HEADER = "sample of every format string"

local function options(inst) return inst.env.LibStub("LibKa0s-Options-1.0") end

--- The owner whose picker is up now, or nil.
local function shownOwner(inst)
    local q = options(inst).__pickerQueue
    local cur = q and q.current
    if cur and cur.frame and cur.frame:IsShown() then return cur.owner end
    return nil
end

--- Logged in, the first-run picker down and the console hidden and empty.
local function loggedIn(opts)
    local inst = ctx.loadAddon(opts)
    local NS = inst.NS
    NS.HideSkinPicker()
    NS.DebugLog:Hide()
    NS.DebugLog:Clear()
    t.nilv(shownOwner(inst), "the first-run picker is down")
    return inst
end

local function open(inst)
    local f = inst.NS.RunSkinVerb()
    t.truthy(f ~= nil and f:IsShown(), "the picker is up")
    return f
end

local function shown(inst) return inst.NS.DebugLog:IsShown() and true or false end

-- ── the hook ─────────────────────────────────────────────────────────────────────────────────

test("Skin preview: the spec hands the picker a console preview and no one-shot onPreview", function()
    -- red under: the old spec (no preview, decision X6), or a one-shot onPreview left beside it.
    local inst = ctx.loadAddon()
    local spec = inst.NS.SkinPickerSpec()
    local h = spec.preview
    t.eq(type(h), "table", "spec.preview is passed")
    t.eq(h.mode, "console", "the owner's answer: the debug console sample")
    for _, name in ipairs({ "enter", "exit", "isActive", "isShown" }) do
        t.eq(type(h[name]), "function", "preview." .. name .. " is a function")
    end
    t.nilv(spec.onPreview, "no one-shot eye")
end)

test("Skin preview: the mode reads the console the panel's checkbox and /pc debug move", function()
    -- red under: an isActive or isShown with a state of its own that the console's other routes
    -- would not move.
    local inst = loggedIn()
    local h = inst.NS.SkinPickerSpec().preview
    t.falsy(h.isActive(), "console hidden: off")
    t.falsy(h.isShown(), "console hidden: not shown")
    inst.addon:OnSlashCommand("debug")
    t.truthy(h.isActive(), "/pc debug opened it: on")
    t.truthy(h.isShown(), "and shown")
    inst.NS.DebugLog:Hide()
    t.falsy(h.isActive(), "hidden again: off")
end)

-- ── the picker opens ─────────────────────────────────────────────────────────────────────────

test("Skin preview: the picker opened with the console hidden opens it with /pc test's sample", function()
    -- red under: no preview hook (nothing opens), or an enter that shows the console empty
    -- instead of running the test path.
    local inst = loggedIn()
    local chat = #inst.env.DEFAULT_CHAT_FRAME.messages
    local f = open(inst)
    t.truthy(shown(inst), "the console is shown")
    t.truthy(inst.NS.DebugLog:FindLine(HEADER), "and holds the sample's header")
    t.truthy(inst.NS.DebugLog:FindLine("end of test output"), "and its footer")
    t.eq(#inst.env.DEFAULT_CHAT_FRAME.messages, chat, "not one sample line went to chat")
    t.truthy(f.preview.lit, "the eye is lit")
    t.truthy(f:IsShown(), "the picker is still up")
end)

test("Skin preview: the enter runs the Test button's and /pc test's act", function()
    -- red under: an enter that writes its own copy of the sample, which could drift from the test
    -- path the button and the verb share.
    local inst = loggedIn()
    local calls = 0
    local real = inst.addon.TestToConsole
    inst.addon.TestToConsole = function(self, ...) calls = calls + 1; return real(self, ...) end
    local ok, err = pcall(open, inst)
    inst.addon.TestToConsole = real
    if not ok then error(err, 0) end
    t.eq(calls, 1, "PrettyChat:TestToConsole ran once")
end)

-- ── the eye ──────────────────────────────────────────────────────────────────────────────────

test("Skin preview: the eye hides the console and shows it again, without a second sample", function()
    -- red under: an enter-only eye (the second click would not hide), or an enter that refills a
    -- console already holding this showing's sample.
    local inst = loggedIn()
    local f = open(inst)
    local lines = inst.NS.DebugLog:BufferSize()
    f.preview:__fire("OnClick")
    t.falsy(shown(inst), "the eye hides the console")
    t.falsy(f.preview.lit, "and dims")
    f.preview:__fire("OnClick")
    t.truthy(shown(inst), "the eye shows it again")
    t.truthy(f.preview.lit, "and lights")
    t.eq(inst.NS.DebugLog:BufferSize(), lines, "the sample was not written twice")
    t.truthy(f:IsShown(), "the picker stays up through both clicks")
end)

-- ── every close puts it back ─────────────────────────────────────────────────────────────────

local ROUTES = {
    { "the close control", function(_, f) f.close:__fire("OnClick") end },
    { "Escape", function(_, f) f:Hide() end },
    { "Apply", function(_, f) f.apply:__fire("OnClick") end },
    { "this addon's own hide (stand-down, profile event)", function(inst) inst.NS.HideSkinPicker() end },
}

for _, route in ipairs(ROUTES) do
    test("Skin preview: " .. route[1] .. " hides the console the picker opened", function()
        -- red under: a hook with no exit, or an exit that leaves the console up.
        local inst = loggedIn()
        local f = open(inst)
        t.truthy(shown(inst), "the picker opened the console")
        route[2](inst, f)
        t.nilv(shownOwner(inst), "the picker is down")
        t.falsy(shown(inst), "the console is hidden again")
    end)
end

test("Skin preview: the gear hides the console the picker opened, the panel opened", function()
    local inst = loggedIn()
    local f = open(inst)
    t.truthy(shown(inst))
    f.settings:__fire("OnClick")
    t.nilv(shownOwner(inst), "the gear closed the picker")
    t.falsy(shown(inst), "the console is hidden again")
end)

test("Skin preview: a console the eye hid and showed again is hidden at the close", function()
    local inst = loggedIn()
    local f = open(inst)
    f.preview:__fire("OnClick")
    f.preview:__fire("OnClick")
    t.truthy(shown(inst))
    f.close:__fire("OnClick")
    t.falsy(shown(inst), "back as it was at the open: hidden")
end)

-- ── a console already up is the player's ─────────────────────────────────────────────────────

test("Skin preview: a console already shown is left alone, its lines untouched", function()
    -- red under: an enter at show that ignores isShown, writing the sample into the player's own
    -- console, or a close that hides a console the picker never opened.
    local inst = loggedIn()
    inst.NS.DebugLog:Show()
    inst.NS.DebugLog:Add("Cmd", "the player's own line")
    local lines = inst.NS.DebugLog:BufferSize()
    local f = open(inst)
    t.truthy(shown(inst))
    t.eq(inst.NS.DebugLog:BufferSize(), lines, "nothing was written into it")
    t.falsy(inst.NS.DebugLog:FindLine(HEADER), "no sample")
    f.close:__fire("OnClick")
    t.truthy(shown(inst), "still shown after the close")
    t.truthy(inst.NS.DebugLog:FindLine("the player's own line"), "with the player's line")
end)

test("Skin preview: the player's console hidden by the eye comes back at the close, with no sample", function()
    -- red under: no restore of a mode that was on at the open, or a restore that runs the test
    -- path into the player's console.
    local inst = loggedIn()
    inst.NS.DebugLog:Show()
    local lines = inst.NS.DebugLog:BufferSize()
    local f = open(inst)
    f.preview:__fire("OnClick")
    t.falsy(shown(inst), "the eye hid it")
    f.close:__fire("OnClick")
    t.truthy(shown(inst), "the close shows it again")
    t.falsy(inst.NS.DebugLog:FindLine(HEADER), "and wrote no sample into it")
    t.eq(inst.NS.DebugLog:BufferSize(), lines)
end)

test("Skin preview: the next showing runs the sample again", function()
    -- red under: a once-per-session latch (the second /pc skin would open an empty console).
    local inst = loggedIn()
    open(inst).close:__fire("OnClick")
    inst.NS.DebugLog:Clear()
    open(inst)
    t.truthy(shown(inst))
    t.truthy(inst.NS.DebugLog:FindLine(HEADER), "the second showing filled the console again")
end)

-- ── the eye's art ────────────────────────────────────────────────────────────────────────────

test("Skin preview: CLAUDE.md declares the eye and its icon ships", function()
    -- red under: the declaration without `eye`, which prunes eye.tga, so the eye draws its glyph.
    local fh = assert(io.open(ctx.root .. "/CLAUDE.md", "rb"))
    local doc = fh:read("*a")
    fh:close()
    local line = doc:match("LibKa0s icons:([^\r\n]*)")
    t.truthy(line ~= nil, "the declaration line")
    local declared = false
    for name in tostring(line):gmatch("[%w%-]+") do
        if name == "eye" then declared = true end
    end
    t.truthy(declared, "the `LibKa0s icons:` line declares eye")
    local art = io.open(ctx.root .. "/libs/LibKa0s/media/icons/eye.tga", "rb")
    t.truthy(art ~= nil, "libs/LibKa0s/media/icons/eye.tga ships")
    if art then art:close() end
end)
