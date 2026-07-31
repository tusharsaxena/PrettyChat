-- tests/test_debuglog.lua — the on-screen debug console (core/DebugLog.lua):
-- the two pure line formatters, the FONT_MONO constant, and the /pc debug
-- seam (window toggle vs session-state on/off) plus the gated NS.Debug sink.

local function debugCmd(NS, addon, rest)
    for _, entry in ipairs(NS.COMMANDS) do
        if entry[1] == "debug" then return entry[3](addon, rest) end
    end
    error("no debug command in NS.COMMANDS")
end

return function(ctx)
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

    test("pure line formatters render plain and coloured lines", function()
        -- Frame-free, unit-tested so colour can't drift from plain.
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
        debugCmd(NS, addon, "on")
        t.eq(NS.State.debug, true, "/pc debug on enables session state")
        debugCmd(NS, addon, "off")
        t.eq(NS.State.debug, false, "/pc debug off disables session state")
    end)

    test("colour-coded chat ack: ON green, OFF red, via [PC]", function()
        -- debug-logging-§5.
        local msgs = env.DEFAULT_CHAT_FRAME.messages
        debugCmd(NS, addon, "on")
        t.truthy(msgs[#msgs]:find("|cff40ff40ON|r", 1, true), "on ack colours ON green (40ff40)")
        debugCmd(NS, addon, "off")
        t.truthy(msgs[#msgs]:find("|cffff4040OFF|r", 1, true), "off ack colours OFF red (ff4040)")
    end)

    test("enable emits the [Init] session summary after the bracket", function()
        -- §5/§8: [Init] session summary emitted on enable, immediately after the bracket.
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
        debugCmd(NS, addon, "")
        t.eq(NS.State.debug, true, "bare /pc debug leaves state on")
        NS.State.debug = false
        debugCmd(NS, addon, "")
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
        -- line at the write seam — no separate [Apply] echo (folded per §10).
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
            "the console line carries the same tag + message, coloured")
        NS.State.debug = false
    end)

    test("the plain buffer never carries colour escapes of its own", function()
        NS.State.debug = true
        D:Clear()
        NS.Debug("Loot", "plain message")
        t.falsy(D.buffer[1]:find("|c", 1, true), "no colour code is added to a plain line")
        t.eq(D.FormatPlain("00:00:00", "Tag", "msg"), "00:00:00 | [Tag] msg",
            "the plain formatter emits the bare separator, never an escape")
        t.truthy(D.FormatColored("00:00:00", "Tag", "msg"):find("|cff", 1, true),
            "while the console formatter does colour its line")
        NS.State.debug = false
    end)

    test("NS.Debug neutralises a protected value inside its format args", function()
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
        for i = 1, 520 do D:Add("Bulk", "line " .. i) end
        t.eq(#D.buffer, 500, "the buffer holds at most MAX_BUFFER lines")
        t.truthy(D.buffer[1]:find("line 21", 1, true), "the oldest lines were dropped")
        t.truthy(D.buffer[#D.buffer]:find("line 520", 1, true), "the newest line is kept")
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
        t.eq(env._frames.byName["PrettyChatDebugWindow"].lineCount.text, "1 / 500 lines",
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

    test("the header label tracks the session flag in the §5 state colours", function()
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

    test("ResetAll emits one [Reset] summary carrying apply counts", function()
        -- A bulk reset bypasses the write seam, so it logs one [Reset] summary.
        NS.State.debug = true
        D:Clear()
        addon:ResetAll()
        local resetJoined = table.concat(D.buffer, "\n")
        t.truthy(resetJoined:find("%[Reset%] all"),
            "ResetAll emits a [Reset] summary line")
        t.truthy(resetJoined:find("applied %d+ restored %d+"),
            "[Reset] carries the material apply counts")
    end)
end
