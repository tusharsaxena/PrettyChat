-- tests/test_profiles.lua — the Profiles page (settings/Profiles.lua) and what a profile
-- switch, copy or reset has to reach.
--
-- Every setting this addon stores lives in db.profile, so a profile act replaces all of it at
-- once. core/PrettyChat.lua's three callbacks share one adopt path (migrations, the latch, the
-- re-apply, one debug line); tests/test_debuglog.lua pins the lines and tests/test_database.lua
-- the load pass. What this suite adds is the page, and the parts of the adopt path the page made
-- newly reachable from the UI:
--
--   * the PAGE: AceDBOptions' own table, over the live db, last in the rail, no Defaults button;
--   * the REDRAW: AceConfigDialog re-reads the profile only when it is fed again, so a profile
--     event redraws the page, and a pipeline refresh does not (it would tear the widget tree
--     down under an open dropdown);
--   * the LATCH: a profile can hold `General.enabled = false`, so a switch stands the addon
--     down or up with no verb and no checkbox touched (slash-commands-§7);
--   * the GLOBAL RESET's blast radius and its veto (options-ui-§3, §12).

local ctx  = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local APP = "PrettyChat-Profiles"

local function lib(inst, name) return inst.env.__libs[name] end

local function profilesFrame(inst)
    local title = inst.NS.L["Profiles"]
    for _, sub in ipairs(inst.env._settings.subcategories) do
        if sub.name == title then return sub.frame end
    end
end

local function opens(inst) return lib(inst, "AceConfigDialog-3.0").__opens end

-- ---------------------------------------------------------------------------
-- The page
-- ---------------------------------------------------------------------------

-- red under: registering the page before General or Categories, or loading its file anywhere
-- but last (options-ui-§3 puts Profiles last in the rail).
test("Profiles: the page is the last in the rail, and its file is the last the TOC loads", function()
    local inst = ctx.loadAddon()
    local subs = inst.env._settings.subcategories
    t.eq(#subs, 3, "General, Categories and Profiles")
    t.eq(subs[#subs].name, inst.NS.L["Profiles"], "Profiles closes the rail")
    local keys = {}
    for i, page in ipairs(inst.NS.Helpers.__pages()) do keys[i] = page.key end
    t.eq(table.concat(keys, ","), "General,Categories,Profiles", "registered after the other two")
    local files = ctx.loadAddon.tocFiles
    t.eq(files[#files], "settings/Profiles.lua", "and its file loads last")
end)

-- red under: building the options table over anything but the live db, or giving the page a
-- Defaults button ("restore defaults" here would mean deleting profiles, options-ui-§3):
-- `defaultsButton = true` in settings/Profiles.lua turns each Defaults assertion red on its own. They read
-- the LIBRARY's own state -- the intent CreatePanel records, and the button EnsureDefaultsButton
-- builds on first show -- because `defaultsOnClick` is set only by a host that wires a click, so
-- a nil there proves nothing about the button.
test("Profiles: the page hosts AceDBOptions' table over the live db, with no Defaults button", function()
    local inst = ctx.loadAddon()
    local reg = lib(inst, "AceConfig-3.0").__registered[APP]
    t.truthy(reg, "the AceDBOptions table is registered under the page's app name")
    t.eq(reg and reg.__db, inst.addon.db, "built over the live db")
    local pageCtx = inst.NS.Helpers.__panelFor(inst.NS.Schema.PROFILES_PAGE)
    t.truthy(pageCtx, "the page has a ctx under its key")
    t.eq(pageCtx.panel.wantsDefaultsButton, false, "the page did not ask for a Defaults button")
    profilesFrame(inst):Show()
    t.nilv(pageCtx.panel.defaultsBtn, "and the first show built none")
    t.eq(pageCtx.panel.titleText,
        "Ka0s Pretty Chat |A:common-icon-forwardarrow:16:16|a " .. inst.NS.L["Profiles"],
        "it carries the shared breadcrumb header")
end)

-- red under: opening AceConfigDialog in the builder instead of on first show (options-ui-§5).
test("Profiles: nothing is drawn until the page is shown, then it is drawn once", function()
    local inst = ctx.loadAddon()
    t.eq(opens(inst), 0, "registration opens no dialog")
    profilesFrame(inst):Show()
    t.eq(opens(inst), 1, "the first show draws the page")
    local last = lib(inst, "AceConfigDialog-3.0").__lastOpen
    t.eq(last and last.name, APP, "from the page's own table")
    t.truthy(last and last.container and last.container.frame, "into an AceGUI container")
    t.truthy(last.container.frame:IsShown(), "whose frame is shown")
    profilesFrame(inst):Hide()
    profilesFrame(inst):Show()
    t.eq(opens(inst), 1, "a second show with nothing changed does not redraw")
end)

-- AceGUI hands a POOLED SimpleGroup back with its frame still hidden: Release hid it, and
-- neither Create, OnAcquire nor AceConfigDialog:Open shows it again. red under: dropping the
-- explicit Show, which leaves AceConfigDialog filling a frame nobody can see (a blank page).
test("Profiles: a pooled, hidden SimpleGroup is shown before the page fills it", function()
    local inst = ctx.loadAddon()
    local gui = lib(inst, "AceGUI-3.0")
    local create = gui.Create
    gui.Create = function(self, wtype)
        local w = create(self, wtype)
        if wtype == "SimpleGroup" then w.frame:Hide() end
        return w
    end
    profilesFrame(inst):Show()
    gui.Create = create
    local last = lib(inst, "AceConfigDialog-3.0").__lastOpen
    t.truthy(last and last.container.frame:IsShown(), "the pooled frame was shown again")
end)

-- ---------------------------------------------------------------------------
-- The redraw
-- ---------------------------------------------------------------------------

-- red under: a reload path that does not reach the page, which leaves AceDBOptions showing the
-- outgoing profile as current; or a renderer that re-opens on every structural refresh.
test("Profiles: a switch made elsewhere redraws the open page, and a plain refresh does not", function()
    local inst = ctx.loadAddon()
    profilesFrame(inst):Show()
    t.eq(opens(inst), 1, "drawn on show")
    inst.addon.db:SetProfile("Alt")
    t.eq(opens(inst), 2, "the switch redrew the open page")
    inst.NS.Helpers.RefreshAllPanels()
    t.eq(opens(inst), 2, "a structural refresh with no profile event draws nothing")
end)

test("Profiles: a switch while the page is hidden redraws it on its next show", function()
    local inst = ctx.loadAddon()
    local frame = profilesFrame(inst)
    frame:Show()
    frame:Hide()
    inst.addon.db:SetProfile("Alt")
    t.eq(opens(inst), 1, "nothing is drawn while the page is off screen")
    frame:Show()
    t.eq(opens(inst), 2, "and the next show draws the new profile")
end)

test("Profiles: a copy and a reset redraw the open page too", function()
    local inst = ctx.loadAddon()
    inst.addon.db:SetProfile("Alt")
    inst.addon.db:SetProfile("Default")
    profilesFrame(inst):Show()
    local before = opens(inst)
    inst.addon.db:CopyProfile("Alt")
    t.eq(opens(inst), before + 1, "the copy redrew the page")
    inst.addon:ResetAll()
    t.eq(opens(inst), before + 2, "and so did the reset")
end)

-- ---------------------------------------------------------------------------
-- The adopt path: the latch
-- ---------------------------------------------------------------------------

-- red under: a reload that re-applies strings without re-taking the `disabled` hold from the
-- INCOMING profile (slash-commands-§7).
test("Profiles: a switch takes the incoming profile's enabled flag, both ways", function()
    local inst = ctx.loadAddon()
    local NS, db = inst.NS, inst.addon.db
    db:SetProfile("Off")
    NS.Schema.Set("General.enabled", false)
    t.truthy(NS.Lifecycle:IsDown(), "the Off profile stands the addon down")
    db:SetProfile("Default")
    t.falsy(NS.Lifecycle:IsDown(), "switching to an enabled profile stands it up")
    db:SetProfile("Off")
    t.truthy(NS.Lifecycle:IsDown(), "and switching back stands it down again")
end)

-- ---------------------------------------------------------------------------
-- The global reset
-- ---------------------------------------------------------------------------

-- options-ui-§12's testing MUST: the blast radius is the active profile, the profile LIST and
-- the active profile survive, and the other profiles are untouched.
test("Profiles: the global reset empties the active profile and nothing else", function()
    local inst = ctx.loadAddon()
    local NS, db = inst.NS, inst.addon.db
    NS.Schema.Set("General.visibility", "never")
    db:SetProfile("Alt")
    NS.Schema.Set("General.visibility", "inCombat")
    inst.addon:ResetAll()
    t.eq(db:GetCurrentProfile(), "Alt", "still on the profile that was reset")
    local names = {}
    for _, name in ipairs((db:GetProfiles({}))) do names[#names + 1] = name end
    table.sort(names)
    t.eq(table.concat(names, ","), "Alt,Default", "the profile list is unchanged")
    t.eq(NS.Schema.Get("General.visibility"), NS.GeneralDefaults.visibility,
        "the active profile is back to its defaults")
    db:SetProfile("Default")
    t.eq(NS.Schema.Get("General.visibility"), "never", "and the other profile kept its value")
end)

-- red under: dropping `skipRestoreAll` from settings/OptionsSetup.lua (the wiring assertion, read
-- off the source); a veto that forgets the Profiles page (options-ui-§3); or dropping
-- `resetProfile`, which leaves the library's own RestoreAllDefaults a walk of the session rows
-- alone rather than the profile reset options-ui-§12 makes every global reset.
--
-- The wiring is read off the SOURCE, comments stripped, because a descriptor field is not
-- observable after the library's New returns, and because with `resetProfile` supplied the
-- library already narrows its row walk to the sessionOnly rows -- no reset behavior can tell
-- whether the veto was passed.
test("Profiles: the global reset's veto names the page, and the library's reset is ResetAll", function()
    local inst = ctx.loadAddon()
    local Schema = inst.NS.Schema
    local fh = io.open(ctx.root .. "/settings/OptionsSetup.lua", "r")
    t.truthy(fh, "settings/OptionsSetup.lua is readable")
    local src = fh and fh:read("*a") or ""
    if fh then fh:close() end
    local code = src:gsub("%-%-[^\r\n]*", "")
    t.truthy(code:match("skipRestoreAll%s*=%s*NS%.Schema%.VetoedFromResetAll") ~= nil,
        "the options descriptor passes the veto as skipRestoreAll")
    t.truthy(Schema.VetoedFromResetAll({ page = Schema.PROFILES_PAGE, sessionOnly = true }),
        "the Profiles page is vetoed, whatever its rows")
    t.truthy(Schema.VetoedFromResetAll(Schema.FindByPath("General.visibility")),
        "a profile-backed row is vetoed")
    t.falsy(Schema.VetoedFromResetAll({ page = "General", sessionOnly = true }),
        "a session-only row is not")
    local db, resets = inst.addon.db, 0
    local real = inst.addon.ResetAll
    inst.addon.ResetAll = function(self) resets = resets + 1; return real(self) end
    Schema.Set("General.visibility", "never")
    local ok, err = pcall(inst.NS.Helpers.RestoreAllDefaults)
    inst.addon.ResetAll = real
    t.truthy(ok, tostring(err))
    t.eq(resets, 1, "the library's global reset is the host's one profile reset, once")
    t.eq(Schema.Get("General.visibility"), inst.NS.GeneralDefaults.visibility,
        "and it leaves the active profile at its defaults")
    t.eq(db:GetCurrentProfile(), "Default", "on the profile it was on")
end)

-- options-ui-§12: the reset control's tooltip SHOULD name the equivalence with Profiles ->
-- Reset Profile. The composer is the only writer of that text and picks it from the
-- descriptor (LibKa0s-Options-1.0 minor 18), so what is pinned is the descriptor, read back
-- the way a player sees it: the real button's OnEnter, into the mock GameTooltip.
--
-- red under: dropping `profilesPage = true` or `resetProfile` from settings/OptionsSetup.lua
-- (the tooltip falls back to "Restore every setting in this addon to its default", which
-- overstates a reset that leaves the other profiles alone).
local RESET_ALL_TIP = "Reset the current profile to its defaults \226\128\148 the same thing "
    .. "Profiles -> Reset Profile does. Your other profiles are not affected."

test("Profiles: Reset all settings' tooltip says it is the same act as Profiles -> Reset Profile",
function()
    local inst = ctx.loadAddon()
    local env = inst.env
    local general
    for _, sub in ipairs(env._settings.subcategories) do
        if sub.name == "General" then general = sub.frame end
    end
    t.truthy(general, "the General page is registered")
    local mark = #env._widgets
    general:Show()
    local btn
    for i = mark + 1, #env._widgets do
        local w = env._widgets[i]
        if w.type == "Button" and w.text == "Reset all settings" then btn = w end
    end
    t.truthy(btn, "the Master controls tab draws a Reset all settings button")
    env.GameTooltip.lines = {}
    btn:Fire("OnEnter")
    local lines = env.GameTooltip.lines
    t.eq(#lines, 1, "one tooltip body line")
    t.eq(lines[1], RESET_ALL_TIP)
end)

-- ---------------------------------------------------------------------------
-- Degraded installs
-- ---------------------------------------------------------------------------

-- library-stack-§4: every lookup silent, so a build without the AceConfig payload loses this
-- page and nothing else.
test("Profiles: with AceDBOptions absent the page opts out and a switch still works", function()
    local inst = ctx.loadAddon({
        mock = function(m) m.__libs["AceDBOptions-3.0"] = nil end,
    })
    t.eq(#inst.env._settings.subcategories, 2, "General and Categories still register")
    t.falsy(profilesFrame(inst), "and no Profiles page does")
    local ok, err = pcall(function() inst.addon.db:SetProfile("Alt") end)
    t.truthy(ok, "a switch with no page to redraw never raises: " .. tostring(err))
end)
