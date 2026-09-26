-- tests/test_diagnostics.lua — the diagnostics report's PrettyChat half (debug-logging-§14):
-- the sections in modules/Diagnostics.lua, the `diagnostics` verb and the `debug diagnostics`
-- word in settings/Slash.lua, and the descriptor fields core/DebugLogSetup.lua hands the library.
--
-- The dispatcher contract every addon owes (both forms, any case, the markers, append, ungated,
-- while disabled, no `diag`) is the kit's shared suite, tests/_kit/test_diagnostics_contract.lua,
-- wired through Kit.diagnostics in tests/run.lua. What is here is this addon's own: what the
-- report says about PrettyChat, and that saying it changes nothing.

local ctx  = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local ENABLED_PATH = "General.enabled"

-- One line per report row, `[Tag] message`, so a case can search the report as the Copy text
-- would read it without the timestamps.
local function report(i, spec)
    local built = i.NS.DebugLog:BuildDiagnostics(spec)
    local out = {}
    for n, line in ipairs(built.lines) do out[n] = "[" .. line[1] .. "] " .. line[2] end
    return out, built
end

local function find(lines, needle)
    for n, line in ipairs(lines) do
        if line:find(needle, 1, true) then return n, line end
    end
end

local function count(lines, needle)
    local n = 0
    for _, line in ipairs(lines) do
        if line:find(needle, 1, true) then n = n + 1 end
    end
    return n
end

local function slash(i, input) i.addon:OnSlashCommand(input) end

-- The loader seeds every pristine original as `ORIG:<NAME>`, which carries no conversions, so
-- against it every shipped default reads as patch drift. A client's real originals carry the
-- conversions the defaults were written against; seeding each original with its own default is
-- the closest the harness gets to that, and a case that asks about drift starts from it.
local function realOriginals(i)
    for _, catData in pairs(i.NS.Defaults) do
        for name, strData in pairs(catData.strings or {}) do
            i.addon.originalStrings[name] = strData.default
        end
    end
    return i
end

-- The first Loot string whose default carries a conversion, and that default.
local function aLootString(i)
    for _, name in ipairs(i.NS.SortedStringNames("Loot")) do
        local default = i.NS.Defaults.Loot.strings[name].default
        if default:find("%s", 1, true) then return name, default end
    end
end

-- ── the verbs ───────────────────────────────────────────────────────────────

test("diagnostics: /pc diagnostics is a COMMANDS row and writes the report", function()
    local i = ctx.loadAddon()
    local row
    for _, entry in ipairs(i.NS.COMMANDS) do
        if entry[1] == "diagnostics" then row = entry end
    end
    t.truthy(row, "COMMANDS carries a `diagnostics` row (slash-commands-§2)")
    t.eq(type(row[2]), "string", "with a help description")
    local D = i.NS.DebugLog
    local before = #D.buffer
    slash(i, "diagnostics")
    t.truthy(#D.buffer > before, "the verb appended the report to the console")
    t.truthy(D.buffer[#D.buffer]:find("Ka0s Pretty Chat diagnostics end:", 1, true),
        "and it ends on the end marker, with the brand")
end)

test("diagnostics: `debug diagnostics` is tested before the other debug words", function()
    local i = ctx.loadAddon()
    local D = i.NS.DebugLog
    local before = #D.buffer
    slash(i, "debug diagnostics")
    t.truthy(#D.buffer > before, "/pc debug diagnostics wrote the report")
    t.eq(i.NS.State.debug, false, "and left the logging flag where it was")
end)

test("diagnostics: the debug usage line names diagnostics, and `diag` is an ordinary unknown word", function()
    local i = ctx.loadAddon()
    local msgs = i.env.DEFAULT_CHAT_FRAME.messages
    local D = i.NS.DebugLog
    local before = #D.buffer
    slash(i, "debug diag")
    t.eq(#D.buffer, before, "`debug diag` wrote nothing to the console")
    t.truthy(msgs[#msgs]:find("usage: ", 1, true), "it prints the usage line, as any unknown word does")
    t.truthy(msgs[#msgs]:find("/pc debug [on | off | diagnostics]", 1, true),
        "and the usage line names the diagnostics word: " .. tostring(msgs[#msgs]))
end)

-- ── the descriptor ──────────────────────────────────────────────────────────

test("diagnostics: the markers carry the plain-text brand and the host sections run", function()
    local i = realOriginals(ctx.loadAddon())
    local lines, built = report(i)
    t.eq(lines[1], "[Diag] ==== Ka0s Pretty Chat diagnostics begin ====", "the begin marker")
    t.truthy(lines[#lines]:find("==== Ka0s Pretty Chat diagnostics end: " .. #lines .. " line(s) ====",
        1, true), "the end marker counts every line: " .. tostring(lines[#lines]))
    t.eq(built.capped, false, "a default install's report is not capped")
    t.eq(count(lines, "failed:"), 0, "no section raised: " .. table.concat(lines, "\n"))
    for _, needle in ipairs({ "state: enabled(stored)=", "schema: stored=", "combat watcher:",
                              "changed rows:", "live globals:", "snapshot:", "patch drift:",
                              "render check:", "would apply=", "pending reset:", "ui:",
                              "chat addons loaded:" }) do
        t.truthy(find(lines, needle), "the report carries `" .. needle .. "`")
    end
    t.truthy(#lines <= 300, "and stays inside DX-PC's size estimate: " .. #lines)
end)

-- ── the content ─────────────────────────────────────────────────────────────

test("diagnostics: General.enabled and General.visibility always print, even at their defaults", function()
    local i = ctx.loadAddon()
    local lines = report(i)
    t.truthy(find(lines, "[Set] General.enabled = true (true)"), "General.enabled at its default")
    t.truthy(find(lines, "[Set] General.visibility = always (always)"),
        "General.visibility at its default")
    t.falsy(find(lines, "Loot.enabled ="), "a row at its default is not printed")
end)

test("diagnostics: a format override prints with its escapes doubled, never stripped", function()
    -- DX-PC's Never: a format string's color codes ARE the evidence, so the report renders
    -- them with `|` doubled (out:escape), which pastes back into /pc set unchanged. The
    -- library strips every escape it sees, so a value handed over raw would lose its colors.
    local i = ctx.loadAddon()
    local name, default = aLootString(i)
    local value = "|cff00ff00Mine|r " .. default
    local path = "Loot." .. name .. ".format"
    i.NS.Schema.Set(path, value)
    t.eq(i.NS.Schema.Get(path), value, "the override was stored")
    local _, line = find(report(i), "[Set] " .. path .. " = ")
    t.truthy(line, "the override is printed")
    t.truthy(line:find("||cff00ff00Mine||r ", 1, true), "with its escapes doubled: " .. tostring(line))
    t.falsy(line:find("[^|]|c"), "and not one live color escape left in it")
end)

test("diagnostics: a disabled category and a disabled string are named", function()
    local i = ctx.loadAddon()
    local name = aLootString(i)
    i.NS.Schema.Set("Money.enabled", false)
    i.NS.Schema.Set("Loot." .. name .. ".enabled", false)
    local lines = report(i)
    local _, cats = find(lines, "disabled categories:")
    t.truthy(cats and cats:find("Money", 1, true), "Money is listed: " .. tostring(cats))
    local _, strs = find(lines, "disabled strings:")
    t.truthy(strs and strs:find("Loot=1", 1, true), "Loot's one disabled string is counted: "
        .. tostring(strs))
end)

test("diagnostics: the live-global audit names a global that is not what the addon wrote", function()
    local i = ctx.loadAddon()
    local name = aLootString(i)
    local lines = report(i)
    t.truthy(find(lines, "mismatch=0"), "a fresh install's globals all match")
    i.env[name] = "tampered by another addon"
    lines = report(i)
    t.truthy(find(lines, "mismatch=1"), "one global differs from what ApplyStrings would write")
    local _, list = find(lines, "mismatching globals:")
    t.truthy(list and list:find(name, 1, true), "and it is named: " .. tostring(list))
end)

test("diagnostics: patch drift lists a client original whose conversions no longer match", function()
    local i = realOriginals(ctx.loadAddon())
    local name = aLootString(i)
    t.truthy(find(report(i), "patch drift: 0"), "originals that match their defaults do not drift")
    i.addon.originalStrings[name] = "%d %d %d %d %d %d"
    local lines = report(i)
    t.truthy(find(lines, "patch drift: "), "the drift line is there")
    local _, line = find(lines, name .. " default=")
    t.truthy(line, "the drifted global is listed with both signatures: " .. table.concat(lines, "\n"))
end)

test("diagnostics: the render check reports a live global string.format cannot render", function()
    local i = ctx.loadAddon()
    local name = aLootString(i)
    i.env[name] = "broken %z"
    local lines = report(i)
    local _, line = find(lines, "render check:")
    t.truthy(line and line:find("failed=1", 1, true), "one live global fails to render: " .. tostring(line))
    t.truthy(find(lines, name .. ":"), "and it is named with its error")
end)

test("diagnostics: would-apply and would-restore match what ApplyStrings then does", function()
    local i = ctx.loadAddon()
    i.NS.Schema.Set("Money.enabled", false)
    local _, line = find(report(i), "would apply=")
    local applied, restored = i.addon:ApplyStrings()
    t.truthy(line and line:find(("would apply=%d restore=%d"):format(applied, restored), 1, true),
        ("the counts agree with ApplyStrings (%d, %d): %s"):format(applied, restored, tostring(line)))
end)

test("diagnostics: stood down, every section still runs and the header says so", function()
    -- STD-05: the report reads state only, so it runs whole while the addon is disabled.
    local i = ctx.loadAddon()
    i.NS.Schema.Set(ENABLED_PATH, false)
    local lines = report(i)
    t.eq(count(lines, "failed:"), 0, "no section raised")
    t.truthy(find(lines, "state: enabled(stored)=false stoodDown=true holds=disabled"),
        "the state line reads disabled and stood down: " .. table.concat(lines, "\n"))
    t.truthy(find(lines, "would apply=0"), "and nothing would be applied")
    t.truthy(find(lines, "stood down"), "the combat watcher says it is stood down")
end)

test("diagnostics: a known chat-rewriting addon that is loaded is named", function()
    local i = ctx.loadAddon()
    i.env.C_AddOns.IsAddOnLoaded = function(name) return name == "Prat-3.0" end
    local _, line = find(report(i), "chat addons loaded:")
    t.truthy(line and line:find("Prat-3.0", 1, true), "Prat-3.0 is listed: " .. tostring(line))
end)

test("diagnostics: a pending profile reset is reported", function()
    local i = ctx.loadAddon()
    t.truthy(find(report(i), "pending reset: none"), "none outside a reset")
    i.addon.pendingReset = { rows = 3, logged = false }
    t.truthy(find(report(i), "pending reset: rows=3 logged=false"), "and the parked count inside one")
end)

-- ── the report's own guarantees (STD-12, STD-15, STD-05) ────────────────────

test("diagnostics: a raising section costs exactly one line and the report still ends", function()
    local i = ctx.loadAddon()
    i.NS.Schema.CountChangedRows = function() error("count exploded") end
    local lines = report(i)
    local failed = count(lines, "failed:")
    t.eq(failed, 1, "exactly one `section <name> failed` line: " .. table.concat(lines, "\n"))
    t.truthy(find(lines, "section settings failed:"), "it names the section")
    t.truthy(find(lines, "count exploded"), "and carries the error")
    t.truthy(find(lines, "live globals:"), "and the sections after it still ran")
    t.truthy(lines[#lines]:find("diagnostics end:", 1, true), "the end marker still closes it")
end)

test("diagnostics: an over-cap report ends in the truncated line, then the end marker", function()
    local i = ctx.loadAddon()
    local lines, built = report(i, { maxLines = 10 })
    t.eq(#lines, 10, "the cap holds")
    t.truthy(built.capped, "and the report says it was capped")
    t.truthy(lines[#lines - 1]:find("truncated: ", 1, true), "the truncated line comes second to last")
    t.truthy(lines[#lines]:find("diagnostics end: 10 line(s)", 1, true), "then the end marker")
end)

test("diagnostics: a secret value in the store or in a global does not raise", function()
    local i = ctx.loadAddon()
    local name = aLootString(i)
    local secret = setmetatable({}, { __concat = function() error("secret") end,
                                      __tostring = function() error("secret") end })
    local cat = i.addon:EnsureCategoryDB("Loot")
    cat.strings = { [name] = secret }
    i.env[name] = secret
    local ok, lines = pcall(report, i)
    t.truthy(ok, "the report did not raise: " .. tostring(lines))
    t.eq(count(lines, "failed:"), 0, "and no section fell over: " .. table.concat(lines, "\n"))
    t.truthy(find(lines, "<secret>"), "the value is printed as the sentinel")
end)

test("diagnostics: the report writes nothing, anywhere, and clears nothing", function()
    -- red under: an ApplyStrings, SyncCombatWatch or Schema.Set call anywhere in
    -- modules/Diagnostics.lua -- each writes a global, a registration or the store, and the
    -- report is a READ (DX-PC's Never list, debug-logging-§14).
    local i = ctx.loadAddon()
    local name = aLootString(i)
    i.NS.Schema.Set("General.visibility", "outOfCombat")
    i.env[name] = "tampered by another addon"
    local D = i.NS.DebugLog
    D:Add("Probe", "trace before the report")
    local writes = #i.env.__svWrites()
    local regs = #i.env.__registrations()
    local clears = 0
    local clear = D.Clear
    D.Clear = function(...) clears = clears + 1 return clear(...) end
    slash(i, "diagnostics")
    t.eq(#i.env.__svWrites(), writes, "no SavedVariables write")
    t.eq(#i.env.__registrations(), regs, "no registration added or removed")
    t.eq(i.env[name], "tampered by another addon", "no global rewritten, not even the wrong one")
    t.eq(clears, 0, "Clear was never called")
    t.truthy(D:FindLine("trace before the report"), "and the trace above the report survives")
end)
