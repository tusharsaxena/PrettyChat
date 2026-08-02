-- tests/test_compat.lua — NS.Compat.GetAddOnMetadata (compat-§1): the
-- C_AddOns namespace is preferred, the legacy _G global is the fallback,
-- and neither present is a clean nil rather than an error. The shim is the
-- addon's only client-version seam, so all three branches are pinned.

local ctx = _G.PC_TEST
local t    = ctx.t
local test = ctx.test
local inst = ctx.loadAddon()
local NS   = inst.NS
local env  = inst.env

-- Swap the two metadata surfaces around a call, then restore, so the
-- branch under test is the only one reachable.
local function withSurfaces(namespaced, legacy, fn)
    local savedNS, savedLegacy = env.C_AddOns, env.GetAddOnMetadata
    env.C_AddOns, env.GetAddOnMetadata = namespaced, legacy
    local ok, res = pcall(fn)
    env.C_AddOns, env.GetAddOnMetadata = savedNS, savedLegacy
    if not ok then error(res, 0) end
    return res
end

test("Compat.GetAddOnMetadata is published on the namespace", function()
    t.truthy(NS.Compat, "NS.Compat exists")
    t.eq(type(NS.Compat.GetAddOnMetadata), "function", "GetAddOnMetadata is a function")
end)

test("reads through the C_AddOns namespace on a modern client", function()
    t.eq(NS.Compat.GetAddOnMetadata("PrettyChat", "Version"), ctx.mock.metadata.Version,
        "Version comes back from C_AddOns")
    t.eq(NS.Compat.GetAddOnMetadata("PrettyChat", "Notes"), ctx.mock.metadata.Notes,
        "Notes comes back from C_AddOns")
end)

test("prefers C_AddOns over the legacy global when both exist", function()
    local got = withSurfaces(
        { GetAddOnMetadata = function() return "NAMESPACED" end },
        function() return "LEGACY" end,
        function() return NS.Compat.GetAddOnMetadata("PrettyChat", "Version") end)
    t.eq(got, "NAMESPACED", "the namespaced surface wins")
end)

test("falls back to the legacy _G global on an older client", function()
    local got = withSurfaces(nil, function() return "LEGACY" end,
        function() return NS.Compat.GetAddOnMetadata("PrettyChat", "Version") end)
    t.eq(got, "LEGACY", "legacy global is used when C_AddOns is absent")
end)

test("falls back when C_AddOns exists without the getter", function()
    local got = withSurfaces({}, function() return "LEGACY" end,
        function() return NS.Compat.GetAddOnMetadata("PrettyChat", "Version") end)
    t.eq(got, "LEGACY", "a C_AddOns table missing the getter still falls back")
end)

test("returns nil (never errors) when neither surface exists", function()
    local got = withSurfaces(nil, nil,
        function() return NS.Compat.GetAddOnMetadata("PrettyChat", "Version") end)
    t.nilv(got, "no metadata surface yields nil")
end)

test("passes the addon name and key straight through", function()
    local seenName, seenKey
    withSurfaces({ GetAddOnMetadata = function(n, k) seenName, seenKey = n, k end }, nil,
        function() return NS.Compat.GetAddOnMetadata("SomeAddon", "X-Custom") end)
    t.eq(seenName, "SomeAddon", "addon name forwarded verbatim")
    t.eq(seenKey, "X-Custom", "metadata key forwarded verbatim")
end)

test("NS.version is seeded from the TOC through the shim", function()
    -- core/Namespace.lua reads the version through Compat at load.
    t.eq(NS.name, "PrettyChat", "NS.name is the addon folder name")
    t.eq(NS.version, ctx.mock.metadata.Version, "NS.version came from the TOC metadata")
end)
