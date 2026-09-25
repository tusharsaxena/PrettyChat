# 01 — Findings (PrettyChat, full-scope review, 2026-09-23)

**Verdict: minor issues.** Nothing blocks a release. One cross-addon defect (F-001, with LootHistory) is
High because an ordinary same-session setup reaches it. Everything else is Medium or below.

Reviewed at branch `feat/2026-09-23-review-audit-remediation`, addon version 1.5.0, LibKa0s v1.55.0
vendored. Standard cross-check: **Ka0s WoW Addon Standard v2.64.0 (2026-09-23)**. The index and all of
its linked section files were fetched verbatim with `curl`.

---

## Measurement run (Step 0: what was measured today)

`ka0s-bounded` was not on `PATH` in this shell. It was present at `~/.claude/wow-addon/bin/ka0s-bounded`,
so every run below went through it at that path. The `timeout 900` fallback was not needed. No run
exited 124 or 137.

| Suite | Result | Command (repo root unless noted) |
|---|---|---|
| luacheck | **pass**: 0 warnings / 0 errors in 48 files | `ka0s-bounded luacheck .` |
| Headless test suite | **pass**: 438 passed, 0 failed, 0 skipped, 438 total | `ka0s-bounded lua5.1 tests/run.lua` |
| Fresh `--list` inventory | **generated** to scratch: 559 lines, Total 438 | `ka0s-bounded lua5.1 tests/run.lua --list > <scratch>/test-cases.md` |
| `tests/perf.lua` | **skipped**: the file does not exist. The `performance-§12` no-combat-path exemption is recorded in `docs/ARCHITECTURE.md:269` | n/a |
| lizard | **pass**: 0 warnings, 941 functions, NLOC 54817, avg CCN 1.9, **max CCN 14** (`Database.PruneOrphans` core/Database.lua:52-76, and the `stubSet` closure settings/Schema.lua:645-669). Band 1000–1500: `tests/test_panel.lua` (1053). Over cap: `GlobalStrings/GlobalStrings.lua` (23842, exempt generated data) | `ka0s-bounded lizard -l lua -x "./libs/*" -x "./tests/_kit/*" . > <scratch>/lizard.txt` |
| `make test` | **skipped**: there is no root `Makefile` | n/a |
| Vendor sync | **pass**: both diffs are silent. `../LibKa0s` is at `v1.55.0-3-g46ccaa6`, and the ship folder is unchanged since the tag | `diff -rq libs/LibKa0s ../LibKa0s/LibKa0s`; `diff -rq tests/_kit ../LibKa0s/testkit` |
| Cross-addon 1: slash tokens | **clean**: 20 roots across 10 addons (the nine plus AuraMaster). `uniq -d` is empty, and there are 0 raw `SLASH_*` assignments in any TOC-loaded file | the two loops in the reviewer brief, run from `../`, scope = each addon's TOC-derived load list |
| Cross-addon 2: vendored minors | **clean**: one line across all 10. `Bus:1 Compat:1 Core:7 DebugLog:12 Env:1 Item:1 Launcher:1 Lifecycle:1 Media:3 Options:23 Perf:12 Pool:3 Schema:1 Slash:14 Widgets:9` | `grep -rhoE 'local MAJOR, MINOR = …' <a>/libs/LibKa0s` |
| Cross-addon 3: payload bytes | **clean**: `diff -rq PrettyChat/libs/LibKa0s <a>/libs/LibKa0s` is silent for all 10 (reference = PrettyChat). **Improvement on the baseline:** the two PrettyChat CR stragglers the 2026-09-07 baseline recorded (`DebugLog.lua`, `Pool.lua`) are gone | as stated |
| Cross-addon 4: `## Interface:` | **clean**: `120100` in all 10. The baseline recorded `120007`. The whole collection moved together, so this is not a finding | `grep -h '^## Interface:' <a>/*.toc \| tr -d '\r' \| sort -u` |
| Headless probe (review-only) | ran. It supplies the evidence for F-002 and F-004 | `ka0s-bounded lua5.1 <scratch>/probe.lua`, which loads the addon through `tests/loader.lua` |

The cross-addon pass matches the recorded baseline in every class. I am recording it here as a measured
non-finding. F-001 is a cross-addon defect of a **different class** from the four collision classes
above: it is a behavioural coupling, and no grep census can see it.

**Committed artifacts compared with today's run**

- `docs/test-cases.md` is **identical** to the fresh `--list`. The CR-normalised `diff` is empty. The
  README `Tests` badge reads `438/438`, which matches.
- `docs/automated-tests/RESULTS.md` is **stale by date**, but that does not make it non-compliant. Its
  newest bundle `20260916-184747` (`manifest.json`: sha `093305b`, addon 1.5.0) records 385 tests,
  854 functions and NLOC 54311. Today's run gives 438, 941 and 54817. There is **no watch-list
  drift**: max CCN is 14 in both runs, and the same file sits in the band (`tests/test_panel.lua`, 1053
  in both runs). Regenerating the report belongs to the release step, not to this review.
- `docs/performance.md`: there is no runner to compare against.

---

## Sweep: conventions detected (so the checks below apply only to conventions the addon actually uses)

- **Prefixed printer:** yes. `Const.PREFIX` is at core/Constants.lua:51, and `NS.Print` is reclaimed
  from LibKa0s-Core at core/CoreSetup.lua:142. There are no raw `print(` calls in loaded source.
- **COMMANDS dispatcher:** yes. settings/Slash.lua:45-74 defines positional triples handed to
  LibKa0s-Slash-1.0. README, ARCHITECTURE and the table agree on the 12 verbs.
- **Single write path:** yes. `NS.Schema.Set` is the LibKa0s-Schema-1.0 instance member, bound at
  settings/Schema.lua:762. The batched sibling is `Schema.ResetRows`.
- **Flat-row schema:** yes, in `settings/Schema.lua`.
- **Secret-values doc:** none. The addon handles no protected-API values.
- **`.gitattributes`:** the CRLF pin, the `*.sh`/`*.py` LF carve-out and the binary list are all
  present. The working tree agrees with them (`test_eol` is green).
- **Library marks:** the addon draws no window of its own. The console and copy window belong to
  LibKa0s. The only own-art path is the per-addon logo, which is documented at core/MediaSetup.lua:60-69.
- **Adopted LibKa0s majors, with the setup file for each:**
  - Env: core/EnvSetup.lua
  - Media: core/MediaSetup.lua
  - Core: core/CoreSetup.lua
  - DebugLog: core/DebugLogSetup.lua
  - Lifecycle: core/LifecycleSetup.lua
  - Launcher: core/LauncherSetup.lua (no stub, and both call sites are guarded)
  - Schema: settings/Schema.lua:547-740
  - Options: settings/OptionsSetup.lua
  - Slash: settings/Slash.lua
- **Test kit:** `tests/_kit/` is vendored. The load list is TOC-derived (`test_harness` pins it).
- **Evidence the addon keeps about itself:** `tests/run.lua` plus 24 suites, `docs/test-cases.md`, and
  `docs/automated-tests/` (11 bundles plus `RESULTS.md`). There is no `tests/perf.lua` and no
  `docs/perf-analysis/`, both by the exemption.

**Stub check (degradation stubs compared with call sites).** I grepped loaded source for every
`NS.DebugLog`, `NS.Lifecycle`, `NS.Launcher`, `H.`/`NS.Helpers.` and `Sl:` member and diffed the list
against each stub.

- Every member that is called is answered by its stub.
- `H.MASTER_GROUP`, `H.ROW_VSPACER` and `H.SECTION_HEADING_H` are absent from the Options stub. That is
  by design: their callers sit after the `EnsureScroll` nil-guard (settings/Panel.lua:122-128,
  :603-641).
- The Launcher has no stub, and both of its call sites are guarded (core/PrettyChat.lua:238,
  settings/Schema.lua:243).

The stub checks come back clean.

---

## High

### F-001: PrettyChat changes the text of `CHAT_MSG_LOOT` / `CHAT_MSG_CURRENCY`, and LootHistory keeps matching it against patterns it compiled once `[cross-addon]` `[logic]`

- **Repositories:** PrettyChat (the side that changes the globals), LootHistory (the side that parses them).
- **Where, in PrettyChat:**
  - modules/Override.lua:292 `_G[globalName] = self:GetStringValue(category, globalName)` and :302
    `_G[globalName] = self.originalStrings[globalName]`. These run on every settings write, on every
    enable-latch transition, on every profile event, and, while the combat watcher is armed, on every
    combat boundary (:121-127, `combatWatcher:SetScript("OnEvent", function() local applied, restored = PrettyChat:ApplyStrings()`).
  - docs/ARCHITECTURE.md:151 states the premise: "the entire mechanism is overriding `_G[GLOBALNAME]`
    and letting WoW's chat code read it lazily".
- **Where, in LootHistory:**
  - core/Util.lua:118 `local lootPatterns`, built by `Util.BuildLootPatterns()` from `LOOT_ITEM_SELF*`,
    `LOOT_ITEM_PUSHED_SELF*`, `LOOT_ITEM_BONUS_ROLL_SELF*`, `LOOT_ITEM_CREATED_SELF*` and
    `LOOT_ITEM_REFUND*`.
  - It is cached at :147 `local pats = lootPatterns or Util.BuildLootPatterns()` and never rebuilt.
  - The same shape applies to currencies: :187 `local currencyPatterns` and :210
    `local pats = currencyPatterns or Util.BuildCurrencyPatterns()`, built from `CURRENCY_GAINED*` and
    `LOOT_ITEM_REFUND*`.
  - PrettyChat overrides every one of those globals (defaults/Defaults.lua, Loot and Currency).
- **Problem:** LootHistory compiles its self-loot and self-currency patterns once, from whatever the
  globals hold at the first parse, which is after PrettyChat's `OnEnable`. After that, PrettyChat keeps
  changing those same globals and therefore changes the message text the client fires. LootHistory's
  cached patterns then stop matching.
- **Impact:** LootHistory **silently records nothing** for the player's own loot and currency in
  whichever state the patterns were not built for. No error is raised, and the chat line still shows.
  The player's loot history develops holes.
- **Reachability:** any player running PrettyChat and LootHistory in the same session, in one of these
  situations:
  - PrettyChat's General visibility is `inCombat` or `outOfCombat`. Every combat boundary then flips the
    Loot and Currency globals between PrettyChat's formats and Blizzard's, so loot in the other state is
    lost for the rest of the session.
  - At any point after their first loot of the session, the player uses `/pc disable`, `/pc enable`,
    toggles the Loot or Currency category or one of those strings, edits one of the ~16 affected
    formats, or presses a Defaults/Reset.

  Load order does not rescue it. LootHistory loads first alphabetically, but its build is lazy and
  happens at the first `CHAT_MSG_LOOT`, which is after every addon's `OnEnable`. That is why the
  default configuration (visibility `always`, no edits) happens to work.
- **Evidence status:** the mechanism is inferred from PrettyChat's own premise. If the client did not
  build the event text from `_G`, PrettyChat would not work at all. It is **unverified in-client**, and
  step SMK-F001 in `03_SMOKE_TESTS.md` confirms it with `/etrace`. No headless suite can see this,
  because each repo loads only itself.
- **Coverage:** none in either repo, and none is possible in a single-addon suite.
- **Fix direction:** the defect lives in LootHistory's cache, so the code fix is **cross-repo**.
  LootHistory should compile against the live global and recompile whenever the source string value
  changes. PrettyChat's half is documentation (Known Limitations, `docs/scope.md`) plus the in-client
  check. Do **not** add a public API or a message bus to PrettyChat for this. `public-api` would require
  a `_G` export, and `library-stack-§1` vendors AceEvent only when it is used. Both are heavier than the
  one-line invariant LootHistory's parser needs. A chat filter is also rejected: `events-frames-taint-§5`
  prefers the global-override mechanism this addon already uses.

---

## Medium

### F-002: The Loot tab's copies of `LOOT_ITEM_CREATED_SELF` and `_MULTIPLE` are dead settings: edits are accepted and never applied `[ux]` `[design]`

- **Where:**
  - Both globals are registered twice: defaults/Defaults.lua:39 and :43 (Loot), and :329 and :333
    (Tradeskill).
  - `ApplyStrings` walks `CATEGORY_ORDER`, and `"Tradeskill"` comes after `"Loot"`
    (settings/Schema.lua:15-19). So Tradeskill's pass always runs last and overwrites
    (modules/Override.lua:280-305).
  - The warning tooltip is settings/Panel.lua:243, keyed as locales/enUS.lua:58.
- **Problem:** Loot's registration never decides what `_G` holds, whatever state it is in. The headless
  probe shows this:
  - `Schema.Set("Loot.LOOT_ITEM_CREATED_SELF.format", "LOOTEDIT %s")` returns `true` and is stored, but
    live `_G` stays Tradeskill's format (`|cffff00ffTradeskill|cffffffff | …`).
  - After `Schema.Set("Tradeskill.LOOT_ITEM_CREATED_SELF.enabled", false)`, live `_G` becomes
    **Blizzard's original** (`ORIG:LOOT_ITEM_CREATED_SELF`), even though the Loot copy is enabled and
    customized.
  - The tooltip says the last category wins "on /reload". In fact it wins on every pass.
  - `/pc test` prints both copies, and Loot's "Formatted" line shows a format that is never live.
  - `ApplyStrings`' `applied` count includes both registrations.
- **Impact:** a player who edits "Item Created (Self)" on the Loot tab sees it saved, sees a correct
  Preview, and never sees it in chat. Disabling the Tradeskill copy looks like it should be harmless,
  but it switches the message off entirely. Two rows, two panel entries, two `/pc list` rows and two
  report blocks exist for no effect.
- **Reachability:** any player who edits or toggles *Item Created (Self)* or *Item Created Multiple
  (Self)* on the Loot tab. That is a normal settings-panel path. It is disclosed (ARCHITECTURE Known
  Limitations, :186, and the tooltip), which is why this is graded Medium rather than High.
- **Coverage:** four cases pin the current behaviour as intended:
  - `test_apply.lua` "cross-registered global resolves to the last CATEGORY_ORDER registrant, stably"
  - `test_panel.lua` "a cross-registered string warns about the shared Blizzard global"
  - `test_schema.lua` "a cross-registered global carries one format row per category"
  - `test_defaults.lua` "cross-registered globals are identified with their real categories"
- **Fix direction:** give each global exactly one registration. Keep the Tradeskill one, because it is
  what the game already shows. Move any stored Loot-copy value across in a migration. This also removes
  the need for `events-frames-taint-§5`'s ordering guarantee to do any work here. It depends on F-003.

### F-003: The migration runner cannot migrate any profile except the one active when the global stamp moves, and it stamps past a step that raised `[savedvariables]` `[design]`

- **Where:**
  - core/Database.lua:100 `local from = db.global.schemaVersion or 0`
  - :102 `db.global.schemaVersion = Database.SCHEMA_VERSION`, which is unconditional after
    `runSteps`
  - :85-90: a failed step is printed and counted as `ran`
  - core/PrettyChat.lua:54-56 claims the opposite of what the code can do: "the migrations run first,
    because a copied profile may have been authored at an older schema version"
- **Problem:**
  - Every stored shape this addon owns lives in `db.profile`, but the version stamp is global
    (`savedvariables` MUSTs it there). The first login after a bump migrates the active profile and
    stamps `global`. Every later `OnProfileChanged`, `OnProfileCopied` or `OnProfileReset` then sees
    `from == SCHEMA_VERSION` and runs nothing, so the other profiles keep the old shape.
  - A step that raises is also stamped as done, so it is never retried.
- **Impact:** today, none. `migrations` is empty (core/Database.lua:42). The first migration anyone
  writes (F-002 proposes it) inherits both defects.
- **Reachability:** nobody in any shipping configuration today. This is capped at Medium. It is filed
  because the remediation in this bundle writes the first migration.
- **Fix direction:**
  - Keep `schemaVersion` in `global`, as `savedvariables` requires.
  - Write profile-scoped steps as **idempotent and shape-detecting**, and run them on every load-pass
    entry regardless of the global stamp. The stamp should gate only global-scope steps.
  - Stamp only after every step returned without raising.

---

## Low

### F-004: `NS.OriginalFormat` reports PrettyChat's own override as "Blizzard's original" for a global the client does not define `[logic]`

- **Where:** modules/Override.lua:589-592:

  ```lua
  return (addon and addon.originalStrings and addon.originalStrings[globalName]) or _G[globalName]
  ```

- **Problem:** when the snapshot recorded the key but the client's value was `nil` (see PC-R-07), the
  `or` falls through to live `_G`. After `ApplyStrings` has run, live `_G` holds the override. The probe
  returned `|cffff0000Loot|cffffffff | … + %s…` for `LOOT_ITEM_SELF` with its original set to nil.
- **Impact:** both the panel's read-only Original box and `/pc test`'s Original line show PrettyChat's
  own text as Blizzard's. On the panel, that is the box the docs tell players to copy the signature
  from (docs/common-tasks.md:51).
- **Reachability:** only on a client where a GLOBALNAME in `NS.Defaults` has been removed or renamed by
  Blizzard. This happens after a patch, and the test suite already treats it as ordinary (PC-R-07).

### F-005: On a degraded install, `/pc test` and the Test button print nothing, while the comments and docs claim they fall back to chat `[logic]` `[docs]`

- **Where:**
  - settings/Panel.lua:101-104: `TestToConsole` always passes the `NS.DebugLog:Add` sink.
  - core/DebugLogSetup.lua:71: the stub's `Add = function() end,`.
  - modules/Override.lua:663-668 says a caller with no console "gets chat rather than nothing". No
    caller passes a nil sink, so the `NS.Print` default is unreachable.
  - docs/settings-panel.md:231 and docs/module-map.md:236 repeat the claim.
- **Impact:** with LibKa0s absent, the first `/pc test` prints one "console unavailable" line. Every run
  after that prints nothing at all.
- **Reachability:** only an install whose `libs/LibKa0s` is missing or partial.

### F-006: Stale user-facing text and comments about where `/pc test` writes and what `resetall` resets `[ux]` `[naming]`

- **User-facing text:**
  - settings/Schema.lua:162, the Test button tooltip: "…`/pc test` prints the same report to chat." It
    goes to the debug console (settings/Slash.lua:62, README.md:27).
  - settings/Slash.lua:60, the `resetall` help row: "Reset every category to addon defaults". It is a
    profile reset that also resets `General.enabled` and `General.visibility` (modules/Override.lua:396-411).
    The standard's own example reads "Reset every setting to defaults" (`slash-commands`, line 61 of the
    section file).
- **Comments:**
  - settings/Panel.lua:86-88: "`/pc test` is unchanged and still prints to chat". This contradicts
    :95-100 in the same block.
  - settings/Panel.lua:551-552: "one SECONDARY tab per format string". It has been a TreeGroup list
    since the `options-ui-§13` deviation.
  - settings/Schema.lua:450-451: "pairs() order is non-deterministic". That has not been true since
    PC-16 (modules/Override.lua:260-267).
- **Reachability:** any player who hovers over Test or reads `/pc help`. The rest is comment text.

### F-007: The panel's New box passes `gsub`'s substitution count into `Schema.Set` as the instance id `[logic]`

- **Where:** settings/Panel.lua:281 `NS.Schema.Set(formatPath, (value or ""):gsub("||", "|"))`. The
  call is not parenthesized, so `Set(path, value, instanceId)` receives the count. The library threads
  it into `validate`, `onChange` and `announce` as `rid` (libs/LibKa0s/Schema.lua:432-478).
- **Impact:** none today. No `resolveRoot` is set and nothing reads `rid`. This is the PC-R-10 defect
  class that Util.lua:17-20 and Panel.lua:270-272 already guard against, one line away. The first
  consumer that reads `rid` would get a number.
- **Reachability:** every Enter in a New box. There is no observable effect in the shipped code.

### F-008: `.luacheckrc` declares 12 globals that no linted file uses, including a writable `UISpecialFrames` `[lint]`

- **Where:** .luacheckrc:55 (`"UISpecialFrames"`, under `globals`, so writable) and :64, :65, :67, :70,
  :71, :78, :82-86 (`date`, `wipe`, `SettingsPanel`, `GameTooltip`, `InCombatLockdown`, `UIParent`, five
  `GameFont*`).
- **Evidence:** with those 12 lines removed (`<scratch>/luacheckrc.trim`),
  `ka0s-bounded luacheck --config <scratch>/luacheckrc.trim .` still reports **0 / 0 in 48 files**. They
  are left over from code that moved into LibKa0s.
- **Impact:** a future `UISpecialFrames[#UISpecialFrames+1] = …` write, or a stray `wipe(`, would lint
  clean with nobody having decided to allow it.
- **Reachability:** developers only. There is no runtime effect.

### F-009: Each category's sorted name list is rebuilt at four sites, and `ApplyStrings` re-allocates and re-sorts it on every pass `[perf]` `[design]`

- **Where:**
  - modules/Override.lua:283-287 (`ApplyStrings`: 8 tables allocated and sorted per pass)
  - modules/Override.lua:566-575 (`collectNames`)
  - settings/Schema.lua:434-438
  - settings/Panel.lua:454-458

  `NS.Defaults` is static after load.
- **Impact:** small. There is one pass per settings write and at most two per fight in the
  combat-scoped visibility modes. The cost is **unmeasured**: there is no `tests/perf.lua`, by the
  recorded exemption. The duplication is also four places for the ordering rule (PC-16) to drift.
- **Reachability:** every player, on every settings write, and at combat boundaries when visibility is
  `inCombat` or `outOfCombat`.

---

## Upstream findings

**None.** No defect was found in `libs/LibKa0s/` or `tests/_kit/`. The two library files read for
context (`Options.lua:915-965`, `Schema.lua:432-501`) behave as the host relies on.

---

## Explicitly checked and clean

- **The disabled state:**
  - It is a real latch (`NS.Lifecycle`), not a draw gate. `SyncCombatWatch` reads the latch first and
    calls `UnregisterAllEvents` (modules/Override.lua:114-141).
  - `tests/test_disabled.lua` asserts on the mock's registration set, by name.
  - A launcher click writes no SavedVariables.
  - The full reserved-verb set answers while disabled.
- **Negative assertions:** sampled in test_override, test_debuglog and test_apply. Each one sits beside
  a positive assertion on the same act (for example `sets == 1` beside `resets == 0`). None could pass
  on a path that never ran.
- **Complexity:** nothing crossed CCN 15, and nothing moved into or out of the band since the committed
  report.
- **LOC census:** default scope, `git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'`, then `wc -l`,
  counting files over 1500 lines. The only hit is `GlobalStrings/GlobalStrings.lua` (23842). It is
  generated, unloaded data and is exempt by rule.
- **Localization:** the hard-coded `usage:` / redirect lines in settings/Slash.lua are recorded in
  `tests/test_locale.lua`'s residue register under the ratified `localization-§1` row. They are not
  re-flagged here.
- **Out of scope for this review (audit matter):** `GlobalStrings/split_globalstrings.py` sits outside
  `tools/` (`layout-§1`, v2.61.0). That belongs to `wow-addon:standards-audit`.
