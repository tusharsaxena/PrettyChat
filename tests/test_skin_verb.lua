-- tests/test_skin_verb.lua — the reserved `skin` verb (LibKa0s v1.82.0, OptionsSkinPicker minor 3's
-- O.SkinVerb; PC-01 of Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK, ruling D-16):
-- a `skin` row right after `config` runs NS.RunSkinVerb, which hands O.SkinVerb the first-run spec
-- (NS.SkinPickerSpec), so `/pc skin` shows the picker a new profile shows whatever skin.pickerSeen
-- says. A feature verb, not on the live set: the dispatcher refuses it while the addon is disabled.
-- In combat the library prints its gray line on every call; without LibKa0s the stub answers nil,
-- "absent" and NS.RunSkinVerb prints the library-absent line. The reference is LibKa0sSkinTester
-- e21689f.

local ctx  = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local OWNER = "PrettyChat"

local function strings(inst) return inst.env.LibStub("LibKa0s-Options-1.0").SKIN_PICKER_STRINGS end

--- The owner whose picker is up now, or nil.
local function shownOwner(inst)
    local q = inst.env.LibStub("LibKa0s-Options-1.0").__pickerQueue
    local cur = q and q.current
    if cur and cur.frame and cur.frame:IsShown() then return cur.owner end
    return nil
end

--- The chat lines a `/pc` input printed.
local function say(inst, input)
    local msgs = inst.env.DEFAULT_CHAT_FRAME.messages
    local from = #msgs
    inst.addon:OnSlashCommand(input)
    local out = {}
    for n = from + 1, #msgs do out[#out + 1] = msgs[n] end
    return out
end

local function anyLine(lines, fragment)
    for _, l in ipairs(lines) do
        if tostring(l):find(fragment, 1, true) then return true end
    end
    return false
end

--- Logged in, the first-run picker closed by the player, so only the verb can bring it back.
local function seenProfile(opts)
    local inst = ctx.loadAddon(opts)
    inst.NS.Schema.Set("skin.pickerSeen", true)
    inst.NS.MaybeShowSkinPicker()
    t.nilv(shownOwner(inst), "the first-run picker is down")
    return inst
end

test("Skin verb: the row sits right after config, with the library's help words", function()
    local inst = ctx.loadAddon()
    local at
    for i, c in ipairs(inst.NS.COMMANDS) do
        if c[1] == "skin" then at = i end
    end
    t.truthy(at ~= nil, "a skin row")
    t.eq(inst.NS.COMMANDS[at - 1][1], "config", "after config")
    t.eq(inst.NS.COMMANDS[at][2], strings(inst).VERB_HELP, "one wording for every host")
end)

test("Skin verb: /pc skin shows the picker on a profile that has closed it", function()
    -- red under: no skin row (the dispatcher answers "unknown command").
    local inst = seenProfile()
    local out = say(inst, "skin")
    t.eq(shownOwner(inst), OWNER, "the picker is up")
    t.falsy(anyLine(out, "unknown command"), "a known verb")
end)

test("Skin verb: NS.RunSkinVerb hands O.SkinVerb this addon's first-run spec", function()
    local inst = seenProfile()
    local O = inst.NS.Helpers
    local real, seen = O.SkinVerb, nil
    O.SkinVerb = function(spec) seen = spec; return nil, "queued" end
    local ok, err = pcall(function()
        local win, why = inst.NS.RunSkinVerb()
        t.nilv(win, "nothing shown")
        t.eq(why, "queued", "the library's reason, passed on")
    end)
    O.SkinVerb = real
    if not ok then error(err, 0) end
    t.truthy(type(seen) == "table", "O.SkinVerb was called with a spec")
    t.eq(seen.owner, OWNER)
    t.truthy(rawequal(seen.get, inst.NS.SkinChoice), "the read seam")
    t.truthy(rawequal(seen.set, inst.NS.WriteSkinChoice), "the write seam")
    t.eq(seen.tab, "Appearance", "the gear opens the Skin tab")
end)

test("Skin verb: in combat every call prints the library's gray line and shows nothing", function()
    local inst = seenProfile()
    inst.env.InCombatLockdown = function() return true end
    local first = say(inst, "skin")
    local second = say(inst, "skin")
    inst.env.InCombatLockdown = function() return false end
    t.nilv(shownOwner(inst), "no picker mid-combat")
    t.truthy(anyLine(first, strings(inst).VERB_COMBAT), "the first call says why")
    t.truthy(anyLine(second, strings(inst).VERB_COMBAT), "and so does every later one")
end)

test("Skin verb: refused while the addon is disabled, and no picker shows", function()
    local inst = seenProfile()
    say(inst, "disable")
    t.eq(inst.addon:IsAddonEnabled(), false)
    local out = say(inst, "skin")
    t.eq(#out, 1, "one refusal line")
    t.truthy(anyLine(out, inst.NS.SlashCommands:DisabledLine()), "the collection's disabled line")
    t.nilv(shownOwner(inst))
end)

test("Skin verb: without LibKa0s the verb prints the library-absent line", function()
    local bare = ctx.loadAddon({ skip = { "libs/LibKa0s/Core.lua" } })
    local out = say(bare, "skin")
    t.truthy(anyLine(out, "/pc skin is unavailable: the LibKa0s library did not load."),
        "the collection's library-absent line, naming the verb")
    local win, why = bare.NS.RunSkinVerb()
    t.nilv(win)
    t.eq(why, "absent")
end)
