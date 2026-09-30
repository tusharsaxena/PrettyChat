-- tests/test_debug_coverage.lua — the debug console's CONTENT (debug-logging-§8, the
-- Diagnosis checklist, and §9's quiet steady state), as docs/debug.md's `## Coverage`
-- section lists it. test_debuglog.lua owns the console's wiring and the [Set] lines;
-- this suite owns the lines a support read of a pasted log needs beyond them: the
-- combat edges, the watcher's registration, the command as typed, the refusals with
-- their guard, the caught errors, the Categories page's view switches, the two
-- state tails of the [Init] summary, and the lines LibKa0s writes through this addon's
-- sink (Slash's refusals, Lifecycle's edges, the Options combat lock; LibKa0s v1.65.0),
-- each pinned as ONE line, never a host copy beside it.
--
-- Each case captures the buffer from a mark, so "no new line" means none at all.

local ctx  = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local function since(D, from)
    local out = {}
    for i = from + 1, #D.buffer do out[#out + 1] = D.buffer[i] end
    return out
end

local function count(lines, needle)
    local n = 0
    for _, line in ipairs(lines) do
        if line:find(needle, 1, true) then n = n + 1 end
    end
    return n
end

-- A fresh instance with logging on, so no other suite's state reaches the buffer.
local function logging(opts)
    local inst = ctx.loadAddon(opts)
    inst.NS.DebugLog:SetEnabled(true)
    inst.NS.DebugLog:Clear()
    return inst, inst.NS.DebugLog
end

local function watcher(env) return env._frames.byName["PrettyChatCombatWatcher"] end

-- ---- combat edges (Diagnosis: state edges) ----------------------------------

-- red under: the pre-060 line `inCombat → applied N restored M`, which logged the
-- mode and never said which boundary fired, so a paste could not tell entering
-- combat from leaving it.
test("each combat boundary is one line naming the edge and the state it took", function()
    local inst, D = logging()
    inst.NS.Schema.Set("General.visibility", "inCombat")
    local from = #D.buffer
    inst.env.__inCombat = true
    watcher(inst.env):FireScript("OnEvent", "PLAYER_REGEN_DISABLED")
    inst.env.__inCombat = false
    watcher(inst.env):FireScript("OnEvent", "PLAYER_REGEN_ENABLED")
    local lines = since(D, from)
    t.eq(#lines, 2, "one line per boundary: " .. table.concat(lines, " / "))
    t.truthy(lines[1]:find("[Visibility] combat entered (inCombat)", 1, true), lines[1])
    t.truthy(lines[1]:find("applied %d+ restored 0$"), "entering applies: " .. lines[1])
    t.truthy(lines[2]:find("[Visibility] combat left (inCombat)", 1, true), lines[2])
    t.truthy(lines[2]:find("applied 0 restored %d+$"), "leaving restores: " .. lines[2])
end)

-- ---- the watcher's registration (Diagnosis: state edges; §9 quiet steady state) --

-- red under: a SyncCombatWatch with no registration trace, where a combat mode that
-- never took effect left nothing in the log to show whether the watcher was armed.
test("arming and disarming the combat watcher is one line each", function()
    local inst, D = logging()
    inst.NS.Schema.Set("General.visibility", "outOfCombat")
    t.eq(count(since(D, 0), "[Events] combat watch armed: 2/2 events"), 1, "armed, once")
    local from = #D.buffer
    inst.NS.Schema.Set("General.visibility", "always")
    t.eq(count(since(D, from), "[Events] combat watch disarmed"), 1, "disarmed, once")
end)

-- QUIET STEADY STATE. SyncCombatWatch re-registers on every Reapply; red under a
-- trace that logged the registration on every call rather than on its change.
test("re-arming an armed watcher logs nothing, however often it runs", function()
    local inst, D = logging()
    inst.NS.Schema.Set("General.visibility", "inCombat")
    local from = #D.buffer
    for _ = 1, 25 do inst.addon.Reapply() end
    t.eq(#since(D, from), 0, "25 passes with nothing changed add no line")
    inst.NS.Schema.Set("General.visibility", "never")
    from = #D.buffer
    for _ = 1, 25 do inst.addon.Reapply() end
    t.eq(#since(D, from), 0, "nor do 25 passes over a disarmed watcher")
end)

-- QUIET STEADY STATE for the refused-name line, which used to repeat on every re-arm.
test("a refused event name is logged once per arming, not once per pass", function()
    local inst, D = logging({ mock = function(m)
        m.__badEvents = { PLAYER_REGEN_DISABLED = true }
        m.C_EventUtils = nil
    end })
    inst.NS.Schema.Set("General.visibility", "inCombat")
    for _ = 1, 10 do inst.addon.Reapply() end
    local lines = since(D, 0)
    t.eq(count(lines, "[Events] rejected PLAYER_REGEN_DISABLED"), 1, "one rejected line")
    t.eq(count(lines, "combat watch armed: 1/2 events"), 1, "on the one arm line's heels")
end)

-- ---- the [Init] summary's state tails (Diagnosis: stand-down, dependencies) -----

test("the [Init] summary carries no state tail on a plain enabled install", function()
    local inst = ctx.loadAddon()
    local summary = inst.NS.DebugLog.SessionSummary()
    t.falsy(summary:find("stood down", 1, true), summary)
    t.falsy(summary:find("chat addons", 1, true), summary)
end)

-- red under: a summary without the tail. The stand-down edge is taken in OnEnable,
-- while the session-only flag is off, so no [Lifecycle] line can record it.
test("the [Init] summary names the holds of a stood-down addon", function()
    local inst = ctx.loadAddon()
    inst.NS.Schema.Set("General.enabled", false)
    t.truthy(inst.NS.DebugLog.SessionSummary():find(", stood down: disabled", 1, true),
        inst.NS.DebugLog.SessionSummary())
end)

-- red under: a summary without the tail, where the first explanation for "my format
-- does not show" (another addon rewriting chat) was only in the diagnostics report.
test("the [Init] summary names a loaded chat-rewriting addon", function()
    local inst = ctx.loadAddon()
    inst.env.C_AddOns.IsAddOnLoaded = function(name) return name == "ElvUI" end
    t.truthy(inst.NS.DebugLog.SessionSummary():find(", chat addons: ElvUI", 1, true),
        inst.NS.DebugLog.SessionSummary())
end)

-- ---- the command as typed, and the host's refusals (Diagnosis: refusals) ---------

-- red under: an OnSlashCommand with no trace, where a pasted log showed a setting
-- change or nothing at all and never what the player typed.
test("a slash command is one [Cmd] line, as typed, with pipes doubled", function()
    local inst, D = logging()
    inst.addon:OnSlashCommand("version")
    inst.addon:OnSlashCommand("get Loot.|cffff0000x")
    local lines = since(D, 0)
    t.eq(lines[1] and lines[1]:match("%[Cmd%] .*$"), "[Cmd] /pc version", lines[1])
    t.truthy(count(lines, "[Cmd] /pc get Loot.||cffff0000x") == 1,
        "a pipe reads as typed: " .. table.concat(lines, " / "))
end)

test("a command sent with logging off leaves no line", function()
    local inst = ctx.loadAddon()
    local D = inst.NS.DebugLog
    D:Clear()
    inst.addon:OnSlashCommand("version")
    t.eq(#D.buffer, 0, "the gate holds")
end)

-- red under: a [Cmd] line without the tail. The tail names the holds behind the
-- command; the refusal itself is the library's own line (the next section).
test("a command on a stood-down addon names the holds", function()
    local inst, D = logging()
    inst.NS.Schema.Set("General.enabled", false)
    local from = #D.buffer
    inst.addon:OnSlashCommand("test")
    t.eq(count(since(D, from), "[Cmd] /pc test (stood down: disabled)"), 1,
        table.concat(since(D, from), " / "))
end)

-- red under: the host's refusals printing to chat alone, so the log said a command
-- arrived and never why nothing happened.
test("a refused command names the guard", function()
    local inst, D = logging()
    inst.addon:OnSlashCommand("list Nope")
    inst.addon:OnSlashCommand("reset Loot")
    inst.addon:OnSlashCommand("test category Nope")
    inst.addon:OnSlashCommand("test formatstring NOPE")
    inst.addon:OnSlashCommand("debug sideways")
    local lines = since(D, 0)
    t.eq(count(lines, "[Cmd] list refused: unknown category 'Nope'"), 1, "list")
    t.eq(count(lines, "[Cmd] reset refused: 'Loot' is a category, not a path"), 1, "reset")
    t.eq(count(lines, "[Cmd] test refused: unknown category 'Nope'"), 1, "test category")
    t.eq(count(lines, "[Cmd] test refused: unknown format string 'NOPE'"), 1, "test formatstring")
    t.eq(count(lines, "[Cmd] debug refused: unknown form 'sideways'"), 1, "debug")
end)

-- ---- caught errors (Diagnosis: errors caught) ----------------------------------

-- red under: NotifyPanelChange's bare pcall, which swallowed a raising refresher
-- with no trace at all. And once per distinct error: red under a line per write.
test("a raising refresher is one [UI] line, however many writes reach it", function()
    local inst, D = logging()
    local Schema = inst.NS.Schema
    Schema.RegisterRefresher("Loot", function() error("panel exploded", 0) end)
    for _ = 1, 5 do Schema.NotifyPanelChange("Loot") end
    Schema.NotifyPanelChange(nil)
    local lines = since(D, 0)
    t.eq(count(lines, "[UI] refresher Loot failed: panel exploded"), 1, table.concat(lines, " / "))
    Schema.RegisterRefresher("Loot", nil)
end)

test("a caught error seen with logging off is still reported once logging is on", function()
    local inst = ctx.loadAddon()
    local D, Util = inst.NS.DebugLog, inst.NS.Util
    Util.TraceCaught("UI", "site", "boom")
    D:SetEnabled(true)
    D:Clear()
    Util.TraceCaught("UI", "site", "boom")
    Util.TraceCaught("UI", "site", "boom")
    t.eq(#D.buffer, 1, "the first sighting with the flag on is the one line")
end)

-- ---- view switches (§8: view open / tab switches) -------------------------------

-- red under: a Categories strip whose onSelect traced nothing, where a paste showed
-- [Set] lines for a tab the log never said the player was on.
test("a Categories tab switch and a string selection are one [UI] line each", function()
    local inst, D = logging()
    local fixture = dofile(ctx.root .. "/tests/panel_fixture.lua")(inst.NS)
    fixture.panelFrame(inst.env, "Categories"):Show()
    local money
    for _, b in ipairs(fixture.tabButtons("Categories")) do
        if b.text == "Money" then money = b end
    end
    local from = #D.buffer
    money:FireScript("OnClick")
    t.eq(count(since(D, from), "[UI] categories tab Money"), 1, table.concat(since(D, from), " / "))
    local tree
    for _, child in ipairs(inst.NS.Helpers.__panelFor("Categories").scroll.children) do
        if child.type == "TreeGroup" then tree = child end
    end
    local second = tree.tree[2].value
    from = #D.buffer
    tree:Fire("OnGroupSelected", second)
    t.eq(count(since(D, from), "[UI] Money string " .. second), 1, table.concat(since(D, from), " / "))
end)

-- ---- the library's own lines, through this addon's sink (LibKa0s v1.65.0) ----------

local function tagged(lines, tag)
    local out = {}
    for _, line in ipairs(lines) do
        if line:find("[" .. tag .. "]", 1, true) then out[#out + 1] = line end
    end
    return out
end

-- red under: a Slash descriptor with no `debug` (the refusal reached chat alone), and
-- under a host that logged the refusal too (two lines for one refusal).
test("the dispatcher's own refusals land in this log, one line each", function()
    local inst, D = logging()
    inst.NS.Schema.Set("General.enabled", false)
    local from = #D.buffer
    inst.addon:OnSlashCommand("test")
    local lines = since(D, from)
    t.eq(count(lines, "[Cmd] refused test: disabled"), 1, table.concat(lines, " / "))
    t.eq(count(lines, "refused test"), 1, "and no second copy of it")
    t.eq(#lines, 2, "the command as typed, then the library's refusal: " .. table.concat(lines, " / "))
    inst.NS.Schema.Set("General.enabled", true)
    from = #D.buffer
    inst.addon:OnSlashCommand("frobnicate")
    inst.addon:OnSlashCommand("get Nope.x")
    lines = since(D, from)
    t.eq(count(lines, "[Cmd] refused frobnicate: unknown verb"), 1, table.concat(lines, " / "))
    t.eq(count(lines, "[Cmd] refused get Nope.x: not found"), 1, table.concat(lines, " / "))
    t.eq(#tagged(lines, "Cmd"), 4, "two commands, two refusals: " .. table.concat(lines, " / "))
end)

-- A host verb's refusal stays this addon's line and gains no library copy.
test("a host verb's refusal is the host's line alone", function()
    local inst, D = logging()
    inst.addon:OnSlashCommand("list Nope")
    local lines = since(D, 0)
    t.eq(count(lines, "[Cmd] list refused: unknown category 'Nope'"), 1, table.concat(lines, " / "))
    t.eq(count(lines, "refused list"), 0, "the library writes nothing for a verb it does not own")
end)

-- red under: a Lifecycle descriptor with no `debug`, and under the arms' own
-- `stood down -> holds` / `stood up -> no holds` lines kept beside the library's.
test("a stand-down and a stand-up edge are the library's one line each", function()
    local inst, D = logging()
    local from = #D.buffer
    inst.NS.Schema.Set("General.enabled", false)
    local lines = tagged(since(D, from), "Lifecycle")
    t.eq(#lines, 1, "one line for the edge: " .. table.concat(lines, " / "))
    t.truthy(lines[1] and lines[1]:find("[Lifecycle] stood down: added disabled (holds: disabled)", 1, true),
        lines[1])
    from = #D.buffer
    inst.NS.Lifecycle:Hold(inst.NS.HOLD_DISABLED)
    t.eq(#tagged(since(D, from), "Lifecycle"), 0, "a call that fires no edge writes nothing")
    from = #D.buffer
    inst.NS.Schema.Set("General.enabled", true)
    lines = tagged(since(D, from), "Lifecycle")
    t.eq(#lines, 1, "one line for the edge back up: " .. table.concat(lines, " / "))
    t.truthy(lines[1] and lines[1]:find("[Lifecycle] stood up: released disabled (holds: none)", 1, true),
        lines[1])
end)

-- red under: an Options descriptor whose `debug` went nowhere, and under a host
-- onSelect that ran (and traced its own [UI] line) under the lock.
test("a tab switch refused by the combat lock is the library's one [Cfg] line", function()
    local inst, D = logging()
    local fixture = dofile(ctx.root .. "/tests/panel_fixture.lua")(inst.NS)
    fixture.panelFrame(inst.env, "Categories"):Show()
    local money
    for _, b in ipairs(fixture.tabButtons("Categories")) do
        if b.text == "Money" then money = b end
    end
    local from = #D.buffer
    inst.env.InCombatLockdown = function() return true end
    money:FireScript("OnClick")
    money:FireScript("OnClick")
    inst.env.InCombatLockdown = function() return false end
    local lines = since(D, from)
    t.eq(count(lines, "[Cfg] tab Money refused (in combat)"), 1,
        "once per combat, however often it is clicked: " .. table.concat(lines, " / "))
    t.eq(count(lines, "[UI] categories tab Money"), 0, "the host's switch did not run")
end)

-- ---- the console's change gates (DebugLogGates 1) -------------------------------

-- red under: the hand-rolled `watchArmed` memo, which a Clear never re-armed, so a
-- cleared console stayed silent about an armed watcher until it next changed.
test("a Clear re-arms the watcher's change gate, and the steady state stays quiet", function()
    local inst, D = logging()
    inst.NS.Schema.Set("General.visibility", "inCombat")
    D:Clear()
    inst.addon.Reapply()
    t.eq(count(since(D, 0), "[Events] combat watch armed: 2/2 events"), 1,
        "the first pass after the Clear states the watcher: " .. table.concat(since(D, 0), " / "))
    local from = #D.buffer
    for _ = 1, 10 do inst.addon.Reapply() end
    t.eq(#since(D, from), 0, "and the passes after it add nothing")
end)

-- red under: a watcher memo taken while logging was off, which kept the first pass
-- after `/pc debug on` silent about a watcher armed at login.
test("the watcher armed while logging was off is stated on the first pass after enable", function()
    local inst = ctx.loadAddon()
    local D = inst.NS.DebugLog
    inst.NS.Schema.Set("General.visibility", "inCombat")
    D:SetEnabled(true)
    D:Clear()
    inst.addon.Reapply()
    t.eq(count(since(D, 0), "[Events] combat watch armed: 2/2 events"), 1, table.concat(since(D, 0), " / "))
end)

-- red under: TraceCaught's own `seenErrors` table, which a Clear never re-armed.
test("a Clear re-arms the caught-error gate", function()
    local inst, D = logging()
    local Util = inst.NS.Util
    Util.TraceCaught("UI", "site", "boom")
    Util.TraceCaught("UI", "site", "boom")
    t.eq(#D.buffer, 1, "one line per distinct error")
    D:Clear()
    Util.TraceCaught("UI", "site", "boom")
    t.eq(count(since(D, 0), "[UI] site failed: boom"), 1, "heard again once, after the Clear")
end)

-- The library-absent stub's gates answer false and raise nothing.
test("with LibKa0s absent the gated call sites write nothing and raise nothing", function()
    local bare = ctx.loadAddon({ skip = { "libs/LibKa0s/Core.lua" } })
    bare.NS.DebugLog:SetEnabled(true)
    t.truthy(pcall(bare.NS.Util.TraceCaught, "UI", "site", "boom"), "TraceCaught")
    t.truthy(pcall(bare.NS.Schema.Set, "General.visibility", "inCombat"), "the watcher's trace")
    t.eq(bare.NS.DebugLog.DebugOnce("k", "UI", "x"), false, "DebugOnce answers false")
    t.eq(bare.NS.DebugLog.DebugChanged("k", "UI", "x"), false, "DebugChanged answers false")
end)

-- ---- the at-enable queue (DebugLogGates 1, Launcher 5) --------------------------

-- red under: a Launcher descriptor with no `debugAtEnable`, whose Register (run in
-- OnEnable, with the session-only flag off) wrote its state line through the gated
-- `debug` and so never landed.
test("the launcher's state line from OnEnable lands at the first enable, once", function()
    local inst = ctx.loadAddon()
    local D = inst.NS.DebugLog
    D:Clear()
    D:SetEnabled(true)
    local lines = since(D, 0)
    t.eq(count(lines, "[Launcher] LibDataBroker-1.1 absent; no launcher"), 1, table.concat(lines, " / "))
    local init, held
    for i, line in ipairs(lines) do
        if line:find("[Init]", 1, true) then init = i end
        if line:find("[Launcher]", 1, true) then held = i end
    end
    t.truthy(init and held and held > init, "after the [Init] summary: " .. table.concat(lines, " / "))
    D:SetEnabled(false)
    D:Clear()
    D:SetEnabled(true)
    t.eq(count(since(D, 0), "[Launcher]"), 0, "one-shot: a second enable does not repeat it")
end)
