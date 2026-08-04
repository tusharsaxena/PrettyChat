# Final summary — what shipped (2026-08-03)

> **Status: written ahead of implementation.** This artifact is the post-implementation record, and
> it is written on the assumption that every task in `04_EXECUTION_PLAN.md` lands and every check in
> `03_SMOKE_TESTS.md` passes. Fill in the perf numbers and the commit range as the work lands; if a
> task is dropped, move its finding IDs to **Known follow-ups** with the reason.

## Headline

This cycle fixed the one class of defect that PrettyChat is uniquely exposed to and had no defense
against: a replacement template whose `%`-conversions disagree with the argument list Blizzard
actually passes it. Two shipped templates were wrong in a way that raised a Lua error inside
Blizzard's own message code, and neither the settings-panel Preview nor `/pc test` could show it,
because both synthesized their sample arguments from the template under test rather than from the
original. The templates are corrected, the addon's single write seam now refuses an incompatible
format with a reason, and the preview renders the way the game will call it. Alongside that, the
settings panel stopped showing an English snapshot of Blizzard's originals to non-English players —
it reads the client's own localized text, which also retired ~1.9 MB of shipped Lua and roughly
22,900 permanently-resident table entries from every session. The rest is structural tidying —
one ordered index instead of four, one bulk-reset tail instead of three — plus locale coverage and
comment hygiene.

## Counts

`Critical fixed: 0, High fixed: 3, Medium fixed: 6, Low fixed: 6` (F-001…F-015).
`Upstream raised: 1` (F-016 — lands in the LibKa0s repo, tracked as U-01).

Deliberately deferred: none at time of writing. Record any here with its reason.

## Changes by theme

### T1 — The shipped format data is consistent with Blizzard's

- **What changed:** `FACTION_STANDING_DECREASED_GENERIC` and `FACTION_STANDING_INCREASED_GUARDIAN`
  now declare exactly the conversions the game passes them. Four templates that intentionally drop a
  trailing argument are annotated as intentional.
- **Why it mattered:** each of the two raised `bad argument #N to 'format'` inside Blizzard's UI
  whenever the message fired — an error the player sees and the addon does not own the stack for.
- **Findings:** F-001, F-011. **Changes:** C-01, part of C-02.
- **Files:** `defaults/Defaults.lua`.

### T2 — Validation at the write seam, and a preview that can fail

- **What changed:** `Schema.Set` compares an incoming format string's conversion signature against
  the original's and refuses with a reason instead of storing it; `NS.RenderSample` accepts a
  reference format and builds its sample arguments from that, so the panel Preview and `/pc test`
  render the template as the game will call it.
- **Why it mattered:** the panel and `/pc test` were structurally incapable of surfacing the single
  most likely user error, which the README's Troubleshooting table already describes. The addon
  accepted values it knew the game could not honor.
- **Findings:** F-002. **Changes:** C-02.
- **Files:** `settings/Schema.lua`, `modules/Override.lua`, `settings/Panel.lua`, `locales/enUS.lua`,
  `tests/test_schema.lua`, `tests/test_render.lua`, `tests/test_panel.lua`.

### T3 — One localized source of truth for "the original"

- **What changed:** the panel's read-only **Original Format String** box (and the C-02 validator)
  read `PrettyChat.originalStrings`, the localized snapshot the addon already takes at `OnEnable`,
  with `_G` as a fallback. The ten generated `GlobalStrings_0NN.lua` chunks left the TOC and the
  shipped package; the folder stays in the repo as build-time developer reference. The snapshot
  itself is now taken once per session with a sentinel for keys the client does not define.
- **Why it mattered:** the box showed English on every non-English client, which defeats its only
  purpose; and every player paid the parse and memory cost of ~22,900 entries to serve 81 lookups. A
  second `OnEnable` (an AceAddon disable/enable cycle) previously recorded PrettyChat's own strings
  as Blizzard's, with no way back short of `/reload`.
- **Findings:** F-003, F-006. **Changes:** C-03, C-04.
- **Files:** `settings/Panel.lua`, `modules/Override.lua`, `core/PrettyChat.lua`,
  `core/Constants.lua`, `PrettyChat.toc`, `.pkgmeta`, `docs/global-strings.md`,
  `docs/file-index.md`, `docs/module-map.md`, `tests/*`.

### T4 — One order, one partition, one bulk tail

- **What changed:** the sorted per-category name list and the category→rows partition are built once
  at schema load and read everywhere; the three reset paths (`ResetCategory`, `ResetAll`,
  `ResetString`) call one `Schema.ApplyScope` seam that performs one re-apply, one panel notify and
  one summary log line.
- **Why it mattered:** four independent copies of the ordering had to agree for the documented
  "last category wins" behavior to hold, and one of them re-sorted nine lists on every settings
  write. The three reset paths wrote the database directly, so any future validation or `onChange`
  would have been silently skipped by a reset.
- **Findings:** F-007, F-008, F-009. **Changes:** C-05, C-06.
- **Files:** `settings/Schema.lua`, `modules/Override.lua`, `settings/Panel.lua`,
  `settings/Slash.lua`, `tests/*`.

### T5 — Convention and documentation hygiene

- **What changed:** the remaining user-facing strings are localized (with parameterized keys rather
  than concatenated fragments), the `/pc test` header lost its trailing colon, comments no longer
  name the long-removed `Config.lua`, `NS.Config` became `NS.Panel`, the version fallback became a
  named constant, and `docs/file-index.md` stopped referencing a `TODO.md` that does not exist.
- **Why it mattered:** `locales/enUS.lua` advertises itself as the authoritative manifest of the
  translatable surface, and it was not one; the trailing colon breaks the collection-wide chat house
  style; stale references send readers looking for files that are gone.
- **Findings:** F-004, F-005, F-010, F-012, F-013, F-014, F-015. **Changes:** C-07, C-08.
- **Files:** `settings/Schema.lua`, `settings/Panel.lua`, `modules/Override.lua`,
  `settings/Slash.lua`, `locales/enUS.lua`, `core/Constants.lua`, `core/Namespace.lua`,
  `core/Util.lua`, `core/PrettyChat.lua`, `settings/OptionsSetup.lua`, `docs/*`, `tests/*`.

## API / behavior changes

- **`/pc set <path> <value>` can now fail** for a string row: an incompatible conversion signature
  prints a refusal naming the path and what was expected, and the stored value is unchanged. Same
  refusal, same wording, from the panel's **New** box.
- **The panel Preview and `/pc test` can now show an error** where they previously always rendered —
  that is the fix, not a regression: the sample arguments come from Blizzard's list.
- **The "Original Format String" box shows localized text** on non-enUS clients (previously always
  English).
- **New locale keys** added to `locales/enUS.lua` (parameterized category label/tooltip, the category
  Defaults tooltip, the shared-global note, the `/pc test` report labels, and the slash usage/error
  lines). No key was renamed; none removed.
- **No slash verb was added, renamed or removed.** `COMMANDS` is unchanged.
- **Namespace member rename:** `NS.Config` → `NS.Panel` (private namespace; no external consumer).
- **Ten files left the TOC** (`GlobalStrings/GlobalStrings_0NN.lua`) and the shipped package.

## SavedVariable / migration notes

**No schema bump.** `Database.SCHEMA_VERSION` stays at 1 and no migration was added: the stored shape
(`db.profile.enabled`, `db.profile.categories[<Cat>].{enabled,strings,disabledStrings}`) is unchanged
by every change in this cycle. Existing profiles load as-is; no `/pc resetall` is required. A user who
had customized either of the two C-01 templates keeps their own value — `/pc reset <path>` adopts the
corrected default, and the C-02 validator refuses the broken shape on the next edit.

## Deprecated-API migrations

None. The addon calls no deprecated API; `GetAddOnMetadata` was already routed through
`core/Compat.lua` before this cycle and is unchanged.

## Performance impact

| Measure | Before | After | Method |
|---|---|---|---|
| Lua memory after login | _record_ | _record_ | `/run collectgarbage("collect"); print(collectgarbage("count"))` |
| PrettyChat load CPU | _record_ | _record_ | `/console scriptProfile 1` → `/reload` → `GetAddOnCPUUsage("PrettyChat")` |
| Shipped package size | _record_ | _record_ | packaged zip, before/after C-03 |
| Per-write allocations | 9 tables + 9 sorts | 0 | code inspection + `tests/test_apply.lua` |

Expected direction: memory down by roughly the size of a 22,879-entry string table; package smaller
by ~1.9 MB; per-write ordering work eliminated.

## Known follow-ups

- **Wording pass on the ~81 default templates** — GitHub issue #1, already deferred in
  `docs/pending/LEDGER.md` (ISS-01). C-01 fixed correctness, not taste.
- **User-defined "Custom" replacement source** — GitHub issue #2 (ISS-02); real feature work.
- **Per-character / per-realm profiles** — declined by decision (DOC-03); unchanged here.
- **Cross-registered globals resolve last-writer-wins** — documented limitation (DOC-05); C-05 makes
  the winner deterministic in one place rather than four, but does not remove the ambiguity.
- **U-01 (F-016)** — the LibKa0s comment cross-references; lands in the library repo plus a re-vendor
  commit here, tracked separately in `04_EXECUTION_PLAN.md` M5.

## Verification evidence

- `03_SMOKE_TESTS.md` with its sign-off table completed (sections C-01…C-08, regression R-01…R-11,
  localization sanity on a deDE client, perf spot-checks).
- Headless gate: `lua tests/run.lua` green and `luacheck .` clean on every commit (baseline at review
  time: 255/255 passing, 0 warnings / 0 errors in 17 files).
- Commit range / PR: _record here_.

## Suggested commit message / PR description

```
fix: correct two Blizzard-incompatible templates and validate format strings at the write seam

Two shipped replacement templates declared conversions Blizzard's own format call does not
pass (F-001), raising `bad argument #N to 'format'` inside the game's message path. Neither
the panel Preview nor `/pc test` could show it, because both built their sample arguments
from the template under test instead of from the original (F-002) — so the addon's preview
feature gave false assurance for exactly the failure its README tells users to look for.

- defaults: match Blizzard's argument list on both reputation templates (F-001, F-011)
- schema: validate a format string's conversion signature at the single write seam; refuse
  with a reason instead of storing a value the game cannot honor (F-002)
- panel: read the original from the live LOCALIZED snapshot, not the shipped enUS dump —
  correct on every client, and ~1.9 MB / ~22,900 table entries lighter per session (F-003)
- core: snapshot the Blizzard originals once, with a sentinel for absent keys, so a
  disable/enable cycle cannot record our own strings as Blizzard's (F-006)
- schema: one ordered name index and one category partition; one apply/notify/log tail for
  the three bulk resets (F-007, F-008, F-009)
- i18n: localize the remaining user-facing strings with parameterized keys; drop the one
  trailing colon (F-004, F-005)
- docs/naming: retire the Config.lua references, the §4.5 cross-ref and the stale TODO.md
  mention; NS.Config -> NS.Panel (F-010, F-012, F-013, F-014, F-015)

No SavedVariables schema change. Review: docs/reviews/2026-08-03/.
```
