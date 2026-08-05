# 05 — Execution Plan (Ka0s Pretty Chat)

**Run date:** 2026-08-05 · **Standard:** v2.21.0 · Hand-off to the remediation engagement.
Every step is tied to a deviation ID and to `04_TECHNICAL_DESIGN.md`. Steps are ordered so each one
can commit **green** (`lua tests/run.lua` + `luacheck .`, `testing-§4`).

Legend: **[MUST]** / **[SHOULD]** is the level of the rule being closed, not the urgency of the work.

---

## Sprint 0 — Verify what this audit could not (before anything else)

| # | Step | IDs | Done when |
|---|---|---|---|
| 0.1 | With the sibling checkout in scope, run `diff -r --strip-trailing-cr ../LibKa0s/LibKa0s libs/LibKa0s` and `diff -r --strip-trailing-cr ../LibKa0s/testkit tests/_kit` (plus the two byte-level runs `docs/testing.md:55-70` documents). Record the output. | — (audit gap, `03_EVIDENCE.md` A6) | Both content diffs empty. A non-empty content diff is a **new** deviation (anti-pattern #45 for drift, #48 for a file missing on the addon side) and blocks every other sprint until re-vendored whole. |

Rationale: every later step assumes the vendored library is the real one. This check is the only thing
that can see otherwise, and both test suites stay green either way.

---

## Sprint 1 — Cheap, isolated, no dependencies (one commit each)

| # | Step | IDs | Level | Done when |
|---|---|---|---|---|
| 1.1 | `README.md:116` → `` `/pc reset setting` ``. Do **not** sweep real HTML. | PC-46 | MUST | `grep -nE '<(setting\|name\|value\|path)>' README.md` returns nothing; `<br>`/`<code>` untouched. |
| 1.2 | Fold the `## Credits` line (`README.md:120-122`) into the Description paragraph or `docs/ARCHITECTURE.md` `## External dependencies`; delete the heading. | PC-47 (half) | MUST | README headings match `documentation-§1`'s order except `## Unreleased` (1.3). |
| 1.3 | Move `## Unreleased`'s three bullets (`README.md:15-19`) into staging for the next bump and delete the section. | PC-47 (half) | MUST | Section gone; bullets preserved for `## What's new in <next>` and the new Version History row. **Sequence with the next `wow-addon:bump-version`.** |
| 1.4 | Add `## Message Bus` to `docs/ARCHITECTURE.md` between `## Slash Commands` and `## Event Subscriptions`; **move** the sentence from `:119` into it. | PC-53 | SHOULD | `grep -n '^## Message Bus' docs/ARCHITECTURE.md` hits; the sentence appears once, not twice. |

---

## Sprint 2 — The root doc set (PC-48), one commit

| # | Step | IDs | Level | Done when |
|---|---|---|---|---|
| 2.1 | Create `docs/deviations.md`; move `CLAUDE.md:8-13`'s six paragraphs into it **verbatim**, each tagged with its `filename-§N` rule and its audit ID (PC-25, PC-54, PC-27, PC-23, PC-51, PC-49/PC-50). | PC-48 | MUST | Six sections, no prose lost, each cross-referencing this bundle. |
| 2.2 | While moving: extend the generated-data record to name `layout-§2`, `toc-file-§5` and `layout-§1`'s 1500-LOC cap; restate the bus absence as a **classified** accepted deviation, not a neutral fact. | PC-25, PC-49, PC-50 | MUST (record) | Each record names every rule it deviates from. |
| 2.3 | Move `CLAUDE.md:56-63`'s invariants/guardrails into `docs/ARCHITECTURE.md` `## Invariants` (except the green-gate line). | PC-48 | MUST | Nothing removed from `CLAUDE.md` is absent from `docs/`. |
| 2.4 | Reduce root `CLAUDE.md` to the five mandated items **in order**: H1 → adherence line → `## Standards compliance (read first)` (text unchanged) → read-the-docs pointers (incl. `docs/deviations.md`) → green-gate line. | PC-48 | MUST | ~20–25 lines; `## Standards compliance (read first)` is item 3; all three standards-reference places still resolve (`PrettyChat.toc:12`, `README.md:6`, `CLAUDE.md`). |

---

## Sprint 3 — The release gate in the docs (PC-57)

| # | Step | IDs | Level | Done when |
|---|---|---|---|---|
| 3.1 | `docs/testing.md`: keep "`perf` and `complexity` never fail a **run**" verbatim; add the release gate — all four suites `pass` **and** `suites.complexity.warnings == 0` at the tag, evaluated by `/wow-addon:bump-version` from `manifest.json`, never by the runner (its exit code and `gating: false` flags are unchanged); a `skip` blocks as **NOT EVALUATED**. | PC-57 | MUST | Both checkpoints stated, and stated as different. |
| 3.2 | `docs/automated-tests/README.md`: same addition, plus a `Gates at release?` column on the suite table. | PC-57 | MUST | The table no longer implies "never". |
| 3.3 | State this addon's standing case: `perf` skipped for *no `tests/perf.lua`* is the standard's one narrow exception — it passes, and it **MUST** be said plainly in the release notes. (Drops away if Sprint 4 lands first.) | PC-57, PC-43 | MUST | Written in `docs/testing.md` and in the release checklist. |
| 3.4 | `docs/automated-tests/RESULTS.md` is **generated** — do not hand-edit. Check the vendored kit's template; if it lacks the release-gate wording, file it upstream in LibKa0s, fix, re-vendor `tests/_kit/` **whole** as its own commit, regenerate. | PC-57 | MUST | `RESULTS.md` carries the corrected prose **and** was produced by the runner. |

---

## Sprint 4 — The perf cluster (PC-40 … PC-45)

**Gate 4.0 — decide first.** Route A (wire minimally) or Route B (take the decline upstream as a
standard change). Everything below is Route A; under Route B the only deliverable is the filed issue
plus a link recorded against PC-40, and PC-41…PC-45 stay open with an owner.

| # | Step | IDs | Level | Done when |
|---|---|---|---|---|
| 4.1 | Add `core/PerfSetup.lua` — silent `LibStub("LibKa0s-Perf-1.0", true)`, member-answering stub on the absent branch, `NS.Perf = lib:New(descriptor)` otherwise. TOC slot in `# Core` after `core/CoreSetup.lua`, before any consumer. | PC-40 | MUST | The addon loads with the library present **and** absent (the suite already pins the absent case for the other three majors — extend it). |
| 4.2 | Declare one bucket, `applyStrings`, and bracket `PrettyChat:ApplyStrings` with the mandated idiom over a load-time `local Perf = NS.Perf` upvalue. No allocation, no concatenation, no `NS` lookup inside the bracket. | PC-40 | MUST | `performance-§2`'s exact shape; anti-pattern #43 clear. |
| 4.3 | Implement `suspend`/`resume` as restore-originals / re-apply. | PC-40 | MUST | `/pc perf` can make the addon inert without `/reload`; smoke test added. |
| 4.4 | `PrettyChat.toc:7` → `## SavedVariables: PrettyChatDB, PrettyChatPerfDB`; hand the name to the descriptor. | PC-41 | MUST | Exactly two SV globals, in that order. |
| 4.5 | `.luacheckrc`: `debugprofilestop` → `read_globals`; `PrettyChatPerfDB` → `globals` **with a comment**. | PC-45 | MUST | `luacheck .` still 0/0 over the (now 18) files. |
| 4.6 | Add the `perf` triple to `NS.COMMANDS` (between `test` and `debug`), printing the lib's returned lines through `NS.Print`. Update `README.md`'s slash table, `docs/slash-commands.md`, `docs/ARCHITECTURE.md:115`, regenerate `docs/test-cases.md`, move the README `Tests` badge — **same change**. | PC-42 | MUST | `/pc help` lists `perf`; inventory and badge in sync (`testing-§5`). |
| 4.7 | Add `tests/perf.lua`: the zero-overhead scenario (capture off ⇒ no `Note` calls, no allocation attributable to the bracket) and a bucket-reachability assertion. Outside the green gate. | PC-43 | MUST | `tests/_kit/run-automated-tests.sh` records `perf: pass` instead of `skip`. |
| 4.8 | Add `docs/performance.md` and `docs/perf-runs/README.md`. | PC-44 | MUST | All **five** required topic-detail docs present. |

**Order within the sprint:** 4.1 → 4.4/4.5 (so lint stays clean) → 4.2/4.3 → 4.7 → 4.6 → 4.8.

---

## Sprint 5 — Test and locale quality

| # | Step | IDs | Level | Done when |
|---|---|---|---|---|
| 5.1 | Extract the conversion scanner out of `modules/Override.lua:171-197` into a named helper shared by `buildSampleArgs` and the tests. | PC-58 | SHOULD | One implementation, two callers; 255 cases still green. |
| 5.2 | Re-title `tests/test_defaults.lua:107-114` to name its real scope (the preview path). | PC-58 | SHOULD | The case no longer reads as coverage of the shipped defaults against Blizzard. |
| 5.3 | Add the falsifiable case: each default's conversion sequence equals the Blizzard original's in count, order and type, with a one-line comment naming the mutation that reddens it. **Lands in the same change as the F-001/F-002 data fix** — it is red against today's `defaults/Defaults.lua`. | PC-58 (+ review F-001/F-002) | SHOULD | The new case passes only after the two bad defaults are corrected; committing it alone would be a red commit. |
| 5.4 | Route the four concatenated user-facing strings through `NS.L` as format keys; comment why category names stay untranslated; correct `locales/enUS.lua:9-11` to say what the manifest does and does not cover. | PC-59 | SHOULD | `test_locale.lua` reaches every new key; no user-facing prose is assembled outside `L`. |

---

## Sprint 6 — Release readiness (whenever the next version ships)

| # | Step | IDs | Done when |
|---|---|---|---|
| 6.1 | Re-run Sprint 0's two vendor diffs. | — | Both empty. |
| 6.2 | Produce a full four-suite bundle with `ANALYSIS.md` **before** the tag (`automated-tests-§5/§6`). | — | `docs/automated-tests/<stamp>/` complete; `RESULTS.md` regenerated by the runner. |
| 6.3 | Evaluate the release gate from `manifest.json`: all four `pass`, `suites.complexity.warnings == 0`. If `perf` is still a no-`tests/perf.lua` skip, state it plainly in the release notes. | PC-57, PC-43 | Gate evaluated and recorded, not assumed. |
| 6.4 | Roll `## What's new` forward with the Sprint-1.3 bullets and add the Version History row in the same change. | PC-47 | Heading names the new version; bullets match the top row. |
| 6.5 | Re-check the watch-list shelf life: `GlobalStrings/GlobalStrings.lua` must not read *accepted* across three consecutive **release** runs (anti-pattern #53). This is release run #1 for that entry. | PC-49 | Disposition re-argued or converted to a tracked ID at run #3. |

---

## Not scheduled — carried as accepted or upstream

| IDs | Disposition |
|---|---|
| PC-23, PC-27, PC-51, PC-54 | Accepted deviations with written reasons; no work beyond the record move in Sprint 2. PC-23 and PC-51 have upstream LibKa0s items (LIBKA0S-06, LIBKA0S-01) — track them so "documented" does not quietly become "permanent". |
| PC-25, PC-49, PC-50 | Accepted; records tightened in Sprint 2.2. |
| PC-52, PC-56 | File upstream on WowAddonStandards (the `library-stack-§1` vs `§3` tension; the `Category-enUS` enumeration). No repo change. |
| Review F-007 | Upstream LibKa0s (`testkit/run-automated-tests.sh` duration arithmetic). Fix there, bump the kit revision, re-vendor `tests/_kit/` whole as its own commit; the committed bundles are **not** retro-corrected. |

---

## Summary of effort

| Sprint | IDs | MUSTs closed | SHOULDs closed |
|---|---|---|---|
| 0 | — | verification only | — |
| 1 | PC-46, PC-47, PC-53 | 2 | 1 |
| 2 | PC-48 (+ records for PC-25/49/50) | 1 | — |
| 3 | PC-57 | 1 | — |
| 4 | PC-40…PC-45 | 6 | — |
| 5 | PC-58, PC-59 | — | 2 |
| 6 | release readiness | — | — |

Closing Sprints 1–4 takes the MUST count from **12 → 2** (PC-25 and PC-49/PC-50 remain as documented,
classified accepted deviations). Sprint 5 takes SHOULD from **7 → 5**, the remaining five all being
documented accepted deviations.
