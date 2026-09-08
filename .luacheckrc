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

-- Ace3 methods take self/event params the addon does not always use;
-- `addonName` is the standard `local addonName, NS = ...` idiom, kept for
-- consistency even in files that only use `NS`.
ignore = { "212/self", "212/event", "211/addonName" }

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
