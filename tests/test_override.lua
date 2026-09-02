-- tests/test_override.lua — modules/Override.lua beyond the enable cascade
-- (which test_apply.lua owns): the value-resolution predicates, the reset
-- family's DB effects, the ApplyStrings pass counters, and the `Test` preview
-- engine's report shape (header, per-category blocks, Name/Original/Formatted
-- triplets, footer counts, and the filtered / empty / erroring paths).

local function firstFormatRow(Schema, category)
    for _, row in ipairs(Schema.RowsByCategory(category)) do
        if row.kind == "string_format" then return row end
    end
end

local function lines(env, from)
    local out = {}
    for i = from + 1, #env.DEFAULT_CHAT_FRAME.messages do
        out[#out + 1] = env.DEFAULT_CHAT_FRAME.messages[i]
    end
    return out
end

local function countMatching(list, pattern)
    local n = 0
    for _, line in ipairs(list) do
        if line:find(pattern) then n = n + 1 end
    end
    return n
end

-- Plain (non-pattern) variant, for needles carrying `|c…` color escapes.
local function countPlain(list, needle)
    local n = 0
    for _, line in ipairs(list) do
        if line:find(needle, 1, true) then n = n + 1 end
    end
    return n
end

local ctx = _G.PC_TEST
local t      = ctx.t
local test   = ctx.test
local inst   = ctx.loadAddon()
local NS     = inst.NS
local addon  = inst.addon
local env    = inst.env
local Schema = NS.Schema

local row  = firstFormatRow(Schema, "Loot")
local cat  = row.category
local g    = row.globalName
local def  = row.default

local function mark() return #env.DEFAULT_CHAT_FRAME.messages end

-- ---- value resolution --------------------------------------------

test("GetStringValue falls back to the defaults table until overridden", function()
    addon:ResetAll()
    t.eq(addon:GetStringValue(cat, g), def, "unset string resolves to its default")
    Schema.Set(cat .. "." .. g .. ".format", "CUSTOM %s")
    t.eq(addon:GetStringValue(cat, g), "CUSTOM %s", "stored override wins")
    addon:ResetAll()
end)

test("IsAddonEnabled treats an absent flag as default-true", function()
    addon:ResetAll()
    t.nilv(addon.db.profile.enabled, "resetting leaves the flag absent, not false")
    t.truthy(addon:IsAddonEnabled(), "absent master flag reads as enabled")
    addon.db.profile.enabled = false
    t.falsy(addon:IsAddonEnabled(), "an explicit false disables")
    addon.db.profile.enabled = true
    t.truthy(addon:IsAddonEnabled(), "an explicit true enables")
    addon:ResetAll()
end)

test("IsCategoryEnabled falls back to the category's shipped default", function()
    t.eq(addon:IsCategoryEnabled(cat), NS.Defaults[cat].enabled,
        "unset category follows the defaults table")
    Schema.Set(cat .. ".enabled", false)
    t.falsy(addon:IsCategoryEnabled(cat), "stored category flag wins")
    addon:ResetCategory(cat)
    t.eq(addon:IsCategoryEnabled(cat), NS.Defaults[cat].enabled,
        "reset restores the shipped default")
end)

test("IsStringEnabled is true unless the string is explicitly disabled", function()
    t.truthy(addon:IsStringEnabled(cat, g), "strings start enabled")
    Schema.Set(cat .. "." .. g .. ".enabled", false)
    t.falsy(addon:IsStringEnabled(cat, g), "explicit disable is honored")
    Schema.Set(cat .. "." .. g .. ".enabled", true)
    t.truthy(addon:IsStringEnabled(cat, g), "re-enabling clears the flag")
    local catDB = addon.db.profile.categories[cat]
    t.falsy(catDB.disabledStrings[g],
        "re-enabling stores nil rather than false (SavedVariables stay lean)")
end)

test("EnsureCategoryDB creates the sub-table once and reuses it", function()
    addon:ResetAll()
    t.nilv(addon.db.profile.categories[cat], "no category table before first write")
    local first = addon:EnsureCategoryDB(cat)
    t.truthy(first, "EnsureCategoryDB returns a table")
    first.marker = "kept"
    t.eq(addon:EnsureCategoryDB(cat).marker, "kept", "a second call reuses the same table")
    addon:ResetAll()
end)

-- ---- ApplyStrings counters ---------------------------------------

test("ApplyStrings returns applied/restored counts that sum to the surface", function()
    addon:ResetAll()
    local applied, restored = addon:ApplyStrings()
    t.truthy(applied > 0, "a default pass applies overrides")
    t.eq(restored, 0, "nothing is restored while everything is enabled")

    Schema.Set("General.enabled", false)
    local applied2, restored2 = addon:ApplyStrings()
    t.eq(applied2, 0, "master off applies nothing")
    t.eq(restored2, applied, "master off restores exactly what it had applied")
    addon:ResetAll()
end)

test("a disabled category shifts its own strings from applied to restored", function()
    addon:ResetAll()
    local baseApplied = addon:ApplyStrings()
    local catStrings = 0
    for _ in pairs(NS.Defaults[cat].strings) do catStrings = catStrings + 1 end

    Schema.Set(cat .. ".enabled", false)
    local applied, restored = addon:ApplyStrings()
    t.eq(applied, baseApplied - catStrings, "the category's strings stop applying")
    t.eq(restored, catStrings, "and are restored instead")
    addon:ResetAll()
end)

-- ---- General visibility -------------------------------------------
--
-- The setting is DECLARED by the composed Master controls block and HONOURED
-- here, and these are the cases that make the second half true. A declared
-- setting nothing reads is worse than an absent one (options-ui-§15).

local function watcher() return env._frames.byName["PrettyChatCombatWatcher"] end

test("visibility `never` restores every original, exactly as Enable off does", function()
    addon:ResetAll()
    local applied = addon:ApplyStrings()
    t.truthy(applied > 0, "the default pass applies overrides")

    Schema.Set("General.visibility", "never")
    local applied2, restored2 = addon:ApplyStrings()
    t.eq(applied2, 0, "never applies nothing")
    t.eq(restored2, applied, "and restores exactly what it had applied")
    t.eq(env[g], "ORIG:" .. g, "the Blizzard original is back in _G")

    Schema.Set("General.visibility", "always")
    t.eq(env[g], addon:GetStringValue(cat, g), "and `always` puts the override back")
    addon:ResetAll()
end)

test("the two combat modes read the player's combat state, in both directions", function()
    addon:ResetAll()
    env.__inCombat = false

    Schema.Set("General.visibility", "inCombat")
    t.falsy(addon:IsVisible(), "inCombat is invisible out of combat")
    t.eq(env[g], "ORIG:" .. g, "so the originals are the ones in _G")
    env.__inCombat = true
    addon:ApplyStrings()
    t.truthy(addon:IsVisible(), "and visible in it")
    t.eq(env[g], addon:GetStringValue(cat, g), "with the overrides applied")

    Schema.Set("General.visibility", "outOfCombat")
    t.falsy(addon:IsVisible(), "outOfCombat is the mirror image")
    env.__inCombat = false
    addon:ApplyStrings()
    t.truthy(addon:IsVisible(), "visible once combat drops")
    t.eq(env[g], addon:GetStringValue(cat, g), "and the overrides come back")

    Schema.Set("General.visibility", "always")
    addon:ResetAll()
end)

test("the combat watcher is armed only while a combat mode is stored", function()
    -- This addon has no combat path at all by default, which is the ground of the
    -- performance-§12 exemption in docs/ARCHITECTURE.md. Dies if SyncCombatWatch
    -- registers unconditionally.
    local fresh = ctx.loadAddon()
    t.nilv(fresh.env._frames.byName["PrettyChatCombatWatcher"],
        "a default install creates no watcher frame at all")

    fresh.NS.Schema.Set("General.visibility", "inCombat")
    local f = fresh.env._frames.byName["PrettyChatCombatWatcher"]
    t.truthy(f, "a combat mode creates it")
    t.truthy(f._events.PLAYER_REGEN_DISABLED, "and registers the combat-entry event")
    t.truthy(f._events.PLAYER_REGEN_ENABLED,  "and the combat-exit event")

    fresh.NS.Schema.Set("General.visibility", "always")
    t.nilv(f._events.PLAYER_REGEN_DISABLED, "leaving the combat modes drops the first")
    t.nilv(f._events.PLAYER_REGEN_ENABLED,  "and the second")
end)

test("the combat boundary re-applies the strings", function()
    addon:ResetAll()
    Schema.Set("General.visibility", "inCombat")
    env.__inCombat = false
    t.eq(env[g], "ORIG:" .. g, "out of combat, the originals stand")

    env.__inCombat = true
    watcher():FireScript("OnEvent", "PLAYER_REGEN_DISABLED")
    t.eq(env[g], addon:GetStringValue(cat, g), "entering combat applies the overrides")

    env.__inCombat = false
    watcher():FireScript("OnEvent", "PLAYER_REGEN_ENABLED")
    t.eq(env[g], "ORIG:" .. g, "and leaving it restores the originals")

    Schema.Set("General.visibility", "always")
    addon:ResetAll()
end)

test("a stored visibility arms the watcher at login, not only on a write", function()
    Schema.Set("General.visibility", "outOfCombat")
    local saved = addon.db.profile.visibility
    t.eq(saved, "outOfCombat", "the mode is stored")
    -- OnEnable is what a fresh session runs; re-run it and the watcher must come
    -- back armed rather than waiting for the player to touch the dropdown.
    watcher():UnregisterEvent("PLAYER_REGEN_DISABLED")
    addon:SyncCombatWatch()
    t.truthy(watcher()._events.PLAYER_REGEN_DISABLED, "the stored mode arms it")
    Schema.Set("General.visibility", "always")
    addon:ResetAll()
end)

-- ---- resets -------------------------------------------------------

test("ResetCategory drops the whole category table", function()
    Schema.Set(cat .. ".enabled", false)
    Schema.Set(cat .. "." .. g .. ".format", "CUSTOM %s")
    t.truthy(addon.db.profile.categories[cat], "category table exists before reset")
    addon:ResetCategory(cat)
    t.nilv(addon.db.profile.categories[cat], "reset removes the category table")
    t.eq(env[g], def, "and re-applies the default override to live chat")
end)

test("ResetCategory('General') clears only the addon-wide keys", function()
    Schema.Set("General.enabled", false)
    Schema.Set("General.visibility", "never")
    Schema.Set(cat .. "." .. g .. ".format", "CUSTOM %s")
    addon:ResetCategory("General")
    t.nilv(addon.db.profile.enabled, "the master override is cleared")
    t.nilv(addon.db.profile.visibility, "and so is the visibility override")
    t.eq(Schema.Get(cat .. "." .. g .. ".format"), "CUSTOM %s",
        "per-category overrides survive a General reset")
    addon:ResetAll()
end)

test("ResetAll clears the master flag and every category at once", function()
    Schema.Set("General.enabled", false)
    Schema.Set(cat .. "." .. g .. ".format", "CUSTOM %s")
    Schema.Set("Money.enabled", false)
    addon:ResetAll()
    t.nilv(addon.db.profile.enabled, "master flag cleared")
    t.truthy(next(addon.db.profile.categories) == nil, "every category table cleared")
    t.eq(env[g], def, "live chat is back on the shipped defaults")
end)

test("a visibility equal to the default stores nothing at all", function()
    addon:ResetAll()
    Schema.Set("General.visibility", "never")
    t.eq(addon.db.profile.visibility, "never", "a real choice is stored")
    Schema.Set("General.visibility", "always")
    t.nilv(addon.db.profile.visibility,
        "and choosing the default clears the key rather than writing it")
    t.eq(addon:GetVisibility(), "always", "which still reads back as the default")
end)

-- ---- the Test preview engine -------------------------------------

test("Test prints a header, a per-category block, and a counted footer", function()
    addon:ResetAll()
    local at = mark()
    addon:Test({ kind = "category", value = cat })
    local out = lines(env, at)

    t.truthy(out[1]:find("sample of every format string", 1, true),
        "the report opens with the preview header")
    t.truthy(countMatching(out, "Category: " .. cat) == 1,
        "exactly one category block for a category filter")

    local strings = 0
    for _ in pairs(NS.Defaults[cat].strings) do strings = strings + 1 end
    t.eq(countMatching(out, "Name: "), strings, "one Name line per string in the category")
    t.eq(countMatching(out, "Original: "), strings, "one Original line per string")
    t.eq(countMatching(out, "Formatted: "), strings, "one Formatted line per string")
    t.truthy(out[#out]:find(("end of test output %%(%d strings shown%%)"):format(strings)),
        "the footer counts the strings shown")
end)

test("Test writes every line to the sink it is given, and nothing to chat", function()
    -- The settings panel's Test button hands in the debug console's writer; the
    -- slash verb hands in nothing and gets NS.Print. Both must produce the SAME
    -- report, which is why the sink is a parameter rather than two report bodies.
    addon:ResetAll()
    local chatAt, sunk = mark(), {}
    addon:Test({ kind = "category", value = cat }, function(line) sunk[#sunk + 1] = line end)

    t.eq(mark(), chatAt, "not one line reached the chat frame")
    t.truthy(sunk[1]:find("sample of every format string", 1, true),
        "the header went to the sink")
    t.truthy(sunk[#sunk]:find("end of test output", 1, true), "and so did the footer")

    -- Byte-for-byte the same report as the default sink's, header to footer.
    local at = mark()
    addon:Test({ kind = "category", value = cat })
    local printed = lines(env, at)
    t.eq(#printed, #sunk, "the two reports are the same length")
    for i, line in ipairs(sunk) do
        t.eq(NS.PREFIX .. line, printed[i], ("line %d is the same text"):format(i))
    end
end)

test("Test previews the Blizzard original from the OnEnable snapshot", function()
    local at = mark()
    addon:Test({ kind = "formatstring", value = g })
    local out = lines(env, at)
    local sawOriginal = false
    for _, line in ipairs(out) do
        if line:find("Original: ", 1, true) and line:find("ORIG:" .. g, 1, true) then
            sawOriginal = true
        end
    end
    t.truthy(sawOriginal, "the Original line renders the snapshotted Blizzard string")
end)

test("a formatstring filter narrows the report to one string", function()
    local at = mark()
    addon:Test({ kind = "formatstring", value = g })
    local out = lines(env, at)
    t.eq(countPlain(out, "Name: " .. NS.Const.Color.reset .. g), 1,
        "the filtered string is shown")
    t.truthy(out[#out]:find("1 string shown", 1, true),
        "the footer singularizes for a single string")
end)

test("a filter that matches nothing says so instead of printing an empty report", function()
    local at = mark()
    addon:Test({ kind = "category", value = "General" })   -- virtual, no strings
    local out = lines(env, at)
    t.truthy(out[#out]:find("(no matching strings)", 1, true),
        "an empty result is reported explicitly")
    t.eq(countMatching(out, "Category: "), 0, "no category block is emitted")
end)

test("Test warns when the addon is disabled but still previews", function()
    Schema.Set("General.enabled", false)
    local at = mark()
    addon:Test({ kind = "formatstring", value = g })
    local out = lines(env, at)
    t.truthy(out[2]:find("addon is currently disabled", 1, true),
        "the disabled notice follows the header")
    t.eq(countPlain(out, "Name: " .. NS.Const.Color.reset .. g), 1,
        "the preview ignores the enable toggles and still renders")
    addon:ResetAll()
end)

test("an unrenderable override is reported as an error line, not a crash", function()
    Schema.Set(cat .. "." .. g .. ".format", "%y bad conversion")
    local at = mark()
    local ok = pcall(function() addon:Test({ kind = "formatstring", value = g }) end)
    local out = lines(env, at)
    t.truthy(ok, "Test never propagates a string.format failure")
    t.truthy(countMatching(out, "%(error: ") == 1, "the failing string renders an error line")
    t.truthy(out[#out]:find("0 strings shown, 1 errored", 1, true),
        "the footer separates errored strings from shown ones")
    addon:ResetAll()
end)

test("every Test line routes through the [PC] printer", function()
    local at = mark()
    addon:Test()
    for _, line in ipairs(lines(env, at)) do
        t.truthy(line:sub(1, #NS.PREFIX) == NS.PREFIX, "line carries the [PC] prefix")
    end
end)
