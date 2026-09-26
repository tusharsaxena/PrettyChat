# Debug surfaces

PrettyChat has two debug surfaces, and both write into the same window:

- **The debug console** is `LibKa0s-DebugLog-1.0`'s window. Tagged `NS.Debug` lines land there while
  the session flag is on, and `/pc test` writes its sample lines there whatever the flag says.
- **The diagnostics report** is a one-shot snapshot of the addon's state, written into the console
  by `/pc diagnostics` (`debug-logging-§14`). It is the reason this page exists (`documentation-§3`,
  Tier 2): every Ka0s addon ships the report, and a maintainer reading a pasted one needs to know what
  each line means.

The console itself is the library's, and its contract lives in LibKa0s's
[`docs/api/DebugLog/version-14.1-docs.md`](https://github.com/tusharsaxena/LibKa0s/blob/master/docs/api/DebugLog/version-14.1-docs.md)
(DebugLog 14.1 is the vendored minor, from LibKa0s v1.60.0). This page covers only what PrettyChat
adds on top.

## The console

| Command | Effect |
|---|---|
| `/pc debug` | Shows or hides the console window, "Pretty Chat — Debug". The logging flag is unchanged. |
| `/pc debug on` / `off` | Sets or clears the logging flag through `NS.DebugLog:SetEnabled`, which confirms on one chat line. |
| `/pc debug diagnostics` | Writes the diagnostics report (below). |
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
  client refused an event name. The report's identity header prints the same line.
- **The sink is `NS.Debug(tag, fmt, ...)`**, bound bare to the library's gated `Debug`. A call with
  the flag off does nothing and allocates nothing.

On an install without LibKa0s the flag still works and `on` / `off` still confirm. The window is gone,
and the stub says so once per entry point.

### Tags in use

| Tag | Emitted by | What it logs |
|---|---|---|
| `Init` | the library, from `core/DebugLogSetup.lua`'s summary | The session summary when logging goes on |
| `Set` | the schema write seam, `settings/Schema.lua`, `core/PrettyChat.lua`, `modules/Override.lua` | Every setting write, a format string the signature gate refused, profile copy and profile reset (one line per bulk reset) |
| `Profile` | `core/PrettyChat.lua` | A profile switch and the strings it applied and restored |
| `Migrate` | `core/Database.lua` | The schema migration steps that ran, and stored keys pruned for having no schema row |
| `Visibility` | `modules/Override.lua` | A visibility change and the strings it applied and restored |
| `Events` | `modules/Override.lua` | Event names this client refused to register |
| `Lifecycle` | `modules/Override.lua` | Standing down (with the holds) and standing up |
| `Test` | `settings/Panel.lua` | The `/pc test` samples and the General page's **Test** button |
| `Diag` | the library | The report's markers, identity header and `truncated` line |

A new tag is a one-word string at the call site. Add its row here in the same change.

## The diagnostics report

### Running it

There are exactly two forms, and no third:

- `/pc diagnostics`, a row of the `COMMANDS` table in `settings/Slash.lua`;
- `/pc debug diagnostics`, the first word `runDebug` tests, in any case.

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
  with logging off, and it does not read or change the flag: the header reads the same afterwards.
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
the README's `## Reporting a bug`. The in-game checks are T-39 and T-29b in
[smoke-tests.md](./smoke-tests.md). The suites are `tests/test_diagnostics.lua` (this addon's
sections), the kit's shared `tests/_kit/test_diagnostics_contract.lua` (wired in `tests/run.lua`),
`tests/test_debuglog.lua`, `tests/test_disabled.lua` and `tests/test_slash.lua`.
