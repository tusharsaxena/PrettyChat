# 03 — Evidence (Ka0s Pretty Chat)

**Run date:** 2026-09-23 · **Standard:** v2.64.0 · **Tree:** `2a32870` on
`feat/2026-09-23-review-audit-remediation`, clean.

Every command below was run from the repo root and its output is pasted as it came back. Every
`file:line` was re-read immediately before it was written here and is quoted beside the citation.
Scope is stated for every count. `ka0s-bounded` is not on `PATH`; every `luacheck`, `lua` and `lizard`
run used `~/.claude/wow-addon/bin/ka0s-bounded` by full path. None exited 124 or 137.

---

## E0. Standard resolution

```sh
RAW=https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master
curl -fsSL $RAW/AUDIT.md            -o AUDIT.md                 # 990 lines
curl -fsSL $RAW/standards/STANDARDS.md -o standards/STANDARDS.md # 242 lines
# then every (standards/<file>.md) link in the Sections list — 27 files, 6027 lines — and ADDONS.md
```

`standards/STANDARDS.md:1` → `# Ka0s WoW Addon Standard (v2.64.0, 2026-09-23)`.
`ADDONS.md` row: `| Ka0s Pretty Chat | [`../../PrettyChat/`] | … | **(c)** the settings panel |` →
kind **Addon**, launcher rung **(c)**.

---

## E1. Lint

```
$ ~/.claude/wow-addon/bin/ka0s-bounded luacheck .
…
Total: 0 warnings / 0 errors in 48 files
luacheck exit 0
```

**Scope.** `.luacheckrc` `exclude_files` = `"Libs"`, `"libs"`, `"GlobalStrings"`, `"docs/audits"`,
`"docs/reviews"`, `"tests/_kit/"` (`.luacheckrc:20-27`). The 48 files are
`git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/|GlobalStrings/)'` → **48** (20 source + 28 test
files incl. `tests/run.lua`, `wow_mock.lua`, `loader.lua`, `prose_waivers.lua`). No top-level
`ignore` (`.luacheckrc:29` — `-- NO TOP-LEVEL \`ignore\`, and none is coming back`); harness globals
in `files["tests/"]`; four one-file `212/self` stanzas, each commented.

## E2. Headless suite and inventory

```
$ ~/.claude/wow-addon/bin/ka0s-bounded lua tests/run.lua
…
  PASS  eol: every tracked file carries the terminator .gitattributes declares for it
  PASS  eol: .gitattributes is line-endings-5's canonical body for this repo kind

438 passed, 0 failed, 0 skipped, 438 total
tests exit 0
```

Selected lines from the same run: `PASS  libs/LibKa0s is the LibKa0s release CLAUDE.md says this addon
bundles`, `PASS  tests/_kit is the test kit that shipped with that release`, `PASS  layoutcap: every
authored file over the 1500-line cap is named in the census`, `PASS  prose: no authored file carries a
British spelling from localization-5's published list`.

```
$ ~/.claude/wow-addon/bin/ka0s-bounded lua tests/run.lua --list > /tmp/list.md   # exit 0
$ diff --strip-trailing-cr /tmp/list.md docs/test-cases.md                       # exit 0, empty
```

`README.md:7` → `![Tests](https://img.shields.io/badge/Tests-438%2F438_passing-green)` — matches.

Kit gates declared by the pair: `tests/run.lua:74` → `{ name = "test_layout_cap", dir = "tests/_kit/" },`;
`tests/run.lua:83` → `{ name = "test_prose", dir = "tests/_kit/" },`;
`tests/run.lua:122` → `{ name = "test_eol", dir = "tests/_kit/" },`.

## E3. Vendored payload (library-stack-§7, testing-§11)

```
$ grep -n 'Bundles \[LibKa0s\]' CLAUDE.md
42:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.55.0 (MIT).
$ grep -n 'Bundles \[LibKa0s\]' README.md                          # nothing
$ grep -nE '^## (Libraries|Bundled libraries|Libraries and credits|Credits and libraries|Credits and bundled libraries)' README.md   # nothing
$ grep -n 'WoW_Addon_Standard' README.md
6:![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)
```

Bare badge, not a link. No `media/logos` or `<img>` in `README.md` (only hit for `<[A-Za-z]` is `<br>`
in the Version History table, `README.md:74`).

```
$ git -C ../LibKa0s rev-parse v1.55.0 HEAD
bb161b730f2691be39a0dfbbe5c66fd7ca5e8db1
46ccaa6c5260e99cd0d1028ab0aee421329cfedf           # sibling HEAD is past the tag; the tag is the ref
$ git -C ../LibKa0s archive v1.55.0 LibKa0s testkit | tar -x -C $SCRATCH/lk
$ diff -r --strip-trailing-cr $SCRATCH/lk/LibKa0s libs/LibKa0s ; echo $?   # 0 — empty
$ diff -r --strip-trailing-cr $SCRATCH/lk/testkit tests/_kit    ; echo $?   # 0 — empty
$ ls $SCRATCH/lk/LibKa0s | wc -l ; ls libs/LibKa0s | wc -l                   # 24 / 24
$ git ls-files -s tests/_kit/run-automated-tests.sh
100755 31ff9b3e429dbb85d52d336bfb286b94bedd838b 0	tests/_kit/run-automated-tests.sh
```

Scope: the whole ship folder (every module, `media/` included) and the whole `testkit/`. Neither #45
(drift) nor #48 (partial vendoring) has an instance. TOC `PrettyChat.toc:29` → `libs\LibKa0s\LibKa0s.xml`
(listed once; no individual module files).

Vendored minors cited in this bundle: `libs/LibKa0s/Slash.lua:21` →
`local MAJOR, MINOR = "LibKa0s-Slash-1.0", 14`; `libs/LibKa0s/Lifecycle.lua:53` →
`local MAJOR, MINOR = "LibKa0s-Lifecycle-1.0", 1`; `libs/LibKa0s/OptionsCompose.lua:29` →
`local COMPOSE_MINOR = 7`.

## E4. Line endings (line-endings-§1..§7)

```
$ grep -nE '^\* text=auto eol=(crlf|lf)$|^\*\.(sh|py) text eol=lf$' .gitattributes
26:* text=auto eol=crlf
36:*.sh text eol=lf
37:*.py text eol=lf
$ grep -c ' binary' .gitattributes
23
$ n=84 ; diff <(head -n 84 .gitattributes | tr -d '\r') canonical-client.gitattributes ; echo $?
0
$ tail -n +85 .gitattributes | tr -d '\r' | grep -m1 . ; echo $?
1                                   # nothing follows the body — no appendix, none needed
$ git ls-files -z | xargs -0 -I{} sh -c '<the (e) one-liner, verbatim from AUDIT.md>' 2>/dev/null | wc -l
0
```

`canonical-client.gitattributes` = `line-endings.md:166-249` of the fetched standard (84 lines).
Scope of (e): the whole tracked set, no exclusions (449 paths before this bundle). The kit gate
`tests/_kit/test_eol.lua` is wired and green (E2), so a future stray reddens the suite.

## E5. Packaging (packaging)

```
(a) entries: .luacheckrc .pkgmeta .gitignore .gitattributes docs tests _dev .claude   → nothing printed
(b) UNACCOUNTED — .git                                                                   → .git only (never owed)
(c)                                                                                       → nothing printed
$ grep -n '^externals' .pkgmeta ; echo $?     # 1 — no externals block
```

Run under `bash` (the playbook's loops rely on word splitting). `.pkgmeta:39` → `  - GlobalStrings`;
`.pkgmeta:21` → `  # It is listed because packaging.md:28 MUSTs every root dot-entry present in`;
`.pkgmeta:25` → `  - .claude     # untracked; listed under packaging.md:28` (PC-86 item 7).

## E6. Settings panel, launcher and UI greps (options-ui, launcher, standalone-windows)

```
$ grep -rn 'MakeCloseButton(' --include='*.lua' core modules settings
core/CoreSetup.lua:94:    function NS.MakeCloseButton() return nil end
core/CoreSetup.lua:123:    return lib.MakeCloseButton(parent, onClick, addonName)
$ grep -rnE 'SettingsPanel|HideUIPanel|ToggleGameMenu|OpenToCategory' core modules settings
core/PrettyChat.lua:254:-- open settings panel" line on a false return from Settings.OpenToCategory, and   (comment)
$ grep -rn 'ScrollUp-Up\|ScrollDown-Up' settings/        # nothing
$ grep -rn 'LSM30_' core modules settings               # nothing
$ grep -rn 'disabledIf' settings/                        # nothing
$ grep -rn 'InCombatLockdown' core settings modules      # nothing — no host combat lock
$ grep -rn 'SetMovable' core settings modules defaults locales
settings/Schema.lua:87:-- PrettyChat is FRAMELESS — `grep -rn SetMovable core/ modules/ settings/`
modules/Override.lua:95:-- no size, no anchor, no SetMovable — so the composed Master controls tab stays
```

Only the wrapper and its degraded twin define `MakeCloseButton`; no caller. No Blizzard-settings close
path. Frameless proven by the sweep (two comments, no calls).

Hand-concatenated texture paths (the logo files, not catalog marks):
`core/LauncherSetup.lua:108` → `local ICON_PATH = "Interface\\AddOns\\" .. addonName`;
`settings/Panel.lua:34` → `local LOGO_PATH = "Interface\\AddOns\\" .. addonName`.

TGA headers read with `od` (byte 2 type; 12–13 / 14–15 width/height; 16 bpp):

```
media/logos/prettychat.logo.128.tga:    2 type; w=   128 h=   128 bpp=  32; size=65580
media/logos/prettychat.logo.tga:       10 type; w=   300 h=   300 bpp=  24; size=215628
```

`PrettyChat.toc:6` → `## IconTexture: Interface\AddOns\PrettyChat\media\logos\prettychat.logo.128.tga`.

Launcher: `core/LauncherSetup.lua:142` → `        label = "Ka0s Pretty Chat",`;
`core/LauncherSetup.lua:118` → `        name = addonName,`; no `onClick` key in the descriptor
(`:112-176`). `core/Database.lua:37` → `        minimap = { hide = false },`.
`modules/Override.lua:332` → `local GENERAL_RESET_PATHS = { "General.enabled", "General.visibility" }`.

Global reset popup: `settings/Panel.lua:48` →
`    text         = L["Reset this profile to the addon's defaults? Everything you have configured or added in it is discarded — your other profiles are not affected."],`
(verbatim `options-ui-§12` wording); `modules/Override.lua:402` →
`    NS.Util.RunAct(function() db:ResetProfile() end, function()`.

### PC-81 — the Categories Defaults button

- `settings/Panel.lua:738` → `        defaultsTooltip = L["Reset the strings on the selected category tab to their defaults."],`
- `settings/Panel.lua:752` → `    ctx.panel.defaultsOnClick = function()`
- `settings/Panel.lua:753` → `        PrettyChat:ResetCategory(activeCategory(ctx))`
- `README.md:31` → `… Undo works at whatever scale you need: **Reset** on one message, **Defaults** on the tab you are looking at, **Reset all settings** for the lot. …`
- Rule: `options-ui.md:316` → `- **The per-page Defaults button stays page-wide.** Its label and its position do not change, so its blast radius **MUST NOT** narrow to the visible tab.`

### PC-96 — the General page has no Defaults button

- `settings/Panel.lua:722` → `        defaultsButton = false,`
- `docs/settings-panel.md:79` → `The General sub-page does not show a \`Defaults\` button in the header — the in-body reset with its popup confirm is the only addon-wide reset surface, and showing both would be redundant.`

### PC-87 — the Test tooltip

- `settings/Schema.lua:162` → `        tooltip = NS.L["Print a sample of every active format string to the debug console, so you can see what real loot/currency/XP messages will look like. \`/pc test\` prints the same report to chat."],`
- `settings/Slash.lua:62` → `    {"test",     L["Print sample chat lines to the debug console — \`/pc test [all | category <name> | formatstring <NAME>]\`"],`
- `settings/Panel.lua:102` → `    NS.DebugLog:Show()`; `settings/Panel.lua:103` → `    PrettyChat:Test(filter, function(line) NS.DebugLog:Add("Test", line) end)`
- `git log -S'H.TextRow(ctx' -- settings/Panel.lua` → `8be34c6 2026-09-16 /pc test writes to the debug console, like the Test button always did`

## E7. TOC position annotations (PC-77..PC-80, PC-60)

Denominator established from the seam files' file-scope reads, not from the TOC:

| TOC line | Quoted | File-scope read that pins it | Annotated? |
|---|---|---|---|
| `PrettyChat.toc:40` | `core\EnvSetup.lua` | `core/Namespace.lua:8` `NS.version = NS.Meta("Version") or "1.5.0"` | yes, `:35-39` |
| `PrettyChat.toc:43` | `core\MediaSetup.lua` | `core/Constants.lua:71` `Const.FONT_MONO = NS.MediaFont and NS.MediaFont(Const.FONT_MONO_NAME) or _G.STANDARD_TEXT_FONT` | yes, `:41-42` |
| `PrettyChat.toc:50` | `core\Util.lua` | `core/Util.lua:14` `local Color = NS.Const.Color` | yes, `:47-49` |
| **`PrettyChat.toc:53`** | **`core\CoreSetup.lua`** | `core/PrettyChat.lua:14` `local PrettyChat = LibStub("AceAddon-3.0"):NewAddon(NS, addonName, "AceConsole-3.0")` → reclaimed at `core/CoreSetup.lua:142` `NS.Print  = printer.Print` | **no** (PC-77) |
| **`PrettyChat.toc:54`** | **`core\DebugLogSetup.lua`** | `core/DebugLogSetup.lua:128` `    font  = NS.Const.FONT_MONO,` | **no** (PC-78) |
| `PrettyChat.toc:61` | `core\LifecycleSetup.lua` | none at load (closures) | conventional, `:55-60` |
| `PrettyChat.toc:67` | `core\LauncherSetup.lua` | none at load | conventional, `:62-66` |
| **`PrettyChat.toc:78`** | **`settings\OptionsSetup.lua`** | `settings/OptionsSetup.lua:271` `    get          = NS.SchemaRuntime.Get,`; `:312` `NS.Schema.InstallMasterControls(NS.Helpers)` | **no** (PC-79) |
| **`PrettyChat.toc:79`** | **`settings\Slash.lua`** | `settings/Slash.lua:265` `    get          = NS.SchemaRuntime.Get,` | **no** (PC-80) |
| `PrettyChat.toc:84` | `settings\Panel.lua` | `settings/Panel.lua:22` `local H      = NS.Helpers` | yes, `:80-83` |

Hub corroboration: `docs/ARCHITECTURE.md:35` → `**Six positions in that order are load-bearing and are pinned by tests, not by convention:**`, followed by bullets for CoreSetup (`:43`), DebugLogSetup (`:44`) and OptionsSetup (`:45`).

Group headers (PC-60): `PrettyChat.toc:34` → `# Core (the LibKa0s seams load first)`;
`PrettyChat.toc:73` → `# Modules (the override pipeline)`;
`PrettyChat.toc:76` → `# Settings (last — depend on everything else being initialized)`;
compare `PrettyChat.toc:31` → `# Locales (locale table — no earlier-load dependency; toc-file-§5 section order)`.

## E8. Disabled state (slash-commands-§7) — registration census

Scope: `git ls-files '*.lua' ':!libs' ':!tests/_kit'` (75 files incl. `GlobalStrings/` and `tests/`).

```
$ … | xargs grep -nE 'Register(Unit)?Event|RegisterMessage|RegisterBucketEvent' | wc -l
4
      1 modules/Override.lua          # :139 combatWatcher:RegisterEvent(event)
      3 tests/wow_mock.lua            # the mock
$ … | xargs grep -nE 'Unregister(All)?Events?|UnregisterMessage|UnregisterBucket|CancelTimer|CancelAllTimers|:Cancel\(|SetScript\("OnUpdate", *nil\)' | grep -v '^tests/'
modules/Override.lua:131:        -- UnregisterAllEvents rather than the two by name: …   (comment)
modules/Override.lua:135:        combatWatcher:UnregisterAllEvents()
$ … | grep -v '^tests/' | xargs grep -nE 'hooksecurefunc|HookScript|SecureHook|RawHook|SetScript\(|C_Timer|NewTicker|ScheduleTimer|OnUpdate'   (code lines only)
modules/Override.lua:121:        combatWatcher:SetScript("OnEvent", function()
settings/Panel.lua:517:    if not ctx.__pcTreeHooked and frame and frame.HookScript then
settings/Panel.lua:519:        frame:HookScript("OnSizeChanged", function() fitTree(ctx) end)
settings/Panel.lua:538:    if C_Timer and C_Timer.After then
settings/Panel.lua:539:        C_Timer.After(0, function() fitTree(ctx) end)
$ … | xargs grep -n '\benabled\b' | grep -v '^tests/\|^GlobalStrings' | wc -l
58
```

The one live registration is undone at the source: `modules/Override.lua:115` →
`    local wanted = (not self:IsStoodDown())`, `:135` → `        combatWatcher:UnregisterAllEvents()`.
The panel's `HookScript` and one-shot `C_Timer.After(0)` are on the settings panel body (setup).
Latch: `core/LifecycleSetup.lua:67` → `local Lifecycle = LibStub and LibStub("LibKa0s-Lifecycle-1.0", true)`;
`settings/Schema.lua:202` → `            NS.Lifecycle:Set(NS.HOLD_DISABLED, not v)`;
`core/PrettyChat.lua:207` → `    NS.Lifecycle:Set(NS.HOLD_DISABLED, not self:IsAddonEnabled())`;
`core/PrettyChat.lua:88` → `    NS.Lifecycle:Set(NS.HOLD_DISABLED, not self:IsAddonEnabled())`.
Slash gate: `settings/Slash.lua:258` → `    isEnabled = function() return PrettyChat:IsAddonEnabled() end,`;
`:259` → `    brandName = "Ka0s Pretty Chat",`.
Suite: `tests/test_disabled.lua:175` → `test("disabled/3: every registration is UNREGISTERED, not gated", function()`;
`:176` → `    -- red under: drop the \`not self:IsStoodDown()\` term from SyncCombatWatch's`;
`:228` → `    -- red under: drop the \`not self:IsStoodDown()\` term from SyncCombatWatch AND the`;
`:414` → `    -- red under: replace NS.Lifecycle with a bare boolean — a \`resume\` that writes`.

## E9. Events (PC-84, PC-85) and performance-§12 trigger

- `modules/Override.lua:120` → `        combatWatcher = CreateFrame("Frame", "PrettyChatCombatWatcher")`
- `modules/Override.lua:138` → `    for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do`
- `modules/Override.lua:139` → `        combatWatcher:RegisterEvent(event)`
- Rule text: `events-frames-taint.md:24` → `… Not a private \`RegisterEvent\` for an event the client does not filter by unit, …`; `:30` → `- A registration block **MUST** survive one bad name. Registration is **isolated per event**: every \`RegisterEvent\` goes through a single \`pcall\`ed helper, …`
- Contradiction: `library-stack.md:24` → `… the two combat-boundary events its visibility watcher needs go on a plain frame it creates lazily and drops again (\`PrettyChat/modules/Override.lua:67-80\`, argued in place). …`

**PC-102 (architecture-§4).** Rule `architecture.md:64-65` → `**Applicability.** This MUST binds an addon with **two or more feature modules**, or **any module that` / `registers game events**. …`. The addon's event-registering module: `modules/Override.lua:139` (above). Direct cross-module calls: `settings/Schema.lua:730` → `        if not row.sessionOnly then PrettyChat:ApplyStrings() end`; `:731` → `        Schema.NotifyPanelChange(row.category)`. Hub: `docs/ARCHITECTURE.md:139` → `**There is none, because this addon publishes no named message.** …`; `:143` → `**Re-check trigger:** the first \`LibStub("AceEvent-3.0")\` in this addon. …`. Bus greps (scope `git ls-files '*.lua' ':!libs' ':!tests/_kit'`): `(Send|Register)Message\(` → no hits (exit 123); `"Ka0s_[A-Za-z]+_[A-Za-z0-9_]+"` → no hits.

`performance-§12` trigger: the sweep above returns only boundary events and a one-shot panel fit; the
register row's citation `settings/Panel.lua:538-539` still resolves to the `C_Timer.After(0, …)` lines.
Not fired.

## E10. Generator placement (PC-83)

```
$ git ls-files '*.py' '*.sh'
GlobalStrings/split_globalstrings.py
tests/_kit/run-automated-tests.sh          # vendored, and a runner — out of scope
$ ls tools
ls: cannot access 'tools': No such file or directory
```

`DEPENDENCIES.md:150` → `| **Run** | \`python3 GlobalStrings/split_globalstrings.py\`, from the repo root |`.
Rule: `layout.md:93` → `… Pretty Chat answered it the other way and is **newly non-compliant**: its splitter sits at \`GlobalStrings/split_globalstrings.py\`, …`.

## E11. Census and exemption (layout-§1)

```
$ git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)' | wc -l
75
$ git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)' | xargs wc -l | awk '$1>1500 && $2!="total"'
  23842 GlobalStrings/GlobalStrings.lua
$ … | awk '$1>=1000 && $1<=1500'
   1053 tests/test_panel.lua
```

Scope: the default denominator (every tracked `.lua` minus `libs/` and `tests/_kit/`); `tests/` in,
`GlobalStrings/` in. Exempt set declared at `tests/run.lua:61` → `Kit.layoutCap = { exempt = { "GlobalStrings/" } }`.
Census: `docs/ARCHITECTURE.md:307` → `### Files over the 1500-line cap`, under `## Documented deviations` (`:250`).
Exemption conditions: `GlobalStrings/GlobalStrings.lua:1` → `-- AUTOMATICALLY GENERATED -- Your benefactors send their regards.`;
`grep -n 'GlobalStrings' PrettyChat.toc` → nothing; `.pkgmeta:39` → `  - GlobalStrings`;
`tests/test_defaults.lua:181` reads chunks with `loadfile` (data, not a load list).

## E12. Complexity (performance-§10, automated-tests)

```
$ ~/.claude/wow-addon/bin/ka0s-bounded lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .
…
No thresholds exceeded (cyclomatic_complexity > 15 or length > 1000 or nloc > 1000000 or parameter_count > 100)
Total nloc   Avg.NLOC  AvgCCN  Avg.token   Fun Cnt  Warning cnt   Fun Rt   nloc Rt
     54817       6.6     1.9       51.0      941            0      0.00    0.00
$ lizard --version
1.24.0
```

Scope: `.` minus `./libs/*` and `./tests/_kit/*` — the invocation verbatim; includes `GlobalStrings/`
(most of the NLOC) and the addon's own `tests/`.

Record: `docs/automated-tests/RESULTS.md:26` →
`| [\`20260916-184747\`](20260916-184747/) | 1.5.0 | 0/0 | 46 | 385/0/385 | skip | 54311 | 854 | 6.7 | 2.0 | 14 | 0 | **green** |`;
its manifest: `"git": { "sha": "093305b90d0e47839dccf66635f2076b7c504b31", "branch": "master", "dirty": false }`.
`git rev-list --count 093305b..HEAD` → **30**. Drift: +87 functions, +506 NLOC, 0 → 0 warnings, band
unchanged (one file). Release markers (`"release"` in each manifest): only `20260910-234511` →
`"release": "1.5.0"`. `tests/test_panel.lua` has carried *Accepted* across **one** release run —
not #53.

### PC-90 / PC-91 / PC-92 — the record's authored and generated text

- `docs/automated-tests/RESULTS.md:58` → `**This repo ships no \`tests/perf.lua\`, so \`perf\` is a permanent \`skip\`** — the first of`
- `docs/automated-tests/RESULTS.md:60` → `` `performance-§12` no-combat-path exemption. The record is therefore **silent about runtime ``
- manifest `20260916-184747`: `"perf": { "status": "skip", … "skipReason": "no tests/perf.lua — this addon ships no offline scenarios", …`
- `tests/_kit/run-automated-tests.sh:343` → `    if [ ! -f tests/perf.lua ]; then`; `:344` → `        ST[perf]="skip"; NOTE[perf]="no tests/perf.lua — this addon ships no offline scenarios"`
- `docs/ARCHITECTURE.md:269` → `| \`performance-§12\` | No perf harness is wired: …` (the exemption the record says is absent)
- `docs/testing.md:238-239` → `… The one narrow exception is` / `` `perf` skipped because this addon ships no `tests/perf.lua`, which the release notes state out loud. ``
- `docs/automated-tests/RESULTS.md:84` → `| > 1500 (over cap) | \`GlobalStrings/GlobalStrings.lua\` | 23842 | **Accepted — not shipped and not loaded.** No TOC line references it and \`.pkgmeta:24\` excludes the whole \`GlobalStrings\` directory; …`
- `.pkgmeta:24` actually reads `  # no .superpowers line, because no such directory exists at this root.` — the `- GlobalStrings` line is `:39`.

## E13. Re-vendor bundles (PC-82)

Commands verbatim from `AUDIT.md` step 4, run under `bash`:

```
horizon=2026-08-25
vendored: v1.18.0 v1.18.1 v1.19.0 v1.23.0 v1.24.0 v1.25.0 v1.26.0 v1.27.0 v1.28.0 v1.29.0 v1.31.0 v1.32.0 v1.33.0 v1.34.0 v1.35.0 v1.36.0 v1.36.1 v1.36.2 v1.37.0 v1.38.0 v1.39.0 v1.42.0 v1.44.0 v1.45.0 v1.46.1 v1.47.0 v1.50.0 v1.51.0 v1.52.0 v1.53.0 v1.55.0
recorded: v1.15.0 v1.30.0 v1.31.0 v1.32.0 v1.33.0 v1.34.0 v1.55.0
UNRECORDED: v1.18.0 v1.18.1 v1.19.0 v1.23.0 v1.24.0 v1.25.0 v1.26.0 v1.27.0 v1.28.0 v1.29.0 v1.35.0 v1.36.0 v1.36.1 v1.36.2 v1.37.0 v1.38.0 v1.39.0 v1.42.0 v1.44.0 v1.45.0 v1.46.1 v1.47.0 v1.50.0 v1.51.0 v1.52.0 v1.53.0
count: 26
$ git log --since=2026-08-25 --format=%H -- libs/LibKa0s | wc -l
32
```

Bare-dated bundles resolved from their first line: `docs/revendor/2026-08-25/01_DELTA.md:1` →
`# 01 — Delta: PrettyChat vs LibKa0s v1.15.0`; `docs/revendor/2026-09-12/01_DELTA.md:1` →
`# 01 — Delta: PrettyChat vs LibKa0s v1.30.0`. `docs/revendor/2026-09-23-v1.55.0/01_DELTA.md:1` →
`# 01 — Delta: LibKa0s v1.54.2 → v1.55.0` (the previous vendored tag was v1.53.0 — commit
`5e6ff6c 2026-09-22 Re-vendor LibKa0s v1.53.0`). No register row covers the gap.

## E14. Register and issue store (audit-review-history)

```
$ gh issue list --state all --limit 200 --json number,title,state,labels,url   # exit 0, 18 issues
1  OPEN   state:triaged severity:low   Update default format strings
…
7  CLOSED state:will-not-do severity:low  Add `## X-Wago-ID` to PrettyChat.toc
10 CLOSED state:will-not-do severity:low  LIBKA0S-12: Perf declined on two independent structural grounds
14 CLOSED state:will-not-do severity:low  Withdraw the ratified performance-§12 exemption: declined — …
16 CLOSED state:will-not-do severity:low  LibKa0s-Compat-1.0: no version-variant API or secret value passes through this addon
17 CLOSED state:will-not-do severity:low  LibKa0s-Bus-1.0: this addon publishes and receives no message
18 OPEN   state:triaged severity:medium Move Schema.ResetRows onto the schema runtime's BulkRun and BulkAdd
```

(Full list: #1–#6 and #18 `state:triaged`; #7, #8, #10–#14, #16, #17 `state:will-not-do`; #9, #15
`state:done`.) `gh api graphql` not used. No `docs/pending/`.

Register rows quoted (`docs/ARCHITECTURE.md`):

- `:271` → `| \`toc-file-§1\` | \`## Title:\` keeps its rainbow … and \`## X-Wago-ID\` is absent | … \`toc-file-§1\` asks for both distribution ids once an addon is published anywhere; … | 2026-07-12 | The addon being listed on Wago (which re-arms \`X-Wago-ID\` immediately), or a decision to retire the brand mark |` (PC-73). Rule: `toc-file.md:30` → `… \`X-Wago-ID\` and \`X-WoWI-ID\` are **optional** (**MAY**) …`.
- `:272` → `| \`debug-logging-§2\` | … **no LibSharedMedia registration happens in this install** | The reason changed with the adoption of \`LibKa0s-Media-1.0\`. Registration is no longer omitted by choice: \`core/MediaSetup.lua\` calls \`Media.RegisterLSM(addonName)\` at load like every other addon … |` (PC-88). Rule: `debug-logging.md:30` → `… Expose the resolved path as a constant (e.g. \`NS.Constants.FONT_MONO\`) and let \`Media.RegisterLSM\` do the LibSharedMedia registration. …`; `core/MediaSetup.lua:99` → `if Media then Media.RegisterLSM(addonName) end`.
- `:276` → `| \`localization-§1\` | **PrettyChat ships English only.** … (LIBKA0S-05, "The \`L\` trap"). …` (PC-89).

Id resolution:

```
LIBKA0S-01: docs/audits/2026-08-04/03_EVIDENCE.md …          ✓
LIBKA0S-05:                                                  ✗ (no bundle; no issue title)
LIBKA0S-06: docs/audits/2026-08-04/03_EVIDENCE.md …          ✓
PC-49:      docs/audits/2026-08-04/…                          ✓
PC-R-05 / PC-R-06: docs/reviews/2026-08-05/01_FINDINGS.md F-005/F-006   ✓ (4 hits)
```

Triggers: `libs/LibKa0s/OptionsWidgets.lua:66` → `local HALF = 0.5`; `:1611` → `  function O.RenderGrid(ctx, items)`
(no third ratio — `options-ui-§6` row not fired). `tests/_kit/loader.lua:22` →
`    __newindex = function(_, k, v) _G[k] = v end,` (no isolated mode — `testing-§1` row not fired).
`ls locales/` → `enUS.lua` only (`localization-§1` not fired).

## E15. Documentation shape (documentation-§3) and drift (PC-86)

```
$ git ls-files docs | grep -vE '^docs/(audits|reviews|revendor|superpowers)/|^docs/automated-tests/2'
docs/ARCHITECTURE.md  docs/automated-tests/README.md  docs/automated-tests/RESULTS.md  docs/common-tasks.md
docs/data-flow.md  docs/global-strings.md  docs/module-map.md  docs/performance.md  docs/schema.md
docs/scope.md  docs/settings-panel.md  docs/slash-dispatch.md  docs/smoke-tests.md  docs/test-cases.md
docs/testing.md
```

Each appears in exactly one table of `## Documentation map` (`docs/ARCHITECTURE.md:210-248`); no
row names a missing file. Tier 2 counts: `NS.COMMANDS` entries = 12 (`settings/Slash.lua:45-74`);
`grep -cE '^\s*function\s+[A-Za-z_][A-Za-z0-9_]*\.' core/Compat.lua` → file absent (0); messages 0.
Hub sizes (awk over `##` headings): Module Map 44, Settings Schema 20, Slash Commands 4, Message Bus 8,
Documented deviations 119, whole file 387 lines.

Drift, re-read today:

1. `docs/ARCHITECTURE.md:71` → `… the \`General\` page (a \`TextRow\` then \`H.RenderTabbedSchema\` over its one composed \`Master controls\` tab, whose \`afterGroup\` draws the host \`Test\` button and then the composer's own closing button), …`; `docs/module-map.md:240` → `… \`buildGeneralBody\` draws the virtual \`General\` page through the library — one explainer \`TextRow\`, then \`H.RenderTabbedSchema\` …, whose \`afterGroup\` hook draws the host \`Test\` button and then …`; `docs/settings-panel.md:61` → `… It is built by \`buildGeneralBody(ctx)\`, which draws one explainer line and then hands the page to \`H.RenderTabbedSchema\`. …`; `docs/smoke-tests.md:898` → `The explainer line sits above them. …`. Code: `settings/Panel.lua:120-129` (ClearScroll, EnsureScroll, `H.RenderTabbedSchema(ctx, "General", { [H.MASTER_GROUP] = generalAfterGroup }, nil)` — no `TextRow`); `settings/Panel.lua:116-118` → `local function generalAfterGroup(ctx)` / `    Schema.masterAfterGroup(ctx)` / `end`; `locales/enUS.lua:37-38` → `    -- confirmation's wording. The page's own explainer was removed at the owner's` / `    -- request -- the tab opened on a paragraph rather than on its controls.`
2. `docs/ARCHITECTURE.md:33` → `… core/Database → core/PrettyChat → core/CoreSetup → core/DebugLogSetup → core/LauncherSetup → defaults/Profile …` (no `core/LifecycleSetup`; `PrettyChat.toc:61` → `core\LifecycleSetup.lua`).
3. `docs/ARCHITECTURE.md:147` → `… **The gate is the library's** (\`LibKa0s-Slash-1.0\` minor 13): …`; `settings/Slash.lua:243` → `    -- THE GATE'S TWO FIELDS (Slash minor 12, live set restored at 13).` — vendored minor is 14 (E3).
4. `core/Constants.lua:24` → `-- keeps adjacent strings from butting against each other. Specific to the`; `:25` → `-- bespoke 40/60 editor in settings/Panel.lua; the library has no equivalent.`
5. `settings/Slash.lua:407` → `-- disabled gate above, which is the second reader of \`IsAddonEnabled\` beside`; `:408` → `-- modules/Override.lua's ApplyStrings); …` vs `modules/Override.lua:278` → `    local addonEnabled = (not self:IsStoodDown()) and self:IsVisible()`.
6. `docs/scope.md:45` → `- Engineer context: [ARCHITECTURE.md](./ARCHITECTURE.md) — design overview, module map, namespace publishing table, invariants, working environment, doc index. …`
7. `.pkgmeta:21`, `:25` (E5).
8. `docs/ARCHITECTURE.md:193` → ``generated directories are named once each and never enumerated per run: `docs/audits/`, `docs/reviews/`, `docs/automated-tests/`, `docs/revendor/`, `docs/superpowers/`.``; rule `documentation.md:332` → `` `docs/audits/`, `docs/reviews/`, `docs/automated-tests/<run>/`, `docs/perf-analysis/<run>/`, … ``.

Retired notation sweep (documentation-§6):

```
$ grep -rEn '§[0-9]+\.[0-9]' . --exclude-dir=libs --exclude-dir=_kit --exclude-dir=audits \
    --exclude-dir=reviews --exclude-dir=automated-tests --exclude-dir=revendor | wc -l
0
```

Range check of every `filename-§N` in the tracked authored set (frozen stores excluded; 72 distinct
citations): one unresolvable — `tiered-layout-§1` at
`docs/superpowers/specs/2026-07-14-tier2-debug-console-slash-conformance-design.md:12`, inside the
frozen `docs/superpowers/` store (out of scope; not filed).

## E16. Remaining MUST evidence

- **PC-93 (compat):** `ls core/Compat.lua` → no such file. `core/EnvSetup.lua:75` → `    if GetAddOnMetadata then`; `:76` → `        return GetAddOnMetadata(addonName, field)`. Rule `compat.md:5` → `Every addon **MUST** ship a \`core/Compat.lua\`. It is the **only** file that calls deprecated APIs …`. Inconsistency: `library-stack.md:88` → `… The nine \`core/Compat.lua\` copies in the collection hold **2820** lines (\`wc -l\` over the nine; AbsorbTracker and PrettyChat carry none) …`.
- **PC-94 (savedvariables-§2):** `core/Database.lua:34` → `Database.defaults = {`, `:37` → `        minimap = { hide = false },`; `settings/Schema.lua:119` → `        enabled    = true,`, `:120` → `        visibility = "always",`; `modules/Override.lua:38` → `    if self.db.profile.enabled == nil then return true end`; `:72` → `    return self.db.profile.visibility or "always"`; `settings/Schema.lua:212` → `            PrettyChat.db.profile.visibility = (v ~= "always") and v or nil`. Rule `savedvariables.md:34` → `- **MUST** be the **only** place a default value is hardcoded. …`.
- **PC-95 (architecture-§3):** `settings/Schema.lua:5` → `local Schema = {}`; `:6` → `NS.Schema = Schema`; contrast `core/Database.lua:9` → `NS.Database = NS.Database or {}`.
- **PC-97 (documentation-§7):** `DEPENDENCIES.md:157` → `### Image tooling — none, and none is claimed`; `:160` → `is **no committed script, Makefile target or documented command that regenerates any of them**, so`; `core/LauncherSetup.lua:96` → `-- be the same file in all three (launcher-§4). 128x128, uncompressed 32-bit TGA,`; `:97` → `-- generated from the 2000x2000 .png beside it by layout-§4's recipe.`; rule recipe `layout.md:133` → `Image.open(src).convert("RGBA").resize((128, 128), Image.LANCZOS).save(out, format="TGA")`.
- **PC-98 (documentation-§1):** `README.md:74` → `| 1.5.0 | 2026-09-10 | - … <br>- The write seam now refuses a format string the game cannot serve, instead of failing at print time<br>- Fixed three places that read a \`nil\` result as silence rather than as an answer<br>- Updated for game patch 12.1.0 |`.
- **PC-99 (documentation-§9):** first comment line per source file (script in the run log) — `NO` for `core/Constants.lua` (`-- The panel layout constants that used to live here …`), `core/Database.lua` (`-- NS.Database — …`), `core/Namespace.lua` (`-- Shared namespace bootstrap. …`), `core/PrettyChat.lua` (`-- Core AceAddon object + lifecycle. …`), `core/State.lua` (`-- Session-only runtime state. …`), `core/Util.lua` (`-- NS.Util — …`), `defaults/Defaults.lua` (no leading comment), `defaults/Profile.lua` (`-- NS.ProfileDefaults — …`), `locales/enUS.lua` (`-- NS.L — …`), `modules/Override.lua` (`-- The override pipeline — …`), `settings/Schema.lua` (`-- Display order shared with settings/Panel.lua. …`); `yes` for the other nine.
- **PC-100 (Info):** `.luacheckrc:37` → `-- into. The other eleven had it because the line was copied, and they now open \`local _, NS = ...\`.`
- **PC-101 (Info):** `docs/performance.md:3-4` → `… This page is the one-screen answer \`documentation-§3\` still requires: …`; `wc -l docs/performance.md` → 230.

## E17. US English (localization-§5)

Independent scan with the canonical `BRITISH` and `ALLOWED` lists copied whole from `localization.md`
(`ALLOWED` removed as whole words first), over `git ls-files` minus `libs/`, `tests/_kit/`,
`docs/audits/`, `docs/reviews/`, `docs/revendor/`, `docs/automated-tests/<run>/`, `GlobalStrings/`
and `media/`:

```
hits 16 files 1
tests/prose_waivers.lua:24: cancelled / travelling / grey / amongst   (the waiver file naming the words it waives)
```

The waiver file is the gate's own configuration quoting the spellings it waives — excluded by
`localization-§5`'s fourth exclusion. PC-75 closed.
