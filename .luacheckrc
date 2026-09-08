-- Luacheck configuration for Ka0s Pretty Chat.
-- Run:  luacheck .

std = "lua51"
max_line_length = false
codes = true

-- Vendored code, the frozen audit/review bundles and the generated GlobalStrings
-- data are not linted. Everything else is, the test tree included:
--   * libs/ (Libs kept too, defensively) — vendored Ace3.
--   * GlobalStrings/ — machine-generated data + the ~1.6MB source dump.
--   * docs/audits/, docs/reviews/ — frozen process bundles (no Lua).
--   * tests/_kit/ — a byte copy of LibKa0s' testkit/, which is linted THERE as
--     source. Linting the copy as well would report every finding twice and let
--     the copy drift green while the original went red, which is the single
--     state tests/test_vendor_sync.lua exists to forbid. That reason does not
--     reach the rest of tests/: those files are ours, and they are in scope.
--     Spelt with the trailing slash the standard's template and the other eight
--     addons use, unlike this list's older entries.
exclude_files = {
    "Libs",
    "libs",
    "GlobalStrings",
    "docs/audits",
    "docs/reviews",
    "tests/_kit/",
}

-- NO TOP-LEVEL `ignore`, and none is coming back (lint.md, `M4-11`). This file carried
-- `ignore = { "212/self", "212/event", "211/addonName" }` until `M4c-06`. Two of those three
-- entries named something real, but a top-level ignore reaches all 43 files, so it silenced those
-- codes in every file that has no business producing them too. Removing the line reported SIXTEEN
-- findings, and ELEVEN of them were not conventions at all: eleven files opened
-- `local addonName, NS = ...` over a folder name they never read. Seven files here DO read it --
-- Namespace, CoreSetup, EnvSetup, MediaSetup, DebugLogSetup, PrettyChat and settings/Panel, each
-- handing it to a vendored library or a texture path that cannot infer which folder it was copied
-- into. The other eleven had it because the line was copied, and they now open `local _, NS = ...`.
-- All eleven are fixed in the source rather than moved into a narrower suppression.
--
-- The third entry, `212/event`, matched NOTHING: no file in this addon has an unused `event`
-- argument, and none did when the blanket was written. It was a line of config that looked like
-- coverage of an Ace3 convention this addon does not happen to use, which is the same defect
-- `M4-11` names, one step further along -- it silenced a code that was never reported.
--
-- The FIVE that remain are the `<code>/<variable>` stanzas at the foot of this file, one per file
-- and one variable each.

-- Writable globals the addon owns.
--   PrettyChatDB       — SavedVariables.
--   StaticPopupDialogs — Blizzard table the addon registers a dialog on.
globals = {
    "PrettyChatDB",
    "StaticPopupDialogs",
    -- The debug console appends its window names to this Blizzard table.
    "UISpecialFrames",
}

-- Blizzard / WoW API surface the addon reads.
read_globals = {
    "LibStub",
    "C_AddOns",
    "C_Timer",
    "CreateFrame",
    "date",
    "wipe",
    "Settings",
    "SettingsPanel",
    "StaticPopup_Show",
    "DEFAULT_CHAT_FRAME",
    "GameTooltip",
    "InCombatLockdown",
    -- The General visibility modes: read at every ApplyStrings pass, and the
    -- transition the combat watcher's two events answer.
    "UnitAffectingCombat",
    "GetAddOnMetadata",
    "UIParent",
    "YES",
    "NO",
    -- Font objects referenced by name.
    "GameFontNormal",
    "GameFontNormalLarge",
    "GameFontNormalHuge",
    "GameFontHighlight",
    "GameFontDisable",
}

-- The harness publishes its exposed table at tests/run.lua:42 and every suite
-- reads it back. It is declared HERE, in a files["tests/"] stanza, rather than in
-- the top-level read_globals above, and the difference is not cosmetic: a name
-- granted at the top level is granted to core/ and settings/ as much as to a
-- suite, and a shipped file reaching for the test harness is exactly what this
-- gate exists to refuse.
--
-- Both names are spelt as _G. fields because that is how the suites write and
-- read them, and luacheck 1.2.0 does not check field access on _G at all — so
-- this stanza silences nothing today and is not what made the tree green. It is
-- here so that the day a suite reaches for a BARE PC_TEST, the declaration is
-- already scoped to tests/ and nobody widens read_globals to get it.
files["tests/"] = {
    globals = {
        "_G.PC_TEST",
        -- The SavedVariables table, a field rather than the bare name because a
        -- suite that clears it is asserting on the ABSENT-saved-variable path
        -- and writes `_G.PrettyChatDB = nil` to say so. The bare name is already
        -- writable above, for the shipped files that own it.
        "_G.PrettyChatDB",
    },
}

-- ---------------------------------------------------------------------------
-- The narrowed 212s (lint.md, `M4c-06`)
-- ---------------------------------------------------------------------------
--
-- Every stanza below names ONE file, and every entry inside it names the code AND the variable, in
-- luacheck's `<code>/<variable>` form. That is the whole difference from the blanket this replaced:
-- an unused `self` in any of the other 40 linted files still reports, and so does an unused
-- `event` or `addonName` anywhere at all. (The tree lints 44 files as of this commit: the 43
-- it linted before, plus tests/test_lintconfig.lua.)
--
-- Measured, not assumed, and the probe matters: this blanket was already spelt in
-- `<code>/<variable>` form, so a dead argument under a NEW name (`deadArg`) was never silenced by
-- it and reports under both configs -- it proves nothing. The probe that separates them is an
-- unused `self` in a file with no stanza. Adding `function Probe:Dead() return 1 end` to
-- modules/Override.lua reports `modules/Override.lua:499:15: (W212) unused argument 'self'` under
-- this config, and the same tree re-linted with the old blanket reports only the W241 beside it.
-- That one line is the entire difference, and it is the whole point: `212/self` used to be off in
-- every linted file and is now off in four.
--
-- Each one is the RECEIVER OF A METHOD, forced by the colon-call at every site that reaches it, on
-- a body that reads the addon through a file-local or through `NS` instead. That is the only shape
-- that earns a stanza here. An argument this addon chose to DECLARE and then never read would be
-- dead code and would be deleted, the way the eleven copied `addonName` headers above were.
-- Turning any of these into a dot-defined function would not be the smaller fix: it would shift
-- the addon table into the first declared parameter at every call site.

-- `PrettyChat:OpenConfig` -- the body is one delegation to `NS.Helpers.OpenOptionsPanel()`, the
-- library's combat-gated opener, so it touches no addon state. It stays a method because
-- settings/Slash.lua:49 reaches it as `PrettyChat:OpenConfig()` and five cases in
-- tests/test_lifecycle.lua reach it as `addon:OpenConfig()`, which is the surface
-- docs/module-map.md publishes.
files["core/PrettyChat.lua"] = {
    ignore = { "212/self" },
}

-- `PrettyChat:ConfirmResetAll` and `PrettyChat:TestToConsole`. Both are LATE-BOUND through the
-- addon table on purpose: settings/Schema.lua:105 and :119 close over `PrettyChat` and call each
-- with a colon from inside the composed MASTER_SPEC, which is built while this file has not loaded
-- yet. Neither body reads the receiver -- one shows a StaticPopup registered in this file, the
-- other drives `NS.DebugLog` -- but a plain local would give Schema's specs nothing to name.
files["settings/Panel.lua"] = {
    ignore = { "212/self" },
}

-- AceConsole-3.0 invokes the handler registered by `RegisterChatCommand` on the addon object --
-- core/PrettyChat.lua:86 registers it BY NAME, `"OnSlashCommand"`, so the library looks the method
-- up on the addon and calls it as `self[name](self, input)`. The receiver arrives whether the body
-- reads it or not; this one hands `input` straight to the LibKa0s-Slash-1.0 instance in this
-- file's `Sl` upvalue. A dot-defined function would land the addon table in `input`.
files["settings/Slash.lua"] = {
    ignore = { "212/self" },
}

-- The mock frame's `GetTextColor`, which answers a constant 1,1,1,1 rather than reading `self`.
-- It is a method because the code under test calls it as one: libs/LibKa0s/Options.lua:446 tints
-- the header divider from `titleFS:GetTextColor()`. Returning real values instead of nil is the
-- mock's fidelity rule 2, written up at tests/wow_mock.lua:36 -- the whole point is that this
-- object answers like a FontString for every frame the suites make, not for one stored colour.
files["tests/wow_mock.lua"] = {
    ignore = { "212/self" },
}
