# Performance sweep

The evidence behind the `performance-§12` no-combat-path exemption that [performance.md](./performance.md)
summarizes and the `performance-§12` row of
[`## Documented deviations`](./ARCHITECTURE.md#documented-deviations) ratifies: the committed
whole-repo sweep that proves criterion (a), and the one load-time cost that was measured and removed.
Moved here from `performance.md` so that page fits one screen (`documentation-§3`); the prose moved
verbatim, and the result block below was re-taken on the LibKa0s v1.56.0 tree at the same commit.

## The sweep — criterion (a), proven rather than asserted

`performance-§12` makes criterion (a) — *no `OnUpdate` handler, no repeating ticker, and no event
handler doing more than occasional work while the player is in combat* — provable only by a
**committed whole-repo sweep**. This is it. Re-run it from the repo root; it is the thing to re-run
before trusting this page.

```sh
grep -rEn 'RegisterEvent|RegisterUnitEvent|RegisterAllEvents|SetScript\("On(Update|Event)"|C_Timer|ScheduleRepeatingTimer|ScheduleTimer|NewTicker' \
  . --exclude-dir=.git --exclude-dir=libs --exclude-dir=_kit --exclude-dir=GlobalStrings \
    --exclude-dir=docs
```

`docs/` is excluded **because this page is inside it**. Without that exclusion the sweep matches its
own prose, and every edit to the page shifts the line numbers the page prints — a result that cannot
reproduce by construction, which is exactly the failure this page exists to prevent. The frozen
evidence bundles that used to be excluded by name (`audits/`, `reviews/`, `automated-tests/`) live
under `docs/` and are covered by it. The rest are the vendored payloads (`libs/`, `tests/_kit/`) and
the generated data (`GlobalStrings/`). **Nothing that ships is excluded**, and `tests/` is deliberately
still in scope.

Result, verbatim, at the commit that carries this page — **forty lines across eleven files**, sorted
by file and line:

```
.luacheckrc:60:    "C_Timer",
core/CoreSetup.lua:54:    -- and the three one-rung Util.SafeRegisterEvent / SafeRegisterUnitEvent /
core/CoreSetup.lua:55:    -- SafeRegisterEvents bodies (tests/test_surface_parity.lua pins the set).
core/CoreSetup.lua:114:    function Util.SafeRegisterEvent(target, event, handler, rejected)
core/CoreSetup.lua:115:        local ok = pcall(target.RegisterEvent, target, event, handler)
core/CoreSetup.lua:119:    function Util.SafeRegisterUnitEvent(frame, event, rejected, unit1, unit2)
core/CoreSetup.lua:120:        local ok = pcall(frame.RegisterUnitEvent, frame, event, unit1, unit2)
core/CoreSetup.lua:124:    function Util.SafeRegisterEvents(target, events, handler, rejected)
core/CoreSetup.lua:127:            if Util.SafeRegisterEvent(target, event, handler, rejected) then n = n + 1 end
core/CoreSetup.lua:140:Util.SafeRegisterEvent     = lib.SafeRegisterEvent
core/CoreSetup.lua:141:Util.SafeRegisterUnitEvent = lib.SafeRegisterUnitEvent
core/CoreSetup.lua:142:Util.SafeRegisterEvents    = lib.SafeRegisterEvents
core/LifecycleSetup.lua:40:-- no AceTimer, no C_Timer ticker and no OnUpdate, it registers no message and no
modules/Override.lua:126:-- Registration goes through LibKa0s-Core's SafeRegisterEvents (bound as
modules/Override.lua:127:-- NS.Util.SafeRegisterEvents by core/CoreSetup.lua): the C_EventUtils.IsEventValid
modules/Override.lua:157:        combatWatcher:SetScript("OnEvent", function()
modules/Override.lua:174:    local n = NS.Util.SafeRegisterEvents(combatWatcher, WATCH_EVENTS, nil, NS.RejectedEvents)
settings/Panel.lua:528:    -- A frame later, both are true. C_Timer.After(0, ...) is the client's own way
settings/Panel.lua:531:    if C_Timer and C_Timer.After then
settings/Panel.lua:532:        C_Timer.After(0, function() fitTree(ctx) end)
tests/test_disabled.lua:28:-- arms no AceTimer, no C_Timer ticker and no OnUpdate, registers no message and no
tests/test_libka0s.lua:739:test("degraded SafeRegisterEvents records a rejected name and registers the rest", function()
tests/test_libka0s.lua:741:    -- (the call raises on nil), call target:RegisterEvent without the pcall (the bad
tests/test_libka0s.lua:752:    local ok, n = pcall(Util.SafeRegisterEvents, frame, events, nil, rejected)
tests/test_libka0s.lua:764:    t.eq(Util.SafeRegisterEvents(frame, events, nil, rejected), 1, "a second walk answers the same")
tests/test_libka0s.lua:766:    t.falsy(Util.SafeRegisterEvent(frame, "PLAYER_REGEN_DISABLED"), "one name answers false with no list")
tests/test_libka0s.lua:767:    t.truthy(Util.SafeRegisterUnitEvent(frame, "UNIT_HEALTH", rejected, "player"), "the unit form registers")
tests/test_libka0s.lua:768:    t.falsy(Util.SafeRegisterUnitEvent(frame, "PLAYER_REGEN_DISABLED", rejected, "player"),
tests/test_override.lua:250:-- Both names go through NS.Util.SafeRegisterEvents (LibKa0s-Core), so a name the
tests/test_override.lua:254:-- A fresh instance whose client refuses `name` at the frame's RegisterEvent and,
tests/test_override.lua:283:test("IsEventValid rejects a name without calling RegisterEvent", function()
tests/test_override.lua:295:    t.nilv(live.PLAYER_REGEN_ENABLED, "the gated name never reached RegisterEvent")
tests/test_panel.lua:673:-- red under: dropping the C_Timer.After, or scheduling it per render without the
tests/test_surface_parity.lua:111:        SafeRegisterEvent     = instance.NS.Util.SafeRegisterEvent,
tests/test_surface_parity.lua:112:        SafeRegisterUnitEvent = instance.NS.Util.SafeRegisterUnitEvent,
tests/test_surface_parity.lua:113:        SafeRegisterEvents    = instance.NS.Util.SafeRegisterEvents,
tests/test_surface_parity.lua:121:                          "SafeRegisterEvent", "SafeRegisterUnitEvent", "SafeRegisterEvents" }) do
tests/wow_mock.lua:72:--  15.  frame RegisterEvent / UnregisterEvent
tests/wow_mock.lua:134:-- The EVENT methods are therefore the kit's, not this file's: `RegisterEvent`,
tests/wow_mock.lua:135:-- `UnregisterEvent`, `IsEventRegistered`, `RegisterUnitEvent` and
```

Reconciled, so a future drift is visible rather than arguable. One is a lint declaration
(`.luacheckrc:60`). Fourteen are the pattern names appearing **inside comments** — `core/CoreSetup.lua:54`,
`:55`, `core/LifecycleSetup.lua:40`, `modules/Override.lua:126`, `:127`, `settings/Panel.lua:528`,
`tests/test_disabled.lua:28`, `tests/test_libka0s.lua:741`, `tests/test_override.lua:250`, `:254`,
`tests/test_panel.lua:673` and `tests/wow_mock.lua:72`, `:134`, `:135` — which describe the discipline
rather than doing anything; the harness mock no longer defines its own `RegisterEvent`, because the
frame event methods are the kit's. Nine are `core/CoreSetup.lua`'s `SafeRegisterEvent` /
`SafeRegisterUnitEvent` / `SafeRegisterEvents` surface (`:114`-`:127`, the degraded arm's one-rung
bodies, and `:140`-`:142`, the binds to `LibKa0s-Core`'s own): wrappers that subscribe nothing until a
caller hands them a frame, and the only caller is the combat watcher. Twelve are suite code that
drives those wrappers or pins the watcher (`tests/test_libka0s.lua`, `tests/test_override.lua`,
`tests/test_surface_parity.lua`). The remaining **four are call sites in shipped code**, and they are
the two sections below: the combat watcher, and one next-frame layout fit in the settings panel.

One thing the grep does *not* return, said out loud so nobody re-adds it: `combatWatcher:UnregisterAllEvents`
at `modules/Override.lua:171` **does not match**, because the pattern spells `RegisterAllEvents` with a
capital R and `UnregisterAllEvents` spells it lowercase. An earlier revision of this page printed that
line inside its result block; the command above cannot produce it, and a result block holding a line
its own command cannot return is worse than no result block at all.

**Zero `SetScript("OnUpdate"`, zero ticker, zero repeating timer** anywhere in `core/`, `defaults/`,
`locales/`, `modules/`, `settings/` or the TOC. That is the part of the old claim that survives.
What does not survive is *"zero `C_Timer` call"*: `.luacheckrc:60` declares `C_Timer` in
`read_globals`, and since 2026-09-03 that declaration has a real consumer.

### The combat watcher — `modules/Override.lua:157`, `:174`

Both hits are `PrettyChat:SyncCombatWatch`, and what matters about them is *when they are reached*:

- the frame is **created lazily**, on the first write that stores `General.visibility` as `inCombat`
  or `outOfCombat`. A default install (`always`) creates no frame and registers no event, so on the
  shipped configuration this half of the sweep's runtime answer is still zero;
- both events are **unregistered** the moment the mode leaves that pair (`modules/Override.lua:171`),
  so the subscription tracks the setting rather than outliving it;
- the handler fires at the combat **boundary** — `PLAYER_REGEN_DISABLED` on entry,
  `PLAYER_REGEN_ENABLED` on exit — at most twice per fight, and never *during* one. Its whole body is
  one `ApplyStrings` pass (~170 table writes, no allocation per string) and one gated debug line.

`tests/test_override.lua` pins all three: no frame on a default load, both events registered on a
combat-scoped write, both dropped on the way back out.

### The settings panel's next-frame fit — `settings/Panel.lua:531-532`

**A guarded one-shot `C_Timer.After(0, …)` on the settings-panel render path, and nothing else.** It
arrived on 2026-09-03 with the string-list revamp (`92c43f5`), after this page's sweep was last taken,
which is why the page went on asserting zero. Its disposition:

- **Where it is reached from.** `buildCategoryBody` only — the render of a Categories page inside the
  options panel. Not `OnInitialize`, not `OnEnable`, not `ApplyStrings`, not the combat watcher.
  Reaching it at all takes a player opening the settings panel and selecting a category, and
  `LibKa0s-Options-1.0`'s `OpenOptionsPanel` refuses to open under `InCombatLockdown()`, and a page
  reached from the sidebar in combat is covered and never renders
  ([ARCHITECTURE.md § Taint Notes](./ARCHITECTURE.md#taint-notes)), so no render reaches it during a
  fight.
- **What it is for.** The AceGUI `TreeGroup` cannot be sized during the render that builds it: the
  scroll frame takes its height when the page's chrome is anchored, *earlier in the same render*, and
  AceGUI has not laid the tree out yet, so there is no position to measure from. `C_Timer.After(0, …)`
  is the client's own idiom for *after this frame's layout*, and it is the pass that actually sizes
  the box. The two-pass reasoning is at [settings-panel.md](./settings-panel.md) and in-code above
  the call.
- **What it costs.** One callback, one frame later. `fitTree` reads two heights and does at most one
  `SetHeight`, behind a change guard so re-rendering the same tree does not queue a stack of resizes.
  It is guarded on `C_Timer and C_Timer.After` so the panel still loads on a client that answers
  nothing for the API.
- **Why it does not touch criterion (a).** Criterion (a) names three things: an `OnUpdate` handler, a
  repeating ticker, and an event handler doing more than occasional work while the player is in
  combat. A one-shot next-frame hop off a UI render is none of the three. Even in the one residual
  case — a panel already open when a pull starts, re-rendered mid-fight — the work is a single
  deferred layout measurement, not per-frame and not repeating, and it schedules exactly one
  callback per render rather than one per category click.

`tests/test_panel.lua:675` pins it: the render schedules exactly one fit for the following frame, and
the case goes red if the hop is dropped or if the change guard stops holding.

The addon's other lifecycle hooks are the two AceAddon callbacks in [performance.md](./performance.md)'s runtime table. Both run at login, neither
repeats, and neither can be reached while the player is in combat.


## The one load-time cost that was measured, and removed (PC-R-05)

`performance-§9` is about what an addon makes the client do at load, and this addon had exactly one
such cost worth naming: `PrettyChat.toc` eagerly loaded the 26 generated `GlobalStrings/` chunks —
1.89 MB, 22,879 entries — to populate `NS.GlobalStrings`. Its **only** reader was the settings
panel's read-only "Original" box, which now reads this client's `OnEnable` snapshot instead
(PC-R-04). Zero readers, full cost, at every login.

Measured before removal on the repo's own toolchain (`lua5.1`, mean of five cold runs; the client
runs the same Lua 5.1, so read these as the order of magnitude rather than as client figures):

| | Before | After |
|---|---|---|
| The addon's own files in the TOC (excluding `libs/`) | 43 | 17 |
| Bytes of those files parsed at load | 2.01 MB | 123 KB |
| `loadfile` over the 26 chunks | 24.3 ms | — |
| Executing the 26 chunks | 2.1 ms | — |
| **Load-time total attributable to the dump** | **26.4 ms** | **0 ms** |
| Resident Lua heap for `NS.GlobalStrings` | ~1.25 MB | 0 |
| Rebuild of one full addon instance in the harness (chunks already compiled) | 3.4 ms | 0.7 ms |

Reproduce the harness figure with `tests/loader.lua`: build N instances with and without the
`GlobalStrings/` entries in the TOC-derived file list and compare `os.clock()`. The compile figure is
`loadfile` over `GlobalStrings/GlobalStrings_0NN.lua`, cold, averaged.

Nothing about what the panel can display changed: the snapshot covers every key `NS.Defaults`
mentions, which is every key any surface draws. See [global-strings.md](./global-strings.md).

