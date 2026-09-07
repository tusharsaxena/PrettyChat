# 01 — Findings

**Repo:** Ka0s Pretty Chat (`PrettyChat`) v1.4.0
**Reviewed at:** `6469f88` (`main`, clean tree)
**Date:** 2026-09-07
**Standard resolved:** Ka0s WoW Addon Standard **v2.38.0 (2026-09-02)**, fetched from
`https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master/standards/STANDARDS.md`
and all 26 section files discovered from its Sections list. The standards cross-check was
**performed**; it constrains the remediation in `02_PROPOSED_CHANGES.md` and is not a compliance audit.

---

## Verdict

**Minor issues.** The addon is green on every out-of-game suite, its library seams are unusually
well-reasoned, and nothing here loses data, taints a secure path or fails to load. Two findings are
worth fixing before the next tag: an unvalidated user-entered format string that makes Blizzard's own
chat code raise, and a hand-rolled landing page whose logo texture leaks into AceGUI's shared widget
pool — a defect the vendored library already fixes in the function this page should have called.
Everything else is stale evidence and localization residue.

---

## Measurement run (Step 0 — what was measured **today**)

Every command was run from the repo root
`/mnt/d/Profile/Users/Tushar/Documents/GIT/PrettyChat`, with output written to a scratch path
outside the repo. **No committed artifact was modified.**

| Suite | Command | Result |
|---|---|---|
| **luacheck** | `luacheck .` | **pass** — `Total: 0 warnings / 0 errors in 18 files` (exit 0). Scope: `.luacheckrc` excludes `libs/`, `tests/`, `GlobalStrings/`, `docs/audits`, `docs/reviews`. |
| **Headless suite** | `lua5.1 tests/run.lua` | **pass** — `300 passed, 0 failed, 0 skipped, 300 total` (exit 0), 18 suite files. |
| **`--list` inventory** | `lua5.1 tests/run.lua --list > <scratch>/list.md` | **pass** — 385 lines, `| **Total** | **300** |`. |
| **Inventory vs. committed** | `diff <scratch>/list.md docs/test-cases.md` | **identical** (exit 0). `docs/test-cases.md` is **current**; README badge reads `Tests-300/300_passing` and agrees. |
| **Offline perf runner** | — | **skipped (no `tests/perf.lua`)**. The addon holds a recorded `performance-§12` no-combat-path exemption; the absence is ratified, not a review finding. `docs/perf-analysis/` is likewise absent by the same row. |
| **Complexity** | `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` | **pass** — `No thresholds exceeded`, 0 warnings over **645** functions, total NLOC 52211, avg CCN 1.9. Highest CCN in the addon's own code: **`fitTree` — CCN 13**, `settings/Panel.lua:413`. |
| **`make test`** | — | **skipped (no root `Makefile`)**. The repo's canonical gate is `luacheck . && lua tests/run.lua`, per `docs/testing.md`. |
| **Vendor sync — library** | `diff -r libs/LibKa0s/ ../LibKa0s/LibKa0s/` | **pass** — no differences (sibling checkout present). |
| **Vendor sync — test kit** | `diff -r tests/_kit/ ../LibKa0s/testkit/` | **pass** — no differences. |
| **Vendor sync — in-suite gate** | `tests/test_vendor_sync.lua` (inside the run above) | **pass, not skipped** — 0 skipped in today's run, so both payload comparisons genuinely executed against the `v1.25.0` tag named in `CLAUDE.md:30`. |
| **Committed perf sweep** | the exact `grep -rEn 'RegisterEvent\|…\|C_Timer\|…'` block in `docs/performance.md:33-36` | **re-run; output disagrees with the recorded result** — see `PRETTYCHAT-R-03`. |

### Committed artifacts whose fresh run disagrees with them

| Artifact | Committed says | Fresh run says |
|---|---|---|
| `docs/test-cases.md` | 300 cases | 300 cases — **agrees** |
| `docs/automated-tests/RESULTS.md` (standing sections) | current run `20260807-114404`; **260** cases over **17** suite files; max CCN **12**; nearest-threshold five are `Database.RunMigrations` 12, `buildParentBody` 11, `runTest` 11, `ApplyStrings` 11, `sampleArg` 11 | **300** cases over **18** suite files; max CCN **13** (`fitTree`, not on the list); `ApplyStrings` now **12**. Two bundles (`20260825-103457`, and the fresh state) postdate the prose. → `PRETTYCHAT-R-05` |
| `docs/performance.md` (the committed sweep) | "**zero** `C_Timer` call" outside `.luacheckrc:42` | `settings/Panel.lua:531-532` is a live `C_Timer.After(0, …)` call. → `PRETTYCHAT-R-03` |
| `docs/ARCHITECTURE.md` invariant *"User-facing strings go through `NS.L`"* + the `localization-§1` deviation row's *"the routing SHOULD is **satisfied**"* | every user-facing string is routed, and `tests/test_locale.lua` reddens on an unwrapped one | the locale scan is structurally incapable of seeing an unwrapped string, and ~107 user-facing strings are unwrapped. → `PRETTYCHAT-R-04` |

**Nothing requiring the game client was run here.** In-client checks live in `03_SMOKE_TESTS.md`.

---

## Sweep — conventions detected (so the checks below are the addon's own)

- `CHAT_PREFIX`-equivalent: **yes** — `Const.PREFIX` / `NS.PREFIX` (`core/Constants.lua:51-52`), printer built by `LibKa0s-Core-1.0` in `core/CoreSetup.lua:123-132`. **Zero raw `print(`** in `core/ modules/ settings/ defaults/ locales/` — verified by grep.
- `COMMANDS` dispatcher table: **yes** — `settings/Slash.lua:45-66`, ten verbs, published as `NS.COMMANDS`. README documents exactly those ten; both directions check out.
- Single write path: **yes** — `Schema.Set` (`settings/Schema.lua:464`). No `db.profile…` write outside a row `set()` closure or a documented bulk reset path.
- `settings/Schema.lua` flat-row schema: **yes**, six row kinds, every row carries `page` and `group`.
- Protected-API safety doc: **no** `docs/CLAUDE_SECRET_VALUES.md`; the addon calls no protected API and reads no combat secret. `Util.SafeToString`/`IsConcatSafe` are the library's.
- `.gitattributes`: **present and correct for a client-bound repo** — `* text=auto eol=crlf` (`:26`), `*.sh text eol=lf` (`:34`), binaries marked (`:43-60`). Working tree spot-checked as CRLF (`modules/Override.lua` reads `^M$`). Observation only; the authoritative count belongs to `/wow-addon:standards-audit`.
- Vendored `libs/LibKa0s/` with its `media/` catalog: **yes**, v1.25.0, six of ten majors adopted (Core, Env, Media, DebugLog, Slash, Options), each as one setup file holding a descriptor and a degradation stub: `core/CoreSetup.lua`, `core/EnvSetup.lua`, `core/MediaSetup.lua`, `core/DebugLogSetup.lua`, `settings/Slash.lua`, `settings/OptionsSetup.lua`. Perf declined under a ratified `performance-§12` row.
- Vendored kit at `tests/_kit/`: **yes**, in sync.
- Evidence the addon generates about itself: `docs/test-cases.md`, `docs/automated-tests/` (7 frozen bundles + `RESULTS.md`), `docs/performance.md`. No `tests/perf.lua`, no `docs/perf-analysis/` — both ratified absences.

---

## High

### PRETTYCHAT-R-01 — A user-entered format is never checked against Blizzard's signature `[logic]` `[ux]`

**Where:** `settings/Schema.lua:214-234` (the `string_format` row's `set` closure) and
`settings/Schema.lua:464-481` (`Schema.Set`); `settings/Panel.lua:270-278` (the panel's *New* box);
`modules/Override.lua:286-292` (`NS.RenderSample`).

**Problem.** Nothing on the write path validates that the player's replacement consumes the same
printf conversions, in the same order, that Blizzard passes for that global. `Schema.Set` stores
whatever it is handed and `ApplyStrings` writes it straight into `_G[GLOBALNAME]`.

**Impact.** A format asking for more conversions than Blizzard supplies — `"%s %s %s"` on
`LOOT_ITEM_SELF`, which takes one — makes `string.format` raise **inside Blizzard's own chat
handler**, on every matching loot line, for the rest of the session. The addon's Preview cannot warn
about it: `buildSampleArgs` (`modules/Override.lua:253-279`) synthesizes exactly as many arguments
as the *format* asks for, so the Preview renders a wrong format perfectly and reports success. The
`Original` box beside it is the only clue, and it is read-only prose rather than a check.

**The check already exists — in the wrong place.** `tests/test_defaults.lua:174-200`
(`conversionSequence`) does precisely this comparison, and
`tests/test_defaults.lua:221-258` asserts it — but only for the **81 shipped defaults**, at test
time, against the committed `GlobalStrings/` dump. Runtime has the better reference available
already: `NS.OriginalFormat(addon, globalName)` (`modules/Override.lua:333-336`) is this client's own
pristine snapshot.

**Reachability:** *Any player who edits a format string — the addon's single advertised action —
through the panel's New box or `/pc set <Cat>.<GLOBAL>.format <text>`, on a default profile.*

**Coverage:** the inventory claims the write seam (`test_schema.lua`, `test_apply.lua`) and the
Preview (`test_render.lua`, `test_panel.lua` — *"the Preview box surfaces an unrenderable format
instead of blanking"*). No case asserts what happens when a **valid-but-wrong-arity** format is
stored, because from the Preview's point of view no such format exists. The gap is in what is
asserted, not in what is exercised.

**Fix direction.** Promote `conversionSequence` out of the suite into addon code and run it inside
`Schema.Set` for `string_format` rows, comparing against `NS.OriginalFormat`; refuse the write with a
`NS.Print` explanation naming the expected sequence. Keep it host-side — this is domain logic about
Blizzard's GlobalStrings, not a library concern, so `library-stack-§4`'s three promotion bars are not
met and it must **not** be pushed into LibKa0s.

---

### PRETTYCHAT-R-02 — The hand-rolled landing page leaks its logo texture into AceGUI's shared pool `[design]` `[ux]`

**Where:** `settings/Panel.lua:646-721` (`buildParentBody`), specifically `:665-675`.
The library's equivalent: `libs/LibKa0s/OptionsWidgets.lua:302-329` (`landingLogo`) and
`:1288-1299` (`O.BuildLandingPage`).

**Problem — two layers, one cause.**

*Layer one, the defect.* `buildParentBody` creates an AceGUI `SimpleGroup`, hangs a 300×300
`Texture` on its backing frame as `logoGroup.frame.pcLogo`, and `:Show()`s it — but never hides it
when the widget is released. `libs/AceGUI-3.0/widgets/AceGUIContainer-SimpleGroup.lua:25` has
`-- ["OnRelease"] = nil,`: SimpleGroup defines no release hook, so AceGUI hides the frame, returns it
to the **process-wide** widget pool, and the texture rides along still `Shown`. The next consumer to
acquire that SimpleGroup — this addon's own per-string `row1`/`resetRow`
(`settings/Panel.lua:210-212`, `:293-295`), or any other addon on the AceGUI pool — gets a
300×300 PrettyChat logo drawn TOPLEFT inside it. The in-code comment at `:658-664` diagnoses this
failure mode correctly and then implements only half the remedy: reuse-on-the-same-frame stops a
*second* logo accumulating, but nothing stops the *first* one showing up somewhere else.

*Layer two, why it is here at all.* The whole body is a private copy of a renderer the vendored
library owns and documents as universally adopted — `libs/LibKa0s/Options.lua:94`:
*"LANDING_LOGO — consumed by `O.BuildLandingPage`, **which every host now calls**."*
The library's `landingLogo` carries both halves (`OptionsWidgets.lua:323`:
`group:SetCallback("OnRelease", function() tex:Hide() end)`) and its comment at `:288-301` describes
this exact bug as one it was extracted to end. This is `anti-patterns` #47 / `options-ui-§5`: a
subsystem the addon consumes, re-implemented beside the library that provides it.

**Impact.** A stray 300px logo rendering inside an unrelated AceGUI group, intermittently, depending
only on pool order — in this addon's own settings pages and potentially in another addon's. No error,
no red suite; only a screenshot.

**Reachability:** *Any player who opens the PrettyChat settings landing page and then navigates to
the Categories page in the same session — the ordinary first-run path through the panel.*

**Coverage:** `tests/test_panel.lua` covers the landing page's **content** (*"the parent page lists
every slash command through the one row formatter"*, *"the parent page shows the TOC tagline"*).
Nothing asserts the texture's release behaviour, so the suite is green over the defect.

**Fix direction.** Delete the private body and call `H.BuildLandingPage(ctx, spec)` with
`logo = LOGO_PATH`, `notes = function() return NS.Meta("Notes") end` and one `sections` entry for
the slash list; add `BuildLandingPage` to the degradation stub in `settings/OptionsSetup.lua`.
**Do not** patch `libs/` — the library is already correct.

---

## Medium

### PRETTYCHAT-R-03 — The `performance-§12` exemption's committed sweep no longer describes the code `[perf]` `[docs]`

**Where:** `docs/performance.md:28-50`; the code it misses is `settings/Panel.lua:528-533`.

**Problem.** `docs/performance.md` is explicit that its sweep is *"the thing to re-run before
trusting this page"*. Re-run verbatim today it returns two hits the recorded result does not carry:

```
./settings/Panel.lua:531:    if C_Timer and C_Timer.After then
./settings/Panel.lua:532:        C_Timer.After(0, function() fitTree(ctx) end)
```

while the page asserts *"**zero** `C_Timer` call"* (`:48-49`). Separately, the recorded result at
`docs/performance.md:44` lists `combatWatcher:UnregisterEvent(event)` — a line the stated
**case-sensitive** regex cannot match, since `UnregisterEvent` does not contain `RegisterEvent`. The
recorded block was therefore hand-composed rather than pasted from the command above it.

**Assessment.** Criterion (a) most likely still holds — `C_Timer.After(0, …)` is a **one-shot**
scheduled from a settings-panel render, not a ticker, and it cannot fire during combat because
`SetRenderer` refuses to render under lockdown (pinned by `tests/test_libka0s.lua:426-450`). So the
exemption is probably still sound; what is broken is its **evidence**, and an exemption whose stated
proof no longer reproduces is one nobody can check.

**Reachability:** *A maintainer or auditor re-running the documented sweep — no runtime effect.*

**Fix direction.** Re-run the sweep, paste its **verbatim** output, and add a sentence disposing of
the `C_Timer.After` hit (one-shot, render-path, lockdown-gated). Re-check the `performance-§12` row's
trigger wording while there. Do **not** widen the regex to hide the hit.

---

### PRETTYCHAT-R-04 — The locale drift cases cannot detect an unwrapped string, and the docs claim they can `[tests]` `[locale]`

**Where:** `tests/test_locale.lua:41-93`; claims at `docs/ARCHITECTURE.md` (`## Invariants`, last
bullet) and in the `localization-§1` deviation row.

**Problem.** The scan builds `callSites` from `body:gmatch('L%[%s*"(.-)"%s*%]')` — it can only ever
see strings that are **already** wrapped. Both drift cases then compare that set against the manifest
in both directions. An unwrapped user-facing string never enters `callSites` and therefore cannot
redden anything. The suite's comment (`:1-7`) and `ARCHITECTURE.md`'s invariant both state the
opposite: *"an unwrapped new string … surfaces here instead of at a translator's desk"*.

**What the gap actually holds.** Measured today by grep over `core/ modules/ settings/ defaults/`:

- **`defaults/Defaults.lua`** — 81 `label = "…"` values (`"Battle Pet Loot"`,
  `"Item Looted Multiple (Other)"`, …). Every one is user-facing: they are the schema row labels and
  the TreeGroup row text (`settings/Panel.lua:387`).
- **`settings/Slash.lua`** — ~20 chat lines: `"schema not ready yet"` (`:36`),
  `"unknown command '"` (`:99`), `"Categories ("` (`:207`), `"Format strings ("` (`:226`),
  `"unknown category '"` (`:241`, `:355`), `"all settings reset to defaults"` (`:298`),
  `"debug console unavailable"` (`:320`), four `"usage: "` lines, and the three-line `reset`
  deprecation notice (`:278-284`).
- **`modules/Override.lua`** — the whole `/pc test` report: `"Category: "` (`:364`),
  `LABEL.name/original/formatted` (`:15-19`), `"end of test output …"` (`:379`),
  `"(no matching strings)"` (`:428`), `"(addon is currently disabled …)"` (`:411`).

**Note on severity.** Shipping English-only is a *terminal compliant state* under `localization-§3`
once recorded, and it **is** recorded. The finding is not "translate these". It is that the register
row asserts the routing SHOULD is *satisfied* and cites a test as proof, and neither is true — so an
auditor reading the register is told a check exists that does not.

**Reachability:** *A maintainer or auditor reading the register and the suite; and a future
translator, who would find a third of the surface unreachable. No player-visible defect today.*

**Fix direction.** Either (a) correct the register row and the `ARCHITECTURE.md` invariant to state
the real extent of the routing, or (b) add a genuine unwrapped-string detector (a heuristic scan for
`SetText("…")` / `NS.Print("…")` with prose arguments) and route what it finds. (a) alone closes the
false claim; do not weaken the existing cases.

---

### PRETTYCHAT-R-05 — `RESULTS.md`'s standing sections are two runs stale; `fitTree` has crossed the recorded maximum `[complexity]` `[docs]`

**Where:** `docs/automated-tests/RESULTS.md:44` (test count), `:48` (lint scope), `:55-74`
(complexity watch list), `:84-93` (layout bands).

**Problem.** The bundle **table** carries a row for `20260825-103457` (`:25`, 271 cases), but every
standing narrative section still reads `20260807-114404` as current: *"260 cases, across 17 suite
files"* (`:44`), *"Clean over 17 files"* (`:48`), *"Current state as of `20260807-114404`"* (`:55`),
*"Zero warnings over 531 functions … the maximum **measured** at 12"* (`:64-65`).

**Fresh run (today, same invocation):** 300 cases over **18** suite files; luacheck clean over
**18** files; **645** functions; **maximum CCN 13**. The five named nearest-threshold functions have
moved:

| Function | `RESULTS.md` | Today |
|---|---|---|
| `fitTree` (`settings/Panel.lua:413-436`) | **not listed** | **13** — the new maximum |
| `PrettyChat:ApplyStrings` (`modules/Override.lua:122-164`) | 11 | 12 |
| `Database.RunMigrations` (`core/Database.lua:30-50`) | 12 | 12 |
| `buildParentBody` (`settings/Panel.lua:646-721`) | 11 | 11 |
| `runTest` (`settings/Slash.lua:336-383`) | 11 | 11 |
| `sampleArg` (`modules/Override.lua:238-251`) | 11 | 11 |

Newest committed bundle stamp: `manifest.json` `"run": "20260825-103457"`, `"startedAt"`
2026-08-25, git sha of a prior tree. **Stale is stale, not non-compliant** — regeneration belongs to
release (`automated-tests-§4`), not to this review.

**Note on `fitTree` itself.** CCN 13 in Lua is not tangled control flow here: `lizard` scores every
`and`/`or` as a decision, and `fitTree` is six guarded reads and two clamps (`performance-§10`).
`PRETTYCHAT-R-02`'s remedy removes `buildParentBody` outright, which will move that row down.

**Reachability:** *A maintainer reading the trend line — no runtime effect.*

**Fix direction.** At the next release run (`/wow-addon:bump-version`), regenerate and let the
standing sections re-derive; add `fitTree` to the nearest-threshold list when they do. Never
hand-edit the numbers.

---

### PRETTYCHAT-R-06 — Slash error and usage lines are built by concatenating translated fragments `[locale]`

**Where:** `settings/Slash.lua:241-242`, `:278-284`, `:349-350`, `:355-356`, `:365-366`,
`:371-372`, `:379-382`.

**Problem.** These lines are assembled as `note("unknown category '") .. arg .. note("'. Valid: ")
.. table.concat(...)`. Even were the fragments routed, the shape pins English word order and leaves a
translator nothing to reorder — the exact construction `localization-§1` names, and the one the addon
already fixed everywhere else (the `Enable %s` / `Shared with %s …` rows in `locales/enUS.lua:56-58`
carry the format-string form deliberately, and `settings/Panel.lua:234-239` says so).

**Impact.** The addon's most-read chat surface — the one a confused user hits — is the least
translatable part of it, and it is inconsistent with the panel beside it.

**Reachability:** *Any player who mistypes a category or a verb (`/pc list Lot`, `/pc test foo`) —
a normal path on a default profile. English-only today, so no visible defect; the cost is structural.*

**Fix direction.** Rewrite each as one `L["…%s…"]:format(...)` sentence with the color escapes
applied **outside** the routed string, exactly as `settings/Panel.lua:234-239` already does, and add
the keys to the `locales/enUS.lua` manifest. Groups naturally with `PRETTYCHAT-R-04`.

---

### PRETTYCHAT-R-07 — A global absent from this client is never restored when the addon is switched off `[logic]`

**Where:** `modules/Override.lua:150-158`, specifically `:154`:
`elseif self.originalStrings and self.originalStrings[globalName] then`.

**Problem.** The restore branch is gated on the **truthiness** of the snapshot entry. `OnEnable`
snapshots `self.originalStrings[globalName] = _G[globalName]` (`core/PrettyChat.lua:82-86`), so a
`GLOBALNAME` in `NS.Defaults` that this client does not define stores `nil`. The apply branch happily
writes that key; the restore branch then skips it, and the override survives every subsequent
`Enable off`, `visibility = never`, category disable and per-string disable for the rest of the
session.

**Impact.** A one-way write: the user turns the addon off and one chat line stays rewritten, with no
way back short of `/reload`. Also self-inconsistent — `ApplyStrings`' own contract is *"the master
toggle wins"* (`docs/ARCHITECTURE.md`, `## Invariants`), and here it does not.

**Reachability:** *Only on a client where one of the 81 globals is undefined — a Classic build, or a
Retail patch that retires a string. `tests/test_defaults.lua` pins all 81 against the committed
Retail dump, so no shipping Retail client reaches it today. It becomes reachable the first time
Blizzard removes one.* Capped at Medium for that reason, despite the defect kind.

**Fix direction.** Replace the truthiness gate with `~= nil`, and record the absent key once at
`OnEnable` so an undefined global is visible in the debug console rather than silently one-way. This
is `savedvariables`' `== nil`-rather-than-`or` rule applied to a snapshot rather than to storage.

---

### PRETTYCHAT-R-08 — Production logic lives only in the test suite `[design]` `[tests]`

**Where:** `tests/test_defaults.lua:169-200` (`conversionSequence`), used at `:221-258`.

**Problem.** The one piece of code that knows how to compare a format's conversion sequence against
Blizzard's — the invariant `docs/ARCHITECTURE.md` calls out as *"Format-specifier signatures must
match Blizzard's"* — is a file-local in a test file. It cannot be called from `Schema.Set`, from the
panel, or from `/pc set`, which is why `PRETTYCHAT-R-01` exists. It also duplicates, in a fourth
spelling, the printf-walking that `modules/Override.lua:253-279` already does for `buildSampleArgs`.

**Reachability:** *A maintainer implementing `PRETTYCHAT-R-01`, who finds the logic present but
unreachable. No runtime effect on its own.*

**Fix direction.** Move a single conversion-sequence parser into `modules/Override.lua` beside
`buildSampleArgs`, publish it as `NS.ConversionSequence`, and have both the suite and the new write-
path validation call it. One implementation, three consumers — which is the shape, not the
`library-stack-§4` promotion case; it stays in this addon.

---

## Low

### PRETTYCHAT-R-09 — `core/MediaSetup.lua` says nothing types a texture path; `settings/Panel.lua` types one `[naming]` `[docs]`

`core/MediaSetup.lua:54-58` states *"PrettyChat builds no frames of its own today, so nothing in this
addon calls this yet … The seam is published anyway so the first window this addon does build asks
the catalog rather than typing a path"*, and `:38-40` warns that *"a path built by concatenation …
draws nothing and raises nothing"*. `settings/Panel.lua:31-32` then does exactly that:
`"Interface\\AddOns\\" .. addonName .. "\\media\\logos\\prettychat.logo.tga"` — extension included,
outside the seam. The logo is genuinely this addon's art (`media/logos/`, correctly typed per
`layout-§4`) and is **not** something the shared catalog ships, so the path is legitimate; the
comment is what is wrong. **Reachability:** *A reader of the comment; no runtime effect.*
**Fix:** correct the comment to name `settings/Panel.lua` as the one host-side path and say why it is
outside the catalog. Note `PRETTYCHAT-R-02` moves this path into `BuildLandingPage`'s `spec.logo`,
which is still a host-supplied path — the comment needs fixing either way.

### PRETTYCHAT-R-10 — The vendor-sync suite quotes a provenance version two majors stale `[docs]`

`tests/test_vendor_sync.lua:25` cites the gate's input as *"the `Bundles [LibKa0s](...) v1.10.2
(MIT).` sentence"*; `CLAUDE.md:30` reads **v1.25.0**. The gate matches the line by **pattern**, not
by the version, so the test is correct and passed today — only the illustrative quote is stale.
**Reachability:** *A reader of the comment; no runtime effect — the gate ran and passed today.*
**Fix:** drop the version from the quoted example, or cite the pattern rather than an instance.

### PRETTYCHAT-R-11 — Three published namespace seams have no caller `[design]`

`NS.Icon` (`core/MediaSetup.lua:62`), `NS.MakeCloseButton` (`core/CoreSetup.lua:111`) and `NS.Format`
(`core/CoreSetup.lua:78` / `:132`) are each reachable only from their own definition — verified by
grep across `core/ modules/ settings/`. All three are **deliberate**, argued in place, and two of the
three are exactly the "publish it so the next call site does not type a path" pattern the collection
wants. The residual cost is real though: an unexercised seam is one whose degraded and live halves
have never been compared by anything but a stub-parity grep. **Reachability:** *Nobody today; the
first future caller.* **Fix:** leave them, and note the intent in `docs/module-map.md` so a later
sweep does not read them as dead. `PRETTYCHAT-R-02`'s remedy gives `NS.MakeCloseButton` no caller
either — the library draws the close control.

### PRETTYCHAT-R-12 — `OnInitialize` mutates the module-level defaults table in place `[savedvariables]`

`core/PrettyChat.lua:20-25` takes `local defaults = NS.ProfileDefaults` and then writes
`defaults[k] = defaults[k] or v`, grafting `NS.Database.defaults.global` onto the module-level table
that `defaults/Profile.lua:15-19` published. It is idempotent, runs once per session before
`AceDB:New`, and AceDB deep-copies defaults into the DB rather than aliasing, so nothing observable
breaks. It is still the "mutating the defaults table at runtime" shape, and it makes
`NS.ProfileDefaults` mean two different things depending on when it is read. **Reachability:**
*Nobody today — one write, before the only reader.* **Fix:** build a fresh merged table
(`local defaults = { profile = NS.ProfileDefaults.profile }` plus the global merge) so
`NS.ProfileDefaults` stays the literal `defaults/Profile.lua` declares.

---

## Upstream findings

**None.** `libs/LibKa0s/` and `tests/_kit/` both diff clean against `../LibKa0s` at v1.25.0, and no
defect in this review lands in vendored code. `PRETTYCHAT-R-02` is the reverse case — the library is
**correct** and the addon has a private copy beside it; the remedy is adoption in this repo, not an
edit anywhere under `libs/`.

---

## Explicitly checked and clean

Recorded so the next reviewer does not re-derive them.

- **Taint / lockdown.** No protected API call, no secure frame, no `SecureActionButtonTemplate`, no
  `:Hook` on a secure function. `Settings.RegisterCanvasLayoutSubcategory` runs from `OnEnable`
  (`settings/Panel.lua:742`, `:774`) via `NS.Config.RegisterPanels`, which is correct for a non-LoD
  addon. The panel-open's `InCombatLockdown()` gate lives inside the library's `OpenOptionsPanel` and
  `PrettyChat:OpenConfig` (`core/PrettyChat.lua:119-121`) is a one-line delegate with no second path
  — `options-ui-§2` satisfied. `SetRenderer` adds a second guard on the render, pinned by
  `tests/test_libka0s.lua:426-450`.
- **Secret values.** No `C_Spell.*`, no `UnitCastingInfo`, no aura API, no cooldown API anywhere in
  the addon's own code. `Util.SafeToString` / `IsConcatSafe` are bound to the library's
  implementations (`core/CoreSetup.lua:90-91`) rather than re-spelled.
- **Events.** Two, both on a lazily-created plain frame, both registered only while
  `General.visibility` is combat-scoped, both unregistered when it is not
  (`modules/Override.lua:75-97`). No `UNIT_AURA`, no `BAG_UPDATE`, no unfiltered unit event.
  Re-registration is idempotent.
- **Deprecated APIs.** None. `C_AddOns.GetAddOnMetadata` is reached through the `LibKa0s-Env-1.0`
  seam with a correct fallback ladder (`core/EnvSetup.lua:70-79`). No `GetSpellInfo`, `UnitAura`,
  `GetContainerItemInfo`, `IsAddOnLoaded` or `InterfaceOptions_AddCategory` anywhere.
- **Frames.** One named frame created in the whole addon (`PrettyChatCombatWatcher`,
  `modules/Override.lua:80`) and it is created at most once. No per-event `CreateFrame`. No
  `setmetatable` on a widget. `ClearAllPoints` precedes the one `SetPoint`
  (`settings/Panel.lua:672-673`).
- **Saved variables.** `AceDB:New` in `OnInitialize` only; `schemaVersion` + a real migration runner
  (`core/Database.lua`); the three profile callbacks are wired and share one body
  (`core/PrettyChat.lua:54-74`); the global reset is `db:ResetProfile()` per `options-ui-§12`
  (`modules/Override.lua:203-206`) and is fronted by the collection's verbatim confirmation wording
  (`settings/Panel.lua:41-53`). `sessionOnly` on the console row is set by the composer
  (`libs/LibKa0s/OptionsCompose.lua:386`) and honoured at `settings/Schema.lua:472`, so toggling the
  console does not drag an `ApplyStrings` pass behind it.
- **Descriptor / stub parity.** All six adopted majors carry both halves. The Options stub's
  one load-reached member (`MasterControls`) is **measured** rather than reasoned
  (`tests/test_libka0s.lua:450+`, comparing degraded row count against a full load). No stub
  re-implements a formatter, a colour code or a layout constant — `tests/test_libka0s.lua:320-324`,
  `:496-497`, `:596-597` grep for exactly that. The `NS.L`-into-a-descriptor trap is grepped for
  across every seam file (`:354`).
- **`COMMANDS` ↔ README.** Ten verbs in the table, ten documented, ten reachable through the
  dispatcher. `NS.COMMANDS` is published as positional triples and both surfaces render it through
  one formatter.
- **Falsifiability spot-check.** The negative assertions carry their falsification: the
  degraded-load cases assert the library genuinely failed to register before asserting on the stub
  (`tests/test_libka0s.lua:608-611`, `tests/test_envsetup.lua:125`), and the lockdown case pairs its
  three `nil` assertions with a positive one on the refusal message
  (`tests/test_libka0s.lua:445-449`). Twelve `-- red under:` comments across five suites. Degraded
  paths are exercised by **loading with the file skipped** (`tests/loader.lua:112-115`), not by
  hand-stubbing — `testing-§8` satisfied.
- **Load lists.** Both derived: `Loader.tocFiles("PrettyChat.toc")` and
  `Loader.xmlFiles("libs/LibKa0s/LibKa0s.xml")` (`tests/loader.lua:43`, `:78`). No hand-typed path.
- **TOC.** Single Interface `120007`; field order and section comments conform; every position that
  is load-bearing says so and the claim holds (`EnvSetup` before `Namespace`, `MediaSetup` before
  `Constants`, `CoreSetup` after `PrettyChat.lua`, `Schema` before `OptionsSetup` before `Panel`).
  `GlobalStrings/` carries no TOC line and is `.pkgmeta`-ignored. SavedVariable is `PrettyChatDB`.
