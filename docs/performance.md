# Performance

**Ka0s Pretty Chat brackets nothing, and holds a recorded `performance-§12` no-combat-path
exemption.** This page is the one-screen answer `documentation-§3` still requires: *how much does this
addon cost?* — *nothing measurable while you are playing, and here is how we know.*

The exemption itself is ratified as the `performance-§12` row of
[`## Documented deviations`](./ARCHITECTURE.md#documented-deviations) in `ARCHITECTURE.md`. That row,
not this page, is the record; this page is the evidence behind it.

## Why there is nothing to bracket

PrettyChat's entire mechanism is **overriding `_G[GLOBALNAME]` and letting WoW's own chat code read
it**. It registers no chat filter and hooks no chat frame, so it has no per-message work and no
per-frame work. Its runtime is:

| When | What runs |
|---|---|
| `OnInitialize` | AceDB open, migrations, two `RegisterChatCommand` calls |
| `OnEnable` | one snapshot pass over ~81 Blizzard originals, one `ApplyStrings` pass, panel registration |
| A settings change | one `ApplyStrings` pass |
| A combat boundary, and only while `General.visibility` is `inCombat` / `outOfCombat` | one `ApplyStrings` pass |
| A settings-panel category render, and only while the player has that panel open | one AceGUI tree build, and **one** `C_Timer.After(0, …)` fit for the frame after the layout |
| Every other moment, combat included | **nothing** |

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

Result, verbatim, at the commit that carries this page — **nine lines across five files**:

```
.luacheckrc:62:    "C_Timer",
modules/Override.lua:82:        combatWatcher:SetScript("OnEvent", function()
modules/Override.lua:93:            combatWatcher:RegisterEvent(event)
settings/Panel.lua:530:    -- A frame later, both are true. C_Timer.After(0, ...) is the client's own way
settings/Panel.lua:533:    if C_Timer and C_Timer.After then
settings/Panel.lua:534:        C_Timer.After(0, function() fitTree(ctx) end)
tests/test_panel.lua:612:-- red under: dropping the C_Timer.After, or scheduling it per render without the
tests/wow_mock.lua:64:--  15.  frame RegisterEvent / UnregisterEvent
tests/wow_mock.lua:141:function frameMethods:RegisterEvent(event)
```

Reconciled, so a future drift is visible rather than arguable. One is a lint declaration
(`.luacheckrc:62`). Three are the pattern names appearing **inside comments** — `settings/Panel.lua:530`,
`tests/test_panel.lua:612`, `tests/wow_mock.lua:64` — which describe the discipline rather than doing
anything. One is the headless harness's own mock (`tests/wow_mock.lua:141` defines
`frameMethods:RegisterEvent`, which no client ever runs). The remaining **four are call sites in
shipped code**, and they are the two sections below: the combat watcher, and one next-frame layout
fit in the settings panel.

One thing the grep does *not* return, said out loud so nobody re-adds it: `combatWatcher:UnregisterEvent`
at `modules/Override.lua:95` **does not match**, because the pattern spells `RegisterEvent` with a
capital R and `UnregisterEvent` spells it lowercase. An earlier revision of this page printed that
line inside its result block; the command above cannot produce it, and a result block holding a line
its own command cannot return is worse than no result block at all.

**Zero `SetScript("OnUpdate"`, zero ticker, zero repeating timer** anywhere in `core/`, `defaults/`,
`locales/`, `modules/`, `settings/` or the TOC. That is the part of the old claim that survives.
What does not survive is *"zero `C_Timer` call"*: `.luacheckrc:62` declares `C_Timer` in
`read_globals`, and since 2026-09-03 that declaration has a real consumer.

### The combat watcher — `modules/Override.lua:82`, `:93`

Both hits are `PrettyChat:SyncCombatWatch`, and what matters about them is *when they are reached*:

- the frame is **created lazily**, on the first write that stores `General.visibility` as `inCombat`
  or `outOfCombat`. A default install (`always`) creates no frame and registers no event, so on the
  shipped configuration this half of the sweep's runtime answer is still zero;
- both events are **unregistered** the moment the mode leaves that pair (`modules/Override.lua:95`),
  so the subscription tracks the setting rather than outliving it;
- the handler fires at the combat **boundary** — `PLAYER_REGEN_DISABLED` on entry,
  `PLAYER_REGEN_ENABLED` on exit — at most twice per fight, and never *during* one. Its whole body is
  one `ApplyStrings` pass (~170 table writes, no allocation per string) and one gated debug line.

`tests/test_override.lua` pins all three: no frame on a default load, both events registered on a
combat-scoped write, both dropped on the way back out.

### The settings panel's next-frame fit — `settings/Panel.lua:533-534`

**A guarded one-shot `C_Timer.After(0, …)` on the settings-panel render path, and nothing else.** It
arrived on 2026-09-03 with the string-list revamp (`92c43f5`), after this page's sweep was last taken,
which is why the page went on asserting zero. Its disposition:

- **Where it is reached from.** `buildCategoryBody` only — the render of a Categories page inside the
  options panel. Not `OnInitialize`, not `OnEnable`, not `ApplyStrings`, not the combat watcher.
  Reaching it at all takes a player opening the settings panel and selecting a category, and
  `LibKa0s-Options-1.0`'s `OpenOptionsPanel` refuses to open under `InCombatLockdown()`
  ([ARCHITECTURE.md § Taint Notes](./ARCHITECTURE.md#taint-notes)), so the ordinary way in is closed
  during a fight.
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

`tests/test_panel.lua:614` pins it: the render schedules exactly one fit for the following frame, and
the case goes red if the hop is dropped or if the change guard stops holding.

The addon's other lifecycle hooks are the two AceAddon callbacks above. Both run at login, neither
repeats, and neither can be reached while the player is in combat.

## Which of (b) and (c) applies — both

`performance-§12` asks for (a) plus **whichever** of (b) or (c) applies. Here both do, independently,
and either alone would qualify:

- **(b) — every declared bucket would read `0.000` by construction.** The capture protocol opens its
  windows on the player's combat state (`performance-§7`). PrettyChat executes no code in that window,
  so both arms of every comparison are the same zero — which `performance-§3` calls *a lie in every
  report*.
- **(c) — `suspend` would suppress the data the addon exists to record.** Making PrettyChat inert
  (`performance-§6`) means restoring Blizzard's originals for the duration of a combat-gated window
  and re-applying afterwards: a **visible flip of the player's chat formatting mid-fight**, for a
  capture that can only ever report zero.

The reasoning is kept at length as [`LIBKA0S-12`](https://github.com/tusharsaxena/PrettyChat/issues/10).

## What the exemption does and does not suspend

Suspended, and correctly absent from this repo: `core/PerfSetup.lua`, the `PrettyChatPerfDB`
SavedVariables global (the TOC declares **one** SV global, not two), the `perf` verb registration, the
suspend/resume contract, `tests/perf.lua`, and `docs/perf-analysis/`.

**Not suspended, and all four are live here:**

- **`libs/LibKa0s/` is still vendored whole.** `Perf.lua` and `PerfPanel.lua` ship even though nothing
  wires them — the folder is copied whole or not at all (`library-stack-§7`, anti-pattern #48).
- **`perf` stays a reserved verb** (`slash-commands-§2`). This addon does not register it, and it may
  never come to mean anything else. `settings/Slash.lua`'s `COMMANDS` table has no `perf` entry.
- **This page stays required** (`documentation-§3`), which is why it exists.
- **`automated-tests-§3`'s `perf: skip` line stays in the release notes.** A skip is never a pass, and
  at the release gate it is NOT EVALUATED rather than passed. The one sanctioned exception is exactly
  this one — *no `tests/perf.lua` to run* — and it MUST be said out loud in the release notes rather
  than left to read as measured. Note that the vendored runner currently writes the shorter of the two
  sanctioned reasons, `no tests/perf.lua — this addon ships no offline scenarios`
  (`tests/_kit/run-automated-tests.sh:263`), which does not name `performance-§12`. `tests/_kit/` is a
  vendored payload and is never patched here, so **the release notes carry the exemption by name**
  until the kit does.

## What ends the exemption

**The first `OnUpdate` handler, repeating ticker, or event handler that runs DURING combat rather
than at its boundary re-arms the full `performance-§12` wiring MUST.** Not "should be reconsidered" —
re-arms. Adding an event subscription or a chat filter to this addon changes its compatibility
contract anyway ([ARCHITECTURE.md § Event Subscriptions](./ARCHITECTURE.md#event-subscriptions)); it
also ends this page, and the change that ends it is exactly the change nobody will re-read this
section during. Run the sweep above; the question to ask of any hit it returns is not "is there an
event?" — there are two now — but **"can this run while the player is fighting?"**. The General
visibility watcher cannot: `PLAYER_REGEN_DISABLED` and `PLAYER_REGEN_ENABLED` are the boundary
itself, and they are only registered while the player has chosen one of the two combat-scoped modes.
The settings panel's next-frame fit cannot be *reached* in a fight by the ordinary route — the panel
refuses to open under lockdown — and it is a one-shot off a UI render rather than a ticker in any
case. Anything that answers yes ends the exemption.

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

## Where the numbers that do exist live

The addon is measured out of game on every recorded run: lint, the headless suite and `lizard`
complexity, in `docs/automated-tests/` ([RESULTS.md](./automated-tests/RESULTS.md) is the trend line,
each `<YYYYMMDD-HHMMSS>/` is that run's frozen bundle). `perf` is the one suite that records `skip`
there, for the reason above.
