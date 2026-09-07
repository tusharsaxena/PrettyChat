# 05 — Execution Plan (Ka0s Pretty Chat)

**Run date:** 2026-09-07 · **Standard:** v2.38.0 (2026-09-02)

Ordered hand-off to the remediation engagement. Every step names its deviation ID and its design
section in `04_TECHNICAL_DESIGN.md`. The counts here are the same ones `02_DEVIATIONS.md` reports —
**11 root deviations, 11 including dependents (there are none), 9 of them MUST failures, all 11 graded
Low** — and the two documents are meant to be read as one.

**Standing gate for every step:** `lua tests/run.lua` green and `luacheck .` clean before the step is
called done. Both are green today (300/300, 0/0 over 18 files), so any red belongs to the step that
just ran.

**Do not** run the automated-test runner with `--release` anywhere in this plan: a release run starts
anti-pattern #53's three-run shelf-life clock on the `GlobalStrings` *Accepted* disposition, which is
not a decision this remediation gets to make.

---

## Sprint 1 — the two-minute items (PC-63, PC-70, PC-64)

Independent, mechanical, each a single file or a matched pair. Do them first so the remaining work is
not queued behind trivia.

| # | Step | IDs | Design | Done when |
|---|---|---|---|---|
| 1.1 | Add `- .claude` to `.pkgmeta`'s `ignore:` block with a one-line comment; give `.pkgmeta` itself either a row or a comment | PC-63 | C | `for e in .[!.]*; do [ -e "$e" ] \|\| continue; grep -q "^  - $e\b" .pkgmeta \|\| echo "UNACCOUNTED — $e"; done` prints only `.git` |
| 1.2 | Insert the adherence sentence at `CLAUDE.md:4`, above `## Standards compliance (read first)`; leave `:7-8` intact | PC-70 | G | `CLAUDE.md`'s first four items read H1 → adherence → `## Standards compliance` → pointer list, and `grep -n 'Bundles \[LibKa0s\]' CLAUDE.md` still returns exactly one hit |
| 1.3 | Publish a `nil`-returning `NS.MakeCloseButton` in `core/CoreSetup.lua`'s library-absent branch, above the `return` at `:84` | PC-64 | D | Loading the addon with `libs/LibKa0s/Core.lua` skipped leaves `NS.MakeCloseButton` a function |
| 1.4 | Add `MakeCloseButton` to `coreSurface` (`tests/test_libka0s.lua:683-689`) and to the non-vacuity key list at `:695`; re-run the grep at `:682` and confirm the projection now matches it | PC-64 | D | The Core parity case passes on both arms and goes **red** if 1.3 is reverted |

1.3 and 1.4 land in one commit. Splitting them ships a fix nothing can prove and a test nothing can
fail.

---

## Sprint 2 — the register (PC-61, PC-62)

One file, two opposite edits, plus two upstream issues. Grouped so `docs/ARCHITECTURE.md`'s
`## Documented deviations` table is opened once.

| # | Step | IDs | Design | Done when |
|---|---|---|---|---|
| 2.1 | Delete the `toc-file-§5` row (`docs/ARCHITECTURE.md:222`) and note the retirement under the table preamble, citing `layout.md:53` as the resolution | PC-61 | B | The register holds ten rows; no row cites a rule whose text has changed since it was decided |
| 2.2 | Add an `architecture-§4` row: no closed bus, one feature module, no second receiver; Decided today; re-check trigger = the second feature module or the first `LibStub("AceEvent-3.0")` | PC-62 | B | The register holds eleven rows again, and a fresh audit finds a ratified decision rather than an open MUST |
| 2.3 | Update `docs/ARCHITECTURE.md:123-129`'s `## Message Bus` section so it records the event trigger as **fired** and points at the new row, rather than reading as below-threshold | PC-62 | B | The section and the register row agree about which side of the threshold the addon is on |
| 2.4 | File `WowAddonStandards` issue: narrow `architecture-§4`'s *"any module that registers game events"* trigger so a single-module addon with no second receiver is not bound by a rule whose stated rationale cannot reach it | PC-62 | B | Issue open; its number is in the 2.2 row's *Why* cell |
| 2.5 | File `WowAddonStandards` issue: `documentation-§3` mandates five verification-and-record docs and describes a three-table `## Documentation map` with no home for them | PC-68 | G | Issue open; a one-line note above `docs/ARCHITECTURE.md:190` cites it |

2.5 sits here rather than in Sprint 3 because it is an issue-filing step, not a doc edit — the local
half of PC-68 is deliberately **one comment**, not a restructure.

---

## Sprint 3 — documentation and the TOC (PC-67, PC-60)

| # | Step | IDs | Design | Done when |
|---|---|---|---|---|
| 3.1 | Diff `README.md:71-82` against `docs/settings-panel.md`; move anything the topic doc is missing into it | PC-67 | G | `docs/settings-panel.md` covers every tab the README table described |
| 3.2 | Delete `README.md:71-82`. Keep `:66-69` and `:84` | PC-67 | G | The README's settings section is page-granularity only, and `:64`'s "two pages" sentence still reads correctly |
| 3.3 | Annotate the three load-bearing TOC lines — `core\Util.lua`, `core\CoreSetup.lua`, `settings\Panel.lua` — each naming the symbol and its publisher, in the shape `PrettyChat.toc:34-35` already uses | PC-60 | A | Every line in the listing whose position is load-bearing carries an at-line comment naming what resolves |
| 3.4 | Mark the conventional positions once per group, after checking each candidate's file scope rather than assuming it | PC-60 | A | No line in the listing is ambiguous between *free to move* and *not yet understood* |
| 3.5 | Add the one-line note above `docs/ARCHITECTURE.md:190` citing the 2.5 issue | PC-68 | G | The fourth table reads as a raised question, not an unexamined departure |

3.3 is the step most likely to be got subtly wrong. Derive each annotation from the `.lua` file's own
file-scope reads, not from the TOC's current sequence — an annotation asserting a dependency that does
not exist freezes an order for a reason that was never true.

---

## Sprint 4 — the test that can fail (PC-69)

The only step in the plan with real design content. It is last among the code work because it is the
one that needs thought rather than typing.

| # | Step | IDs | Design | Done when |
|---|---|---|---|---|
| 4.1 | In `tests/wow_mock.lua` (never `tests/_kit/`), give a texture that has been handed an atlas a height derived from the atlas name, so `Options_Tab_Active_*` and `Options_Tab_*` answer different numbers | PC-69 | H | The whole suite is still green with the new height model in place |
| 4.2 | Add the selection-invariance case: build the eight-tab Categories page and assert the reserved band height and every tab row's y offset are identical for every value of the selection | PC-69 | H | The case passes against the vendored `libs/LibKa0s/OptionsWidgets.lua:384-399`, and goes red under a mutation that reads the pitch off the selected tab's atlas |

Name the mutation in the case's comment. A case whose failure mode is not written down is one refactor
away from being deleted as inscrutable.

---

## Sprint 5 — hygiene and the record (PC-66, PC-65)

Last, and in this order, because both are measurements of the tree and both are wrong the moment
anything above them changes.

| # | Step | IDs | Design | Done when |
|---|---|---|---|---|
| 5.1 | `git add --renormalize .`, review the terminator-only diff, commit it **alone**, then `rm <path> && git checkout -- <path>` for each straggler | PC-66 | F | The working-tree agreement command in `03_EVIDENCE.md` §4 prints `0` |
| 5.2 | Run `tests/_kit/run-automated-tests.sh` (no `--release`) to write a fresh bundle and prepend its `RESULTS.md` row | PC-65 | E | A new `docs/automated-tests/<stamp>/` exists with all five artifacts and a `"release": null` manifest |
| 5.3 | Rewrite `RESULTS.md`'s four standing sections against the new bundle: the ANALYSIS.md roll-call (`:7-9`), `## Test suite` (`:44`), `## Lint` (`:48`), and the `layout-§1` band row (`:84`) | PC-65 | E | No standing section names `20260807-114404` as current, and every figure in them comes from the new bundle's files |

**5.3's prohibition is the point of the step:** do not hand-edit a generated number. `RESULTS.md:74-79`
already makes that argument about a different row, and it applies to itself — a figure edited by hand
reads as measured when it is not.

---

## Verification pass

Run after Sprint 5 and record the output; this is what a re-audit will re-run first.

1. `luacheck .` → 0/0.
2. `lua tests/run.lua` → all green, count matching the README badge and `docs/test-cases.md`.
3. `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` → zero functions over CCN 15, and the totals
   matching the new bundle's `complexity.txt`.
4. The `03_EVIDENCE.md` §4 line-ending command → `0`.
5. The `03_EVIDENCE.md` §3 dot-entry sweep → `.git` only.
6. `diff -r --strip-trailing-cr <LibKa0s v1.25.0>/LibKa0s libs/LibKa0s` and
   `… /testkit tests/_kit` → both still empty. Nothing in this plan touches either payload, so a
   non-empty result means a step went somewhere it should not have.
7. `grep -rn 'MakeCloseButton(' --include='*.lua' . | grep -v '/libs/' | grep -v '/tests/'` → the
   wrapper at `core/CoreSetup.lua:112` **plus** the new degraded twin, and nothing else.

## What this plan deliberately does not do

- **It does not build a message bus.** PC-62's honest answer is a register row and an upstream issue;
  a bus with one module and one receiver is ceremony that the section's own rationale does not ask for.
- **It does not wire a perf harness.** The `performance-§12` exemption (`docs/ARCHITECTURE.md:220`) is
  ratified, re-checked on 2026-09-02, and re-confirmed by this audit against the code.
- **It does not touch `libs/` or `tests/_kit/`.** Both diff clean against the vendored tag. A library
  problem is fixed in `../LibKa0s` and re-vendored whole.
- **It does not restructure `## Documentation map`.** The fourth table is the least-bad answer to a
  gap in the standard; the fix is upstream (2.5), and collapsing mandated docs into Tier 3 meanwhile
  would be worse than the deviation.
- **It does not bump the version.** No user-facing behavior changes anywhere in this plan.
