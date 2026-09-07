# 04 — Technical Design (Ka0s Pretty Chat)

**Run date:** 2026-09-07 · **Standard:** v2.38.0 (2026-09-02)

Remediation design for the eleven deviations in `02_DEVIATIONS.md`. Every section is keyed to its ID.
Nothing here changes addon behavior: the whole set is comments, config, docs, one stub member and one
test. That is the shape of the work, and it is worth saying up front because it sets the risk budget —
the only change that can alter what a player sees is **none of them**.

---

## Design A — TOC annotations (PC-60)

**Files:** `PrettyChat.toc` only.

The rule wants two things in the file listing: every load-bearing line commented **at the line** with
what resolves, and each group of conventional lines marked once. The file already does the first
correctly twice (`:28-32`, `:34-35`), so this is replication of an in-repo pattern, not a new
convention.

Three lines need a comment; the text should name the **symbol** and the **publisher**, not merely say
the order matters:

- above `core\Util.lua` — `NS.Const.Color` is taken as a file-scope upvalue at `core/Util.lua:14`, so
  the line must follow `core\Constants.lua`;
- above `core\CoreSetup.lua` — `NS.Util` is taken at `core/CoreSetup.lua:39`, and the `NS.Print`
  reclaim at `:131-132` must follow `core\PrettyChat.lua`'s `NewAddon`;
- above `settings\Panel.lua` — `NS.Helpers` is taken at `settings/Panel.lua:22`, published by
  `settings\OptionsSetup.lua`.

Then one *conventional* note per group, so the unannotated remainder stops reading as unclassified.
`core\State.lua`, `core\Database.lua` and `core\Namespace.lua` are the candidates; each should be
checked against its own file scope before being called conventional rather than assumed.

**Risk:** none to runtime. The one real hazard is writing a comment that is *wrong* — an annotation
asserting a dependency that does not exist is worse than none, because the next author will preserve
an order for a reason that was never true. Derive each from the `.lua`, not from the TOC's current
sequence.

**Ordering:** independent of everything else.

---

## Design B — register hygiene (PC-61, PC-62)

**Files:** `docs/ARCHITECTURE.md` only, plus one upstream issue.

These are opposite operations on the same table and should land in one change so the table is read
once.

**PC-61 — retire the `toc-file-§5` row.** The row (`:222`) records a conflict the standard has since
resolved in the addon's favour. Delete it and add a line under the table's preamble noting the
retirement and why, in the shape `audit-review-history` describes: a retired row is not silently
dropped, because a reader who remembers it needs to find out what happened to it. Do **not** replace it
with a row saying the TOC is now compliant — compliance is not a register entry.

**PC-62 — record or escalate the message-bus applicability.** Two routes:

1. **Local (fast).** Add a row: Rule `architecture-§4`; *What differs* — no closed bus although
   `modules/Override.lua:80-96` registers two game events; *Why* — one feature module and no second
   receiver, so the CallbackHandler `(message, target)` clobber the section exists to prevent cannot
   arise, and the fan-out is a direct call inside the single write path (`Schema.Set` →
   `Schema.NotifyPanelChange`); *Decided* — today; *Re-check trigger* — the second feature module, or
   the first `LibStub("AceEvent-3.0")` in this addon.
2. **Upstream (correct).** Open a `WowAddonStandards` issue proposing the trigger be narrowed. The
   current wording — *"any module that registers game events"* — makes the MUST fire on an addon that
   has nobody to send a message to, which is the same unsatisfiable shape §4's own applicability
   paragraph was written to remove for the two-module case.

Do route 1 **and** route 2: the row keeps the next audit from re-litigating, the issue is what actually
ends it. `docs/ARCHITECTURE.md:129`'s re-check trigger sentence should be updated in the same change,
since it currently reads as if the section were below the threshold.

**Risk:** none. **Ordering:** PC-61 before PC-62 only so the table is edited once.

---

## Design C — package ignore list (PC-63)

**Files:** `.pkgmeta`.

Add `- .claude` to the `ignore:` block with a one-line comment matching the neighbouring entries'
voice (agent tooling, dev-only, never loaded by the client). Decide `.pkgmeta` explicitly: either list
it or add a comment saying the packager reads it and it is harmless in the payload — the point of the
exhaustive sweep is that every root dot-entry has an answer, not that every one is ignored.

While in the file, consider whether a `# every root dot-entry is accounted for` marker comment is
worth adding, so the next tool that writes a dot-directory is caught by the reader rather than by an
audit.

**Risk:** the packager reads this file; a malformed YAML line breaks the build. The change is one
list item in an existing block, so the mitigation is simply to keep the two-space indent the other
rows use.

**Ordering:** independent.

---

## Design D — the Core stub's missing member (PC-64)

**Files:** `core/CoreSetup.lua`, `tests/test_libka0s.lua`.

Two edits, and they must land together or the test still cannot see the code.

**The stub.** Inside the `if not lib then` branch (before the `return` at `:84`), publish:

```lua
-- Published on BOTH paths for the same reason NS.Format is: the first caller
-- added later would work in every install that has the library and be nil here.
-- The library draws an addon-named close glyph; without the library there is
-- nothing to draw, so the honest degraded answer is nil.
function NS.MakeCloseButton(_parent, _onClick) return nil end
```

`core/DebugLogSetup.lua:89` already ships exactly this shape for its own copy, so the degraded
contract is consistent across seams. The alternative — leaving the member out with the reason written
down — is permitted by the standard, but it is the weaker choice here: the file's own `NS.Format`
paragraph (`:74-77`) argues against it, and a `nil`-returning function costs one line.

**The test.** Add `MakeCloseButton = instance.NS.MakeCloseButton` to `coreSurface`
(`tests/test_libka0s.lua:683-689`) and to the non-vacuity key list at `:695`. The projection is
documented as derived from a grep over `core/CoreSetup.lua` (`:682`); re-running that grep is the
check that the list is complete, and it should be re-run rather than reasoned about — that is exactly
how this member went missing.

**Risk:** the live arm must still pass. `NS.MakeCloseButton` on the live path is a two-argument
closure over the three-argument library function; the parity assertion compares **types**, so a
two-argument stub matches. The existing wrapper-shape case (`tests/test_libka0s.lua:258-264`) already
pins that the live wrapper forwards `addonName`, and must not be weakened.

**Ordering:** independent, and the cheapest real fix in the bundle.

---

## Design E — refresh the automated-test record (PC-65)

**Files:** a new `docs/automated-tests/<stamp>/` bundle plus `docs/automated-tests/RESULTS.md`.

Run the vendored runner — `tests/_kit/run-automated-tests.sh` — which writes the bundle and prepends
the table row. Then rewrite, **by hand and against the new bundle**, the four standing sections that
are still anchored at `20260807-114404`:

- the ANALYSIS.md roll-call in the intro (`:7-9`) — it omits `20260825-103457` entirely;
- `## Test suite` (`:44`) — 260/17 becomes the new figures, and the "sat at 260 across three
  consecutive runs" narrative needs rewriting, since source **has** changed since;
- `## Lint` (`:48`) — "over 17 files" becomes 18, and the 91%-generated-NLOC figure must be
  re-measured from the new `complexity.txt`, not scaled;
- the `layout-§1` band table (`:84`) — the `GlobalStrings.lua` NLOC and the "nothing newly crossed a
  band at …" clause both name a run.

**The prohibition that matters:** do not hand-edit a generated number. `RESULTS.md:74-79` already
makes this argument about a different row, and it applies to itself. Anything the runner emits is the
runner's; only the prose around it is hand-written.

**Risk:** none to the addon. The one process risk is running the script with `--release`, which would
start anti-pattern #53's shelf-life clock on the `GlobalStrings` Accepted disposition. This should be a
plain run.

**Ordering:** run this **last** in the remediation, so the recorded bundle reflects the tree after
every other change — otherwise it is stale again on the day it is written.

---

## Design F — renormalize the working tree (PC-66)

**Files:** none edited; the index and four checkouts are rewritten.

```
git add --renormalize .
git status                       # review
# per straggler:
rm <path> && git checkout -- <path>
```

Then re-run the working-tree agreement command from `03_EVIDENCE.md` §4 and confirm it prints `0`.

Two of the four stragglers live under `docs/revendor/2026-08-25/`, which is a **frozen** bundle
directory — but line endings are a byte-level property of the checkout, not content, so renormalizing
them is not editing the bundle's text. The other two are vendored library files, and the vendored-payload
diffs in `03_EVIDENCE.md` §2 already prove their content is byte-correct against the tag; only their
on-disk terminators disagree.

**Risk:** `--renormalize` rewrites the index, which produces a diff that looks large and is entirely
line terminators. Review it as such and do not let it ride along with a content change — this belongs
in a commit of its own.

**Ordering:** last but one, before Design E, so the record is written over a normalized tree.

---

## Design G — documentation shape (PC-67, PC-68, PC-70)

**Files:** `README.md`, `docs/settings-panel.md`, `docs/ARCHITECTURE.md`, `CLAUDE.md`.

**PC-67.** Delete `README.md:71-82` — the sentence and the eight-row Tab table. Before deleting,
diff its content against `docs/settings-panel.md`: anything the README says about a tab that the topic
doc does not is content to move, not to lose. Keep `:66-69` (the page-granularity table the rule
mandates) and `:84` (behavior prose, not an inventory). The README's own "two pages" sentence at `:64`
stays accurate afterwards.

**PC-68.** Do not restructure the map. Open a `WowAddonStandards` issue: `documentation-§3` mandates
five verification-and-record docs and then describes a three-table register with no place to put them,
so every compliant addon must either invent a fourth table (as this one has) or file mandated docs as
Tier 3. Propose the fourth table be named in the section. Until it resolves, leave
`docs/ARCHITECTURE.md:190` where it is and add a one-line note above it citing the open issue, so the
next audit reads it as a raised question rather than an unexamined departure.

**PC-70.** Insert a single adherence sentence at `CLAUDE.md:4`, above the `## Standards compliance`
heading — *"Built to the Ka0s WoW Addon Standard: https://github.com/tusharsaxena/WowAddonStandards."*
Leave `:7-8` alone; item 3 needs it.

**Risk:** none. The README edit is the only one a player could notice, and what they lose is a table
duplicating a topic doc.

**Ordering:** independent of everything else.

---

## Design H — the strip-geometry case (PC-69)

**Files:** `tests/test_panel.lua` (or a new case in `tests/test_libka0s.lua`), `tests/wow_mock.lua`.

The library is already correct — `libs/LibKa0s/OptionsWidgets.lua:384-399` measures the wrapped-row
pitch once from the inactive cap atlas. What is missing is the case that would notice a regression, and
it needs the harness to be able to fail it first.

**Step 1 — the mock.** `tests/_kit/mock_base.lua:97` answers `GetHeight() == 0` for every frame, and
it **must not be edited** (it is vendored). Extend in `tests/wow_mock.lua` instead: give a texture that
has been handed an atlas a height derived from the atlas name, so `Options_Tab_Active_*` and
`Options_Tab_*` answer **different** numbers. That asymmetry is the whole mutation the case dies under.

**Step 2 — the case.** Build the Categories page (`settings/Panel.lua:745`), which has eight tabs, and
for each possible selection record the reserved band height and every tab row's y offset. Assert all
selections produce identical geometry. With step 1 in place, reverting the library to "pitch from the
first tab drawn" turns the case red; without step 1 it is green against nothing, which is the state
`testing-§12` names.

**Risk:** the mock change touches a shared fixture, so run the whole suite, not just the new case. If
the height model turns out to affect unrelated cases, scope it to textures that have had `SetAtlas`
called rather than to all frames.

**Ordering:** independent, but it is the only item here with real design content, so it should not be
bundled with the trivia.

---

## Cross-cutting notes

- **Nothing in this bundle touches `libs/` or `tests/_kit/`.** Both are vendored whole and both diff
  clean against `v1.25.0`. A fix that wants to change either is a LibKa0s change followed by a
  re-vendor, never a local patch (anti-pattern #45).
- **Nothing here needs a version bump.** No user-facing behavior changes, so `## Version:`,
  `## What's new` and `## Version History` all stay put — with the one exception that PC-67 edits the
  README, which is not a release-note event.
- **The green gate applies throughout:** `lua tests/run.lua` and `luacheck .` after every step. Both
  are green today, so any red is the step that just ran.
- **Two items are upstream questions, not addon defects** (PC-62's trigger wording, PC-68's table
  count). Both should be filed as `WowAddonStandards` issues in the same sitting, because the local
  half of each is a note pointing at the issue number.
