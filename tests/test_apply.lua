-- tests/test_apply.lua — the master -> category -> string enable cascade,
-- and (post-PC-16) deterministic apply for cross-registered globals.

local function firstFormatRow(Schema, category)
    for _, row in ipairs(Schema.RowsByCategory(category)) do
        if row.kind == "string_format" then return row end
    end
end

local ctx = _G.PC_TEST
local t = ctx.t
local test = ctx.test
local inst   = ctx.loadAddon()
local Schema = inst.NS.Schema
local env    = inst.env

local row = firstFormatRow(Schema, "Loot")
local g, cat = row and row.globalName, row and row.category
local def    = row and Schema.Get(row.path)
local orig   = "ORIG:" .. tostring(g)

test("override is applied by default when all three layers are on", function()
    t.truthy(row, "found a Loot format row")
    t.eq(env[g], def, "override applied by default")
end)

test("master toggle off restores original, back on reapplies", function()
    Schema.Set("General.enabled", false)
    t.eq(env[g], orig, "master off restores original")
    Schema.Set("General.enabled", true)
    t.eq(env[g], def, "master back on reapplies override")
end)

test("category toggle off restores original, back on reapplies", function()
    Schema.Set(cat .. ".enabled", false)
    t.eq(env[g], orig, "category off restores original")
    Schema.Set(cat .. ".enabled", true)
    t.eq(env[g], def, "category back on reapplies override")
end)

test("per-string toggle off restores original, back on reapplies", function()
    Schema.Set(cat .. "." .. g .. ".enabled", false)
    t.eq(env[g], orig, "string off restores original")
    Schema.Set(cat .. "." .. g .. ".enabled", true)
    t.eq(env[g], def, "string back on reapplies override")
end)

test("the cascade is a conjunction — every layer must be on to apply", function()
    -- All eight master/category/string combinations, so no single layer can
    -- be quietly promoted to "wins" by a future refactor.
    local paths = {
        master = "General.enabled",
        cat    = cat .. ".enabled",
        str    = cat .. "." .. g .. ".enabled",
    }
    for _, combo in ipairs({
        { true,  true,  true  },
        { true,  true,  false },
        { true,  false, true  },
        { true,  false, false },
        { false, true,  true  },
        { false, true,  false },
        { false, false, true  },
        { false, false, false },
    }) do
        Schema.Set(paths.master, combo[1])
        Schema.Set(paths.cat,    combo[2])
        Schema.Set(paths.str,    combo[3])
        local expectApplied = combo[1] and combo[2] and combo[3]
        t.eq(env[g], expectApplied and def or orig,
            ("master=%s category=%s string=%s"):format(tostring(combo[1]),
                tostring(combo[2]), tostring(combo[3])))
    end
    inst.addon:ResetAll()
end)

test("a disabled category leaves other categories applied", function()
    inst.addon:ResetAll()
    local otherRow = firstFormatRow(Schema, "Money")
    Schema.Set(cat .. ".enabled", false)
    t.eq(env[g], orig, "the disabled category is restored")
    t.eq(env[otherRow.globalName], otherRow.default, "its neighbor is untouched")
    inst.addon:ResetAll()
end)

test("a string with no snapshot is left alone rather than blanked", function()
    -- ApplyStrings only restores globals it snapshotted in OnEnable; a
    -- global with no original must not be written to nil.
    inst.addon.originalStrings[g] = nil
    env[g] = "SOMETHING ELSE"
    Schema.Set("General.enabled", false)
    t.eq(env[g], "SOMETHING ELSE", "an unsnapshotted global is skipped, not cleared")
    inst.addon.originalStrings[g] = orig
    Schema.Set("General.enabled", true)
    t.eq(env[g], def, "and normal service resumes once it is back")
end)

test("repeated applies are idempotent across the whole surface", function()
    inst.addon:ResetAll()
    local snapshot = {}
    for _, category in ipairs(Schema.CATEGORY_ORDER) do
        for globalName in pairs((inst.NS.Defaults[category] or {}).strings or {}) do
            snapshot[globalName] = env[globalName]
        end
    end
    for _ = 1, 3 do inst.addon:ApplyStrings() end
    for globalName, value in pairs(snapshot) do
        t.eq(env[globalName], value, globalName .. " is unchanged by re-applying")
    end
end)

test("ResetString clears both the custom format and the per-string disable", function()
    -- A per-string reset must restore BOTH dimensions to default (enabled
    -- + default format), matching ResetCategory/ResetAll. Dirty both first.
    Schema.Set(cat .. "." .. g .. ".enabled", false)
    Schema.Set(cat .. "." .. g .. ".format", "CUSTOM:" .. tostring(g))
    t.falsy(inst.addon:IsStringEnabled(cat, g), "string disabled before reset")
    t.eq(Schema.Get(cat .. "." .. g .. ".format"), "CUSTOM:" .. tostring(g),
        "custom format stored before reset")

    inst.addon:ResetString(cat, g)

    t.truthy(inst.addon:IsStringEnabled(cat, g), "reset re-enables the string")
    t.eq(Schema.Get(cat .. "." .. g .. ".format"), def, "reset restores the default format")
    local catDB = inst.addon.db.profile.categories[cat]
    t.falsy(catDB and catDB.disabledStrings and catDB.disabledStrings[g],
        "reset clears the disabledStrings entry")
    t.eq(env[g], def, "reset re-applies the default override to live chat")
end)

test("cross-registered global resolves to the last CATEGORY_ORDER registrant, stably", function()
    -- Deterministic cross-registered apply (PC-16): a global registered
    -- under more than one category must resolve to the documented winner
    -- — the LAST category in CATEGORY_ORDER that registers it — stably.
    -- LOOT_ITEM_CREATED_SELF is shared by Loot + Tradeskill.
    local shared = Schema.crossRegisteredGlobals or {}
    local name = "LOOT_ITEM_CREATED_SELF"
    if shared[name] then
        local winner
        for _, c in ipairs(Schema.CATEGORY_ORDER) do
            for _, reg in ipairs(shared[name]) do
                if reg == c then winner = c end
            end
        end
        t.truthy(winner, "resolved a deterministic winner category")
        inst.addon:ApplyStrings()
        t.eq(env[name], inst.addon:GetStringValue(winner, name),
            "cross-registered global resolves to last CATEGORY_ORDER registrant")
        local first = env[name]
        for _ = 1, 5 do inst.addon:ApplyStrings() end
        t.eq(env[name], first, "repeated apply is stable")
    end
end)
