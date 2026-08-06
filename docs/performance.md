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
| Every other moment, combat included | **nothing** |

## The sweep — criterion (a), proven rather than asserted

`performance-§12` makes criterion (a) — *no `OnUpdate` handler, no repeating ticker, and no event
handler doing more than occasional work while the player is in combat* — provable only by a
**committed whole-repo sweep**. This is it. Re-run it from the repo root; it is the thing to re-run
before trusting this page.

```sh
grep -rEn 'RegisterEvent|RegisterUnitEvent|RegisterAllEvents|SetScript\("On(Update|Event)"|C_Timer|ScheduleRepeatingTimer|ScheduleTimer|NewTicker' \
  . --exclude-dir=.git --exclude-dir=libs --exclude-dir=_kit --exclude-dir=GlobalStrings \
    --exclude-dir=audits --exclude-dir=reviews --exclude-dir=automated-tests
```

Result, at the commit that carries this page:

```
.luacheckrc:42:    "C_Timer",
```

**One hit, and it is not a call.** `.luacheckrc:42` declares `C_Timer` in `read_globals` — a lint
declaration of an API this addon does not use. There is no per-event work to name because there are
no events: **zero** `RegisterEvent`, **zero** `SetScript("OnUpdate"`, **zero** `C_Timer` call, zero
ticker, zero repeating timer in `core/`, `defaults/`, `locales/`, `modules/`, `settings/` or the TOC.
The excluded paths are the vendored payloads (`libs/`, `tests/_kit/`), the generated data
(`GlobalStrings/`) and the frozen evidence bundles (`docs/audits/`, `docs/reviews/`,
`docs/automated-tests/`) — none of which is this addon's shipped runtime code.

The addon's only lifecycle hooks are the two AceAddon callbacks above. Both run at login, neither
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
suspend/resume contract, `tests/perf.lua`, and `docs/perf-runs/`.

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
  (`tests/_kit/run-automated-tests.sh:223`), which does not name `performance-§12`. `tests/_kit/` is a
  vendored payload and is never patched here, so **the release notes carry the exemption by name**
  until the kit does.

## What ends the exemption

**The first `OnUpdate` handler, repeating ticker, or in-combat event handler doing real work re-arms
the full `performance-§12` wiring MUST.** Not "should be reconsidered" — re-arms. Adding an event
subscription or a chat filter to this addon changes its compatibility contract anyway
([ARCHITECTURE.md § Event Subscriptions](./ARCHITECTURE.md#event-subscriptions)); it also ends this
page, and the change that ends it is exactly the change nobody will re-read this section during. Run
the sweep above; if it returns a call, the exemption is over.

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
