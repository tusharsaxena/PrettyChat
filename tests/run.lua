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

-- layout-§1's generated-data carve-out, handed to the kit's cap gate. `GlobalStrings/` is a dump
-- extracted from the client (banner at `GlobalStrings/GlobalStrings.lua:1`), loaded by nothing
-- (no `GlobalStrings\` line in PrettyChat.toc; tests/test_defaults.lua reads the chunks as data)
-- and dropped from the packaged zip by `.pkgmeta`'s `- GlobalStrings`. The gate cannot read those
-- three facts, so it takes the set from here and grades the census's `exempt` row against it; the
-- legitimacy of the exemption is the auditor's (docs/ARCHITECTURE.md, *Files over the 1500-line
-- cap*).
--
-- There is deliberately NO `Kit.prose = { exempt = ... }` beside it. localization-§5 lists a
-- generated dump of the client's strings among the spellings that MAY be waived per FILE and per
-- WORD, and forbids a whole-file waiver, so the dump's spellings are waived word by word in
-- tests/prose_waivers.lua instead.
Kit.layoutCap = { exempt = { "GlobalStrings/" } }

-- The kit's diagnostics contract (debug-logging-§14), wired to THIS addon's dispatcher: the
-- consumer facts tests/_kit/test_diagnostics_contract.lua reads. `reset` builds a fresh instance
-- before every case, so no case inherits another's console, flag or latch; the other facts read
-- that instance at call time. Every form goes through `/pc`'s own handler, and the disabled state
-- is the one a player reaches, through the single write seam.
local diagInstance
Kit.diagnostics = {
    brand       = "Ka0s Pretty Chat",
    reset       = function() diagInstance = loadAddon() end,
    dispatch    = function(line) diagInstance.addon:OnSlashCommand(line) end,
    console     = function() return diagInstance.NS.DebugLog end,
    setDebug    = function(on) diagInstance.NS.State.debug = on and true or false end,
    setDisabled = function(off) diagInstance.NS.Schema.Set("General.enabled", not off) end,
}

-- Order is load-order-sensitive; keep it stable.
Kit.run{
    dir    = "tests/",
    suites = {
        "test_harness",
        "test_vendor_sync",
        -- The 1500-line cap gate (layout-§1), the kit's since revision 25 (vendored: 27). Beside
        -- test_vendor_sync because it is the same kind of case: it loads no addon and asserts
        -- nothing about behavior, it reads the repository itself and compares it against what a
        -- document claims about it. Declared by the pair (testing-§9): the bare name would wire a
        -- file of this repo's own, and this repo's hand-written copy was retired for this one.
        { name = "test_layout_cap", dir = "tests/_kit/" },
        -- The "no blanket suppression" gate (lint.md, `M4-11`). Third of the three
        -- repository-reading gates for the same reason the other two sit here: it loads no
        -- addon and asserts nothing about behavior, it reads `.luacheckrc` and the tracked
        -- set and compares them against a rule. It is what keeps the top-level `ignore`
        -- `M4c-06` removed from being one line for anyone to re-add.
        "test_lintconfig",
        -- The US-English prose gate (localization-§5), the kit's copy, declared by the pair for
        -- the same reason; this repo's hand-written copy was retired rather than wired beside it.
        { name = "test_prose", dir = "tests/_kit/" },
        "test_libka0s",
        -- The four degradation-stub parity cases, split out of test_libka0s by M4-09 so the
        -- gate sits at the path all nine addons carry it at. Immediately after test_libka0s
        -- because it is the same seam read from the other side, and because it registers the
        -- surface source the by-name form resolves through.
        "test_surface_parity",
        "test_envsetup",
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
        -- The launcher seam, the composed Minimap button row and the two reserved verbs.
        -- After test_debuglog because it is the last of the core/ seams, and BEFORE
        -- test_slash, which reads the same COMMANDS table from the dispatcher's side.
        "test_launcher",
        "test_slash",
        -- The stand-down conformance suite slash-commands-§7 requires of every addon.
        -- AFTER test_slash because its step 7 drives the same dispatcher, and after
        -- test_launcher because its step 8 drives the same broker object -- both of those
        -- suites establish that the surface works AT ALL, and this one asks what it does
        -- while the addon is switched off.
        "test_disabled",
        -- The diagnostics report's PrettyChat half: its sections, both forms and the read-only
        -- guarantee. After test_disabled for the reason test_disabled follows test_slash: the
        -- verbs are established first, and this asks what one of them writes.
        "test_diagnostics",
        "test_panel",
        "test_doc_structure",
        "test_register",
        -- The kit has shipped one suite of its own since revision 15: the working-tree
        -- line-ending gate, over every path `git ls-files` reports. It lives where the rest
        -- of the kit lives rather than being re-typed into nine repositories, so it is
        -- declared with its own `dir`. Kit.assertSuiteInventory fails the run until it is
        -- declared, so it cannot arrive with a re-vendor and then quietly run nothing.
        { name = "test_eol", dir = "tests/_kit/" },
        -- The kit's diagnostics contract (debug-logging-§14), its own since revision 27: the
        -- dispatcher half of the report, run against this addon's dispatcher through
        -- Kit.diagnostics. Until the addon ships the report that table is unset and the suite
        -- registers one declared skip naming the rule, so the re-vendor is green on its own.
        { name = "test_diagnostics_contract", dir = "tests/_kit/" },
    },
}
