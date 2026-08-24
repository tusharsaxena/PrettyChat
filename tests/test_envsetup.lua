-- tests/test_envsetup.lua — core/EnvSetup.lua, the LibKa0s-Env-1.0 seam.
--
-- What is asserted here is THE SEAM, not the library. The library's own suite covers
-- the C_AddOns-then-legacy ladder inside GetAddOnMetadata, and a second copy of those
-- cases here is exactly the consumer-side duplication testing-§8 forbids. What only
-- this repo can check is that this addon's helpers answer what the deleted
-- Compat.GetAddOnMetadata answered, that they ask about THIS addon's folder, that the
-- addon's OWN fallback ladder still runs with the library absent, and — the case that
-- earns this file — that the seam is published before the three call sites that read
-- it at FILE LOAD.

local ctx  = _G.PC_TEST
local t     = ctx.t
local test  = ctx.test
local inst  = ctx.loadAddon()
local NS    = inst.NS
local env   = inst.env

local FIXTURE = ctx.mock.metadata

-- Swap the two metadata surfaces around a call, then restore, so the branch under
-- test is the only one reachable. This is the harness the deleted tests/test_compat.lua
-- used; it moves here with the ladder it drives, which now lives in the seam's
-- library-absent arm rather than in a shim.
local function withSurfaces(instance, namespaced, legacy, fn)
    local e = instance.env
    local savedNS, savedLegacy = e.C_AddOns, e.GetAddOnMetadata
    e.C_AddOns, e.GetAddOnMetadata = namespaced, legacy
    local ok, res = pcall(fn)
    e.C_AddOns, e.GetAddOnMetadata = savedNS, savedLegacy
    if not ok then error(res, 0) end
    return res
end

-- ---- the seam ---------------------------------------------------------------

test("EnvSetup: NS.Meta reads THIS addon's TOC", function()
    t.eq(NS.Meta("Version"), FIXTURE.Version, "Version comes back from the manifest")
    t.eq(NS.Meta("Notes"), FIXTURE.Notes, "Notes comes back from the manifest")
end)

test("EnvSetup: NS.Meta asks about the addon FOLDER, not its title or its slash prefix",
function()
    -- The one thing a VENDORED library cannot work out for itself: which folder its
    -- copy sits in. "PrettyChat" is the folder; "Ka0s Pretty Chat" is the ## Title and
    -- "/pc" is the prefix, and both are live strings in this repo. A wrong name reads
    -- some other addon's manifest, or none at all, and answers nil without raising.
    local seenName, seenKey
    withSurfaces(inst,
        { GetAddOnMetadata = function(n, k) seenName, seenKey = n, k end }, nil,
        function() return NS.Meta("X-Custom") end)
    t.eq(seenName, "PrettyChat", "the addon folder name is forwarded verbatim")
    t.eq(seenKey, "X-Custom", "the metadata key is forwarded verbatim")
end)

test("EnvSetup: NS.Version prefers the TOC over this addon's own constant", function()
    -- A packaged addon whose TOC can be read must never report the in-code constant
    -- somebody forgot to edit.
    t.eq(NS.Version(), FIXTURE.Version)
end)

test("EnvSetup: NS.Version answers a string, never nil — it goes straight into a banner",
function()
    local v = NS.Version()
    t.truthy(v ~= nil and v ~= "", "/pc version must never print an empty line")
end)

-- ---- the file-scope reads, which is why this addon's seam loads where it does ----

test("EnvSetup: every file-scope read resolved through the seam", function()
    -- Three call sites read the TOC at FILE SCOPE, not inside a function:
    -- core/Namespace.lua (NS.version), settings/Slash.lua (VERSION) and
    -- settings/Panel.lua (TOC_NOTES). Each resolves once, at load, and keeps the answer
    -- for the whole session, so a seam published after any of them leaves that one on
    -- its hardcoded fallback forever. All three call the seam unguarded, so that
    -- mistake raises at load rather than passing quietly — but a raise only proves the
    -- seam EXISTS by then. What this case proves is that each read took the seam's
    -- answer rather than its own fallback, which no raise can tell you.
    --
    -- The fixture is overridden to values NO fallback in this repo spells, because the
    -- shipped fixture Version is "1.4.0" and so is core/Namespace.lua's own literal —
    -- asserting the fixture value would pass just as happily on the fallback.
    local meta = { Version = "9.9.9", Notes = "SEAM-TAGLINE", Title = FIXTURE.Title }
    local other = ctx.loadAddon({ mock = function(m)
        m.C_AddOns = { GetAddOnMetadata = function(_, k) return meta[k] end,
                       LoadAddOn = function() return true end }
        m.GetAddOnMetadata = function(_, k) return meta[k] end
    end })

    -- core/Namespace.lua:7
    t.eq(other.NS.version, "9.9.9", "NS.version was seeded through the seam, not the literal")

    -- settings/Slash.lua:24 — reachable only through what `/pc version` prints.
    local from = #other.env.DEFAULT_CHAT_FRAME.messages
    other.addon:OnSlashCommand("version")
    local printed = other.env.DEFAULT_CHAT_FRAME.messages[from + 1] or ""
    t.truthy(printed:find("9.9.9", 1, true) ~= nil,
        "/pc version printed '" .. printed .. "', so its file-scope read missed the seam")

    -- settings/Panel.lua:25 — the tagline is only drawn when TOC_NOTES is non-empty.
    local parent = other.env._settings.categories[1] and other.env._settings.categories[1].frame
    t.truthy(parent ~= nil, "no parent settings panel was registered")
    parent:Show()
    local sawTagline = false
    for _, w in ipairs(other.env._widgets) do
        if w.text == "SEAM-TAGLINE" then sawTagline = true end
    end
    t.truthy(sawTagline, "the About tagline did not carry the TOC Notes read through the seam")
end)

-- ---- degraded: this addon's OWN ladder, which only this repo can check ----------

-- Load a fresh instance with the vendored Env module genuinely ABSENT, rather than
-- hand-stubbing the member under test (testing-§8). This runs the else-branch of
-- every helper in core/EnvSetup.lua.
local function degraded()
    return ctx.loadAddon({ skip = { "libs/LibKa0s/Env.lua" } })
end

test("EnvSetup degraded: an install with no LibKa0s still reads its own TOC", function()
    -- The case that earns the written-out fallbacks. Without them the seam answers nil
    -- for everything, and nil is not an error a player would ever see reported: it is a
    -- blank version in the banner and an About page with no tagline.
    local bare = degraded()
    t.nilv(bare.env.LibStub("LibKa0s-Env-1.0", true), "the library was not actually absent")
    t.eq(bare.NS.Meta("Version"), FIXTURE.Version)
    t.eq(bare.NS.Version(), FIXTURE.Version)
end)

test("EnvSetup degraded: the fallback prefers C_AddOns and falls back to the legacy global",
function()
    -- GetAddOnMetadata moved from the _G global into C_AddOns in 10.1. With the library
    -- absent this ladder is THIS addon's again, so all four rungs stay pinned here —
    -- they are not a copy of the library's coverage, they are what replaces it when the
    -- library is missing.
    local bare = degraded()
    t.eq(withSurfaces(bare, { GetAddOnMetadata = function() return "NAMESPACED" end },
        function() return "LEGACY" end,
        function() return bare.NS.Meta("Version") end), "NAMESPACED",
        "the namespaced surface wins when both exist")
    t.eq(withSurfaces(bare, nil, function() return "LEGACY" end,
        function() return bare.NS.Meta("Version") end), "LEGACY",
        "the legacy global is used when C_AddOns is absent")
    t.eq(withSurfaces(bare, {}, function() return "LEGACY" end,
        function() return bare.NS.Meta("Version") end), "LEGACY",
        "a C_AddOns table missing the getter still falls back")
    t.nilv(withSurfaces(bare, nil, nil, function() return bare.NS.Meta("Version") end),
        "no metadata surface at all yields nil, never a raise")
end)

test("EnvSetup degraded: NS.Version falls back to this addon's own constant", function()
    -- The fallback constant lives at the call site rather than in the library, because
    -- which constant this addon falls back to is genuinely its own business — so it is
    -- the seam's job to prove it still works when nothing can be read.
    local bare = degraded()
    local v = withSurfaces(bare, nil, nil, function() return bare.NS.Version() end)
    t.eq(v, bare.NS.version, "the addon's own constant answered")
    t.truthy(v ~= nil and v ~= "", "a version string, never nil — it goes into a banner")
end)

-- ---- the shim it replaced ------------------------------------------------------

test("EnvSetup: the deleted shim is gone from Compat", function()
    -- A seam that leaves the old copy in place is a second answer nobody removed, and
    -- the next caller reaches for whichever one autocomplete offers first.
    -- Compat.GetAddOnMetadata was the WHOLE of core/Compat.lua here, so the file went
    -- with it rather than staying behind as an empty shim for the next one to land in.
    t.nilv(NS.Compat, "NS.Compat is gone — core/Compat.lua held nothing but the shim")
end)
