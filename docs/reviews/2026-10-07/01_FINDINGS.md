# PrettyChat review — 2026-10-07 — 01 Findings

**Verdict: minor issues.** Nothing blocks this addon. One High is a cross-addon defect whose fix lands in LootHistory, not here.

**Resolved scope:** `all`, the whole PrettyChat repository at `8626790` on `feat/2026-10-07-review-audit-remediation` (clean tree). Profile `wow`, kind `addon`. Vendored `libs/` and `tests/_kit/` are reviewed only as `[upstream]`.

**Standards cross-check:** Ka0s WoW Addon Standard **v2.76.1 (2026-10-07)**, fetched with `curl` from `raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master`. Every fix direction below was checked against it.

## Measurement run

Everything below was measured today. Each command ran from the repo root through `/home/tushar/.claude/dev-copilot/bin/ka0s-bounded` and wrote its output to a scratch path outside the repo. The repo was left unchanged.

| Suite | Result | Command |
|---|---|---|
| luacheck | **pass**: 0 warnings / 0 errors in 56 files | `ka0s-bounded luacheck .` |
| Headless suite | **pass**: 572 passed, 0 failed, 1 skipped, 573 total | `ka0s-bounded lua5.1 tests/run.lua` |
| Fresh `--list` inventory | **matches** the committed `docs/test-cases.md` byte for byte (after stripping CR) | `ka0s-bounded lua5.1 tests/run.lua --list` → scratch, then `diff` |
| Offline perf runner | **not applicable**: there is no `tests/perf.lua`, by the ratified `performance-§12` exemption (`docs/ARCHITECTURE.md` register) | — |
| Complexity (sighted, kit revision 37) | **pass**: 0 warnings, 1314 functions, 57375 NLOC, avg CCN 2.1, **max CCN 15**, no blind files reported | `ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle` |
| `make test` | **not applicable**: there is no root `Makefile` | — |
| Vendor sync | **pass**: `diff -rq libs/LibKa0s ../LibKa0s/LibKa0s` and `diff -rq tests/_kit ../LibKa0s/testkit` both print nothing. The LibKa0s checkout's payload equals tag `v1.70.0` (`git -C LibKa0s diff --stat v1.70.0 -- LibKa0s testkit` is empty) | as shown |
| Cross-addon class 1 (slash tokens) | **clean**: 22 roots across the 11 addons, `uniq -d` prints nothing, and no raw `SLASH_*` appears in any loaded source. PrettyChat holds `pc` and `prettychat` | TOC-derived loop from the review overlay, run from `GIT/` |
| Cross-addon class 2 (vendored minors) | **clean**: one line, `Bus:2 Compat:1 Core:10 DebugLog:19 Env:1 Item:2 Launcher:5 Lifecycle:3 Media:4 Options:28 Perf:14 Pool:3 Schema:2 Slash:19 Widgets:12` | as in the overlay |
| Cross-addon class 3 (payload bytes) | **clean**: `diff -rq AbsorbTracker/libs/LibKa0s <each>/libs/LibKa0s` prints nothing for all 11 (159 files; reference addon AbsorbTracker) | as in the overlay |
| Cross-addon class 4 (`## Interface:`) | **clean**: a single value, `120100` | as in the overlay |

These committed artifacts disagree with today's run:

- `docs/automated-tests/RESULTS.md`: its newest row is `20260927-031723`, measured at `a663bc6`. The runner reports that row as "49 commit(s) behind HEAD". Fresh vs recorded: functions **1314** vs 1135, NLOC **57375** vs 56489, max CCN **15** vs 14, tests **572/1/573** vs 518/0/518. The record is stale but not non-compliant: it is regenerated at release, not by this review. The new max-CCN function is F-009.
- The cross-addon baseline in the review brief is recorded at LibKa0s v1.56.0. The tag has moved to `v1.70.0`, so the class 2 and 3 figures differ from the brief. That is the brief being out of date, not drift. All 11 consumers agree with each other.
- `docs/test-cases.md` vs the README badge: **573** vs **572/572**. The badge is right under `testing-§5` and the generated inventory is not. See F-007.

## Census scopes used

- **Default (authored Lua):** `git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'`. Files over 1000 lines: `GlobalStrings/GlobalStrings.lua` (23842, exempt as generated data under `layout-§1`) and `settings/Schema.lua` (**1094**, in the 1000–1500 on-notice band).
- **TOC load list (runtime):** `tr -d '\r' < PrettyChat.toc | grep -iE '\.lua$' | grep -v '^#' | sed 's|\\|/|g' | grep -v '^libs/'`. Over those files, `awk` counts **6292 lines: 2915 comment, 438 blank, 2939 code** (see F-006).

---

## High

### F-001 `[cross-addon]` `[correctness]`: LootHistory's cached loot and currency patterns go stale whenever PrettyChat rewrites the globals mid-session

- **Repos:** PrettyChat (the writer) and LootHistory (the reader).
- **Where:**
  - `PrettyChat/modules/Override.lua:350`: `_G[globalName] = self:GetStringValue(category, globalName)`
  - `PrettyChat/modules/Override.lua:360`: `_G[globalName] = self.originalStrings[globalName]`
  - `LootHistory/core/Util.lua:152`: `local pats = lootPatterns or Util.BuildLootPatterns()`
  - `LootHistory/core/Util.lua:215`: `local pats = currencyPatterns or Util.BuildCurrencyPatterns()`
- **Problem:** LootHistory builds its self-loot and self-currency match patterns from `LOOT_ITEM_SELF*`, `LOOT_ITEM_CREATED_SELF*`, `LOOT_ITEM_REFUND*` and `CURRENCY_GAINED*` on the first parse, then keeps them for the session. Nothing ever invalidates them: `lootPatterns` and `currencyPatterns` are assigned only inside their builders. PrettyChat rewrites exactly those globals on every settings write, every profile change, every stand-down or stand-up, and, under `General.visibility` `inCombat` or `outOfCombat`, at every combat boundary (`Override.lua:140-145`).
- **Impact:** After any of those events, LootHistory silently stops recognizing the player's own loot and currency lines until `/reload`. Records are lost and nothing reports an error.
- **Reachability:** Any player running LootHistory and PrettyChat together who, after the session's first loot line, edits or toggles a Loot, Currency or Tradeskill string, runs `/pc disable`/`/pc enable` (or the launcher's Enabled entry), switches profile, or has stored `General.visibility = inCombat|outOfCombat`. That last case fires on every combat boundary. Load order does not matter, because LootHistory compiles lazily on its first `CHAT_MSG_LOOT`, which is after PrettyChat's `OnEnable`.
- **Evidence:** PrettyChat already knows about this. `docs/ARCHITECTURE.md:202` and `docs/scope.md:12` describe it as "handoff H-1, the fix is LootHistory's". But no LootHistory issue tracks it: `gh issue list -R tusharsaxena/LootHistory --state all --search "PrettyChat"` and `--search "H-1"` return no matching issue. LootHistory's code at today's HEAD (`b9c1271`) has no invalidation. A handoff with no tracker in the receiving repo is not handed off. PrettyChat's in-client check is OVR-9 (`docs/smoke-tests.md`). No headless suite can see this, because each repo tests alone.
- **Fix direction:** in LootHistory. Rebuild a pattern set when any source global's current value differs from the value it was compiled from: keep the source strings beside the patterns and compare them on parse, or rebuild on a miss. PrettyChat adds no bus message for this; that is a documented decision (`ARCHITECTURE.md:202`) and stays consistent with `architecture-§4`.

## Medium

### F-002 `[ux]` `[correctness]`: the settings panel stores an empty format string, which the CLI refuses

- **Where:**
  - `settings/Panel.lua:274-277`: `NS.Schema.Set(formatPath, ((value or ""):gsub("||", "|")))`
  - `settings/Schema.lua:343-346`: `if row.kind ~= "string_format" or type(value) ~= "string" then return false end … if NS.SequenceIsPrefix(asked, supplied) then return false end`
- **Problem:** If a player clears a **New** box and presses Enter, `Schema.Set(path, "")` runs. The conversion-signature gate accepts `""` because an empty sequence is a prefix of every sequence. The value differs from the default, so it is stored, and `ApplyStrings` writes `""` into the Blizzard global. `/pc set <path>` with a blank value is refused by the library parser instead ("expected a value"; see the comment at `settings/Slash.lua:270-272` and `tests/test_slash.lua:270`).
- **Impact:** That message type renders as an empty chat line, or not at all, until the player resets it. The two write surfaces disagree about whether the value is legal. The Preview shows `(empty format)` but does not refuse it.
- **Reachability:** Any player who empties a New box on the Categories page and presses Enter. That is an ordinary panel interaction.
- **Coverage:** No case drives the panel path with `""`. `tests/test_render.lua:25` covers only the render of an empty format.
- **Fix direction:** refuse a blank or whitespace-only format at the row's `validate`, so every surface goes through the same single-write-path gate (`architecture-§5`).

### F-003 `[ux]`: the Categories page's Defaults button discards every category's custom formats without asking

- **Where:** `settings/Panel.lua:756-758`: `ctx.panel.defaultsOnClick = function() PrettyChat:ResetCategoriesPage() end`. Compare `settings/Panel.lua:732`, where the General page's button goes through `ConfirmResetAll`.
- **Problem:** One click resets all eight tabs (`options-ui-§13`), which can be dozens of hand-written format strings. There is no confirmation and no undo. The General page's equivalent asks first.
- **Impact:** A misclick throws away customization that cannot be recovered.
- **Reachability:** Any player who clicks the header Defaults button on the Categories page.
- **Note:** `options-ui-§12` mandates confirmation only for the global reset, so this is not a standards deviation. It is a UX and data-safety call. The README documents the behavior (`README.md:63`).

### F-004 `[savedvars]`: downgrading the addon deletes overrides that a newer build stored

- **Where:**
  - `core/Database.lua:198-201`: when the stored stamp is ahead of `SCHEMA_VERSION`, it is normalized down to it (`db.global.schemaVersion = Database.SCHEMA_VERSION`).
  - `core/Database.lua:106-107`: `if not Schema.FindByPath(path) then sub[globalName] = nil`
- **Problem:** `PruneOrphans` runs on every load and drops any stored `strings[G]` or `disabledStrings[G]` that the running build has no schema row for. An older build has no rows for the strings a newer build added, so it deletes them. It also rewrites the stamp downward.
- **Impact:** A player who rolls back a release loses those custom formats permanently, including after they upgrade again.
- **Reachability:** Only a player who installs an older PrettyChat over a newer one, for example a CurseForge rollback. That is a narrow path, so this is capped below High.

### F-005 `[taint]` `[docs]`: `docs/data-flow.md` says "`_G` writes don't taint", which is not WoW's taint model

- **Where:** `docs/data-flow.md:141`: "`ApplyStrings` is unprotected; `_G` writes don't taint."
- **Problem:** A write to a global from addon code taints that variable: `issecurevariable("LOOT_ITEM_SELF")` answers `false, "PrettyChat"`. What actually holds is narrower. The overridden globals are read by non-protected chat formatting, so the taint has nowhere protected to propagate. Nobody has checked that against Midnight (12.x) chat handling.
- **Impact:** A false premise in the document that future taint reasoning starts from. The runtime consequence is **unverified**, because it needs the client.
- **Reachability:** Document text; no runtime effect has been demonstrated. Capped at Medium.

### F-006 `[naming]` `[comments]`: comment volume rivals code, and some of its factual claims contradict each other

- **Where:** Census over the TOC load list: 6292 lines, of which 2915 are comment and 2939 are code. Per file: `settings/Schema.lua` 463 of 1094 lines are comment, `settings/Panel.lua` 410 of 766, `modules/Override.lua` 384 of 788, `core/PrettyChat.lua` 162 of 268.
- **Concrete stale or contradictory claims:**
  - Test report length:
    - `settings/Panel.lua:89-90` says "500+ lines with every category enabled".
    - `modules/Override.lua:752` says "A 500-line preview".
    - `settings/Panel.lua:109` says "the verb printed eighty-odd lines".
    - From the code (`Override.lua:691-735`), the real figure is 4 lines × 79 strings, plus 2 × 8 category headers, plus a header and a footer: **334**, or 335 while disabled.
  - `settings/Schema.lua:104-105` says "nine addons drawing the same tab from nine hand-written copies". The roster in `ADDONS.md` is **eleven**.
- **Problem:** Much of the comment text narrates history ("It used to…", "until M4-21…", issue IDs) or restates standard sections. That belongs in commit messages and `docs/`. Every refactor has to keep the prose true as well, and the numbers above show it already isn't.
- **Impact:** Maintenance cost, and wrong figures that read as authoritative.
- **Reachability:** Comments; no runtime effect. Capped at Medium.

### F-007 `[upstream]` `[tests]`: the testkit's `--list` Total includes skipped cases, so the inventory disagrees with the badge

- **Owner:** LibKa0s, file `testkit/framework.lua` (vendored here as `tests/_kit/framework.lua:557-569`): `out(string.format("| **Total** | **%d** |", #tests))`. The header it writes at `:576-577` says the Totals table "is the **authoritative pass count** — the README test badge … must agree with it."
- **Problem:** `testing-§5` says a skip "MUST NOT be folded into either the passed count or the total". The renderer counts every registered case, skips included, so the generated `docs/test-cases.md` says **573** while the compliant badge says **572/572**. The generated document contradicts its own header.
- **Impact:** Every consumer with a skipped case (this one has the opt-out case in `test_diagnostics_contract.lua`) ships an inventory whose "authoritative" figure no badge may show.
- **Reachability:** The test inventory only. Capped at Medium.
- **Fix direction:** in LibKa0s's `testkit/framework.lua`. Render the skip count separately and exclude it from Total, bump the kit revision, then re-vendor the whole `tests/_kit/` into every consumer. **Not a local edit.**

### F-008 `[design]` `[upstream: WowAddonStandards]`: 758 lines of degradation stubs serve an install the packager cannot produce

- **Where:** stub arms, measured with the CR-stripped `awk` range shown in `02`:
  - `core/CoreSetup.lua:43-132`
  - `core/DebugLogSetup.lua:71-175`
  - `core/LifecycleSetup.lua:74-121`
  - `settings/OptionsSetup.lua:19-247`
  - `settings/Slash.lua:175-259`
  - `settings/Schema.lua:601-801`

  Total: **758 lines**. `tests/test_surface_parity.lua` pins them.
- **Problem:** `.pkgmeta` sets `enable-nolib-creation: no`, and `libs/LibKa0s` is vendored whole. So the only way to reach these arms is a hand-damaged install. They are still about 12% of loaded authored lines and carry a parity-test burden, and the Schema stub re-implements the runtime's `Set`, `SetMany` and `BulkRun`.
- **Impact:** Maintenance weight, and a second implementation of the library that can drift from it.
- **Reachability:** Nobody on a packaged install.
- **Note:** `library-stack.md:110` mandates these stubs ("degrading to a stub when it is absent"). Removing them here would be a **new deviation**. The question belongs to the standard: should a stub be required for a library that is vendored and never stripped? **No local change.**

## Low

### F-009 `[complexity]`: `listSettings` is at the CCN 15 cap

- **Where:** `settings/Slash.lua:363-422` (`function listSettings(rest)`). Fresh sighted run: CCN **15**. The committed watch list peaks at 14.
- **Impact:** One more branch and it warns.
- **Reachability:** Maintainers only.

### F-010 `[docs]`: `ARCHITECTURE.md:202` cites stale LootHistory line numbers

- **Where:** It cites `LootHistory/core/Util.lua:118/147/187/210`. The functions are now at `:124` (`function Util.BuildLootPatterns()`), `:152` (lazy use), `:193` (`function Util.BuildCurrencyPatterns()`) and `:215` (lazy use).
- **Reachability:** Document text.

### F-011 `[ux]`: `/pc test category General` resolves, then prints "(no matching strings)"

- **Where:**
  - `settings/Slash.lua:593`: `local matched = NS.Schema.ResolveCategory(value)`. `General` is in `CATEGORY_ORDER` but has no strings.
  - `settings/Slash.lua:588-589`: the usage line's "Valid:" list includes `General`.
- **Reachability:** Any player who types it. Harmless.

### F-012 `[frames]`: the combat watcher is a named global frame

- **Where:** `modules/Override.lua:199`: `combatWatcher = CreateFrame("Frame", "PrettyChatCombatWatcher")`
- **Problem:** It writes `_G.PrettyChatCombatWatcher` for a frame nothing looks up by name. The name is cited in the docs and is handy in `/etrace`.
- **Reachability:** Only players who store a combat-scoped visibility.

### F-013 `[design]`: the version literal is duplicated outside the TOC

- **Where:** `core/Namespace.lua:8`: `NS.version = NS.Meta("Version") or "1.6.0"`. The test mock repeats it at `tests/wow_mock.lua:104`.
- **Problem:** No test pins the literal to the TOC's `## Version`, and no bump tooling found in `dev-copilot` edits it.
- **Reachability:** Only when `NS.Meta` returns nil, which means no `C_AddOns` and no Env. Effectively nobody.

---

## Measured non-findings

These were checked and are clean:

- Disabled-state tests are falsifiable. `tests/test_disabled.lua:160-190` asserts a baseline of 2 registrations, then 0, against the kit's recording mock.
- The runner derives its load list from the TOC (`tests/test_harness.lua`).
- No `SecureHook` and no protected calls.
- The single write path is honored: every panel and CLI write goes through `NS.Schema.Set`.
- `.gitattributes` pins CRLF: `git ls-files --eol` shows 446 `i/lf w/crlf`, 127 binary and 2 LF (the `*.sh`/`*.py` carve-outs).

## Upstream and cross-repo findings at a glance

- F-001 → **LootHistory** (`core/Util.lua`). It has no tracker today.
- F-007 → **LibKa0s** (`testkit/framework.lua`), then a re-vendor.
- F-008 → **WowAddonStandards** (`library-stack`). A standards question, not a code change.
