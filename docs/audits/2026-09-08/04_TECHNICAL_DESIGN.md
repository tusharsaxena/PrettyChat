# 04 — Technical design (Ka0s Pretty Chat)

**Run date:** 2026-09-08 · **Standard:** v2.39.0 (2026-09-07)

Remediation design for the seven entries in `02_DEVIATIONS.md`, keyed to their IDs. Nothing here has
been executed — this audit is read-only and wrote only the five files in this folder.

**The shape of this cycle's work.** Six of the seven touch **no shipped Lua**. Five are documentation
or register edits inside `docs/ARCHITECTURE.md` and root `CLAUDE.md`; one is a comment sweep across
comments and prose; one adds a test case and one adds a mock capability. **Nothing a player installs
changes**, which is why the whole set grades Low and why the ordering below is driven by *what
unblocks what*, not by urgency.

---

## PC-73 — narrow the `toc-file-§1` register row (do this first)

**Files:** `docs/ARCHITECTURE.md` only.

The row at `:230` records two things. One is a real, ratified deviation (the rainbow `## Title:` and
stylized `## Author:` brand mark). The other — the absent `## X-Wago-ID` — is behavior
`toc-file-§1` **permits outright**, so it is not a deviation and its presence in the register is the
graveyard `documentation-§3` forbids.

**Shape of the change.** Three cell edits and one addition, in one commit:

1. *What differs* — strike `, and \`## X-Wago-ID\` is absent`.
2. *Why* — strike the sentence beginning *"`toc-file-§1` asks for both distribution ids…"* through
   *"…there is no Wago listing to reference. Do not add the field and do not commit a placeholder"*.
   What survives is the brand-mark reasoning alone.
3. *Re-check trigger* — reduce to *"a decision to retire the brand mark"*; drop the Wago clause,
   which is a trigger for a row that should not exist.
4. Add a third bullet to the **Retired** block below the table, in the shape the two 2026-09-08
   retirements already use: name the rule, quote `toc-file.md:30`'s *optional (**MAY**)* wording,
   state that PrettyChat is not listed on Wago so the omission is compliant rather than ratified,
   and cite `PC-73`.

**Why the row is narrowed rather than retired whole.** The brand mark genuinely departs from
`toc-file-§1`'s naming guidance and is a deliberate decision with no expiry. Retiring the row
outright would lose it.

**What must NOT change.** `PrettyChat.toc` is correct as it stands and is not touched. Issue #7
(*Add `## X-Wago-ID` to PrettyChat.toc*) is correctly closed `state:will-not-do` and stays closed —
the issue store is a working queue, and closing a feature request is not the same act as retiring a
register row.

**Risk:** none. `tests/test_doc_structure.lua` asserts the register's *shape* and that every
deviation id it cites resolves to a bundle; a narrowed cell and a new retired bullet keep both true.
Run `lua tests/run.lua` after.

---

## PC-72 — resync `CLAUDE.md:36`

**Files:** `CLAUDE.md` only. **Depends on PC-73**, which changes what the sentence has to say.

One line is stale in three ways. The fix is to rewrite it so that none of the three can rot the same
way again:

- **Stop restating a count.** *"each of the eleven"* is a number that goes stale on the next
  retirement — which is exactly what happened. Replace with a form that does not carry an integer:
  *"…carries the `filename-§N` rule, what differs, why, the date decided and the re-check trigger for
  every ratified deviation, with the retired rows kept below the table."*
- **Drop the two retired subjects** from the enumeration — *"the TOC section order"* and *"the two
  Ace libs this addon does not vendor"* — and, after PC-73, the Wago clause if the enumeration names
  it. Better still, shorten the enumeration to a pointer: the register is one click away and a
  second copy of its subject list is a second thing to maintain. This is the same reasoning PC-74
  applies to `## Doc index`.
- **Repoint the bundle links** at `docs/audits/2026-09-08/` (Standard **v2.39.0**) and
  `docs/reviews/2026-09-07/`, keeping the older ones in the *"Earlier bundles are kept for history"*
  clause where they belong.

**Optional hardening, and it is cheap.** `tests/test_doc_structure.lua` already reads both
`docs/ARCHITECTURE.md` and root `CLAUDE.md`. A case asserting that `CLAUDE.md`'s audit pointer names
the **newest** directory under `docs/audits/` would have caught this the day it went stale, and would
keep catching it. Scope it to the directory name only — asserting the standard version too would
make every audit a two-file edit for no gain.

---

## PC-74 — delete `## Doc index`

**Files:** `docs/ARCHITECTURE.md`, and one line added to `CLAUDE.md`.

Two inventories of one doc set is one too many, and the second has already drifted: it is missing
`test-cases.md` and `automated-tests/README.md`, two of the six rows `documentation-§3` makes
mandatory in every addon in every state.

**Shape of the change.** Delete `docs/ARCHITECTURE.md:341-359` (`## Doc index` and its table). Its
13 rows are 12 documents the mandated `## Documentation map` at `:164` already registers, plus one
that is genuinely not a `docs/` file and therefore has no place in the map: `../DEPENDENCIES.md`.
Move that single pointer into root `CLAUDE.md`'s docs pointer list, where `documentation-§2` item 4
already puts signposts of exactly that kind.

**Why deleting beats re-syncing.** Adding the two missing rows fixes today's drift and recreates it
on the next doc added, because nothing gates the second table — `tests/test_doc_structure.lua`
checks the map. Deletion removes the failure mode rather than the symptom.

**Sequencing note.** Do this **after** PC-72 or in the same commit: both touch `CLAUDE.md`'s pointer
material, and two commits editing adjacent lines of one stub is churn.

**Risk:** low. Verify no anchor elsewhere in the repo links to `#doc-index`
(`grep -rn 'doc-index' docs/ README.md CLAUDE.md`) before deleting — a live link to a deleted heading
is the same failure one step removed, which the suite's *"every anchor pointing into
docs/ARCHITECTURE.md resolves to a heading"* case will catch if the grep is skipped.

---

## PC-71 — `docs/revendor/` is an upstream question, not a local edit

**Files:** none in this repo. **This is a standards-repo change.**

Two `.md` files under `docs/revendor/2026-08-25/` sit in no table of `## Documentation map`, because
`documentation-§3`'s out-of-scope carve-out is an **enumerated** list — `docs/audits/`,
`docs/reviews/`, `docs/automated-tests/<run>/`, `docs/perf-analysis/<run>/`, `docs/superpowers/`,
`docs/investigations/` — and `docs/revendor/` is not on it.

**The right fix is upstream.** A re-vendor bundle is a frozen dated record of exactly the same kind
as an audit or review bundle: written once, never edited, and growing one directory per event. Adding
a row per re-vendor is precisely the register growth the carve-out exists to prevent, so the
enumeration should carry `docs/revendor/` rather than this repo carrying two rows.

**What to do locally: nothing.** `docs/ARCHITECTURE.md:167` already names the directory once, which
is the honest local answer and is what the rule would say if it named the directory. Do **not** add
two rows to the map as an interim measure — that ships the shape the carve-out forbids and then has
to be undone.

**Filing.** Open an issue on `WowAddonStandards` naming `documentation-§3`'s out-of-scope list, and
cite this bundle's `PC-71`. Until it resolves, record nothing in this repo's deviation register: a
gap that lives in the standard is the graveyard row `library-stack-§1`'s retirement on 2026-09-08
was written to warn against, and manufacturing one here would repeat that mistake in the same cycle
it was corrected.

---

## PC-75 — the British-spelling sweep, and the gate that keeps it swept

**Files:** 19 authored files for the sweep; one new suite file (or one new case) for the gate.

49 hits, none of them player-visible. **Two steps, and the second matters more than the first.**

### Step 1 — the sweep

One commit, comments and prose only, no behavior change. The distribution decides the order:

| Site | Hits | Note |
|---|---|---|
| `tests/test_locale.lua` | 16 | Eleven are one thing: a residue-taxonomy class literal spelt `SPLIT COLOUR`. Renaming that literal to `SPLIT COLOR` in its definition and its ten uses clears eleven hits in one edit. Confirm the string is a **local** taxonomy label and not a key any other file matches on before renaming. |
| `tests/test_schema.lua` | 7 | All in the *"no colour row exists…"* case name and its comments. Renaming a **test case name** changes `docs/test-cases.md`, so regenerate the inventory in the same commit and move the README `[tests]` badge only if the count changes (it should not). |
| `docs/smoke-tests.md`, `docs/settings-panel.md`, `docs/common-tasks.md` | 10 | Prose. |
| `tests/test_panel.lua`, `tests/run.lua`, `tests/wow_mock.lua`, `tests/test_override.lua`, `tests/test_libka0s.lua`, `tests/test_apply.lua` | 8 | Comments. |
| `settings/Schema.lua`, `settings/Panel.lua`, `modules/Override.lua`, `core/PrettyChat.lua`, `.luacheckrc` | 5 | Comments in shipped source and config. |
| `docs/schema.md`, `docs/data-flow.md`, `docs/ARCHITECTURE.md` | 3 | Prose; the `ARCHITECTURE.md` hit is inside the `localization-§1` register row's *Why* cell (*"two mandated colour spans"*), so it is a register edit and belongs in the same commit as the others rather than in PC-73's. |

**Do not touch:** `locales/enUS.lua` (already clean), anything under `libs/` or `tests/_kit/` (both
vendored — a change there is drift and both `diff -r` gates go red), `GlobalStrings/` (generated),
and the frozen bundles under `docs/audits/`, `docs/reviews/`, `docs/revendor/` and
`docs/automated-tests/<run>/`.

### Step 2 — the gate, which is the real deliverable

The collection has already proved a swept repo drifts back within one cycle: `M4-13` swept KickCD
clean against this same list and five later items in the same cycle put seventeen instances back,
none of them about spelling and none able to see what it had done. A sweep without a gate buys one
cycle.

**Shape.** A case that:

- carries `localization-§5`'s `BRITISH` and `ALLOWED` lists **copied whole**, with a comment saying
  they are copied whole and must be re-copied whole on the next standard bump. A private subset is
  the exact failure mode the amendment was written to end — the library's own six-substring gate
  stayed green for months while `CANCELLED` shipped in text a player reads.
- builds its candidate set from `git ls-files` and subtracts, by prefix, `libs/`, `tests/_kit/`,
  `GlobalStrings/`, `media/`, `.claude/`, `LICENSE`, `docs/audits/`, `docs/reviews/`,
  `docs/revendor/`, `docs/superpowers/`, `docs/automated-tests/<run>/` and `docs/test-cases.md`.
  **State the scope in the case's own failure message**, because a count whose scope is unstated is
  not a count.
- removes `ALLOWED` as **whole words first**, then matches `BRITISH` as case-insensitive substrings.
  Getting that order wrong makes *analysis* a British spelling.
- fails with the file, line and matched substring for every hit, not just a total.

**Where it goes.** `tests/test_locale.lua` already owns this section's other gates and already reads
the TOC-derived source set, so a new case there is the smallest change. If the file's size argues
against it — it is one of the two densest sites in the sweep — a `tests/test_prose.lua` alongside is
equally correct; the suite list in `tests/run.lua` takes one line either way.

**Risk.** The gate must go **red before it goes green**: write it, watch it report 49, then sweep.
A gate written after the sweep is a gate nobody has seen fail, which is `testing-§12`'s failure mode
arriving inside the fix for it.

---

## PC-69 — the selection-invariant tab-strip geometry case

**Files:** `tests/wow_mock.lua` (capability) and `tests/test_panel.lua` (the case).
**Not** `tests/_kit/` — that is vendored, and editing it breaks the `diff -r` gate.

`options-ui-§13`'s Testing MUST asks the suite to pin the **invariant**, not the mechanism: on a
strip wide enough to wrap, the total reserved band and every row's y offset are identical for every
value of the selection.

**Why it cannot be written today, and what changed.** `tests/_kit/mock_base.lua:132` now reads
`function f:GetHeight() return (self.__geomLive and self.__geomH) or 0 end` — the kit **can** answer
a real height, which it could not when this was first filed. What is still missing is that the mock
answers the **same** height for the selected and unselected cap atlases, so an assertion of
invariance is green against nothing and would be reported as a *missing* case, not a passing one.

**Shape, in two parts.**

1. **`tests/wow_mock.lua`** — give atlas-bearing textures per-atlas heights, so
   `SetAtlas("…-selected")` and `SetAtlas("…")` produce **different** measured heights. This is the
   extender's job by design; the shared kit's fidelity contract is not touched.
2. **`tests/test_panel.lua`** — build the `Categories` page (eight tabs,
   `settings/Panel.lua:618`, the page that wraps first), record the reserved band height and every
   row's y offset for selection = tab 1, then for each remaining tab, and assert every recorded
   number is identical across all eight.

**Name the mutation it dies under**, in a comment on the case, as `options-ui-§13` asks: make the
library read the row pitch off the **selected** tab's cap atlas instead of the inactive one and the
case must go red. That sentence is what distinguishes this case from the vacuous version.

**Sequencing.** This is the only entry that is genuinely blocked on something outside the repo's
control today — it was deferred to `M1-LK-08` for the collection-wide mock change. If `M1-LK-08`
lands the per-atlas heights in the kit, part 1 disappears and only the case remains. Check the kit's
revision before writing part 1.

---

## PC-60 — three conventional group notes in the TOC

**Files:** `PrettyChat.toc` only. Comments; no line moves.

The MUST half is closed. What remains is `toc-file-§5`'s per-group SHOULD: three of six `#` groups
say nothing about which of their lines are free to move.

**Shape.** One added clause per header, in the form `# Locales` (`:24`) already models — *"locale
table — no earlier-load dependency; toc-file-§5 section order"*:

- `# Core` (`:27`) — say that the four annotated positions are the load-bearing ones and that the
  remaining `core/` lines are conventional, reached through closures at call time.
- `# Modules` (`:53`) — say the position is conventional given everything above it, and name what it
  depends on (`core\PrettyChat.lua` for `GetAddon`, `core\Constants.lua` and `core\Util.lua` for its
  file-scope upvalues at `modules/Override.lua:8-12`).
- `# Settings` (`:56`) — replace *"depend on everything else being initialized"*, which is the weaker
  *order matters* form, with a statement of which positions in the group are conventional. The one
  load-bearing position in the group, `settings\Panel.lua`, is already annotated at `:60-63` and
  stays exactly as it is.

**What must NOT change.** No line moves. `toc-file-§5` is explicit that a dependency-correct
within-section order with its load-bearing positions declared is compliant whatever the sequence, and
reordering to satisfy a comment would be work with a real regression risk in exchange for none.

**Risk:** none. Comment-only.

---

## PC-76 — no design; it closes itself

Nothing to change. The record is two commits behind `master` and the delta is entirely `M4c-06`;
`automated-tests-§4`'s checkpoint is **release** and none has been cut. The next release run
regenerates `docs/automated-tests/RESULTS.md` in place and writes a fresh bundle, and both figures
move together. Recorded here only so the +6-function, +209-NLOC delta is not read as growth when it
appears.

**The one thing that would turn this into a real finding** is hand-editing the numbers to match
today's tree. `automated-tests-§4`'s one boundary makes every cell but the watch list's
`Disposition` the runner's output, and a hand-edited generated figure reads as measured — which
`docs/automated-tests/RESULTS.md:67-70` already says about a different cell.
