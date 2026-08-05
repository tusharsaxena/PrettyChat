# 04 — Technical Design (Ka0s Pretty Chat)

**Run date:** 2026-08-05 · **Standard:** v2.21.0 · Keyed to the IDs in `02_DEVIATIONS.md`.

This document designs the remediation. It changes nothing — `05_EXECUTION_PLAN.md` orders it and a
separate engagement executes it.

---

## D1. The perf cluster — PC-40, PC-41, PC-42, PC-43, PC-44, PC-45

Six MUSTs with one root: `LibKa0s-Perf-1.0` is vendored and shipped to every player and never wired.
They cannot be closed independently — PC-41…PC-45 are all consequences of PC-40 — so the design is one
decision followed by five mechanical follow-ons.

### The decision (PC-40)

The recorded decline (`CLAUDE.md:6`, `docs/pending/LEDGER.md:66`) rests on two facts this audit
verified: the addon registers **no** events, timers or tickers (`docs/ARCHITECTURE.md:119`), and
`suspend` would restore Blizzard's raw formats mid-fight for a capture that can only read `0.000`.
Both are true. Neither makes the wiring optional — `performance`'s adoption strength is *"**MUST** for
the wiring … **SHOULD** for coverage"*, and the wiring is what makes *"run `/pc perf` and send me the
JSON"* true of **any** Ka0s addon.

**Route A — wire it minimally (recommended).** Honors the MUST and keeps the decline's substance,
because the decline is about *coverage*, which stays at zero.

- New `core/PerfSetup.lua`, TOC slot after `core/CoreSetup.lua` and before any consumer
  (`toc-file-§5` shows `core\PerfSetup.lua` in `# Core`). Shape mandated by `performance-§1`:
  ```lua
  local lib = LibStub and LibStub("LibKa0s-Perf-1.0", true)
  if not lib then  -- member-answering stub: .on, .Note, and whatever the slash layer touches
      NS.Perf = { on = false, Note = function() end, … }
      return
  end
  NS.Perf = lib:New({ savedVariable = "PrettyChatPerfDB", buckets = { … }, suspend = …, resume = … })
  ```
- **Buckets:** exactly one, `applyStrings`, bracketing `PrettyChat:ApplyStrings` — the addon's only
  repeated work path. `performance-§3` forbids declaring a bucket no bracket reaches, so declare one
  and bracket it, rather than declaring an empty set. The bracket uses the mandated idiom verbatim
  (`local t0 = Perf.on and debugprofilestop()` … `if t0 then Perf.Note("applyStrings", debugprofilestop() - t0) end`)
  with `local Perf = NS.Perf` as a load-time upvalue in `modules/Override.lua`.
- **`suspend`/`resume` (`performance-§6`):** the honest implementation for this addon is *restore the
  Blizzard originals from `originalStrings`, and re-apply on resume* — that **is** "does our code run?"
  for an addon whose entire runtime effect is the contents of `_G[GLOBALNAME]`. The decline's real
  objection (visible chat-format flip mid-fight) is a **UX** cost of running a capture, not a reason the
  contract cannot be implemented; document it in `docs/performance.md` as "do not capture during
  progression raiding" rather than leaving `suspend` unimplemented.

**Route B — take it upstream.** If the wiring is still judged wrong, the decline must become a
**standard change** (a carve-out in `performance` for addons with no runtime execution path), filed as
an issue on WowAddonStandards like the `toc-file-§5` conflict already was
(`CLAUDE.md:13` → WowAddonStandards#2). Route B leaves PC-40…PC-45 open with an owner and a link, which
is a materially different state from a local decision.

### The follow-ons (mechanical once PC-40 lands)

| ID | Change |
|---|---|
| PC-41 | `PrettyChat.toc:7` → `## SavedVariables: PrettyChatDB, PrettyChatPerfDB` (that order), and hand `"PrettyChatPerfDB"` to the descriptor. |
| PC-42 | One triple in `settings/Slash.lua`'s `COMMANDS` between `test` and `debug`: `{"perf", L["…"], function(rest) … end}` forwarding to the lib's command entry point and printing the **returned lines** through `NS.Print` — `performance-§4` forbids the library registering the verb itself. `docs/test-cases.md` and the README `Tests` badge move in the same change; `README.md`'s slash table and `docs/ARCHITECTURE.md:115` gain the row. |
| PC-43 | New `tests/perf.lua` — **outside** the green gate (`testing-§7`), asserting only deterministic quantities: the zero-overhead scenario (`Perf.on = false`, N calls through the bracketed path, assert **zero** allocations attributable to the bracket and zero `Note` calls), plus a bucket-reachability assertion that `applyStrings` is actually hit when capture is on (`performance-§3`). This also converts the standing `perf: skip` into a `pass`, which matters for PC-57's release gate. |
| PC-44 | New `docs/performance.md` (what is bracketed and why; how to run `/pc perf`; how to read the report; what the harness cannot resolve — pointing at the library for the shared protocol rather than restating it) and `docs/perf-runs/README.md` (in-game record naming, schema summary, a pointer to the library's field-by-field contract, and the note that offline runs live in `docs/automated-tests/`). |
| PC-45 | `.luacheckrc` — `debugprofilestop` into `read_globals`, `PrettyChatPerfDB` into `globals` with a justifying comment (`lint` MUSTs the comment). |

**Risks.** The `suspend` arm is the only behavior-visible change; it is reachable only from `/pc perf`
and must be covered by a smoke test (the panel and live chat are outside headless reach). Nothing else
in the cluster touches a code path the player can reach.

---

## D2. The v2.21.0 release gate — PC-57

Documentation-only, no code. Three files say the same half-truth and must move together, in the
standard's own terms, so the two checkpoints are never collapsed:

1. `docs/testing.md` — after "**At release, not at commit.**" (`:120`), add the gate: the tag requires
   all four suites at `pass` **and** `suites.complexity.warnings == 0` (zero functions above CCN 15),
   evaluated by `/wow-addon:bump-version` from the run's `manifest.json` — **not** by the runner, whose
   exit code and `gating: false` flags stay exactly as they are because the same vendored script is the
   commit gate. A `skip` blocks as **NOT EVALUATED**, not as a pass. Keep the existing
   "`perf` and `complexity` never fail a **run**" sentence verbatim — it is still true and the standard
   retains it deliberately — and add "run" emphasis so the two statements cannot be read as
   contradictory.
2. `docs/automated-tests/README.md` — same addition; add a **`Gates at release?`** column to the suite
   table so the table itself stops implying "never".
3. `docs/automated-tests/RESULTS.md` — **generated**, so this text belongs to the runner's template,
   not to a hand-edit. Two options: (a) if the vendored kit's template already carries the release-gate
   wording at a later revision, re-vendor `tests/_kit/` whole and regenerate; (b) if not, it is an
   upstream LibKa0s finding (like the review's F-007 duration bug) — file it, fix it there, re-vendor,
   regenerate. **Do not hand-edit `RESULTS.md`**: a generated file edited by hand reads as measured.

**This addon's specific case must be stated:** its `perf` skip is the standard's one narrow exception
(*"skipped because the addon ships no `tests/perf.lua`"* → passes, but **MUST** be said plainly in the
release notes). If PC-43 lands first, the exception disappears and the sentence changes to a plain
pass — so sequence PC-43 before the release-notes wording, or write both cases.

---

## D3. The root doc set — PC-46, PC-47, PC-48

**PC-46** is one character-level edit at `README.md:116`: `` `/pc reset <setting>` `` →
`` `/pc reset setting` ``. Do not run a blanket `<…>` sweep — `documentation-§1` explicitly protects
real HTML (`<br>`, `<code>`) — and confirm the grep set (`<setting>`, `<name>`, `<value>`, `<path>`)
returns nothing afterward.

**PC-47** is two moves, and one of them is scheduled rather than immediate:

- `## Credits` (`:120-122`) → fold the LibKa0s attribution sentence into the Description paragraph
  (`:11-13`) or into `docs/ARCHITECTURE.md`'s `## External dependencies`. The README is player-facing;
  a bundled-library note is not a player fact. Do this now.
- `## Unreleased` (`:15-19`) → its three bullets **are** the next release's highlights. They belong in
  `## What's new in <next>` and in the new top `## Version History` row, both of which
  `wow-addon:bump-version` writes. Deleting them now would lose written copy; carrying them under a
  non-canonical heading is the deviation. Design: move the three bullets verbatim into a
  `docs/pending/` note (or the bump command's staging input), delete the section, and let the bump
  restore them under the canonical heading. Sequence with the next version bump.

**PC-48** is a relocation, not a rewrite. The six accepted-deviation paragraphs (`CLAUDE.md:8-13`) are
genuinely valuable — they are the source of truth for what intentionally diverges — and
`documentation-§6` names `docs/` and the audit bundle as their home. Design:

- New `docs/deviations.md`: one section per accepted deviation, each carrying the existing prose
  **verbatim**, its `filename-§N` reference, and its audit ID (PC-23, PC-25, PC-27, PC-49, PC-51,
  PC-54) so the doc and this bundle are cross-linked. `docs/ARCHITECTURE.md`'s doc index gains a row.
- Root `CLAUDE.md` reduces to the five mandated items **in order**: H1 (`:1`), adherence line, then
  `## Standards compliance (read first)` **third** (the existing `:14-31` text moves up unchanged),
  then the read-the-docs pointer list (`:52`, extended with `docs/deviations.md`), then the green-gate
  line (`:59`). The eight guardrails at `:56-63` are invariants and belong in
  `docs/ARCHITECTURE.md`'s `## Invariants`, which already exists (`:89`) — except the green-gate line,
  which stays as item 5.
- Target: roughly 20–25 lines. Reference implementation named by the standard: the absorb-shield
  tracker's root `CLAUDE.md`.

**Risk:** `CLAUDE.md` is the file an agent loads as working context, so anything dropped rather than
moved is lost silently. Every removed line must land somewhere named in the pointer list, and the
pointer list must be checked to actually resolve.

---

## D4. Structural documentation — PC-53

Add `## Message Bus` to `docs/ARCHITECTURE.md` between `## Slash Commands` (`:113`) and
`## Event Subscriptions` (`:117`), carrying the sentence currently stranded at `:119` ("There is no
message bus.") plus the one-line reason (single feature module, zero event traffic). Move the sentence
rather than duplicating it. If PC-50 is ever closed by introducing a bus, this heading is where the
message table lands.

---

## D5. The unfalsifiable test — PC-58

`testing-§12`'s remedy is not to delete the case but to add one that **can** fail.

- Keep `tests/test_defaults.lua:107-114` and re-title it to name its real scope — it correctly pins
  that the **panel preview / `/pc test`** path renders every default, which is a genuine contract.
- Add a sibling case: for every override, extract the conversion sequence from the addon's default
  **and** from the Blizzard original (`NS.GlobalStrings[globalName]`, already loaded in the headless
  environment) with the same `%%…` scanner, and assert the two sequences are **equal in count, order
  and type**. That assertion is falsifiable by construction: `defaults/Defaults.lua:162-165` and
  `:190-193` redden it today.
- Factor the scanner out of `modules/Override.lua:171-197` into a named helper so the test and
  `buildSampleArgs` share one implementation rather than the test re-deriving it (a re-derived scanner
  is a second place to be wrong).
- `SHOULD`, per `testing-§12`: carry a one-line comment naming the mutation that reddens the new case.

**Ordering constraint:** this case goes red against the current `defaults/Defaults.lua`. It therefore
lands **with or after** the fix for the review's F-001/F-002, or as a deliberately-red TDD step —
never as a "fix the data quietly and add a green test" change, which would hide what the test is for.
Committing red violates `testing-§4`, so the two land in one change.

---

## D6. Localization coverage — PC-59

Four call sites, one shape. Move each fixed fragment into `locales/enUS.lua` as a **format key** and
interpolate the variable half:

| Site | Today | Design |
|---|---|---|
| `settings/Schema.lua:72` | `"Enable " .. category` | `L["Enable %s"]:format(category)` |
| `settings/Schema.lua:73` | `"Enable or disable all " .. category .. " string overrides."` | `L["Enable or disable all %s string overrides."]:format(category)` |
| `settings/Panel.lua:167-169` | concatenated shared-global tooltip | one `L[…]` key with a `%s` for the joined list |
| `settings/Panel.lua:392-394` | `"Reset all " .. category .. " strings to defaults."` | `L["Reset all %s strings to defaults."]:format(category)` |

Category names themselves stay untranslated — they are schema keys, not prose, and translating them
would break `/pc set Loot.enabled`. Say so in a comment at the point of interpolation, or the next
sweep will "fix" it.

Then correct `locales/enUS.lua:9-11` to describe what the manifest covers **and what it does not**
(category names; the three strings that moved into LibKa0s, already noted at `:13-20`).

**Risk:** a key added to `enUS` and not to a call site is invisible (the metatable returns the key), so
add the key and change the call site in the same edit, and let the existing `test_locale.lua` suite
assert that every new key is reachable.

---

## D7. Documented deviations — no code change

PC-23, PC-27, PC-49, PC-50, PC-51, PC-54 stay as they are. Two record-keeping edits are worth making
while D3 is open, since the records move to `docs/deviations.md` anyway:

- PC-25 / PC-49: extend the generated-data record to name `layout-§2` (folder casing), `toc-file-§5`
  (the TOC section) and `layout-§1`'s 1500-LOC cap (the unshipped dump) explicitly, so the accepted
  deviation covers the rules it actually breaks rather than the section it gestures at.
- PC-50: state the absence as a **classified accepted deviation** with the single-module rationale,
  not as a neutral fact. `docs/ARCHITECTURE.md:119` currently reads as a description; an audit reading
  it cannot tell whether the absence was decided or defaulted into.

PC-52 and PC-56 are upstream questions; the design is to file them, not to change the repo.

---

## Cross-cutting constraints

- **Nothing under `libs/` or `tests/_kit/` may be edited** (`library-stack-§7`, `testing-§1`). D2's
  `RESULTS.md` half and the review's F-007 are both **upstream** LibKa0s work followed by a whole-folder
  re-vendor as its own commit.
- **Every change commits green** — `lua tests/run.lua` and `luacheck .` (`testing-§4`,
  `versioning-git`). The commit gate is unchanged by any of this; only PC-57's *documentation* concerns
  the release gate.
- **Doc sync moves with code** (`documentation-§5`): a new `perf` verb touches `README.md`'s slash
  table, `docs/slash-commands.md`, `docs/ARCHITECTURE.md:115`, `docs/test-cases.md` and the README
  `Tests` badge in the **same** change.
- **Before the next release**, run the two vendor diffs this audit could not (`03_EVIDENCE.md` A6) and
  produce a full four-suite bundle with an `ANALYSIS.md`.
