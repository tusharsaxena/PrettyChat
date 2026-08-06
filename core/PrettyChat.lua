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

-- The panel-open is LibKa0s-Options-1.0's, and this is a one-line delegate rather
-- than a second implementation beside it — options-ui-§2 is explicit that the
-- combat gate lives INSIDE the panel-open function so every caller is gated, and
-- that a host MUST NOT wire a second, un-gated open path around it. The library's
-- version refuses under lockdown with the same gray notice this addon printed
-- (byte for byte — Color.gray IS |cffaaaaaa), logs through the descriptor's debug
-- hook, and does the same private-API category-tree expansion inside a pcall.
--
-- Two host diagnostics were dropped with the old body, both deliberately and both
-- recorded in this repo's GitHub issues (LIBKA0S-04, issue #9): the "could not
-- open settings panel" line on a false return from Settings.OpenToCategory, and
-- the one-time "could not auto-expand the sub-tree" notice. The library reports
-- neither, and inventing a second open path to keep them is the thing
-- options-ui-§2 forbids.
function PrettyChat:OpenConfig()
    NS.Helpers.OpenOptionsPanel()
end
