# 03 — Evidence (Ka0s Pretty Chat)

**Run date:** 2026-10-07 · **Standard:** v2.76.1 · **Tree:** `8626790` on
`feat/2026-10-07-review-audit-remediation`.

Every command below was run for this audit from the repo root. Each output shown is the real
output, trimmed only where marked. Each count states its scope. Each `file:line` citation was
re-read before writing, and the cited text is quoted beside it.

**Default census scope** (`layout-§1`): `git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'`.
That is all tracked authored Lua, `tests/` and the generated `GlobalStrings/` included, with the two
vendored payloads excluded. Where a check uses another scope, it says so.

---

## E-1 Standard resolution

```
curl -fsSL $RAW/AUDIT.md                 -> 1157 lines
curl -fsSL $RAW/standards/STANDARDS.md   -> "# Ka0s WoW Addon Standard (v2.76.1, 2026-10-07)"
Sections list -> 27 files under standards/standards/; all 27 fetched; cmp against a second
same-day curl copy: "identical: 27"
curl -fsSL $RAW/standards/ADDONS.md      -> fetched
```

`dev-copilot-profile` printed `profile=wow`, `kind=addon`, `name=PrettyChat` and
`reason=toc:## Interface`. **Kind: Addon.**

## E-2 Headless suite (bounded)

```
$ ~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua
...
572 passed, 0 failed, 1 skipped, 573 total
EXIT 0
```

The one skip is the kit's `diagnostics contract: an addon that opts out …` case. This addon keeps
the default, so the case does not apply. Running `lua tests/run.lua --list` through the bounded
runner and comparing it with `diff --strip-trailing-cr` against `docs/test-cases.md` printed
`INVENTORY-SAME`. The README badge `Tests-572%2F572_passing` (`README.md:7`) follows
`testing-§5`'s rule that a skip counts in neither figure.

## E-3 Vendored Ka0s-owned library drift (`library-stack-§7`, anti-patterns #45/#48)

The provenance line is `CLAUDE.md:42`: "Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.70.0 (MIT)."

```
$ grep -n 'Bundles \[LibKa0s\]' CLAUDE.md   -> 42:Bundles [LibKa0s](...) v1.70.0 (MIT).
$ grep -n 'Bundles \[LibKa0s\]' README.md   -> (none)
$ grep -nE '^## (Libraries|Bundled libraries|Libraries and credits|Credits and libraries|Credits and bundled libraries)' README.md -> (none)
$ grep -n 'WoW_Addon_Standard' README.md    -> 6:![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)   (bare, not linked)
$ git -C ../LibKa0s archive v1.70.0 LibKa0s testkit | tar -x -C <scratch>/lk170
$ diff -r <scratch>/lk170/LibKa0s libs/LibKa0s && echo EMPTY   -> EMPTY
$ diff -r <scratch>/lk170/testkit tests/_kit && echo EMPTY     -> EMPTY
```

The diff ran against the **tag the provenance line names**, not against the sibling's `HEAD`
(`353f286`). Both payloads were compared whole. `grep -c '<Script file=' libs/LibKa0s/LibKa0s.xml`
returns 34, and `ls libs/LibKa0s/*.lua | wc -l` also returns 34. Result: no #45 and no #48.

## E-4 Lint (bounded)

```
$ ~/.claude/dev-copilot/bin/ka0s-bounded luacheck .
Total: 0 warnings / 0 errors in 56 files
EXIT 0
```

The scope comes from `.luacheckrc:20-27`, `exclude_files = { "Libs", "libs", "GlobalStrings",
"docs/audits", "docs/reviews", "tests/_kit/" }`, so `tests/` is linted apart from the kit. The
harness global is scoped to `files["tests/"]` at `.luacheckrc:86` and is not a top-level
`read_globals`. The file has no top-level `ignore` (`.luacheckrc:29`).

## E-5 Complexity, sighted (`automated-tests-§3`, `-§4`)

```
$ ~/.claude/dev-copilot/bin/ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle
PrettyChat 1.6.0 — automated tests — 20261007-160948
  complexity  pass  — 0 warnings (fun rate 0.00), 57375 NLOC / 1314 funcs, avg NLOC 7.2, avg CCN 2.1 (max 15), avg tokens 59.6 (recorded, non-gating)
  verdict: green
  record:  newest bundle 20260927-031723 measured a663bc6, 49 commit(s) behind HEAD — its figures describe a tree this one is no longer
EXIT 0
```

`blindFiles` and the per-function list were read from a **throwaway local clone** under the session
scratchpad. A run with a bundle there writes nothing into this repo. That clone's manifest records
`'warnings': 0, 'maxCcn': 15, 'functions': 1314, 'blindFiles': 0`. Functions with CCN ≥ 12 in its
`complexity.txt`:

```
25  14  Database.PruneOrphans@94-118@./core/Database.lua
33  14  scanLiterals@168-220@./tests/test_locale.lua
25  13  trackedMarkdown@139-163@./tests/test_doc_structure.lua
29  12  (anonymous)@369-401@./tests/test_doc_structure.lua
49  15  listSettings@363-422@./settings/Slash.lua
16  13  fitTree@415-438@./settings/Panel.lua
```

`listSettings` does not appear in the recorded `20260927-031723/complexity.txt`. A
`grep -n listSettings` over that file returns nothing, while `PruneOrphans` and `fitTree` are there at
`:19` and `:236`. The function is therefore newly visible to the sighted shadow, not newly grown.
`settings/Slash.lua:363` reads "function listSettings(rest)". It branches over four sub-forms:
`"category"` at `:368`, `"formatstring"` at `:377`, bare at `:399` and filtered at `:404`. That is
genuine branching, not `or` defaulting.

**Kit and record checks.** `tests/_kit/framework.lua:20` reads "Kit.VERSION = 37", which is
revision 35 or later. `{ name = "test_lizard_sighted", dir = "tests/_kit/" }` is at
`tests/run.lua:162`. `grep -n -i 'lizard\|hazard'` over `tests/test_lintconfig.lua`,
`tests/test_doc_structure.lua` and `tests/prose_waivers.lua` returns nothing, so there is no local
scanner (#92 clear). The `complexity` row in `docs/testing.md:237` names the runner and says "never
raw". The newest manifest, `docs/automated-tests/20260927-031723/manifest.json`, has `git.sha`
`a663bc6…` and `dirty: false`, and its `suites.complexity` has **no `blindFiles` key** (it was
recorded before kit 35). `docs/automated-tests/RESULTS.md:15` reads "evaluated by
`/wow-addon:bump-version` from the". The vendored runner now prints `/dev-copilot:bump-version`
(`tests/_kit/run-automated-tests.sh:1112`). The watch list has no warned function and one band row
(`settings/Schema.lua`, *On notice*). No entry reads Accepted, so anti-pattern #53 is clear. → PC-76.

## E-6 Line endings (`line-endings`)

```
$ test -f .gitattributes                          -> present
$ grep -n '^\* text=auto eol=\(crlf\|lf\)$' .gitattributes   -> 26:* text=auto eol=crlf
$ grep -nE '^\*\.(sh|py) text eol=lf$' .gitattributes        -> 36:*.sh text eol=lf / 37:*.py text eol=lf
$ grep -c ' binary$' .gitattributes                         -> 20
$ diff <(tr -d '\r' < .gitattributes | head -84) <canonical client-bound body, line-endings.md:166-249> && echo BODY-IDENTICAL
BODY-IDENTICAL
$ tr -d '\r' < .gitattributes | sed -n '85,$p' | wc -l   -> 0   (no appendix)
$ git ls-files | wc -l                                       -> 575
$ git ls-files -z | xargs -0 -I{} sh -c '<AUDIT.md (e) body, verbatim>' 2>/dev/null | wc -l
0
```

The (e) scope is the whole tracked set, `libs/` and `tests/_kit/` included. **0 of 575** tracked
files disagree with the pin. The `test_eol` gate is wired at `tests/run.lua:152`.

## E-7 Packaging (`packaging`)

Run under `bash`, verbatim from `AUDIT.md`. (zsh does not word-split `$entries`, and the first zsh
attempt printed one bogus combined line. It is discarded.)

```
(a) -> (no output)        (tools and .claude present and ignored: .pkgmeta:45, :25)
(b) -> UNACCOUNTED — .git (the one entry the playbook exempts)
(c) -> (no output)
```

## E-8 Re-vendor bundle completeness (`audit-review-history`) → PC-103

This is `AUDIT.md`'s script run verbatim, with its two temp files placed in the session scratchpad.

```
horizon=2026-08-25
vendored: 51  recorded: 49
--- unrecorded:
v1.69.0
v1.70.0
```

The scope is every commit since `2026-08-25 00:00` that touched `libs/LibKa0s` or `tests/_kit`,
with each tag read from `CLAUDE.md` at that commit, against every bundle under `docs/revendor/`.

```
$ git show --stat 136cf54   -> "chore: re-vendor LibKa0s v1.69.0 (kit 37; adds the line chart widget)"
                               CLAUDE.md | 2 +-, libs/LibKa0s/WidgetsLineChart.lua | 463 +++, tests/_kit/mock_lines.lua | 85 +++ ...
$ git show --stat 7a1aabf   -> "chore: re-vendor LibKa0s v1.70.0"
                               CLAUDE.md | 2 +-, libs/LibKa0s/WidgetsAutocomplete.lua | 375 +++ ...
$ ls docs/revendor | tail -1 -> 2026-10-04-v1.68.1
```

Neither commit touches `docs/revendor/`. The register has no row for the gap.

## E-9 Disabled-state census (`slash-commands-§7`)

The scope is authored shipped Lua: `git ls-files '*.lua' ':!libs' ':!tests/_kit' ':!tests' ':!GlobalStrings'`.

```
# registrations (code lines only; comment hits omitted)
core/CoreSetup.lua:115   local ok = pcall(target.RegisterEvent, target, event, handler)    (library-absent twin of SafeRegisterEvent)
core/CoreSetup.lua:120   local ok = pcall(frame.RegisterUnitEvent, ...)                   (twin; no caller)
modules/Override.lua:212 traceWatch(true, NS.Util.SafeRegisterEvents(combatWatcher, WATCH_EVENTS, nil, NS.RejectedEvents))
# un-registrations
modules/Override.lua:208 combatWatcher:UnregisterAllEvents()
# timers / hooks
settings/Panel.lua:533   C_Timer.After(0, function() fitTree(ctx) end)      (one-shot, settings panel = setup)
settings/Profiles.lua:143 C_Timer.After(0, redrawNextFrame)                 (one-shot, settings panel = setup)
settings/Panel.lua:513   frame:HookScript("OnSizeChanged", ...)              (AceGUI pane on the settings panel = setup)
```

There is one registration site. Its first term is the latch, at `modules/Override.lua:194-195`:
"local wanted = (not self:IsStoodDown()) and COMBAT_SCOPED[self:GetVisibility()] and true or false".
When `wanted` is false it calls `UnregisterAllEvents` at `:208`. Both latch arms are `Reapply`
(`:292-298`). The conformance suite asserts on the mock's registration set:
`tests/test_disabled.lua:188` reads "t.eq(#R_off, 0, \"nothing is registered any more: \" .. show(R_off))".
The live verbs are `settings/Slash.lua:287-289`, "for i, verb in ipairs(lib.LIVE_VERBS) do liveVerbs[i] = verb end"
followed by "liveVerbs[#liveVerbs + 1] = \"profile\"". There are no findings.

## E-10 Diagnostics (`debug-logging-§14`)

```
$ grep -n '"diagnostics"' settings/*.lua core/*.lua
settings/Slash.lua:77:    {"diagnostics", L["Write a diagnostics report to the debug console, for a bug report"],
settings/Slash.lua:542:    if arg:match("^(%S*)") == "diagnostics" then          (runDebug's first test)
core/DebugLogSetup.lua:162:            if word == "diagnostics" then            (stub DebugVerb)
$ grep -rniE '"(diag|dump|dx)"' settings core modules   -> (none)
$ grep -n 'SetEnabled' settings/*.lua core/*.lua modules/*.lua
  settings/Slash.lua:548 (the `debug on|off` arm, not around RunDiagnostics); core/DebugLogSetup.lua:127,167 (stub)
$ grep -n 'diagnosticsEnablesLogging' core/*.lua   -> (none: default, logging turns on)
```

`settings/Slash.lua:529` reads "NS.DebugLog:RunDiagnostics()". The stub at
`core/DebugLogSetup.lua:147-153` prints "%s is unavailable: the LibKa0s library did not load." and
returns 0. The `## Reporting a bug` section at `README.md:70-76` matches documentation-§1 item 9
verbatim with `/pc`.

## E-11 Library debug lines (`debug-logging-§4`, v2.73.0)

- `core/LauncherSetup.lua:168`: "debug = function(tag, message) NS.Debug(tag, \"%s\", message) end,"
- `core/LauncherSetup.lua:174`: "debugAtEnable = function(tag, message) NS.DebugLog.DebugAtEnable(tag, \"%s\", message) end,"
- `core/LifecycleSetup.lua:142`: "debug = function(tag, message) NS.Debug(tag, \"%s\", message) end,"
- `settings/OptionsSetup.lua:270`: "debug = function(tag, fmt, ...) NS.Debug(tag, fmt, ...) end,"
- `settings/Slash.lua:305`: "debug   = function(tag, message) NS.Debug(tag, \"%s\", message) end,"
- `settings/Schema.lua:823`: "debug  = function(tag, fmt, ...) return NS.Debug(tag, fmt, ...) end,"
- Change gates: `modules/Override.lua:160` reads "D.DebugChanged(WATCH_GATE, \"Events\", \"combat watch disarmed\")",
  and `core/Util.lua:80` reads "NS.DebugLog.DebugOnce(key, tag, \"%s failed: %s\", site, err)".
- No duplicate edge line: `modules/Override.lua:292-298` (`StandDown` and `StandUp` call `Reapply`
  and write no line). `core/DebugLogSetup.lua:104-107` stubs `DebugOnce`, `DebugChanged`,
  `DebugForget` and `DebugAtEnable`.

## E-12 Launcher, media, close button, settings window

```
core/LauncherSetup.lua:148   label = "Ka0s Pretty Chat",
core/LauncherSetup.lua:186   isEnabled = function() return NS:IsAddonEnabled() end,
core/LauncherSetup.lua:191   setEnabled = function(on)
$ grep -rn 'MakeCloseButton(' --include='*.lua' . | grep -v '/libs/' | grep -v '/tests/'
core/CoreSetup.lua:99:    function NS.MakeCloseButton() return nil end           (degraded twin)
core/CoreSetup.lua:163:    return lib.MakeCloseButton(parent, onClick, addonName)   (the one wrapper)
$ git ls-files '*.lua' ':!libs' ':!tests' | xargs grep -nE 'SettingsPanel|HideUIPanel|ToggleGameMenu|OpenToCategory'
core/PrettyChat.lua:262:-- open settings panel" line on a false return from Settings.OpenToCategory, and   (comment only)
$ python3 (TGA header of media/logos/prettychat.logo.128.tga) -> type 2 w 128 h 128 bpp 32
$ git ls-files media -> logos (.128.tga, .tga, .png, .jpg), screenshots (2 .png); no fonts/icons/textures copy
```

## E-13 `docs/` shape (`documentation-§3`)

```
$ git ls-files docs | grep -vE '^docs/(audits|reviews|revendor|superpowers|automated-tests/2)' | grep '\.md$' | wc -l
18
```

That covers the 16 `docs/*.md` files plus `automated-tests/README.md` and `RESULTS.md`. Each one
appears exactly once in the four Map tables (`docs/ARCHITECTURE.md:224-263`), and no row names a
missing file. Tier 2 rows: `slash-dispatch.md` "14 verbs in the command table" (`:239`), with 14
COMMANDS rows at `settings/Slash.lua:46-87`; `compat-layer.md` *Not applicable* citing compat's
condition (`:242`); `debug.md` Present (`:244`).

```
$ wc -l < docs/ARCHITECTURE.md          -> 434
$ git show e561b79:docs/ARCHITECTURE.md | wc -l   -> 387   (the 2026-09-23 audit's record commit)
```

Section spans, from `grep -n '^## '`: `## Documented deviations` runs `:265`–`:413` (the census
heading is at `:337`), the retired blocks are at `:293`–`:335`, and the census prose is at
`:362`–`:412`. → PC-105.

## E-14 PC-104 evidence (doc drift)

**(1)** `docs/ARCHITECTURE.md:418` reads "**Item**, **Pool** and **Widgets** are not consumed here at
all — nothing in this addon, and no other vendored LibKa0s file, `LibStub`s any of the three.
`Item.lua`, `Pool.lua`, `Widgets.lua`, `WidgetsReorder.lua`, `Perf.lua`, `PerfSampler.lua`,
`PerfCommands.lua` and `PerfPanel.lua` are still vendored". The vendored payload contradicts it:
- `libs/LibKa0s/DebugLog.lua:33`: "local widgets = LibStub and LibStub(\"LibKa0s-Widgets-1.0\", true)"
- `libs/LibKa0s/OptionsNav.lua:20`, `OptionsTabs.lua:38` and `OptionsWidgets.lua:37`: "local Pool = LibStub and LibStub(\"LibKa0s-Pool-1.0\", true)"
- `libs/LibKa0s/OptionsIds.lua:787` and `OptionsIdList.lua:358`: "local Item = LibStub and LibStub(\"LibKa0s-Item-1.0\", true)"
- `ls libs/LibKa0s/ | grep -i widgets` → `OptionsWidgets.lua`, `Widgets.lua`, `WidgetsAutocomplete.lua`,
  `WidgetsDragHandle.lua`, `WidgetsLineChart.lua`, `WidgetsReorder.lua`. The sentence names only
  `Widgets.lua` and `WidgetsReorder.lua`.

**(2)** The sweep command from `docs/performance-sweep.md:19-21` was re-run verbatim. It printed 43
lines. Diffing that output against the page's recorded block shows only these differences:

```
< tests/test_libka0s.lua:802:test("degraded SafeRegisterEvents records a rejected name and registers the rest", function()
...  (7 rows: :802 :804 :815 :827 :829 :830 :831)
> tests/test_libka0s.lua:831:test("degraded SafeRegisterEvents records a rejected name and registers the rest", function()
...  (7 rows: :831 :833 :844 :856 :858 :859 :860)
```

Today `tests/test_libka0s.lua:831` reads "test(\"degraded SafeRegisterEvents records a rejected name
and registers the rest\", function()". `docs/performance-sweep.md:8-9` reads "The result block below
was last re-taken on the LibKa0s v1.65.0 tree, by running the command, in the `DG-PC-01:` commit."
The register row `docs/ARCHITECTURE.md:284` reads "proven by the committed whole-repo sweep in
[`performance-sweep.md`] …, last re-taken in the `SP-PC-02R:` commit."

**(3)** `.luacheckrc:34-37` reads "Seven files here DO read it -- Namespace, CoreSetup, EnvSetup,
MediaSetup, DebugLogSetup, PrettyChat and settings/Panel … The other eleven had it because the line
was copied". The scope of the following count is the five source folders:

```
$ git ls-files 'core/*.lua' 'defaults/*.lua' 'locales/*.lua' 'modules/*.lua' 'settings/*.lua' | xargs grep -l '^local addonName, NS = \.\.\.' | wc -l  -> 10
$ ... | xargs grep -l '^local _, NS = \.\.\.' | wc -l                                                                                         -> 12
```

`docs/ARCHITECTURE.md:81` correctly says "Ten files read both … The other twelve".

**(4)** These are digest ids the tree cites. The scope is tracked files outside the frozen stores and vendored payloads.

| Citation | Text | In-repo resolution (`grep -rlF <id> docs/audits docs/reviews`) |
|---|---|---|
| `docs/ARCHITECTURE.md:375` | "(2026-09-24, `PRETTYCHAT-A-07`)" (generator move) | `docs/audits/2026-09-07/02_DEVIATIONS.md:33`: "PC-66 \| PRETTYCHAT-A-07" (a different finding) |
| `docs/ARCHITECTURE.md:173` | "(PRETTYCHAT-A-08)" (boundary watcher) | 2026-09-07 map `:34`: "PC-67 \| PRETTYCHAT-A-08" |
| `docs/ARCHITECTURE.md:171`, `docs/module-map.md:58` | "PRETTYCHAT-A-09" (SafeRegisterEvents) | 2026-09-07 map `:35`: "PC-68 \| PRETTYCHAT-A-09" |
| `tests/test_doc_structure.lua:469` | "core/LifecycleSetup did exactly that (PRETTYCHAT-A-03)" | 2026-09-07 map `:35`: "PC-62 \| PRETTYCHAT-A-03", which `:48` describes as the `architecture-§4` bus finding |
| `docs/ARCHITECTURE.md:100`, `docs/module-map.md:54`, `defaults/Profile.lua:3`, `tests/test_override.lua:77`, `tests/test_defaults.lua:303` | "PRETTYCHAT-A-19" | nothing |
| `tests/test_doc_structure.lua:410` | "(PRETTYCHAT-A-20, A-25)" | nothing |

These ids belong to `../Ka0sAddonsCommonTasks/docs/2026-09-23-REVIEW_AND_STANDARDS_AUDIT_REMEDIATION/01_CONSOLIDATED_FINDINGS.md`.
For example, its `:366` reads "**PRETTYCHAT-A-09** `low` (audit PC-85 …) — Event registrations are a
bare loop". The register preamble `docs/ARCHITECTURE.md:276-277` reads "A `PC-NN` id … resolves in
`docs/audits/`; a `PC-R-NN` id is a review finding and resolves in `docs/reviews/2026-08-05/`". It
says nothing about `PRETTYCHAT-A-NN`.

## E-15 Issue store and register (`audit-review-history`)

```
$ gh issue list --state all --limit 200 --json number,title,state,labels,closedAt
18 issues; each carries one state: and one severity: label; no "[" title prefix.
OPEN  #2 #3 #6 (state:triaged)
CLOSED state:done #4 #9 #15 #18; state:will-not-do #1 #5 #7 #8 #10 #11 #12 #13 #14 #16 #17
$ gh issue view 8 --json body,closedAt
2026-08-06T15:18:00Z
"PrettyChat is single-profile by design; per-character / per-realm scoping will not be exposed."
```

`settings/Profiles.lua` exists and is loaded last (`PrettyChat.toc:114`). The README FAQ row
"Where are my settings saved?" says the Profiles page lets you "give a character, class, realm or
faction its own" (`README.md:55`). → PC-106.

**Register trigger evidence.**
- `libs/LibKa0s/OptionsWidgets.lua:76` reads "local HALF = 0.5", and `:1041` reads "function O.RenderGrid(ctx, items, parent, opts)".
- `tests/_kit/loader.lua:22` reads "__newindex = function(_, k, v) _G[k] = v end,".
- `options-ui.md:374` reads "A one-shot test action (a sample line printed, a flow run once, a value held for a few seconds) MAY stay beside it as a verb or the composer's `leadButton`, but does not replace it."
- `settings/Schema.lua:191` reads "leadButton = {".

Evidence ids, each resolved with `grep -rlF`:
- `LIBKA0S-06`, `LIBKA0S-01`, `PC-49` and `PC-52` resolve to `docs/audits/2026-08-04/`.
- `PC-61` resolves to `docs/audits/2026-09-07/`.
- `PC-73` resolves to `docs/audits/2026-09-08/`.
- `PC-88` resolves to `docs/audits/2026-09-23/`.
- Issues #7 and #10 exist.

## E-16 LOC census (`layout-§1`)

```
$ git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)' | xargs wc -l | sort -n | tail -3
   1094 settings/Schema.lua
  23842 GlobalStrings/GlobalStrings.lua
  64669 total
```

This uses the default scope with no exclusions applied after the command. The only file over 1500
is the declared exemption (`tests/run.lua:61`: "Kit.layoutCap = { exempt = { \"GlobalStrings/\" } }",
and the census row `docs/ARCHITECTURE.md:357`). The band holds `settings/Schema.lua` (1094). The 26
chunks are 881–882 lines each.
