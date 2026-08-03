local addonName, NS = ...

-- NS.L — localization table with English-key fallback. Keys ARE the
-- enUS strings, so a missing translation returns the key verbatim: any
-- unwrapped or untranslated string still renders in English (zero
-- behavior change on enUS). Translators add locale files that assign
-- L["English source"] = "translated" under their own `GetLocale()` gate.
--
-- The seeded block below is the authoritative manifest of the addon's
-- user-facing string surface — every string wrapped in `L[...]` at a
-- call site appears here.
--
-- Three entries LEFT this manifest when the addon adopted LibKa0s: "Defaults"
-- (the options header button), "Debug console" and its tooltip (the console
-- visibility checkbox). Those strings are the library's now — lib.STRINGS on
-- LibKa0s-Options-1.0 and LibKa0s-DebugLog-1.0 — and are therefore no longer
-- translatable from this folder. That is a real, if small, narrowing of the
-- translatable surface, and it is deliberate rather than an oversight: the
-- library ships no locale files, so a translator restores them by passing a
-- PLAIN table of just those keys as the module's descriptor `L`, in
-- core/DebugLogSetup.lua and settings/OptionsSetup.lua — never NS.L itself
-- (see LibKa0s's README, "The `L` trap"). Recorded at LIBKA0S-05.

local L = setmetatable({}, {
    __index = function(_, k) return k end,
})
NS.L = L

-- enUS manifest (identity mappings — documents the translatable surface).
local enUS = {
    -- General sub-page
    "Addon-wide controls. The Enable toggle is the master switch — disable it and every Blizzard original is restored regardless of per-category settings.",
    "Enable PrettyChat",
    "Master switch for the addon. When off, all Blizzard originals are restored.",
    "Test",
    "Print a sample of every active format string to chat so you can see what real loot/currency/XP messages will look like.",
    "Reset all to defaults",
    "Reset every category and string to its default value.",
    "Reset every category and string to defaults?",
    -- Per-string row
    "Enable",
    "Use the rewritten format for this message. When unchecked, Blizzard's original is used.",
    "Original",
    "Original Format String",
    "Blizzard's original format. Read-only.",
    "(original not available)",
    "New",
    "New Format String",
    "Your replacement. Type `||` for a literal `|` (color codes use this).",
    "Reset",
    "Restore this string to its default.",
    "Preview",
    "The current format rendered with sample arguments.",
    -- Parent page
    "Slash Commands",
    "/prettychat is an alias for /pc",
    -- Slash-command help descriptions (shown in /pc help and the parent panel)
    "List available commands",
    "Open the settings panel",
    "List settings — `/pc list [<Category> | category | formatstring]`",
    "Print a setting's current value — `/pc get <path>`",
    "Set a setting — `/pc set <path> <value>` (try /pc list)",
    "Reset one setting to its default — `/pc reset <path>`",
    "Reset every category to addon defaults",
    "Print sample chat lines — `/pc test [all | category <name> | formatstring <NAME>]`",
    "Debug console — `/pc debug` shows it; `on`/`off` toggle logging",
    "Print the addon version",
}
for _, s in ipairs(enUS) do L[s] = s end
