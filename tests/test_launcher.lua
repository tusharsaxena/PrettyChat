-- tests/test_launcher.lua — core/LauncherSetup.lua, the LibKa0s-Launcher-1.0 seam,
-- the composed Minimap button row behind it, and the two reserved verbs that write
-- the addon's own switch.
--
-- WHAT THIS FILE EXISTS TO CATCH is the same class of failure tests/test_mediasetup.lua
-- guards, one step further along. A launcher is four things a green suite cannot
-- otherwise see:
--
--   * an ICON PATH, which is a plain string handed to the client. Name a file that
--     is not there and the button draws NOTHING and raises NOTHING (anti-pattern
--     #82). So the path is compared against the TOC's `## IconTexture` AND against
--     the file on disk;
--   * an INVERSION. The row says SHOWN and LibDBIcon's key says HIDDEN, so exactly
--     one negation stands between a checkbox and the opposite of what it promises;
--   * a RUNG, which for this addon is an ABSENCE. `onClick` not being passed is
--     what makes left-click open the settings panel, and an absence is the one
--     thing a reader cannot tell from a typo;
--   * a ONE-WAY SWITCH. `/pc disable` must not be able to take `/pc enable` away
--     with it.
--
-- THE BROKER LIBRARIES ARE STUBBED, NOT SKIPPED. tests/loader.lua derives its load
-- list from PrettyChat.toc (addon files) and libs/LibKa0s/LibKa0s.xml (the vendored
-- payload), and LibDataBroker-1.1 and LibDBIcon-1.0 are in NEITHER — they are their
-- own TOC entries. So a plain ctx.loadAddon() is already the degraded install, and
-- the wired one is built by registering two fakes into the mock's LibStub BEFORE any
-- source loads, which is what opts.mock is for. The fakes are deliberately tiny:
-- what is under test is this addon's wiring, and the real LibDBIcon would drag in
-- the whole minimap frame for nothing.

local ctx = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local ICON_PATH = "Interface\\AddOns\\PrettyChat\\media\\logos\\prettychat.logo.128.tga"
local MINIMAP_PATH = "global.minimap.shown"
local ENABLED_PATH = "General.enabled"

-- ── the two fakes ───────────────────────────────────────────────────────────
--
-- Registered through the mock's own LibStub:NewLibrary, which is the real one's
-- shape, so the library resolves them exactly as it resolves the vendored LibKa0s
-- modules beside them. Both record what they were asked to do; nothing is asserted
-- about HOW they do it, because that is their repo's business.
local function withBroker(mocks)
    local ldb = mocks.LibStub:NewLibrary("LibDataBroker-1.1", 4)
    ldb.objects = {}
    function ldb:NewDataObject(name, obj)
        -- nil for a name already taken, which is what the real one answers and
        -- what the library's "take the existing object" arm depends on.
        if self.objects[name] then return nil end
        self.objects[name] = obj
        return obj
    end
    function ldb:GetDataObjectByName(name) return self.objects[name] end

    local icons = mocks.LibStub:NewLibrary("LibDBIcon-1.0", 50)
    icons.registrations, icons.acts = {}, {}
    function icons:Register(name, obj, db)
        self.registrations[#self.registrations + 1] = { name = name, obj = obj, db = db }
    end
    function icons:Show(name) self.acts[#self.acts + 1] = "Show:" .. name end
    function icons:Hide(name) self.acts[#self.acts + 1] = "Hide:" .. name end

    mocks.__ldb, mocks.__icons = ldb, icons
end

local function wired() return ctx.loadAddon({ mock = withBroker }) end

-- ── the icon ────────────────────────────────────────────────────────────────

test("Launcher: the broker object's icon IS the file the TOC's IconTexture names", function()
    -- launcher-§4: one file is the addon's face in three places — the AddOns list,
    -- the minimap button and a broker display's row. Two spellings of it is a
    -- player seeing two addons.
    local inst = wired()
    local object = inst.NS.Launcher:Object()
    t.truthy(object, "the broker object was built")
    t.eq(object.icon, ICON_PATH, "the LDB object wears the addon's own logo")

    local fh = io.open(ctx.root .. "/PrettyChat.toc", "r")
    local toc = fh:read("*a")
    fh:close()
    local declared = toc:match("##%s*IconTexture:%s*([^\r\n]+)")
    t.eq(declared, ICON_PATH, "and the TOC names the same path, character for character")
end)

test("Launcher: that file is on disk, 128x128 uncompressed 32-bit TGA", function()
    -- layout-§4's format rules, read from the header rather than trusted. An RLE
    -- (type 10) or 24-bit file loads as nothing, silently, in the client only —
    -- which is the half of anti-pattern #82 no gate would otherwise report.
    local fh = io.open(ctx.root .. "/media/logos/prettychat.logo.128.tga", "rb")
    t.truthy(fh, "media/logos/prettychat.logo.128.tga exists")
    local header = fh:read(18)
    local size = fh:seek("end")
    fh:close()
    t.eq(#header, 18, "and carries a whole TGA header")
    t.eq(header:byte(3), 2, "image type 2 — uncompressed true-color, not RLE")
    t.eq(header:byte(17), 32, "32 bits per pixel — the alpha channel is the point")
    t.eq(header:byte(13) + header:byte(14) * 256, 128, "128 wide")
    t.eq(header:byte(15) + header:byte(16) * 256, 128, "128 tall, and power-of-two")
    t.eq(size, 18 + 128 * 128 * 4 + 26, "header + raw pixels + footer, with nothing compressed")
end)

-- ── the label ───────────────────────────────────────────────────────────────

test("Launcher: the broker label is the BRAND NAME in plain text, not the Title", function()
    -- launcher-§1. `label` is what a broker display prints in its own row, beside
    -- the other ten, so it is the one field that decides whether the collection
    -- reads as one collection or as eleven unrelated addons. The rule is
    -- `Ka0s <Name>` — and this addon is the case the "not the TOC Title" half of
    -- it was written for, because PrettyChat's Title is a wall of color escapes.
    local inst = wired()
    local object = inst.NS.Launcher:Object()
    t.eq(object.label, "Ka0s Pretty Chat", "the brand name, spelled as the collection spells it")
    t.falsy(object.label:find("|", 1, true),
        "and carrying no escape sequence of any kind — a display draws this string raw")

    local fh = io.open(ctx.root .. "/PrettyChat.toc", "r")
    local toc = fh:read("*a")
    fh:close()
    local title = toc:match("##%s*Title:%s*([^\r\n]+)")
    t.truthy(title:find("|cff", 1, true), "the TOC Title really is color-escaped (toc-file-§1)")
    t.neq(object.label, title, "so the two fields are not wired to each other")
    t.neq(object.label, "PrettyChat", "nor is it the folder name — that is `name`, the position key")
    t.eq(inst.mocks.__ldb.objects.PrettyChat.label, object.label,
        "and the broker object a display reads carries that same one string")
end)

-- ── registration ────────────────────────────────────────────────────────────

test("Launcher: OnEnable registers the one object, under the FOLDER name", function()
    -- The name is not cosmetic: LibDBIcon keys the button's SAVED POSITION by it,
    -- so a second spelling drops the angle the player dragged the button to.
    local inst = wired()
    t.truthy(inst.NS.Launcher:IsRegistered(), "both halves are wired after OnEnable")

    local regs = inst.mocks.__icons.registrations
    t.eq(#regs, 1, "exactly one LibDBIcon registration")
    t.eq(regs[1].name, "PrettyChat", "under the folder name, not the branded Title")
    t.eq(inst.mocks.__ldb.objects.PrettyChat, regs[1].obj,
        "and LibDBIcon holds the SAME object LibDataBroker does — one object, registered twice")
    t.eq(regs[1].obj.type, "launcher",
        "typed `launcher`, so a broker display draws a button rather than an empty value cell")
end)

test("Launcher: LibDBIcon is handed db.global.minimap ITSELF, not a copy", function()
    -- launcher-§3. LibDBIcon writes `minimapPos` into this table when the player
    -- drags the button and `hide` when they use its own menu; a copy here would be
    -- two records of one state, free to disagree the first time either was used.
    local inst = wired()
    local handed = inst.mocks.__icons.registrations[1].db
    t.eq(handed, inst.addon.db.global.minimap, "the stored table, by identity")

    -- And it is GLOBAL rather than profile: a profile switch must not move a
    -- player's buttons, and options-ui-§12's reset must not un-hide one.
    t.nilv(inst.addon.db.profile.minimap, "nothing is stored under the profile")
end)

test("Launcher: Register is idempotent — a second call builds no second button", function()
    -- A host may call it from OnInitialize and again from a login handler. A
    -- second LibDBIcon:Register on a name it already holds would draw a button
    -- over the first, and the two would drift apart on the next drag.
    local inst = wired()
    t.eq(#inst.mocks.__icons.registrations, 1, "one registration after OnEnable")
    t.truthy(inst.NS.Launcher:Register(), "a second Register reports success")
    t.truthy(inst.NS.Launcher:Register(), "and a third")
    t.eq(#inst.mocks.__icons.registrations, 1, "and still one registration")
end)

-- ── the rung ────────────────────────────────────────────────────────────────

test("Launcher: RUNG (c) — left-click opens the settings panel, through the gated path",
function()
    -- The standard's ADDONS.md puts Ka0s Pretty Chat on rung (c), and the rung is
    -- expressed by the ABSENCE of `onClick`: this addon has no primary window and,
    -- being frameless, no preview switch either. What is pinned is that the click
    -- reaches NS.Helpers.OpenOptionsPanel — LibKa0s-Options-1.0's own open, where
    -- options-ui-§2 puts the combat gate — rather than some second open path built
    -- beside it.
    local inst = wired()
    local opened = 0
    inst.NS.Helpers.OpenOptionsPanel = function() opened = opened + 1 end

    local object = inst.NS.Launcher:Object()
    object.OnClick({}, "LeftButton")
    t.eq(opened, 1, "left-click opened the panel")
end)

test("Launcher: RIGHT-click opens the settings panel too, as it does on every rung", function()
    local inst = wired()
    local opened = 0
    inst.NS.Helpers.OpenOptionsPanel = function() opened = opened + 1 end

    local object = inst.NS.Launcher:Object()
    object.OnClick({}, "RightButton")
    t.eq(opened, 1, "right-click opened the panel")
    object.OnClick({}, "MiddleButton")
    t.eq(opened, 2, "and so does any other button — only LEFT is the rung's to spend")
end)

test("Launcher: no toggle hides behind the left button — there is no state to flip", function()
    -- The rung is an absence, and an absence is the one thing a reader cannot tell
    -- from a typo. If a later change hands the descriptor an `onClick`, this case
    -- is what says so: nothing about the addon's stored state may move on a click.
    local inst = wired()
    inst.NS.Helpers.OpenOptionsPanel = function() end
    local before = inst.addon:IsAddonEnabled()

    inst.NS.Launcher:Object().OnClick({}, "LeftButton")
    t.eq(inst.addon:IsAddonEnabled(), before, "the master switch did not move")
    t.eq(inst.NS.Launcher:IsShown(), true, "and neither did the button's own visibility")
end)

-- ── the status tooltip (Launcher minor 3, launcher-§1 as of v2.66.0) ────────
--
-- The library draws the whole tooltip; this addon only answers its questions. So
-- what is pinned here is the DESCRIPTOR, read back through the one place a player
-- sees it: `version` answers the TOC's own `## Version`, `isEnabled` answers the
-- master switch on every show, and `isLocked` / `isTestMode` / `leftClickLabel` /
-- `onTooltipShow` are ABSENT. A frameless rung-(c) addon has no lock, no test mode
-- and no line of its own to add, and a label on rung (c) is one the library ignores.
-- An absent field is pinned by the line it would have drawn not being there.

--- A fake GameTooltip: records AddLine and nothing else, which is all the library
--- draws with. Color escapes are stripped so a case reads the words a player reads;
--- the raw lines come back second for the one case that looks at the color.
local function hover(inst)
    local tt = { lines = {} }
    function tt:AddLine(line) self.lines[#self.lines + 1] = line end
    inst.NS.Launcher:Object().OnTooltipShow(tt)
    local plain = {}
    for n, line in ipairs(tt.lines) do
        plain[n] = (line:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
    end
    return plain, tt.lines
end

local function tocVersion()
    local fh = io.open(ctx.root .. "/PrettyChat.toc", "r")
    local toc = fh:read("*a")
    fh:close()
    return toc:match("##%s*Version:%s*([^\r\n]+)")
end

local function block(lines) return table.concat(lines, "\n") end

test("Launcher tooltip: the library draws it — brand, TOC version, status, the rung-(c) hints",
function()
    local inst = wired()
    local version = tocVersion()
    t.truthy(version and version ~= "", "the TOC declares a version")
    t.eq(block(hover(inst)), block({
        "Ka0s Pretty Chat  v" .. version,
        "Enabled: Yes",
        "Left-click: Open settings",
        "Right-click: Open settings",
    }), "exactly four lines: no Locked, no Test mode, no line of the addon's own")
end)

test("Launcher tooltip: the version is the TOC's metadata, never a hand-typed copy", function()
    -- NS.Version() reads `## Version` through LibKa0s-Env; the tooltip must say
    -- what `/pc version` says, so a bump that edits the TOC moves both.
    local inst = wired()
    local title = hover(inst)[1]
    t.eq(title, "Ka0s Pretty Chat  v" .. inst.NS.Version(),
        "the title carries the same version /pc version prints")
    t.falsy(title:find("vv", 1, true), "and a leading v is not doubled")
end)

test("Launcher tooltip: Enabled is green Yes, and red No while disabled — shown either way",
function()
    local inst = wired()
    local _, raw = hover(inst)
    t.truthy(raw[2]:find("|cff%x%x%x%x%x%xYes|r") or raw[2]:find("|cFF%x%x%x%x%x%xYes|r"),
        "Enabled answers a colored Yes on a fresh install: " .. raw[2])

    inst.NS.Schema.Set(ENABLED_PATH, false)
    local lines, rawOff = hover(inst)
    t.eq(block(lines), block({
        "Ka0s Pretty Chat  v" .. tocVersion(),
        "Enabled: No",
        "Left-click: Open settings",
        "Right-click: Open settings",
    }), "the tooltip is still drawn while disabled, and says so")
    t.neq(rawOff[2]:match("|c%x%x%x%x%x%x%x%x"), raw[2]:match("|c%x%x%x%x%x%x%x%x"),
        "and No wears a different color from Yes")
    t.falsy(lines[3]:find("disabled", 1, true),
        "rung (c) is never gated, so its hint does not become the refusal pointer")
end)

test("Launcher tooltip: the status is read on every show, never cached", function()
    local inst = wired()
    t.eq(hover(inst)[2], "Enabled: Yes")
    inst.addon:OnSlashCommand("disable")
    t.eq(hover(inst)[2], "Enabled: No", "the same object reads the switch the verb just wrote")
    inst.addon:OnSlashCommand("enable")
    t.eq(hover(inst)[2], "Enabled: Yes", "and reads it back the moment it flips again")
end)

test("Launcher tooltip: passing isEnabled does NOT gate the rung-(c) left click", function()
    -- isEnabled is on the descriptor for the tooltip's sake. The library gates the
    -- left click only where `onClick` is present, so this addon's left click keeps
    -- opening the panel while disabled (launcher-§2's rung-(c) carve-out).
    local inst = wired()
    local opened = 0
    inst.NS.Helpers.OpenOptionsPanel = function() opened = opened + 1 end
    inst.NS.Schema.Set(ENABLED_PATH, false)
    inst.env.__resetPrinted()
    inst.NS.Launcher:Object().OnClick({}, "LeftButton")
    t.eq(opened, 1, "a disabled addon's left click still opens the settings panel")
    local refusal = inst.NS.SlashCommands:DisabledLine()
    for _, line in ipairs(inst.env.__printed()) do
        t.falsy(line:find(refusal, 1, true), "and prints no refusal line")
    end
end)

-- ── the Minimap button row ──────────────────────────────────────────────────

test("Launcher: the Minimap button row is composed, stored, and defaults to SHOWN", function()
    -- options-ui-§15/§16: the Master-controls set is the composer's, never
    -- hand-written. What this addon declares is the PATH; the label, the tooltip
    -- and the position are LibKa0s-Options-1.0's own.
    local inst = wired()
    local row = inst.NS.Schema.FindByPath(MINIMAP_PATH)
    t.truthy(row, "the row exists at the verbatim global path")
    t.eq(row.type, "bool")
    t.eq(row.default, true, "SHOWN by default — the row's sense, not LibDBIcon's")
    t.falsy(row.sessionOnly, "STORED: a hidden button is furniture, not session state")
    t.eq(row.category, "General", "wired onto the virtual General category")
    t.eq(row.label, "Minimap button", "and labeled by the composer")
end)

test("Launcher: the row's get/set INVERT onto LibDBIcon's hide key", function()
    -- The whole cost of storing the library's own key, and the one negation
    -- between a checkbox and the opposite of what it promises.
    local inst = wired()
    local Schema, db = inst.NS.Schema, inst.addon.db

    t.eq(db.global.minimap.hide, false, "the declared default is not hidden")
    t.eq(Schema.Get(MINIMAP_PATH), true, "so the row reads SHOWN")

    Schema.Set(MINIMAP_PATH, false)
    t.eq(db.global.minimap.hide, true, "unticking the box STORES hide = true")
    t.eq(Schema.Get(MINIMAP_PATH), false, "and the row reads back false")

    Schema.Set(MINIMAP_PATH, true)
    t.eq(db.global.minimap.hide, false, "and ticking it again clears hide")
    t.eq(Schema.Get(MINIMAP_PATH), true)
end)

-- WS-06: the settings PATH names the row's sense, SHOWN; the stored key stays
-- LibDBIcon's own `hide` (launcher-§3, anti-pattern #81). No SavedVariables change,
-- no migration: only the CLI name moved.
local function lastLine(inst)
    local msgs = inst.env.DEFAULT_CHAT_FRAME.messages
    return msgs[#msgs] or ""
end

test("Launcher: /pc get global.minimap.shown answers true on a fresh install, and "
    .. "/pc set global.minimap.shown false stores hide = true", function()
    local inst = wired()
    local addon, db = inst.addon, inst.addon.db

    addon:OnSlashCommand("get " .. MINIMAP_PATH)
    t.truthy(lastLine(inst):find("global.minimap.shown|r = |cFFFFFFFFtrue", 1, true),
        "a fresh install reads SHOWN")

    addon:OnSlashCommand("set " .. MINIMAP_PATH .. " false")
    t.eq(db.global.minimap.hide, true, "the set lands on LibDBIcon's own hide key")
    t.nilv(db.sv.global.minimap.shown, "and no `shown` key is ever stored")
end)

test("Launcher: global.minimap.hide is no longer a settings path", function()
    local inst = wired()
    t.nilv(inst.NS.Schema.FindByPath("global.minimap.hide"),
        "the old CLI name answers unknown setting")
    inst.addon:OnSlashCommand("get global.minimap.hide")
    t.truthy(lastLine(inst):find("Setting not found: global.minimap.hide", 1, true),
        "and /pc get says so")
end)

test("Launcher: a LEGACY store keeps its choice under the renamed path", function()
    -- A player who hid the button before WS-06: the stored table is exactly what
    -- LibDBIcon wrote, and nothing migrates it.
    local inst = wired()
    local addon, db = inst.addon, inst.addon.db
    local acts = inst.mocks.__icons.acts
    local m = db.global.minimap
    m.hide, m.minimapPos = true, 200

    addon:OnSlashCommand("get " .. MINIMAP_PATH)
    t.truthy(lastLine(inst):find("global.minimap.shown|r = |cFFFFFFFFfalse", 1, true),
        "the legacy hide = true reads as shown = false")

    addon:OnSlashCommand("set " .. MINIMAP_PATH .. " false")
    t.eq(acts[#acts], "Hide:PrettyChat", "the button stays hidden")
    t.eq(db.global.minimap.hide, true, "hide is still true")
    t.eq(db.global.minimap.minimapPos, 200, "minimapPos is untouched")
    t.nilv(db.sv.global.minimap.shown, "and no `shown` key reached the raw SV")

    addon:OnSlashCommand("set " .. MINIMAP_PATH .. " true")
    t.eq(db.sv.global.minimap.hide, false, "showing it writes hide = false")
    t.nilv(db.sv.global.minimap.shown, "still no `shown` key")
    t.eq(db.global.minimap.minimapPos, 200, "and minimapPos still untouched")
end)

test("Launcher: the write moves the BUTTON, not just the store", function()
    -- launcher-§3: the button follows the checkbox immediately rather than at the
    -- next reload.
    local inst = wired()
    local acts = inst.mocks.__icons.acts

    inst.NS.Schema.Set(MINIMAP_PATH, false)
    t.eq(acts[#acts], "Hide:PrettyChat", "unticking hid the button")
    inst.NS.Schema.Set(MINIMAP_PATH, true)
    t.eq(acts[#acts], "Show:PrettyChat", "ticking showed it again")
end)

test("Launcher: the write is a LEAF write — minimapPos survives a toggle", function()
    -- architecture-§5. LibDBIcon keeps the angle the player dragged the button to
    -- in this same table, so a whole-section `minimap = { hide = ... }` write would
    -- throw it away every time the box was ticked.
    local inst = wired()
    inst.addon.db.global.minimap.minimapPos = 217.5

    inst.NS.Schema.Set(MINIMAP_PATH, false)
    inst.NS.Schema.Set(MINIMAP_PATH, true)
    t.eq(inst.addon.db.global.minimap.minimapPos, 217.5, "the dragged angle is untouched")
end)

test("Launcher: the row is the FOURTH of the composed block, after the console", function()
    -- options-ui-§15's canonical order, and the line it opens. Pinned here as well
    -- as in tests/test_schema.lua because THIS is the file that would be read after
    -- a composer minor moved it.
    local inst = wired()
    local rows = inst.NS.Schema.RowsByCategory("General")
    t.eq(rows[#rows].path, MINIMAP_PATH, "last, because there is no Test mode beside it")
    t.eq(rows[#rows].group, "Master controls", "on the Master controls tab")
end)

-- ── surviving a reset (launcher-§3) ─────────────────────────────────────────
--
-- The rule is a PROPERTY, not a consequence of where the table is stored: a
-- player's minimap-button choice is a per-installation display preference, in the
-- same class as the angle they dragged the button to, and NEITHER
-- options-ui-§12's `Reset all settings` NOR a page-scoped Defaults button may
-- un-hide a hidden button or re-hide a shown one.
--
-- Two shapes of addon are genuinely reached by that and this one is neither, so
-- what these cases exist to do is keep it that way. PrettyChat has a real
-- `profile` section, so its global reset -- db:ResetProfile() -- cannot see a
-- table in db.global; its General page's Defaults button is that same profile
-- reset behind the same confirmation (options-ui-§12), and the Categories page's
-- button resets the MESSAGE categories. But the minimap row carries
-- `category = "General"` and a `default`, which is exactly the shape a page walk
-- rewrites, so both of those are one edit away from being false and neither edit
-- would look wrong. These drive the real resets and read the store.

local function hidden(inst)
    inst.NS.Schema.Set(MINIMAP_PATH, false)
    t.eq(inst.addon.db.global.minimap.hide, true, "the button starts hidden")
end

test("Launcher: `Reset all settings` does not un-hide the button", function()
    -- The options-ui-§12 reset, by the path the popup and `/pc resetall` both
    -- take: PrettyChat:ResetAll -> db:ResetProfile().
    local inst = wired()
    local Schema, db = inst.NS.Schema, inst.addon.db
    hidden(inst)
    db.global.minimap.minimapPos = 217.5
    Schema.Set("General.visibility", "never")

    inst.addon:ResetAll()

    t.eq(Schema.Get("General.visibility"), "always",
        "the reset really ran -- a profile row went back to its default")
    t.eq(db.global.minimap.hide, true, "and the button is STILL hidden")
    t.eq(Schema.Get(MINIMAP_PATH), false, "so the checkbox still reads unticked")
    t.eq(db.global.minimap.minimapPos, 217.5, "and the dragged angle survived beside it")
end)

test("Launcher: `/pc resetall` counts the rows it rewrote, and not the minimap row",
function()
    -- The ledger half of the same property. The count is parked before the wipe
    -- and every stored row that differs is in it, the minimap row included -- so a
    -- line reporting the parked figure said the reset rewrote a row it cannot
    -- reach. It reads the difference instead.
    local inst = wired()
    local Schema, D = inst.NS.Schema, inst.NS.DebugLog
    hidden(inst)
    Schema.Set("General.visibility", "never")
    D:SetEnabled(true)

    local from = #D.buffer
    inst.addon:OnSlashCommand("resetall")
    local lines = {}
    for i = from + 1, #D.buffer do lines[#lines + 1] = D.buffer[i] end

    t.eq(#lines, 1, "one line for the whole reset")
    t.truthy(lines[1]:find("reset profile 'Default' to defaults (1 rows)", 1, true),
        "counting the one profile row the wipe rewrote, not the two that differed: " .. lines[1])
    t.eq(inst.addon.db.global.minimap.hide, true, "and the button is still hidden")
end)

-- The General page's REAL header Defaults button, driven end to end: its click
-- raises the reset-all popup, and accepting it runs PrettyChat:ResetAll, a profile
-- reset that cannot reach db.global. red under: a General Defaults button bound to
-- a page walk over RowsByCategory("General"), which would rewrite the minimap row.
test("Launcher: a hidden minimap button survives the General page's real Defaults button",
function()
    local inst = wired()
    local Schema, db, env = inst.NS.Schema, inst.addon.db, inst.env
    local panel
    for _, sub in ipairs(env._settings.subcategories) do
        if sub.name == "General" then panel = sub.frame end
    end
    t.truthy(panel and panel.defaultsOnClick, "the General page wires a Defaults click")
    hidden(inst)
    Schema.Set("General.visibility", "never")

    panel.defaultsOnClick()
    t.eq(env._popupsShown[#env._popupsShown], "PRETTYCHAT_RESET_ALL",
        "the click asks first")
    env.StaticPopupDialogs["PRETTYCHAT_RESET_ALL"].OnAccept()

    t.eq(Schema.Get("General.visibility"), "always", "the accepted reset really ran")
    t.eq(db.global.minimap.hide, true, "and the button is STILL hidden")
end)

test("Launcher: no per-category reset reaches the row either", function()
    -- PrettyChat:ResetCategory is the public per-category method. No panel button
    -- calls it any more (the Categories page's resets every message category in one
    -- batch, and General's is the profile reset above), and `/pc` never did, but it
    -- stays public, so every category is driven here, plus the General body itself,
    -- which is the one a widening of its allow-list would reach.
    local inst = wired()
    local Schema, db = inst.NS.Schema, inst.addon.db

    for _, category in ipairs(Schema.CATEGORY_ORDER) do
        hidden(inst)
        inst.addon:ResetCategory(category)
        t.eq(db.global.minimap.hide, true,
            "the Defaults button on " .. category .. " left the button hidden")
    end

    -- And the General body really did reset what it owns, so the sweep above is
    -- not passing over a reset that did nothing.
    hidden(inst)
    Schema.Set("General.visibility", "never")
    inst.addon:ResetCategory("General")
    t.eq(Schema.Get("General.visibility"), "always", "General's own rows went back to default")
    t.eq(db.global.minimap.hide, true, "and the minimap row was not among them")
    t.eq(Schema.Get(MINIMAP_PATH), false)
end)

test("Launcher: a reset does not RE-HIDE a shown button either", function()
    -- The rule is symmetrical, and the asymmetry would be easy to ship: the row's
    -- default is SHOWN, so a reset that reached it would look harmless on a
    -- default install and only bite the player who hid the button.
    local inst = wired()
    local Schema, db = inst.NS.Schema, inst.addon.db
    local acts = inst.mocks.__icons.acts

    t.eq(db.global.minimap.hide, false, "shown to begin with")
    Schema.Set("Loot.enabled", false)
    local before = #acts

    inst.addon:ResetAll()
    inst.addon:ResetCategory("General")

    t.eq(db.global.minimap.hide, false, "still shown")
    t.eq(#acts, before, "and LibDBIcon was never asked to Show or Hide anything")
end)

-- ── the two reserved verbs ──────────────────────────────────────────────────

test("Launcher: /pc enable and /pc disable write the Enable row's own stored path", function()
    -- slash-commands-§2: ALIASES, never a second switch. They hold no state of
    -- their own, so the checkbox and the verbs can never show two answers.
    local inst = wired()
    local addon, Schema = inst.addon, inst.NS.Schema

    addon:OnSlashCommand("disable")
    t.eq(Schema.Get(ENABLED_PATH), false, "/pc disable turned the addon off")
    t.eq(addon:IsAddonEnabled(), false, "and the addon agrees")
    t.eq(addon.db.profile.enabled, false, "through the Enable row's own stored key")

    addon:OnSlashCommand("enable")
    t.eq(Schema.Get(ENABLED_PATH), true, "/pc enable turned it back on")
    t.eq(addon:IsAddonEnabled(), true)
    t.nilv(addon.db.profile.enabled, "and cleared the key, which is how that row stores ON")
end)

test("Launcher: the verbs hold NO state of their own — the long form is the same write",
function()
    local inst = wired()
    local addon = inst.addon

    addon:OnSlashCommand("disable")
    local viaVerb = addon.db.profile.enabled
    addon:OnSlashCommand("set " .. ENABLED_PATH .. " true")
    addon:OnSlashCommand("set " .. ENABLED_PATH .. " false")
    t.eq(addon.db.profile.enabled, viaVerb,
        "/pc set General.enabled false leaves the store exactly where /pc disable did")

    -- No second key anywhere. If either verb ever grew one, this is what would say so.
    t.nilv(rawget(inst.NS, "enabled"), "no NS.enabled local")
    t.nilv(addon.db.profile.addonEnabled, "no second stored key beside the row's")
    t.nilv(addon.db.global.enabled, "and nothing in the global store either")
end)

test("Launcher: the verbs drive the OVERRIDES, because they take the one write seam",
function()
    -- The proof that "same seam" means something: the write runs ApplyStrings, so
    -- the Blizzard globals go back to their originals and come back again.
    local inst = wired()
    local addon, env = inst.addon, inst.env
    local row = inst.NS.Schema.AllRows()
    local name
    for _, r in ipairs(row) do
        if r.kind == "string_format" then name = r.globalName break end
    end
    t.truthy(name, "the schema has at least one format row to watch")

    local overridden = env[name]
    addon:OnSlashCommand("disable")
    t.eq(env[name], "ORIG:" .. name, "disabling restored this client's pristine string")
    addon:OnSlashCommand("enable")
    t.eq(env[name], overridden, "and enabling put the override back")
end)

test("Launcher: THE SWITCH IS NOT ONE-WAY — the dispatcher answers while disabled",
function()
    -- slash-commands-§2. A player who turns the addon off and finds the verb that
    -- turns it back on gone is left with the settings panel they were trying not
    -- to open. `/pc` and `enable` above all MUST survive.
    local inst = wired()
    local addon, env = inst.addon, inst.env
    inst.NS.Helpers.OpenOptionsPanel = function() env.__opened = (env.__opened or 0) + 1 end

    addon:OnSlashCommand("disable")
    t.eq(addon:IsAddonEnabled(), false, "disabled")

    -- The chat command is still registered: OnInitialize registers it
    -- unconditionally and nothing unregisters it. Read from AceConsole's own
    -- registry, which is where the mock keeps it -- it deliberately does not
    -- invent a global SlashCmdList.
    local AceConsole = inst.mocks.LibStub("AceConsole-3.0", true)
    t.truthy(AceConsole.commands["pc"], "/pc is still registered")
    t.truthy(AceConsole.commands["prettychat"], "and so is its alias")

    local before = #env.DEFAULT_CHAT_FRAME.messages
    addon:OnSlashCommand("help")
    t.truthy(#env.DEFAULT_CHAT_FRAME.messages > before, "help still prints")

    addon:OnSlashCommand("")
    t.eq(env.__opened, 1, "a bare /pc still opens the panel")
    addon:OnSlashCommand("version")
    addon:OnSlashCommand("config")
    t.eq(env.__opened, 2, "and so does /pc config")

    addon:OnSlashCommand("enable")
    t.eq(addon:IsAddonEnabled(), true, "and enable turns it back on")
end)

test("Launcher: the launcher is registered while disabled, for the same reason", function()
    -- The button and the dispatcher are SETUP, not features. A disabled addon that
    -- drew no button would take the other way back with it.
    local inst = ctx.loadAddon({
        mock = withBroker,
        -- Nothing here can disable the addon BEFORE OnEnable without reaching into
        -- SavedVariables, so it is disabled after the fact and the registration is
        -- re-asserted: what matters is that nothing tears it down.
    })
    inst.addon:OnSlashCommand("disable")
    t.eq(inst.addon:IsAddonEnabled(), false)
    t.truthy(inst.NS.Launcher:IsRegistered(), "the launcher is still registered")
    t.truthy(inst.NS.Launcher:Register(), "and re-registering is still a no-op success")
end)

-- ── degradation ─────────────────────────────────────────────────────────────

test("Launcher: DEGRADED — no LibDataBroker and no LibDBIcon, and nothing raises", function()
    -- The plain instance: neither broker library is in the TOC list the loader
    -- derives, so this is the install the library resolves both to nil in. It
    -- reports itself absent by name and the addon carries on.
    local inst = ctx.loadAddon()
    t.truthy(inst.NS.Launcher, "the seam still published an instance")
    t.falsy(inst.NS.Launcher:IsRegistered(), "which is honestly not registered")
    t.nilv(inst.NS.Launcher:Object(), "and holds no broker object")
    t.falsy(inst.NS.Launcher:Register(), "a further Register still answers false")

    local said = false
    for _, m in ipairs(inst.env.DEFAULT_CHAT_FRAME.messages) do
        if m:find("LibDataBroker", 1, true) then said = true end
    end
    t.truthy(said, "and it named the missing library rather than going quiet")
end)

test("Launcher: DEGRADED — the row still reads and writes, so the choice is kept", function()
    -- The checkbox reflects what the PLAYER chose rather than reading `true`
    -- because nothing contradicted it, and the choice takes effect the day the
    -- library arrives.
    local inst = ctx.loadAddon()
    local Schema, db = inst.NS.Schema, inst.addon.db

    t.eq(Schema.Get(MINIMAP_PATH), true)
    Schema.Set(MINIMAP_PATH, false)
    t.eq(db.global.minimap.hide, true, "the store took the write with no button to move")
    t.eq(Schema.Get(MINIMAP_PATH), false, "and the row reads it back")
end)

test("Launcher: DEGRADED — LibDataBroker present, LibDBIcon absent: the plugin, no button",
function()
    -- The middle state the library documents, and the one a real install hits: a
    -- broker display still shows the plugin; there is simply no minimap button.
    local inst = ctx.loadAddon({ mock = function(mocks)
        local ldb = mocks.LibStub:NewLibrary("LibDataBroker-1.1", 4)
        ldb.objects = {}
        function ldb:NewDataObject(name, obj) self.objects[name] = obj return obj end
        function ldb:GetDataObjectByName(name) return self.objects[name] end
    end })

    t.falsy(inst.NS.Launcher:IsRegistered(), "not fully wired")
    t.truthy(inst.NS.Launcher:Object(), "but the broker object exists and carries the click")
    t.eq(inst.NS.Launcher:Object().icon, ICON_PATH)

    local opened = 0
    inst.NS.Helpers.OpenOptionsPanel = function() opened = opened + 1 end
    inst.NS.Launcher:Object().OnClick({}, "RightButton")
    t.eq(opened, 1, "and a broker display's row still opens the settings panel")
end)

test("Launcher: DEGRADED — no LibKa0s at all: no launcher, and the row survives", function()
    -- The whole-payload-missing install every Ka0s addon models. There is no stub
    -- for this major and none is needed: the two call sites guard on NS.Launcher,
    -- and the row's get/set read and write the STORE.
    local inst = ctx.loadAddon({ skip = { "libs/LibKa0s/Launcher.lua" } })
    t.nilv(inst.NS.Launcher, "the seam published nothing")

    local Schema = inst.NS.Schema
    t.eq(Schema.Get(MINIMAP_PATH), true, "the row is still there")
    Schema.Set(MINIMAP_PATH, false)
    t.eq(inst.addon.db.global.minimap.hide, true, "and still writes, without raising")

    inst.addon:OnSlashCommand("disable")
    t.eq(inst.addon:IsAddonEnabled(), false, "and /pc disable still works")
    inst.addon:OnSlashCommand("enable")
    t.eq(inst.addon:IsAddonEnabled(), true, "and /pc enable still brings it back")
end)
