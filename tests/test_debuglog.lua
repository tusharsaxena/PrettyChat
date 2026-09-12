-- tests/test_debuglog.lua — the on-screen debug console (core/DebugLogSetup.lua):
-- the two pure line formatters, the FONT_MONO constant, and the /pc debug
-- seam (window toggle vs session-state on/off) plus the gated NS.Debug sink.

local function debugCmd(NS, rest)
    for _, entry in ipairs(NS.COMMANDS) do
        if entry[1] == "debug" then return entry[3](rest) end
    end
    error("no debug command in NS.COMMANDS")
end

local ctx = _G.PC_TEST
local t     = ctx.t
local test  = ctx.test
local inst  = ctx.loadAddon()
local NS    = inst.NS
local addon = inst.addon
local env   = inst.env
local D     = NS.DebugLog

test("FONT_MONO points at the vendored JetBrainsMono TTF", function()
    -- debug-logging-§2.
    t.truthy(type(NS.Const.FONT_MONO) == "string", "FONT_MONO is a string")
    t.truthy(NS.Const.FONT_MONO:match("JetBrainsMono.-%.ttf$") ~= nil,
        "FONT_MONO points at the vendored JetBrainsMono TTF")
end)

test("pure line formatters render plain and colored lines", function()
    -- Frame-free, unit-tested so color can't drift from plain.
    t.eq(D.FormatPlain("15:04:43", "Loot", "item x2"),
        "15:04:43 | [Loot] item x2", "FormatPlain: ts | [tag] msg")
    t.eq(D.FormatPlain("15:04:43", nil, "hi"),
        "15:04:43 | [] hi", "FormatPlain tolerates a nil tag")
    t.eq(D.FormatColored("15:04:43", "Loot", "item x2"),
        "|cff6f8faf15:04:43|r || |cffc9a66b[Loot]|r item x2",
        "FormatColored: steel-blue ts, tan/gold tag, default rest")
end)

test("/pc debug on|off drives the session flag through the SetEnabled seam", function()
    NS.State.debug = false
    debugCmd(NS, "on")
    t.eq(NS.State.debug, true, "/pc debug on enables session state")
    debugCmd(NS, "off")
    t.eq(NS.State.debug, false, "/pc debug off disables session state")
end)

test("color-coded chat ack: ON green, OFF red, via [PC]", function()
    -- debug-logging-§5.
    local msgs = env.DEFAULT_CHAT_FRAME.messages
    debugCmd(NS, "on")
    t.truthy(msgs[#msgs]:find("|cff40ff40ON|r", 1, true), "on ack colors ON green (40ff40)")
    debugCmd(NS, "off")
    t.truthy(msgs[#msgs]:find("|cffff4040OFF|r", 1, true), "off ack colors OFF red (ff4040)")
end)

test("enable emits the [Init] session summary after the bracket", function()
    -- debug-logging-§5/§8: [Init] session summary emitted on enable, immediately after the bracket.
    D:Clear()
    D:SetEnabled(true)
    local bracketIdx, initIdx
    for i, line in ipairs(D.buffer) do
        if line:find("%[Debug%] logging enabled") then bracketIdx = i end
        if line:find("%[Init%]") then initIdx = i end
    end
    t.truthy(bracketIdx, "enable writes the [Debug] logging enabled bracket line")
    t.truthy(initIdx and bracketIdx and initIdx > bracketIdx,
        "[Init] session summary follows the enable bracket")
    t.truthy(initIdx and D.buffer[initIdx]:find("PrettyChat v", 1, true),
        "[Init] carries the addon name + version")
    t.truthy(initIdx and D.buffer[initIdx]:find("schema v", 1, true),
        "[Init] carries the schema/DB version")
    t.truthy(initIdx and D.buffer[initIdx]:find("profile 'Default'", 1, true),
        "[Init] carries the active profile")
    D:SetEnabled(false)  -- leave logging off for the blocks below
end)

test("bare /pc debug toggles the window without changing the flag", function()
    NS.State.debug = true
    debugCmd(NS, "")
    t.eq(NS.State.debug, true, "bare /pc debug leaves state on")
    NS.State.debug = false
    debugCmd(NS, "")
    t.eq(NS.State.debug, false, "bare /pc debug leaves state off")
end)

test("header toggle click flips state through the same seam", function()
    -- Fire the button's real OnClick script rather than a copy of the
    -- closure parked beside it, so a dropped SetScript wiring fails here
    -- too — the header toggle and /pc debug on|off must stay one seam.
    NS.State.debug = false
    D:Show()
    local btn = env._frames.byName["PrettyChatDebugWindow"].debugToggleBtn
    t.truthy(btn, "the header toggle button was built")
    t.eq(type(btn:GetScript("OnClick")), "function", "with an OnClick handler wired to it")
    btn:FireScript("OnClick")
    t.eq(NS.State.debug, true,  "header click turns state on")
    btn:FireScript("OnClick")
    t.eq(NS.State.debug, false, "second header click turns state off")
end)

test("NS.Debug is a no-op when off and appends one line when on", function()
    NS.State.debug = false
    local before = #D.buffer
    NS.Debug("Loot", "%s x%d", "item", 2)
    t.eq(#D.buffer, before, "NS.Debug appends nothing when logging is off")
    NS.State.debug = true
    local n = #D.buffer
    NS.Debug("Loot", "%s x%d", "item", 2)
    t.eq(#D.buffer, n + 1, "NS.Debug appends one line when logging is on")
    t.truthy(D.buffer[#D.buffer]:find("| %[Loot%] item x2$"),
        "NS.Debug renders the format args into a [tag]-prefixed line")
end)

test("Schema.Set emits one [Set] line with no separate [Apply] echo", function()
    -- Producers (debug-logging-§8/§9/§10): a settings change logs exactly one [Set]
    -- line at the write seam — no separate [Apply] echo (folded per debug-logging-§10).
    NS.State.debug = true
    D:Clear()
    NS.Schema.Set("General.enabled", false)
    local setJoined = table.concat(D.buffer, "\n")
    t.truthy(setJoined:find("%[Set%] General%.enabled = false"),
        "Schema.Set emits one [Set] <path> = <value> line")
    t.falsy(setJoined:find("%[Apply%]"),
        "no separate [Apply] line per settings change")
end)

test("the console line and the copy buffer describe the same event", function()
    -- FormatColored feeds the on-screen log; FormatPlain feeds the Copy
    -- window. They must never drift apart in tag or message.
    NS.State.debug = true
    D:Clear()
    NS.Debug("Loot", "item x%d", 3)
    local plain = D.buffer[#D.buffer]
    -- The console frame itself is private; read the lines it was given.
    local console = env._frames.byName["PrettyChatDebugWindow"].log.messages
    t.eq(#D.buffer, 1, "one buffered line")
    t.truthy(plain:find("| %[Loot%] item x3$"), "the plain line carries tag + message")
    t.truthy(console[#console]:find("%[Loot%]|r item x3$"),
        "the console line carries the same tag + message, colored")
    NS.State.debug = false
end)

test("the plain buffer never carries color escapes of its own", function()
    NS.State.debug = true
    D:Clear()
    NS.Debug("Loot", "plain message")
    t.falsy(D.buffer[1]:find("|c", 1, true), "no color code is added to a plain line")
    t.eq(D.FormatPlain("00:00:00", "Tag", "msg"), "00:00:00 | [Tag] msg",
        "the plain formatter emits the bare separator, never an escape")
    t.truthy(D.FormatColored("00:00:00", "Tag", "msg"):find("|cff", 1, true),
        "while the console formatter does color its line")
    NS.State.debug = false
end)

test("NS.Debug neutralizes a protected value inside its format args", function()
    -- events-frames-taint-§8: a combat secret must not reach string.format.
    NS.State.debug = true
    D:Clear()
    local secret = setmetatable({}, { __concat = function() error("secret") end })
    local ok = pcall(NS.Debug, "Loot", "got %s", secret)
    t.truthy(ok, "the sink never raises on a protected value")
    t.truthy(D.buffer[1]:find("got <secret>", 1, true), "the value is replaced in place")
    NS.State.debug = false
end)

test("NS.Debug passes a bare message through without formatting it", function()
    NS.State.debug = true
    D:Clear()
    local ok = pcall(NS.Debug, "Loot", "100% done")
    t.truthy(ok, "a lone %-carrying message is not run through string.format")
    t.truthy(D.buffer[1]:find("100% done", 1, true), "and reaches the log verbatim")
    NS.State.debug = false
end)

test("NS.Debug keeps argument types so numeric conversions still work", function()
    NS.State.debug = true
    D:Clear()
    NS.Debug("Loot", "%d gold, %.1f%% rate, %s", 12, 2.5, "ok")
    t.truthy(D.buffer[1]:find("12 gold, 2.5% rate, ok", 1, true),
        "numbers survive the secret-safety pass as numbers")
    NS.State.debug = false
end)

test("the buffer is capped and drops its oldest lines first", function()
    D:Clear()
    for i = 1, 1520 do D:Add("Bulk", "line " .. i) end
    t.eq(#D.buffer, 1500, "the buffer holds at most MAX_BUFFER lines")
    t.truthy(D.buffer[1]:find("line 21", 1, true), "the oldest lines were dropped")
    t.truthy(D.buffer[#D.buffer]:find("line 1520", 1, true), "the newest line is kept")
end)

test("Clear empties both the buffer and the console view", function()
    D:Add("Loot", "before clear")
    D:Clear()
    t.eq(#D.buffer, 0, "the copy buffer is emptied")
    t.eq(#env._frames.byName["PrettyChatDebugWindow"].log.messages, 0,
        "and so is the on-screen log")
end)

test("the line counter reports buffered lines against the cap", function()
    D:Clear()
    D:Add("Loot", "one")
    t.eq(env._frames.byName["PrettyChatDebugWindow"].lineCount.text, "1 / 1500 lines",
        "the status bar counts lines against MAX_BUFFER")
end)

test("the Copy window is filled with the plain-text buffer", function()
    D:Clear()
    D:Add("Loot", "first")
    D:Add("Loot", "second")
    D:ShowCopy()
    local copy = env._frames.byName["PrettyChatDebugCopyWindow"]
    t.truthy(copy, "the copy window is created on demand")
    t.eq(copy.edit.text, table.concat(D.buffer, "\n"),
        "it holds the whole buffer, newline-joined")
    t.truthy(copy:IsShown(), "and it is shown")
end)

test("both console windows register for Esc-to-close", function()
    local registered = {}
    for _, name in ipairs(env.UISpecialFrames) do registered[name] = true end
    t.truthy(registered["PrettyChatDebugWindow"], "the console closes on Esc")
    t.truthy(registered["PrettyChatDebugCopyWindow"], "so does the copy window")
end)

test("Show, Hide and Toggle drive the window's visibility", function()
    D:Hide()
    t.falsy(D:IsShown(), "hidden reports false")
    D:Toggle()
    t.truthy(D:IsShown(), "toggle from hidden shows it")
    D:Toggle()
    t.falsy(D:IsShown(), "toggle again hides it")
    D:Show()
    t.truthy(D:IsShown(), "an explicit show reopens it")
end)

test("IsShown is false before the console has ever been built", function()
    -- The window is created lazily on first use; the General-page checkbox
    -- reads this before anything has opened it.
    local fresh = ctx.loadAddon()
    t.falsy(fresh.NS.DebugLog:IsShown(), "no frame yet means not shown")
end)

test("the header label tracks the session flag in the debug-logging-§5 state colors", function()
    local header = env._frames.byName["PrettyChatDebugWindow"].debugToggle
    D:SetEnabled(true)
    t.eq(header.text, "Debug: ON", "the toggle reads ON while logging")
    D:SetEnabled(false)
    t.eq(header.text, "Debug: OFF", "and OFF once stopped")
end)

test("SessionSummary self-identifies the build, schema and profile", function()
    local summary = D.SessionSummary()
    t.truthy(summary:find("PrettyChat v" .. ctx.mock.metadata.Version, 1, true),
        "addon name and version")
    t.truthy(summary:find("schema v" .. tostring(addon.db.global.schemaVersion), 1, true),
        "the live schema version")
    t.truthy(summary:find("profile 'Default'", 1, true), "the active profile")
end)

test("disabling logging still writes its closing bracket line", function()
    -- D:Add is ungated, so the "logging disabled" line lands after the flag
    -- has already flipped off.
    D:SetEnabled(true)
    D:Clear()
    D:SetEnabled(false)
    t.eq(#D.buffer, 1, "exactly one line is written on disable")
    t.truthy(D.buffer[1]:find("[Debug] logging disabled", 1, true), "the closing bracket")
    t.falsy(NS.State.debug, "with the flag already off")
end)

-- debug-logging-§10: a profile-wide reset, copy or switch is logged ONCE, by the
-- profile-event handler, worded by the event. Each case below captures the whole
-- console buffer, so "exactly one line" means one line in total.

local function firstLootFormatPath()
    for _, r in ipairs(NS.Schema.RowsByCategory("Loot")) do
        if r.kind == "string_format" then return r.path end
    end
end

-- Run fn with the debug console capturing from empty, ApplyStrings and
-- Schema.NotifyPanelChange counted, and hand back pcall's (ok, err), the buffer,
-- the pass count and the notify count. The console's own visibility hook notifies
-- too: the first line ever logged builds the frame and fires it, so one line is
-- logged before the counters go in, and a test that wants the console open opens
-- it BEFORE this, never inside.
local function captureRaw(fn)
    local Schema = NS.Schema
    NS.State.debug = true
    NS.Debug("Test", "warm-up")
    local origApply, origNotify = addon.ApplyStrings, Schema.NotifyPanelChange
    local passes, notifies = 0, 0
    addon.ApplyStrings = function(self, ...)
        passes = passes + 1
        return origApply(self, ...)
    end
    Schema.NotifyPanelChange = function(...)
        notifies = notifies + 1
        return origNotify(...)
    end
    NS.State.debug = true
    D:Clear()
    local ok, err = pcall(fn)
    NS.State.debug = false
    addon.ApplyStrings, Schema.NotifyPanelChange = origApply, origNotify
    return ok, err, D.buffer, passes, notifies
end

-- The same, re-raising: hands back the buffer, the pass count and the notify count.
local function capture(fn)
    local ok, err, buf, passes, notifies = captureRaw(fn)
    if not ok then error(err, 0) end
    return buf, passes, notifies
end

test("ResetAll logs one [Set] reset profile line counting the rows it rewrote", function()
    addon:ResetAll()
    NS.Schema.Set("Loot.enabled", false)
    NS.Schema.Set(firstLootFormatPath(), "CUSTOM")
    NS.Schema.Set("General.visibility", "never")
    -- The session-only console row reads differently from its default (open vs
    -- closed), and a profile reset must neither count it nor close the console.
    local consoleRow = NS.Schema.FindByPath("state.debugConsole")
    NS.Schema.Set("state.debugConsole", true)
    t.truthy(D:IsShown(), "the console is open before the reset")
    local origSet, consoleWrites = consoleRow.set, 0
    consoleRow.set = function(...) consoleWrites = consoleWrites + 1; return origSet(...) end

    local ok, err, buf, passes, notifies = captureRaw(function() addon:ResetAll() end)
    consoleRow.set = origSet
    local stillShown = D:IsShown()
    NS.Schema.Set("state.debugConsole", false)
    if not ok then error(err, 0) end

    t.eq(#buf, 1, "exactly one line for the whole reset")
    t.truthy(buf[1]:find("[Set] reset profile 'Default' to defaults (3 rows)", 1, true),
        "worded by the event, counting the three changed rows and not the console row")
    t.eq(consoleWrites, 0, "the console row is never written")
    t.truthy(stillShown, "and the console stays open")
    t.eq(passes, 1, "exactly one ApplyStrings pass")
    t.eq(notifies, 1, "exactly one NotifyPanelChange")
end)

test("/pc resetall is one debug line in total", function()
    addon:ResetAll()
    NS.Schema.Set("Loot.enabled", false)
    local buf, passes, notifies = capture(function() addon:OnSlashCommand("resetall") end)
    t.eq(#buf, 1, "the slash verb adds no second line")
    t.truthy(buf[1]:find("[Set] reset profile 'Default' to defaults (1 rows)", 1, true),
        "the same profile-reset line")
    t.eq(passes, 1, "one ApplyStrings pass")
    t.eq(notifies, 1, "one NotifyPanelChange")
end)

test("a profile reset AceDB starts on its own is one line, without a count", function()
    -- Nothing counted the rows before AceDB wiped them, so the count is omitted
    -- rather than guessed (debug-logging-§10: included where cheap).
    addon:ResetAll()
    local buf = capture(function() addon.db:ResetProfile() end)
    t.eq(#buf, 1, "one line")
    t.truthy(buf[1]:find("%[Set%] reset profile 'Default' to defaults$"),
        "the reset line with no count")
end)

test("a profile copy logs one [Set] copied line and nothing else", function()
    addon:ResetAll()
    addon.db:SetProfile("Alt")
    NS.Schema.Set("Loot.enabled", false)
    addon.db:SetProfile("Default")
    local buf, passes, notifies = capture(function() addon.db:CopyProfile("Alt") end)
    t.eq(#buf, 1, "exactly one line for the copy")
    t.truthy(buf[1]:find("[Set] copied profile '", 1, true), "a [Set] copied line")
    t.truthy(buf[1]:find("' \226\134\146 'Default'", 1, true), "into the active profile")
    t.eq(addon.db.profile.categories.Loot.enabled, false, "and the copy really landed")
    t.eq(passes, 1, "one ApplyStrings pass")
    t.eq(notifies, 1, "one NotifyPanelChange")
    addon:ResetAll()
end)

test("the copy line names AceDB's source profile and the active one", function()
    -- AceDB fires OnProfileCopied(event, db, sourceProfileKey). Driven directly
    -- with that signature, because the kit's AceDB fake passes the active profile
    -- in the source's place.
    local buf = capture(function()
        addon:OnProfileCopied("OnProfileCopied", addon.db, "Alt")
    end)
    t.eq(#buf, 1, "one line")
    t.truthy(buf[1]:find("[Set] copied profile 'Alt' \226\134\146 'Default'", 1, true),
        "source first, destination second")
end)

test("a profile switch keeps its one [Profile] line", function()
    local buf = capture(function() addon.db:SetProfile("Alt") end)
    addon.db:SetProfile("Default")
    t.eq(#buf, 1, "one line for the switch")
    t.truthy(buf[1]:find("[Profile] switched \226\134\146 applied", 1, true),
        "the addon's existing switch line, unchanged")
end)

-- debug-logging-§10, failure marker: a profile reset or copy that raises partway
-- still writes its one line, ending in ` (stopped by an error)`, exactly once, and
-- the error still reaches the caller. The kit's AceDB fake calls the handlers
-- directly, so a handler's raise comes back out of ResetProfile here.

test("a profile reset that raises logs its one line marked, exactly once", function()
    addon:ResetAll()
    NS.Schema.Set("Loot.enabled", false)
    -- Raised in the handler's reload, after AceDB's wipe: the handler writes the
    -- line, and ResetAll must not add a second one on the way out.
    local origApply = addon.ApplyStrings
    addon.ApplyStrings = function() error("boom in the reload") end
    local ok, err, buf = captureRaw(function() addon:ResetAll() end)
    addon.ApplyStrings = origApply
    t.falsy(ok, "the error reaches the caller")
    t.truthy(tostring(err):find("boom in the reload", 1, true), "with its own message")
    t.eq(#buf, 1, "exactly one line")
    t.truthy(buf[1]:find("[Set] reset profile 'Default' to defaults (1 rows) (stopped by an error)", 1, true),
        "the wipe landed, so its row counts, and the line says it stopped")
    t.nilv(addon.pendingReset, "the parked count is cleared")

    -- Raised inside AceDB before the callback fires: the handler never ran, so
    -- ResetAll writes the line, counting what the wipe had changed (nothing).
    addon:ResetAll()
    NS.Schema.Set("Loot.enabled", false)
    local db = addon.db
    local origReset = db.ResetProfile
    db.ResetProfile = function() error("boom in AceDB") end
    ok, err, buf = captureRaw(function() addon:ResetAll() end)
    db.ResetProfile = origReset
    t.falsy(ok, "that error reaches the caller too")
    t.truthy(tostring(err):find("boom in AceDB", 1, true), "with its own message")
    t.eq(#buf, 1, "exactly one line")
    t.truthy(buf[1]:find("[Set] reset profile 'Default' to defaults (0 rows) (stopped by an error)", 1, true),
        "nothing was wiped, so nothing counts")
    t.nilv(addon.pendingReset, "the parked count is cleared")
    addon:ResetAll()
end)

test("a profile copy that raises logs its one line marked", function()
    local origApply = addon.ApplyStrings
    addon.ApplyStrings = function() error("boom in the copy") end
    local ok, err, buf = captureRaw(function()
        addon:OnProfileCopied("OnProfileCopied", addon.db, "Alt")
    end)
    addon.ApplyStrings = origApply
    t.falsy(ok, "the error reaches the caller")
    t.truthy(tostring(err):find("boom in the copy", 1, true), "with its own message")
    t.eq(#buf, 1, "exactly one line")
    t.truthy(buf[1]:find("[Set] copied profile 'Alt' \226\134\146 'Default' (stopped by an error)", 1, true),
        "the copy line, saying it stopped")
    addon:ResetAll()
end)
