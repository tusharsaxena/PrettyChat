local _, NS = ...

-- defaults/Profile.lua — THE ONE DECLARATION SITE (savedvariables-§2, PC-94). Every setting
-- default this addon has is typed in this file and nowhere else; readers elsewhere
-- (the Master block spec, the reader fallbacks, the set arms, the load-time
-- validator) name these tables instead of retyping a literal. The per-string
-- reference data stays in defaults/Defaults.lua. core/PrettyChat.lua's
-- OnInitialize assembles NS.ProfileDefaults + NS.GlobalDefaults before AceDB:New,
-- so AceDB provisions both namespaces.

-- NS.GlobalDefaults — the AceDB `global` defaults.
--
-- `schemaVersion = 0` is the migration runner's declared stamp (core/Database.lua
-- owns the runner and the contract). It starts at 0 so a brand-new DB runs cleanly
-- up to Database.SCHEMA_VERSION (every step is a no-op on a fresh profile), and it
-- survives AceDB's removeDefaults: a stamp above 0 differs from the default so it
-- is never stripped, and a stored 0 that is stripped reads back as the default 0.
--
-- `minimap` is LibDBIcon's OWN table and it is DECLARED here rather than written
-- anywhere (launcher-§3, architecture-§5): the declared default is what
-- materializes it, and LibDBIcon then writes `minimapPos` into the same table when
-- the player drags the button. A `minimap = { hide = false }` assignment in a
-- setup file would be a whole-section write over a path a schema row addresses,
-- and it would wipe the position on every login.
--
-- GLOBAL, and that is the decision rather than where the rest of the settings
-- happened to land. A minimap button belongs to the INSTALLATION: a profile switch
-- must not move a player's buttons, and options-ui-§12's `Reset all settings` -- a
-- profile reset by definition -- must not un-hide a button the player deliberately
-- hid. PrettyChat has never stored this table anywhere else, so there is no
-- db.profile.minimap to carry across and no schemaVersion bump: this is a new
-- default, not a stored-path move.
NS.GlobalDefaults = {
    schemaVersion = 0,
    minimap = { hide = false },
}

-- NS.GeneralDefaults — the two addon-wide General rows' defaults, `General.enabled`
-- and `General.visibility`. NOT in NS.ProfileDefaults, on purpose: both are stored
-- only when they differ from the default (the rows' `set` clears to nil), and the
-- readers answer nil with these values (savedvariables-§5's `== nil` form), which
-- keeps SavedVariables empty until the player changes something.
NS.GeneralDefaults = {
    enabled    = true,
    visibility = "always",
}

-- NS.ProfileDefaults — the AceDB `profile` defaults table.
--
-- Addon-wide and per-category `enabled` flags are intentionally absent.
-- IsAddonEnabled / IsCategoryEnabled treat `nil` as default-true (see
-- docs/schema.md), which keeps SavedVariables empty until the user disables
-- something. The empty `categories` table is documentation-only — AceDB never
-- merges {} into user-keyed sub-tables, so removing this line would be
-- semantically identical.
--
-- `skin` is the skin this addon wears (skinning-§2; owner ruling R1, per addon, per profile),
-- applied through core/SkinSetup.lua: where it comes from ("ka0s", the Ka0s skins, or "eui",
-- EllesmereUI's) and which Ka0s skin, "ka0s"/"ka0s" being Ka0s Default; the Skin tab's Scope
-- (leave the settings panel the client's, leave every font the client's; a new profile leaves the
-- panel the client's and skins the fonts, the owner's call for LootHistory on 2026-10-27, taken
-- for the collection); the font and texture overrides, an LSM key each or "" for the skin's own;
-- the Font outline (LibKa0s v1.82.0, ruling D-06: "all" text, "hud" text only, or "off"; "hud" is
-- the default since v1.83.0, D-10 of Ka0sAddonsCommonTasks docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/, a stored mode stays);
-- and `pickerSeen`, whether the first-run skin picker was closed on this profile (false on every
-- profile, old and new: owner ruling O3). New keys with defaults, so AceDB merges them into every
-- existing profile and no migration is owed.
NS.ProfileDefaults = {
    profile = {
        categories = {},
        skin = {
            source      = "ka0s",
            skin        = "ka0s",
            ignorePanel = true,
            ignoreFonts = false,
            font        = "",
            texture     = "",
            outline     = "hud",
            pickerSeen  = false,
        },
    },
}
