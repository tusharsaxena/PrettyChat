# 04 — Technical Design (remediation)

**Run date:** 2026-08-04 · **Standard:** v2.17.1 (2026-08-03)

Design for closing the deviations in `02_DEVIATIONS.md`. Keyed to deviation IDs throughout.
This audit is read-only; nothing here has been applied.

---

## The shape of the work

Nineteen deviations, but they are not nineteen independent problems. They fall into **five**
work items, and one of them — the performance decision — gates six deviations on a single
question that only the user can answer.

| Item | Deviations | Nature |
|---|---|---|
| **A. Resolve the Perf decline** | PC-40, PC-41, PC-42, PC-43, PC-44, PC-45 | **Decision first, then code.** Blocked on the user. |
| **B. README hygiene** | PC-46, PC-47 | Text edits, zero risk. |
| **C. `CLAUDE.md` back to a stub** | PC-48, and it relocates the records behind PC-23/PC-25/PC-27/PC-51/PC-54 | Doc move, zero code risk. |
| **D. The generated-data folder** | PC-25, PC-49 | Mechanical regeneration **or** a widened written exception. |
| **E. Small doc/architecture gaps** | PC-50, PC-53, PC-55 | Two doc edits and one design question. |
| *(no action)* | PC-23, PC-27, PC-51, PC-54, PC-52, PC-56 | Settled deviations and upstream items. |

---

## A. The performance decline (PC-40 → PC-45)

### The question that has to be answered first

`performance` states its adoption strength as **MUST for the wiring** — vendor the lib, create
one instance at load, expose the `perf` verb, declare `<Addon>PerfDB`, implement
`suspend`/`resume` — and **SHOULD for coverage**, explicitly conceding that *"some addons have
almost no hot path."* PrettyChat's `LIBKA0S-12` argues the decline on coverage grounds (every
bucket reads `0.000`) and on a genuine harm (suspend flips the player's chat formatting
mid-fight). The first argument is an argument about **coverage**, which the standard already
concedes; the second is an argument about **the suspend contract**, which the standard does not.

So the honest reading is: PrettyChat has a real objection to `performance-§6`, and no objection
at all to §1/§4/§5 beyond *"it would be empty."* That points at a narrower fix than either
"wire it all" or "decline it all."

### Option A1 — wire the harness with an empty bucket set (recommended)

Do the wiring, skip the coverage, and make `suspend` honest.

- **`core/PerfSetup.lua`** (new), TOC-listed in `# Core` **before** any module taking `NS.Perf`
  as an upvalue — in practice immediately after `core/CoreSetup.lua`, since nothing takes such
  an upvalue today. Shape follows the standard's worked example: silent lookup
  (`LibStub("LibKa0s-Perf-1.0", true)`), `NS.Perf = lib:New(descriptor)` **only** `if lib`, and
  a member-answering stub otherwise — `on = false`, `Note`, and whatever the slash layer calls.
- **Descriptor:** `buckets = {}` — an empty, *honest* set. `performance-§3` forbids a bucket no
  bracket reaches ("a lie in every report"); it does not require inventing one. `svName =
  "PrettyChatPerfDB"`.
- **`suspend` / `resume`:** implement them, and implement them as **what inert actually means
  here**. PrettyChat's only runtime effect is the `_G[GLOBALNAME]` assignment, so `suspend`
  restores Blizzard's originals and `resume` re-runs `ApplyStrings` from **current** state —
  both already exist as `PrettyChat:ApplyStrings()` with the master toggle off/on
  (`modules/Override.lua:50-88`). This is a ~10-line implementation on top of code that ships.
  - **The user-visible flip is real and must be surfaced, not hidden.** The `LIBKA0S-12`
    objection stands: a suspended arm shows Blizzard's stock chat lines. Mitigation is a
    warning line at the head of the guided run — *"suspend restores Blizzard's chat formatting
    for the duration of the second arm"* — printed through `NS.Print`. That converts a surprise
    into a documented property, which is what the two-arm protocol needs anyway.
- **PC-41:** `## SavedVariables: PrettyChatDB, PrettyChatPerfDB` (`PrettyChat.toc:7`).
- **PC-42:** one triple in `NS.COMMANDS` between `debug` and `version`, forwarding to the
  instance's command entry point and printing the returned lines through `NS.Print` — the lib
  returns lines, the host prints them (`performance-§4`).
- **PC-45:** `debugprofilestop` → `read_globals`; `PrettyChatPerfDB` → `globals` with a comment.
- **PC-43:** `tests/perf.lua`, outside the gate, with the **zero-overhead scenario** measuring
  the `ApplyStrings` pass with capture off against the same pass with the instrumentation
  absent. Deterministic quantities only — allocations and call counts, never wall-clock.
- **PC-44:** `docs/performance.md` (what is and is not bracketed, and **why the bucket set is
  empty** — that page is the right home for the LIBKA0S-12 reasoning) and
  `docs/perf-runs/README.md`.
- **Tests** (`testing-§8`): descriptor well-formed; **suspend genuinely makes the addon inert**
  (assert every overridden `_G[GLOBALNAME]` is back to its snapshot) and resume restores from
  current state; the **degraded path** exercised by loading with `Perf.lua` omitted from
  `tests/loader.lua`'s explicit list — a real scenario, not a hand-written stub.

**Risk:** low. Nothing in the addon's runtime path changes; `NS.Perf.on` is false unless a
capture is running, and the bracket idiom is not introduced at all (no buckets). The one
behavioral addition is `suspend`, which is only reachable from an explicit `/pc perf` run.

**Cost:** roughly one file, one TOC line, one COMMANDS row, two `.luacheckrc` lines, two docs,
one scenario runner and four test cases.

### Option A2 — take the decline upstream

If the user's position is that an addon with **no execution path after login** should not be
required to carry the harness, that is a **change to the standard**, not a local decision — and
`CLAUDE.md`'s own compliance section says exactly that. The change would be a carve-out in
`performance`'s adoption-strength paragraph, e.g. *"an addon that registers no events, timers or
tickers MAY decline the wiring, recording the decision in `docs/`."* PC-40…PC-45 then close as
compliant rather than as deviations.

**This is a legitimate outcome and should be put to the user, not assumed away.** The evidence
supporting it is already gathered (`03_EVIDENCE.md` §PC-40, which independently confirms the
zero-hot-path premise).

**What is not acceptable is the status quo**: a MUST silently unmet, recorded only in a ledger
row inside the addon, with the standard unaware of the case.

### Ordering constraint

PC-41 → PC-45 all **block on** the A1/A2 choice. Do not part-implement: adding
`PrettyChatPerfDB` to the TOC without a writer produces an SV global nothing writes, which is
worse than its absence.

---

## B. README hygiene (PC-46, PC-47)

**PC-46** — one-character-class edit at `README.md:116`: `` `/pc reset <setting>` `` →
`` `/pc reset setting` ``, matching `README.md:63`. Do **not** run a blanket `<…>` sweep: the
README contains no deliberate HTML today, but a sweep is the documented way this fix
over-corrects (`documentation-§1`).

**PC-47** — two moves:

- `## Unreleased` (`README.md:15-19`) holds three genuine user-facing highlights for work
  already merged. They belong in `## What's new` and in a Version History row — which means the
  clean fix is to **fold them in at the next version bump** (`wow-addon:bump-version` does this
  as one change, per `documentation-§1`'s roll-forward rule). If a bump is not imminent, move
  them into `## What's new in 1.4.0` now and delete the section; a README section that exists
  only between releases is the drift the fixed section list exists to prevent.
- `## Credits` (`README.md:120-122`) — a one-line LibKa0s attribution. Move it into the
  Description paragraph or `docs/ARCHITECTURE.md § External dependencies`, which already exists
  (`docs/ARCHITECTURE.md:137`) and is the contributor-facing home.

**Risk:** none. **Verification:** re-read the section headings against `documentation-§1`'s
twelve-item list.

---

## C. `CLAUDE.md` back to a stub (PC-48)

The file's content is good; its **location** is wrong. Six accepted-deviation records, a code-
invariants bullet and seven guardrails have accreted onto a document the standard defines as a
short pointer.

**Design:** create **`docs/deviations.md`** — a topic-detail doc, explicitly permitted by
`documentation-§3` — as the single home for accepted deviations, one section per ID, each
carrying the section violated, the reason, and the upstream item where one exists. Seed it from
`CLAUDE.md:8-13` **verbatim** (the prose is good; nothing is rewritten) and cross-reference the
audit IDs: PC-25, PC-49 (generated data), PC-54 (font), PC-27 (branding), PC-23 (editor),
PC-51 (harness), and the `toc-file-§5`/`layout-§1` conflict already raised as
WowAddonStandards#2.

Then reduce root `CLAUDE.md` to the five mandated items **in order**:

1. `# CLAUDE.md — Ka0s Pretty Chat`
2. adherence line + standards URL
3. `## Standards compliance (read first)` — **unchanged, verbatim in substance**
4. the read-the-docs pointer list — `docs/ARCHITECTURE.md`, `docs/testing.md`, then the topic
   docs **including the new `docs/deviations.md`**
5. the green-gate line

The `## The docs/ set — there is no agent-context.md` section (`CLAUDE.md:33-48`) is a
judgment call: it is not one of the five, but it is load-bearing — it stops an agent
"restoring" a file anti-pattern #49 forbids, and the repo's frozen history still names it.
**Recommendation: keep it**, compressed to two or three lines, as part of item 4's pointer list.
Its value is precisely that it lives in the working-context document.

The three non-negotiables worth keeping in the stub (they are not a brief, they are the guard
rails an agent needs before its first edit) fold into item 5's neighborhood as short bullets:
never edit `libs/` or `tests/_kit/`; never hand a LibKa0s descriptor `NS.L`; keep the test
inventory and badge in lockstep. Everything else moves to `docs/`.

**Risk:** none to code. **Verification:** `documentation-§2`'s five items present, in order;
`documentation-§6`'s three places still complete (the TOC and README halves are untouched).

---

## D. The generated-data folder (PC-25, PC-49)

Two routes, and they close different amounts.

### D1 — Relocate and re-split (closes both)

Move the ten runtime chunks to **`defaults/globalstrings/`** — lowercase, inside the skeleton,
under the folder whose job is data tables (`layout-§1` names `defaults/` for "Retail data
tables"). The `# GlobalStrings` TOC section then disappears into `# Defaults`, closing PC-25's
TOC half at the same time. Re-run `split_globalstrings.py` with a chunk target of ~1400 lines
(~17 chunks instead of 10) to close PC-49.

Keep the dev-only source dump and the splitter **out** of `defaults/` — they are build inputs,
not addon source. `_dev/` is already an ignored path in `.pkgmeta:14`, which makes
`_dev/globalstrings/` their natural home and removes three `.pkgmeta` ignore lines
(`:21-23`) as a side effect.

**Risk:** low but not zero — it touches ~1.9 MB of TOC-loaded content and every path in
`tests/loader.lua`'s derivation. It is fully covered: the runner derives its list from the TOC
(`Loader.tocFiles`), so the load list follows automatically, and `test_defaults.lua` /
`test_override.lua` assert on the resulting `NS.Defaults` content. Green gate is the check.

**Cost:** one script run, one TOC section rewrite, one `.pkgmeta` simplification.

### D2 — Widen the written exception (closes neither, but makes them honest)

Keep the layout and extend the `CLAUDE.md:8` record (moving to `docs/deviations.md` under item
C) to name **all three** rules it actually breaks — `layout-§1` (root folder **and** the 1500-LOC
cap), `layout-§2` (PascalCase subfolder), `toc-file-§5` (the seventh TOC section) — instead of
the current single unqualified reference to `layout`. The deviation then stops being partly
implicit.

**Recommendation: D1.** The exception exists because "the modular layout has no home for bulk
generated reference data" — but `defaults/` **is** that home, and the standard's own layout
sketch says so (`defaults/ … Spells.lua / Data*.lua -- Retail data tables`). The exception looks
like it survived a restructure rather than being re-derived after it.

---

## E. Small gaps (PC-50, PC-53, PC-55)

**PC-53** — add a `## Message Bus` heading to `docs/ARCHITECTURE.md`, between
`## Settings Schema` and `## Slash Commands`, carrying the existing sentence from `:119`. One
edit; do it whichever way PC-50 lands.

**PC-55** — `lizard core defaults settings modules locales > docs/complexity.md`, with a header
line stating it is generated and how. `performance-§10` explicitly forbids gating commits on it.
If `lizard` is not installed locally, the correct outcome is to record that — a stale or absent
report is not non-compliance, but it has never been generated at all.

**PC-50** — the real question is whether this addon should have a bus. Two defensible answers:

- **E1 (minimal, recommended):** introduce **one** message,
  `Ka0s_PrettyChat_SettingsChanged`, sent from `Schema.Set` and the three reset paths, with
  `settings/Panel.lua`'s refresher registration as the single receiver on its own
  `NS.NewBusTarget()` embed. That converts four direct `NS.Schema.NotifyPanelChange` /
  `NS.Helpers.RefreshScalars` call sites into one producer and one consumer, satisfies
  `architecture-§4` literally, and gives PC-53's new section something to document.
  **Requires the bus test mock to key by target and fan out** (`architecture-§4`,
  anti-pattern #33) — `tests/_kit/mock_base.lua` already does this, so the coverage is free.
- **E2:** record the absence as an accepted deviation in `docs/deviations.md`, with the
  single-feature-module rationale and the observation that the clobber hazard
  `architecture-§4` exists to prevent cannot arise with one receiver.

E1 costs perhaps thirty lines and removes a standing MUST; E2 costs a paragraph. Either is
honest. What is not honest is the current state, where `docs/ARCHITECTURE.md` states the fact
without classifying it.

---

## Cross-cutting constraints

- **Never edit `libs/` or `tests/_kit/`.** Both diffs are currently empty (`03_EVIDENCE.md`
  §1.4) and that is a property to preserve. The one British spelling found this run
  (`tests/_kit/README.md:119`) is **upstream's to fix** — patching it here would break byte
  identity and be silently reverted by the next re-vendor.
- **Green gate on every commit** — `lua tests/run.lua` (currently 255/255) and `luacheck .`
  (currently 0/0). Any change that moves the case count must regenerate `docs/test-cases.md`
  **and** the README `[tests]` badge in the same change (`testing-§5`).
- **TDD.** Items A and E1 change behavior and take failing tests first. Items B, C, D2 and E's
  doc halves do not.
- **Trunk-based, no branch, no push** unless the user asks (`versioning-git`).
- **Two items are upstream, not local:** LIBKA0S-01 (isolated-environment mode, behind PC-51)
  and LIBKA0S-06 (a third `RenderGrid` ratio, behind PC-23). Neither should be worked around
  locally — a host-side workaround for a library gap is the drift `anti-patterns` #47 exists to
  end.
</content>
