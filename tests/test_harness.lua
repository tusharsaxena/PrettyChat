-- tests/test_harness.lua — the harness itself (testing-§9 / testing-§11).
--
-- Two silent failure modes, both of which actually happened during the LibKa0s
-- extraction, and neither of which shows up in the pass/fail line:
--
--   * a file named in a hand-maintained load list but missing from disk is
--     skipped rather than failed, so a renamed source quietly stops being
--     exercised while the run stays green;
--   * a LIBRARY file omitted from the load list makes its module refuse to
--     register (the dependency guard returns before LibStub:NewLibrary), so the
--     host's setup file falls back to its stub and the suite happily measures
--     THE STUB.
--
-- These cases make both impossible rather than merely noticed: the addon's own
-- list is re-derived from the TOC here and compared against what the factory
-- actually fed the loader, the vendored list is checked against LibKa0s.xml, and
-- every major is asserted to have genuinely registered.

local ctx = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local Loader = dofile("tests/_kit/loader.lua")

local function readFile(path)
    local fh = io.open(path, "r")
    if not fh then return nil end
    local body = fh:read("*a")
    fh:close()
    return body
end

test("the runner fed the loader exactly the TOC's files, in the TOC's order", function()
    -- Derived FRESH here rather than compared against a copy, so the assertion
    -- cannot be satisfied by two readings of the same stale list.
    local fresh = Loader.tocFiles(ctx.root .. "/PrettyChat.toc")
    t.truthy(#fresh > 0, "the TOC lists at least one file")
    t.eq(#ctx.loadAddon.tocFiles, #fresh, "the same number of addon files")
    for i, rel in ipairs(fresh) do
        t.eq(ctx.loadAddon.tocFiles[i], rel, ("TOC file %d is %s"):format(i, rel))
    end
end)

test("every derived path exists on disk and no libs/ path leaked in", function()
    for _, src in ipairs(ctx.loadAddon.sources) do
        t.truthy(readFile(ctx.root .. "/" .. src.path) ~= nil,
            ("%s exists on disk"):format(src.path))
    end
    for _, rel in ipairs(ctx.loadAddon.tocFiles) do
        t.falsy(rel:lower():find("^libs/"),
            ("%s is not a libs/ path (those come from the XML list)"):format(rel))
    end
end)

test("the vendored load list is every file of LibKa0s.xml, in XML order", function()
    -- The XML is what the client reads. The runner's list is no longer a hand-typed
    -- second copy — tests/loader.lua derives it with `Loader.xmlFiles` — so this is
    -- not a list compared against itself: the kit's line-based parser is pinned here
    -- against an INDEPENDENT `gmatch` read of the same file, and goes red if the
    -- derivation ever drops, reorders or mis-prefixes an entry. A module whose
    -- sibling is missing is absent rather than broken (anti-patterns #48), which is
    -- exactly the silent case above.
    local xml = readFile(ctx.root .. "/libs/LibKa0s/LibKa0s.xml")
    t.truthy(xml, "libs/LibKa0s/LibKa0s.xml is vendored")

    local fromXml = {}
    for file in xml:gmatch('<Script%s+file="([^"]+)"') do
        fromXml[#fromXml + 1] = "libs/LibKa0s/" .. file
    end
    t.truthy(#fromXml > 0, "the XML lists Script files")
    t.eq(#ctx.loadAddon.libFiles, #fromXml, "the runner lists as many library files as the XML")
    for i, rel in ipairs(fromXml) do
        t.eq(ctx.loadAddon.libFiles[i], rel, ("library file %d is %s"):format(i, rel))
    end
end)

test("every LibKa0s major actually registered in the loaded environment", function()
    -- The load-bearing one. A major that failed to register answers nil to a
    -- silent LibStub lookup, every setup file takes its degradation branch, and
    -- the whole suite measures the fallbacks while staying green.
    local inst = ctx.loadAddon()
    for _, major in ipairs({
        "LibKa0s-Core-1.0", "LibKa0s-DebugLog-1.0", "LibKa0s-Slash-1.0",
        "LibKa0s-Options-1.0", "LibKa0s-Perf-1.0",
    }) do
        local lib = inst.env.LibStub(major, true)
        t.truthy(lib, major .. " registered")
        t.truthy(lib and type(lib.MINOR) == "number" and lib.MINOR > 0,
            major .. " carries a positive MINOR")
    end
end)
