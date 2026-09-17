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
    --
    -- A FRESH TABLE, not an alias onto NS.ProfileDefaults. `local defaults =
    -- NS.ProfileDefaults` followed by a write is the same table under two names,
    -- and the published one then means "the profile defaults" before this line
    -- and "the profile defaults plus whatever Database wanted merged" after it.
    -- Nothing else reads NS.ProfileDefaults today, which is precisely why the
    -- divergence would sit there until the first reader arrived. The copy is
    -- shallow on purpose: AceDB is handed the same `profile` sub-table either
    -- way, so what is being protected here is the published table's KEY SET.
    local defaults = {}
    for k, v in pairs(NS.ProfileDefaults) do defaults[k] = v end
    if NS.Database and NS.Database.defaults then
        for k, v in pairs(NS.Database.defaults) do
            if defaults[k] == nil then defaults[k] = v end
        end
    end

    self.db = LibStub("AceDB-3.0"):New("PrettyChatDB", defaults, true)

    if NS.Database and NS.Database.RunMigrations then
        NS.Database.RunMigrations(self.db)
    end

    -- PROFILE CALLBACKS, and this addon had none.
    --
    -- Every override this addon applies is READ from db.profile and WRITTEN onto a
    -- Blizzard global. Switching, copying or resetting a profile replaces every
    -- stored value at once, and nothing here reacted: the chat strings on screen
    -- stayed the OUTGOING profile's until something else happened to call
    -- ApplyStrings, and an open settings panel kept showing values that were no
    -- longer stored. It went unnoticed because nothing in this addon switched
    -- profiles -- until options-ui-§12 made the GLOBAL RESET a profile reset,
    -- which fires the same event and needs the same reaction.
    --
    -- The migrations run first, because a copied profile may have been authored at
    -- an older schema version, and ApplyStrings must not read a shape that has not
    -- been brought forward yet.
    --
    -- ONE BODY, THREE LINES. The work is identical for all three events (the
    -- shared reloadProfile below); only the one debug line differs, worded by the
    -- event (debug-logging-§10). Each handler is a method so a suite can drive it
    -- with AceDB's real callback arguments.
    if self.db.RegisterCallback then
        self.db.RegisterCallback(self, "OnProfileChanged", function(...) self:OnProfileChanged(...) end)
        self.db.RegisterCallback(self, "OnProfileCopied",  function(...) self:OnProfileCopied(...) end)
        self.db.RegisterCallback(self, "OnProfileReset",   function(...) self:OnProfileReset(...) end)
    end

    self:RegisterChatCommand("pc", "OnSlashCommand")
    self:RegisterChatCommand("prettychat", "OnSlashCommand")
end

-- The reaction every profile event shares: bring the incoming profile forward,
-- re-arm the combat watcher, re-apply every string and redraw the panel. Returns
-- ApplyStrings' (applied, restored) counts.
local function reloadProfile(self)
    if NS.Database and NS.Database.RunMigrations then
        NS.Database.RunMigrations(self.db)
    end
    -- THE LATCH FIRST, because a profile switch can flip the enable path with no
    -- verb and no checkbox touched, and slash-commands-§7 makes re-evaluating it on
    -- these three callbacks a MUST — a player switching to a profile where the addon
    -- is enabled expects it to come up. `Set` takes or releases the `disabled` hold
    -- from the INCOMING profile's stored value; `Reevaluate` then fires an arm only
    -- if the new profile actually disagrees with the old one, and nothing at all if
    -- it does not. Neither is a bare stand-up: a `perf` hold taken for this session
    -- survives the switch and keeps the addon down, which is the trap the latch
    -- exists for.
    NS.Lifecycle:Set(NS.HOLD_DISABLED, not self:IsAddonEnabled())
    NS.Lifecycle:Reevaluate()
    -- Then the rest of the incoming profile, which the latch knows nothing about:
    -- the visibility mode the combat watcher has to be armed for, and every
    -- per-string format. Reapply is idempotent and is the same body both latch arms
    -- run, so on an edge this is a second pass over settings that already agree
    -- rather than a second mechanism that might not.
    return self.Reapply()
end

local function activeProfile(self)
    local db = self.db
    return db and db.GetCurrentProfile and db:GetCurrentProfile() or "?"
end

-- A switch rewrites no rows, so it keeps its [Profile] trace and the apply counts
-- (debug-logging-§10).
function PrettyChat:OnProfileChanged()
    local applied, restored = reloadProfile(self)
    NS.Debug("Profile", "switched \226\134\146 applied %d restored %d", applied, restored)
end

-- AceDB fires OnProfileCopied(event, db, sourceProfileKey); the copy lands in the
-- active profile. One [Set] line, and nothing else logs the copy. A reload that
-- raises still writes it, ending in Util.STOPPED, and the error goes on up.
function PrettyChat:OnProfileCopied(_, _, source)
    local function line(suffix)
        NS.Debug("Set", "copied profile '%s' \226\134\146 '%s'%s",
                 tostring(source), activeProfile(self), suffix)
    end
    NS.Util.RunAct(function() reloadProfile(self) end, function() line(NS.Util.STOPPED) end)
    line("")
end

--- N for the profile-reset line: the rows the wipe ACTUALLY rewrote.
---
--- MEASURED, NOT PREDICTED, and the difference is the point. The parked count is
--- taken before the wipe, because nothing can count a change after it has
--- happened — but it counts every stored row that differed from its default, and
--- a PROFILE reset does not reach every stored row. `global.minimap.hide` is
--- stored outside the profile deliberately (launcher-§3): a player's
--- minimap-button choice is a per-installation display preference, in the same
--- class as the angle they dragged the button to, and it survives this reset. A
--- line claiming the reset rewrote that row is the ledger saying the opposite of
--- what the store says, and it read `(2 rows)` for a one-row reset whenever the
--- button was hidden.
---
--- So the answer is the parked count less what still differs once the wipe has
--- landed. That needs no list of which rows are out of reach and stays right when
--- the next one is added — and it is the formula modules/Override.lua's ResetAll
--- already uses on the path where this handler never ran, so the two spellings of
--- one number become one.
local function rowsRewritten(pending)
    local ok, left = pcall(NS.Schema.CountChangedRows)
    if not ok then return pending.rows end
    return math.max(0, pending.rows - left)
end

-- A profile reset's one line, written here whether the reload finishes or raises
-- (then ending in Util.STOPPED). PrettyChat:ResetAll parks `pendingReset` before it
-- starts: the count of rows the wipe changes, which by now has happened, and a
-- `logged` flag this sets so ResetAll never writes a second line. A reset AceDB
-- starts on its own has no count, and the line omits it rather than guess
-- (debug-logging-§10: where cheap).
function PrettyChat:OnProfileReset()
    local pending = self.pendingReset
    local function line(suffix)
        if pending then
            pending.logged = true
            NS.Debug("Set", "reset profile '%s' to defaults (%d rows)%s",
                     activeProfile(self), rowsRewritten(pending), suffix)
        else
            NS.Debug("Set", "reset profile '%s' to defaults%s", activeProfile(self), suffix)
        end
    end
    NS.Util.RunAct(function() reloadProfile(self) end, function() line(NS.Util.STOPPED) end)
    line("")
end

--- Take this client's pristine value for every registered global.
---
--- Its own method rather than four lines inside OnEnable because the snapshot is
--- what modules/Override.lua's restore arm consults, and a restore is only ever
--- as good as what was recorded here.
---
--- TWO TABLES, AND THE SECOND ONE IS THE POINT (PC-R-07). `originalStrings` holds
--- the values; `snapshotKeys` holds the fact that the pass looked. They cannot be
--- one table, because the pristine value of a global THIS client does not define
--- is nil, and nil is also what an absent entry looks like. The restore arm used
--- to read the value's truthiness and so could not tell "the client never had
--- this string" from "we never recorded it" -- and answered the first with the
--- behaviour owed to the second, leaving the override in place until a /reload.
--- Blizzard retires and renames GLOBALNAMEs every expansion, so that is the
--- ordinary case on any client older or newer than the defaults were written for.
function PrettyChat:SnapshotOriginals()
    self.originalStrings = {}
    self.snapshotKeys    = {}
    for _, catData in pairs(NS.Defaults) do
        for globalName in pairs(catData.strings) do
            self.originalStrings[globalName] = _G[globalName]
            self.snapshotKeys[globalName]    = true
        end
    end
end

function PrettyChat:OnEnable()
    self:SnapshotOriginals()

    -- THE LATCH, ARMED FROM THE STORED PATH (slash-commands-§7). `disabled` is the
    -- persisted hold — surviving a /reload is the entire point of the setting — so
    -- it is re-taken here, at load, from `General.enabled`. This is not a special
    -- case: it is the same `Set` call the checkbox and `/pc enable` make.
    --
    -- Then the bring-up, and the guard on it is load-bearing. Taking the hold
    -- already fired `standDown` (empty -> non-empty is an edge); an empty hold set
    -- is NOT an edge, so nothing ran, and something has to arm the combat watcher
    -- and write the overrides for the enabled install. Calling the arm directly is
    -- safe here and nowhere else, because `IsDown()` has just answered false — the
    -- thing §7 forbids is a stand-up that IGNORES a hold somebody else is holding.
    NS.Lifecycle:Set(NS.HOLD_DISABLED, not self:IsAddonEnabled())
    if not NS.Lifecycle:IsDown() then
        -- A stored General visibility of `inCombat` / `outOfCombat` arms the combat
        -- watcher for this session; `always` and `never` arm nothing at all, so the
        -- default install still registers no combat event (modules/Override.lua).
        self.StandUp()
    end

    -- Settings.RegisterCanvasLayoutCategory is allowed in OnEnable for a
    -- non-LoD addon (OnEnable fires after the Settings API is live and
    -- after PLAYER_LOGIN). Folding panel registration into the AceAddon
    -- lifecycle removes Panel.lua's parallel PLAYER_LOGIN bootstrap.
    if NS.Config and NS.Config.RegisterPanels then
        NS.Config.RegisterPanels()
    end

    -- The launcher (launcher-§1). REGISTERED HERE rather than in
    -- core/LauncherSetup.lua, where the object is built, because Register
    -- resolves the broker libraries and the `minimap` table at CALL time and
    -- db.global.minimap does not exist until AceDB has run in OnInitialize
    -- above. Idempotent, so this cannot build a second button over the first.
    --
    -- Guarded on NS.Launcher rather than answered by a stub: nothing else in
    -- this addon calls into the launcher except settings/Schema.lua's minimap
    -- row, which guards the same way (see core/LauncherSetup.lua's header).
    --
    -- Deliberately OUTSIDE IsAddonEnabled: the button and the dispatcher are
    -- SETUP, not features. A disabled addon that drew no button would leave the
    -- player the settings panel they were trying not to open as the only way
    -- back (slash-commands-§2's one-way-switch rule, and the same reason
    -- OnInitialize registers /pc unconditionally).
    if NS.Launcher then NS.Launcher:Register() end
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
