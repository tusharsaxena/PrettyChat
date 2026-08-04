# CCN elimination — prettychat

Branch `feat/fix-ccn`. Design: `LibKa0s/docs/superpowers/specs/2026-08-04-ccn-elimination-design.md`.

**2 functions** with `lizard` CCN > 15. Target: every one at CCN <= 15, behavior unchanged.

## Exit criteria

1. `luacheck . --quiet` — 0 warnings, 0 errors.
2. `lua5.1 tests/run.lua` — all pass, count >= baseline.
3. `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` — no CCN > 15.
4. No behavior change. No version bump, no CHANGELOG, no merge, no tag.

## Rules

- Preferred shapes, in order: table-driven dispatch; a named file-local helper for a
  self-contained block; a data table + loop replacing repeated defaulting; splitting a
  builder into N small builders.
- No dumping a body into one helper to game the metric. Every resulting function must be a
  unit a reader can name.
- Dispatch/defaults tables are **module-level**, built once at file load — never per call.
- `lizard` counts `and`/`or` as decisions. Prefer `== nil` over `or` wherever a stored
  `false` or `0` must survive.
- Hot paths must not gain a per-call allocation.
- Sixteen functions across the collection have no coverage; where this file says
  `Coverage: NONE`, write a characterization test pinning current behavior **before**
  refactoring.

## Functions

### `PrettyChat:Test` — CCN 23 → target 7

`modules/Override.lua:219-289` · pattern `nested-report-builder` · risk **low**

**What it does.** The `/pc test` preview engine. Walks NS.Schema.CATEGORY_ORDER, filters by an optional {kind="category"|"formatstring", value=...} filter, and for each surviving format string prints three [PC]-prefixed lines (Name / Original from the OnEnable snapshot / Formatted from the configured value), then a counted footer. Lizard labels it `PrettyChat` because it is a colon method on the AceAddon object.

**Where the branches come from.** Four nested levels (category loop -> filter guard -> name-collect loop -> render loop) plus three multi-term boolean guards that each cost 3: `not filter or filter.kind ~= "category" or filter.value == category`, `not filter or filter.kind ~= "formatstring" or filter.value == globalName`, and `catData and catData.strings and next(catData.strings)`. On top of that: the nested `renderOrError` closure (lizard folds its `if` into the parent), the `(self.originalStrings and self.originalStrings[gn]) or _G[gn]` fallback (+2), `if newErr or origErr` (+2), the `printed == 1 and "string" or "strings"` pluralization (+2) and `if errored > 0`.

**Fix.** Split into five file-locals in modules/Override.lua plus a module-level LABEL constant table; no behavior change, no new globals.
1. Hoist the three label strings to a module-level `local LABEL = { name = Color.green.."Name: "..Color.reset, original = ..., formatted = ... }` right after `local Color` (Color is a load-time constant, so this is safe and removes a per-call allocation).
2. `local function renderOrError(fmt)` — the current nested closure, lifted to module scope verbatim (CCN 2). It only closes over Color/NS.
3. `local function categoryMatches(filter, category) return not filter or filter.kind ~= "category" or filter.value == category end` (CCN 3).
4. `local function collectNames(catData, filter)` — returns the sorted, filtered name list; opens with `if not (catData and catData.strings) then return names end` so the old `catData and catData.strings and next(...)` guard is subsumed (the `next()` emptiness check is already equivalent to the existing `#sortedNames > 0` gate) (CCN 7).
5. `local function printStringRow(addon, category, globalName)` — prints the Name/Original/Formatted/blank quartet and `return newErr or origErr` (CCN 4).
6. `local function printCategoryBlock(addon, category, names)` — prints the gold `Category:` header + blank, loops names through printStringRow, returns `printed, errored` (CCN 3).
7. `local function printFooter(printed, errored)` — the pluralized footer plus the `, %d errored` clause (CCN 4).
Test then reads: header, disabled notice, `for _, category in ipairs(NS.Schema.CATEGORY_ORDER)` -> `if categoryMatches(filter, category)` -> `local names = collectNames(NS.Defaults[category], filter)` -> `if #names > 0 then emittedAny = true; local p, e = printCategoryBlock(self, category, names); printed, errored = printed + p, errored + e end`, then the `if not emittedAny` early return and `printFooter(printed, errored)`. CCN 6.

**Must not change.** Exact print ORDER and the exact literal text of every line — the tests assert on both, and users diff Original against Formatted visually. Specifically: header first, disabled notice as line 2 when the master toggle is off, one blank line after the Category header and one after each string's Formatted line, the gold `Category: ` header emitted only when the category has >=1 matching string, `(no matching strings)` (with early return, no footer) when nothing matched, singular `1 string shown` vs plural, the `, %d errored` suffix, and the fact that Original comes from `self.originalStrings[gn]` falling back to `_G[gn]`. Every line must still route through NS.Print so it carries the [PC] prefix. A `string.format` failure must stay contained by the pcall inside NS.RenderSample and print `(error: ...)` in gray rather than propagating. Test must keep ignoring the enable toggles.

**Coverage.** tests/test_override.lua:167-250 — seven characterization tests covering header + per-category block + counted footer, the OnEnable-snapshot Original line, formatstring-filter narrowing + singular footer, the empty-filter `(no matching strings)` path, the disabled-but-still-previews path, the unrenderable-override error line + `0 strings shown, 1 errored` footer, and the [PC]-prefix-on-every-line invariant. tests/test_render.lua covers NS.RenderSample itself. Coverage is good enough to refactor against as-is; no new characterization test needed.

---

### `build (tests/loader.lua instance factory)` — CCN 18 → target 7

`tests/loader.lua:77-121` · pattern `phase-sequence-inlined` · risk **low**

**What it does.** Builds one fully-booted, isolated PrettyChat test instance: fresh mock env, optional pre-load mock tweak, runs every compiled LibKa0s + TOC chunk under that env honoring opts.skip, runs OnInitialize, seeds `ORIG:<GLOBALNAME>` originals for every schema row, runs OnEnable, and returns { env, NS, addon, mocks }. It is a local inside the factory closure returned by the file, reached via the `__call` metamethod on the published table.

**Where the branches come from.** A linear sequence of six small phases, each carrying its own branches, all inlined: `opts = opts or {}` (+1); `ipairs(opts.skip or {})` skip-set build (+2); `if type(opts.mock) == "function"` (+1); the source loop with `if not skipSet[src.path]` and `if src.lib then ... else ...` (+3); `if addon and addon.OnInitialize` (+2) and `if addon and addon.OnEnable` (+2); and the seeding block — `if NS.Schema and NS.Schema.CATEGORY_ORDER` (+2), two nested ipairs loops (+2), `if row.globalName and not seen[row.globalName]` (+2).

**Fix.** Extract four named locals; `build` becomes a readable list of phase calls. Two go at module scope in tests/loader.lua (above the returned factory) because they close over nothing; two stay inside the factory closure because they need `sources` / `chunkFor`.
Module scope:
1. `local function toSet(list) local set = {} for _, v in ipairs(list or {}) do set[v] = true end return set end` (CCN 3).
2. `local function callIfPresent(addon, method) if addon and addon[method] then addon[method](addon) end end` (CCN 3) — replaces both lifecycle guards.
3. `local function seedOriginals(NS, mocks)` — the whole ORIG: seeding block, opening with `if not (NS.Schema and NS.Schema.CATEGORY_ORDER) then return end` (CCN 7). Keep the existing comment on it.
Inside the factory (after `chunkFor`):
4. `local function runSources(env, NS, addonName, skipSet)` — the source loop with the skip guard and the `src.lib` lib-vs-addon call split (CCN 4).
build then reads: `opts = opts or {}`; `local skipSet = toSet(opts.skip)`; `local mocks = mockModule()`; `if type(opts.mock) == "function" then opts.mock(mocks) end`; `local env = Loader.makeEnv(mocks)`; `local NS = {}`; `_G.PrettyChatDB = nil`; `runSources(env, NS, "PrettyChat", skipSet)`; `local addon = mocks.LibStub("AceAddon-3.0"):GetAddon("PrettyChat")`; `callIfPresent(addon, "OnInitialize")`; `seedOriginals(NS, mocks)`; `callIfPresent(addon, "OnEnable")`; return the table. CCN 3.

**Must not change.** Phase ORDER is the whole contract and headless tests cannot catch a reordering that still passes today: mockModule() -> opts.mock(mocks) -> Loader.makeEnv(mocks) -> `_G.PrettyChatDB = nil` -> load sources -> GetAddon -> OnInitialize -> seed ORIG: strings -> OnEnable. Seeding MUST sit strictly between OnInitialize and OnEnable, because OnEnable is what snapshots originalStrings. opts.mock must still run before makeEnv and before any chunk executes. `setfenv(chunk, env)` must be re-applied per instance on the cached chunk (compile-once, re-run-per-instance). Libs are called with no args, addon files with (addonName, NS). Nulling the real `_G.PrettyChatDB` before loading must stay, or the AceDB fake adopts the previous instance's saved table. The returned table keeps both `env` and `mocks` pointing at the same table.

**Coverage.** Indirect but total: every one of the 17 tests/test_*.lua suites obtains its instance through this function, so a phase-order break fails the suite broadly. Targeted coverage: tests/test_harness.lua:36-50 pins the sources/tocFiles derivation; tests/test_lifecycle.lua:43 asserts `addon.originalStrings[globalName] == "ORIG:"..globalName`, which is exactly the seed-between-OnInitialize-and-OnEnable ordering; tests/test_libka0s.lua:250,406,521,550,593 and tests/test_panel.lua:321-326 exercise opts.skip; tests/test_libka0s.lua:378 and tests/test_panel.lua:113 exercise opts.mock. No dedicated test for the compile-once cache or for `_G.PrettyChatDB = nil` — those are covered only by the absence of cross-suite bleed.

---
