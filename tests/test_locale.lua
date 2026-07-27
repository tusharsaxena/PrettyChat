-- tests/test_locale.lua — locales/enUS.lua. `ns.L` is an identity table with an
-- English-key fallback, so a missing translation can never blank a string; the
-- seeded manifest is the authoritative list of the addon's translatable surface
-- (localization-§1). The drift cases below scan the real sources for `L["…"]`
-- call sites and check them against that manifest in both directions — an
-- unwrapped new string, or a manifest entry left behind by a deleted one,
-- surfaces here instead of at a translator's desk.

-- Sources that may reference L (locales/ itself seeds the table, so it is
-- excluded — its `L[s] = s` loop is the seeding, not a call site).
local L_CONSUMERS = {
    "core/PrettyChat.lua",
    "core/DebugLog.lua",
    "modules/Override.lua",
    "settings/Schema.lua",
    "settings/Slash.lua",
    "settings/Panel.lua",
}

local function readFile(path)
    local fh = io.open(path, "r")
    if not fh then return nil end
    local body = fh:read("*a")
    fh:close()
    return body
end

return function(ctx)
    local t    = ctx.t
    local test = ctx.test
    local inst = ctx.loadAddon()
    local ns   = inst.ns
    local L    = ns.L

    -- Every `L["…"]` literal in the addon's own sources, mapped to the file
    -- it was found in.
    local callSites = {}
    for _, rel in ipairs(L_CONSUMERS) do
        local body = readFile(ctx.root .. "/" .. rel)
        if body then
            for key in body:gmatch('L%[%s*"(.-)"%s*%]') do
                callSites[key] = callSites[key] or rel
            end
        end
    end

    test("ns.L is published as a table", function()
        t.truthy(L, "ns.L exists")
        t.eq(type(L), "table", "ns.L is a table")
    end)

    test("an unknown key falls back to itself verbatim", function()
        -- The fallback is what guarantees an unwrapped string still renders.
        t.eq(L["a string nobody translated"], "a string nobody translated",
            "unknown key returns the key")
        t.eq(L["%d items"], "%d items", "the fallback preserves format conversions")
    end)

    test("every seeded manifest entry is an identity mapping", function()
        local n = 0
        for k, v in pairs(L) do
            n = n + 1
            t.eq(v, k, ("manifest entry %q maps to itself"):format(k))
        end
        t.truthy(n > 0, "the manifest seeded entries")
    end)

    test("the scan found the L call sites it is meant to guard", function()
        -- A guard on the guard: if the scan silently matched nothing, the two
        -- drift cases below would pass vacuously.
        local n = 0
        for _ in pairs(callSites) do n = n + 1 end
        t.truthy(n > 20, "the source scan found the localized string surface")
    end)

    test("every localized call site is in the enUS manifest", function()
        for key, file in pairs(callSites) do
            t.truthy(rawget(L, key) ~= nil,
                ("%s: L[%q] is missing from the enUS manifest"):format(file, key))
        end
    end)

    test("the manifest carries no entry that nothing references", function()
        for key in pairs(L) do
            t.truthy(callSites[key] ~= nil,
                ("manifest entry %q is still referenced by a call site"):format(key))
        end
    end)

    test("every slash-command description is localized", function()
        -- The COMMANDS table is the single source for /pc help AND the parent
        -- panel's command list, so its descriptions must be translatable.
        for _, entry in ipairs(ns.COMMANDS) do
            t.truthy(rawget(L, entry[2]) ~= nil,
                ("description for /pc %s is in the manifest"):format(entry[1]))
        end
    end)
end
