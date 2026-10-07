# 05 — Execution Plan (Ka0s Pretty Chat)

**Run date:** 2026-10-07 · **Standard:** v2.76.1 · Keyed to `02_DEVIATIONS.md` and `04_TECHNICAL_DESIGN.md`.

**Scope:** 5 roots, 0 dependents. That is 3 Low (PC-103, PC-104, PC-105) and 2 Info (PC-76,
PC-106). Two of them are MUST failures: PC-103 and PC-104. Nothing is player-reachable, so this is
a single short sprint of docs, records and comments. There is **no shipped-Lua behavior change**,
and none of it needs an in-client smoke check.

**Gate for every step:** these two commands run through `~/.claude/dev-copilot/bin/ka0s-bounded`:
`lua tests/run.lua` (today 572/0/1, 573 total) and `luacheck .` (0/0 in 56 files). Commit each step
as `<ID>: <summary>` on the feature branch. **Never** bump the version, and never push or merge
without the owner's go-ahead.

---

## Sprint 1: records and docs

- [ ] **PC-103.** Write the span bundle `docs/revendor/2026-10-07-v1.69.0-v1.70.0/`.
  - [ ] `01_DELTA.md`. Line 1 is exactly `Delta: LibKa0s v1.68.1 -> v1.70.0 (span: v1.69.0 v1.70.0)`.
    Then the two carrying commits (`136cf54`, `7a1aabf`) and the files each added or changed, taken
    from `git show --stat`.
  - [ ] `05_SUMMARY.md`. No host adoption: Widgets is declined, #11. The vendor-sync gate is green,
    and `diff -r` of both payloads against the `v1.70.0` tag is empty.
  - [ ] Verify by re-running `AUDIT.md`'s re-vendor script. The `unrecorded` list must be empty.
  - Commit: `PC-103: record the v1.69.0-v1.70.0 re-vendors in one span bundle`.

- [ ] **PC-104 (1).** Rewrite the LibKa0s majors sentence at `docs/ARCHITECTURE.md:418`.
  - [ ] State that DebugLog resolves Widgets and that the Options files resolve Pool and Item.
  - [ ] Drop the hand-kept file list, or replace it with "the files `LibKa0s.xml` lists".
- [ ] **PC-104 (3).** Fix `.luacheckrc:34-37`, either to ten and twelve or to history-only wording.
  The edit is comment-only.
- [ ] **PC-104 (4).** Resolve the `PRETTYCHAT-A-NN` citations.
  - [ ] Rewrite each to its in-repo `PC-NN` (A-07→PC-83, A-08→PC-84, A-09→PC-85, A-19→PC-94,
    A-20→PC-95, A-25→PC-99; look up A-03 in the consolidated digest before choosing). The sites are
    `docs/ARCHITECTURE.md:100,171,173,375`, `docs/module-map.md:54,58`, `defaults/Profile.lua:3`,
    `tests/test_override.lua:77`, `tests/test_defaults.lua:303` and
    `tests/test_doc_structure.lua:410,469`.
  - [ ] **And/or** add the one-line expansion to the register preamble (`docs/ARCHITECTURE.md:276-280`).
- [ ] **PC-104 (2)**, which comes **after** (4) because (4) edits `tests/`.
  - [ ] Re-run the sweep at `docs/performance-sweep.md:19-21`.
  - [ ] Paste the result verbatim and name the carrying commit in the header.
  - [ ] Make the `performance-§12` register row's *Why* cell (`docs/ARCHITECTURE.md:284`) name the
    same commit, or point at the page instead of naming one.
  - [ ] Confirm the count is still 43, with no new shipped-code hit. A new shipped-code hit means
    re-evaluating the exemption, which is a stop-and-flag.
  - Commit: `PC-104: sync docs and comments to the v1.70.0 tree (majors, sweep, lint comment, digest ids)`.

- [ ] **PC-105.** Bring `docs/ARCHITECTURE.md` under about 400 lines.
  - [ ] Move `:362-412` (the census exemption prose) to `docs/global-strings.md` →
    `## The cap exemption`. Leave the heading, the command, the table and the verdict.
  - [ ] Shorten the retired-row narratives (`:293-335`) to one sentence and an id each.
  - [ ] Run the suite. `test_layout_cap` and `test_doc_structure` must stay green.
  - [ ] Run `wc -l docs/ARCHITECTURE.md` and record the new figure.
  - Commit: `PC-105: spill the census prose and trim retired rows; hub back under 400 lines`.

- [ ] **Sprint 1 checkpoint.** Suite and lint are green (bounded). The re-vendor script reports
  nothing unrecorded. `diff --strip-trailing-cr <(lua tests/run.lua --list) docs/test-cases.md`
  is empty, which is expected because no case changed. The README badge needs no change unless a
  case changed.

## Owner-gated (no commit in this repo)

- [ ] **PC-106.** After the owner's go-ahead, post the supersession comment on issue #8, and
  optionally relabel it `state:done`. Use `gh issue comment 8 --body …` and
  `gh issue edit 8 --add-label state:done --remove-label state:will-not-do`. Throttle the GitHub
  writes.

## At the next release (not now)

- [ ] **PC-76.** Through `/dev-copilot:bump-version`, run
  `bash tests/_kit/run-automated-tests.sh --release <ver>` via `ka0s-bounded`. Confirm that
  `suites.complexity.blindFiles` is 0, max CCN is at most 15 and the band row is current.
  - [ ] **Never** hand-edit `RESULTS.md`. The one authored cell is the band row's *Disposition*.
  - [ ] Optionally peel `listSettings`' two keyword listings into `listCategories()` and
    `listFormatStrings()`. Do it only if `settings/Slash.lua` is being touched anyway, with the
    `/pc list category|formatstring` cases (`tests/test_slash.lua:351`, `:362`) as the
    characterization.

---

## Traceability

| ID | Grade | Level | Step | Files touched |
|---|---|---|---|---|
| PC-103 | Low | MUST | Sprint 1 | `docs/revendor/2026-10-07-v1.69.0-v1.70.0/` (new) |
| PC-104 | Low | MUST | Sprint 1 | `docs/ARCHITECTURE.md`, `docs/performance-sweep.md`, `docs/module-map.md`, `.luacheckrc`, `defaults/Profile.lua` (comment), `tests/test_override.lua`, `tests/test_defaults.lua`, `tests/test_doc_structure.lua` (comments) |
| PC-105 | Low | SHOULD | Sprint 1 | `docs/ARCHITECTURE.md`, `docs/global-strings.md` |
| PC-76 | Info | — | next release | `docs/automated-tests/` (generated) |
| PC-106 | Info | — | owner-gated | GitHub issue #8 |
