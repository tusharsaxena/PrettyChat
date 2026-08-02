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

-- The manual `diff -r`, mechanical (testing-§11) — but asked as the question a
-- CONSUMER actually needs answered, which is not the one the library repo's own
-- kit-sync test asks.
--
-- There, both copies live in one repo and comparing working trees is right. Here
-- the other copy is a separate checkout that a maintainer may legitimately be
-- editing: LibKa0s can be mid-release, several commits and a pile of uncommitted
-- work ahead of anything it has tagged. Diffing against its WORKING TREE would
-- redden this suite for upstream progress that this addon has not adopted and
-- should not adopt — and the natural "fix" for that red is to re-vendor
-- uncommitted work, shipping bytes that exist at no ref anybody can check out.
--
-- So the comparison is against the RELEASED TAG this addon says it bundles, read
-- out of the README's own provenance line. That is the adoption report's first
-- question — *is what this consumer is running actually what the library
-- shipped?* — and it is answerable, and it is immune to upstream work in flight.
--
-- One normalisation, and only one: `git show` hands back the stored blob, which is
-- LF, while the working tree is CRLF because `.gitattributes` pins
-- `* text=auto eol=crlf`. Stripping CR from the working-tree side compares the
-- file to the blob it round-trips to. Nothing else is normalised — a real fork in
-- content still fails.

--- The version the README claims to bundle. Read rather than hardcoded: a
--- provenance line and a vendored payload that disagree is precisely the drift
--- this pair exists to catch, so the claim has to be an INPUT to the check.
local function bundledVersion()
    local readme = readFile("README.md") or ""
    return readme:match("Bundles %[LibKa0s%]%b() (v[%d%.]+)")
end

local function gitShow(ref)
    local pipe = io.popen(('git -C "%s/../LibKa0s" show "%s" 2>/dev/null')
        :format(ctx.root, ref), "r")
    if not pipe then return nil end
    local body = pipe:read("*a")
    pipe:close()
    if body == "" then return nil end
    return body
end

local function assertVendorSync(tag, subdir, localDir, names, label)
    for _, name in ipairs(names) do
        local shipped = gitShow(("%s:%s/%s"):format(tag, subdir, name))
        local vendored = readFile(localDir .. "/" .. name)
        t.truthy(shipped ~= nil, ("%s %s carries %s"):format(label, tag, name))
        t.truthy(vendored ~= nil, ("the vendored copy carries %s"):format(name))
        -- CR stripped from the working-tree side only; see the header.
        t.eq((vendored or ""):gsub("\r\n", "\n"), shipped,
            ("%s matches %s at %s"):format(name, label, tag))
    end
end

--- Present only where the sibling checkout is. That is the ONE place this pair may
--- go quiet — a missing sibling means the check did not look — and it is said in
--- the case name rather than hidden. Where the folder IS there, a missing tag, a
--- missing file or a content difference all FAIL.
local function siblingTag()
    if not gitShow("HEAD:LibKa0s/Core.lua") then return nil end   -- no sibling checkout
    local version = bundledVersion()
    t.truthy(version, "README.md carries a `Bundles [LibKa0s](...) vX.Y.Z (MIT).` provenance line")
    return version
end

test("libs/LibKa0s is the LibKa0s release the README says this addon bundles", function()
    local tag = siblingTag()
    if not tag then return end
    local names = { "LibKa0s.xml", "LICENSE" }
    for _, rel in ipairs(ctx.loadAddon.libFiles) do
        names[#names + 1] = rel:match("([^/]+)$")
    end
    assertVendorSync(tag, "LibKa0s", ctx.root .. "/libs/LibKa0s", names, "the library repo")
end)

test("tests/_kit is the test kit that shipped with that release", function()
    local tag = siblingTag()
    if not tag then return end
    -- README.md included: the file that actually diverged in this collection WAS a
    -- README, so a check restricted to *.lua would have caught nothing.
    assertVendorSync(tag, "testkit", ctx.root .. "/tests/_kit",
        { "README.md", "framework.lua", "loader.lua", "mock_base.lua" }, "the library repo")
end)
