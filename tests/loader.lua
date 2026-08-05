-- tests/loader.lua
--
-- The instance factory: builds one fully-booted, ISOLATED PrettyChat in a fresh
-- mock environment and runs the AceAddon lifecycle, so each call returns
--
--   { env = <the mock table, which is also its _G>, NS = <namespace>, addon = <AceAddon obj> }
--
-- This file is reduced to the isolated-environment need and NOTHING ELSE. Every
-- capability the kit already has is taken from the kit: `Loader.makeEnv` builds
-- the sandbox, `Loader.tocFiles` derives the addon's own file list from
-- PrettyChat.toc, and `Loader.xmlFiles` derives the vendored-library list from
-- libs/LibKa0s/LibKa0s.xml (testing-§9, both lists). What remains below is only
-- what the kit has no mode for, and each piece says which need it serves. When
-- `LIBKA0S-01` lands upstream — an isolated-environment mode in
-- `tests/_kit/loader.lua` — this file is deleted outright rather than trimmed
-- again; there is nothing left in it that would survive.
--
-- ISOLATION is the need, because:
--
--   * the addon's reason for existing is rewriting `_G[GLOBALNAME]`, and half the
--     suite asserts on what landed there. A single shared environment would let
--     one suite's overrides answer another suite's reads;
--   * `tests/wow_mock.lua` points `_G` back at the mock table, and this file
--     builds a fresh mock per call, so each instance gets its own global-string
--     table, its own chat-frame transcript and its own AceGUI widget log.
--
-- Chunks are COMPILED ONCE and re-run per instance. `loadfile` on the ~1.9 MB of
-- generated GlobalStrings chunks dominates the run otherwise, and re-executing a
-- cached chunk against a fresh environment is exactly as faithful — the client
-- compiles each file once too.

local Loader = dofile("tests/_kit/loader.lua")

-- Every file of libs/LibKa0s/LibKa0s.xml, in XML order, DERIVED — a vendored
-- library is pulled in through its own .xml, which `tocFiles` cannot see, and a
-- module whose sibling is missing returns before LibStub:NewLibrary and leaves
-- the host measuring its own fallback stub (testing-§9, anti-patterns #48). This
-- was eight hand-typed paths; the kit reads the XML the client reads, so a file
-- added to or removed from LibKa0s.xml cannot leave this list behind. A missing
-- XML raises rather than returning an empty list.
local LIBKA0S = Loader.xmlFiles("libs/LibKa0s/LibKa0s.xml")

local function toSet(list)
    local set = {}
    for _, v in ipairs(list or {}) do set[v] = true end
    return set
end

-- The AceAddon lifecycle hooks are optional — a degraded load (opts.skip) can leave
-- the addon object absent entirely, and a partial one without a given hook.
local function callIfPresent(addon, method)
    if addon and addon[method] then addon[method](addon) end
end

-- Seed pristine Blizzard originals for every registered global so the
-- snapshot in OnEnable captures a recognizable value and the
-- restore-on-disable path is assertable.
local function seedOriginals(NS, mocks)
    if not (NS.Schema and NS.Schema.CATEGORY_ORDER) then return end
    local seen = {}
    for _, cat in ipairs(NS.Schema.CATEGORY_ORDER) do
        for _, row in ipairs(NS.Schema.RowsByCategory(cat)) do
            if row.globalName and not seen[row.globalName] then
                seen[row.globalName] = true
                mocks[row.globalName] = "ORIG:" .. row.globalName
            end
        end
    end
end

-- Returns a loader closure bound to the repo root + the mock module.
return function(root, mockModule)
    local function abs(rel) return root .. "/" .. rel end

    -- The addon's own files, in TOC order, derived rather than restated.
    local tocFiles = Loader.tocFiles(abs("PrettyChat.toc"))

    local sources = {}
    for _, rel in ipairs(LIBKA0S) do sources[#sources + 1] = { path = rel, lib = true } end
    for _, rel in ipairs(tocFiles) do sources[#sources + 1] = { path = rel, lib = false } end

    local compiled = {}
    local function chunkFor(rel)
        local c = compiled[rel]
        if c == nil then
            local err
            c, err = loadfile(abs(rel))
            if not c then
                error(("loadfile(%s) failed: %s"):format(rel, tostring(err)))
            end
            compiled[rel] = c
        end
        return c
    end

    -- Run every source under `env`, honoring the skip set. Libs are called with no
    -- args (they self-register through LibStub); addon files get (addonName, NS).
    -- setfenv is re-applied per instance because the chunk itself is cached.
    local function runSources(env, NS, addonName, skipSet)
        for _, src in ipairs(sources) do
            if not skipSet[src.path] then
                local chunk = chunkFor(src.path)
                setfenv(chunk, env)
                if src.lib then chunk() else chunk(addonName, NS) end
            end
        end
    end

    --- Build one instance.
    --- opts.skip = { "<relative path>", ... } omits those files, which is how the
    --- degraded-install cases load the addon with the library genuinely ABSENT
    --- rather than by hand-stubbing the namespace member under test (testing-§8).
    ---
    --- opts.mock = function(mocks) end runs against the fresh environment BEFORE any
    --- source is loaded, for the client-shape scenarios a post-hoc assignment cannot
    --- reach — an older client with no canvas Settings registrars, say, where what
    --- matters is what the addon does at load and at OnEnable rather than afterwards.
    local function build(opts)
        opts = opts or {}
        local skipSet = toSet(opts.skip)

        local mocks = mockModule()
        if type(opts.mock) == "function" then opts.mock(mocks) end
        local env   = Loader.makeEnv(mocks)
        local NS    = {}
        local addonName = "PrettyChat"

        -- The AceDB fake resolves a SavedVariables NAME against the REAL _G, so a
        -- previous instance's saved table would otherwise be adopted by this one.
        _G.PrettyChatDB = nil

        runSources(env, NS, addonName, skipSet)

        local addon = mocks.LibStub("AceAddon-3.0"):GetAddon("PrettyChat")
        callIfPresent(addon, "OnInitialize")

        -- Seeding sits strictly between OnInitialize and OnEnable: OnEnable is what
        -- snapshots originalStrings, so the originals must already be in place.
        seedOriginals(NS, mocks)

        callIfPresent(addon, "OnEnable")

        return { env = mocks, NS = NS, addon = addon, mocks = mocks }
    end

    -- A callable table, so what the factory actually fed the loader is published
    -- beside it and tests/test_harness.lua can pin the derivation against a fresh
    -- read of the TOC (testing-§9).
    return setmetatable({
        sources  = sources,
        tocFiles = tocFiles,
        libFiles = LIBKA0S,
        root     = root,
    }, { __call = function(_, opts) return build(opts) end })
end
