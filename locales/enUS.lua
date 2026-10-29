local _, NS = ...

-- locales/enUS.lua — NS.L, the localization table with English-key fallback. Keys ARE the
-- enUS strings, so a missing translation returns the key verbatim: any
-- unwrapped or untranslated string still renders in English (zero
-- behavior change on enUS). Translators add locale files that assign
-- L["English source"] = "translated" under their own `GetLocale()` gate.
--
-- The seeded block below is the authoritative manifest of the addon's
-- user-facing string surface — every string wrapped in `L[...]` at a
-- call site appears here.
--
-- Entries LEAVE this manifest whenever a string changes hands. Three left when
-- the addon adopted LibKa0s: "Defaults" (the options header button), "Debug
-- console" and its tooltip (the console visibility checkbox). Four more left
-- with the settings revamp, when the General page's controls became the COMPOSED
-- Master controls block (options-ui-§15): "Enable PrettyChat" and its tooltip,
-- and the "Reset all to defaults" button and its tooltip, which the composer
-- draws as "Reset all settings". Those strings are the library's now — lib.STRINGS on
-- LibKa0s-Options-1.0 and LibKa0s-DebugLog-1.0 — and are therefore no longer
-- translatable from this folder. That is a real, if small, narrowing of the
-- translatable surface, and it is deliberate rather than an oversight: the
-- library ships no locale files, so a translator restores them by passing a
-- PLAIN table of just those keys as the module's descriptor `L`, in
-- core/DebugLogSetup.lua and settings/OptionsSetup.lua — never NS.L itself
-- (see LibKa0s's README.md, "The `L` trap").

local L = setmetatable({}, {
    __index = function(_, k) return k end,
})
NS.L = L

-- enUS manifest (identity mappings — documents the translatable surface).
local enUS = {
    -- General sub-page. Every control on its one tab is the library's now; what
    -- is left here is the Test verb this addon alone has, and the reset
    -- confirmation's wording. The page's own explainer was removed at the owner's
    -- request -- the tab opened on a paragraph rather than on its controls.
    "Test",
    "Write a sample of every active format string to the debug console, so you can see what real loot/currency/XP messages will look like. `/pc test` writes the same report there.",
    "Reset this profile to the addon's defaults? Everything you have configured or added in it is discarded — your other profiles are not affected.",
    -- The General sub-page's title and sidebar name (its page KEY stays the literal). Its
    -- header Defaults tooltip is the library's (O.ResetAllTooltip), the words `Reset all
    -- settings` carries, so it is not keyed here.
    "General",
    -- Categories sub-page (the tab strip). The page name is a heading rather
    -- than a schema path segment, so unlike the category names interpolated
    -- below it is fully translatable.
    "Categories",
    "Messages are rewritten only while Enable PrettyChat is on and General visibility allows it (General page > Master controls).",
    -- The eight tab tooltips (item 020): what each tab covers, and where the look-alikes went.
    "Item pickups, your own and group loot, bonus rolls, refunds. Crafted items are under Tradeskill.",
    "Currency gained and lost. Currency refunds are under Loot.",
    "Gold looted, split, refunded or rewarded.",
    "Faction standing going up and down.",
    "XP from kills and quests, by rest state, solo, group or raid. Quest-reward and exploration XP lines are under Misc.",
    "Honor you earn.",
    "Professions: crafting (yours and others') and opening locks.",
    "Quest-reward XP and zone exploration XP.",
    -- The page's Defaults tooltip. The button resets every tab (options-ui-§13).
    "Reset the strings on every category tab to their defaults.",
    -- The confirmation that page's header Defaults raises (PC-R-03).
    "Reset the strings on every category tab to their defaults? Your edits in every category are discarded.",
    -- Profiles sub-page (settings/Profiles.lua): its sidebar entry and header title.
    -- The page body is AceDBOptions' own table, translated by Ace3's locale files.
    "Profiles",
    -- Category sub-page. `%s` is the category name, which is itself English —
    -- see the `localization-§1` row in docs/ARCHITECTURE.md's deviations
    -- register. The placeholder is what makes the SENTENCE translatable; these
    -- were concatenated fragments until PC-R-06, which pinned English word order
    -- and left a translator nothing to reorder. There were four until the eight
    -- category pages became one tabbed page: the per-page `Reset all %s strings
    -- to defaults.` had no caller left, because one Defaults button over eight
    -- tabs cannot name a category (settings/Panel.lua, the Categories page).
    "Enable %s",
    "Rewrite %s messages. When off, every %s message uses Blizzard's original wording, whatever the switches below say.",
    -- Per-string row. Each tooltip title is its control's label, so a label is one key.
    "Rewrite this message",
    "Rewrite this message. When off, Blizzard's original wording is used.",
    "Original",
    "Blizzard's original format. Read-only.",
    "(original not available)",
    "New",
    "Your rewritten format. Type `||` for a literal `|` (color codes use this).",
    -- The write gate's refusal (PC-R-01), shown wherever the write came from:
    -- the panel's New box, `/pc set`, or a preset load. The four placeholders are
    -- the schema path, the signature asked for, the Blizzard global and the
    -- signature it supplies.
    "Not saved — %s asks for %s; %s supplies %s. A format may drop trailing conversions but must not add or retype one.",
    -- The same gate's blank-format rule (PC-R-02), checked first: a cleared New
    -- box committed with Enter. The placeholder is the schema path.
    "Not saved — %s: a format can't be blank. Use Reset message to restore it.",
    "Reset message",
    "Restore this string to its default.",
    "Preview",
    "Your rewritten format, rendered with sample values. Hover the entry in the list to see Blizzard's original rendered the same way.",
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
    "Reset every setting to defaults",
    "List profiles, or switch to one: profile <name>",
    "Print sample chat lines to the debug console — `/pc test [all | category <name> | formatstring <NAME>]`",
    "Debug console — `/pc debug` shows it; `on`/`off` toggle logging",
    "Print the addon version",
    -- The diagnostics report's verb (debug-logging-§14). The report body is English
    -- diagnostic text like every trace line and is not keyed here; the one chat line
    -- after it is LibKa0s-DebugLog-1.0's `DIAG_WRITTEN`, overridable through the
    -- console descriptor's `L` (see the header above).
    "Write a diagnostics report to the debug console, for a bug report",
    -- The two reserved ALIASES (slash-commands-§2). They write the SAME stored
    -- path the composed `Enable PrettyChat` checkbox writes, so what is
    -- translatable from this folder is the verb's DESCRIPTION; the confirmation
    -- line itself is LibKa0s-Slash-1.0's `set` rendering, like every other one.
    "Enable the addon",
    "Disable the addon",
    -- Slash-command and `/pc test` OUTPUT, as opposed to the verb descriptions
    -- above. Each key is a WHOLE sentence with `%s`/`%d` where the data goes, and
    -- each one was a concatenation of prose and data until M4-21; the routing is
    -- byte-identical because `L` falls back to the key. What is NOT here is the
    -- residue `tests/test_locale.lua` records with a reason per site: a line whose
    -- prose is split across two color spans cannot become one key without moving
    -- the `|c…|r` escapes inside translatable text, and wrapping the halves
    -- separately is the fragment-keying PC-R-06 removed.
    "schema not ready yet",
    "unknown command '%s'",
    "v%s slash commands",
    "Categories (%d)",
    "Format strings (%d)",
    "unknown category '%s'. Valid: ",
    "unknown format string '%s' — try ",
    "all settings reset to defaults",
    "debug console unavailable",
    -- The `/pc test` report's own lines (modules/Override.lua).
    "sample of every format string (preview ignores enable toggles):",
    "(addon is currently disabled — these formats aren't being applied to live chat)",
    "(no matching strings)",
    -- General ▸ Skin: the skin.* rows (settings/Schema.lua). The tab itself is the library's
    -- (O.AppearanceTab), which draws these rows from its own words; these are the rows' labels
    -- and tooltips as `/pc list` and the schema carry them.
    "Skin source",
    -- The source row's first value (core/SkinSetup.lua NS.SKIN_SOURCE_OPTIONS); the second,
    -- EllesmereUI, is a proper name.
    "Ka0s skins",
    "Where this addon's look comes from: the Ka0s skin chosen below, or EllesmereUI.",
    "Skin",
    "The Ka0s skin this addon wears. Changes its settings pages and the debug console right away.",
    "Ignore settings panel",
    "Keep this addon's settings panel in the game's own look. The debug console still wears the skin.",
    "Ignore fonts",
    "Keep every font in this addon as the game draws it. The skin still colors the text.",
    "Font",
    "The font this addon's text uses, over the skin's own. Empty keeps the skin's.",
    "Texture",
    "The texture this addon's bars use, over the skin's own. Empty keeps the skin's.",
    "Skin picker seen",
    "Whether the first-run skin picker was closed on this profile.",
    -- core/SkinSetup.lua: the one line a reload request earns on a profile event.
    "Reload your interface (/reload) to finish changing the skin.",
}
for _, s in ipairs(enUS) do L[s] = s end
