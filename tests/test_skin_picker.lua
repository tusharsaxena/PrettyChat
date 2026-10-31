-- tests/test_skin_picker.lua — the first-run skin picker and this addon's own AceGUI widgets on the
-- skin (PC-04 of Ka0sAddonsCommonTasks docs/2026-10-29-SKINNING_ROLLOUT/; core/SkinSetup.lua's
-- NS.MaybeShowSkinPicker / NS.HideSkinPicker / NS.SkinPickerSpec / NS.SkinPaintAceTree).
--
-- What this addon owes the picker, and nothing the library pins itself: the spec it hands
-- O.SkinPicker (its owner, its two seams, the Skin tab's page and key, no eye, the close); WHEN it
-- shows (a profile whose `skin.pickerSeen` is false, at OnEnable and after every profile event,
-- never while the addon stands down and never in combat, with no timer and no event armed for
-- it); and that only the player's close marks it seen.
--
-- Then the widgets settings/Panel.lua and settings/Profiles.lua acquire from AceGUI themselves,
-- past the Options instance's owner proxy: the Categories TreeGroup and its editor painted for
-- this owner (nothing while the Scope ignores the settings panel, the default), and the Profiles
-- page painted after every Open and re-opened by a skin switch. Last, the debug console, the one
-- library tool window this addon opens, is owned by it.
--
-- The kit's widgets are recorders, so "painted" is read where the library keeps it:
-- `Skin.__ace[widget].owner` (SkinAce.lua's weak state table) and `Skin.painted[frame].owner`.
-- Every case builds its own instance (tests/loader.lua).

local ctx  = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local OWNER = "PrettyChat"
local PATH  = "skin.pickerSeen"

local function libs(inst)
    return inst.env.LibStub("LibKa0s-Skin-1.0"), inst.env.LibStub("LibKa0s-Options-1.0")
end

--- The owner whose picker is up now, or nil.
local function shownOwner(inst)
    local _, OptionsLib = libs(inst)
    local q = OptionsLib.__pickerQueue
    local cur = q and q.current
    if cur and cur.frame and cur.frame:IsShown() then return cur.owner end
    return nil
end

--- Run `fn(calls)` with O.SkinPicker replaced by a recorder: each call's spec, in order.
local function spying(inst, fn)
    local O = inst.NS.Helpers
    local real = O.SkinPicker
    local calls = {}
    O.SkinPicker = function(spec)
        calls[#calls + 1] = spec
        return { spy = true }
    end
    local ok, err = pcall(fn, calls)
    O.SkinPicker = real
    if not ok then error(err, 0) end
end

local function quietly(inst, fn)
    local cf = inst.env.DEFAULT_CHAT_FRAME
    local add = cf.AddMessage
    cf.AddMessage = function() end
    local ok, err = pcall(fn)
    cf.AddMessage = add
    if not ok then error(err, 0) end
end

-- ── the spec ─────────────────────────────────────────────────────────────────────────────────

test("Skin picker: the spec names this owner, its seams and the Skin tab, with no eye", function()
    -- red under: a set that is not the write seam (Apply would never reach the profile), a page or
    -- tab key the General page does not carry, or an onPreview (X6: no window, no test mode).
    local inst = ctx.loadAddon()
    local NS = inst.NS
    local spec = NS.SkinPickerSpec()
    t.eq(spec.owner, OWNER)
    t.truthy(rawequal(spec.get, NS.SkinChoice), "get is the read seam")
    t.truthy(rawequal(spec.set, NS.WriteSkinChoice), "set is the write seam")
    t.eq(spec.page, "General")
    t.eq(spec.tab, "Appearance", "the Skin tab's key")
    t.truthy(NS.Helpers.__panelFor("General") ~= nil, "\"General\" is a registered page")
    t.nilv(spec.onPreview, "no eye: PrettyChat has nothing to preview in")
    t.eq(type(spec.onClose), "function")
end)

-- ── when it shows ────────────────────────────────────────────────────────────────────────────

test("Skin picker: a fresh profile shows it at OnEnable, with no timer and no event armed", function()
    -- red under: dropping the call from PrettyChat:OnEnable, or deferring it on a timer or an
    -- event this addon would then hold while running (tests/test_disabled.lua's baseline).
    local inst = ctx.loadAddon()
    t.eq(shownOwner(inst), OWNER, "the library's picker is up for this addon")
    t.eq(inst.NS.Schema.Get(PATH), false, "showing is not seen")
    t.eq(#inst.env.__timers, 0, "no timer was armed for it")
end)

test("Skin picker: an unseen profile shows it; a seen one does not, and takes it down", function()
    local inst = ctx.loadAddon()
    local NS = inst.NS
    spying(inst, function(calls)
        NS.MaybeShowSkinPicker()
        t.eq(#calls, 1, "pickerSeen false: the picker shows")
        t.eq(calls[1].owner, OWNER)
        NS.Schema.Set(PATH, true)
        NS.MaybeShowSkinPicker()
        t.eq(#calls, 1, "pickerSeen true: it does not show again")
    end)
    t.nilv(shownOwner(inst), "a profile that has seen it took the login picker down")
    t.eq(NS.Schema.Get(PATH), true)
end)

test("Skin picker: never in combat; the next start out of combat shows it", function()
    -- red under: a start that ignores InCombatLockdown (the picker would pop up mid-fight).
    local inst = ctx.loadAddon({ mock = function(m) m.InCombatLockdown = function() return true end end })
    t.nilv(shownOwner(inst), "a login in combat shows nothing")
    t.eq(inst.NS.Schema.Get(PATH), false, "and the profile still has not seen it")
    t.eq(#inst.env.__timers, 0, "nothing is held for the combat's end")
    inst.env.InCombatLockdown = function() return false end
    inst.NS.MaybeShowSkinPicker()
    t.eq(shownOwner(inst), OWNER, "out of combat it shows")
end)

test("Skin picker: never while the addon is switched off; the stand-down takes it down unmarked", function()
    -- red under: no HideSkinPicker in PrettyChat.StandDown, or a pickerDue that ignores the latch.
    local inst = ctx.loadAddon()
    local NS = inst.NS
    t.eq(shownOwner(inst), OWNER)
    quietly(inst, function() NS.Schema.Set("General.enabled", false) end)
    t.truthy(NS.Lifecycle:IsDown(), "the switch stood the addon down")
    t.nilv(shownOwner(inst), "the stand-down took the picker down")
    t.eq(NS.Schema.Get(PATH), false, "a stand-down is not the player's close")
    spying(inst, function(calls)
        NS.MaybeShowSkinPicker()
        t.eq(#calls, 0, "a disabled addon shows no picker")
    end)
end)

test("Skin picker: a new profile and a reset profile show it again; a seen one stays down", function()
    -- Both start from the defaults, pickerSeen false (O3). red under: no call on the profile adopt
    -- path, or one before the latch re-reads the new profile's switch.
    local inst = ctx.loadAddon()
    local NS, db = inst.NS, inst.addon.db
    NS.Schema.Set(PATH, true)
    quietly(inst, function()
        spying(inst, function(calls)
            db:SetProfile("PickerProbe")
            t.eq(#calls, 1, "a new profile shows the picker")
            NS.Schema.Set(PATH, true)
            db:ResetProfile()
            t.eq(#calls, 2, "a reset profile shows it again")
            NS.Schema.Set(PATH, true)
            db:SetProfile("Default")
            t.eq(#calls, 2, "back on a profile that has seen it: no picker")
        end)
    end)
end)

test("Skin picker: a profile event takes a shown picker down before the new skin is applied", function()
    -- red under: HideSkinPicker after NS.ApplySkinChoice in the adopt path (the library's put-back
    -- of the old profile's skin would then be worn over the new profile's).
    local inst = ctx.loadAddon()
    local NS, db = inst.NS, inst.addon.db
    local Skin = libs(inst)
    quietly(inst, function()
        db:SetProfile("PickerProbe")
        NS.Schema.Set(PATH, true)
        NS.WriteSkinChoice("ka0s", "obsidian")
        NS.ApplySkinChoice()
        db:SetProfile("Default")
        t.eq(shownOwner(inst), OWNER, "Default has not seen it")
        db:SetProfile("PickerProbe")
    end)
    t.nilv(shownOwner(inst), "a profile that has seen it takes the picker down")
    t.eq(select(2, Skin:GetChoice(OWNER)), "obsidian", "the new profile's skin is worn")
end)

-- ── the real window ──────────────────────────────────────────────────────────────────────────

test("Skin picker: the player's close marks it seen; this addon's own hide does not", function()
    local inst = ctx.loadAddon()
    local NS = inst.NS
    local f = NS.MaybeShowSkinPicker()
    t.truthy(f ~= nil and f:IsShown(), "the library's picker is up")
    NS.HideSkinPicker()
    t.eq(NS.Schema.Get(PATH), false, "a hide of this addon's own is not the player's close")
    f = NS.MaybeShowSkinPicker()
    t.truthy(f ~= nil and f:IsShown(), "it shows again while unseen")
    t.truthy(f.close ~= nil, "the window has a close control")
    f.close:__fire("OnClick")
    t.falsy(f:IsShown(), "the close control closes the window")
    t.eq(NS.Schema.Get(PATH), true, "the player's close sets pickerSeen")
    t.nilv(NS.MaybeShowSkinPicker(), "and it does not show again")
end)

test("Skin picker: a pick previews unsaved; Apply saves it through the write seam, seen", function()
    local inst = ctx.loadAddon()
    local NS = inst.NS
    local f = NS.MaybeShowSkinPicker()
    t.truthy(f ~= nil and f:IsShown())
    local wrote = 0
    local write = NS.WriteSkinChoice
    NS.WriteSkinChoice = function(...) wrote = wrote + 1; return write(...) end
    local ok, err = pcall(function()
        -- The spec captured the seam when it was built; a fresh showing reads the swapped one.
        NS.HideSkinPicker()
        f = NS.MaybeShowSkinPicker()
        -- Open the list and click Obsidian's row, as the player does: a pick previews, unsaved.
        -- The mock's frames do not record a parent, so the row is the frame carrying the key
        -- and the swatches the picker builds each list row with.
        f.dd:__fire("OnClick")
        local hit = false
        for _, r in ipairs(inst.env._frames.all) do
            if not hit and r.key == "obsidian" and r.swatches then r:__fire("OnClick"); hit = true end
        end
        t.truthy(hit, "no row for obsidian")
        t.eq(select(2, NS.SkinChoice()), "ka0s", "a pick alone writes nothing to the profile")
        f.apply:__fire("OnClick")
    end)
    NS.WriteSkinChoice = write
    if not ok then error(err, 0) end
    t.falsy(f:IsShown(), "Apply closes the window")
    t.truthy(wrote >= 1, "Apply saved through NS.WriteSkinChoice")
    t.eq(select(2, NS.SkinChoice()), "obsidian", "the pick is the profile's skin")
    t.eq(NS.Schema.Get(PATH), true, "Apply marks the picker seen")
end)

-- ── this addon's own AceGUI widgets ──────────────────────────────────────────────────────────

local function ownerOf(Skin, w)
    local st = Skin.__ace and Skin.__ace[w]
    return st and st.owner or nil
end

--- A fresh instance on `skin`, its Scope set to paint the settings panel unless `ignorePanel`,
--- with the Categories page shown; answers the instance, the Skin library and the TreeGroup.
local function categories(skin, ignorePanel)
    local inst = ctx.loadAddon()
    local NS = inst.NS
    local Skin = libs(inst)
    quietly(inst, function()
        NS.WriteSkinChoice("ka0s", skin, { panel = ignorePanel == true, fonts = false })
        NS.ApplySkinChoice()
    end)
    inst.env.__fireTimers()
    local fixture = dofile(ctx.root .. "/tests/panel_fixture.lua")(NS)
    fixture.panelFrame(inst.env, "Categories"):Show()
    local tree
    for _, child in ipairs(NS.Helpers.__panelFor("Categories").scroll.children) do
        if child.type == "TreeGroup" then tree = child end
    end
    return inst, Skin, tree
end

--- Every widget under `w`, `w` included.
local function walk(w, out)
    out = out or {}
    out[#out + 1] = w
    for _, c in ipairs(w.children or {}) do walk(c, out) end
    return out
end

local PAINTED = { TreeGroup = true, CheckBox = true, Label = true, EditBox = true, Button = true }

test("Skin widgets: the Categories tree and its editor are painted for this owner, past the proxy", function()
    -- red under: dropping NS.SkinPaintAceTree from settings/Panel.lua's buildCategoryBody (the
    -- page acquires from AceGUI itself, so the library's proxy paints none of these).
    for _, skin in ipairs({ "obsidian", "ka0s" }) do
        local _, Skin, tree = categories(skin)
        t.truthy(tree ~= nil, "the Categories page drew its TreeGroup")
        local seen = {}
        for _, w in ipairs(walk(tree)) do
            if PAINTED[w.type] then
                seen[w.type] = true
                t.eq(ownerOf(Skin, w), OWNER, skin .. ": a " .. w.type .. " is painted for this owner")
                t.eq(type(rawget(w, "OnRelease")), "function", skin .. ": its release is wrapped")
            end
        end
        for wtype in pairs(PAINTED) do
            t.truthy(seen[wtype], skin .. ": the editor carries a " .. wtype)
        end
    end
end)

test("Skin widgets: while the Scope ignores the settings panel (the default) nothing is painted", function()
    local _, Skin, tree = categories("obsidian", true)
    for _, w in ipairs(walk(tree)) do
        t.nilv(ownerOf(Skin, w), "a " .. w.type .. " was painted on an ignored settings panel")
    end
end)

test("Skin widgets: a release hands the tree back stock", function()
    -- red under: a host that replaced a widget's OnRelease outright (the restore never runs).
    local inst, Skin, tree = categories("obsidian")
    t.eq(ownerOf(Skin, tree), OWNER)
    inst.env.LibStub("AceGUI-3.0"):Release(tree)
    t.nilv(ownerOf(Skin, tree), "nothing of this owner rides the tree back to the pool")
    t.nilv(rawget(tree, "OnRelease"), "the wrapper is taken back")
end)

local function profilesFrame(inst)
    for _, sub in ipairs(inst.env._settings.subcategories) do
        if sub.name == inst.NS.L["Profiles"] then return sub.frame end
    end
end

test("Skin widgets: the Profiles page paints what AceConfigDialog drew, and a skin switch re-opens it", function()
    -- red under: dropping NS.SkinPaintAceTree from the Profiles renderer, or a renderer that skips
    -- the library's re-render after a skin switch (the page would keep the old skin's rows).
    local inst = ctx.loadAddon()
    local NS = inst.NS
    local dialog = inst.env.__libs["AceConfigDialog-3.0"]
    local painted = {}
    local paintTree = NS.SkinPaintAceTree
    NS.SkinPaintAceTree = function(container)
        painted[#painted + 1] = container
        return paintTree(container)
    end
    local ok, err = pcall(function()
        profilesFrame(inst):Show()
        t.eq(dialog.__opens, 1, "drawn on show")
        t.eq(#painted, 1, "and painted after the Open")
        t.truthy(rawequal(painted[1], dialog.__lastOpen.container), "the container Open filled")
        NS.Helpers.RefreshAllPanels()
        t.eq(dialog.__opens, 1, "a structural refresh still draws nothing")
        quietly(inst, function() NS.ApplySkinChoice("ka0s", "obsidian") end)
        inst.env.__fireTimers()
        t.eq(dialog.__opens, 2, "the skin switch re-opened the page")
        t.eq(#painted, 2, "in the new skin")
    end)
    NS.SkinPaintAceTree = paintTree
    if not ok then error(err, 0) end
end)

-- ── the library tool window this addon opens ─────────────────────────────────────────────────

test("Skin tools: the debug console is owned by this addon", function()
    -- red under: a console descriptor that drops `addonName` or passes its own `skin` /
    -- `applySkin` (the library then paints it for no owner, and it never follows the skin).
    local inst = ctx.loadAddon()
    local Skin = libs(inst)
    quietly(inst, function() inst.NS.ApplySkinChoice("ka0s", "obsidian") end)
    inst.NS.DebugLog:Show()
    local frame = inst.env._frames.byName["PrettyChatDebugWindow"]
    t.truthy(frame ~= nil and frame:IsShown(), "the console is up")
    local rec = Skin.painted[frame]
    t.truthy(rec ~= nil, "the console window was painted through the skin")
    t.eq(rec and rec.owner, OWNER)
end)

-- options-ui-§23: every media picker previews its entries. PrettyChat's only two are the Skin tab's
-- Font and Texture, the library's Ka0sMedia_* pickers. What the addon owes them is the descriptor's
-- getLSM, which O.LSMValues and the panel's font preload read.
test("Skin media: the descriptor passes getLSM, so a media list reads LibSharedMedia", function()
    -- red under: a descriptor with no getLSM, whose LSMValues answers the one "no media" row.
    local inst = ctx.loadAddon()
    local LSM = inst.env.LibStub:NewLibrary("LibSharedMedia-3.0", 1)
    LSM.HashTable = function(_, kind) return { [kind .. " one"] = "path" } end
    local list = inst.NS.Helpers.LSMValues("font")()
    t.eq(list["font one"], "font one")
end)

test("Skin media: with no LibSharedMedia a media list still answers its no-media row", function()
    local inst = ctx.loadAddon()
    local list = inst.NS.Helpers.LSMValues("font")()
    local n = 0
    for _ in pairs(list) do n = n + 1 end
    t.eq(n, 1, "never an empty list")
end)

test("Skin media: the media rows are the Skin tab's, and no schema row is a plain media dropdown", function()
    -- red under: a font, texture, border, background or sound row of the addon's own in a stock
    -- Dropdown, which shows names and no preview.
    local inst = ctx.loadAddon()
    local media = 0
    for _, row in ipairs(inst.NS.Schema.AllRows()) do
        local leaf = tostring(row.path):match("[^.]+$"):lower()
        if leaf == "font" or leaf == "texture" or leaf == "statusbar" or leaf == "border"
            or leaf == "background" or leaf == "sound" then
            media = media + 1
            t.truthy(row.skipRender == true, row.path .. ": the library's picker draws it")
            t.truthy(row.widget ~= "Dropdown", row.path .. ": not a stock Dropdown")
        end
    end
    t.eq(media, 2, "skin.font and skin.texture")
end)
