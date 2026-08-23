-- tests/run.lua
--
-- Headless test runner for Ka0s Pretty Chat, on the shared LibKa0s test kit
-- (testing-§1). Everything generic — the case registry, the assertions, the
-- runner, the `--list` inventory renderer, the sandboxed source loader and the
-- TOC reader — comes from tests/_kit/ and is never edited here. What stays is
-- what is genuinely this addon's: the instance factory (tests/loader.lua), the
-- mock extender (tests/wow_mock.lua) and the ordered suite list below.
--
-- Run from the repo root:
--   lua tests/run.lua          -- run all suites (non-zero exit on failure)
--   lua tests/run.lua --list   -- print docs/test-cases.md's body; run nothing

local Kit  = dofile("tests/_kit/framework.lua")
local mock = dofile("tests/wow_mock.lua")

local root      = "."
local loadAddon = dofile("tests/loader.lua")(root, mock)

-- The assertion names this repo's suites were written against, aliased onto the
-- kit's. Aliases, never re-implementations: `t.eq` IS `Kit.assertEqual`, so the
-- failure messages, the caller-line reporting and the raise semantics are the
-- kit's everywhere.
--
-- `neq` is the one the kit does not carry. Kept as a thin Kit.fail wrapper (so it
-- still reports the CALLER's line) and reported upstream, rather than grown here
-- into a private assertion vocabulary.
local t = {
    eq     = Kit.assertEqual,
    truthy = Kit.assertTrue,
    falsy  = Kit.assertFalse,
    nilv   = Kit.assertNil,
    neq    = function(got, other, msg)
        if got == other then
            Kit.fail((msg or "neq") .. (" (both %s)"):format(tostring(got)), 1)
        end
    end,
}

-- The shared table every suite reaches through `_G.PC_TEST`. Kit.expose merges
-- `test` and the kit assertions in beside this repo's own keys.
_G.PC_TEST = Kit.expose{
    t         = t,
    loadAddon = loadAddon,
    mock      = mock,
    root      = root,
}

-- Order is load-order-sensitive; keep it stable.
Kit.run{
    dir    = "tests/",
    suites = {
        "test_harness",
        "test_vendor_sync",
        "test_libka0s",
        "test_compat",
        "test_constants",
        "test_mediasetup",
        "test_util",
        "test_locale",
        "test_defaults",
        "test_schema",
        "test_render",
        "test_apply",
        "test_override",
        "test_database",
        "test_lifecycle",
        "test_debuglog",
        "test_slash",
        "test_panel",
    },
}
