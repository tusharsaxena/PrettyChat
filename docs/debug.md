# Debug surfaces

PrettyChat has two debug surfaces, and both write into the same window:

- **The debug console** is `LibKa0s-DebugLog-1.0`'s window. Tagged `NS.Debug` lines land there while
  the session flag is on, and `/pc test` writes its sample lines there whatever the flag says.
- **The diagnostics report** is a one-shot snapshot of the addon's state, written into the console
  by `/pc diagnostics` (`debug-logging-§14`). It is the reason this page exists (`documentation-§3`,
  Tier 2): every Ka0s addon ships the report, and a maintainer reading a pasted one needs to know what
  each line means.

The console itself is the library's, and its contract lives in LibKa0s's
[`docs/api/DebugLog/version-19.2.1-docs.md`](https://github.com/tusharsaxena/LibKa0s/blob/master/docs/api/DebugLog/version-19.2.1-docs.md)
(DebugLog 19 with DebugLogDiagnostics 2 and DebugLogGates 1 is the vendored set, from LibKa0s v1.68.1). This page covers
only what PrettyChat adds on top.

## The console

| Command | Effect |
|---|---|
| `/pc debug` | Shows or hides the console window, "Pretty Chat — Debug". The logging flag is unchanged. |
| `/pc debug on` / `off` | Sets or clears the logging flag through `NS.DebugLog:SetEnabled`, which confirms on one chat line. |
| `/pc debug diagnostics` | Writes the diagnostics report (below), and turns logging on for the session if it was off. |
| `/pc debug <anything else>` | Prints `usage: /pc debug [on \| off \| diagnostics]`. |

What PrettyChat supplies, all in `core/DebugLogSetup.lua`:

- **The flag is ours, and session-only.** It is `NS.State.debug`: off at login, never written to
  SavedVariables, and reset by every `/reload`. The General page's **Debug console** checkbox shows
  and hides the window; it does not set the flag.
- **The buffer is the library's 3000 lines** (`lib.MAX_BUFFER`). The footer counter reads
  `N / 3000 lines` and pins there, and Copy pastes out of the same buffer, so a long capture keeps
  only its newest 3000 lines.
- **The `[Init]` line** opens a session when the flag goes on:
  `PrettyChat v<version>, schema v<n>, profile '<name>'`, plus `, rejected events: <names>` when this
  client refused an event name, `, stood down: <holds>` when the addon is stood down, and
  `, chat addons: <names>` when a known chat-rewriting addon is loaded. The report's identity header
  prints the same line.
- **The sink is `NS.Debug(tag, fmt, ...)`**, bound bare to the library's gated `Debug`. A call with
  the flag off does nothing and allocates nothing.

On an install without LibKa0s the flag still works and `on` / `off` still confirm. The window is gone,
and the stub says so once per entry point.

## Coverage

What the console records, tag by tag (debug-logging-§8, and its Diagnosis checklist). Every line is
gated: nothing below lands, and nothing is built for it, while the flag is off. The test for the list
is whether a pasted log lets a maintainer reconstruct what happened; `tests/test_debug_coverage.lua`
pins the lines that answer that, and `tests/test_debuglog.lua` the `[Set]` ones.

**Which lines are the library's.** Since LibKa0s v1.65.0 every LibKa0s module that decides something
a support read needs writes its own line through this addon's gated sink: the host passes
`function(tag, message) NS.Debug(tag, "%s", message) end` as `debug` to the Slash, Lifecycle and
Launcher descriptors, and `NS.Debug` itself to the Options one. The `Emitted by` column below says
*the library* for those lines, and this addon writes no copy of any of them (debug-logging-§4).
`tests/test_debug_coverage.lua` pins each library line landing here, once.

| Tag | Emitted by | When |
|---|---|---|
| `Debug` | the library | `logging enabled` / `logging disabled`, at each flip of the flag, including the enable a diagnostics run makes when logging was off. The disable line is written ungated. |
| `Init` | the library, from `core/DebugLogSetup.lua`'s summary | Once, right after `logging enabled`: version, schema, profile, then `, rejected events: <names>`, `, stood down: <holds>` and `, chat addons: <names>` when each applies. The last two carry what happened at load, while the flag was off. |
| `Cmd` | `settings/Slash.lua`, and the library (`LibKa0s-Slash-1.0`) | **Host:** every `/pc` command, as typed (pipes doubled), with `(stood down: <holds>)` appended while any hold is taken; then a `<verb> refused: <guard>` line for each refusal of a verb the host owns: schema not ready, an unknown category, a category given to `reset`, an unknown format string, an unknown `test` or `debug` form. **Library** (Slash minor 18): one `refused <verb>[ <arg>]: <guard>` line after the command line for each refusal the dispatcher decides itself: a feature verb on a stood-down addon (`refused test: disabled`), an unknown verb, `get` / `set` / `reset` usage and not-found, a value that does not parse, a write the seam refused, a reset with no default, and the `profile` verb's unavailable, already-current, in-combat and unknown-profile refusals. |
| `Set` | the schema write seam (`LibKa0s-Schema-1.0` through `settings/Schema.lua`), `core/PrettyChat.lua`, `modules/Override.lua` | Every setting write as `<path> = <value>`; a format string the signature gate refused, with both sequences; one line per bulk reset (`reset <scope>: N rows`), per profile copy and per profile reset (debug-logging-§10). |
| `Profile` | `core/PrettyChat.lua` | A profile switch, with the strings it applied and restored. |
| `Migrate` | `core/Database.lua` | The migration steps that ran, and stored keys pruned for having no schema row, once per pass. Silent when nothing ran or nothing was pruned. |
| `Lifecycle` | the library (`LibKa0s-Lifecycle-1.0`), through `core/LifecycleSetup.lua` | One line per edge of the latch, before the arm runs: `stood down: added <key> (holds: <set>)` and `stood up: released <key> (holds: none)` (Lifecycle minor 3). A call that fires no edge writes nothing. `modules/Override.lua`'s arms write no line of their own. |
| `Events` | `modules/Override.lua` | `combat watch armed: N/2 events` and `combat watch disarmed`, on a change of registration only, through the console's change gate (`D.DebugChanged`, so a Clear or the enable edge re-arms it). `rejected <names>` follows the arm line when the client refused a name. |
| `Visibility` | `modules/Override.lua` | Each combat boundary while a combat-scoped mode is stored: `combat entered` or `combat left`, the mode, and the strings applied and restored. |
| `UI` | `settings/Panel.lua`, `settings/Schema.lua` | A Categories tab switch (`categories tab <name>`) and a string selection (`<category> string <NAME>`). A panel refresher that raised inside its `pcall`: `<site> failed: <error>`, once per distinct site and error, through the console's `D.DebugOnce` (a Clear re-arms it). |
| `Cfg` | the library (`LibKa0s-Options-1.0`) | The settings panel opened, an open refused in combat, a registration parked in combat and its `register flushed (combat ended)` line, and (Options minor 27) one `<what> refused (in combat)` line for each write, Defaults, button, toggle, tab or page switch the combat lock refuses on an open panel, once per combat (`tab Money refused (in combat)`). |
| `Launcher` | the library (`LibKa0s-Launcher-1.0`), through `core/LauncherSetup.lua` | The launcher's own lines. Its state lines, `registered` or the broker library it found missing, are written at `OnEnable` while the session-only flag is off, so they go to the console's at-enable queue (`debugAtEnable`, Launcher minor 5) and land once, right after the `[Init]` summary, the first time logging is turned on. Its events, a menu entry refused while disabled and a tooltip callback that raised, are written as they happen. |
| `Test` | `settings/Panel.lua` | The `/pc test` samples and the General page's **Test** button. Written ungated, because the player asked for them. |
| `Diag` | the library | The diagnostics report's markers, identity header and `truncated` line. |

A new tag is a one-word string at the call site. Add its row here in the same change.

### Quiet steady state

PrettyChat has no `OnUpdate`, no ticker and no repeating timer (the sweep is
[performance-sweep.md](./performance-sweep.md)). The one path that runs again and again with nothing
new to say is the combat watcher's registration: `SyncCombatWatch` re-registers on every re-apply (each
latch arm, each profile event, each visibility write). Its `[Events]` lines are change-gated, so 25
re-applies with the mode unchanged add no line (debug-logging-§9). The gate is the console's
(`D.DebugChanged`, DebugLogGates 1), not a memo of this addon's, so it remembers nothing while logging
is off and a Clear re-arms it: the first re-apply after a Clear states the watcher again. The
combat-boundary line itself is not steady state: each boundary is a real recompute.

### Deliberately not traced

- **Per-string work.** `ApplyStrings` returns its counts, and its callers put them on their own one
  line. A line per global would be 79 lines a pass (debug-logging-§9).
- **Load-time work.** The snapshot, the latch armed from the stored path, panel registration and a
  migration step that fails. The flag is off at every load, so a line there could never land (the
  launcher's state lines are the exception: they wait in the at-enable queue). The `[Init]` tails
  carry the stand-down; a failed migration is printed to chat, and the report's
  `state` section shows the stored and code schema versions.
- **The Preview's render errors.** `NS.RenderSample` catches a `string.format` raise per string and
  shows it in the panel's Preview and in `/pc test`, which is where the player is looking.

## The diagnostics report

### Running it

There are exactly two slash forms, and no third:

- `/pc diagnostics`, a row of the `COMMANDS` table in `settings/Slash.lua`;
- `/pc debug diagnostics`, the first word `runDebug` tests, in any case.

The console carries the one other way in: the orange **Diagnostics** link in its title bar, a small
gap right of the Debug On/Off label (the library's, DebugLog minor 16 and later). It is plain text,
not a button, and a click runs the same `RunDiagnostics` the two forms call, so it writes the same
report.

`/prettychat` reaches both, as it reaches every verb. `diag`, `dump`, `dx` and every other short name
are ordinary unknown words: `/pc diag` prints the unknown-command help, and `/pc debug diag` prints
the `debug` usage line.

`diagnostics` is on the library's live set (`lib.LIVE_VERBS`), so both forms answer while the addon
is **disabled**. A disabled addon is stood down, and the report says so on its state line rather than
printing empty data.

### What it does to the console

- **It appends.** The report lands after whatever the console already holds, so the trace a player
  has just reproduced stays above it and one Copy carries both. Nothing the report reaches calls
  `Clear()`.
- **It is ungated.** It writes through the library's raw append, not `NS.Debug`, so it lands in full
  whatever the flag says.
- **It turns logging on for the session** (`debug-logging-§14`, standard v2.71.0). When logging is
  off, the run calls `NS.DebugLog:SetEnabled(true)`, the flag's one seam, before it writes, so the
  `[Debug] logging enabled` line, the `[Init]` summary and the chat ack come first, the header reads
  `Debug: ON` afterwards, and the player's next reproduction is traced. It never turns logging off,
  and with logging already on it writes no second enable line. A `/reload` turns it off again, as it
  does every session. PrettyChat keeps the library's default: its descriptor in
  `core/DebugLogSetup.lua` sets no `diagnosticsEnablesLogging = false`, and `runDiagnostics` wraps no
  `SetEnabled` of its own around the run. The sections only read the flag, which is why the identity
  header prints it as on.
- **It reveals the console** if it is hidden, then prints one chat line:
  `Diagnostic report written to the debug console: N lines. Use Copy to share it.`
- **It is plain text.** The library strips color, texture, atlas and hyperlink escapes from every
  line, so the Copy text reads cleanly. Format strings are the one exception (see `Set` below).

The report body is English diagnostic text and does not go through `NS.L`, like every trace line.
The chat line after it is the library's localizable one.

### What it prints

The library writes the frame: the begin marker, the identity header, each section under its own
`pcall`, the cap and the end marker. `modules/Diagnostics.lua` writes the sections in between, in
this order. The tag in brackets is what each line carries in the paste.

| Section | Tag | What it reports |
|---|---|---|
| (begin) | `Diag` | `==== Ka0s Pretty Chat diagnostics begin ====` |
| identity | `Diag` | The `[Init]` summary (version, schema, profile, rejected events); the client's version, build, date and interface from `GetBuildInfo()`; the locale; the logging flag; `InCombatLockdown` and `UnitAffectingCombat("player")`; the **running** LibKa0s minors, file by file, which under LibStub may come from another addon's vendored copy |
| state | `State` | The stored master switch, whether the addon is stood down and the Lifecycle holds; the visibility mode, whether it is visible now and whether the apply gate is open; the stored and code schema versions and the profile; the combat watcher (built, wanted, and each event's registration); rejected events; the schema path check (checked, failed, unresolved paths); a pending reset |
| settings | `Set` | The count of changed rows, the disabled categories, the disabled strings per category, then every row that differs from its default as `path = value (default)`. `General.enabled` and `General.visibility` always print, whatever their value. A format string prints with every `\|` doubled to `\|\|`, so it pastes back into `/pc set` unchanged |
| globals | `Globals` | For every string the addon manages, whether `_G` holds what `ApplyStrings` would have written (the override) or restored (the snapshot): expected, match and mismatch counts, then the mismatching names. A mismatch usually means another addon wrote the global after PrettyChat |
| apply | `Apply` | How many strings `ApplyStrings` would apply and restore right now |
| snapshot | `Snapshot` | Whether the snapshot of the client's originals was taken, how many keys it holds, the globals this client does not define, and globals that more than one category claims |
| drift | `Drift` | Patch drift: each shipped default whose conversion sequence no longer fits the client's own string, as `NAME default=<seq> client=<seq>`; then any stored override the signature gate would refuse today |
| render | `Render` | Whether each live global renders through the sample renderer: ok and failed counts, then each failure with its error |
| ui | `UI` | Whether the settings pages are built, whether the console is shown, whether the launcher is registered, and whether the minimap button is hidden |
| addons | `Addons` | Which known chat-rewriting addons are loaded (Prat, Chatter, ElvUI, Chattynator, BasicChatMods, Glass) |
| (end) | `Diag` | `==== Ka0s Pretty Chat diagnostics end: N line(s) ====`, with `N` counting both markers |

A section that raises costs one line, `section <name> failed: <err>`, and the rest of the report
still lands. On an install where `modules/Diagnostics.lua` failed to load, the report is the markers
and the identity header around no sections.

### Caps

- **The whole report** stops at `lib.DIAG_MAX_LINES` (1200), which the library clamps to
  `lib.MAX_BUFFER - 100`, so the report never pushes itself out of the 3000-line buffer. The trace
  above it is kept on a best-effort basis.
- **Each list** (mismatching globals, drifted strings, unrenderable strings and the rest) prints at
  most `lib.DIAG_MAX_PER_LIST` (40) entries and then `(+N more)`. A long list wraps at 200
  characters a line.
- A capped report ends with `truncated: N line(s) omitted, per-list caps hit=yes|no`, then the end
  marker.

### What it does not do

- **It writes nothing.** No `ApplyStrings`, no re-apply, no `Schema.Set`, no event registration, no
  Lifecycle hold, no timer. A report that repaired the state would describe a state the player is
  not in. The combat watcher is read through `PrettyChat.CombatWatchState()`, never armed.
- **It calls no protected API**, so it is safe in combat.
- **It does not read secret values.** Every value goes through `NS.Util.SafeToString` before a
  format sees it, so a secret prints as `<secret>`, and the live-global audit compares with
  `rawequal`, so a secret or a table in `_G` cannot reach an `__eq` that could raise. A format string
  is only ever an argument, never the format of the line, so a `%` in a player's format cannot
  consume the line's own arguments.
- **Nothing is redacted.** Players send the report to the maintainer privately, so it prints what a
  maintainer needs to reproduce the bug.

With no LibKa0s the stub's `RunDiagnostics` prints
`/pc diagnostics is unavailable: the LibKa0s library did not load.`, writes nothing and returns 0.

## Where else this is pinned

The command rows are in [slash-dispatch.md](./slash-dispatch.md), and the player-facing steps are
the README's `## Reporting a bug`. The in-game checks are DIAG-1 to DIAG-8, DIAG-11 to DIAG-15,
DIAG-23 to DIAG-25 (the library's own lines) and COMBAT-4 (the report in combat) in [smoke-tests.md](./smoke-tests.md). The suites are `tests/test_diagnostics.lua` (this addon's
sections), the kit's shared `tests/_kit/test_diagnostics_contract.lua` (wired in `tests/run.lua`),
`tests/test_debuglog.lua`, `tests/test_debug_coverage.lua` (the Coverage lines above), `tests/test_disabled.lua` and `tests/test_slash.lua`.
