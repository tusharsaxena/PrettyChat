# 04 — Execution plan

Five milestones. M1 is the only one that must ship soon; M4 lands in another repo entirely.

---

## M0 — Baseline (no code changes)

**Done when:** the reviewer's Step 0 numbers are reproduced on the implementer's machine, so any later
red is attributable to the work rather than to the environment.

| Task | Role | Findings | Files touched |
|---|---|---|---|
| T0.1 | any | — | none — run `luacheck .`, `lua5.1 tests/run.lua`, `lua5.1 tests/run.lua --list \| diff - docs/test-cases.md`, `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` |

**Exit criterion:** lint 0/0 over 17 files · tests 255/255 · `--list` identical to `docs/test-cases.md`
· lizard 528 functions, 0 warnings, max CCN 12.

---

## M1 — Correctness: the two broken defaults and the test that let them through

**Done when:** T-01, T-02 and T-03 in `03_SMOKE_TESTS.md` pass in-client, the headless suite is
256/256, and `docs/test-cases.md` + the README badge have moved in the same commit.

| Task | Role | Change / findings | Files touched |
|---|---|---|---|
| T1.1 | data-fixer | C-01 / F-001, F-002 | `defaults/Defaults.lua` |
| T1.2 | test-author | C-02 / F-003 | `tests/test_defaults.lua` |
| T1.3 | test-author | C-02 (artifact movement, `testing-§7`) | `docs/test-cases.md` (regenerated via `--list`, never hand-edited), `README.md` (badge 255 → 256) |

**Ordering:** T1.2 **before** T1.1 is strongly preferred — write the new case first, watch it go
**red** on the two `FACTION_STANDING_*` entries, then apply T1.1 and watch it go green. That
sequencing is the only cheap proof the new case is falsifiable, which is the entire point of replacing
the old one. T1.3 is mechanical and follows T1.1+T1.2 in the same commit.

**Serialization:** T1.1 and T1.2 touch disjoint files but are logically coupled through the red→green
proof — **serialize** them.

---

## M2 — One source of truth for "the Blizzard original"

**Done when:** T-04 passes on enUS and **L-01 passes on deDE/frFR** — the non-enUS arm is the one that
actually discriminates the fix.

| Task | Role | Change / findings | Files touched |
|---|---|---|---|
| T2.1 | lua-refactorer | C-03 / F-004 | `settings/Panel.lua` |
| T2.2 | test-author | C-03 test movement | `tests/test_panel.lua` |
| T2.3 | doc-sync | C-03 | `docs/global-strings.md` (the "extra entries support the panel" rationale is no longer true), `docs/settings-panel.md` if it describes the Original row's source |

**Serialization:** T2.1 and T2.2 are coupled (the existing case pins the old behavior and will go red
the moment T2.1 lands) — **serialize**. T2.3 is disjoint and **parallelizable** with either.

**Conflict with M1:** none — disjoint file sets (`settings/Panel.lua` + `tests/test_panel.lua` vs.
`defaults/Defaults.lua` + `tests/test_defaults.lua`). M1 and M2 are **parallelizable** across agents
if `docs/test-cases.md` regeneration is left to whichever lands second.

---

## M3 — Localization surface and small repairs

**Done when:** T-05 and T-06 pass, and the suite is still green.

| Task | Role | Change / findings | Files touched |
|---|---|---|---|
| T3.1 | ux-cleanup | C-04 / F-006 | `settings/Schema.lua`, `settings/Panel.lua`, `locales/enUS.lua` |
| T3.2 | lua-refactorer | C-05 / F-008, F-010 | `settings/Panel.lua` |
| T3.3 | doc-sync | C-05 / F-009 (comment only) | `settings/OptionsSetup.lua` |

**Serialization:** T3.1 and T3.2 both touch `settings/Panel.lua`, and **T2.1 touches it too** →
**all three must serialize on that file**. Suggested order: T2.1 → T3.2 → T3.1. T3.3 is disjoint and
**parallelizable**.

---

## M4 — Upstream: the test kit's suite durations `[cross-repo]`

**Done when:** a re-vendor commit exists in this repo whose only content is the copied `tests/_kit/`
folder, and the next `/wow-addon:automated-tests` run emits no negative `durationMs`.

| Task | Role | Change / findings | Repo / files |
|---|---|---|---|
| T4.1 | upstream-maintainer | U-01 / F-007 | **`LibKa0s` repo** — `testkit/run-automated-tests.sh` |
| T4.2 | upstream-maintainer | U-01 | **`LibKa0s` repo** — kit revision bump + its `README.md` |
| T4.3 | vendor-sync | U-01 | **this repo** — whole-folder copy into `tests/_kit/`, as its **own** commit |
| T4.4 | vendor-sync | U-01 | **every other LibKa0s consumer** — same whole-folder re-vendor |

**Cross-repo handoff:** T4.1/T4.2 are done and merged in `LibKa0s` **before** T4.3 begins. T4.3 is a
copy, not an edit — if the diff after re-vendoring shows changes to any file other than the ones
T4.1 touched, the vendored copy had drifted and that is a separate finding.

**Hard constraint:** nothing in M1–M3 may modify `tests/_kit/`. Committed bundles under
`docs/automated-tests/` are append-only and are **not** retro-corrected by this milestone.

---

## M5 — Deferred: the eager GlobalStrings load `[F-005]`

**Not scheduled.** Listed so it is deferred rather than forgotten.

**Precondition:** M2 shipped and L-01 green — only then is the dump genuinely a fallback rather than
the primary source.

**Shape:** a measured change, with the `collectgarbage("count")` before/after from
`03_SMOKE_TESTS.md`'s performance section as its evidence, and with `docs/global-strings.md`'s
existing note about needing a shared accessor for any on-demand path honoured. Not a one-liner in the
TOC.

---

## Critical-path / concurrency map

```
M0 ──┬── M1 (defaults/Defaults.lua, tests/test_defaults.lua)   ─┐
     │                                                          ├── M5 (deferred)
     └── M2 (settings/Panel.lua, tests/test_panel.lua) ── M3 ───┘

M4 runs independently, in another repo, at any time.
```

* **Must serialize:** `settings/Panel.lua` is touched by T2.1, T3.1 and T3.2. One agent, in that
  order.
* **Parallelizable:** M1 ∥ M2 (disjoint files). T2.3 and T3.3 ∥ anything. M4 ∥ everything.
* **Single shared artifact:** `docs/test-cases.md` — regenerated by whichever of M1/M2 lands second,
  and only ever by `lua tests/run.lua --list > docs/test-cases.md`.

---

## Checkpoints

1. **After T1.2, before T1.1** — human confirms the new case is **red**, and on exactly the two
   expected entries. If it is green before T1.1, it is unfalsifiable and must be rewritten; that is the
   whole failure mode F-003 documents.
2. **After M1** — human runs T-01/T-02/T-03 in-client with `scriptErrors 1`. This is the checkpoint
   that matters: it is the only place the Critical findings are observed as fixed.
3. **After M2, before M3** — L-01 on a non-enUS client. Do not stack M3's `settings/Panel.lua` edits
   on top of an unverified M2.
4. **Before M4's T4.3** — confirm the upstream change is merged and released; a re-vendor from an
   unreleased working tree is how the two copies diverge.

---

## Incremental commit strategy

One commit per task group, atomic and independently revertible:

1. `tests: assert every default's conversions fit the Blizzard string it replaces` *(T1.2 — lands red)*
2. `fix: two Reputation defaults demanded arguments Blizzard never passes` *(T1.1 + T1.3 — turns it green; regenerates docs/test-cases.md and moves the README badge in the same commit; references F-001, F-002, F-003)*
3. `fix: the panel's Original row reads this client's snapshot, not the enUS dump` *(T2.1 + T2.2; F-004)*
4. `docs: the GlobalStrings dump is a fallback, not the panel's source` *(T2.3)*
5. `locale: four settings strings reach L instead of being concatenated` *(T3.1; F-006)*
6. `fix: call LandingRows as the method it is declared as` *(T3.2; F-008, F-010)*
7. `docs: name the guard that actually keeps the Options stub's nils unreachable` *(T3.3; F-009)*
8. `re-vendor LibKa0s testkit rev N` *(T4.3 — copy only, no other file in the commit)*

Commits 1 and 2 may be squashed at merge, but **not** reordered: the red-then-green pair is the
evidence.
