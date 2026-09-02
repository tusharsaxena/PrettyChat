-- tests/test_libka0s.lua — the LibKa0s seams.
--
-- Unit coverage for what the library DOES lives in the library's own suite
-- (testing-§8); nothing here re-tests a formatter or a parser. What is pinned
-- here is the wiring this addon owns and nothing else can see:
--
--   * the descriptor is well-formed — the fields we pass are the ones we mean;
--   * every formatter that changed hands still renders the SAME BYTES;
--   * the degraded path, exercised by loading the addon with the library
--     genuinely ABSENT rather than by hand-stubbing the member under test;
--   * the `L` trap, in both halves — a rendered assertion where a module can
--     express it, and a tripwire on the library where it cannot.

local ctx = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local inst = ctx.loadAddon()
local NS   = inst.NS
local env  = inst.env

-- Drive `/pc get <path>` and return the line it emitted, so the format hook is
-- asserted through the real verb rather than by calling the closure directly.
local function joinedGet(path)
    local msgs = inst.env.DEFAULT_CHAT_FRAME.messages
    NS.SlashCommands:OnSlash("get " .. path)
    return msgs[#msgs]
end

local function readFile(rel)
    local fh = io.open(ctx.root .. "/" .. rel, "r")
    if not fh then return nil end
    local body = fh:read("*a")
    fh:close()
    return body
end

-- Every file that hands a descriptor to a LibKa0s module. Listed rather than
-- globbed so a new seam is a deliberate addition to this list, not a silent one.
local SEAM_FILES = {
    "core/CoreSetup.lua",
    "core/MediaSetup.lua",
    "core/DebugLogSetup.lua",
    "settings/OptionsSetup.lua",
    "settings/Slash.lua",
}

-- ── the `L` trap: the matcher, and the matcher's own test ───────────────────
--
-- A descriptor field is not observable after `lib:New` returns, so the only way
-- to pin "we never handed a module the addon-wide locale table" is to read the
-- seam source. The obvious pattern is WRONG in two directions at once:
--
--   L = NS.L                       -- the table itself                       OFFENDER
--   L = NS.L or { ... }            -- NS.L is always truthy, so: the table   OFFENDER
--   L = NS.L and { ... } or nil    -- evaluates to the plain table           fine
--
-- An end-of-line-anchored `L = NS.L` misses the `or` spelling completely, and
-- never looks at the third line at all — which is the LEGITIMATE form, one
-- and/or typo away from being the live trap. So the rule is: flag any `L =`
-- whose value STARTS with the locale table, unless the next token is `and`.

local function localeTableOffenders(source)
    local hits = {}
    for line in (source or ""):gmatch("[^\r\n]+") do
        -- `local L = NS.L` is the file-scope binding every seam needs for its own
        -- `L["…"]` call sites, not a descriptor field. Excluded by SPELLING rather
        -- than by hoping the pattern misses it, and driven in the matcher's own case
        -- below so the exclusion cannot quietly widen into a hole.
        if not line:match("^%s*local%s+L%s*=") then
            local rest = line:match("[,{%s]L%s*=%s*NS%.L(.*)$") or line:match("^L%s*=%s*NS%.L(.*)$")
            -- `NS.L[` / `NS.L.` is an INDEX into the table, not the table, so it is a
            -- value taken from the locale table and is fine.
            if rest and not rest:match("^[%[%.]") and not rest:match("^%s*and%f[%s]") then
                hits[#hits + 1] = line:match("^%s*(.-)%s*$")
            end
        end
    end
    return hits
end

test("the locale-table matcher catches both offending spellings and clears the legal one", function()
    -- A matcher nothing tests can be narrowed back to a single anchored form while
    -- still reporting green, which is exactly how the anchored version got there.
    local offenders = localeTableOffenders(table.concat({
        '    L = NS.L,',
        '    L = NS.L or { LIST_HEADER = "x" },',
        '    L = NS.L and { LIST_HEADER = NS.L["Available settings"] } or nil,',
        '    L = { LIST_HEADER = NS.L["Available settings"] },',
        'local L       = NS.L',
    }, "\n"))
    t.eq(#offenders, 2, "exactly the two offending spellings are flagged")
    t.truthy(offenders[1]:find("L = NS.L,", 1, true), "the bare table is caught")
    t.truthy(offenders[2]:find("or {", 1, true), "the `or` spelling is caught too")
end)

test("no seam file hands a LibKa0s descriptor the addon-wide locale table", function()
    -- NS.L answers EVERY key with the key itself (the standard mandates the
    -- metatable fallback), so a descriptor holding it renders raw SCREAMING_SNAKE
    -- keys in place of English, for every key at once, visible only in game.
    for _, rel in ipairs(SEAM_FILES) do
        local src = readFile(rel)
        t.truthy(src, rel .. " is readable")
        local hits = localeTableOffenders(src)
        t.eq(#hits, 0, ("%s hands no descriptor NS.L (found: %s)")
            :format(rel, table.concat(hits, " | ")))
    end
end)

-- ── LibKa0s-Core-1.0 ───────────────────────────────────────────────────────

test("Core cannot express the L trap — the tripwire that stands in for a rendered case", function()
    -- Core ships no user-visible strings and reads no descriptor `L`, so a rendered
    -- assertion here would be a case that CANNOT FAIL — worse than no case, because
    -- it reads as coverage. This is the tripwire instead: it passes today and goes
    -- red the day Core grows either half, which is the moment a rendered assertion
    -- becomes both possible and necessary.
    local core = env.LibStub("LibKa0s-Core-1.0", true)
    t.truthy(core, "Core registered")
    t.nilv(core.STRINGS, "Core ships no STRINGS table")

    local src = readFile("libs/LibKa0s/Core.lua")
    t.truthy(src, "libs/LibKa0s/Core.lua is readable")
    t.falsy(src:find("STRINGS", 1, true), "Core.lua's source names no STRINGS table")
    t.falsy(src:find("d%.L%f[^%w_]"), "Core.lua reads no descriptor L")
end)

test("the secret-safe pair on NS.Util IS Core's, not a host copy beside it", function()
    -- Identity, not behavior: two implementations that agree today are exactly the
    -- state the extraction exists to end, and only identity can see the difference.
    local core = env.LibStub("LibKa0s-Core-1.0", true)
    t.eq(NS.Util.SafeToString, core.SafeToString, "SafeToString is the library's function")
    t.eq(NS.Util.IsConcatSafe, core.IsConcatSafe, "IsConcatSafe is the library's function")
    t.eq(core.SECRET, "<secret>", "and the sentinel is the one the suite asserts on")
end)

test("the [PC] printer renders the same bytes it did before Core owned it", function()
    -- Const.PREFIX carries its own trailing space, so the descriptor passes sep = "".
    -- Without it every line would render with a double gap after the tag — a change
    -- nobody files a bug about and everybody sees.
    local msgs = env.DEFAULT_CHAT_FRAME.messages
    NS.Print("hello")
    t.eq(msgs[#msgs], NS.PREFIX .. "hello", "prefix, no separator of its own, then the body")
    t.falsy(msgs[#msgs]:find("|r  hello", 1, true), "specifically NOT a double space")

    NS.Print("")
    t.eq(msgs[#msgs], NS.PREFIX, "an empty body still emits the bare tag, as it always did")

    local secret = setmetatable({}, { __concat = function() error("secret") end })
    local ok = pcall(NS.Print, secret)
    t.truthy(ok, "a combat-protected value never reaches the chat frame raw")
    t.eq(msgs[#msgs], NS.PREFIX .. "<secret>", "it renders as the sentinel, in place")
end)

test("the printer is reclaimed from AceConsole's embed, not merely defined", function()
    -- NewAddon(NS, ...) stamps AceConsole's :Print over NS.Print. If core/CoreSetup.lua
    -- ever loads BEFORE core/PrettyChat.lua the embed wins and every line renders
    -- green with a trailing colon and no cyan tag.
    local msgs = env.DEFAULT_CHAT_FRAME.messages
    NS.Print("reclaimed")
    t.falsy(msgs[#msgs]:find("|cff33ff99", 1, true), "no AceConsole green")
    t.falsy(msgs[#msgs]:find("|r:", 1, true), "no AceConsole trailing colon")
    t.truthy(msgs[#msgs]:find("^" .. NS.PREFIX:gsub("([%|%[%]%(%)%.%%%+%-%*%?%^%$])", "%%%1")),
        "the cyan [PC] tag leads the line")
end)

-- ── LibKa0s-DebugLog-1.0 ───────────────────────────────────────────────────

test("the console descriptor seeds the frame globals and the title we mean", function()
    -- The descriptor is not readable after :New returns, so these are the two
    -- things it produced that ARE: the frame names, and the composed title. Both
    -- match what the hand-written console used, which is what makes the swap
    -- invisible to a user's muscle memory and to /framestack.
    NS.DebugLog:Show()
    local win = env._frames.byName["PrettyChatDebugWindow"]
    t.truthy(win, "the console window carries the addon-seeded global name")
    t.eq(win.titleText, "Pretty Chat \226\128\148 Debug",
        "the library composed <title> + its own em-dash Debug suffix")
    NS.DebugLog:ShowCopy()
    t.truthy(env._frames.byName["PrettyChatDebugCopyWindow"], "so does the copy window")
    t.truthy(env._frames.byName["PrettyChatDebugCopyScroll"], "and its named scroll frame")
    NS.DebugLog:Hide()
end)

test("the console renders prose, not its own SCREAMING_SNAKE keys", function()
    -- The `L` trap, rendered half. A resolved string is prose; an unresolved one is
    -- the key, and no English label is SCREAMING_SNAKE_CASE. Read back off the REAL
    -- FontString the library built, not off a value handed to the assertion — a case
    -- that guards on `if label then` passes vacuously when the accessor is missing.
    NS.DebugLog:Show()
    local win = env._frames.byName["PrettyChatDebugWindow"]
    NS.DebugLog:SetEnabled(true)
    local header = win.debugToggle.text
    t.truthy(header, "the header label exists to be read at all")   -- non-vacuity
    t.eq(header, "Debug: ON", "and it is the library's resolved English")
    t.falsy(header:match("^[A-Z][A-Z0-9_]+$"), "not a raw locale key")
    NS.DebugLog:SetEnabled(false)
    t.eq(win.debugToggle.text, "Debug: OFF", "the other arm resolves too")

    t.truthy(win.lineCount.text, "the line counter renders")
    t.falsy(win.lineCount.text:match("^[A-Z][A-Z0-9_]+$"), "not the LINES key")
    t.truthy(win.lineCount.text:find("/ 1500 lines", 1, true), "it is the formatted counter")

    local spec = NS.DebugLog:ConsoleCheckbox()
    t.falsy(spec.label:match("^[A-Z][A-Z0-9_]+$"), "the checkbox label is prose")
    t.falsy(spec.tooltip:match("^[A-Z][A-Z0-9_]+$"), "so is its tooltip")
    t.truthy(spec.tooltip:find("/pc debug", 1, true),
        "and the tooltip names this addon's slash, from the descriptor")
    NS.DebugLog:Hide()
end)

test("the console's two formatters still render the bytes the copy buffer expects", function()
    -- They changed hands; nothing about the rendered line may change with them.
    t.eq(NS.DebugLog.FormatPlain("15:04:43", "Loot", "item x2"), "15:04:43 | [Loot] item x2")
    t.eq(NS.DebugLog.FormatColored("15:04:43", "Loot", "item x2"),
        "|cff6f8faf15:04:43|r || |cffc9a66b[Loot]|r item x2")
    -- And the instance's copy is the lib-level one, not a second implementation.
    local dl = env.LibStub("LibKa0s-DebugLog-1.0", true)
    t.eq(NS.DebugLog.FormatPlain, dl.FormatPlain, "FormatPlain is the library's function")
    t.eq(NS.DebugLog.FormatColored, dl.FormatColored, "FormatColored is the library's function")
end)

test("the console's print and safeToString are call-time forwarders, not captures", function()
    -- debug-logging-§1 makes this a MUST, and it is one of the few rules a
    -- behavioral case genuinely cannot reach here: core/CoreSetup.lua loads BEFORE
    -- this seam, so `print = NS.Print` would capture the already-reclaimed printer
    -- and work perfectly — today. It breaks the day the TOC order moves, which is
    -- exactly the change nobody re-tests. So the guard is on the source, where the
    -- difference is visible.
    local src = readFile("core/DebugLogSetup.lua")
    t.truthy(src, "core/DebugLogSetup.lua is readable")
    t.truthy(src:find("print%s*=%s*function%(line%)%s*NS%.Print%(line%)%s*end"),
        "print is a thin forwarder")
    t.truthy(src:find("safeToString%s*=%s*function%(v%)%s*return NS%.Util%.SafeToString%(v%)%s*end"),
        "safeToString is a thin forwarder")
    t.falsy(src:find("print%s*=%s*NS%.Print%s*,"), "print is not a captured reference")
    t.falsy(src:find("safeToString%s*=%s*NS%.Util%.SafeToString%s*,"),
        "safeToString is not a captured reference either")
end)

test("NS.Debug is the instance's bare sink, bound not wrapped", function()
    -- A wrapper would work and would also be a second place the gate could be
    -- forgotten; debug-logging-§4 requires the bare binding.
    t.eq(NS.Debug, NS.DebugLog.Debug, "NS.Debug IS the instance's Debug")
end)

test("the close button is the library's, told which addon folder is asking", function()
    -- THE ONE SEAM IN core/CoreSetup.lua THAT IS WRAPPED rather than handed over, and
    -- the wrapper takes two arguments and passes three. That asymmetry is the whole
    -- reason it exists: LibKa0s draws this collection's `close` mark once it can build
    -- a texture path, and it cannot work out which addon folder it was vendored into.
    -- Only the addon knows, and only this file has it as its first vararg.
    --
    -- Asserted on the ARGUMENT, never on the appearance. A two-argument passthrough
    -- returns a perfectly good button wearing a multiplication sign: nothing errors,
    -- no suite reddens, and the only witness is someone looking at two Ka0s windows
    -- side by side. That is anti-pattern #64, and it cost a sibling addon a release.
    -- red under: NS.MakeCloseButton = lib.MakeCloseButton, or a two-argument forward.
    local seen
    local lib  = inst.mocks.LibStub("LibKa0s-Core-1.0", true)
    local real = lib.MakeCloseButton
    lib.MakeCloseButton = function(_, _, name) seen = name; return nil end
    NS.MakeCloseButton(inst.mocks.__stubFrame(), function() end)
    lib.MakeCloseButton = real

    t.eq(seen, "PrettyChat",
        "the library was not told which addon folder to build the texture path from")
end)

test("the console descriptor passes the FOLDER name, not just the frame name", function()
    -- Two fields, two questions, one string in this addon: `name` seeds
    -- PrettyChatDebugWindow and friends, `addonName` is what the library builds a
    -- texture path from so its own copy, clear and close draw the collection's art
    -- instead of two words and a multiplication sign. A host where the two diverge
    -- would hand the library a path into nowhere -- which draws nothing and raises
    -- nothing -- so it is passed explicitly rather than inferred from `name`.
    --
    -- Read off the SOURCE because a descriptor field is not observable after
    -- lib:New returns, and with comments stripped so a mention in prose cannot
    -- stand in for the field.
    -- red under: dropping `addonName`, or replacing `name` with it.
    local src = readFile("core/DebugLogSetup.lua")
    t.truthy(src, "core/DebugLogSetup.lua is readable")
    local code = src:gsub("%-%-[^\r\n]*", "")
    t.truthy(code:match("addonName%s*=%s*addonName") ~= nil,
        "the descriptor does not pass addonName, so the console keeps the minor-8 title bar")
    t.truthy(code:match("name%s*=%s*addonName") ~= nil,
        "the descriptor must still pass `name`: it is what seeds the frame globals")
end)

test("with DebugLog absent the console degrades but the flag and the ack survive", function()
    -- Loaded with the library genuinely missing. NS.State.debug is the ADDON's, so
    -- `/pc debug on` must still flip it and still acknowledge; what is lost is the
    -- window, said once (debug-logging-§7).
    local bare = ctx.loadAddon({ skip = { "libs/LibKa0s/Core.lua" } })
    local msgs = bare.env.DEFAULT_CHAT_FRAME.messages
    bare.NS.State.debug = false

    bare.NS.DebugLog:SetEnabled(true)
    t.truthy(bare.NS.State.debug, "the session flag still flips")
    local joined = table.concat(msgs, "\n")
    t.truthy(joined:find("debug logging |cff40ff40ON|r", 1, true), "the color-coded ack still lands")
    t.truthy(joined:find(bare.NS.LIBKA0S_MISSING ..
        ", so the debug console window is unavailable.", 1, true),
        "and the window's absence is explained through the shared cause clause")

    -- ONCE PER ENTRY POINT, not once for the whole seam. `/pc debug on` above has
    -- already spent the enable surface's announce; the WINDOW is a different thing
    -- the stub silently does not do, so the first request for it says so — and only
    -- the first. A single shared token would make every later `/pc debug` a silent
    -- no-op, which is the failure this shape exists to avoid.
    local before = #msgs
    bare.NS.DebugLog:Toggle()
    t.eq(#msgs, before + 1, "the first request for the window explains its absence")
    bare.NS.DebugLog:Show()
    bare.NS.DebugLog:Toggle()
    t.eq(#msgs, before + 1, "and never again after that")

    -- The stub must NOT re-implement the line format (debug-logging-§3/§7).
    t.nilv(bare.NS.DebugLog.FormatPlain, "the stub carries no plain formatter")
    t.nilv(bare.NS.DebugLog.FormatColored, "and no colored one")
    local src = readFile("core/DebugLogSetup.lua")
    t.falsy(src:find("6f8faf", 1, true), "nor the console's color codes anywhere in the seam")
    t.falsy(src:find("c9a66b", 1, true), "either of them")

    -- Every member the addon actually calls has to answer.
    for _, member in ipairs({ "Add", "Debug", "Clear", "Show", "Hide", "Toggle", "IsShown",
                              "IsEnabled", "SetEnabled", "RefreshHeader", "ShowCopy",
                              "UpdateScrollBar", "UpdateStatus", "SessionSummary",
                              "ConsoleCheckbox" }) do
        t.eq(type(bare.NS.DebugLog[member]), "function", "the stub answers " .. member)
    end
    t.eq(type(bare.NS.DebugLog.buffer), "table", "and carries the raw buffer")
end)

-- ── LibKa0s-Options-1.0 ────────────────────────────────────────────────────

test("Options cannot express the L trap either — its own, different tripwire", function()
    -- The Core tripwire's two halves do NOT both transfer here. Options.lua DOES
    -- ship a STRINGS table, so asserting `lib.STRINGS` is absent would fail on a
    -- module that is behaving correctly. What holds is the source half alone: the
    -- module reads no descriptor `L`, so a rendered assertion against a descriptor
    -- override would be a case that cannot fail. It passes today and goes red the
    -- day Options grows one — which is the moment it matters most, because the
    -- settings panel is where a raw SCREAMING_SNAKE key is most visible.
    local opts = env.LibStub("LibKa0s-Options-1.0", true)
    t.truthy(opts, "Options registered")
    t.truthy(type(opts.STRINGS) == "table", "and it DOES ship STRINGS, unlike Core")

    for _, rel in ipairs({ "libs/LibKa0s/Options.lua", "libs/LibKa0s/OptionsWidgets.lua",
                           "libs/LibKa0s/OptionsScroll.lua" }) do
        local src = readFile(rel)
        t.truthy(src, rel .. " is readable")
        t.falsy(src:find("d%.L%f[^%w_]"), rel .. " reads no descriptor L")
    end
end)

test("NS.Helpers IS the library instance, decorated in place", function()
    -- options-ui-§1: never a fresh table that copies members across. A copy-across
    -- gives a page helper added later something the library's own callers do not
    -- see, and gives a suite that swaps a member out to spy on it the wrong one.
    for _, member in ipairs({ "CreatePanel", "EnsureDefaultsButton", "EnsureScroll",
                              "ClearScroll", "AddSpacer", "Section", "AttachTooltip",
                              "InlineButtonPair", "RenderField", "SessionCheckbox",
                              "RenderRows", "RenderSchema", "RenderGrid", "SetRenderer",
                              "RegisterOptionsPage", "CreateOptionsPanel",
                              "OpenOptionsPanel", "RefreshAllPanels", "RefreshScalars",
                              "__panels", "__panelFor" }) do
        t.eq(type(NS.Helpers[member]), "function", "the instance carries " .. member)
    end
    -- Two registered pages, BY KEY and in rail order, rather than a count derived
    -- from CATEGORY_ORDER. The two stopped being the same number when the eight
    -- message categories became eight tabs on one page, and a count alone would
    -- have gone on passing if a page were registered twice under one key.
    local pageKeys = {}
    for i, page in ipairs(NS.Helpers.__pages()) do pageKeys[i] = page.key end
    t.eq(table.concat(pageKeys, ","), "General,Categories", "every page builder ran, in rail order")

    -- The member list above survives a copy-across table intact, so on its own it
    -- asserts nothing the case name claims. THIS is the identity check: swap a
    -- member out on NS.Helpers and see whether the LIBRARY's own caller picks the
    -- swap up. RenderRows resolves RenderField off the instance at call time, so it
    -- does exactly when NS.Helpers is the instance, and does not when it is a copy.
    local realRenderField, seen = NS.Helpers.RenderField, 0
    NS.Helpers.RenderField = function(...) seen = seen + 1; return realRenderField(...) end
    local ok, err = pcall(function()
        local pageCtx = NS.Helpers.__panelFor("Categories")
        NS.Helpers.RenderRows(pageCtx, { NS.Schema.FindByPath("Loot.enabled") })
    end)
    NS.Helpers.RenderField = realRenderField
    t.truthy(ok, "the render ran: " .. tostring(err))
    t.truthy(seen > 0,
        "the library's own RenderRows reached the member we swapped — NS.Helpers IS the instance")
end)

test("every canvas frame carries the Blizzard OnCommit / OnDefault / OnRefresh trio", function()
    -- options-ui-§1 MUST. The Settings window calls all three, and the FOOTER
    -- defaults control is the one that silently does nothing when OnDefault is
    -- missing — while the header Defaults button beside it keeps working and looks
    -- equivalent to the user. This addon shipped without all three before adopting.
    -- rawget, and it is the whole assertion. A mock frame answers EVERY unmodelled
    -- PascalCase key from its metatable with a self-returning function, so a plain
    -- `type(panel.OnCommit) == "function"` is true whether or not the library ever
    -- stamped anything — two of the three assertions here could not fail, on a case
    -- whose own comment claims they are the coverage. The library's own suite uses
    -- rawget for exactly this hazard, and so does this repo's locale drift check.
    for _, pageCtx in ipairs(NS.Helpers.__panels()) do
        local panel = pageCtx.panel
        t.eq(type(rawget(panel, "OnCommit")), "function", "OnCommit is really stamped")
        t.eq(type(rawget(panel, "OnRefresh")), "function", "OnRefresh is really stamped")
        t.eq(type(rawget(panel, "OnDefault")), "function", "OnDefault is really stamped")
    end

    -- And OnDefault FORWARDS rather than being an assignment taken at build time:
    -- every host parks defaultsOnClick after CreatePanel returns.
    -- The Categories page's forwarder resolves the ACTIVE TAB at click time, so the
    -- footer control resets the category the player is looking at. Loot is the first
    -- tab, hence the one a page nobody has clicked is showing.
    local categories = NS.Helpers.__panelFor("Categories")
    NS.Schema.Set("Loot.enabled", false)
    categories.panel.OnDefault()
    t.eq(NS.Schema.Get("Loot.enabled"), NS.Defaults.Loot.enabled,
        "the footer control reaches the same body the header button does")
end)

test("the settings panel refuses to render under combat rather than drawing half a page", function()
    -- The Blizzard AddOns sidebar reaches a panel without going through
    -- OpenOptionsPanel, so its combat guard is bypassed on exactly the path a user
    -- is most likely to take mid-fight. SetRenderer puts a second guard on the
    -- render itself; without adopting SetRenderer this addon had none.
    local fresh = ctx.loadAddon({
        mock = function(m) m.InCombatLockdown = function() return true end end,
    })
    local panel
    for _, sub in ipairs(fresh.env._settings.subcategories) do
        if sub.name == "Categories" then panel = sub.frame end
    end
    panel:Show()

    -- The header Defaults button IS built — EnsureDefaultsButton runs ahead of the
    -- guard, deliberately, so the control exists on a page the user can see. What
    -- must not happen is the BODY: no scroll container, and therefore none of the
    -- ~50 per-string blocks a Loot render would create.
    local pageCtx = fresh.NS.Helpers.__panelFor("Categories")
    t.nilv(pageCtx.scroll, "the page body was never built under lockdown")
    t.nilv(pageCtx.__tabLayout, "and the tab strip was not placed either")
    t.eq(#pageCtx.refreshers, 0, "so nothing registered a refresher either")
    local msgs = fresh.env.DEFAULT_CHAT_FRAME.messages
    t.truthy(msgs[#msgs]:find("cannot open settings during combat", 1, true),
        "and the refusal is surfaced, in the canonical wording")
end)

test("with Options absent the schema still loads whole — the measured stub set", function()
    -- options-ui-§1's degradation rule is LOAD-COMPLETING rather than
    -- member-answering, and the member set it requires MUST be determined by
    -- MEASUREMENT: delete a member, load with the library absent, and compare the
    -- resulting schema row count against a full load. PrettyChat's measured set is
    -- exactly ONE member — MasterControls, which settings/Schema.lua composes the
    -- General page's Master controls block through at load — and these two numbers
    -- agreeing is the only thing standing between that claim and a silent
    -- half-load. Delete the stub's MasterControls and this case goes red by three.
    local full = #NS.Schema.AllRows()
    local bare = ctx.loadAddon({ skip = { "libs/LibKa0s/Core.lua" } })
    t.truthy(full > 100, "the full load really does build a large schema")
    t.eq(#bare.NS.Schema.AllRows(), full,
        "the library-absent load builds exactly the same rows")
    t.eq(bare.NS.Schema.validation.failed, 0, "and every one of them still resolves")

    -- The panel is gone, said once, and the global reset still works without it.
    local msgs = bare.env.DEFAULT_CHAT_FRAME.messages
    t.truthy(table.concat(msgs, "\n"):find(
        bare.NS.LIBKA0S_MISSING .. ", so the settings panel is unavailable.", 1, true),
        "the panel's absence is explained through the shared cause clause")
    bare.NS.Schema.Set("Loot.enabled", false)
    bare.NS.Helpers.RestoreAllDefaults()
    t.eq(bare.NS.Schema.Get("Loot.enabled"), bare.NS.Defaults.Loot.enabled,
        "reset-everything still works with no panel at all (options-ui-§1)")

    -- EVERY lost verb names the missing library (slash-commands-§1) — including the
    -- one the user actually types. CreateOptionsPanel is called automatically from
    -- OnEnable, so a single announce token shared across the seam is always spent
    -- before `/pc config` is ever reached, and the verb is then a silent no-op for
    -- the whole session. Driven through the real verb, after the load-time notice
    -- has already been emitted, because that is the only ordering that fails.
    local before = #msgs
    bare.addon:OnSlashCommand("config")
    t.eq(#msgs, before + 1, "/pc config answers rather than going silently nowhere")
    t.truthy(msgs[#msgs]:find(bare.NS.LIBKA0S_MISSING ..
        ", so the settings panel is unavailable.", 1, true),
        "and it names the missing library through the shared cause clause")
    bare.addon:OnSlashCommand("config")
    t.eq(#msgs, before + 1, "said once for that surface, not on every attempt")

    -- And the stub carries no copy of the library's layout constants or makers.
    local src = readFile("settings/OptionsSetup.lua")
    t.falsy(src:find("0%.492"), "no host copy of BUTTON_PAIR_REL")
    t.falsy(src:find("SetRelativeWidth", 1, true), "no host copy of a widget maker")
end)

-- ── LibKa0s-Slash-1.0 ──────────────────────────────────────────────────────

test("the dispatcher renders prose, not its own SCREAMING_SNAKE keys", function()
    -- The `L` trap, rendered half, on the module whose strings a user sees most.
    local header = NS.SlashCommands:HelpHeader()
    t.truthy(header, "the help header exists to be read at all")   -- non-vacuity
    t.falsy(header:match("^[A-Z][A-Z0-9_]+$"), "it is prose, not HELP_HEADER")
    t.truthy(header:find("slash commands", 1, true), "and it is the library's resolved English")

    local lines = NS.SlashCommands:BuildListLines()
    t.truthy(#lines > 1, "the list renders rows to assert on")
    for _, key in ipairs({ "LIST_HEADER", "LIST_GROUP", "LIST_EMPTY" }) do
        t.falsy(table.concat(lines, "\n"):find(key, 1, true),
            "no raw " .. key .. " reached the listing")
    end
    t.eq(lines[1], "|cff33ff99Available settings|r", "the header is the mandated green string")
end)

test("the COMMANDS table is the positional shape the library reads", function()
    -- A table of NAMED fields is silently invisible to the dispatcher: every verb
    -- becomes unknown and the help block renders empty (slash-commands-§3).
    for i, entry in ipairs(NS.COMMANDS) do
        t.eq(type(entry[1]), "string", ("COMMANDS[%d][1] is the verb"):format(i))
        t.eq(type(entry[2]), "string", ("COMMANDS[%d][2] is the description"):format(i))
        t.eq(type(entry[3]), "function", ("COMMANDS[%d][3] is the handler"):format(i))
        t.nilv(entry.name, ("COMMANDS[%d] carries no named `name` field"):format(i))
    end
end)

test("the format hook doubles pipes without re-implementing the value formatter", function()
    -- Slash minor 5's `format` hook, applied to a row type the library CAN already
    -- render. Everything it does not own falls through to lib.FormatValue, including
    -- the empty-string case, which this addon rendered as nothing before adopting.
    local slashLib = env.LibStub("LibKa0s-Slash-1.0", true)
    local row = NS.Schema.FindByPath("Loot.LOOT_ITEM_SELF.format")
    NS.Schema.Set(row.path, "|cffff0000Red|r %s")
    t.truthy(joinedGet(row.path):find("||cffff0000Red||r %s", 1, true),
        "a stored pipe renders doubled so the escape reads as text")

    NS.Schema.Set(row.path, "")
    t.truthy(joinedGet(row.path):find(slashLib.STRINGS.NONE, 1, true),
        "an empty string renders as the library's (none), per slash-commands-§5")
    NS.Schema.Set(row.path, row.default)

    local boolRow = NS.Schema.FindByPath("General.enabled")
    t.truthy(joinedGet(boolRow.path):find("= |cFFFFFFFFtrue|r", 1, true),
        "and a bool still renders through the library untouched")
end)

test("the parse hook keeps a whole free-text value, spaces and all", function()
    -- The gap it exists for: lib.ParseValue splits the remainder on whitespace and a
    -- string row takes args[1]. Driven through the REAL verb, not the hook directly.
    local row = NS.Schema.FindByPath("Loot.LOOT_ITEM_SELF.format")
    NS.SlashCommands:OnSlash("set " .. row.path .. " You receive loot: %s")
    t.eq(NS.Schema.Get(row.path), "You receive loot: %s", "the whole remainder was stored")
    NS.Schema.Set(row.path, row.default)
end)

test("both convergences are adopted, in bytes", function()
    -- reset takes a PATH (slash-commands-§2), and the landing page renders through
    -- the one row formatter (slash-commands-§4). Both are user-visible removals, so
    -- both are pinned here as well as in their own suites.
    local slashLib = env.LibStub("LibKa0s-Slash-1.0", true)
    t.eq(type(NS.SlashCommands.CliReset), "function",
        "the path-scoped reset is the library's, not a host page-scoped one")
    t.eq(type(NS.SlashCommands.LandingRows), "function", "LandingRows is what the panel renders")
    -- The old page-scoped body is gone from the source, not merely unreachable.
    local src = readFile("settings/Slash.lua")
    t.truthy(src:find("Sl:CliReset(rest)", 1, true), "`reset` delegates to the library's verb")
    t.falsy(src:find("self:ResetCategory", 1, true), "and no page-scoped reset survives beside it")
    local first = NS.COMMANDS[1]
    t.eq(NS.SlashCommands:LandingRows()[1], slashLib.FormatRow("/pc " .. first[1], first[2]),
        "the landing row is the shared formatter, un-indented")
    t.eq(NS.SlashCommands:HelpRows()[1], "  " .. NS.SlashCommands:LandingRows()[1],
        "and the chat row is the same bytes plus two spaces")
end)

test("with Slash absent the host verbs survive and the schema CLI says why", function()
    local bare = ctx.loadAddon({ skip = { "libs/LibKa0s/Core.lua" } })
    local msgs = bare.env.DEFAULT_CHAT_FRAME.messages

    -- A host verb never went to the library, so it still works.
    bare.NS.State.debug = false
    bare.addon:OnSlashCommand("debug on")
    t.truthy(bare.NS.State.debug, "/pc debug on still flips the session flag")

    -- A schema verb names the missing library rather than going quiet.
    local before = #msgs
    bare.addon:OnSlashCommand("list")
    t.truthy(#msgs > before, "/pc list answers")
    t.truthy(msgs[#msgs]:find(bare.NS.LIBKA0S_MISSING ..
        ", so the settings CLI is unavailable.", 1, true),
        "through the shared cause clause")

    -- And the stub re-implements none of the library's rendering.
    local src = readFile("settings/Slash.lua")
    t.falsy(src:find("cFFFFFF00", 1, true), "no copied row/key color codes in the seam")
    t.falsy(src:find("cFFFFFFFF", 1, true), "either of them")
end)

-- ── the degraded install ───────────────────────────────────────────────────

test("with LibKa0s absent the addon still loads and still prints, saying so once", function()
    -- Loaded with the library genuinely missing from the file list, not hand-stubbed
    -- (testing-§8). Skipping Core.lua alone is the honest scenario: every other
    -- module returns before LibStub:NewLibrary when Core is absent, so one missing
    -- file takes the whole library out exactly as a broken vendor would.
    local bare = ctx.loadAddon({ skip = { "libs/LibKa0s/Core.lua" } })
    t.nilv(bare.env.LibStub("LibKa0s-Core-1.0", true), "Core did not register")
    for _, major in ipairs({ "LibKa0s-DebugLog-1.0", "LibKa0s-Slash-1.0",
                             "LibKa0s-Options-1.0", "LibKa0s-Perf-1.0" }) do
        t.nilv(bare.env.LibStub(major, true), major .. " is absent rather than half-wired")
    end

    -- The notice rides the FIRST line the addon prints, whichever that is — on this
    -- load it is settings/OptionsSetup.lua's own "settings panel is unavailable"
    -- line, emitted from OnEnable. So the assertion is on the transcript as a whole:
    -- said exactly once, and said before anything else.
    local msgs = bare.env.DEFAULT_CHAT_FRAME.messages
    local notice = bare.NS.PREFIX .. bare.NS.LIBKA0S_MISSING ..
        "; running on reduced built-in fallbacks."
    local function noticeCount()
        local n = 0
        for _, line in ipairs(msgs) do if line == notice then n = n + 1 end end
        return n
    end
    t.eq(msgs[1], notice,
        "the notice rides the first line printed, in the shared cause clause's wording")
    t.eq(noticeCount(), 1, "and is said exactly once")

    local before = #msgs
    bare.NS.Print("first line")
    bare.NS.Print("second line")
    t.eq(#msgs, before + 2, "later lines are just the lines")
    t.eq(msgs[before + 1], bare.NS.PREFIX .. "first line", "the first one lands verbatim")
    t.eq(msgs[before + 2], bare.NS.PREFIX .. "second line", "and so does the second")
    t.eq(noticeCount(), 1, "the notice is never stapled to another line")
end)

test("the shared cause clause names the addon and where the library should be", function()
    -- A user with a broken install must see the same sentence about WHY from every
    -- Ka0s addon they have open; that is the whole reason the clause is shared.
    t.eq(NS.LIBKA0S_MISSING,
        "The LibKa0s library is missing from this installation of Ka0s Pretty Chat " ..
        "(expected in libs/LibKa0s)",
        "the clause is the collection's wording with this addon's name in it")
    t.falsy(NS.LIBKA0S_MISSING:find("%.$"), "it carries no terminal punctuation of its own")
end)

test("the degraded secret guard still neutralizes a protected value", function()
    local bare = ctx.loadAddon({ skip = { "libs/LibKa0s/Core.lua" } })
    local secret = setmetatable({}, { __concat = function() error("secret") end })
    t.eq(bare.NS.Util.SafeToString(secret), "<secret>", "the fallback answers the same sentinel")
    t.falsy(bare.NS.Util.IsConcatSafe(secret), "and the fallback probe still refuses it")
end)

-- ── stub-surface parity, one case per adopted seam (testing-§8) ────────────
--
-- The degraded arm comes from feeding the loader a PARTIAL FILE LIST — skipping
-- libs/LibKa0s/Core.lua, which takes the whole library out, since every other
-- module returns before LibStub:NewLibrary when Core is absent. Never by
-- hand-stubbing the member under test: that would assert the test's own typing.
--
-- `assertSurfaceParity` walks the LIVE surface and reports every divergence in
-- one message, counting a key that is a function live and something else degraded
-- — the shape `X = lib and lib.X` leaves behind when the library is absent.
--
-- `ignore` carries the live-only members AS DATA, with the reason each one is
-- live-only. Without it an intentional omission and a bug read the same, and the
-- usual resolution for that is to delete the case.

-- BOTH arms are freshly loaded, differing only by the file list, so the two
-- surfaces are read at the same point in their lives. The shared `inst` above is
-- not usable as the live arm: LibKa0s-DebugLog-1.0 attaches `_frameForTest` and
-- `_toggleClickForTest` to its instance when the console frame is first built, so
-- whether that surface carries them depends on which case ran before this one.
local parityLive = ctx.loadAddon()
local parityBare = ctx.loadAddon({ skip = { "libs/LibKa0s/Core.lua" } })

-- LibKa0s-Core-1.0 is the one seam this addon does not keep as an instance: the
-- printer's members are re-published under the addon's own keys (anti-pattern #36
-- reclaim), so the surface is PROJECTED from both paths by the same list.
-- Members from: grep -nE "^\s*(function )?(NS|Util)\.[A-Za-z]+" core/CoreSetup.lua
local function coreSurface(instance)
    return {
        Print        = instance.NS.Print,
        Format       = instance.NS.Format,
        IsConcatSafe = instance.NS.Util.IsConcatSafe,
        SafeToString = instance.NS.Util.SafeToString,
    }
end

test("the Core stub carries the whole live surface", function()
    local live = coreSurface(parityLive)
    -- Non-vacuity: a projection that read nothing would pass parity trivially.
    for _, key in ipairs({ "Print", "Format", "IsConcatSafe", "SafeToString" }) do
        t.eq(type(live[key]), "function", "the live Core seam publishes " .. key)
    end
    ctx.assertSurfaceParity(live, coreSurface(parityBare), "Core stub")
end)

test("the DebugLog stub carries the whole live surface", function()
    -- Members from: grep -E "^  (function D[:.][A-Za-z_]+|D\.[A-Za-z_]+ +=)" libs/LibKa0s/DebugLog.lua
    ctx.assertSurfaceParity(parityLive.NS.DebugLog, parityBare.NS.DebugLog, "DebugLog stub", {
        -- debug-logging-§3/§7: the stub MUST NOT re-implement the line format, so
        -- the two formatters are live-only by rule, not by oversight.
        FormatPlain   = true,
        FormatColored = true,
        -- The library's own string resolver. Nothing in this addon calls it —
        -- `grep -rn "DebugLog[:.]Text" core settings modules` is empty — and a stub
        -- copy would be a second place the library's English could drift.
        Text          = true,
    })
end)

test("the Options stub carries the whole live surface", function()
    -- Members from: grep -E "^  (function O[:.][A-Za-z_]+|O\.[A-Za-z_]+ +=)" libs/LibKa0s/Options.lua
    ctx.assertSurfaceParity(parityLive.NS.Helpers, parityBare.NS.Helpers, "Options stub", {
        -- options-ui-§8: the layout constants MUST NOT be copied into the host, so
        -- the stub omits them deliberately. See settings/OptionsSetup.lua's comment
        -- on the guard that keeps a nil from reaching anything.
        PADDING_X         = true,
        ROW_VSPACER       = true,
        SECTION_HEADING_H = true,
        BUTTON_PAIR_REL   = true,
        -- Minor 13/14 published three more of them (the chrome gap, one tab row's
        -- height, the banner floor) for a host that lays out its own strip. This
        -- addon lays out none: settings/Panel.lua hands H.TabStrip a tab list and
        -- the library places the buttons, so nothing here measures a band and a
        -- stub copy of the numbers would be exactly the stale copy options-ui-§8
        -- forbids. The FUNCTIONS of both minors are in the stub, by name.
        CHROME_GAP        = true,
        TAB_H             = true,
        BANNER_H          = true,
        -- Live-only because nothing in this addon reads them: settings/Panel.lua
        -- resolves AceGUI itself, builds its own landing page and its own rows, and
        -- never asks the library to patch a scrollbar or restore one page's
        -- defaults. `grep -rn "Helpers.\(AceGUI\|BuildLandingPage\|RestoreDefaults\|PatchAlwaysShowScrollbar\)" core settings modules` is empty.
        -- TextRow LEFT this list when the Categories page took it for its footnote.
        AceGUI                   = true,
        BuildLandingPage         = true,
        RestoreDefaults          = true,
        PatchAlwaysShowScrollbar = true,
        -- OptionsCompose 1. Four of the five composers are live-only because this
        -- addon has none of the surfaces they compose: `grep -rn 'type = "color"'
        -- settings defaults` is empty, and so is `grep -rn 'LSM30_' settings` —
        -- the schema is bool and string only, with no swatch, no font picker, no
        -- border and no status bar anywhere in it. MasterControls is the one this
        -- addon does call, and it is NOT here: it is in the stub, doing real work,
        -- because settings/Schema.lua composes the General page through it at
        -- load. The five published CONSTANTS go with the four composers, for the
        -- reason the layout constants above do — a stub copy of the library's
        -- English or of its visibility value table is the copy that goes stale.
        ColorPair                = true,
        FontGroup                = true,
        BorderGroup              = true,
        BarGroup                 = true,
        FONT_FLAGS               = true,
        FONT_FLAGS_SORT          = true,
        VISIBILITY_VALUES        = true,
        VISIBILITY_SORT          = true,
        CLASS_COLOR_NOTE         = true,
        -- Read by settings/Panel.lua, but only inside the General page's builder
        -- and only AFTER the EnsureScroll guard the degraded page returns at, so
        -- it is never reached here. Spelling the literal into the stub would put
        -- the tab's name — which is also the afterGroup hook's key — in two
        -- places, and a rename would then detach the hook silently.
        MASTER_GROUP             = true,
    })
end)

test("the Slash stub carries the whole live surface", function()
    -- Members from: grep -E "^  (function Sl[:.][A-Za-z_]+|Sl\.[A-Za-z_]+ +=)" libs/LibKa0s/Slash.lua
    ctx.assertSurfaceParity(parityLive.NS.SlashCommands, parityBare.NS.SlashCommands, "Slash stub", {
        -- Live-only because the degraded PrintHelp writes its own header inline and
        -- nothing else asks for one: settings/Panel.lua:368 is the addon's only
        -- caller of the help-index surface and it takes LandingRows, on a page that
        -- never builds without the library. The day a degraded caller appears, this
        -- entry is what has to be deleted first.
        HelpHeader = true,
    })
end)
