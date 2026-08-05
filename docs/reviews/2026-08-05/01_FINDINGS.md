# 01 — Findings (review of 2026-08-05)

**Verdict: minor issues — two shipped defaults raise a Lua error inside Blizzard's own chat code, and
the test case that claims to cover them cannot fail. Everything else is small.**

Reviewed at `1c19181`-era working tree of `prettychat` (`git status --porcelain` clean at start;
addon version `1.4.0`, `## Interface: 120007`). Standards cross-check performed against the **Ka0s
WoW Addon Standard v2.21.0 (2026-08-04)**, fetched from
`https://github.com/tusharsaxena/WowAddonStandards`.

---

## Measurement run (Step 0 — all suites re-run from scratch today)

| Suite | Command (repo root) | Result |
|---|---|---|
| luacheck | `luacheck .` | **pass** — `0 warnings / 0 errors in 17 files`, exit 0 |
| Headless tests | `lua5.1 tests/run.lua` | **pass** — `255 passed, 0 failed, 255 total`, exit 0 |
| Test-case inventory | `lua5.1 tests/run.lua --list > <scratch>/list.txt` | **pass** — 255 case lines; `diff <scratch>/list.txt docs/test-cases.md` is **byte-identical** |
| Offline perf | `lua5.1 tests/perf.lua` | **skipped** — no `tests/perf.lua` in the repo. This is a *recorded, declined* adoption (`docs/pending/LEDGER.md:66`, LIBKA0S-12: no event/OnUpdate/timer hot path exists), not a tooling gap. No perf claim below is measured; each is marked. |
| Complexity | `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` (verbatim) | **pass** — `Total nloc 51248 · Avg.NLOC 6.3 · AvgCCN 1.9 · Avg.token 47.5 · Fun Cnt 528 · Warning cnt 0`. **Zero functions above CCN 15.** Highest five measured today: `Database.RunMigrations` (`core/Database.lua:30-50`) **12**; `buildParentBody` (`settings/Panel.lua:302-374`) **11**; `runTest` (`settings/Slash.lua:329-376`) **11**; `PrettyChat:ApplyStrings` (`modules/Override.lua:58-96`) **11**; `sampleArg` (`modules/Override.lua:156-169`) **11**. |
| `make test` | — | **skipped** — no `Makefile` at the repo root. |
| Vendor sync | `diff -r libs/LibKa0s/ ../LibKa0s/…` | **skipped** — this run is hard-scoped to a single repo; the sibling `LibKa0s` source repo was not read. Vendor drift is therefore **unverified** today. `tests/test_harness.lua` does pin `libs/LibKa0s` against the release the README names, and that case passes. |

### Committed artifact vs. fresh run

| Artifact | Agreement |
|---|---|
| `docs/test-cases.md` | **agrees** — identical to today's `--list`, total 255. |
| `README.md:7` `Tests-255/255` badge | **agrees.** |
| `docs/automated-tests/RESULTS.md` + `20260804-233338/manifest.json` | **agrees** on every field re-measured today: lint 0/0 over 17 files, tests 255/255, nloc 51248, funcs 528, avgCCN 1.9, avgNLOC 6.3, warnings 0, maxCcn 12. Its watch-list "five nearest the threshold" also matches today's lizard output. Stamp: `startedAt 2026-08-04T23:33:38+05:30`, git `9bb28db`, `dirty: true`. |
| `docs/performance.md`, `docs/perf-runs/` | absent by design (LIBKA0S-12). Absence is an audit matter, not a review finding. |

No drift to report. The one anomaly inside a committed record is F-007, and it is upstream.

---

## Critical

### F-001 — `FACTION_STANDING_DECREASED_GENERIC` override demands an argument Blizzard never passes `[bug]`

`defaults/Defaults.lua:162-165`

The shipped default is `"…|cff76a5af%s|cffffffff | |cffffffff- %d|cffffffff"` — two conversions — but
the Blizzard string it replaces takes **one**: the repo's own reference copy has
`NS.GlobalStrings["FACTION_STANDING_DECREASED_GENERIC"] = "Reputation with %s decreased."`
(`GlobalStrings/GlobalStrings_009.lua`). Blizzard calls `format(FACTION_STANDING_DECREASED_GENERIC,
factionName)`, so once PrettyChat writes this value into `_G` (`modules/Override.lua:84`) the `%d`
has no argument and `string.format` **raises inside Blizzard's chat handler**.

The row directly above it, `FACTION_STANDING_DECREASED` (`defaults/Defaults.lua:158-161`), is
byte-identical in its format — this is a copy-paste of a two-argument default onto a one-argument
global.

*Impact:* a Lua error (and a lost chat line) every time the player loses reputation with a faction
that uses the generic message, for every user with the Reputation category enabled — which is the
default (`defaults/Defaults.lua`, `enabled = true`).

*Evidence:* computed today by comparing every `NS.Defaults[*].default`'s printf conversion sequence
against `NS.GlobalStrings[<same key>]` from the repo's own reference dump. Six arity mismatches
exist; four of them drop conversions (harmless — `string.format` ignores extra arguments) and two add
or retype them. This is one of the two.

*Fix direction:* make the override's conversion sequence a subset of the reference string's, in
order — here, drop the ` - %d` segment (or restore the `%s`-only shape). Do **not** "fix" it by
teaching `RenderSample` to tolerate it; the defect is in the data, not the preview.

### F-002 — `FACTION_STANDING_INCREASED_GUARDIAN` puts `%d` where Blizzard passes a name `[bug]`

`defaults/Defaults.lua:190-193`

The override is `"…|cffccccccGuardian|cffffffff | |cffffffff+ %d|cffffffff"` — its **first**
conversion is `%d`. The reference is `"%s has gained %d guardian experience points."`
(`GlobalStrings/GlobalStrings_009.lua`), so Blizzard passes `(guardianName, points)` and the `%d`
receives a non-numeric string. `string.format("%d", "Ulfar")` raises
`bad argument … (number expected, got string)`.

Contrast `FACTION_STANDING_INCREASED_GENERIC` (`defaults/Defaults.lua:186-189`), which correctly
drops down to the leading `%s`. Dropping *trailing* conversions is safe; dropping a *leading* one and
keeping a later one is not, because positions shift.

*Impact:* Lua error in Blizzard's chat path on every guardian-reputation gain.

*Fix direction:* keep the positions Blizzard passes — either render the name (`%s`) and then the
points (`%d`), or use explicit positional `%2$d` so the intent survives a re-read. `RenderSample`
already honours `%n$` (`modules/Override.lua:176-189`), and so does WoW's `format`.

## High

### F-003 — the case that claims to cover F-001/F-002 is tautological `[tests]`

`tests/test_defaults.lua:107-114`

> `test("every default format string renders with sample arguments", …)`

It calls `NS.RenderSample(e[3].default)`, and `RenderSample` synthesizes its arguments **from the
same string** (`modules/Override.lua:171-197, 204-210`). The case therefore asserts only that a
format string can be formatted with arguments derived from itself — which is true of every syntactically
valid format string, including both defects above. It passes today and would pass with the arity
doubled.

Its own comment states the intent that it does not deliver: *"A default whose conversions can't be
filled would show as an error line…"* — the conversions are filled by construction.

This is the shape `testing-§12` names: green that reads as coverage while providing none. It is worse
than an absent case here, because `docs/test-cases.md` lists it and the review of the defaults data
stops at it.

*Impact:* the only automated guard over the addon's core data set is inert; F-001 and F-002 shipped
in 1.4.0 under it.

*Fix direction:* assert the override's conversion sequence against `NS.GlobalStrings[<key>]` — the
reference is already loaded in the test environment — rather than against itself. That check is
mechanical (positions and `s`/number class) and would have caught both defects.

### F-004 — two different sources of truth for "the Blizzard original" `[locale] [design]`

`settings/Panel.lua:180-182` vs `modules/Override.lua:246`

The settings panel's read-only **Original** box reads the shipped enUS dump:

```lua
local origValue = (NS.GlobalStrings and NS.GlobalStrings[globalName])
                 or L["(original not available)"]
```

`/pc test` reads the live snapshot taken at `OnEnable`:

```lua
local origFmt = (addon.originalStrings and addon.originalStrings[globalName]) or _G[globalName]
```

`self.originalStrings` is captured from `_G` before any override is written
(`core/PrettyChat.lua:38-43`) and covers **exactly** the keys the panel draws — the panel only builds
a block per key in `NS.Defaults` (`settings/Panel.lua:277-285`), and the snapshot iterates the same
table. So the panel is using a *less* accurate source that it does not need:

* on a non-enUS client the panel shows the **English** original while chat, `/pc test` and the
  restore-on-disable path all use the client's localized one;
* if a Blizzard patch changes a format string, the panel shows the value as of the last
  `split_globalstrings.py` run rather than the value actually in the client — which is the exact case
  `docs/global-strings.md` tells a maintainer to verify by eye after a re-split.

`docs/global-strings.md` justifies the dump by saying it "carries the full ~22,879 … even ones the
user has added to `defaults/Defaults.lua` since the addon last shipped". That justification does not
hold: a key added to `NS.Defaults` is snapshotted by `OnEnable` on the very next login, so
`originalStrings` covers it too.

*Impact:* the panel's Original row is wrong on every non-enUS client, and can be stale on enUS.
Two surfaces disagree about the same fact.

*Fix direction:* read `PrettyChat.originalStrings[globalName]` first and fall back to
`NS.GlobalStrings[globalName]`, then to the existing `L["(original not available)"]`. Note that
`tests/test_panel.lua:309-317` pins the current behavior and must move with the change.

## Medium

### F-005 — a 2.0 MB, 22,879-entry reference dump is loaded at every login to serve 79 lookups `[perf]`

`PrettyChat.toc:38-63` (the 26 `GlobalStrings/GlobalStrings_0NN.lua` entries), consumed at exactly one
call site: `settings/Panel.lua:180`.

Measured today from the repo: the chunk files total **2.0 MB** and populate **22,879** entries into
`NS.GlobalStrings`; the addon registers **81** string rows over **79** unique globals. Every one of
those 79 is already in `self.originalStrings` after `OnEnable`, and — per F-004 — is the *better*
value. The table is also never released, so it is resident for the whole session.

*Impact:* per-login load time and a permanent resident allocation, both of which this addon otherwise
does not have (`docs/pending/LEDGER.md:66` correctly observes the addon has no hot path at all).

*Unverified:* this addon ships no `tests/perf.lua` and no `docs/perf-runs/` capture, so the cost is
stated from file size and entry count, not measured. If F-005 is acted on, the in-client
`/run collectgarbage("count")` check in `03_SMOKE_TESTS.md` is the evidence.

*Fix direction:* F-004's fix makes the eager load redundant for the panel's normal path. The
compliant sequencing is: land F-004 first (behavior), then decide the dump's fate as a separate,
measured change — `docs/global-strings.md` already documents that dropping the eager load needs a
shared accessor if it is ever wanted back. Do **not** couple the two into one commit.

### F-006 — user-facing strings outside the `L` manifest, assembled by concatenation `[locale]`

* `settings/Schema.lua:72-73` — `label = "Enable " .. category`, `tooltip = "Enable or disable all " .. category .. " string overrides."`
* `settings/Panel.lua:167-169` — `"Shared with " .. table.concat(others, ", ") .. " — both registrations write the same Blizzard global; …"`
* `settings/Panel.lua:392-394` — `defaultsTooltip = "Reset all " .. category .. " strings to defaults."`

`locales/enUS.lua:9-11` states that the seeded block "is the **authoritative manifest** of the addon's
user-facing string surface — every string wrapped in `L[...]` at a call site appears here." That claim
is *literally* true (I diffed every `L["…"]` in `core/ defaults/ modules/ settings/` against the
manifest: zero keys in either direction), and it is *materially* false: these four strings are
user-facing, in the settings UI, and reach no translator. Concatenating around an interpolated
category name also fixes English word order (`localization-§4`).

*Impact:* four visible strings are permanently untranslatable, and the manifest overstates the
surface it covers.

*Fix direction:* format strings through `L`, e.g. `L["Enable %s"]:format(category)`, with the keys
added to the manifest. Category names themselves stay untranslated — they are schema path segments.

## Low

### F-008 — a library method called through a dot `[design]`

`settings/Panel.lua:368` — `for _, line in ipairs(NS.SlashCommands.LandingRows()) do`

`libs/LibKa0s/Slash.lua:460` declares it as `function Sl:LandingRows()`. The call works only because
the body happens to ignore `self`. The degradation stub (`settings/Slash.lua:111-115`) matches the
dot form, so both paths are consistent — and both are consistent with the wrong shape.

*Impact:* none today; a silent `nil`-index the first time the library uses `self` there.

*Fix direction:* `NS.SlashCommands:LandingRows()` at the call site. The stub already tolerates the
extra argument.

### F-009 — the Options stub's "a nil reaches nothing" holds by one early return `[design]`

`settings/OptionsSetup.lua:90-95` deliberately omits `ROW_VSPACER` / `SECTION_HEADING_H` from the
degradation stub, on the stated grounds that "Every consumer of them in `settings/Panel.lua` sits
behind a maker that is a no-op on this path, so a nil reaches nothing."

Two consumers are **not** behind a maker: `settings/Panel.lua:275` does arithmetic
(`H.AddSpacer(scroll, H.ROW_VSPACER * 2)` — `nil * 2` raises, it does not no-op) and
`settings/Panel.lua:138` / `:347` call `SetHeight(H.SECTION_HEADING_H)` directly. All three are
unreachable on the degraded path only because `H.EnsureScroll` returns `nil` and each body returns at
`:268` / `:61` / `:305`. The comment describes a stronger invariant than the code has.

*Impact:* none today; a future body that draws before its `EnsureScroll` guard raises rather than
degrading. The reasoning in the comment would not warn anyone.

*Fix direction:* correct the comment to name the actual guard (the `EnsureScroll` early return), and
keep the constants out of the stub — `options-ui-§8` forbids the host copy, so importing them would
be the wrong repair.

### F-010 — `gsub`'s second return leaks into widget setters `[naming]`

`settings/Panel.lua:182` and `:248` — `origInput:SetText(origValue:gsub("|", "||"))` passes the
replacement **count** as a second argument. Harmless with AceGUI's `SetText(self, text)`, and
inconsistent with the same idiom parenthesized elsewhere in this repo (`core/Util.lua:18`,
`settings/Schema.lua:245`, `settings/Slash.lua:150`).

*Fix direction:* wrap in parentheses, as the other three sites do.

---

## Upstream findings — these do **not** land in this repo

### F-007 — the test kit records negative and falsely-precise durations `[upstream]`

**Owning repo:** `LibKa0s` — file `testkit/run-automated-tests.sh`, vendored here as
`tests/_kit/run-automated-tests.sh`.

`tests/_kit/run-automated-tests.sh:205` and `:245` bracket the complexity suite with `t0=$(date +%s)`
and `DUR[complexity]=$(( $(date +%s) - t0 ))`; `:290` and `:302` then emit
`durationMs = seconds * 1000`. Two consequences, one of them visible in this repo's committed
evidence:

1. the clock is **wall-clock and non-monotonic**, and the difference is never clamped, so a clock step
   during a suite produces a negative duration.
   `docs/automated-tests/20260804-233338/manifest.json` records
   `"complexity": { … "durationMs": -1000 … }` — a suite that ran for minus one second. The
   surrounding `RESULTS.md` prose already had to explain one instrument fault in that same run's
   numbers; this is a second, unexplained one;
2. every `durationMs` in every bundle is a multiple of 1000, because the source resolution is whole
   seconds. A field named `Ms` that can only ever carry whole seconds invites exactly the
   sub-second comparison it cannot support.

*Impact:* low, but it is a **generated artifact carrying an impossible number**, which is the class of
thing `performance-§10` treats as worse than an absent figure — it reads as measured.

*Remediation (explicitly NOT a local edit):* fix in the `LibKa0s` repo — clamp the difference at zero
and, where the shell supports it, source `SECONDS`/a monotonic clock; bump
`testkit/run-automated-tests.sh`'s kit revision; then **re-vendor the whole `testkit/` folder** into
`prettychat` (and every other consumer) as its own commit. Do not patch
`tests/_kit/run-automated-tests.sh` here — the next re-vendor silently reverts it, and the
regression then has no cause anywhere in this repo's history.

---

## What I checked and found clean (so the absence of a finding is deliberate)

* **The four LibKa0s seams** — `core/CoreSetup.lua`, `core/DebugLogSetup.lua`,
  `settings/OptionsSetup.lua`, `settings/Slash.lua`. Every member the addon calls on a stub is
  answered by that stub (checked by grepping call sites: `NS.DebugLog:ConsoleCheckbox`,
  `:SetEnabled`, `:Toggle`; `NS.Helpers.*`; `Sl:*`), and no stub re-implements a library formatter,
  line format, color code or layout constant. The `L` trap is avoided in all four.
* **TOC ordering against the load-time reads** — `core/CoreSetup.lua`'s reclaim sits immediately after
  the `NewAddon` clobber, and before `settings/Schema.lua`'s load-time `NS.Print`; verified by
  reading `PrettyChat.toc` against the call sites.
* **`Schema.FormatValue`'s pipe-doubling** (`settings/Schema.lua:231-247`) — guarded by
  `v ~= ""`, so it never doubles the library's own escapes in `lib.STRINGS.NONE`
  (`libs/LibKa0s/Slash.lua:131-134`). Correct as written.
* **Single write path** — every schema write in `core/`, `modules/`, `settings/` goes through
  `Schema.Set`; the two bulk paths (`PrettyChat:ResetAll` / `:ResetCategory`) bypass it deliberately
  and carry their own `[Reset]` summary, per `debug-logging-§9`.
* **Locale-key drift** — zero keys used but unmanifested, zero manifested but unused (see F-006 for
  the strings that never reach `L` at all).
* **Dead code** — every function exported on `NS`, `Schema`, `Util`, `Compat`, `Database` and the
  `PrettyChat` object has at least one non-test caller.
* **Load-list rot** — `tests/loader.lua:76` derives the addon's own files from `PrettyChat.toc` via
  the kit's `Loader.tocFiles` (`testing-§9`), and `tests/test_harness.lua` pins that derivation and
  the explicit `LIBKA0S` XML-order list against a fresh read. `tests/run.lua`'s suite list names all
  16 `tests/test_*.lua` files on disk.
* **Source-grep assertions** (`tests/test_libka0s.lua`) — `readFile` returns `nil` for a missing path
  and the subsequent `src:find` then raises, so a mistyped path fails loudly rather than passing
  vacuously. Not the unfalsifiable shape.
* **Deprecated APIs** — none found. `C_AddOns.GetAddOnMetadata` is used with a legacy fallback
  (`core/Compat.lua:11-19`); panel registration is `Settings.RegisterCanvasLayoutSubcategory`
  (`settings/Panel.lua:417`), not `InterfaceOptions_AddCategory`.
* **Taint / lockdown** — the addon registers no events, creates no secure frames and touches no
  protected API. The only combat-sensitive path is opening the settings panel, and the gate lives
  inside `LibKa0s-Options-1.0`'s `OpenOptionsPanel` with `PrettyChat:OpenConfig`
  (`core/PrettyChat.lua:71-73`) as a one-line delegate — `options-ui-§2`'s required shape, with no
  second un-gated open path anywhere.
