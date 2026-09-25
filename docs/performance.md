# Performance

**Ka0s Pretty Chat brackets nothing: it costs nothing measurable while you play.** It holds the
`performance-§12` no-combat-path exemption in [`## Documented deviations`](./ARCHITECTURE.md#documented-deviations).

## It brackets nothing

PrettyChat overrides `_G[GLOBALNAME]` and lets WoW's own chat code read it. It registers no chat
filter, hooks no chat frame, and has no `OnUpdate` handler and no ticker. Its whole runtime:

| When | What runs |
|---|---|
| Login (`OnInitialize`, `OnEnable`) | AceDB, migrations, one snapshot of Blizzard's originals, one `ApplyStrings` pass |
| A settings change, or a combat boundary while `General.visibility` is `inCombat` / `outOfCombat` | one `ApplyStrings` pass (a boundary: at most twice per fight) |
| A settings-panel category render, panel open | one AceGUI tree build and **one** `C_Timer.After(0, …)` layout fit |
| Every other moment, combat included | **nothing** |

## Which of (b) and (c) applies: both

- **(b)** Every declared bucket would read `0.000` by construction: no code runs in a capture window.
- **(c)** `suspend` would flip the player's chat formatting back to Blizzard's mid-fight, for a capture
  that can only report zero. Reasoned at length as [`LIBKA0S-12`](https://github.com/tusharsaxena/PrettyChat/issues/10).

## Where the sweep lives

[performance-sweep.md](./performance-sweep.md) holds the committed whole-repo sweep that proves
criterion (a) (command, verbatim result, every hit's disposition) and the one load-time cost measured
and removed (PC-R-05). Re-run the sweep before trusting this page.

The exemption drops `core/PerfSetup.lua`, `PrettyChatPerfDB`, the `perf` verb registration,
`tests/perf.lua` and `docs/perf-analysis/`; `perf` stays reserved and `libs/LibKa0s/` stays whole.
The vendored kit-26 runner reads the register row and records skip reason (2),
`performance-§12 no-combat-path exemption (ratified; docs/ARCHITECTURE.md -> Documented deviations)`,
in [`automated-tests/`](./automated-tests/RESULTS.md); the release notes name the exemption too.

## What re-arms the wiring

**The first `OnUpdate` handler, repeating ticker, or event handler that runs DURING combat rather
than at its boundary re-arms the full `performance-§12` wiring MUST.** Ask of every new sweep hit:
*can this run while the player is fighting?*
