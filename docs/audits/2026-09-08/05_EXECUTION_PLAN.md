# 05 — Execution plan (Ka0s Pretty Chat)

**Run date:** 2026-09-08 · **Standard:** v2.39.0 (2026-09-07) · **Design:** `04_TECHNICAL_DESIGN.md`

Hand-off to a separate remediation engagement. **Nothing below has been executed.** This audit wrote
only the five files in this folder.

Every step names its deviation ID and its acceptance check. Every figure quoted here is the one
`02_DEVIATIONS.md` and `03_EVIDENCE.md` carry — the two documents are read as one, and the numbers
reconcile: **7 root deviations, 7 including dependents (none), 6 MUST failures, 49 British-spelling
hits across 19 files, 0 files off the line-ending pin, 328 test cases, 44 lint files, 694 functions**.

## Standing gate for every step

```
luacheck .        # must stay 0 warnings / 0 errors in >= 44 files
lua tests/run.lua # must stay 0 failed, 0 skipped
```

Both are green today. Commit only on green (`versioning-git`, `testing-§4`). Do not edit anything
under `libs/` or `tests/_kit/` in any step — both are vendored and both `diff -r` gates are empty
today.

---

## Sprint 1 — the register tells the truth (PC-73, PC-72, PC-74)

Three edits to two documents, one sprint because they overlap: PC-73 changes what PC-72 has to say,
and PC-72 and PC-74 both touch `CLAUDE.md`'s pointer material. Ordered.

### S1-1 · PC-73 — narrow the `toc-file-§1` register row

- [ ] `docs/ARCHITECTURE.md:230` — strike `, and \`## X-Wago-ID\` is absent` from *What differs*.
- [ ] Same row — strike the Wago sentence from *Why*, keeping the brand-mark reasoning whole.
- [ ] Same row — reduce *Re-check trigger* to *"a decision to retire the brand mark"*.
- [ ] Add a third bullet to the **Retired** block (`docs/ARCHITECTURE.md:238`+) in the shape the two
      2026-09-08 retirements use, quoting `toc-file.md:30`'s *optional (**MAY**)* wording and citing
      `PC-73`.
- [ ] **Do not** touch `PrettyChat.toc`. **Do not** reopen or relabel issue #7.

**Accept when:** the register carries 9 active rows and 3 retired bullets; `lua tests/run.lua` is
green (the case *"every deviation id the register cites is assigned by a bundle in docs/audits/"*
must still pass, so `PC-73` needs this bundle committed first).

### S1-2 · PC-72 — resync `CLAUDE.md:36`

- [ ] Replace *"the re-check trigger for each of the **eleven**"* with a form carrying **no integer**.
- [ ] Drop *"the TOC section order"* and *"the two Ace libs this addon does not vendor"* from the
      enumeration — both were retired 2026-09-08 — and the Wago clause if present after S1-1.
      Prefer shortening the enumeration to a pointer over maintaining a second subject list.
- [ ] Repoint the audit link at `docs/audits/2026-09-08/` (Standard **v2.39.0**) and the review link
      at `docs/reviews/2026-09-07/`; keep the older bundles in the *"kept for history"* clause.
- [ ] *Optional, recommended:* add a case to `tests/test_doc_structure.lua` asserting `CLAUDE.md`'s
      audit pointer names the **newest** directory under `docs/audits/`. Scope it to the directory
      name only.

**Accept when:** `grep -o 'each of the [a-z]*' CLAUDE.md` returns nothing, and the two links resolve
to directories that exist.

### S1-3 · PC-74 — delete `## Doc index`

- [ ] `grep -rn 'doc-index' docs/ README.md CLAUDE.md` — expect no hit. Fix any anchor first.
- [ ] Delete `docs/ARCHITECTURE.md:341-359` (`## Doc index` and its table).
- [ ] Move the one unique row — the `../DEPENDENCIES.md` pointer — into `CLAUDE.md`'s docs pointer
      list. Fold into S1-2's commit if convenient.
- [ ] **Do not** re-sync the table instead. Adding `test-cases.md` and `automated-tests/README.md`
      fixes today's drift and recreates it on the next doc added.

**Accept when:** `grep -c '^## ' docs/ARCHITECTURE.md` drops by one, the hub is ~340 lines, the suite
case *"every anchor pointing into docs/ARCHITECTURE.md resolves to a heading"* is green, and
`## Documentation map` is the file's only doc inventory.

---

## Sprint 2 — the spelling gate, then the sweep (PC-75)

**The order is deliberate and is the whole design.** The gate goes first so it is seen to fail.

### S2-1 · Write the gate, and watch it go red

- [ ] Copy `localization-§5`'s `BRITISH` and `ALLOWED` lists **whole** into a case — no entry added,
      none removed — with a comment saying they are copied whole and must be re-copied whole on the
      next standard bump.
- [ ] Build the candidate set from `git ls-files` minus, by prefix: `libs/`, `tests/_kit/`,
      `GlobalStrings/`, `media/`, `.claude/`, `LICENSE`, `docs/audits/`, `docs/reviews/`,
      `docs/revendor/`, `docs/superpowers/`, `docs/automated-tests/<run>/`, `docs/test-cases.md`.
      **State that scope in the failure message.**
- [ ] Remove `ALLOWED` as **whole words first**, then match `BRITISH` case-insensitively as
      substrings. Wrong order makes *analysis* a British spelling.
- [ ] Report file, line and matched substring per hit, not just a total.
- [ ] Home it in `tests/test_locale.lua` (smallest change — it already reads the TOC-derived source
      set) or a new `tests/test_prose.lua` with one line added to `tests/run.lua`'s suite list.

**Accept when:** the case **fails**, reporting **49** hits across **19** files — the same number
`03_EVIDENCE.md` §10 records. A gate that reports anything else means the scope was mistyped; fix the
scope, not the number.

### S2-2 · Sweep the 49, largest site first

- [ ] `tests/test_locale.lua` — 16. Eleven fall to one rename: the residue-taxonomy class literal
      `SPLIT COLOUR` → `SPLIT COLOR`, in its definition and its ten uses. **Confirm first** that the
      string is a local taxonomy label and not a key another file matches on.
- [ ] `tests/test_schema.lua` — 7. Renaming the case *"no colour row exists…"* changes a **test case
      name**, so regenerate `docs/test-cases.md` in the same commit. The count does not move, so the
      README `[tests]` badge stays at 328/328.
- [ ] `docs/smoke-tests.md` (4), `docs/settings-panel.md` (3), `docs/common-tasks.md` (3) — prose.
- [ ] `tests/test_panel.lua` (2), `tests/run.lua` (2), `tests/wow_mock.lua`, `tests/test_override.lua`,
      `tests/test_libka0s.lua`, `tests/test_apply.lua` — comments.
- [ ] `settings/Schema.lua:72`, `settings/Panel.lua:465`, `modules/Override.lua:41`,
      `core/PrettyChat.lua:102`, `.luacheckrc:167` — comments in shipped source and config.
- [ ] `docs/schema.md`, `docs/data-flow.md`, and `docs/ARCHITECTURE.md`'s `localization-§1` register
      row (*"two mandated colour spans"*) — prose; the register hit belongs in this commit, not
      Sprint 1's.
- [ ] **Do not touch** `locales/enUS.lua` (already clean), `libs/`, `tests/_kit/`, `GlobalStrings/`,
      or any frozen bundle under `docs/audits/`, `docs/reviews/`, `docs/revendor/`,
      `docs/automated-tests/<run>/`.

**Accept when:** the S2-1 gate is **green**, `luacheck .` is 0/0, `lua tests/run.lua` is 0 failed,
and no player-visible string moved — `git diff` touches no quoted string in `core/`, `settings/`,
`modules/`, `defaults/` or `locales/`.

---

## Sprint 3 — the geometry case (PC-69)

Do this last: it is the only item whose prerequisite may live outside this repo, and it is the one
deferred by plan (`M1-LK-08`).

### S3-0 · Check the prerequisite before writing anything

- [ ] Read the vendored kit's revision and `tests/_kit/mock_base.lua`. If `M1-LK-08` has landed
      per-atlas heights in the kit, **skip S3-1** — re-vendoring the kit is a `diff -r` matter, not a
      local edit.

### S3-1 · Give the extender per-atlas heights

- [ ] `tests/wow_mock.lua` — make an atlas-bearing texture answer a **different** measured height for
      the selected-state atlas than for the unselected one. `tests/_kit/mock_base.lua:132` already
      supports a real height (`(self.__geomLive and self.__geomH) or 0`); what is missing is the
      difference between the two states.
- [ ] **Do not edit `tests/_kit/`.** Confirm `diff -r ../LibKa0s/testkit tests/_kit` is still empty
      after.

### S3-2 · Add the case

- [ ] `tests/test_panel.lua` — build the `Categories` page (eight tabs, `settings/Panel.lua:618` —
      the page that wraps first). Record the reserved band height and **every row's y offset** for
      each of the eight selections. Assert all eight recordings are identical.
- [ ] **Name the mutation it dies under**, in a comment: make the library read the row pitch off the
      **selected** tab's cap atlas instead of the inactive one, and the case must go red. Without
      that sentence this is the vacuous version `options-ui-§13`'s Testing MUST exists to refuse.

**Accept when:** the case fails under that mutation and passes without it. A case that passes both
ways is a *missing* case, not a passing one, and must be reported as still open.

---

## Sprint 4 — the low-risk residue (PC-60)

### S4-1 · Three conventional group notes

- [ ] `PrettyChat.toc:27` (`# Core`) — say the four annotated positions are the load-bearing ones and
      the remaining `core/` lines are conventional, reached through closures at call time.
- [ ] `PrettyChat.toc:53` (`# Modules`) — say the position is conventional given everything above it,
      naming `core\PrettyChat.lua` (for `GetAddon` at `modules/Override.lua:8`) and
      `core\Constants.lua` / `core\Util.lua` (for the file-scope upvalues at `:10-12`).
- [ ] `PrettyChat.toc:56` (`# Settings`) — replace *"depend on everything else being initialized"*,
      the weaker *order matters* form, with a statement of which positions in the group are
      conventional. Leave `settings\Panel.lua`'s existing annotation at `:60-63` untouched.
- [ ] **No line moves.** `toc-file-§5` makes a dependency-correct, annotated order compliant whatever
      the sequence.

**Accept when:** `PrettyChat.toc` still loads in-game (smoke test 1), the file gains only comment
lines in `git diff`, and a re-audit files no `toc-file-§5` row of either kind.

---

## Not scheduled here

### PC-71 — upstream, not local

- [ ] Open an issue on `WowAddonStandards` asking that `documentation-§3`'s out-of-scope directory
      list carry `docs/revendor/` beside `docs/audits/` and `docs/reviews/`, citing `PC-71`.
- [ ] **Change nothing in this repo.** `docs/ARCHITECTURE.md:167` already names the directory once,
      which is the answer the rule would give. Do not add two rows to the map, and do not open a
      deviation-register row — a gap that lives in the standard is exactly the manufactured
      graveyard entry `library-stack-§1`'s 2026-09-08 retirement was written to warn against.

### PC-76 — closes itself at the next release run

- [ ] Nothing now. Run `tests/_kit/run-automated-tests.sh` as part of the next release and let it
      overwrite `docs/automated-tests/RESULTS.md` in place.
- [ ] **Never hand-edit the figures** to match the tree. `automated-tests-§4`'s one boundary makes
      every cell but the watch list's `Disposition` the runner's, and a hand-edited generated number
      reads as measured.
- [ ] Expect the delta the release run will show — recorded here so it is not mistaken for growth:
      **+5 test cases (323 → 328), +1 lint file (43 → 44), +6 functions (688 → 694), +209 NLOC
      (52,962 → 53,171), max CCN unchanged at 13, warnings unchanged at 0.** All of it is `M4c-06`.

---

## Ordering constraints, in one place

| Step | Blocked by | Why |
|---|---|---|
| S1-1 (PC-73) | this bundle being committed | the register's evidence-id case resolves `PC-73` against `docs/audits/` |
| S1-2 (PC-72) | S1-1 | S1-1 changes what the sentence has to enumerate |
| S1-3 (PC-74) | S1-2 | both touch `CLAUDE.md`'s pointer material; adjacent-line churn otherwise |
| S2-2 (PC-75 sweep) | S2-1 | the gate must be seen to fail at 49 before it is made to pass |
| S3-1 (PC-69 mock) | S3-0 | `M1-LK-08` may make it unnecessary |
| S3-2 (PC-69 case) | S3-1 | the case is vacuous without per-atlas heights |
| S4-1 (PC-60) | nothing | comment-only, run any time |

**Nothing in this plan changes a shipped byte a player receives**, with one exception that is worth
naming: Sprint 2 edits comments inside `core/`, `settings/` and `modules/`, which are packaged files.
Comments do not execute, so the behavior is identical — but the diff will show shipped-source
changes, and a reviewer should know that is expected rather than scope creep.
