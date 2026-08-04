# 03 — Evidence (Ka0s Pretty Chat)

**Run date:** 2026-08-04 · **Standard:** v2.17.1 (2026-08-03)

Every claim in `01_CURRENT_STATE.md` and `02_DEVIATIONS.md` is sourced here. Mechanical checks
were **executed**, not reasoned about; the real command and its real output are recorded below.

---

## Part 1 — Mechanical checks (run this session)

### 1.1 Standard provenance — network fetch + byte-identity

```
$ curl -fsSL --max-time 15 ".../master/AUDIT.md" -o $S/AUDIT.md
FETCH_OK   9165 AUDIT.md
$ diff AUDIT.md $S/AUDIT.md          → (empty)   "AUDIT identical"
$ diff standards/STANDARDS.md $S/STANDARDS.md → (empty)   "STANDARDS identical"

$ ls standards/standards/*.md | xargs -P 8 -I{} curl -fsS --max-time 20 \
    -o $S/sections/{} ".../master/standards/standards/{}"
exit=0
$ ls $S/sections | wc -l
24
$ diff -r standards/standards $S/sections
(empty)  → ALL_SECTIONS_IDENTICAL
```

Local checkout state:

```
$ git -C .../WowAddonStandards status --porcelain
(empty)
$ git -C .../WowAddonStandards log -1 --format='%H %s'
2141229...  v2.17.1 — finish the v2.17.0 rollout: no fourth slot, no drop-in imperative
```

**Result:** raw-URL fetch succeeded for all 26 documents and every one is byte-identical to the
clean local checkout. No section unassessed; nothing recalled from memory.

### 1.2 `luacheck .`

```
$ cd /mnt/d/.../prettychat && luacheck .
Checking core/Compat.lua           OK
Checking core/Constants.lua        OK
Checking core/CoreSetup.lua        OK
Checking core/Database.lua         OK
Checking core/DebugLogSetup.lua    OK
Checking core/Namespace.lua        OK
Checking core/PrettyChat.lua       OK
Checking core/State.lua            OK
Checking core/Util.lua             OK
Checking defaults/Defaults.lua     OK
Checking defaults/Profile.lua      OK
Checking locales/enUS.lua          OK
Checking modules/Override.lua      OK
Checking settings/OptionsSetup.lua OK
Checking settings/Panel.lua        OK
Checking settings/Schema.lua       OK
Checking settings/Slash.lua        OK

Total: 0 warnings / 0 errors in 17 files
```

**Result: PASS.** `lint`'s zero-error gate is met. (The *configuration* gap — missing
`debugprofilestop` / `PrettyChatPerfDB` — is PC-45 and is invisible to this run because no
bracket call site exists yet.)

### 1.3 Headless test runner

```
$ lua5.1 tests/run.lua
… (255 cases) …
255 passed, 0 failed, 255 total
exit 0
```

**Result: PASS, 255/255.** Cross-checks:

- `docs/test-cases.md` tail → `| **Total** | **255** |`
- `README.md:7` → `![Tests](https://img.shields.io/badge/Tests-255%2F255_passing-green)`

Inventory, badge and run agree — `testing-§5`'s lockstep rule is satisfied.

### 1.4 Vendored Ka0s-owned library drift (`anti-patterns` #45 / #48)

Source repo located at the sibling path `../LibKa0s`, confirmed to be the library repo
(`LibKa0s/`, `testkit/`, `tests/`, `docs/`, `CHANGELOG.md`).

```
$ diff -r ../LibKa0s/LibKa0s   prettychat/libs/LibKa0s
(no output)      ship_exit=0

$ diff -r ../LibKa0s/testkit   prettychat/tests/_kit
(no output)      kit_exit=0
```

**Result: both MUST-empty diffs are EMPTY.** The whole ship folder is vendored — every module,
including the two (`Perf.lua`, `PerfPanel.lua`) the addon does not wire — and the harness sits
under `tests/_kit/`, **not** under `libs/`. No `#45` drift and no `#48` partial vendoring.

TOC corroboration — the aggregate XML is listed once and modules are never named individually:

```
PrettyChat.toc:22   libs\LibKa0s\LibKa0s.xml
$ grep -c 'libs\\LibKa0s\\.*\.lua' PrettyChat.toc
0
```

### 1.5 Checks **not** run

None. Every mechanical check the playbook names was executed and its real output is above.

---

## Part 2 — Compliance evidence (positive findings, sourced)

### 2.1 The four adopted LibKa0s modules — descriptor + stub, not hand-rolled

The addon owns **no** console, widget maker, flow engine, dispatcher, parser or test framework.
What it owns is one setup file per module. Cited below is the library lookup, the descriptor,
and the degradation branch — never the library's own source.

| Module | Lookup | Descriptor | Stub branch |
|---|---|---|---|
| `LibKa0s-Core-1.0` | `core/CoreSetup.lua:41` | `:101-104` (`prefix` as a **function**, `sep=""`) | `:43-85` |
| `LibKa0s-DebugLog-1.0` | `core/DebugLogSetup.lua:39` | `:109-152` | `:41-107` |
| `LibKa0s-Slash-1.0` | `settings/Slash.lua:72` | `:155-181` | `:78-126` |
| `LibKa0s-Options-1.0` | `settings/OptionsSetup.lua:17` | `:104-153` | `:58-96` |

Corroborating absences (evidence of compliance, per `AUDIT.md` step 4):

```
$ ls core/ | grep -i debuglog
DebugLogSetup.lua          # ← a setup file, not a console implementation

$ ls modules/
Override.lua               # ← one feature module; no widget maker, no dispatcher

$ grep -rn "ScrollingMessageFrame" core defaults settings modules locales
(no matches)               # ← no private console window
```

### 2.2 Stub coverage — every member the addon reaches is answered

Call sites enumerated this run, then checked against each stub.

**DebugLog** — members reached on the instance:

```
$ grep -rhoE 'NS\.DebugLog[.:][A-Za-z_]+' core settings modules defaults locales | sort -u
NS.DebugLog.Debug        NS.DebugLog.SessionSummary   NS.DebugLog.SetEnabled
NS.DebugLog.Toggle       NS.DebugLog:ConsoleCheckbox  NS.DebugLog:SetEnabled
NS.DebugLog:Toggle
```

All seven are present in the stub (`core/DebugLogSetup.lua:68-104`), which additionally covers
`Add`, `Clear`, `Show`, `Hide`, `IsShown`, `IsEnabled`, `RefreshHeader`, `ShowCopy`,
`UpdateScrollBar`, `UpdateStatus`, `BufferSize`, `LastLine`, `FindLine`, `CopyText`,
`MakeCloseButton` and the raw `buffer`. **No gap.** The stub still flips
`NS.State.debug` and still prints the ack (`:88-95`), as `debug-logging-§7` requires, and
deliberately copies no formatter — with the reason written down at `:64-67`.

**Slash** — members reached:

```
$ grep -rhoE '\bSl[.:][A-Za-z_]+' settings core modules | sort -u
Sl:CliGet  Sl:CliList  Sl:CliReset  Sl:CliSet  Sl:CliVersion
Sl:OnSlash Sl:PrintHelp Sl:Text
```

All eight present in the stub (`settings/Slash.lua:88-125`). The two lib-level helpers used
outside the descriptor — `lib.FormatKV` and `lib.STRINGS` — are reached only behind an explicit
`if not lib then … return end` guard (`settings/Slash.lua:241-247`). **No gap.**

**Core** — `NS.Print`, `NS.Format`, `NS.Util.IsConcatSafe`, `NS.Util.SafeToString` are all
answered on the degraded path (`core/CoreSetup.lua:52-83`), including `NS.Format`, which
**nothing calls today** — published on both paths deliberately, with the reason at `:75-77`.
**No gap.**

**Options** — the standard's **one documented exception**: the stub is *load-completing*, not
member-answering (`options-ui-§1`). The addon has done the measurement the rule demands rather
than reasoning about it — `settings/OptionsSetup.lua:20-36` records that the measured load-time
member set is **empty**, and `tests/test_libka0s.lua` pins it by loading with the library absent
and comparing the schema row count against a full load. The stub carries `LSMValues` anyway,
keeps `RestoreAllDefaults` **real** (`:85-89`, the SHOULD in `options-ui-§1`), and copies **no**
layout constant, with the reason written at `:90-95`. Two members the panel reads off the
instance — `ROW_VSPACER`, `SECTION_HEADING_H` — are omitted **with that written reason**, and
per `AUDIT.md` step 4(b) that is a decision, not a gap. **Correctly not flagged.**

### 2.3 `architecture-§2` — the AceConsole clobber is handled

```
core/PrettyChat.lua:14   local PrettyChat = LibStub("AceAddon-3.0"):NewAddon(NS, addonName, "AceConsole-3.0")
core/CoreSetup.lua:109   NS.Print  = printer.Print          -- the reclaim
core/CoreSetup.lua:110   NS.Format = printer.Format
```

`NS` is passed first; the reclaim runs in the very next TOC entry
(`PrettyChat.toc:34-35`), and `core/CoreSetup.lua:11-26` records *why* that slot is load-bearing
from both sides. Mock fidelity is real, not assumed:

```
tests/_kit/mock_base.lua:387-392   -- "Faithfully mirror AceConsole-3.0's Embed: it stamps a
                                   -- :Print mixin onto the addon object, clobbering any
                                   -- same-named custom NS.Print."
```

### 2.4 `events-frames-taint-§8` — one secret-safe seam, no raw `print`

```
core/CoreSetup.lua:90-91   Util.IsConcatSafe = lib.IsConcatSafe
                           Util.SafeToString = lib.SafeToString      -- the library's own values
core/CoreSetup.lua:101-104 local printer = lib:New({ prefix = function() return NS.PREFIX end, sep = "" })
```

```
$ grep -rn "[^.:%w]print(" core defaults settings modules locales
(no matches)
```

Every chat line goes through `NS.Print`; every trace through `NS.Debug`. The degraded branch's
second copy (`core/CoreSetup.lua:51-61`) is the **one sanctioned** place a copy may exist, and
it probes `table.concat` (`:51`), not `..`.

### 2.5 `slash-commands` — host table, library dispatch, mandated colors

```
settings/Slash.lua:45-66   NS.COMMANDS = { {"help", …, fn}, … }   -- positional triples
settings/Slash.lua:70      NS.COMMANDS = COMMANDS                 -- crosses as plain data
core/PrettyChat.lua:33-34  self:RegisterChatCommand("pc", …); ("prettychat", …)
core/Constants.lua:51-52   Const.PREFIX = cyan .. "[PC]" .. reset .. " " ; NS.PREFIX = Const.PREFIX
core/Constants.lua:41-46   listHead = "|cff33ff99"  azure = "|cff3399ff"  -- with a comment
                           stating these are a MUST and must not be substituted
```

```
$ grep -rn "SLASH_" core defaults settings modules
(no matches)
```

`reset` takes a path, with the retired category form intercepted and answered rather than
silently failing (`settings/Slash.lua:265-282`). The `parse` and `format` overrides sit at the
**descriptor seams** the standard sanctions (`settings/Slash.lua:134`, `:147-153`), with the
gap they close named explicitly — not a fork of the dispatcher.

### 2.6 `debug-logging` — coverage and coalescing

```
settings/Schema.lua:296    NS.Debug("Set", "%s = %s", path, Schema.FormatValue(row, value))
```

One line, at the single write seam, deferred behind the gate (format args passed, not
pre-built). Bulk paths carry **one summary each**, not one line per row:

```
modules/Override.lua:105   NS.Debug("Reset", "%s → applied %d restored %d", category, applied, restored)
modules/Override.lua:115   NS.Debug("Reset", "all → applied %d restored %d", applied, restored)
modules/Override.lua:135   NS.Debug("Reset", "%s.%s → applied %d restored %d", …)
```

`settings/Schema.lua:310-317` and `settings/Slash.lua:284-288` both record the reason: driving a
reset row-by-row would run `ApplyStrings` ~350 times and evict the 500-line buffer — exactly the
per-item spam `debug-logging-§9` forbids. Session-only flag: `core/State.lua:6`.

### 2.7 `localization`

```
locales/enUS.lua:1-16      NS.L with a key-returning metatable; keys ARE the English strings
```

Game data is matched on non-localized Blizzard **global-string names**, never on translated
display text (`modules/Override.lua:76` — `_G[globalName] = …`). US-English sweep of authored
text:

```
$ grep -rniE '\b(colour|grey|behaviour|centre|cancelled|initialise|analyse|catalogue|…)\b' \
    core defaults settings modules locales README.md CLAUDE.md docs/*.md
tests/_kit/README.md:119:  "Model the awkward real behaviour, not the convenient one."
```

The single hit is **vendored library text**, byte-identical to `../LibKa0s/testkit/README.md`
(§1.4). It is an upstream finding for the LibKa0s repo, **not** a PrettyChat deviation — editing
it here would breach the read-only-`tests/_kit` rule and be reverted by the next re-vendor.

### 2.8 `options-ui` — lazy body, lazy Defaults button, gated open

```
core/PrettyChat.lua:50-52  if NS.Config and NS.Config.RegisterPanels then NS.Config.RegisterPanels() end
                           -- eager category registration at OnEnable, not behind /pc config
core/PrettyChat.lua:71-73  function PrettyChat:OpenConfig() NS.Helpers.OpenOptionsPanel() end
                           -- one-line delegate; the combat gate stays INSIDE the library's open
settings/Panel.lua:382-417 first-OnShow deferral, every-OnShow Defaults button, RegisterOptionsPage
```

Behavior is pinned by the suite, not asserted here:

```
tests/test_panel.lua  PASS  the Defaults button is deferred to first show, not built at registration
tests/test_panel.lua  PASS  the Defaults button resets its own category only
tests/test_panel.lua  PASS  a master-toggle change refreshes every built page, not just its own
tests/test_panel.lua  PASS  the parent page lists every slash command through the one row formatter
```

### 2.9 `documentation` — the pack is absent and the absence is enforced

```
$ ls docs/agent-context.md
ls: cannot access 'docs/agent-context.md': No such file or directory
$ ls docs/ | grep -i todo
(no matches)
CLAUDE.md:39-44   "docs/agent-context.md does not exist in this repo and MUST NOT be created."
```

Anti-pattern #49 clear. Three-place standards reference complete: `PrettyChat.toc:12`,
`README.md:6`, `CLAUDE.md:14`.

### 2.10 `packaging`

```
.pkgmeta:4        package-as: PrettyChat
$ grep -n "externals" .pkgmeta
(no matches)
.pkgmeta:8-15     ignore: .luacheckrc .gitignore .gitattributes docs tests _dev "*.bak"
```

---

## Part 3 — Deviation evidence

### PC-25 — `GlobalStrings/` root folder + non-canonical TOC section

```
$ ls -d */ | tr '\n' ' '
GlobalStrings/ core/ defaults/ docs/ libs/ locales/ media/ modules/ settings/ tests/
```

`GlobalStrings/` is PascalCase and at the repo root, outside the `layout-§1` skeleton and
against `layout-§2`'s lowercase-subfolder MUST. Its TOC home:

```
PrettyChat.toc:42   # GlobalStrings (generated Blizzard reference data — must precede settings\Panel.lua)
PrettyChat.toc:43-52  GlobalStrings\GlobalStrings_001.lua … _010.lua
```

`toc-file-§5` fixes the section set to Libraries → Locales → Core → Defaults → Modules →
Settings; `# GlobalStrings` is a seventh. Recorded at `CLAUDE.md:8`.

*(The former PC-33's other half is fixed: `PrettyChat.toc:24-25` now places `# Locales`
immediately after `# Libraries`.)*

### PC-40 / PC-41 / PC-42 / PC-43 / PC-44 / PC-45 — the performance cluster

```
$ ls core/PerfSetup.lua
ls: cannot access 'core/PerfSetup.lua': No such file or directory
$ ls tests/perf.lua
ls: cannot access 'tests/perf.lua': No such file or directory
$ ls docs/performance.md docs/perf-runs/
ls: cannot access 'docs/performance.md': No such file or directory
ls: cannot access 'docs/perf-runs/': No such file or directory
$ grep -rn "NS.Perf\|debugprofilestop" core defaults settings modules locales
(no matches)
$ grep -n "perf" settings/Slash.lua
(no matches in the COMMANDS table, settings/Slash.lua:45-66)
```

```
PrettyChat.toc:7    ## SavedVariables: PrettyChatDB        ← one global, not two
.luacheckrc:31-36   globals = { "PrettyChatDB", "StaticPopupDialogs", "UISpecialFrames" }
                                                            ← no PrettyChatPerfDB
.luacheckrc:39-62   read_globals = { … }                    ← no debugprofilestop
```

The recorded decision (evidence that this is a decline, not an oversight):

```
docs/pending/LEDGER.md:66  | LIBKA0S-12 | Perf | 🔵 declined, on two independent structural
                             grounds | (1) There is no hot path at all. … zero RegisterEvent,
                             zero OnUpdate, zero C_Timer, zero ticker … Every declared bucket
                             would read 0.000 by construction. (2) suspend would change what
                             the user sees mid-fight … <Addon>PerfDB is therefore not declared
                             in the TOC and no core/PerfSetup.lua exists. |
docs/ARCHITECTURE.md:141   "Perf is declined — see LIBKA0S-12 …"
```

The "no hot path" premise is independently confirmed by this run:

```
$ grep -rn "RegisterEvent\|OnUpdate\|C_Timer\|AceEvent\|AceTimer" core defaults settings modules locales
(no matches)
```

So the *rationale* is factually correct. The *rule* is nonetheless a MUST on the wiring
(`performance` — "**MUST** for the **wiring** — vendor the instrumentation lib, create one
instance at load, expose the `perf` verb, declare `<Addon>PerfDB`, implement the
`suspend`/`resume` contract"), which is why this is catalogued rather than waived.

### PC-46 — angle-bracket placeholder in the README

```
README.md:116  | I want a clean slate | One message: its **Reset** button, or `/pc reset <setting>`. …
```

The same command is spelled correctly 53 lines earlier, which is what makes this a slip rather
than a convention:

```
README.md:63   | `/pc reset setting` | Restore one setting to its default, e.g. `/pc reset Loot.enabled`. …
```

A full sweep found exactly one occurrence:

```
$ grep -n '<[a-zA-Z][a-zA-Z_ -]*>' README.md
116:| I want a clean slate | … `/pc reset <setting>`. …
```

No deliberate HTML (`<br>`, `<code>`) is present to be caught by the fix.

### PC-47 — non-canonical README sections

```
README.md:15   ## Unreleased          ← between the Description and `## What's new`
README.md:21   ## What's new in 1.4.0
README.md:28   ## Screenshots
README.md:109  ## Troubleshooting
README.md:120  ## Credits             ← between Troubleshooting and Issues
README.md:124  ## Issues and feature requests
README.md:128  ## Version History
```

`documentation-§1` fixes the twelve sections and their order; neither `## Unreleased` nor
`## Credits` is among them. Note the *rest* of the structure is correct — `## What's new in
1.4.0` sits immediately above `## Screenshots` and its bullets agree with the top Version
History row (`README.md:132`), so anti-pattern #40 does **not** apply.

### PC-48 — root `CLAUDE.md` is a brief, not a stub

```
$ wc -l CLAUDE.md
64 CLAUDE.md
CLAUDE.md:8    Generated-data exception  (5 lines of prose)
CLAUDE.md:9    Accepted deviation — debug-console font  (9 lines)
CLAUDE.md:10   Deliberate deviation from toc-file-§1 (TOC branding)  (7 lines)
CLAUDE.md:11   Accepted deviation — per-string editor layout  (8 lines)
CLAUDE.md:12   Accepted deviation — the test harness  (8 lines)
CLAUDE.md:13   TOC section order — standard-internal conflict  (10 lines)
CLAUDE.md:14   ## Standards compliance (read first)      ← mandated item 3, actually 8th
CLAUDE.md:54-63 ## Non-negotiable guardrails  (7 bullets, incl. code invariants)
```

`documentation-§2` requires **a short pointer** with five items in order. All five items exist
and item 3 is verbatim in substance — the defect is scope and placement, not absence.
`documentation-§6` names `docs/` and the audit bundle as the home for deviation records.

### PC-49 — files over the 1500-LOC cap

```
$ wc -l GlobalStrings/*.lua
  2893 GlobalStrings_001.lua      2425 GlobalStrings_002.lua      1004 GlobalStrings_003.lua
  2662 GlobalStrings_004.lua      2494 GlobalStrings_005.lua      2498 GlobalStrings_006.lua
  2312 GlobalStrings_007.lua      1150 GlobalStrings_008.lua      3285 GlobalStrings_009.lua
  2176 GlobalStrings_010.lua     23842 GlobalStrings.lua
```

Eight of the ten **shipped** chunks are over the cap. For contrast, the largest addon-authored
file is `settings/Panel.lua` at 423 lines — the cap is not under strain anywhere else.

### PC-50 — no message bus; direct cross-module calls

```
docs/ARCHITECTURE.md:119  "… There is no message bus."
$ grep -rn "SendMessage\|RegisterMessage\|NS.bus\|NewBusTarget" core defaults settings modules locales
(no matches)
```

The direct calls the bus would carry:

```
modules/Override.lua:100-102  if NS.Schema and NS.Schema.NotifyPanelChange then
                                  NS.Schema.NotifyPanelChange(category) end
modules/Override.lua:112-113  NS.Schema.NotifyPanelChange()          -- nil → all categories
modules/Override.lua:130-131  NS.Schema.NotifyPanelChange(category)
settings/Schema.lua:270-272   if NS.Helpers and NS.Helpers.RefreshScalars then
                                  NS.Helpers.RefreshScalars() end
```

`architecture-§4` MUSTs named messages over direct calls, and `documentation-§3` requires a
Message Bus section documenting each. Mitigating context, recorded so the fix is proportionate:
the addon has one feature module and no event traffic, so `architecture-§4`'s actual hazard —
two receivers clobbering on a shared target — cannot arise here.

### PC-23 — bespoke 40/60 editor

```
settings/Panel.lua:127   local LEFT_W  = 0.4
settings/Panel.lua:128   local RIGHT_W = 0.6
settings/Panel.lua:130   local function buildStringRow(scroll, category, globalName, strData, refreshers)
settings/Panel.lua:13    "-- documented deviation this file has carried since PC-23 — see buildStringRow."
CLAUDE.md:11             the accepted-deviation record, incl. the LIBKA0S-06 upstream check
```

`options-ui-§6` MUSTs a 50/50 default. The block is host-drawn rather than flow-engine-driven,
and the library's `RenderGrid` offers only `HALF` or full width, so the ratio cannot currently
be expressed through the library.

### PC-27 — TOC branding

```
PrettyChat.toc:2   ## Title: Ka0s |cffff0000P|cffff9900r|cffffff00e|…|cffefefeft|r
PrettyChat.toc:4   ## Author: aDd1kTeD2Ka0s
CLAUDE.md:10       the accepted-deviation record
```

### PC-51 — addon-side test loader

```
tests/loader.lua:1-23    "The instance factory: builds one fully-booted, ISOLATED PrettyChat …
                          Everything about the environment comes from the shared kit —
                          Loader.makeEnv builds the sandbox, Loader.tocFiles derives the
                          addon's own file list from PrettyChat.toc (testing-§9) — and
                          everything about ISOLATION is here, because the kit has no
                          isolated-environment mode …"
tests/loader.lua:25      local Loader = dofile("tests/_kit/loader.lua")     ← delegates, not forks
tests/loader.lua:32-41   the eight LibKa0s files spelled out in XML order (testing-§9 MUST)
tests/run.lua:14-18      Kit + mock + loader wiring
CLAUDE.md:12             the accepted-deviation record, incl. LIBKA0S-01 upstream report
```

This is materially **weaker** than a `#47` fork — the kit's registry, assertions, runner,
`--list` renderer, TOC reader and mock base are all used unmodified — which is why it is graded
SHOULD rather than MUST.

### PC-53 — no Message Bus heading

```
$ grep -n '^## ' docs/ARCHITECTURE.md
5:## Overview          28:## Module Map        64:## Namespace publishing pattern
89:## Invariants       102:## Settings Schema  113:## Slash Commands
117:## Event Subscriptions   121:## Taint Notes  129:## Known Limitations
137:## External dependencies 145:## Testing      149:## Working environment
156:## Doc index
```

`documentation-§3` lists Message Bus among the required sections; the content is present at
`:119` but under the wrong heading.

### PC-54 — mono font not LSM-registered

```
core/Constants.lua:54-59  "… LibSharedMedia registration is intentionally omitted: PrettyChat
                           ships no font-picker consumer … a documented SHOULD-deviation from
                           debug-logging-§2."
core/Constants.lua:60     Const.FONT_MONO = "Interface\\AddOns\\PrettyChat\\media\\fonts\\JetBrainsMono-Regular.ttf"
core/DebugLogSetup.lua:116 font  = NS.Const.FONT_MONO
```

The font itself is correctly vendored **with its license**:

```
$ ls media/fonts/
JetBrainsMono-Regular.ttf   OFL.txt
```

Per `debug-logging-§2` and `standalone-windows`, the shipped console font and the logo are
**sanctioned** and are not flagged as styling deviations — only the missing LSM registration is.

### PC-55 — no complexity report

```
$ ls docs/complexity.md
ls: cannot access 'docs/complexity.md': No such file or directory
```

### PC-52 / PC-56 — advisory

```
$ ls libs/
AceAddon-3.0  AceConsole-3.0  AceDB-3.0  AceGUI-3.0  CallbackHandler-1.0  LibKa0s  LibStub
                                    ← no AceEvent-3.0, no AceTimer-3.0
$ grep -rn 'LibStub("AceEvent\|LibStub("AceTimer' core defaults settings modules locales
(no matches)                        ← and neither is used, so library-stack-§3 is satisfied

PrettyChat.toc:10   ## Category-enUS: Chat & Communication
```
</content>
