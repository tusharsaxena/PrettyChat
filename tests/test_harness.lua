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
    -- The XML is what the client reads; the runner's list is a second copy of the
    -- same order, and a module whose sibling is missing is absent rather than
    -- broken (anti-patterns #48), which is exactly the silent case above.
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

-- The manual `diff -r`, mechanical (testing-§11). A vendored copy that has forked
-- from ../LibKa0s is the one state the whole vendoring discipline forbids, and
-- both copies keep working while they drift, so nothing else can see it. Raw
-- bytes, read whole, with NO line-ending normalisation: this repo pins
-- `* text=auto eol=crlf`, and a check that normalised could not see a copy that
-- arrived through a normalising path.
--
-- The sibling checkout is a developer convenience rather than a build input, so
-- these two cases can only run where it is present. That is the ONE place they
-- are allowed to go quiet, and it is stated in the case name rather than hidden:
-- a missing sibling means the check did not look, and the release path is covered
-- by the four explicit diffs in docs/testing.md. Once the folder IS there, a
-- missing or differing file FAILS.
local function assertVendorSync(shipDir, localDir, names, label)
    for _, name in ipairs(names) do
        local a = readFile(shipDir .. "/" .. name)
        local b = readFile(localDir .. "/" .. name)
        t.truthy(a ~= nil, ("%s carries %s"):format(label, name))
        t.truthy(b ~= nil, ("the vendored copy carries %s"):format(name))
        t.eq(b, a, ("%s is byte-identical to %s's copy"):format(name, label))
    end
end

test("libs/LibKa0s is byte-identical to the sibling library checkout, where present", function()
    local ship = ctx.root .. "/../LibKa0s/LibKa0s"
    if not readFile(ship .. "/Core.lua") then return end
    local names = { "LibKa0s.xml", "LICENSE" }
    for _, rel in ipairs(ctx.loadAddon.libFiles) do
        names[#names + 1] = rel:match("([^/]+)$")
    end
    assertVendorSync(ship, ctx.root .. "/libs/LibKa0s", names, "the ship folder")
end)

test("tests/_kit is byte-identical to the sibling library checkout, where present", function()
    local ship = ctx.root .. "/../LibKa0s/testkit"
    if not readFile(ship .. "/framework.lua") then return end
    -- README.md included: the file that actually diverged in this collection WAS a
    -- README, so a check restricted to *.lua would have caught nothing.
    assertVendorSync(ship, ctx.root .. "/tests/_kit",
        { "README.md", "framework.lua", "loader.lua", "mock_base.lua" }, "testkit/")
end)
