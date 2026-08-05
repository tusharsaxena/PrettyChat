# 03 — Evidence (Ka0s Pretty Chat)

**Run date:** 2026-08-05 · **Standard:** v2.21.0 · **HEAD:** `a2ba8f8` · working tree otherwise clean
(only `docs/reviews/2026-08-05/` and this bundle are untracked).

Every claim below is either a `file:line` citation or a command with its **actual** output. Checks
that could not be run are recorded as **NOT RUN**, never inferred.

---

## Part A — Mechanical checks (run, not reasoned about)

### A1. Lint — PASS

```
$ luacheck .
Checking core/Compat.lua        OK
… 17 files …
Total: 0 warnings / 0 errors in 17 files
exit=0
```

Scope note (`docs/testing.md:47-51`): the 17 files are the addon's own source; `libs/`, `tests/`,
`GlobalStrings/`, `docs/audits`, `docs/reviews` are excluded by `.luacheckrc:14-21`. All four seam
files are inside the checked set — `core/CoreSetup.lua`, `core/DebugLogSetup.lua`,
`settings/OptionsSetup.lua`, `settings/Slash.lua` each appear in the run above.

### A2. Headless harness — PASS

```
$ lua5.1 tests/run.lua
…
255 passed, 0 failed, 255 total
exit=0
```

### A3. Test-case inventory sync — PASS

```
$ lua5.1 tests/run.lua --list > /tmp/pc-list.md
$ diff --strip-trailing-cr /tmp/pc-list.md docs/test-cases.md
(no output)
```

`docs/test-cases.md` is 332 lines and byte-in-sync with `--list`. The README badge
(`README.md:7`, `Tests-255%2F255_passing`) matches (`testing-§5`, `documentation-§1` keep-in-sync rule).

### A4. Complexity — MEASURED, and **zero drift**

Invocation taken verbatim from `performance-§10` / `AUDIT.md`; no extra flags, no narrowed path:

```
$ lizard --version
1.23.0
$ lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .
…
No thresholds exceeded (cyclomatic_complexity > 15 or length > 1000 …)
Total nloc  Avg.NLOC  AvgCCN  Avg.token  Fun Cnt  Warning cnt  Fun Rt  nloc Rt
    51248       6.3     1.9       47.5      528            0    0.00    0.00
exit=0
```

Compared against the latest run bundle (`docs/automated-tests/20260804-233338/complexity.txt`):

```
$ diff <(sed 's/\r$//' <today's lizard output>) <(sed 's/\r$//' docs/automated-tests/20260804-233338/complexity.txt)
IDENTICAL
```

**Drift: none.** No function crossed a `lizard` threshold and no file entered `layout-§1`'s 1000–1500
band since that bundle. The manifest agrees with the code:
`docs/automated-tests/20260804-233338/manifest.json` records
`"complexity": { "status": "pass", "warnings": 0, "maxCcn": 12, "nloc": 51248, "functions": 528, "avgCcn": 1.9 }`.
The record is **not stale** and shows no sign of hand-editing (anti-pattern #51 clear).

Staleness of the bundle's own stamp: `20260804-233338` is **one day old**, taken at `9bb28db`
(`"git": { "sha": "9bb28db…", "branch": "feat/fix-ccn", "dirty": true }`) — three commits behind HEAD
`a2ba8f8`, all three of which are documentation-only (`53b2121`, `a2ba8f8`) or a merge of the branch
the bundle was taken on (`2b99dc3`). That is why the numbers still match exactly.

Watch list read as a decision record (`RESULTS.md:42-65`):

- **Functions warned on: "None."** — an empty list written as a result, not a dropped heading
  (`performance-§10`). The five functions nearest the threshold are named rather than counted
  (`Database.RunMigrations` 12, `PrettyChat:ApplyStrings` 11, `sampleArg` 11, `runTest` 11,
  `buildParentBody` 11), which is what makes the next regression visible.
- **Files by band: one entry**, `GlobalStrings/GlobalStrings.lua` (23,842 LOC, over cap), disposition
  *Accepted — not shipped and not loaded*. Consecutive **release** runs carrying that disposition:
  **zero** — all three bundles record `"release": null`
  (`20260804-233338/manifest.json`), so anti-pattern #53's three-run shelf life has not started. One
  entry is not a backlog wearing a watch list's clothes.
- `RESULTS.md:21-28` explains the `Max CCN 0` in `20260804-214445` as an **instrument fault** (a
  pre-rev-6 kit read `CCN_MAX` out of the warnings block) and leaves the generated row **unedited**,
  which is the behavior `performance-§10` requires.

### A5. Artifact audit against `automated-tests`

| Check | Result | Evidence |
|---|---|---|
| Runner vendored at `tests/_kit/run-automated-tests.sh` | ✅ | `-rwxrwxrwx … 23340 tests/_kit/run-automated-tests.sh` — present and **executable** |
| `.gitattributes` carries `*.sh text eol=lf` | ✅ | `.gitattributes:29` (with the `bash\r` rationale written above it) |
| `docs/automated-tests/README.md` | ✅ | 52 lines |
| `docs/automated-tests/RESULTS.md` | ✅ | one file, one path, three rows, two watch-list tables |
| Bundles frozen, not pruned | ✅ | `20260804-182235`, `20260804-214445`, `20260804-233338` all retained |
| `ANALYSIS.md` per bundle | ✅ (SHOULD) | present for `-182235` and `-233338`; absent for `-214445`, and `RESULTS.md:6-9` + `README.md:41-45` say why (`"release": null` → skipped SHOULD, not a missed MUST) |
| Retired `docs/complexity.md` still present? | ✅ **No** | `ls docs/` → `ARCHITECTURE.md audits automated-tests common-tasks.md file-index.md global-strings.md module-map.md override-pipeline.md pending reviews schema.md scope.md settings-panel.md slash-commands.md smoke-tests.md superpowers test-cases.md testing.md` — no `complexity.md` (closes **PC-55**) |

### A6. Vendored Ka0s-owned library drift — **NOT RUN**

The Ka0s-owned library under `libs/` is `LibKa0s` (`library-stack-§7`). Both mandated diffs were
**not run**:

```
diff -r ../LibKa0s/LibKa0s libs/LibKa0s      # NOT RUN
diff -r ../LibKa0s/testkit tests/_kit        # NOT RUN
```

**Reason:** this run operates under an explicit single-repo scope — `/mnt/…/GIT/prettychat` only — and
reading the sibling `/mnt/…/GIT/LibKa0s` checkout was out of bounds. The path that would have been
used is `../LibKa0s/LibKa0s` (ship folder) and `../LibKa0s/testkit` (harness, a **sibling** of the ship
folder, landing under `tests/`, never `libs/`).

**This check is therefore UNVERIFIED, not passed.** Drift here is invisible to both suites — the
library's suite passes against the library, this addon's 255 cases pass against whatever copy is on
disk, and both repos stay green while diverging (anti-pattern #45). What *can* be said from inside the
repo, and what it does not prove:

- The vendoring is **structurally whole**, which is the #48 half: `libs/LibKa0s/` holds
  `Core.lua`, `DebugLog.lua`, `Slash.lua`, `Options.lua`, `OptionsWidgets.lua`, `OptionsScroll.lua`,
  `Perf.lua`, `PerfPanel.lua`, `LibKa0s.xml`, `LICENSE` — all five majors including both attach files
  of Options and Perf's `PerfPanel.lua`. `libs/LibKa0s/LibKa0s.xml` lists exactly those eight scripts,
  and `PrettyChat.toc:22` loads that one aggregate file. No individual module `.lua` appears in the TOC.
- `tests/_kit/` holds `framework.lua`, `loader.lua`, `mock_base.lua`, `README.md`,
  `run-automated-tests.sh` and nothing else; **no harness file exists under `libs/`**.
- `tests/test_harness.lua:120-121` runs the byte-identity comparison mechanically **when the sibling
  checkout is present** (`io.popen('git -C "<root>/../LibKa0s" show …')`) — and `DEPENDENCIES.md:98`
  records that it **goes quiet rather than failing** when `git` or the sibling is missing. A green
  suite today therefore does not assert vendor sync either.

Re-run both diffs in a session with the sibling repo in scope before any release.

### A7. Not applicable / not present

- `make test` — **NOT RUN**: no `Makefile` in the repo.
- `lua tests/perf.lua` — **NOT RUN**: no `tests/perf.lua` (that absence is **PC-43**).

---

## Part B — Evidence per deviation

### PC-25 — generated-data folder outside the skeleton

- `GlobalStrings/GlobalStrings_001.lua` … `_026.lua`, `GlobalStrings/GlobalStrings.lua`,
  `GlobalStrings/README.md`, `GlobalStrings/split_globalstrings.py` — a **root-level PascalCase**
  folder; `layout-§1` puts source under `core/ defaults/ settings/ locales/ modules/` and `layout-§2`
  makes subfolders lowercase.
- `PrettyChat.toc:42` — `# GlobalStrings (generated Blizzard reference data — must precede settings\Panel.lua)`,
  a section `toc-file-§5`'s fixed set (`Libraries → Locales → Core → Defaults → Modules → Settings`)
  does not admit; it sits between `# Defaults` (`:38`) and `# Modules` (`:70`).
- Recorded: `CLAUDE.md:8` — "a **generated-data folder at the repo root** … it stays a documented root
  exception". The record names `layout`; it does not name `layout-§2` or `toc-file-§5`.

### PC-40 / PC-41 / PC-42 / PC-43 / PC-44 / PC-45 — the perf cluster

- No `core/PerfSetup.lua` in the repo file list; `PrettyChat.toc:27-36` (`# Core`) lists nine files and
  none of them is a Perf seam. `grep -n "LibKa0s-Perf-1.0"` over `core/ settings/ modules/` finds
  nothing — while `libs/LibKa0s/Perf.lua` and `libs/LibKa0s/PerfPanel.lua` **are** vendored and
  `libs/LibKa0s/LibKa0s.xml:8-9` loads them. The library is shipped to every player and never wired
  (`performance-§1`: MUST for the wiring).
- `PrettyChat.toc:7` — `## SavedVariables: PrettyChatDB` (one global; `toc-file-§2` mandates two).
- `settings/Slash.lua:45-70` — the ten `COMMANDS` triples: `help`, `config`, `version`, `list`, `get`,
  `set`, `reset`, `resetall`, `test`, `debug`. No `perf` (`slash-commands-§2`, `performance-§4`).
- No `tests/perf.lua`; consequently
  `docs/automated-tests/20260804-233338/manifest.json` records
  `"perf": { "status": "skip", "skipReason": "no tests/perf.lua — this addon ships no offline scenarios" }`,
  and `RESULTS.md:38-40` states plainly that the record "says **nothing** about the addon's runtime
  cost" and that `performance-§9`'s zero-overhead evidence "does not exist for it."
- No `docs/performance.md`; no `docs/perf-runs/` directory at all (see the `ls docs/` output in A5).
- `.luacheckrc:39-62` (`read_globals`) contains no `debugprofilestop`; `.luacheckrc:31-36` (`globals`)
  contains `PrettyChatDB`, `StaticPopupDialogs`, `UISpecialFrames` and no `PrettyChatPerfDB`.
- The decline is written down: `CLAUDE.md:6` ("**Perf is declined**, on two structural grounds recorded
  at `LIBKA0S-12`: the addon registers no events, no timers and no ticker … `suspend` would flip the
  player's chat formatting back to Blizzard's mid-fight") and `docs/pending/LEDGER.md:66`. The
  no-event claim is itself sourced: `docs/ARCHITECTURE.md:119` — "**None by design** … zero
  `RegisterEvent`, zero `OnUpdate`, zero `C_Timer`, zero ticker."

### PC-46 / PC-47 — README

- `README.md:116` — ``| I want a clean slate | One message: its **Reset** button, or `/pc reset <setting>`. …``
  The same command is spelled correctly at `README.md:63` (`` `/pc reset setting` ``), which is what
  makes this a transcription miss rather than a style choice. A repo-wide grep for `<setting>`,
  `<name>`, `<value>`, `<path>` in `README.md` returns this one line and nothing else.
- `README.md:15` — `## Unreleased`, sitting between the Description (`:11-13`) and
  `## What's new in 1.4.0` (`:21`).
- `README.md:120` — `## Credits`, sitting between `## Troubleshooting` (`:109`) and
  `## Issues and feature requests` (`:124`).
- The canonical order is otherwise intact: H1 `:1`, five badges `:3-7` in template order (the standard
  badge uses `_` not `%20` at `:6`), logo `:9`, description, What's new, Screenshots `:28`, Usage `:49`
  with both subsections, How it works `:86`, FAQ `:97`, Troubleshooting `:109`, Issues `:124`,
  Version History `:128`. `## What's new in 1.4.0` and the top Version History row (`:132`, `1.4.0`)
  agree, so anti-pattern #40 is clear.

### PC-48 — root `CLAUDE.md` is a brief, not a stub

- 64 lines. `CLAUDE.md:5-13` — nine bullets, six of them multi-sentence accepted-deviation records
  (`:8` generated data, `:9` console font, `:10` TOC branding + X-Wago-ID, `:11` per-string editor,
  `:12` test harness, `:13` TOC section order, several running to 6+ lines).
- `CLAUDE.md:14` — `## Standards compliance (read first)`, i.e. **after** all six, where
  `documentation-§2` places it third, immediately after the adherence line.
- `CLAUDE.md:50-63` — `## Before touching code` and `## Non-negotiable guardrails` (eight bullets
  including code invariants, badge-sync rules and git policy) — brief content, not stub content.
- The stub's mandated items *are* all present and correct in substance (H1 `:1`, adherence `:7`,
  compliance section `:14-31` verbatim, docs pointer `:52`, green gate `:59`); the deviation is bulk
  and order, not absence.

### PC-49 — the LOC cap, reduced

- `wc -l GlobalStrings/GlobalStrings_0*.lua` → every chunk **882**; 22,931 total across 26 files.
  Under the 1500 cap and under the 1000 on-notice threshold (`layout-§1`).
- `GlobalStrings/GlobalStrings.lua` → **23,842** lines. Not in the TOC (no line between
  `PrettyChat.toc:42-68` names it) and excluded from the package at `.pkgmeta:21`.
- `docs/automated-tests/RESULTS.md:65` carries it as the sole watch-list band entry with the
  disposition *"**Accepted — not shipped and not loaded.** … `layout-§1` caps files a reader has to
  change."*
- Largest addon-owned file: `settings/Panel.lua` 423 lines. Nothing else is close.

### PC-50 / PC-53 — no bus, and no heading for it

- `docs/ARCHITECTURE.md:119` — "There is no message bus." — the last sentence of `## Event
  Subscriptions`, not a section of its own.
- `grep -n '^## ' docs/ARCHITECTURE.md` → Overview, Module Map, Namespace publishing pattern,
  Invariants, Settings Schema, Slash Commands, Event Subscriptions, Taint Notes, Known Limitations,
  External dependencies, Testing, Working environment, Doc index. **No `## Message Bus`**
  (`documentation-§3` fixes the section list).
- Direct cross-module calls: `modules/Override.lua:100-102,112-113,130-131` →
  `NS.Schema.NotifyPanelChange`; `settings/Schema.lua:270-272` → `NS.Helpers.RefreshScalars`
  (`architecture-§4`, anti-pattern #19).

### PC-57 — the release gate is not stated anywhere

- `docs/testing.md:106-112` — the suite table, `| complexity | lizard … | no — recorded only |`, with
  no release column.
- `docs/testing.md:113-116` — "**`perf` and `complexity` never fail a run.** … They contribute
  `amber`, which is a signal rather than a stop."
- `docs/testing.md:120-121` — "**At release, not at commit.** A full bundle is produced as part of
  every version bump, before the tag, with an `ANALYSIS.md` write-up. Commits are gated on lint +
  tests only." — correct about the *bundle*, silent about the *gate*.
- `docs/automated-tests/README.md:19-29` — the same table and the same "never used to fail a run"
  paragraph.
- `docs/automated-tests/RESULTS.md:11-13` — "**`lint` and `tests` gate. `perf` and `complexity` are
  recorded and never fail a run**".
- The rule missed: `automated-tests-§3`, *The release gate* — "**MUST NOT** cut a release … unless the
  release run's `manifest.json` shows **all four** suites at `pass`, and `suites.complexity.warnings`
  at **0**", with "**MUST** treat a **skip** as a gate that did **not pass**" and the narrow
  no-`tests/perf.lua` exception. Also `automated-tests-§6` and `performance-§10`'s checkpoint bullet.
- Note the addon is in **no danger of failing** that gate on complexity today (A4: 0 warnings, max CCN
  12). The finding is that the documented process would not know to check, and that its `perf` skip is
  exactly the case the standard says **MUST** be stated in the release notes.

### PC-58 — a test that cannot fail

- `tests/test_defaults.lua:107-114`:
  ```lua
  test("every default format string renders with sample arguments", function()
      -- A default whose conversions can't be filled would show as an error
      -- line in the panel preview and in /pc test for every user.
      for _, e in ipairs(entries) do
          local rendered, err = NS.RenderSample(e[3].default)
          t.truthy(rendered, …)
      end
  end)
  ```
- `modules/Override.lua:171-197` (`buildSampleArgs`) walks **the format string itself** with
  `clean:gmatch("%%(%d*%$?)[%-+ #0]*%d*%.?%d*([%a])")` and calls `sampleArg(ftype)` per conversion
  found — so the argument list is generated from the same text the assertion renders. Arity and type
  always agree by construction.
- Consequence, sourced to the review that ran the day before this audit
  (`docs/reviews/2026-08-05/01_FINDINGS.md`, F-001/F-002): `defaults/Defaults.lua:162-165` declares
  `%s` + `%d` against a one-argument Blizzard string, and `:190-193` puts `%d` in the slot the client
  fills with a name — both raise inside Blizzard's handler, and this case is **green** over both.
- `testing-§12`: "A test that passes no matter what the implementation does … **reads as coverage**
  while providing none." The audit records the *unfalsifiable shape*; it does not re-file F-001/F-002,
  which are code defects owned by the review.

### PC-59 — user-facing strings that cannot be translated

- `settings/Schema.lua:72-73` — `label = "Enable " .. category`,
  `tooltip = "Enable or disable all " .. category .. " string overrides."`
- `settings/Panel.lua:167-169` — `"Shared with " .. table.concat(others, ", ") .. " — both registrations write the same Blizzard global; the last category to apply wins on /reload."`
- `settings/Panel.lua:392-394` — `defaultsTooltip = ("Reset all " .. category .. " strings to defaults.")`
- `locales/enUS.lua:9-11` — "The seeded block below is the authoritative manifest of the addon's
  user-facing string surface — every string wrapped in `L[...]` at a call site appears here."
- `localization-§1`/`§2` place the addon's output surface in `NS.L` with the English string as the key;
  a concatenated fragment has no key, so no locale file can reach it.

### PC-23 / PC-27 / PC-51 / PC-54 / PC-52 / PC-56 — documented / advisory

- PC-23: `settings/Panel.lua:127-128` (`local LEFT_W = 0.4` / `local RIGHT_W = 0.6`), applied at
  `:151` and `:178`; recorded `CLAUDE.md:11`.
- PC-27: `PrettyChat.toc:2` (rainbow `|cff…|r` title), `:4` (`## Author: aDd1kTeD2Ka0s`); recorded
  `CLAUDE.md:10`.
- PC-51: `tests/loader.lua` 155 lines; recorded `CLAUDE.md:12`; upstream item LIBKA0S-01.
- PC-54: `core/Constants.lua:54-60` — the omission and its reason in-code; recorded `CLAUDE.md:9`.
- PC-52: `DEPENDENCIES.md:118-119` — "**`AceEvent-3.0` / `AceTimer-3.0`** are not vendored and not
  needed — this addon `LibStub`s neither."
- PC-56: `PrettyChat.toc:10` — `## Category-enUS: Chat & Communication`.

---

## Part C — Compliance evidence (claims that pass, with citations)

**Shared subsystems — the descriptor and the stub, not the behavior** (`AUDIT.md` step 6): none of the
four claims below cites `libs/LibKa0s/*` as the addon's implementation.

| Module | Lookup | Descriptor | Degradation stub |
|---|---|---|---|
| Core | `core/CoreSetup.lua:41` `LibStub("LibKa0s-Core-1.0", true)` | `:101-104` (`prefix` as a **function**, `sep = ""`) + the anti-pattern-#36 reclaim at `:106-110` | `:43-85` — `Util.IsConcatSafe`, `Util.SafeToString`, `NS.Print` (one honest announce), and `NS.Format` published **on both paths** with the reason at `:74-77` |
| DebugLog | `core/DebugLogSetup.lua:39` | `:109-152` — name, title, `font`, `slash`, `isEnabled`/`setEnabled`, call-time `print`/`safeToString`, `initSummary`, `onVisibilityChanged`; the four fields deliberately not passed are named at `:142-151` | `:41-106` — 19 members + `buffer`; the two formatters are omitted **with the reason written down** at `:64-67` (copying them is the duplication the extraction ended) |
| Options | `settings/OptionsSetup.lua:17` | `:104-153` — `parentTitle`, `mainPanelName`, printer/debug, the single `get`/`set`/`applyDefault` write seam, `rowsForPage`/`allRows`, `buildMain`; seven unpassed fields each justified at `:137-152` | `:19-97` — the standard's **one documented load-completing** stub, with its *measured* justification at `:26-33` ("PrettyChat's measured load-time set is EMPTY … `tests/test_libka0s.lua` pins that by loading with the library absent and comparing the row count against a full load"). Not a member-answering stub **by design**, and correctly so. `RestoreAllDefaults` is kept real at `:85-89`; the layout constants are deliberately absent, with the reason at `:90-95` |
| Slash | `settings/Slash.lua:72` | `:158-179` — `commands = COMMANDS`, `slashAliases = { "/prettychat" }`, plus the addon's `format`/`parse` hooks | `:74-126` — a hand-shaped dispatcher over the same `COMMANDS` table so every verb still names the missing library rather than going quiet (`slash-commands-§1`) |

**Stub-coverage sweep.** Every member the addon reaches on `NS.DebugLog` (`settings/Slash.lua`,
`settings/Panel.lua`) is answered by the `core/DebugLogSetup.lua:68-104` table; the two absent
formatters have no addon call site (`grep` finds them only inside the library's own `Add`). The
Options stub is the documented exception and is **not** flagged. `NS.Helpers` members reached from
`settings/Panel.lua` all appear in `settings/OptionsSetup.lua:58-96`; the constants
(`H.ROW_VSPACER` &c.) are deliberately absent — the review's F-009 notes one call site
(`settings/Panel.lua:275`) that would raise rather than no-op if reached, saved by the `EnsureScroll`
early return at `:268`. That is a review finding about the stub's own comment, not a missing member,
and it is not re-filed here.

**Not hand-rolled (anti-pattern #47 clear).** The repo carries no `modules/DebugLog.lua`, no widget
makers or flow engine, no dispatcher/parser, and no test framework of its own:
`find . -name '*.lua' -not -path './libs/*'` shows nine `core/` files, two `defaults/`, four
`settings/`, one `modules/`, one `locales/`, and a `tests/` tree whose framework is the vendored
`tests/_kit/framework.lua`. The absence of those files **is** the compliance evidence.

**Other passes.**

- `architecture-§1`: `local addonName, NS = ...` at line 1 of every source file; no `_G[addonName]`.
- `architecture-§2` / anti-pattern #36: `core/PrettyChat.lua:14` `NewAddon(NS, addonName, "AceConsole-3.0")`,
  reclaimed at `core/CoreSetup.lua:109-110`, with the clobber modeled in the mock.
- `savedvariables-§1/§3`: `core/Database.lua:14,19-23,30-50` — `SCHEMA_VERSION`, `global.schemaVersion`
  default, idempotent runner.
- `savedvariables-§5` / anti-pattern #54: `modules/Override.lua:31` `if self.db.profile.enabled == nil then return true end`;
  `core/Database.lua:32` `db.global.schemaVersion or 0` is numeric, where `0` is truthy and `or` is safe.
- `performance-§11` / `testing-§13` (the CCN refactor in `ab30a70`): the extracted helpers are
  `renderSample`-adjacent names a reader recognizes — `renderOrError`, `categoryMatches`,
  `collectNames`, `printStringRow`, `printCategoryBlock`, `printFooter` — not `part2`/`doTheRest`
  (anti-pattern #52 clear); the `LABEL` table is **module-level, built once at load**, not per call
  (anti-pattern #43 clear); and coverage was checked **before** the refactor and written down —
  `docs/superpowers/plans/2026-08-04-ccn-elimination.md:51` ("seven characterization tests … Coverage
  is good enough to refactor against as-is") and `:74`. Case count held at 255 across the refactor,
  which `RESULTS.md:32` calls out as correct for a behavior-preserving change.
- `localization-§5` (US English): a repo-wide grep for `colour|grey|behaviour|centre|cancelled|initialis|normalis|organis|optimis|analyse|catalogue|dialogue|defence|licence|favour|labelled|travelled`
  over `*.lua`, `*.md`, `*.toc` excluding `libs/`, `GlobalStrings/`, `docs/audits/`, `docs/reviews/`
  returns **no matches**.
- `documentation-§6` (three places): `PrettyChat.toc:12`, `README.md:6`, `CLAUDE.md:14`.
- `documentation-§3` (no scaffolding pack): no `docs/agent-context.md`; `CLAUDE.md:33-48` says it must
  never return (anti-pattern #49 clear).
- `documentation-§4`: no `TODO.md` at root or under `docs/`. `docs/pending/LEDGER.md` is a
  **decision record** (`:1-27`: `done` / `wont-do` / `deferred` with rationale and evidence hashes),
  not a second backlog — the three `deferred` rows point at open GitHub issues rather than replacing
  them. Recorded as an observation, not a deviation.
- `documentation-§7`: `DEPENDENCIES.md` splits runtime (`:15-37`) / development (`:41-119`) / release
  (`:123-154`), gives evidence per entry (e.g. `:51` cites `tests/loader.lua:103` and
  `tests/_kit/loader.lua:31,50` for the `setfenv` Lua-5.1 requirement), warns off
  `pip install lizard` on 24.04 and gives the `pipx` route (`:75-85`), and carries a verify line per
  tool.
- `packaging`: `.pkgmeta` has no `externals:` and ignores `docs`, `tests`, `_dev`, `*.bak` plus the
  build-time assets (`:8-31`).
- `toc-file-§3`: single `## Interface: 120007` (`:1`) matching the README `[wow]` badge
  `Midnight_12.0.7` (`README.md:3`).
- `audit-review-history`: prior runs at `docs/audits/2026-07-12/`, `2026-07-18/`, `2026-08-04/` and
  `docs/reviews/2026-05-02/`, `2026-08-03/`, `2026-08-05/` are all retained and untouched by this run;
  this bundle is a new dated folder.
