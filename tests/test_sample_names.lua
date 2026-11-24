-- tests/test_sample_names.lua — one source of sample names (FB2-PC-01 of Ka0sAddonsCommonTasks
-- docs/2026-11-24-FEEDBACK_BATCH/R2_SMOKE_FEEDBACK.md, decision D1, LibKa0s#104; LibKa0s v1.113.0,
-- Sim minor 5; standard v2.120.0).
--
-- The owner, 2026-11-24: "adopt the predefined test mode names consistently across all addon's
-- test/sim modes". Every named sample person an addon draws (test mode, sim, preview, unlock
-- stand-ins, sample chat lines or toasts) comes from the library: `Sim.Sample()`'s five
-- protagonists and `Sim.SampleCrowd()`, never a hand-kept list or a hand-copied literal.
--
-- THIS ADDON DRAWS NO SAMPLE PERSON. `/pc test` and the Categories page's Preview render each
-- format string with one placeholder per conversion class (modules/Override.lua, CLASS_SAMPLE:
-- the bare word "Sample" for every `%s`, 42 for an integer, 1.5 for a float). A `%s` there may be
-- a player, an item or a zone, and the walk cannot tell which, so the placeholder names nobody.
-- The guard keeps it that way: no `Sample*` or `Mock*` name literal (the convention's shape, a
-- capitalized word starting "Sample" or "Mock" and then lower-case letters: `Samplehunter`,
-- `Mockrealm`) in a tracked text file outside tests/, libs/ (the library is the source) and the
-- frozen bundles. A plain English word that fits the shape ("Samples", "Mocked") is not a name.
--
-- IT FAILS RATHER THAN PASSES WHEN IT CANNOT LOOK: no io.popen, no git, or too few tracked files.

local ctx  = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local SKIP_DIRS = { "libs/", "tests/", "docs/audits/", "docs/reviews/", "docs/automated-tests/",
                    "docs/perf-analysis/", "docs/revendor/", "docs/superpowers/" }
local TEXT_EXTENSIONS = { lua = true, toc = true, xml = true, md = true, txt = true, json = true,
                          py = true, csv = true }
local WORDS = { Samples = true, Sampled = true, Sampler = true, Samplers = true, Sampling = true,
                Mocks = true, Mocked = true, Mocking = true, Mockup = true, Mockups = true }

local function skipped(path)
    for _, dir in ipairs(SKIP_DIRS) do
        if path:sub(1, #dir) == dir then return true end
    end
    local ext = path:match("%.([%w]+)$")
    return not (ext and TEXT_EXTENSIONS[ext:lower()])
end

--- Every `Sample*`/`Mock*` name literal in `text`, as "line:word".
local function namesIn(text)
    local hits, n = {}, 0
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        n = n + 1
        for word in line:gmatch("%f[%w_]([SM]%a+)%f[^%w_]") do
            local name = word:match("^Sample%l+$") or word:match("^Mock%l+$")
            if name and #name <= 12 and not WORDS[name] then hits[#hits + 1] = n .. ":" .. name end
        end
    end
    return hits
end

local function trackedText()
    t.truthy(io.popen ~= nil, "io.popen is available, so the guard can look")
    local p = io.popen("git -C '" .. ctx.root .. "' ls-files 2>/dev/null")
    t.truthy(p ~= nil, "git ls-files ran")
    local out, seen = {}, 0
    for path in p:lines() do
        seen = seen + 1
        if not skipped(path) then out[#out + 1] = path end
    end
    p:close()
    t.truthy(seen > 100, "git ls-files named the repository's files, got " .. seen)
    t.truthy(#out > 20, "the guard reads the addon's own text files, got " .. #out)
    return out
end

test("sample names: the guard sees a name literal and lets an English word through", function()
    -- red under: a pattern that misses the convention's shape, or flags plain prose.
    t.eq(table.concat(namesIn('local who = "Samplehunter-Samplerealm"\nMock fields'), ","),
        "1:Samplehunter,1:Samplerealm")
    t.eq(table.concat(namesIn("Samples were Mocked, Sim.SampleCrowd(n), MockField and Sample"), ","), "")
    t.eq(table.concat(namesIn("x\npet = 'Mockfang'"), ","), "2:Mockfang")
    t.eq(table.concat(namesIn("unSamplehunter Samplehunter_x"), ","), "", "a name inside a word is not a literal")
end)

test("sample names: no Sample*/Mock* name literal lives outside tests/, libs/ and the frozen bundles", function()
    -- red under: a hand-kept sample name in the addon's code or living docs (LibKa0s#104: take it
    -- from Sim.Sample() or Sim.SampleCrowd() instead).
    local found = {}
    for _, path in ipairs(trackedText()) do
        local fh = io.open(ctx.root .. "/" .. path, "rb")
        if fh then
            local text = fh:read("*a")
            fh:close()
            for _, hit in ipairs(namesIn(text)) do found[#found + 1] = path .. ":" .. hit end
        end
    end
    t.eq(table.concat(found, "; "), "", "sample names outside the library")
end)

test("sample names: the format preview's string placeholder is the bare word, naming nobody", function()
    -- red under: a person's name typed into the placeholder (it would stand in for items and
    -- zones too), or a placeholder that drifts onto the convention's name shape.
    local inst = ctx.loadAddon()
    local rendered = inst.NS.RenderSample("%s receives loot: %s.")
    t.eq(rendered, "Sample receives loot: Sample.", "every %s renders the class placeholder")
    t.eq(#namesIn(rendered), 0, "and the placeholder is no sample person's name")
end)
