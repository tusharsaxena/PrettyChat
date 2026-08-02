local addonName, NS = ...

-- Core AceAddon object + lifecycle. The override engine (snapshot / ApplyStrings / Test)
-- lives in modules/Override.lua; the /pc dispatcher in settings/Slash.lua. This file owns
-- registration, OnInitialize/OnEnable, the shared chat printer, and the combat-gated
-- panel open. Methods defined in the other files hang off this same PrettyChat object.

-- Pass the NS table as the AceAddon object (architecture-§2) so the addon
-- object and the bootstrap namespace are one table. AceConsole's :Print embed
-- therefore lands on NS and clobbers the cyan printer — which is why
-- core/CoreSetup.lua, the file that builds that printer from LibKa0s-Core-1.0,
-- is the very next entry in the TOC and reclaims the name (anti-pattern #36).
-- Keep that order: NewAddon here, the reclaim immediately after.
local PrettyChat = LibStub("AceAddon-3.0"):NewAddon(NS, addonName, "AceConsole-3.0")

local Color = NS.Const.Color

function PrettyChat:OnInitialize()
    -- Start from the profile defaults (defaults/Profile.lua) and merge
    -- Database's `global` defaults (schemaVersion) so AceDB provisions both
    -- the profile and global namespaces.
    local defaults = NS.ProfileDefaults
    if NS.Database and NS.Database.defaults then
        for k, v in pairs(NS.Database.defaults) do
            defaults[k] = defaults[k] or v
        end
    end

    self.db = LibStub("AceDB-3.0"):New("PrettyChatDB", defaults, true)

    if NS.Database and NS.Database.RunMigrations then
        NS.Database.RunMigrations(self.db)
    end

    self:RegisterChatCommand("pc", "OnSlashCommand")
    self:RegisterChatCommand("prettychat", "OnSlashCommand")
end

function PrettyChat:OnEnable()
    self.originalStrings = {}
    for _, catData in pairs(NS.Defaults) do
        for globalName in pairs(catData.strings) do
            self.originalStrings[globalName] = _G[globalName]
        end
    end
    self:ApplyStrings()

    -- Settings.RegisterCanvasLayoutCategory is allowed in OnEnable for a
    -- non-LoD addon (OnEnable fires after the Settings API is live and
    -- after PLAYER_LOGIN). Folding panel registration into the AceAddon
    -- lifecycle removes Panel.lua's parallel PLAYER_LOGIN bootstrap.
    if NS.Config and NS.Config.RegisterPanels then
        NS.Config.RegisterPanels()
    end
    -- No boot-summary debug line here: the session-only debug flag is off at load, so it
    -- would never render. The self-identifying [Init] summary rides the DebugLog:SetEnabled
    -- seam instead (debug-logging-§5/§8).
end

-- Expand the parent category in the Blizzard Settings left tree so
-- every sub-page is visible. Wrapped in pcall: SettingsPanel internals
-- (CategoryList, GetCategoryEntry, SetExpanded) are private API and
-- could shift between patches; if any call goes missing we return false
-- so OpenConfig can surface a one-time grey notice rather than silently
-- absorbing the regression.
local function expandMainCategory(cat)
    if not (cat and SettingsPanel) then return false end
    local ok, expanded = pcall(function()
        local list = SettingsPanel.GetCategoryList
            and SettingsPanel:GetCategoryList()
            or SettingsPanel.CategoryList
        if not (list and list.GetCategoryEntry) then return false end
        local entry = list:GetCategoryEntry(cat)
        if entry and entry.SetExpanded then
            entry:SetExpanded(true)
            return true
        end
        return false
    end)
    return ok and expanded
end

function PrettyChat:OpenConfig()
    -- Combat guard lives here (not just in the slash dispatcher) so any
    -- programmatic caller — other addons, a /run script, future internal
    -- code paths — is also gated. Settings.OpenToCategory triggers the
    -- protected category-switch code; calling it under combat lockdown
    -- taints the panel for the rest of the session, so we refuse with a
    -- grey notice rather than deferring (Ka0s standard, options-ui-§2).
    if InCombatLockdown and InCombatLockdown() then
        NS.Print(Color.grey .. "cannot open settings during combat — Blizzard's category-switch is protected" .. Color.reset)
        NS.Debug("Config", "refused (in combat)")
        return
    end
    if not (Settings and Settings.OpenToCategory) or not self.optionsCategoryID then
        NS.Debug("Config", "unavailable (Settings API / category not ready)")
        return
    end
    local opened = Settings.OpenToCategory(self.optionsCategoryID)
    if opened == false then
        NS.Print(Color.grey .. "could not open settings panel — category not registered" .. Color.reset)
        NS.Debug("Config", "blocked (category not registered)")
        return
    end
    NS.Debug("Config", "opened")
    if not expandMainCategory(self.optionsCategory) and not self._expandWarned then
        self._expandWarned = true
        NS.Print(Color.grey .. "(could not auto-expand the Pretty Chat sub-tree — click the parent row to expand)" .. Color.reset)
    end
end
