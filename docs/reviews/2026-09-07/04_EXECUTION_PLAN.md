# 04 — Execution plan

Implements `02_PROPOSED_CHANGES.md`. Four milestones, ordered so the riskiest behaviour change lands
behind a characterization test and the documentation corrections land last, when the code they
describe has stopped moving.

**Standing constraints for every task below.**

- The commit gate is `luacheck .` clean **and** `lua5.1 tests/run.lua` green. Commit only on green
  (`versioning-git`). Today's baseline: **0/0 lint, 300/300 tests**.
- Never edit anything under `libs/` or `tests/_kit/`. There are no upstream findings in this review,
  so no task touches either — and if one appears to need to, that is the wrong task.
- Never hand-edit `docs/test-cases.md`; regenerate with `lua5.1 tests/run.lua --list`. It moves in
  the **same commit** as the change that moved the count, together with the README `[tests]` badge
  (`testing-§4`).
- Never regenerate `docs/automated-tests/` here. That is the release checkpoint
  (`automated-tests-§4`).
- Never delete or rewrite a frozen bundle under `docs/audits/` or `docs/automated-tests/`.

---

## Milestone M1 — Make the format invariant enforceable

**Done when:** `NS.ConversionSequence` is published, `tests/test_defaults.lua`'s 81-default
assertions pass **unchanged** against it, and the suite is green at the same count as today (300).

| Task | Owner role | Findings / changes | Files touched |
|---|---|---|---|
| **T1.1** | lua-refactorer | `PRETTYCHAT-R-08` / PC-C-01 | `modules/Override.lua`, `tests/test_defaults.lua` |

**T1.1 notes.** This is a **pure move**, and `tests/test_defaults.lua:221-258` is its characterization
test — those assertions are the only proof the parser behaves identically after relocation, so they
must not be edited in this task. Reconcile the parser with `buildSampleArgs`' existing printf walk
(`modules/Override.lua:253-279`) only far enough to share the pattern; do not merge the two functions
in this commit. Pass count does **not** move.

**Checkpoint C1 (human).** Confirm `git diff` shows the parser body byte-identical apart from the
`local` → `NS.` rename and the doc comment, and that the suite still reports `300 passed`.

---

## Milestone M2 — The two behaviour changes

**Done when:** a mismatched format is refused on both surfaces, a missing global restores, the suite
is green at its **new** count, and `docs/test-cases.md` + the README badge have moved in the same
commits.

| Task | Owner role | Findings / changes | Files touched |
|---|---|---|---|
| **T2.1** | lua-feature | `PRETTYCHAT-R-01` / PC-C-02 | `modules/Override.lua`, `settings/Schema.lua`, `locales/enUS.lua`, `tests/test_schema.lua`, `docs/test-cases.md`, `README.md` |
| **T2.2** | lua-bugfix | `PRETTYCHAT-R-07` / PC-C-04 | `modules/Override.lua`, `core/PrettyChat.lua`, `tests/test_apply.lua`, `docs/test-cases.md`, `README.md` |
| **T2.3** | lua-bugfix | `PRETTYCHAT-R-12` / PC-C-05 | `core/PrettyChat.lua` |

**Concurrency.** T2.1 and T2.2 **both touch `modules/Override.lua`** and both move
`docs/test-cases.md` and `README.md` → **must serialize**, T2.1 first (it is the one whose refusal
message needs review time). T2.2 and T2.3 **both touch `core/PrettyChat.lua`** → **must serialize**.
Net: T2.1 → T2.2 → T2.3, strictly sequential. Nothing in M2 is parallelizable.

**T2.1 notes.** Write the tests first (`testing-§2`, TDD): four cases — surplus conversions refused
and nothing stored; a truncating format accepted; a type mismatch refused; an unknown reference
accepted. Then the guard. The refusal message must name the **expected** sequence, and it must be
routed through `NS.L` with a `%s` (`localization-§1`), not concatenated. Regenerate the inventory and
move the badge in the same commit.

**T2.2 notes.** Add the mock-side case that omits one global from the seeded originals
(`tests/loader.lua`'s `opts.mock` hook is how — do **not** hand-stub `originalStrings`). The
`[Init]` count line is one summary, never per-global (`debug-logging-§9`).

**Checkpoint C2 (human).** Read the refusal message as a player would. Then execute
`03_SMOKE_TESTS.md` **SMOKE-01** and **SMOKE-05** in-client before M3 starts — T2.1 changes what a
shipping verb accepts, and that is the one change in this plan a suite cannot fully vouch for.

---

## Milestone M3 — Adopt the library's landing renderer

**Done when:** `settings/Panel.lua` contains no private landing body, the Options stub declares
`BuildLandingPage`, `tests/test_panel.lua`'s two landing cases are green **without being rewritten**,
and SMOKE-02 has passed in-client.

| Task | Owner role | Findings / changes | Files touched |
|---|---|---|---|
| **T3.1** | libka0s-adopter | `PRETTYCHAT-R-02` / PC-C-03 | `settings/Panel.lua`, `settings/OptionsSetup.lua` |
| **T3.2** | lua-refactorer | follow-on of PC-C-03 | `core/Constants.lua`, `tests/test_constants.lua` (only if `SECTION_TOP_SPACER` / `SECTION_BOTTOM_SPACER` become unreferenced) |

**Concurrency.** T3.1 and T3.2 touch disjoint files but T3.2 **depends on** T3.1's result (whether
the constants still have a caller) → serialize. M3 as a whole touches `settings/Panel.lua`, which no
M2 task touches, so **M3 could run in parallel with M2** if two agents are available — but see the
checkpoint note: reviewing a visual change and a behaviour change in the same pass is how one hides
the other, so serializing is preferred.

**T3.1 notes.** The acceptance criterion is that `tests/test_panel.lua`'s *"the parent page lists
every slash command through the one row formatter"* and *"the parent page shows the TOC tagline"*
stay green **as written**. If either needs editing, the adoption changed the page's content, which it
must not — stop and re-read `libs/LibKa0s/OptionsWidgets.lua:1275-1299` for the `spec` shape. Do not
add an assertion about the texture to the suite: the widget mock has no real frame, so it could only
assert that a callback was registered, not that it hides anything. That check is SMOKE-02's, and it
belongs in the client.

**Checkpoint C3 (human).** Execute **SMOKE-02** in full, including the five landing→Categories cycles
and the other-addon check. Screenshot the landing page before and after for the spacing comparison.

---

## Milestone M4 — Make the record true

**Done when:** the `performance-§12` sweep reproduces, the register row and the `ARCHITECTURE.md`
invariant state what is actually checked, and four stale comments are corrected. No frozen bundle is
touched.

| Task | Owner role | Findings / changes | Files touched |
|---|---|---|---|
| **T4.1** | docs-maintainer | `PRETTYCHAT-R-03` / PC-C-06 | `docs/performance.md` |
| **T4.2** | docs-maintainer | `PRETTYCHAT-R-04`, `-R-09`, `-R-10` / PC-C-07 | `docs/ARCHITECTURE.md`, `tests/test_locale.lua` (comment), `core/MediaSetup.lua` (comment), `tests/test_vendor_sync.lua` (comment) |
| **T4.3** | ux-cleanup | `PRETTYCHAT-R-06` / PC-C-08 | `settings/Slash.lua`, `locales/enUS.lua`, `tests/test_slash.lua`, `docs/test-cases.md`, `README.md` |
| **T4.4** | docs-maintainer | `PRETTYCHAT-R-05` / PC-C-09 | none — a note carried into `05_FINAL_SUMMARY.md` |

**Concurrency.** T4.1 and T4.2 touch disjoint files → **parallelizable**. T4.3 touches
`locales/enUS.lua`, which T2.1 also touched, and `docs/test-cases.md` / `README.md`, which T2.1 and
T2.2 also touched → **must run after M2 is complete**, and must not overlap T4.2, which edits
`tests/test_locale.lua`'s header while T4.3 adds manifest keys the same suite validates → **serialize
T4.2 before T4.3**.

**T4.1 must run last of the doc tasks in practice**, or at least after M2 and M3 are merged: the sweep
it pastes has to reflect the final tree. If T4.1 runs before M3, re-run the sweep after M3 and amend.

**T4.3 notes.** This is the widest-touching task and the least valuable — it is structural, not
behavioural, and the English-only deviation stands either way. If time is short, defer it and record
the deferral in `05_FINAL_SUMMARY.md`'s known-follow-ups; T4.2's correction of the register is what
actually closes the misleading claim.

**Checkpoint C4 (human).** Re-run the sweep in `docs/performance.md` from the repo root and diff its
output against the pasted block character for character. Then run **SMOKE-06** if T4.3 landed.

---

## Critical path

```
T1.1 ──▶ T2.1 ──▶ T2.2 ──▶ T2.3 ──▶ [C2 + SMOKE-01, SMOKE-05]
                                        │
                                        ▼
                                  T3.1 ──▶ T3.2 ──▶ [C3 + SMOKE-02]
                                        │
                                        ▼
                        ┌───────────────┴───────────────┐
                        ▼                               ▼
                      T4.2 ──▶ T4.3                   T4.1        (T4.1 ∥ T4.2)
                        │                               │
                        └───────────────┬───────────────┘
                                        ▼
                                [C4 + SMOKE-06] ──▶ Regression R1–R13
```

**Serialization callouts, explicitly.**

| Pair | Shared file | Verdict |
|---|---|---|
| T1.1 ↔ T2.1 | `modules/Override.lua` | serialize (T2.1 depends on T1.1's output) |
| T2.1 ↔ T2.2 | `modules/Override.lua`, `docs/test-cases.md`, `README.md` | serialize |
| T2.2 ↔ T2.3 | `core/PrettyChat.lua` | serialize |
| T2.1 ↔ T4.3 | `locales/enUS.lua`, `docs/test-cases.md`, `README.md` | serialize (M2 fully before T4.3) |
| T4.2 ↔ T4.3 | `tests/test_locale.lua` / `locales/enUS.lua` | serialize (T4.2 first) |
| T3.1 ↔ T4.1 | none | **parallelizable** |
| T4.1 ↔ T4.2 | none | **parallelizable** |

---

## Commit strategy

One commit per task, each green before it lands. Suggested messages:

```
refactor(override): one published conversion-sequence parser, three callers

The check that a format's printf sequence matches Blizzard's lived only in
tests/test_defaults.lua, so the one input it exists to protect -- what a player
types -- was unchecked. Moved beside buildSampleArgs and published as
NS.ConversionSequence; the suite's 81-default assertions are the characterization
and are unchanged. PRETTYCHAT-R-08.
```

```
fix(schema): refuse a format Blizzard cannot fill

A replacement asking for more conversions than Blizzard passes made string.format
raise inside Blizzard's own chat handler, on every matching line, for the rest of
the session -- and the Preview could not warn, because it synthesizes its arguments
from the format under test. Schema.Set now compares against this client's OnEnable
snapshot and refuses, naming the expected sequence. Both surfaces get it, because
both already route through the one seam. PRETTYCHAT-R-01.
```

```
fix(settings): the landing page is the library's renderer, not a copy of it

buildParentBody was a private copy of O.BuildLandingPage, and the copy never hid
its logo Texture on release -- so the 300px logo rode AceGUI's pooled SimpleGroup
frame into whatever acquired it next, in this addon or another. The library fixed
exactly that at OptionsWidgets.lua:323 and documents the bug in place. Adopted;
the stub declares the new member as a no-op. PRETTYCHAT-R-02.
```

```
fix(override): restore on `~= nil`, not on truthiness

A GLOBALNAME this client does not define snapshots as nil, so the apply branch wrote
it and the restore branch skipped it -- the override survived every subsequent
disable for the whole session. No shipping Retail client reaches it today; the first
string Blizzard retires does. PRETTYCHAT-R-07.
```

```
docs: re-run the performance-§12 sweep and say what it now returns

The page says its sweep is the thing to re-run before trusting it. Re-run, it
returns settings/Panel.lua's C_Timer.After, which the recorded result does not
carry -- and the recorded result lists an UnregisterEvent line the stated
case-sensitive regex cannot produce. Criterion (a) still holds and the row is
unchanged; its evidence now reproduces. PRETTYCHAT-R-03.
```

```
docs: the locale drift cases cannot see an unwrapped string, and said they could

The scan builds its call-site set from L["…"] literals, so a string that was never
wrapped cannot redden anything. ARCHITECTURE's invariant and the localization-§1
row both claimed otherwise, and cited the suite as proof. Corrected both to state
what is routed and what is not; the English-only shipping decision is unchanged.
PRETTYCHAT-R-04, PRETTYCHAT-R-09, PRETTYCHAT-R-10.
```

Trailer on every commit, per this repo's convention:

```
Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
```
