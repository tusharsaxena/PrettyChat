# Review findings — Ka0s Pretty Chat (2026-08-03)

**Verdict:** **minor issues, with one functional defect worth fixing before the next release.** The
addon loads clean, lints clean (`luacheck .` → 0 warnings / 0 errors in 17 files) and its headless
suite is green (255/255). There is **no taint surface, no deprecated-API usage, no event
registration at all**, and the LibKa0s adoption is wired correctly on every seam this review
checked. What is wrong is concentrated in the **data** the addon ships and the fact that nothing
validates it: two of the 81 default replacement templates disagree with Blizzard's own argument
list in a way that raises a Lua error inside Blizzard's message path, and neither the panel Preview
nor `/pc test` can ever show it. Everything else is convention drift, one localization gap, and
housekeeping.

## Standards cross-check

Performed. Standard resolved: **Ka0s WoW Addon Standard v2.17.1 (2026-08-03)**. `STANDARDS.md` was
fetched over the network with `curl`; the section files were read from the pinned clean checkout of
the same repo at the same version after the bulk-fetch loop timed out on network latency — the
version header matched the fetched index byte for byte, so the text used is the published text.
Every fix direction below was checked against the standard and none introduces a new deviation;
where the obvious fix would have, the compliant direction is named with its rule.

## Conventions detected (checks applied only where present)

- `NS.PREFIX` / `NS.Print` chat chokepoint (`core/Constants.lua:51`, `core/CoreSetup.lua:109`) — the
  "no raw `print(`" rule applies. **Clean:** no call site bypasses it.
- `COMMANDS` positional-triple table (`settings/Slash.lua:45-66`), passed to the library as data.
  **Clean:** README's command table and `COMMANDS` agree entry for entry, both directions.
- Single write path `NS.Schema.Set` (`settings/Schema.lua:287`). Panel and CLI both route through it
  (`settings/OptionsSetup.lua:122`, `settings/Slash.lua:166`). One documented bypass — F-008.
- `settings/Schema.lua` flat-row schema with a `tooltip` convention on rows. **Clean:** every row
  that is rendered as a widget carries `label` + `tooltip`.
- No `docs/CLAUDE_SECRET_VALUES.md`; the addon consumes no protected API. Secret-safety is inherited
  from `LibKa0s-Core-1.0` through `core/CoreSetup.lua:90-91`. **Clean.**
- `.gitattributes` declares `* text=auto eol=crlf`. **Clean.**
- Vendored `libs/LibKa0s/` (Core 3, DebugLog 7, Slash, Options 5 + Widgets 5 + Scroll 2, Perf 5 +
  PerfPanel 3), whole ship folder, TOC-listed as `libs\LibKa0s\LibKa0s.xml`
  (`PrettyChat.toc:22`). Majors actually wired: **Core** (`core/CoreSetup.lua`), **DebugLog**
  (`core/DebugLogSetup.lua`), **Options** (`settings/OptionsSetup.lua`), **Slash**
  (`settings/Slash.lua`). Perf is deliberately not adopted (recorded in `docs/pending/LEDGER.md`).
  `diff -r` against the library's ship folder is **empty** — no vendor drift (anti-pattern #45).
- Vendored test kit `tests/_kit/`. `diff -r` against the library repo's `testkit/` is **empty**.

## Areas checked and found clean (no findings raised)

- **Taint / combat:** the only protected surface is the settings-category open, and it is a one-line
  delegate to the library's gated `OpenOptionsPanel` (`core/PrettyChat.lua:71-73`) — the addon wires
  no second, un-gated path (options-ui-§2). No `SetAttribute`, no secure templates, no `:Hide()` on
  Blizzard frames. The addon rewrites `_G[GLOBALNAME]` rather than hooking `AddMessage`, which is
  the sanctioned taint-free shape (events-frames-taint-§5).
- **Deprecated APIs:** none. `GetAddOnMetadata` is the only moved API and it is routed through
  `core/Compat.lua:11-19` (compat, anti-pattern #10).
- **Events / frames:** the addon registers no events and creates no frames of its own (all frame work
  is the library's). Nothing to leak, nothing to unregister.
- **Degradation stubs:** every member the addon calls on `NS.Helpers`, `NS.DebugLog` and
  `NS.SlashCommands` is answered by the corresponding stub — verified by grepping the call sites
  against `settings/OptionsSetup.lua:58-96`, `core/DebugLogSetup.lua:68-104` and
  `settings/Slash.lua:88-125`. No stub re-implements a library formatter, layout constant or line
  format.
- **Descriptors:** every field each descriptor passes is a field the vendored library reads, with the
  contracted arity; `get`/`set`/`applyDefault` agree with the addon's own single write path; the
  DebugLog `isEnabled`/`setEnabled` pair reads and writes the one flag (`NS.State.debug`) the panel
  and the slash verb also use — no second truth.
- **Defaults keys:** all 81 `GLOBALNAME`s in `defaults/Defaults.lua` exist in the shipped Blizzard
  reference — no dead override keys.
- **Migration runner:** `core/Database.lua` is version-stamped, idempotent and pcall-guarded
  (savedvariables-§1).

---

## High

### F-001 — Two shipped default templates disagree with Blizzard's argument list and will raise inside Blizzard's own `format` call [bug]

**Where:** `defaults/Defaults.lua:162` (`FACTION_STANDING_DECREASED_GENERIC`) and
`defaults/Defaults.lua:190` (`FACTION_STANDING_INCREASED_GUARDIAN`).

**Problem:** Blizzard's `FACTION_STANDING_DECREASED_GENERIC` is `"Reputation with %s decreased."`
(one `%s`); the shipped replacement adds a `%d`, so the game's one-argument `format` call raises
*bad argument #3 to 'format' (no value)*. Blizzard's `FACTION_STANDING_INCREASED_GUARDIAN` is
`"%s has gained %d guardian experience points."` (`%s`, `%d`); the shipped replacement declares only
`%d`, which then consumes the **name** argument — *bad argument #2 to 'format' (number expected, got
string)*.

**Impact:** every time either message fires, the player gets a Lua error from a call site inside
Blizzard's UI and the message itself does not print. The addon is the cause, but the stack does not
name it.

**Fix direction:** correct the two templates so their conversion signature matches the original's
exactly (same count, same order, same types). Keep the replacement's own wording and colors.

### F-002 — Nothing validates a format string on write, and the Preview cannot detect the failure it is there to prevent [design][bug]

**Where:** `settings/Schema.lua:287-298` (`Schema.Set`, no validate step),
`modules/Override.lua:163-202` (`buildSampleArgs` / `NS.RenderSample`),
`settings/Panel.lua:201-203` and `settings/Slash.lua:147-153` (both write paths).

**Problem:** `buildSampleArgs` synthesizes its sample arguments **from the replacement's own
conversions**, so any replacement renders cleanly in the panel Preview and in `/pc test` regardless
of what Blizzard will actually pass it. A template with the wrong arity is therefore green on every
surface the addon offers and only fails in live chat — which is exactly how F-001 shipped. Schema
rows carry no `validate`, and `Schema.Set` writes without one, so the same defect is one keystroke
away for any user (the README's own Troubleshooting table describes the symptom and offers no way to
see it coming).

**Impact:** the addon's preview feature gives false assurance for the single most likely user error,
and its single write seam accepts values it knows will break the game's chat handler.

**Fix direction:** validate on the write seam, not at the call sites — `Schema.Set` compares the
incoming string's conversion signature against the **original's** (the live snapshot, F-003) and
refuses with a reason, and `NS.RenderSample` gains an "as Blizzard will call it" mode that feeds the
original's argument list. This is the shape architecture-§5 already mandates (`validate → write →
onChange`) and slash-commands-§6's "MUST NOT silently store a value the addon cannot honor"; the
tempting alternative — validating inside each panel/CLI call site — is rejected because it would put
two validators either side of one seam.

### F-003 — The panel's "Original" box reads a hardcoded enUS snapshot, so it is wrong on every non-enUS client — and that snapshot costs ~1.9 MB and 22,879 resident table entries to serve 81 lookups [locale][perf]

**Where:** `settings/Panel.lua:180-182` (`NS.GlobalStrings[globalName]`),
`PrettyChat.toc:43-52` (ten eagerly-loaded chunks), `docs/global-strings.md`.

**Problem:** `NS.GlobalStrings` is a build-time dump of Blizzard's **enUS** `GlobalStrings.lua`. The
game hands the client its **localized** originals, and the addon already snapshots exactly the ones
it needs — the true, localized values — into `self.originalStrings` at `OnEnable`
(`core/PrettyChat.lua:38-43`), before it overwrites anything. The panel ignores that and renders
English. Separately, the ten chunks are parsed and kept resident for the whole session at every
login to answer at most 81 lookups.

**Impact:** on deDE/frFR/… the "Original Format String" row shows a string the player has never seen
and cannot compare against, which is the row's only purpose; and every player pays the memory and
load cost of the other ~22,798 entries. It is also the reason F-002's validation has no localized
reference today.

**Fix direction:** read the original from the live snapshot (`self.originalStrings`, with `_G` as a
fallback for a key added since load), and retire the eager `GlobalStrings/` load from the TOC. Note
that `docs/global-strings.md` justifies the dump as covering "any global key, even ones the user has
added to `defaults/Defaults.lua` since the addon last shipped" — that is a developer workflow, and
the compliant place for it is the splitter's build-time output, not a runtime load in every player's
session.

---

## Medium

### F-004 — User-facing text built by concatenation and not routed through `NS.L` [locale]

**Where:** `settings/Schema.lua:72-73` (`"Enable " .. category`,
`"Enable or disable all " .. category .. " string overrides."`), `settings/Panel.lua:167-170`
(the shared-global tooltip), `settings/Panel.lua:392-394` (`"Reset all " .. category .. " strings to
defaults."`), `modules/Override.lua:220-232` (Test header, `Category:` / `Name:` / `Original:` /
`Formatted:` labels, the error and footer lines), and the usage/error lines throughout
`settings/Slash.lua:200-375`.

**Problem:** `locales/enUS.lua:9-11` states that the seeded block "is the authoritative manifest of
the addon's user-facing string surface — every string wrapped in `L[...]` at a call site appears
here". These strings are never wrapped at all, so the manifest is complete only about the strings
that opted in. Several are also assembled by concatenating an English fragment with a value, which a
translator cannot reorder (localization-§1/§2 keys are the English *sentence*).

**Impact:** a translator who translates the whole manifest still ships an addon that is half
English, in places (`Enable Loot`, the category Defaults tooltip) that sit right next to translated
text.

**Fix direction:** wrap them, and make the parameterized ones format strings with the value as an
argument (`L["Enable %s"]:format(category)`), then add the new keys to `locales/enUS.lua`. Not:
per-fragment locale keys.

### F-005 — A printed chat line ends in a trailing colon [convention][ux]

**Where:** `modules/Override.lua:220`.

**Problem:** `sample of every format string (preview ignores enable toggles):` ends in `:`.
slash-commands-§4 is explicit: **no** chat line the addon prints may end in a trailing colon; a list
is introduced by its header text alone.

**Impact:** the one house-style rule that makes six Ka0s addons read as one surface is broken on the
first line of the addon's most-used report.

**Fix direction:** drop the colon (this string is also an F-004 candidate — do both in one edit so
the locale key lands correct the first time).

### F-006 — The restore arm is keyed on truthiness, and a second `OnEnable` re-snapshots overridden values as "originals" [bug]

**Where:** `modules/Override.lua:78-80`, `core/PrettyChat.lua:38-43`.

**Problem:** two independent gaps in the same snapshot. (a) `elseif self.originalStrings and
self.originalStrings[globalName]` — a `GLOBALNAME` that does not exist on the client at `OnEnable`
(a key Blizzard removes in a future patch) is still **written** by the enabled arm but can never be
restored, because its snapshot entry is nil rather than a sentinel. (b) `OnEnable` rebuilds
`self.originalStrings` from `_G` unconditionally; AceAddon re-runs `OnEnable` on any
`:Disable()`/`:Enable()` cycle, at which point `_G` holds *PrettyChat's* strings and they are
recorded as Blizzard's — permanently, until `/reload`.

**Impact:** (a) is latent today (all 81 keys currently resolve) and self-limiting; (b) turns a
disable/enable cycle into a silent, unrecoverable loss of the user's ability to see or restore the
real originals.

**Fix direction:** snapshot **once** (guard on `self.originalStrings` already existing) and store a
sentinel for a key that was absent, so the restore arm can distinguish "was nil" from "not
snapshotted".

### F-007 — The same sorted name list is rebuilt and re-sorted in four places, one of them on every write [perf][design]

**Where:** `modules/Override.lua:67-71` (inside `ApplyStrings`, i.e. on every `Schema.Set`),
`settings/Schema.lua:130-134`, `settings/Panel.lua:277-281`, `settings/Slash.lua:207-218`.

**Problem:** each site independently collects `pairs(catData.strings)` into a table and `table.sort`s
it, to obtain the *same* order the schema already fixed at load. `ApplyStrings` does it for all nine
categories on every single settings write and on every reset.

**Impact:** ~9 table allocations plus 9 sorts per write for an order that never changes after load —
and, worse than the cost, four places that must agree about ordering for the "last writer wins"
guarantee in `ApplyStrings`'s own comment to hold.

**Fix direction:** build one ordered index at schema-build time (`Schema.OrderedNames(category)`) and
have all four read it. This keeps the deterministic-ordering guarantee in one place, which is what
the comment at `modules/Override.lua:54-61` is actually promising.

### F-008 — Bulk resets bypass the single write seam and duplicate its tail three times [design]

**Where:** `modules/Override.lua:90-136` (`ResetCategory`, `ResetAll`, `ResetString`) writing
`self.db.profile.*` directly, then each repeating apply → notify → debug.

**Problem:** architecture-§5 requires every mutation to route through one helper. These three are
documented deviations, for a good reason (row-by-row `Schema.Set` would run `ApplyStrings` ~350
times and flood the 500-line console buffer — debug-logging-§9), but the deviation was taken by
dropping to raw writes rather than by adding the bulk seam the schema's own comment anticipates
(`settings/Schema.lua:38-41` says "so a future `Schema.SetMany` / preset-load can apply once per
batch"). The consequence today is three copies of the post-write tail; the consequence tomorrow is
that F-002's validation and any future `onChange` will not run on a reset.

**Impact:** maintainability, plus a real correctness hazard the moment the write seam grows a step.

**Fix direction:** add the batch seam to `settings/Schema.lua` (`Schema.SetMany` / `Schema.ResetScope`)
that performs the DB mutation, then **one** apply + **one** notify + **one** summary line, and have
the three reset paths call it. Compliant with both architecture-§5 and debug-logging-§9; the
rejected alternative is driving resets row-by-row through `Schema.Set`.

### F-009 — `Schema.RowsByCategory` is a full-table scan with a fresh allocation per call [perf]

**Where:** `settings/Schema.lua:323-329`, reached from `settings/OptionsSetup.lua:126`
(`rowsForPage`) and from `settings/Slash.lua:246`.

**Problem:** every call walks all ~350 rows and builds a new table, for a partition that is fixed at
load.

**Impact:** small in absolute terms, but it is on the page-build and `/pc list <Category>` paths and
the index is free to precompute beside `byPath`.

**Fix direction:** build `byCategory` in `addRow`, return the live table (as `AllRows` already does,
with the same reasoning recorded at `settings/Schema.lua:300-303`).

---

## Low

### F-010 — Stale comment references to a file that no longer exists, and one retired cross-reference form [naming][doc]

**Where:** `core/Constants.lua:29`, `settings/Schema.lua:8`, `settings/Schema.lua:249` all name
`Config.lua` (the file is `settings/Panel.lua`); `settings/Schema.lua:167` cites `§4.5`, the global
numbering the standard retired in favor of `filename-§N`.

**Impact:** a reader greps for `Config.lua` and finds nothing; `§4.5` cannot be resolved against the
current standard.

**Fix direction:** rename the references and re-cite as `architecture-§5`.

### F-011 — Four shipped templates silently drop an argument Blizzard's original carried [ux]

**Where:** `defaults/Defaults.lua:15` (`LOOT_DISENCHANT_CREDIT` — loses who disenchanted),
`:292` (`COMBATLOG_DISHONORGAIN` — loses the victim), `:345` / `:349` (`OPEN_LOCK_OTHER` /
`OPEN_LOCK_SELF` — one argument each).

**Problem:** dropping a trailing conversion is harmless to `format` (extra args are ignored), so
unlike F-001 these do not error — but they are indistinguishable from F-001 by inspection, and they
change what information the player receives.

**Impact:** information loss that may well be intentional; today nothing records that it is.

**Fix direction:** decide per string, and record the intentional ones in a comment beside the entry
so the F-002 validator can whitelist "fewer, in order" while still rejecting the F-001 shape.

### F-012 — `NS.version` carries a hand-maintained fallback that drifts from the TOC [design]

**Where:** `core/Namespace.lua:7` (`or "1.4.0"`).

**Impact:** a release that bumps the TOC and forgets this line reports the old version on any client
where the metadata shim returns nil — the one client where the user is being asked what version they
run.

**Fix direction:** keep the fallback (slash-commands-§3 wants a constant), but make it a single named
constant in `core/Constants.lua` referenced by both, and add it to the release checklist in
`docs/`.

### F-013 — `NS.Util.cmd` is documented as "gold" and implemented from `Color.yellow` [naming]

**Where:** `core/Util.lua:26-28` with `core/Constants.lua:37`.

**Impact:** `ffff00` is the standard's gold command color, so the behavior is right and only the two
names disagree — but a reader checking the palette against slash-commands-§4 has to prove that to
themselves.

**Fix direction:** name the palette entry `gold` (or annotate the alias explicitly at both ends).

### F-014 — `settings/Panel.lua` publishes its module surface as `NS.Config` [naming]

**Where:** `settings/Panel.lua:421-423`.

**Impact:** the file/member mismatch is the last trace of the old `Config.lua` and is the reason
F-010's stale comments read as plausible.

**Fix direction:** rename to `NS.Panel` in the same change as F-010 (three call sites:
`core/PrettyChat.lua:50-51`, `settings/OptionsSetup.lua:134`, `settings/Panel.lua:421-423`).

### F-015 — `docs/file-index.md` documents a `TODO.md` the repo does not have [doc]

**Where:** `docs/file-index.md:58`.

**Fix direction:** drop the clause. (Do **not** add a `TODO.md` — anti-pattern #27 forbids one in a
released addon.)

---

## Upstream — these do not land in this repo

Fix in the library's own repo, bump the file's LibStub minor, then re-vendor the whole `LibKa0s/`
ship folder into this addon (and every other consumer) as its own commit. **Not** a local edit under
`libs/`.

### F-016 — `LibKa0s-Options-1.0` comments cite the retired numbering scheme and a nonexistent subsection [upstream][doc]

**Owning library:** `LibKa0s` (`libs/LibKa0s/Options.lua`).

**Where:** `libs/LibKa0s/Options.lua:117` and `:156` cite "Ka0s standard §3.4" — the global `§N.M`
scheme the standard retired in favor of `filename-§N`; `libs/LibKa0s/Options.lua:216` cites
`options-ui-§41`, which does not exist (the section has no subsection 41; the intended reference is
the single-write-seam rule, `options-ui-§1`).

**Impact:** documentation only, but it is the seam every consumer reads when wiring its descriptor,
and an unresolvable cross-reference sends the reader looking for a rule that is not where it says.

**Fix direction:** correct the three comments in the LibKa0s repo, bump `Options.lua`'s minor, and
re-vendor the whole folder into PrettyChat and the other consumers. No edit under
`prettychat/libs/`.
