-- tests/test_disabled.lua — THE STAND-DOWN CONFORMANCE SUITE (slash-commands-§7).
--
-- WHAT THIS SUITE IS FOR, AND WHAT IT REFUSES TO BE.
--
-- "Disabled" means the addon is NOT RUNNING. Not hidden, not quiet, not skipping a
-- repaint — not running. It stops drawing, it stops watching, it stops writing, and
-- the only thing left alive is the surface that can turn it back on. Eleven addons
-- in this collection implemented that as a DRAW GATE instead: a stored boolean read
-- as one rung of a show ladder, handlers that early-return, and every event, message
-- and bucket the addon owns still registered. The client then goes on walking the
-- registration list, building the argument frame and entering Lua on every event, to
-- run the comparison that decides to leave — which is precisely the cost a player
-- switching the addon off is trying to stop paying, and it is invisible from every
-- surface they can see (anti-pattern #85).
--
-- THAT IS WHY EVERY ASSERTION BELOW IS MADE AGAINST THE REGISTRATION SET, through
-- the kit's recording mock, and never against a handler's return value. A suite that
-- called a handler and asserted it returned early would CERTIFY the draw gate it
-- exists to catch: an early return is what a draw gate does. `M.__registrations()`
-- reports what the client would actually dispatch to, and the mock REMOVES entries
-- on unregister, which is the half that makes the assertion falsifiable in the
-- useful direction.
--
-- THIS ADDON IN PARTICULAR. PrettyChat is frameless: its display is the chat text it
-- rewrites, so `_G[GLOBALNAME]` is its screen and the Blizzard original is its blank
-- one. It owns exactly one frame that ever registers anything — the combat watcher,
-- lazily built and armed only while a combat-scoped visibility is stored — and it
-- arms no AceTimer, no C_Timer ticker and no OnUpdate, registers no message and no
-- bucket, and installs no hook of any kind. So the suite's steps 4 and 5 are thin
-- HERE and are still written out: an addon that grows a timer later has a case
-- waiting for it, and a step that was never written is a step nobody notices is
-- missing.
--
-- STEP 1 ARMS THE WATCHER ON PURPOSE. A default install stores `visibility =
-- always`, which registers nothing at all — and §7 is explicit that a baseline
-- registration set which is empty makes every later assertion pass trivially. So the
-- baseline stores a combat-scoped visibility first, which is an ordinary player
-- setting and the only one this addon has that registers anything.

local ctx  = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local ENABLED_PATH    = "General.enabled"
local VISIBILITY_PATH = "General.visibility"

-- The two events the combat watcher takes, named here so a case can fire them at a
-- target whose registration is gone (step 6).
local COMBAT_EVENTS = { "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }

-- ── surveys ─────────────────────────────────────────────────────────────────
--
-- `{ target, kind, event, unit }` rows are not comparable across two calls by
-- identity, so every comparison below goes through one stable key per row. The frame
-- contributes its name, so a registration that MOVED to another frame is a
-- difference rather than a match.
local function regKey(r)
    local target = r.target
    local name = (type(target) == "table" and (target._name or target.name)) or "?"
    return ("%s|%s|%s|%s"):format(tostring(name), r.kind, tostring(r.event), tostring(r.unit))
end

local function regSet(env)
    local out, list = {}, env.__registrations()
    for i = 1, #list do out[#out + 1] = regKey(list[i]) end
    table.sort(out)
    return out
end

local function sameSet(got, want)
    if #got ~= #want then return false end
    for i = 1, #got do
        if got[i] ~= want[i] then return false end
    end
    return true
end

local function show(list) return "{" .. table.concat(list, ", ") .. "}" end

-- Every override this addon can write, with the pristine value the loader seeded.
-- This is the addon's SCREEN: "every frame hidden" for a frameless addon whose
-- display is the chat text means every global back to what the client shipped.
local function overridesLive(inst)
    local n = 0
    for _, category in ipairs(inst.NS.Schema.CATEGORY_ORDER) do
        local catData = inst.NS.Defaults[category]
        for globalName in pairs((catData and catData.strings) or {}) do
            local live = inst.env[globalName]
            if live ~= nil and live ~= ("ORIG:" .. globalName) then n = n + 1 end
        end
    end
    return n
end

-- Every OnUpdate script still attached to any frame this build made.
local function onUpdates(env)
    local n = 0
    for _, f in ipairs(env._frames.all) do
        if rawget(f, "__scripts") and f.__scripts.OnUpdate then n = n + 1 end
    end
    return n
end

local function watcher(inst) return inst.env._frames.byName["PrettyChatCombatWatcher"] end

-- ── the fixture ─────────────────────────────────────────────────────────────
--
-- A fresh instance per case. The subject is a TRANSITION, and a case that inherited
-- another's latch state would be asserting on whatever ran before it in the
-- inventory rather than on the write it made itself.
-- The two broker fakes, registered through the mock's own LibStub:NewLibrary so the
-- library resolves them exactly as it resolves the vendored LibKa0s modules beside
-- them. Only step 8 needs them; tests/test_launcher.lua carries the same pair and
-- asserts what they recorded, which is that suite's business rather than this one's.
local function withBroker(mocks)
    local ldb = mocks.LibStub:NewLibrary("LibDataBroker-1.1", 4)
    ldb.objects = {}
    function ldb:NewDataObject(name, obj)
        if self.objects[name] then return nil end
        self.objects[name] = obj
        return obj
    end
    function ldb:GetDataObjectByName(name) return self.objects[name] end

    local icons = mocks.LibStub:NewLibrary("LibDBIcon-1.0", 50)
    -- Inert: this suite asserts nothing about WHAT LibDBIcon was told, only that
    -- the object exists and answers its click. tests/test_launcher.lua records both.
    icons.Register = function() end
    icons.Show     = function() end
    icons.Hide     = function() end
end

local function armed(opts)
    local i = ctx.loadAddon(opts)
    -- Never the panel-open itself: OpenOptionsPanel reaches the client's Settings
    -- API, and the cases below want to know THAT it was asked, not to drive it.
    i.opened = 0
    i.NS.Helpers.OpenOptionsPanel = function() i.opened = i.opened + 1 end
    -- Step 1's arming write. An ordinary player setting, through the single write
    -- seam, and the only one this addon has that registers anything.
    --
    -- `outOfCombat` RATHER THAN `inCombat`, and the choice is load-bearing. Both are
    -- combat-scoped, so both arm the watcher — but the mock player is not in combat,
    -- so `inCombat` would leave the addon registered AND showing nothing, and step 5
    -- would then be asserting that a blank screen went blank. `outOfCombat` is the
    -- one stored value under which this addon is simultaneously WATCHING and DRAWING,
    -- which is the only baseline a stand-down is worth measuring against.
    i.NS.Schema.Set(VISIBILITY_PATH, "outOfCombat")
    return i
end

--- Disable through THE SINGLE WRITE SEAM (§7 step 2) — never by calling a teardown
--- function directly. The checkbox, `/pc disable` and `/pc set General.enabled false`
--- all land on this exact call, so driving it is driving the route a player takes.
local function disable(i) i.NS.Schema.Set(ENABLED_PATH, false) end
local function enable(i)  i.NS.Schema.Set(ENABLED_PATH, true)  end

-- ── 1. baseline ─────────────────────────────────────────────────────────────

test("disabled/1: the enabled baseline registers something for the stand-down to remove", function()
    local i = armed()
    local R_on = regSet(i.env)
    -- NON-VACUITY, and §7 calls for it by name: an addon that registered nothing
    -- while enabled would pass every later assertion in this file trivially, and the
    -- suite would be green over a question it never asked.
    t.truthy(#R_on > 0, "the enabled addon holds at least one registration: " .. show(R_on))
    t.eq(#R_on, 2, "the combat watcher's two events, and nothing else")
    t.truthy(watcher(i), "and they are on the watcher this addon names")
    t.eq(#i.env.__timers, 0, "T_on: this addon arms no timer even while running")
    t.eq(onUpdates(i.env), 0, "and no OnUpdate")
end)

-- ── 2 + 3. the registration set is EMPTY ────────────────────────────────────

test("disabled/3: every registration is UNREGISTERED, not gated", function()
    -- red under: drop the `not self:IsStoodDown()` term from SyncCombatWatch's
    -- `wanted` in modules/Override.lua — the addon then goes on watching both combat
    -- events while switched off, which is the draw gate this whole suite exists for
    -- and is exactly what this repo shipped before the latch.
    local i = armed()
    t.eq(#regSet(i.env), 2, "registered before the write")

    disable(i)

    local R_off = regSet(i.env)
    -- BY COUNT and BY NAME, because a count alone passes an addon that dropped one
    -- registration and added another.
    t.eq(#R_off, 0, "nothing is registered any more: " .. show(R_off))
    for _, event in ipairs(COMBAT_EVENTS) do
        t.nilv(watcher(i)._events[event], event .. " is gone from the watcher itself")
    end
end)

-- ── 4. nothing is left armed ────────────────────────────────────────────────

test("disabled/4: no timer, ticker or OnUpdate is left armed", function()
    local i = armed()
    disable(i)
    t.eq(#i.env.__timers, 0, "no timer is queued")
    t.eq(onUpdates(i.env), 0, "no OnUpdate script is attached to any frame")
    -- "and no new one is armed for the rest of the run" — the events are fired at
    -- the watcher unconditionally in step 6; here the cheaper half, a second write.
    i.NS.Schema.Set(VISIBILITY_PATH, "outOfCombat")
    t.eq(#i.env.__timers, 0, "and a settings change while disabled arms none either")
    t.eq(#regSet(i.env), 0, "nor does it re-register anything")
end)

-- ── 5. nothing is drawn ─────────────────────────────────────────────────────

test("disabled/5: nothing is drawn — and for THIS addon that is the globals", function()
    local i = armed()
    local F_on = i.env.__shownFrames()
    t.truthy(overridesLive(i) > 0, "the running addon has its text in the client's globals")

    disable(i)

    -- The frame half. PrettyChat is frameless — it shows nothing while running, so
    -- there is nothing to hide — and the assertion is written anyway, against the
    -- kit's survey, so an addon that grows a display frame later reddens here.
    t.eq(#i.env.__shownFrames(), #F_on, "no frame this addon owns is left shown")
    -- The half that is actually this addon's screen.
    t.eq(overridesLive(i), 0, "every Blizzard original is back — the display is blank")
end)

-- ── 6. a survivor would have been caught ────────────────────────────────────

test("disabled/6: firing the baseline events anyway writes nothing and says nothing", function()
    -- red under: drop the `not self:IsStoodDown()` term from SyncCombatWatch AND the
    -- latch read from ApplyStrings' `addonEnabled` — the OnEvent handler then re-runs
    -- the apply pass and writes this addon's text back over Blizzard's while the
    -- player has it switched off.
    local i = armed()
    disable(i)

    local w = watcher(i)
    i.env.__resetSvWrites()
    i.env.__resetPrinted()
    local shownBefore = #i.env.__shownFrames()

    -- THE CLIENT WOULD NOT FIRE THESE — the registrations are gone. `__fire` over the
    -- live set therefore runs nothing at all, which is true of a conformant addon AND
    -- of a harness that has lost the ability to dispatch. `__fireUnconditional`
    -- reaches the handler ANYWAY, which is what proves a survivor would have been
    -- caught: the OnEvent script is still on the frame, it is simply no longer
    -- reachable from the client.
    for _, event in ipairs(COMBAT_EVENTS) do
        t.eq(i.env.__fire(event), 0, event .. " reaches nobody through the live registry")
        t.eq(i.env.__fireUnconditional(w, event), 1, "but the handler is still there to reach")
    end

    t.eq(#i.env.__svWrites(), 0, "zero SavedVariables writes from a game event")
    t.eq(#i.env.__printed(), 0, "zero lines printed to the player")
    t.eq(#i.env.__shownFrames(), shownBefore, "zero frames shown")
    t.eq(overridesLive(i), 0, "and not one global was overridden again")
    t.eq(#regSet(i.env), 0, "and nothing re-registered itself on the way through")
end)

-- ── 7. the slash surface ────────────────────────────────────────────────────
--
-- NOT THE STAND-DOWN. Steps 1-6 are. A green step 7 says nothing about whether this
-- addon is inert; it says the player can still read their settings and find the
-- switch. The two facts are not in tension — the dispatcher and the settings
-- registration are SETUP, not features, so keeping them live costs nothing the
-- stand-down was trying to reclaim.
--
-- The surface here is the standard's thirteen reserved verbs, ALL ANSWERING, and the
-- bare `/pc` opening the panel. That was narrowed to `enable` and `help` at standard
-- v2.56.0 and REVERSED at v2.57.0, on the first thing anyone tried: `/pc` on a
-- disabled addon answered with a refusal instead of opening the one surface a player
-- uses to switch it back on by hand.

local LIVE_VERBS = {
    help = true, config = true, version = true, enable = true, disable = true,
    debug = true, perf = true, diagnostics = true,
    get = true, set = true, list = true, reset = true, resetall = true,
}

local function say(i, input)
    local from = #i.env.DEFAULT_CHAT_FRAME.messages
    i.addon:OnSlashCommand(input)
    local out = {}
    for n = from + 1, #i.env.DEFAULT_CHAT_FRAME.messages do
        out[#out + 1] = i.env.DEFAULT_CHAT_FRAME.messages[n]
    end
    return out
end

test("disabled/7: every reserved verb answers normally, and the bare /pc opens the panel", function()
    local i = armed()
    disable(i)
    local refusal = i.NS.SlashCommands:DisabledLine()

    local seen = 0
    for _, entry in ipairs(i.NS.COMMANDS) do
        local verb = entry[1]
        if LIVE_VERBS[verb] then
            seen = seen + 1
            local lines = say(i, verb)
            if verb == "help" then
                -- The one live verb that carries the line, and it is not a refusal OF
                -- help: the index prints in full, because the player has to be able
                -- to SEE `enable` in it. The line sits under the header as a
                -- statement ABOUT the index, some of whose rows are feature verbs.
                t.truthy(#lines > #i.NS.COMMANDS, "/pc help prints the whole index while disabled")
            else
                for _, line in ipairs(lines) do
                    t.falsy(line:find(refusal, 1, true),
                        "/pc " .. verb .. " must answer normally while disabled, not refuse")
                end
            end
            -- `enable` and `disable` are live and they WRITE, so put the addon back
            -- where this loop found it before the next verb runs.
            if verb == "enable" then disable(i) end
        end
    end
    t.truthy(seen >= 10, "the loop actually reached the reserved verbs: " .. tostring(seen))

    -- THE CASE THAT SETTLED THE REVERSAL.
    local before = i.opened
    say(i, "")
    t.eq(i.opened, before + 1, "the bare /pc opened the settings panel, disabled and all")
end)

test("disabled/7: the addon's own FEATURE verb refuses on one line and reaches no write seam", function()
    local i = armed()
    disable(i)

    -- The write seam itself, counted. "Does nothing else" is a claim about the store
    -- and not about the chat frame, and a case that read only the line would pass a
    -- verb that printed the refusal and then ran anyway.
    local Schema, writes = i.NS.Schema, 0
    local realSet = Schema.Set
    Schema.Set = function(...) writes = writes + 1; return realSet(...) end

    local lines = say(i, "test")
    Schema.Set = realSet

    t.eq(#lines, 1, "exactly one line — no partial work, no second line")
    -- Matched against the LIBRARY'S line rather than quoted here: the wording is the
    -- collection's, in one place, and a suite that hard-coded it would be a second.
    t.eq(lines[1]:find(i.NS.SlashCommands:DisabledLine(), 1, true) ~= nil, true,
        "and it is the collection's refusal line: " .. tostring(lines[1]))
    t.truthy(lines[1]:find("/pc enable", 1, true), "which names the verb that turns it back on")
    t.eq(writes, 0, "and the verb reached no write seam")
    t.eq(#regSet(i.env), 0, "and registered nothing on its way through")
end)

test("disabled/7: both diagnostics forms write the whole report while disabled, and stand nothing up", function()
    -- red under: pass Slash a `liveVerbs` without `diagnostics`, or gate runDebug's
    -- diagnostics word on IsAddonEnabled -- either refuses the report on the one install a
    -- player is most likely to be sending it from (debug-logging-§14, STD-05). The second
    -- half is red under a report that took or released a Lifecycle hold: the registration
    -- set would come back.
    local i = armed()
    disable(i)
    local D = i.NS.DebugLog
    for _, form in ipairs({ "diagnostics", "debug diagnostics" }) do
        local before = #D.buffer
        say(i, form)
        t.truthy(#D.buffer > before, "/pc " .. form .. " wrote the report while disabled")
        t.truthy(D.buffer[#D.buffer]:find("diagnostics end:", 1, true),
            "/pc " .. form .. " wrote it whole, to the end marker")
        t.truthy(D:FindLine("stoodDown=true"), "and the report says the addon is stood down")
    end
    t.eq(#regSet(i.env), 0, "the report stood nothing up: still no registration")
    t.eq(overridesLive(i), 0, "and wrote not one override")
    t.eq(i.addon:IsAddonEnabled(), false, "and the addon is still disabled")
end)

-- ── 8. the launcher ─────────────────────────────────────────────────────────

test("disabled/8: the launcher works while disabled — panel on LEFT, menu on RIGHT, no writes",
function()
    -- slash-commands-§7 lists the launcher among the SETUP surfaces that survive
    -- the disabled state, and launcher-§2 (v2.67.0) gives both buttons one meaning
    -- in either state: LEFT opens the settings panel, RIGHT the options menu, whose
    -- Enabled entry stays live. Opening either writes nothing and refuses nothing.
    local menu
    local i = armed({ mock = function(mocks)
        withBroker(mocks)
        menu = dofile(ctx.root .. "/tests/mock_menu.lua")(mocks)
    end })
    disable(i)
    local object = i.NS.Launcher:Object()
    t.truthy(object, "the broker object is still registered while disabled")

    local refusal = i.NS.SlashCommands:DisabledLine()
    i.env.__resetSvWrites()
    i.env.__resetPrinted()

    object.OnClick({}, "LeftButton")
    t.eq(i.opened, 1, "LeftButton opened the settings panel")
    object.OnClick({}, "RightButton")
    t.eq(menu.opens, 1, "RightButton opened the options menu")
    t.eq(menu.last:Find("Enabled").enabled, true, "whose Enabled entry is live")
    t.eq(i.opened, 1, "and did not open the panel as well")

    t.eq(#i.env.__svWrites(), 0, "opening either on a disabled addon writes NO SavedVariables")
    for _, line in ipairs(i.env.__printed()) do
        t.falsy(line:find(refusal, 1, true), "and neither button prints the refusal line")
    end
end)

-- ── 9. restoration, from CURRENT state ──────────────────────────────────────

test("disabled/9: re-enabling rebuilds the same registration set", function()
    local i = armed()
    local R_on = regSet(i.env)
    disable(i)
    t.eq(#regSet(i.env), 0, "down")
    enable(i)
    t.truthy(sameSet(regSet(i.env), R_on),
        "the set came back exactly: " .. show(regSet(i.env)) .. " vs " .. show(R_on))
end)

test("disabled/9: the rebuild reads the settings as they are NOW, not as they were", function()
    -- performance-§6's restore-from-current-state rule, applied to the latch. A
    -- stand-up that replayed a snapshot taken on the way down would re-arm the combat
    -- watcher for a visibility the player has since changed.
    local i = armed()
    t.eq(#regSet(i.env), 2, "armed by the combat-scoped visibility")

    disable(i)
    i.NS.Schema.Set(VISIBILITY_PATH, "always")   -- changed WHILE disabled
    enable(i)

    t.eq(#regSet(i.env), 0,
        "the rebuilt set reflects `always`, which registers nothing: " .. show(regSet(i.env)))

    -- And the other direction, so the case cannot pass by simply never re-arming.
    disable(i)
    i.NS.Schema.Set(VISIBILITY_PATH, "inCombat")
    enable(i)
    t.eq(#regSet(i.env), 2, "and a combat mode chosen while disabled arms the watcher on the way up")
end)

-- ── 10. the latch ───────────────────────────────────────────────────────────

test("disabled/10: releasing one hold does not resurrect an addon the other holds down", function()
    -- red under: replace NS.Lifecycle with a bare boolean — a `resume` that writes
    -- false and stands the addon up brings it back to life under a player who
    -- switched it off, and a `disable` that stands it up on its way out ruins a
    -- capture that is still running. That state is the one a boolean cannot carry,
    -- and it is why this is a latch.
    local i = armed()
    local lc = i.NS.Lifecycle
    local R_on = regSet(i.env)

    -- perf first, then disabled.
    lc:Hold(i.NS.HOLD_PERF)
    t.eq(#regSet(i.env), 0, "the perf hold alone stands the addon down")
    disable(i)
    t.truthy(lc:IsHeld(i.NS.HOLD_DISABLED), "and the player's switch takes the second hold")

    lc:Release(i.NS.HOLD_PERF)
    t.eq(#regSet(i.env), 0, "releasing perf leaves it down — `disabled` is still held")
    t.truthy(lc:IsDown(), "and the latch says so")

    enable(i)
    t.truthy(sameSet(regSet(i.env), R_on), "only the LAST release stands it up")
end)

test("disabled/10: and the same with the holds taken in the other order", function()
    local i = armed()
    local lc = i.NS.Lifecycle
    local R_on = regSet(i.env)

    disable(i)
    lc:Hold(i.NS.HOLD_PERF)
    t.eq(#regSet(i.env), 0, "both holds taken, down")

    -- The trap by its own name: `/pc enable` is a LIVE verb, so a player can
    -- re-enable the addon in the middle of a suspended capture arm.
    enable(i)
    t.eq(#regSet(i.env), 0, "re-enabling mid-capture does NOT bring it back")
    t.truthy(lc:IsHeld(i.NS.HOLD_PERF), "because the perf hold is still taken")
    t.falsy(lc:IsHeld(i.NS.HOLD_DISABLED), "while the player's hold is genuinely released")

    lc:Release(i.NS.HOLD_PERF)
    t.truthy(sameSet(regSet(i.env), R_on), "and the capture's own release is what stands it up")
end)

test("disabled/10: the perf hold is session-only and the disabled hold is stored", function()
    local i = armed()
    i.NS.Lifecycle:Hold(i.NS.HOLD_PERF)
    disable(i)
    i.env.__resetSvWrites()
    i.NS.Lifecycle:Release(i.NS.HOLD_PERF)
    -- performance-§6, unchanged in force: the harness releases its OWN hold and
    -- persists nothing. `disabled` is persisted because it IS the stored enable path,
    -- and surviving a /reload is the entire point of that setting — which the write
    -- in step 2 already put in the store.
    t.eq(#i.env.__svWrites(), 0, "releasing the perf hold stored nothing")
    t.eq(i.addon.db.profile.enabled, false, "and the player's own hold is in the file")
end)
