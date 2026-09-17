local addonName, NS = ...

-- core/LifecycleSetup.lua — the ONE latch this addon is stood down by
-- (LibKa0s-Lifecycle-1.0, slash-commands-§7).
--
-- ── WHY A LATCH AND NOT THE BOOLEAN THAT WAS HERE ───────────────────────────
--
-- Until this file existed, "disabled" was a DRAW GATE: `PrettyChat:IsAddonEnabled()`
-- was read as one rung of ApplyStrings' ladder, so the Blizzard originals came back
-- and NOTHING ELSE CHANGED. The combat watcher stayed registered for
-- PLAYER_REGEN_DISABLED / PLAYER_REGEN_ENABLED whenever a combat-scoped visibility
-- was stored, and every combat boundary went on waking this addon up to walk 79
-- globals and decide to restore them again — on an addon the player had switched
-- off. From outside that is indistinguishable from standing down, which is exactly
-- how the shape survived every audit (anti-pattern #85). The addon had not stopped
-- watching; it had stopped reacting, and it still paid the dispatch.
--
-- So the gate moved: the show ladder now reads THE LATCH, and the latch's stand-down
-- arm actually unregisters. Hiding at the source rather than imperatively is the
-- rule's own wording, and it is what keeps the visibility row from re-arming the
-- watcher behind the switch's back.
--
-- ── TWO HOLDS, AND THIS ADDON ONLY EVER TAKES ONE ───────────────────────────
--
-- The library's key space is `disabled` (taken from the stored enable path) and
-- `perf` (taken by LibKa0s-Perf-1.0 for a capture's suspended arm). PrettyChat holds
-- a recorded `performance-§12` no-combat-path exemption — the register row is in
-- docs/ARCHITECTURE.md and the sweep in docs/performance.md — so it builds no Perf
-- instance and NOTHING in this addon ever takes the `perf` hold. That is not a
-- reason to skip the latch: the whole point of the latch is that the two holds are
-- independent, and an addon that wired a bare boolean because it happens to have one
-- hold today is an addon that resurrects itself mid-capture on the day the harness is
-- armed. tests/test_disabled.lua drives BOTH holds through this instance to pin it.
--
-- ── WHAT STANDS DOWN, AND WHAT DOES NOT ─────────────────────────────────────
--
-- Down: the combat watcher's two event registrations (modules/Override.lua's
-- SyncCombatWatch, which reads this latch), and every `_G[GLOBALNAME]` override
-- restored to this client's pristine value. There is nothing else — this addon arms
-- no AceTimer, no C_Timer ticker and no OnUpdate, it registers no message and no
-- bucket, it draws no display frame (it is `frameless`; its display IS the chat text),
-- and it installs no hook, secure or otherwise. It also performs NO secure or
-- attribute work, so slash-commands-§7's combat-lockdown carve-out has nothing to
-- defer: rewriting a global string is not a protected operation and needs no
-- PLAYER_REGEN_ENABLED completion.
--
-- Up (SETUP, not features — it comes up on load in either state and stays up): the
-- `/pc` and `/prettychat` chat commands and the whole dispatcher, the settings
-- category registration and its panel body, the AceDB handle with its single write
-- seam and its three profile callbacks, and the launcher's broker object and minimap
-- button.
--
-- ── DEGRADED INSTALL ────────────────────────────────────────────────────────
--
-- No LibKa0s means no latch, and the stub below answers the whole instance surface
-- so that every caller — the show ladder, the enable row, the profile callbacks —
-- keeps working. It holds the set honestly and calls the same two arms, because the
-- alternative is an addon whose master switch does nothing on precisely the install
-- the stub exists for. What it does not do is re-implement `Reevaluate`'s edge
-- bookkeeping in some other shape: it is the same three lines the library has.
--
-- TOC slot: after core/DebugLogSetup.lua (NS.Debug, which the arms trace through)
-- and before core/LauncherSetup.lua. Nothing here resolves at load beyond the
-- LibStub lookup — the arms reach PrettyChat through closures at CALL time — so the
-- position is conventional rather than load-bearing.

local Lifecycle = LibStub and LibStub("LibKa0s-Lifecycle-1.0", true)

-- The arms, late-bound. modules/Override.lua defines both methods and loads after
-- this file; capturing them here would freeze a nil.
local function standDown() NS.StandDown() end
local function standUp()   NS.StandUp()   end

if not Lifecycle then
    local holds, taken, down = {}, 0, false
    local function edge()
        local wanted = taken > 0
        if wanted == down then return false end
        down = wanted
        if wanted then standDown() else standUp() end
        return true
    end
    NS.Lifecycle = {
        name = addonName,
        Hold = function(_, key)
            if holds[key] then return false end
            holds[key], taken = true, taken + 1
            return edge()
        end,
        Release = function(_, key)
            if not holds[key] then return false end
            holds[key], taken = nil, taken - 1
            return edge()
        end,
        Set = function(self, key, held)
            if held then return self:Hold(key) end
            return self:Release(key)
        end,
        IsHeld = function(_, key) return holds[key] and true or false end,
        IsDown = function() return taken > 0 end,
        Holds  = function()
            local out = {}
            for key in pairs(holds) do out[#out + 1] = key end
            table.sort(out)
            return out
        end,
        Reevaluate = function() return edge() end,
        -- ANSWERS FALSE, ALWAYS, and that is the same rule core/DebugLogSetup.lua's
        -- stub follows for the line formatters: the wording of the one line this
        -- library ever prints is the LIBRARY'S, and a stub copy of it would be a
        -- second place the collection's phrasing can drift. `false` is the answer
        -- the library itself gives a host that passed no printer, so the shape is
        -- one a caller already has to handle. Nothing in this addon calls it.
        PrintHolds = function() return false end,
    }
    -- The two keys are exported by the library rather than typed at each call site,
    -- and the stub exports them for the same reason: fourteen spellings is thirteen
    -- chances to write "Perf" and take a hold nothing releases.
    NS.HOLD_DISABLED, NS.HOLD_PERF = "disabled", "perf"
    return
end

NS.HOLD_DISABLED, NS.HOLD_PERF = Lifecycle.HOLD_DISABLED, Lifecycle.HOLD_PERF

NS.Lifecycle = Lifecycle:New({
    -- The FOLDER name. Diagnostic only — nothing in the library branches on it.
    name = addonName,

    standDown = standDown,
    standUp   = standUp,

    -- Used ONLY by :PrintHolds(), which nothing in this addon calls today. Passed
    -- anyway: the member answers `false` with no printer, and a diagnostic that
    -- silently declines to say anything is worse than one that was never wired.
    print = function(line) NS.Print(line) end,

    -- No `L`: this library's one line is the collection's, and NS.L answers every
    -- key with the key itself (anti-pattern #2). Nothing to translate, nothing passed.
})
