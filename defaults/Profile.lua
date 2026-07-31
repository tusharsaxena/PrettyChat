local addonName, NS = ...

-- NS.ProfileDefaults — the AceDB `profile` defaults table. Profile defaults
-- live under defaults/ (savedvariables-§2 / layout-§1); the per-string reference
-- data stays in defaults/Defaults.lua. core/PrettyChat.lua's OnInitialize merges
-- this with NS.Database's `global` defaults before AceDB:New, so AceDB provisions
-- both namespaces.
--
-- Addon-wide and per-category `enabled` flags are intentionally absent.
-- IsAddonEnabled / IsCategoryEnabled treat `nil` as default-true (see
-- docs/schema.md), which keeps SavedVariables empty until the user disables
-- something. The empty `categories` table is documentation-only — AceDB never
-- merges {} into user-keyed sub-tables, so removing this line would be
-- semantically identical.
NS.ProfileDefaults = {
    profile = {
        categories = {},
    },
}
