# 04 — Technical design (Ka0s Pretty Chat)

**Run date:** 2026-09-23 · **Standard:** v2.64.0 · Keyed to the IDs in `02_DEVIATIONS.md`.

This bundle is read-only; nothing below has been done. The design is ordered the way the work has to
land: **upstream first** (the standard and LibKa0s), then the **whole-folder re-vendor** that carries
the library changes in, then this addon. Five findings cannot be settled in this repo alone because the
standard or the vendored kit is what is wrong or ambiguous (PC-84, PC-90, PC-93, PC-100, PC-102, and the
PC-69 tension); each is designed so the addon change is small whichever way upstream decides.

---

## A. Upstream — WowAddonStandards (decisions, not code here)

| Question to settle | Findings it decides | Recommended ruling | Addon consequence either way |
|---|---|---|---|
| Does `events-frames-taint-§1`'s carve-out admit a lazily-created, fully-stood-down private frame for **non-unit boundary events**, given `library-stack-§1` already cites PrettyChat's watcher as the reason AceEvent became "when used"? | PC-84 | Extend the carve-out narrowly: *a single private frame whose only job is a fixed set of `PLAYER_REGEN_*`-class boundary events, held on `NS`, unregistered by the stand-down, re-used* — or state that such an addon records a row. | Extended → PC-84 closes by rule change. Not extended → one register row keyed `events-frames-taint-§1`. Vendoring AceEvent for two events is the literal fix and is not recommended. |
| Does `architecture-§4`'s "any module that registers game events" arm bind a single-module addon whose one registrant is that private frame? | PC-102 | Narrow the arm to *a module registering through a shared AceEvent target, or a second receiver* — the clobber hazard the rule cites needs two receivers. | Narrowed → rewrite one sentence of `## Message Bus`. Kept → one register row keyed `architecture-§4`. |
| Does `compat`'s "every addon MUST ship `core/Compat.lua`" bind an addon with zero addon-specific shims now that `LibKa0s-Env-1.0` owns the metadata reader? `library-stack-§7` already states "AbsorbTracker and PrettyChat carry none". | PC-93 | Allow the file's absence when no addon-specific shim exists, and route any legacy rung a seam's degraded branch keeps through the seam itself. | Allowed → closes by rule change. Kept → a 15-line `core/Compat.lua` owning the legacy `GetAddOnMetadata` rung (design C6). |
| `architecture-§1` prints `local addonName, NS = ...` as mandatory while `lint` forbids suppressing `211/addonName`. | PC-100 | Permit `local _, NS = ...` where the file never reads the name. | None — Info only. |
| `options-ui-§13`'s Testing MUST (wrap invariance) vs `testing-§8` (library behavior tested where it lives) for a strip the library draws. | PC-69 | The invariant is pinned in LibKa0s' suite; a host that draws its strip through `H.TabStrip` owes no copy. | Adopted → PC-69 closes. Kept → one host case against a per-atlas-height mock (design C9). |
| Is a subcategory Defaults button mandatory (`options-ui-§5`'s header description, `slash-commands-§2`'s "every schema-driven page already carries …")? | PC-96 | Say so explicitly, with the General page's veto list named. | Either way the addon can enable it cheaply (design C4). |

File one issue per row in `tusharsaxena/WowAddonStandards` (gh CLI, no GraphQL), each citing this
bundle's ID. The AUDIT playbook's High grade for PC-82 against its own impact table is worth raising in
the same batch, as a playbook consistency question, not as a PrettyChat change.

## B. Upstream — LibKa0s (code, then a tag)

### B1. The runner's perf skip reason (PC-90, feeds PC-91)

`testkit/run-automated-tests.sh` hard-codes one skip reason when `tests/perf.lua` is absent
(`:343-344`) and writes a standing paragraph that denies an exemption (`:838-841`).
`automated-tests-§3` sanctions two reasons and MUSTs the second — naming `performance-§12` — when it
applies. The runner needs a **consumer fact** it can read without a per-repo edit:

- Preferred: detect a `| \`performance-§12\` |` row under `## Documented deviations` in
  `docs/ARCHITECTURE.md` (or the root `CLAUDE.md` for a library repo) — the register is already the
  single home of the exemption, so this reads the one true record rather than a second flag.
- Emit `skipReason: "performance-§12 no-combat-path exemption (docs/ARCHITECTURE.md register)"` in the
  manifest and replace the standing paragraph with one that names the exemption.
- Test it in the kit's own suite with two fixture trees (row present / absent).

Ship in a LibKa0s tag (kit revision 26 or the next free), with a changelog entry noting the runner's
new read.

### B2. Wrap invariance in the library (PC-69, if ruling A5 lands that way)

A LibKa0s suite case over `OptionsTabs.lua`: a strip wide enough to wrap, a mock answering a different
height for the selected-state art, and assertions that the band height and every row's y offset are
identical across every selection value, carrying the `-- red under:` mutation.

## C. Re-vendor (whole folder) and this addon

### C0. Re-vendor LibKa0s whole, and record it (PC-82)

- Copy the tagged `LibKa0s/` over `libs/LibKa0s/` and `testkit/` over `tests/_kit/` — whole folders,
  never files; move `CLAUDE.md:42`'s provenance line **in the same commit**; set
  `git update-index --chmod=+x tests/_kit/run-automated-tests.sh`.
- `tests/test_vendor_sync.lua` must go green against the new tag; `diff -r` both payloads.
- Write the new tag's `docs/revendor/<date>-v<tag>/` bundle **and**, separately, the one
  **consolidated** backlog bundle PC-82 owes — `docs/revendor/<date>-v1.18.0-v1.53.0/` with
  `01_DELTA.md` (the 26 tags, each with the commit that carried it, from
  `git log --format='%h %ad %s' -- libs/LibKa0s`) and `05_SUMMARY.md` (what was adopted in those
  commits — Launcher at v1.39.0, Lifecycle/latch at v1.42.0+, the rest carried by sweeps). Its first
  line names the span so the recorded-tag check resolves it.

### C1. TOC annotations (PC-77, PC-78, PC-79, PC-80, PC-60)

One comment-only edit to `PrettyChat.toc`:

```
# core\CoreSetup.lua loads AFTER core\PrettyChat.lua and the position is load-bearing: NewAddon
# embeds AceConsole's :Print over NS.Print, and this file's last line reclaims it (anti-pattern #36).
# Loaded earlier, nothing errors and every chat line turns green with a trailing colon.
core\CoreSetup.lua
# core\DebugLogSetup.lua loads AFTER core\Constants.lua and the position is load-bearing: the console
# descriptor reads NS.Const.FONT_MONO at file scope. NS.State and NS.Print are read at call time.
core\DebugLogSetup.lua
…
# settings\OptionsSetup.lua loads AFTER settings\Schema.lua and the position is load-bearing: its
# descriptor takes NS.SchemaRuntime's Get/Set/ApplyDefault/AllRows as values and it calls
# NS.Schema.InstallMasterControls at file scope.
settings\OptionsSetup.lua
# settings\Slash.lua loads AFTER settings\Schema.lua and the position is load-bearing: the dispatcher
# descriptor takes NS.SchemaRuntime's members as values at file load.
settings\Slash.lua
```

Plus one *conventional* note per group for PC-60 (`# Core`: which of Constants/Namespace/State/
Database/PrettyChat are free to move and why; `# Modules`; `# Settings` replacing the
"depend on everything" phrasing with what actually resolves). Update `docs/ARCHITECTURE.md:35`'s list
to match the TOC one-for-one (it names six positions; the TOC will annotate eight) and
`docs/module-map.md`'s load-order section. Consider a `test_doc_structure` case asserting every
position the hub lists as load-bearing carries a comment in the TOC.

### C2. Categories Defaults button page-wide (PC-81) — needs the owner's call

Two designs; the first is the rule.

- **Page-wide (rule).** `ctx.panel.defaultsOnClick` resets every message category:
  `Schema.ResetRows(allCategoryRows, "Categories")` where `allCategoryRows` concatenates
  `Schema.RowsByCategory(c)` for `c` in the page's `TAB_ORDER` — one batch, one `ApplyStrings`, one
  `[Set] reset Categories: N rows` line (debug-logging-§10 counts it as one bulk act). Tooltip becomes
  *"Reset every message category on this page to its defaults."* (new `enUS` key; old key removed —
  localization-§3 forbids dead keys). A page-wide reset of ~170 rows is destructive enough to warrant
  a confirmation popup; if added, give it its own wording (it is not the global reset). The per-tab
  reset remains available as the category row's own reset or a `/pc reset <path>` walk, and README
  `Usage`/`Troubleshooting` change in the same commit (de-AI pass).
- **Ratify (owner).** A `## Documented deviations` row keyed `options-ui-§13`: *What differs* — the
  Categories page's Defaults resets the selected tab; *Why* — eight independent categories, the page
  button would discard 170 rows for a one-category mistake; *Re-check trigger* — "an `options-ui`
  revision that names a per-tab reset control, or the category tabs becoming one schema group".

Tests: extend `tests/test_panel.lua`'s Defaults case to assert the chosen scope (N rows across all
eight categories, or exactly one category) and that the footer `OnDefault` forwards to the same body.

### C3. Test tooltip (PC-87)

Change the key in `settings/Schema.lua:162` and `locales/enUS.lua` together: *"Print a sample of
every active format string to the debug console, so you can see what real loot/currency/XP messages
will look like. `/pc test` writes the same report there."* Add a case in `tests/test_locale.lua` that
fails if any `L[...]` key mentioning `/pc test` says "chat" while `runTest` routes to
`TestToConsole` (cheap text assertion against the source).

### C4. General page Defaults button (PC-96)

`defaultsButton = true`, `defaultsTooltip = L["Reset Enable and General visibility to their defaults."]`,
`ctx.panel.defaultsOnClick = function() PrettyChat:ResetCategory("General") end`. The existing
allow-list (`modules/Override.lua:332`) already excludes `state.debugConsole` and `global.minimap.hide`,
which is exactly what `launcher-§3` requires. `tests/test_launcher.lua`'s two-reset case then covers a
real button. Update `docs/settings-panel.md:79` (the "redundant" sentence).

### C5. Event registration guard (PC-85) and the watcher/bus decisions (PC-84, PC-102)

```lua
-- modules/Override.lua
NS.RejectedEvents = NS.RejectedEvents or {}
local function registerEvent(frame, event)
    if C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(event) then
        NS.RejectedEvents[event] = "invalid on this client"; return false
    end
    local ok, err = pcall(frame.RegisterEvent, frame, event)
    if not ok then NS.RejectedEvents[event] = tostring(err) end
    return ok
end
```

The loop calls `registerEvent`; the rejected set is surfaced on `/pc debug` (one tagged line when
non-empty) and in the `[Init]` summary. Test with the kit's `M.__badEvents` that one bad name leaves
the other registered and is recorded. The frame itself stays until ruling A1/A2; if the rulings keep
the MUSTs, add the two register rows (texts drafted in `02_DEVIATIONS.md`).

### C6. Compat (PC-93) — only if ruling A3 keeps the MUST

`core/Compat.lua` (TOC before `core/EnvSetup.lua`, annotated conventional — EnvSetup reaches it at call
time) publishing `NS.Compat.GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or
GetAddOnMetadata` with the legacy rung only here; `core/EnvSetup.lua:72-77` calls it. Re-run the
`compat-layer.md` count (1 < 3 → the N/A row stays, with its text updated).

### C7. Defaults declared once (PC-94)

- New `defaults/Global.lua` → `NS.GlobalDefaults = { schemaVersion = 0, minimap = { hide = false } }`;
  `core/Database.lua` reads it for `Database.defaults.global` (TOC: `defaults\` loads after `core\`, so
  `Database.defaults` must be assembled at `OnInitialize` time, not file load — `core/PrettyChat.lua:29-35`
  already merges there).
- `defaults/Profile.lua` gains `NS.GeneralDefaults = { enabled = true, visibility = "always" }`
  **outside** `NS.ProfileDefaults.profile`, so the absent-key storage contract (`docs/schema.md:170`) is
  untouched. `MASTER_SPEC.defaults`, `PrettyChat:IsAddonEnabled`, `GetVisibility` and the visibility
  row's clearing arm read it.
- Characterization first (testing-§13): pin `IsAddonEnabled`/`GetVisibility` on nil/false/string
  stored values before the change.

### C8. Small MUSTs

- **PC-95** `settings/Schema.lua:5-6` → `NS.Schema = NS.Schema or {}; local Schema = NS.Schema`.
- **PC-83** generator move to `tools/` with the dependent edits listed in `02_DEVIATIONS.md`; add
  `- tools` to `.pkgmeta`; re-run `.pkgmeta` checks (a)/(b)/(c); confirm the script's repo-root paths
  still resolve (it reads and asserts on `PrettyChat.toc`).
- **PC-97** Pillow entry in `DEPENDENCIES.md` → *Release / assets*.
- **PC-98** two README highlights reworded, through the de-AI pass.
- **PC-73 / PC-88 / PC-89** register edits in `docs/ARCHITECTURE.md` (narrow; retire; re-point the
  `LIBKA0S-05` citation, also at `locales/enUS.lua:26` and `tests/test_locale.lua:237`).
- **PC-86** one sync pass over the eight drift items; **PC-99** eleven self-naming headers.
- **PC-91** `docs/testing.md:238-239` names the exemption; **PC-92** the one authored cell in
  `docs/automated-tests/RESULTS.md` points at the census (at the next runner run, not by hand-editing
  generated rows).

### C9. PC-69 host case (only if ruling A5 keeps it)

A `tests/test_panel.lua` case over the Categories strip at a width that wraps (inject a narrow
`scroll.frame` width), with the extender answering a different atlas height for the selected tab
(`tests/wow_mock.lua`, never `tests/_kit/`), asserting identical band and row offsets across all eight
selections; `-- red under:` naming the mutation (read the pitch off the selected tab).

## D. Risks and ordering constraints

- **C0 before everything in C**: a re-vendor lands a new kit whose gates (EOL, cap, prose, inventory)
  may add cases; take the new tag green first, then make the addon edits against it.
- **PC-81 changes player-visible behavior** — README, `docs/settings-panel.md`, `docs/schema.md:158`
  and the smoke tests move with it, in one commit.
- **PC-87 and PC-81 are key changes** in `locales/enUS.lua`; the enUS manifest test and the prose gate
  must stay green; no second locale file exists, so only the manifest moves.
- **PC-83** changes a documented command; grep the repo for `GlobalStrings/split_globalstrings.py`
  before committing (DEPENDENCIES, common-tasks, global-strings, GlobalStrings/README, prose_waivers,
  the register row).
- **PC-94** touches load order (`defaults/` after `core/`); keep `Database.defaults` resolution at
  `OnInitialize` and pin it with a case.
- **Release checkpoint**: after the addon sprints, a full four-suite run (`run-automated-tests.sh`) on
  the new kit writes the first row with commit cells and — once B1 lands — the correct perf skip reason;
  `ANALYSIS.md` for that run if it is a release.
