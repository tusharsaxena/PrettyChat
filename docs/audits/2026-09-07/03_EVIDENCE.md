# 03 — Evidence (Ka0s Pretty Chat)

**Run date:** 2026-09-07 · **Standard:** v2.38.0 (2026-09-02)

Every `file:line` below was re-read at write time and the cited text is quoted beside it. Every count
is produced by a recorded command whose **scope** is stated. No figure is carried over from an earlier
bundle.

---

## 1. Mechanical suites

### `luacheck .`

Run from the repo root. Scope: everything except `.luacheckrc`'s `exclude_files` — `Libs`, `libs`,
`GlobalStrings`, `docs/audits`, `docs/reviews`, `tests` (`.luacheckrc:14-21`). So this covers the 18
shipped source files and **not** the harness, the vendored libraries or the generated data.

```
$ luacheck .
Checking core/Constants.lua                       OK
… 18 files …
Total: 0 warnings / 0 errors in 18 files
```

### Headless suite

```
$ lua tests/run.lua
…
300 passed, 0 failed, 0 skipped, 300 total
```

Scope: all 18 `tests/test_*.lua` suites through `tests/run.lua`. This is the figure the README badge
must track, and it does — `README.md:7` reads `Tests-300%2F300_passing`, and
`docs/test-cases.md:385` reads `| **Total** | **300** |`.

### `lizard`

The standard's invocation, verbatim, from the repo root:

```
$ lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .
…
No thresholds exceeded (cyclomatic_complexity > 15 or length > 1000 …)
Total nloc   Avg.NLOC  AvgCCN  Avg.token   Fun Cnt  Warning cnt   Fun Rt   nloc Rt
     52211       6.4     1.9       48.0      645            0      0.00    0.00
```

Scope: the whole tree except `libs/` and `tests/_kit/` — so it **includes** `GlobalStrings/` and
`tests/`, exactly as the recorded bundles do, which is what makes the two comparable.

**Drift against the newest recorded bundle** `docs/automated-tests/20260825-103457/complexity.txt`
(its last line: `51480 6.3 1.9 47.6 555 0 0.00 0.00`):

| Quantity | `20260825-103457` | Today | Drift |
|---|---|---|---|
| Total NLOC | 51,480 | 52,211 | +731 |
| Functions | 555 | 645 | +90 |
| Warnings (CCN > 15) | 0 | 0 | — |
| Tests | 271/271 | 300/300 | +29 |
| Lint files | 18 | 18 | — |

No function crossed a `lizard` threshold and no file entered `layout-§1`'s 1000–1500 band. The
recorded bundle's own stamp is 2026-08-25 (`manifest.json`: `"startedAt": "2026-08-25T10:34:57+05:30"`,
`"release": null`), and the last source commit is `92c43f5` (2026-09-03), so the record is 13 days and
one feature branch behind the tree. See PC-65.

### Watch list (`docs/automated-tests/RESULTS.md`)

One entry in either table carries a disposition, and it reads **Accepted**:

> `RESULTS.md:84` — `| > 1500 (over cap) | GlobalStrings/GlobalStrings.lua | 23840 | **Accepted — not
> shipped and not loaded.** …`

The function watch list is empty (`RESULTS.md:64` — `| — | — | — | **None.** Zero warnings over 531
functions; nothing is deferred. |`). Consecutive-run count for the one Accepted entry, from
`git log --format='%h %ad %s' --date=short -- docs/automated-tests/RESULTS.md`: `7de1655` (2026-08-25),
`14c1957` (2026-08-07), `b7b9180` (2026-08-07). None of those runs is a **release** run — every
`manifest.json` in the store carries `"release": null` — so anti-pattern #53's three-release clock has
not started, exactly as `RESULTS.md:91-95` states. Not a deviation.

The five near-threshold functions the list names are all dense **defaulting and guarding** rather than
tangled control flow, which the list itself says at `RESULTS.md:71-75`; today's run confirms the
maximum is unchanged in kind (zero warnings).

---

## 2. Vendored Ka0s-owned library drift

Sibling repo found at `/mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s`. Provenance line read out of
root `CLAUDE.md`, **not** `README.md`:

```
$ grep -n 'Bundles \[LibKa0s\]' CLAUDE.md
30:- **Library provenance — this line is the gate's input.** Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.25.0 (MIT). …

$ grep -n 'Bundles \[LibKa0s\]' README.md
(no output)

$ grep -nE '^## (Libraries|Bundled libraries|Libraries and credits|Credits and libraries|Credits and bundled libraries)' README.md
(no output)

$ grep -n 'WoW_Addon_Standard' README.md
6:![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)
```

The badge is the **bare** `![Standard](…)` form, not wrapped in a link. Anti-patterns #58 and #59 both
clear.

The tag `v1.25.0` was materialized from the sibling repo (`git archive v1.25.0 LibKa0s testkit`) so
the comparison is against the ref the addon declares, not the sibling's `HEAD`. Both diffs use
`--strip-trailing-cr` because the addon's working tree is CRLF-pinned while a `git archive` payload is
LF; without it the flag would report every line of every file.

```
$ diff -r --strip-trailing-cr <v1.25.0>/LibKa0s  ./libs/LibKa0s
(no output)

$ diff -r --strip-trailing-cr <v1.25.0>/testkit  ./tests/_kit
(no output)
```

**Both empty.** No anti-pattern #45 drift and no #48 partial vendoring. The harness is under `tests/`,
never `libs/`, as required. `PrettyChat.toc:21` lists the aggregate once —
`libs\LibKa0s\LibKa0s.xml` — and no individual module `.lua`.

---

## 3. Recorded-deviation register and the issue store

```
$ gh issue list --state all --limit 200 --json number,title,state,labels …
13 CLOSED [state:will-not-do,severity:low] LibKa0s-Pool-1.0: declined — AceGUI is already the pool
12 CLOSED [state:will-not-do,severity:low] LibKa0s-Item-1.0: declined — the addon edits format templates, never links
11 CLOSED [state:will-not-do,severity:low] LibKa0s-Widgets-1.0: declined — no control in this addon wants it
10 CLOSED [state:will-not-do,severity:low] LIBKA0S-12: Perf declined on two independent structural grounds
 9 CLOSED [state:done,severity:low]        LIBKA0S-04: Options adopted; OpenConfig delegates to OpenOptionsPanel
 8 CLOSED [state:will-not-do,severity:low] Expose per-character or per-realm profile scoping
 7 CLOSED [state:will-not-do,severity:low] Add `## X-Wago-ID` to PrettyChat.toc
 6..1 OPEN [state:triaged,severity:low]    (four known limitations + two feature requests)
```

Read with `gh issue list --json`/`--label`, never `gh api graphql`. Every issue carries a `state:` and
a `severity:` label; **no** `[status]` title prefix survives (anti-pattern #62 clear). There is no
`docs/pending/` directory and no `LEDGER.md` (`find . -name LEDGER.md` returns nothing).

**The inverse check — a `state:will-not-do` with no register row.** Four such issues exist:

| Issue | Register row? | Verdict |
|---|---|---|
| #10 Perf declined | Yes — `docs/ARCHITECTURE.md:220`, `performance-§12`, Decided 2026-08-05 / re-checked 2026-09-02 | Ratified. |
| #7 `X-Wago-ID` | Yes — `docs/ARCHITECTURE.md:223`, `toc-file-§1`, Decided 2026-07-12 | Ratified. |
| #11/#12/#13 Widgets/Item/Pool unwired | No row, and none is owed | `library-stack-§3:39` MUSTs vendoring only what the addon `LibStub`s, and `library-stack-§7` keeps the whole LibKa0s ship folder regardless. Not consuming a major is compliance, not deviation. `docs/ARCHITECTURE.md:234-236` records the fact without claiming it is a deviation, which is correct. |
| #8 profile scoping | No row, and none is owed | `options-ui-§3` — *"**MAY** ship a Profiles sub-category"*. Declining a MAY is not a deviation. |

Register health: eleven rows at `docs/ARCHITECTURE.md:220-230`, each with Rule / What differs / Why /
Decided / Re-check trigger. One row cites a rule the standard has since changed — see §5 below.

---

## 4. Line endings

```
$ test -f .gitattributes && echo present
present

$ grep -n '^\* text=auto eol=\(crlf\|lf\)$' .gitattributes
26:* text=auto eol=crlf

$ grep -n '^\*\.sh text eol=lf$' .gitattributes
34:*.sh text eol=lf

$ grep -c ' binary$' .gitattributes
20
```

The repo ships a `.toc`, so it is **client-bound** and `crlf` is the correct pin. The file is not the
`*.sh`-only near-miss `line-endings-§1` names: the pin sits above the carve-out with its rationale,
and the body matches the canonical client-bound document including the renormalize recipe.

Working-tree agreement, run exactly as the playbook writes it. Scope: **every tracked file**,
`git ls-files`, with `binary`-marked paths skipped by the `text=unset` guard.

```
$ git ls-files -z | xargs -0 -I{} sh -c '
    set -- $(git check-attr text eol -- "{}" | sed "s/.*: //")
    [ "$1" = unset ] && exit
    cr=$(tr -dc "\r" < "{}" | wc -c); lf=$(tr -dc "\n" < "{}" | wc -c)
    case "$2" in crlf) [ "$lf" -gt 0 ] && [ "$cr" -ne "$lf" ] && echo "{}";;
                 lf)   [ "$cr" -gt 0 ] && echo "{}";; esac' 2>/dev/null | wc -l
4
```

**4** — reported as one rolled-up finding (PC-66), never file by file, because the remedy is a single
`git add --renormalize .` plus a re-checkout. Earlier frozen bundles quoted a much larger number for
this repo using the pre-v2.28.1 command, which counted binaries and JSON as strays; those bundles are
frozen and are not edited.

---

## 5. Per-deviation evidence

### PC-60 — unannotated load-bearing TOC positions (`toc-file-§5`)

```
PrettyChat.toc:40   core\Util.lua
core/Util.lua:14    local Color = NS.Const.Color
```

`NS.Const` is published by `core/Constants.lua`, listed at `PrettyChat.toc:37`. The dependency is
written down — but in the wrong file: `core/Util.lua:5` reads *"Loads after Constants so
NS.Const.Color exists."* `toc-file-§5` requires the comment **at the TOC line**.

```
PrettyChat.toc:43   core\CoreSetup.lua
core/CoreSetup.lua:39   local Util = NS.Util
```

`NS.Util` is `core/Util.lua`'s (`PrettyChat.toc:40`). The same file's `:131-132` reclaim of `NS.Print`
also depends on `core\PrettyChat.lua` (`:42`) having run — `core/PrettyChat.lua:13` says *"Keep that
order: NewAddon here, the reclaim immediately after"*, again in the `.lua` rather than the TOC.

```
PrettyChat.toc:57   settings\Panel.lua
settings/Panel.lua:22   local H      = NS.Helpers
```

`NS.Helpers` is published by `settings/OptionsSetup.lua` (`PrettyChat.toc:55`).

The compliant shape already exists twice in this file and is the model for the fix:

```
PrettyChat.toc:34-35
# core\MediaSetup.lua loads BEFORE core\Constants.lua and the position is load-bearing:
# Constants resolves FONT_MONO through NS.MediaFont at load, so the seam must be published first.
```

The SHOULD half: no line or group in the listing is marked **conventional**, so every unannotated
line reads as ambiguous between *free to move* and *not yet understood*.

### PC-61 — a register row citing a since-changed rule (`audit-review-history`)

```
docs/ARCHITECTURE.md:222
| `toc-file-§5` | `# Locales` sits immediately after `# Libraries` rather than after `# Defaults` |
… The Locales placement is a **standard-internal conflict**: `toc-file-§5` orders Locales before
Defaults, `layout-§1`'s load order puts Defaults first, and the two disagree … | 2026-07-18 |
WowAddonStandards#2 resolving. …
```

The standard as fetched today:

```
standards/standards/layout.md:53
- **MUST** load in this **folder** order: `libs/*` → `locales/*` → `core/*` → `defaults/*` →
  `modules/*` → `settings/*`. … This is the same order the TOC's `#` section headers express
  (toc-file-§5) — one order stated in two places, and if the two ever disagree that is a defect in
  this document rather than a choice an addon gets to make.
```

`toc-file.md:71-104` gives the same header order. The conflict the row records no longer exists, and
the addon's TOC (`PrettyChat.toc:15,24,27,46,50,53` = Libraries, Locales, Core, Defaults, Modules,
Settings) is what both halves now mandate. The row's re-check trigger has therefore already fired.

### PC-62 — the message-bus applicability trigger (`architecture-§4`)

```
modules/Override.lua:80    combatWatcher = CreateFrame("Frame", "PrettyChatCombatWatcher")
modules/Override.lua:90-96 for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
                               if wanted then combatWatcher:RegisterEvent(event)
```

The standard:

```
standards/standards/architecture.md — §4 Applicability
This MUST binds an addon with **two or more feature modules**, or **any module that registers game
events**. Below that threshold — one feature module and no event traffic — direct calls are
**permitted**, and `docs/ARCHITECTURE.md`'s `## Message Bus` section … **MUST** record that there is
no bus and why.
```

The addon's own record still describes the below-threshold state:

```
docs/ARCHITECTURE.md:125
**There is none, because this addon publishes no named message.** A whole-repo sweep … returns zero
`SendMessage`, zero `RegisterMessage` and zero `AceEvent` …
```

That sweep is accurate — the finding is not that a message was missed, it is that the section's
**event** trigger has fired and the register carries no row for it. The section's own rationale (the
CallbackHandler `(message, target)` clobber) is unreachable here: there is exactly one feature module
and no second receiver, which is why this is graded Low and why the fix direction prefers the upstream
route.

### PC-63 — `.pkgmeta` ignore list (`packaging`)

Named-entry check:

```
$ for e in .luacheckrc .gitignore .gitattributes .claude .superpowers docs tests _dev; do
    grep -q "^  - $e\b" .pkgmeta || echo "NOT IGNORED — $e"; done
NOT IGNORED — .claude
NOT IGNORED — .superpowers
```

Exhaustive dot-entry check — scope: every root dot-entry that exists on disk:

```
$ for e in .[!.]*; do [ -e "$e" ] || continue;
    grep -q "^  - $e\b" .pkgmeta || echo "UNACCOUNTED — $e"; done
UNACCOUNTED — .claude
UNACCOUNTED — .git
UNACCOUNTED — .pkgmeta
```

`.superpowers` does not exist here, so only `.claude` is a live payload leak; `.git` never needs a row.
`.claude/` holds `settings.local.json` today, but the directory is the class of thing the check exists
for. `.pkgmeta:8-32` shows the ignore list as it stands, each entry commented.

### PC-64 — a stub member the addon publishes on only one path

```
core/CoreSetup.lua:41   local lib = LibStub and LibStub("LibKa0s-Core-1.0", true)
core/CoreSetup.lua:43   if not lib then
core/CoreSetup.lua:84       return
core/CoreSetup.lua:85   end
core/CoreSetup.lua:111  NS.MakeCloseButton = function(parent, onClick)
core/CoreSetup.lua:112      return lib.MakeCloseButton(parent, onClick, addonName)
```

The degraded branch exits at `:84`, so `:111` never runs when the library is absent. The file states
the opposing rule for its neighbour three lines earlier:

```
core/CoreSetup.lua:74-77
-- Published on BOTH paths, not just the library one. Nothing calls it today,
-- which is exactly why it would go unnoticed: the first caller added later
-- would work in every install that has the library and be nil in the one this
-- branch exists for.
```

The parity case cannot catch it, because its projection is hand-listed:

```
tests/test_libka0s.lua:682  -- Members from: grep -nE "^\s*(function )?(NS|Util)\.[A-Za-z]+" core/CoreSetup.lua
tests/test_libka0s.lua:683-689
local function coreSurface(instance)
    return { Print = …, Format = …, IsConcatSafe = …, SafeToString = … }
end
```

That grep, run against `core/CoreSetup.lua`, **does** return `:111 NS.MakeCloseButton = …`, so the
projection is narrower than its own stated derivation. Impact is latent, and the repo says so:

```
docs/ARCHITECTURE.md:80
| `NS.MakeCloseButton` | `core/CoreSetup.lua` | **No host caller today**, …
```

The pattern to copy already exists one file over:

```
core/DebugLogSetup.lua:89   MakeCloseButton = function(_parent, _onClick, _addonName) return nil end,
```

### PC-65 — stale automated-test record

Newest table row:

```
docs/automated-tests/RESULTS.md:25
| [`20260825-103457`](20260825-103457/) | 1.4.0 | 0/0 | 18 | 271/271 | skip | 51480 | 555 | 6.3 | 1.9 | 12 | 0 | **green** |
```

Standing sections still anchored two runs back:

```
RESULTS.md:44  260 cases, across 17 suite files, with **0 skipped** — the figure `20260807-114404` states in full …
RESULTS.md:48  Clean over 17 files, and clean over the same 17 in every recorded run. …
RESULTS.md:56  Current state as of [`20260807-114404`](20260807-114404/) — not that run's diff.
RESULTS.md:84  … Carried forward unchanged; nothing newly crossed a band at `20260807-114404`. |
RESULTS.md:7-9 … `20260807-114404`, `20260807-110428`, `20260807-022707`, `20260804-182235` and
               `20260804-233338` have one, `20260804-214445` does not.
```

The `:7-9` roll-call omits `20260825-103457` entirely. Measured today against those sentences: 300
cases over **18** suite files, lint clean over **18**, `lizard` 645 functions / 52,211 NLOC. The
checkpoint is release (`RESULTS.md:15-20`), so this is a release-process finding and **not** a reason
to say the addon fails to gate commits on complexity — commits gate on lint and the suite, and both
are green.

### PC-66 — see §4 above. Command, scope and output are recorded there; the count is **4**.

### PC-67 — README per-tab breakdown (`documentation-§1` item 7)

```
README.md:66-69   | Page | Covers |  … | **General** … | **Categories** …     ← compliant, page granularity
README.md:71      The **Categories** page carries eight tabs across the top:
README.md:73-82   | Tab | Covers |  … | **Loot** … through | **Misc** … |     ← the per-tab table
```

The rule:

```
standards/standards/documentation.md — §1 item 7, "### Settings panel"
… a **Tab | Covers** table, one row per settings subcategory (options-ui-§5). This is the
player-facing summary and stays at page granularity; the per-tab breakdown that options-ui-§13's
strip makes derivable belongs in `docs/settings-panel.md` (documentation-§3), not here.
```

`docs/settings-panel.md` exists (230 lines) and is the destination the rule names.

### PC-68 — four tables in `## Documentation map` (`documentation-§3`)

```
docs/ARCHITECTURE.md:167  ### Required (documentation-§3, Tier 1)
docs/ARCHITECTURE.md:178  ### Conditional (documentation-§3, Tier 2)
docs/ARCHITECTURE.md:190  ### Verification and record          ← the non-canonical fourth
docs/ARCHITECTURE.md:201  ### Addon-specific (documentation-§3, Tier 3)
```

The rule and its canonical block:

```
standards/standards/documentation.md — §3, "## Documentation map"
Every `.md` under `docs/` appears in **exactly one** of its three tables …
```
followed by a markdown example carrying exactly `### Required` / `### Conditional` /
`### Addon-specific`. The five docs in PrettyChat's fourth table
(`docs/ARCHITECTURE.md:194-199`: `testing.md`, `smoke-tests.md`, `test-cases.md`, `performance.md`,
`automated-tests/README.md`, `automated-tests/RESULTS.md`) are mandated by the same section's
verification list, which the three-table shape gives no home. Filed against the standard, not the
addon's judgment.

Bidirectional check of the map itself — scope: every `.md` under `docs/` excluding the frozen and
generated directories the section names:

| File on disk | In the map? |
|---|---|
| `ARCHITECTURE.md` (the map's own host) | n/a |
| `scope.md`, `module-map.md`, `schema.md`, `settings-panel.md`, `data-flow.md`, `common-tasks.md` | Yes, Tier 1 |
| `slash-dispatch.md` | Yes, Tier 2 "Present", trigger *10 verbs* — matches `settings/Slash.lua:45-66` |
| `testing.md`, `smoke-tests.md`, `test-cases.md`, `performance.md`, `automated-tests/README.md`, `automated-tests/RESULTS.md` | Yes, fourth table |
| `global-strings.md` | Yes, Tier 3 |
| `audits/`, `reviews/`, `automated-tests/<run>/`, `revendor/`, `superpowers/` | Named once each at `docs/ARCHITECTURE.md:164-165`, not enumerated |

**No orphan and no dangling row.** Tier 2's six *Not applicable* rows were each re-checked against the
code today and all six are true: no `core/Compat.lua` exists; zero `SendMessage`/`RegisterMessage`; no
profile control in the schema; no debug surface beyond `LibKa0s-DebugLog-1.0`; no client-version shim;
no perf harness (ratified exemption).

### PC-69 — no selection-invariance case (`options-ui-§13`, `testing-§12`)

Library side is **correct** in the vendored payload, and says so at length:

```
libs/LibKa0s/OptionsWidgets.lua:384-388
-- THE STRIP'S GEOMETRY IS SELECTION-INVARIANT (options-ui-§13, anti-patterns #70). Nothing about
-- where a tab lands, how many rows the strip wraps into, or how tall a band it reserves may depend
-- on WHICH tab is selected. …
libs/LibKa0s/OptionsWidgets.lua:398-399
-- So the pitch is measured ONCE, from the INACTIVE cap atlas, on a throwaway texture …
```

The addon's suite has no matching case — `grep -rn 'unselected\|reserved band\|pitch' tests/*.lua`
returns nothing — and could not have a failing one, because the harness answers one height for every
frame:

```
tests/_kit/mock_base.lua:97   function f:GetHeight() return 0 end
```

The page that would show it first is Categories, with eight tabs built at
`settings/Panel.lua:612-623`. Reported as a **missing** case, not a passing one.

### PC-70 — `CLAUDE.md` adherence line position (`documentation-§2` item 2)

```
CLAUDE.md:1  # CLAUDE.md — Ka0s Pretty Chat
CLAUDE.md:3  **Ka0s Pretty Chat** — a WoW addon that reformats system chat messages by overriding
             Blizzard's `GlobalStrings.lua` format strings (not by parsing chat events).
CLAUDE.md:5  ## Standards compliance (read first)
CLAUDE.md:7  This repo is built to the **Ka0s WoW Addon Standard**
CLAUDE.md:8  (https://github.com/tusharsaxena/WowAddonStandards). …
```

Item 2 is the adherence line; `:3` is a description. The substance appears at `:7-8` but as the
opening of item 3. Items 3, 4, 5 and 6 are all present and in order (`:5`, `:51-53`, `:60`, `:30`).

---

## 6. Compliance evidence — checks run that found nothing

| Check | Command / citation | Result |
|---|---|---|
| Close-button wrapper (`standalone-windows`, anti-pattern #65) | `grep -rn 'MakeCloseButton(' --include='*.lua' . \| grep -v '/libs/' \| grep -v '/tests/'` → one hit, `core/CoreSetup.lua:112` `return lib.MakeCloseButton(parent, onClick, addonName)` | Compliant — the one three-argument wrapper, fed `addonName`; no direct `lib.`/`Core.`/`NS.DebugLog.MakeCloseButton` call anywhere in host code |
| Private media copy (anti-pattern #63) | `media/` holds `logos/` (3 files) and `screenshots/` (5) only; nothing under `libs/LibKa0s/media/` is duplicated | Compliant |
| Media seam fed the folder name | `core/MediaSetup.lua:88` `if Media then Media.RegisterLSM(addonName) end`, with `addonName` the file's first vararg (`:1`); loads at `PrettyChat.toc:36`, above `core\Constants.lua` | Compliant |
| Console told its name (`debug-logging-§13`) | `core/DebugLogSetup.lua:112` `NS.DebugLog = lib:New({` … descriptor carries `addonName` | Compliant |
| Perf-panel decoration hook | No `PerfSetup.lua` and no `decorate` hook anywhere in host code (ratified `performance-§12` exemption) | Not applicable |
| Colour rows (`options-ui-§17`) | `grep -n 'type *= *"color"' settings/Schema.lua` → no output | Not applicable — no colour row exists |
| `disabledIf` on a colour row | `grep -rn 'disabledIf' settings/` → no output | Compliant |
| Ordering-by-drag (`options-ui-§18`) | `grep -rn 'ScrollUp-Up\|ScrollDown-Up' --include='*.lua' settings/` → no output; no `MoveUp`/`MoveDown` handler and no numeric position field | Not applicable |
| Hand-written font/border/bar group (`options-ui-§16`) | `grep -rn 'LSM30_' --include='*.lua' settings/ core/ modules/` → no output | Not applicable |
| Chrome band boxed twice (anti-pattern #72) | `grep -n 'InlineGroup\|SetBackdrop' settings/Panel.lua` → no output; the three `SimpleGroup`s (`:210`, `:293`, `:653`) are layout rows with no backdrop | Compliant |
| Tab strip per page (`options-ui-§13`) | General → `H.RenderTabbedSchema` (`settings/Panel.lua:123`); Categories → `H.TabStrip` (`:616`); landing page is `buildParentBody` (`:646`), one of the two exempt pages | Compliant |
| `Master controls` first tab (`options-ui-§15`) | `settings/Schema.lua:79` `MASTER_SPEC` with `frameless = true` (`:83`); group name taken off the library as `H.MASTER_GROUP` (`settings/Panel.lua:123`) | Compliant |
| Frameless proof | `grep -rn 'SetMovable' core/ modules/ settings/` → two hits, both comments (`modules/Override.lua:70`, `settings/Schema.lua:65`) | Compliant — master scale/alpha/lock/reset-position correctly omitted |
| `General visibility` stored-type migration | `git log --all -S'visibility' -- settings/Schema.lua` → one commit, `8ee771a` (2026-09-02). The path is new; no boolean ever shipped at it | No migration owed. `core/Database.lua:14` `SCHEMA_VERSION = 1` with an empty `migrations` table is correct |
| Reserved verb `perf` (`slash-commands-§2`) | Absent from `settings/Slash.lua:45-66`, which is what the section requires under a recorded `performance-§12` exemption | Compliant |
| Retired docs | No `docs/file-index.md`, `docs/conventions.md`, `docs/complexity.md`, `docs/perf-runs/`, `docs/agent-context.md` (`find docs -maxdepth 2 -name …` → nothing) | Compliant |
| Hub shape (`documentation-§3`) | `wc -l docs/ARCHITECTURE.md` → 269; longest mandated section is `## Documentation map` at 44 lines | Compliant |
| `.luacheckrc` perf entries | No `debugprofilestop` in `read_globals`, no `PrettyChatPerfDB` in `globals` (`.luacheckrc:31-62`) — which `lint` **requires** under the exemption | Compliant |
| Badge sync | `README.md:3` `WoW-Midnight_12.0.7` vs `PrettyChat.toc:1` `## Interface: 120007`; `README.md:7` `Tests-300%2F300` vs `docs/test-cases.md:385` `| **Total** | **300** |` | Both in sync |
| `DEPENDENCIES.md` (`documentation-§7`) | `:15` Runtime, `:45` Development, `:132` Release/assets, `:169` verification commands, `:185` a keep-honest section | Compliant |
