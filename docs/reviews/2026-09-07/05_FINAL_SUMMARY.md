# 05 — Final summary

> **Status: written ahead of implementation.** This artifact is the post-implementation record for
> the 2026-09-07 review, drafted on the assumption that every change in `02_PROPOSED_CHANGES.md`
> lands and every check in `03_SMOKE_TESTS.md` passes. Fill in the sign-off table and the commit
> range before pasting it into a PR; anything still unimplemented moves to **Known follow-ups**.

---

## Headline

Ka0s Pretty Chat's job is to replace Blizzard's chat format strings with the player's own. This cycle
closed the one place that trust was one-way: the addon stored whatever a player typed and handed it
straight to Blizzard's chat code, where a format asking for more arguments than the game supplies
raises a Lua error on every matching line for the rest of the session — and the panel's own Preview
could not warn, because it invents exactly the arguments the format asks for. The check to catch it
already existed, in the test suite, where nothing could call it; it now lives in the addon and runs on
the single write path, so the panel and `/pc set` refuse the same input with the same explanation.

Beside that, the settings landing page stopped being a private copy of a renderer the vendored
LibKa0s already ships. The copy never hid its logo texture when AceGUI released the widget it was
drawn on, so a 300-pixel logo rode the shared widget pool into whatever acquired that frame next —
this addon's own category pages, or another addon entirely. The library's version fixes exactly that
and documents the bug in place; adopting it removed the defect and 51 lines of duplicated layout
code at the same time.

The rest is the record catching up with the code: the committed sweep backing the addon's
performance exemption no longer reproduced, and the localization register claimed a check the test
suite is structurally incapable of performing.

---

## Counts

| Severity | Found | Fixed | Deferred |
|---|---|---|---|
| Critical | 0 | 0 | 0 |
| High | 2 | 2 | 0 |
| Medium | 6 | 6 | 0 |
| Low | 4 | 4 | 0 |

*(Adjust after implementation. `PRETTYCHAT-R-06` / PC-C-08 is the most likely deferral — see Known
follow-ups.)*

No finding landed in vendored code: `libs/LibKa0s/` and `tests/_kit/` both diffed clean against
`../LibKa0s` at v1.25.0 on the review date, and nothing in this cycle edited either.

---

## Changes by theme

### Theme A — The format invariant moved from the suite to the write path

**What changed.** `NS.ConversionSequence` is published on the namespace and used by three callers
instead of one: the shipped-defaults gate in the test suite (unchanged behaviour), the sample-argument
synthesizer, and a new guard in `Schema.Set`. A `string_format` write whose printf sequence is not a
positional prefix of Blizzard's is refused with a message naming the expected sequence; a truncating
format is still accepted, because `string.format` ignores surplus arguments.

**Why it mattered.** `docs/ARCHITECTURE.md` names format-signature matching as an invariant that
"no test or lint will name" when broken, and then checked it only for the addon's own 81 defaults.
The player's input — the addon's entire point — went unchecked, and the Preview that looked like a
safety net could not be one.

**Findings covered:** `PRETTYCHAT-R-01`, `PRETTYCHAT-R-08`.
**Changes implemented:** PC-C-01, PC-C-02.
**Files touched:**

- `modules/Override.lua`
- `settings/Schema.lua`
- `locales/enUS.lua`
- `tests/test_defaults.lua`
- `tests/test_schema.lua`
- `docs/test-cases.md`, `README.md` (badge)

### Theme B — The landing page adopted the library's renderer

**What changed.** `settings/Panel.lua`'s `buildParentBody` is now a call to `H.BuildLandingPage` with
a `spec` carrying the logo path, the TOC one-liner and one section of slash-command rows. The
degradation stub in `settings/OptionsSetup.lua` declares `BuildLandingPage` as a no-op.

**Why it mattered.** AceGUI pools widget frames and a `Texture` is not a widget, so nothing hid the
logo when the group was released. The library's `landingLogo` carries both halves of the fix —
reuse-on-the-same-frame *and* `SetCallback("OnRelease", …)` — and its own comment records the same
symptom biting another host. Keeping a private copy also meant keeping the library's label-font
guard pair, ClearScroll ordering and spacer constants in sync by hand.

**Findings covered:** `PRETTYCHAT-R-02`.
**Changes implemented:** PC-C-03.
**Files touched:**

- `settings/Panel.lua`
- `settings/OptionsSetup.lua`
- `core/Constants.lua`, `tests/test_constants.lua` (only if the two section spacers lost their last
  caller)

### Theme C — The committed record now says what the code says

**What changed.** `docs/performance.md`'s sweep was re-run and its result block replaced with real
output, plus a disposition for the `C_Timer.After` hit it now returns. `docs/ARCHITECTURE.md`'s
`NS.L` invariant and its `localization-§1` register row now state what is routed and what is not,
instead of asserting the routing SHOULD is satisfied. Four stale comments were corrected.

**Why it mattered.** `audit-review-history` makes the register the single home of a ratified
deviation and makes reading it a MUST in both directions. A register that claims a check exists is
worse than one that admits a gap, because the next auditor stops looking.

**Findings covered:** `PRETTYCHAT-R-03`, `PRETTYCHAT-R-04`, `PRETTYCHAT-R-09`, `PRETTYCHAT-R-10`.
**Changes implemented:** PC-C-06, PC-C-07.
**Files touched:**

- `docs/performance.md`
- `docs/ARCHITECTURE.md`
- `tests/test_locale.lua` (header comment only)
- `core/MediaSetup.lua` (comment only)
- `tests/test_vendor_sync.lua` (comment only)

### Theme D — Two correctness repairs

**What changed.** `ApplyStrings`' restore branch tests `~= nil` rather than truthiness, so a
`GLOBALNAME` this client does not define is still restored when the addon is switched off; `OnEnable`
emits one summary line naming how many were missing. `OnInitialize` builds a fresh merged defaults
table instead of grafting `Database.defaults` onto the module-level `NS.ProfileDefaults`.

**Why it mattered.** The first was a one-way write — the master toggle's own contract says it wins,
and for an undefined global it did not. The second made `NS.ProfileDefaults` mean two different
things depending on when it was read.

**Findings covered:** `PRETTYCHAT-R-07`, `PRETTYCHAT-R-12`.
**Changes implemented:** PC-C-04, PC-C-05.
**Files touched:** `modules/Override.lua`, `core/PrettyChat.lua`, `tests/test_apply.lua`.

### Theme E — Slash output routed as sentences *(if PC-C-08 landed)*

**What changed.** The `/pc` error, usage and deprecation lines became single routed sentences with
`%s` placeholders and the colour escapes applied outside the routed string, matching the shape
`settings/Panel.lua` already uses.

**Why it mattered.** The most-read chat surface in the addon — the one a confused user hits — was the
least translatable part of it, and was inconsistent with the panel beside it. The English-only
shipping decision is unchanged; this buys structure, not behaviour.

**Findings covered:** `PRETTYCHAT-R-06`. **Changes implemented:** PC-C-08.
**Files touched:** `settings/Slash.lua`, `locales/enUS.lua`, `tests/test_slash.lua`,
`docs/test-cases.md`, `README.md`.

---

## API / behaviour changes

| Change | Detail |
|---|---|
| **`/pc set <Cat>.<GLOBAL>.format <text>` can now be refused** | A format whose printf conversion sequence is not a positional prefix of Blizzard's is rejected with a `[PC]` line naming the expected sequence, and nothing is stored. Previously accepted silently and raised inside Blizzard's chat handler at runtime. |
| **The settings panel's *New* box can now be refused** | Same rule, same message, same seam — both surfaces route through `Schema.Set`. |
| **Truncating formats remain accepted** | Dropping trailing conversions is safe and stays legal, matching the rule the suite already applies to the shipped defaults. |
| **Landing-page spacing may shift by a few pixels** | The library's spacer constants replace two host copies (`options-ui-§8`). No content changed: same logo, same tagline, same ten command rows, same alias line. |
| **One new locale key** | The refusal message, added to the `locales/enUS.lua` manifest. Plus the PC-C-08 keys if that change landed. |
| **No slash verb added, renamed or removed** | The `COMMANDS` table is unchanged; ten verbs before and after. |

---

## Saved-variable / migration notes

**No schema bump. `Database.SCHEMA_VERSION` stays at 1 and `migrations` stays empty.**

Nothing in this cycle changed the stored shape: the same `db.profile.enabled`,
`db.profile.visibility`, `db.profile.categories[<Cat>].{enabled, strings, disabledStrings}` and
`db.global.schemaVersion`. PC-C-05 changed only how the **defaults table** is assembled in memory
before `AceDB:New`, and AceDB deep-copies defaults into the DB rather than aliasing them, so no
stored value moves.

**Existing profiles need no action** — no `/pc resetall`, no `/reload` beyond the ordinary one after
updating. One consequence worth stating: a profile that already stores a **malformed** format (saved
before PC-C-02) keeps it. The validation runs on write, not on load, so the bad value survives and
still raises. A player in that state clears it with the per-string **Reset** button, the category
**Defaults** button, or `/pc reset <Cat>.<GLOBAL>.format`. Consider whether a one-time load-path sweep
is worth a follow-up; it was deliberately not built here, because refusing at the seam is the smaller
change and a load-path sweep that silently rewrote a player's setting would be its own surprise.

---

## Deprecated-API migrations

**None.** The addon calls no deprecated or removed API. `C_AddOns.GetAddOnMetadata` is reached
through the `LibKa0s-Env-1.0` seam with a correct fallback ladder (`core/EnvSetup.lua`), and a sweep
for `GetSpellInfo`, `UnitAura`/`UnitBuff`/`UnitDebuff`, `GetContainerNumSlots`/`GetContainerItemInfo`,
`IsAddOnLoaded`/`LoadAddOn`/`GetAddOnInfo` and `InterfaceOptions_AddCategory` returned nothing in
`core/ defaults/ locales/ modules/ settings/`.

---

## Performance impact

**No perf-tagged change was made, and no number is offered.** The addon brackets nothing under a
ratified `performance-§12` no-combat-path exemption; it ships no `tests/perf.lua` and no
`docs/perf-analysis/` bundles, so there is no scenario and no capture to cite. Stating a figure here
would be an estimate, which this section does not carry.

Two qualitative notes, each with the record behind it:

- **PC-C-02 adds work only to a settings write**, which happens at human speed. It parses one format
  per write and retains nothing. `03_SMOKE_TESTS.md`'s garbage-count check is the confirmation that
  it retains nothing; there is no per-message and no per-frame path in this addon for it to reach.
- **PC-C-03 removes 51 NLOC from the settings render path** and hands the work to the library's
  renderer. Nothing about that is measurable in game — a settings page is drawn when a player opens
  it — and it is not claimed as a performance win.

The `performance-§12` exemption is **unchanged** by this cycle. PC-C-06 corrected its evidence; the
row itself, its criteria and its re-check trigger stand.

---

## Test and complexity movement

| | Before | After |
|---|---|---|
| Headless pass count | **300 / 300**, 18 suite files, 0 skipped | *(fill in — expect 305–310 after PC-C-02, PC-C-04 and PC-C-08)* |
| `luacheck` | 0 warnings / 0 errors over 18 files | expected unchanged |
| `docs/test-cases.md` | regenerated in the same commit as each count move | ✅ / ❌ |
| README `[tests]` badge | moved in the same commit as the inventory | ✅ / ❌ |

**Complexity — to be confirmed by the next release regeneration, not run now.**
Today's fresh `lizard` run (2026-09-07): 0 warnings over 645 functions, maximum CCN **13**. Expected
movement at the next `/wow-addon:bump-version`:

- `buildParentBody` (`settings/Panel.lua`, CCN 11) — **gone**, deleted by PC-C-03.
- `fitTree` (`settings/Panel.lua:413`, CCN **13**) — should **appear** on `RESULTS.md`'s
  nearest-threshold list; the committed narrative does not carry it and records the maximum as 12.
- `PrettyChat:ApplyStrings` (`modules/Override.lua:122`) — reads **12**, where the narrative records
  11.
- `Schema.Set` — gains one branch from PC-C-02, ~10 → ~12. Still comfortably under 15.
- The narrative's *"260 cases, across 17 suite files"* and *"Clean over 17 files"* need re-deriving;
  they are two bundles stale as of this review (`PRETTYCHAT-R-05`).

Per `automated-tests-§4`, none of that was regenerated here and no commit was gated on it.

---

## Known follow-ups

| Item | Why deferred |
|---|---|
| **`PRETTYCHAT-R-06` / PC-C-08 — routed slash sentences** | Widest-touching, lowest-value change in the set: the English-only deviation is ratified and terminal, so this buys structure rather than behaviour. T4.2's correction of the register is what actually closes the misleading claim. Pick it up when a second locale file is genuinely on the table — which is also the deviation row's own re-check trigger. |
| **`defaults/Defaults.lua`'s 81 per-string labels** | User-facing and unrouted. Routing them means 81 manifest entries for a surface no translator exists for yet, and the labels double as the panel's tree row text. Fires with the same trigger as the row above. |
| **A load-path sweep for pre-existing malformed formats** | PC-C-02 refuses at the seam; a value stored before it still raises. A load-path sweep that silently rewrote a player's setting is its own surprise, and the three existing reset paths already clear it. Revisit if a user reports it. |
| **`PRETTYCHAT-R-11` — three seams with no caller** | `NS.Icon`, `NS.MakeCloseButton` and `NS.Format` are deliberate, argued in place, and cost nothing. Left as-is; noted in `docs/module-map.md` so a later dead-code sweep does not misread them. PC-C-03 leaves `NS.MakeCloseButton` without a caller too — the library draws the console's close control. |
| **`tests/loader.lua` deletion (`LIBKA0S-01`)** | Blocked on `tests/_kit/loader.lua` gaining an isolated-environment mode upstream. Already a ratified `testing-§1` deviation row with the right trigger; out of scope here. |

---

## Verification evidence

- **Headless, measured on 2026-09-07 before any change:** `luacheck .` → `0 warnings / 0 errors in
  18 files`; `lua5.1 tests/run.lua` → `300 passed, 0 failed, 0 skipped`;
  `lua5.1 tests/run.lua --list` diffs clean against `docs/test-cases.md`;
  `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` → `No thresholds exceeded`, 0 warnings over 645
  functions; `diff -r libs/LibKa0s/ ../LibKa0s/LibKa0s/` and `diff -r tests/_kit/
  ../LibKa0s/testkit/` → no differences. Full block: `01_FINDINGS.md`, *Measurement run*.
- **In-client:** the completed sign-off table at the bottom of
  [`03_SMOKE_TESTS.md`](./03_SMOKE_TESTS.md), with SMOKE-01, SMOKE-02 and SMOKE-05 as the three that
  must pass before this is considered shipped.
- **Commit range:** *(fill in)* · **PR:** *(fill in)*

---

## Suggested PR description

```
Refuse a chat format Blizzard cannot fill, and stop hand-rolling the landing page

Two defects and a stale record, from the 2026-09-07 review
(docs/reviews/2026-09-07/).

PRETTYCHAT-R-01 — the addon stored whatever format a player typed and handed it to
Blizzard's chat code. One asking for more conversions than the game passes makes
string.format raise inside Blizzard's own handler, on every matching line, for the
rest of the session. The panel's Preview could not warn: it synthesizes exactly the
arguments the format under test asks for, so a wrong format previews perfectly. The
comparison already existed in tests/test_defaults.lua, where nothing could call it
(PRETTYCHAT-R-08); it is now NS.ConversionSequence, and Schema.Set runs it against
this client's own OnEnable snapshot. Both the panel and /pc set get the refusal,
because both already route through the one seam.

PRETTYCHAT-R-02 — settings/Panel.lua's landing body was a private copy of
LibKa0s's O.BuildLandingPage, and the copy never hid its logo Texture when AceGUI
released the widget it sat on. AceGUI pools frames and a Texture is not a widget, so
the 300px logo rode that frame into whatever acquired it next -- this addon's own
category rows, or another addon. The library fixes exactly that and documents the
bug in place; adopted, and 51 lines of duplicated layout went with it.

Also: restore on `~= nil` rather than truthiness, so a global this client does not
define is still restored when the addon is switched off (PRETTYCHAT-R-07); a
non-mutating defaults merge (PRETTYCHAT-R-12); a re-run performance-§12 sweep that
now reproduces (PRETTYCHAT-R-03); and a corrected localization register, which
claimed a routing check the locale suite is structurally incapable of performing
(PRETTYCHAT-R-04).

No schema bump, no migration, no library edit. libs/LibKa0s/ and tests/_kit/ diff
clean against ../LibKa0s v1.25.0.

Tests: 300 -> <N>. docs/test-cases.md and the README badge moved with each count.
Lint: 0/0. Smoke tests: docs/reviews/2026-09-07/03_SMOKE_TESTS.md.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
```
