# 04 — Technical Design (Ka0s Pretty Chat)

**Run date:** 2026-10-07 · **Standard:** v2.76.1 · Keyed to `02_DEVIATIONS.md`.

Nothing in this design touches shipped Lua behavior. Every change is documentation, a comment, a
frozen-store record or an issue comment. The only Lua edits are comment-only (`.luacheckrc`, and
optionally comments in `defaults/Profile.lua` and `tests/`). Risk is correspondingly low. The one
guard to keep in mind is `tests/test_doc_structure.lua`, which pins parts of the hub's shape and
load-order line, so any hub edit is re-run through the suite.

---

## PC-103: the missing re-vendor bundle (v1.69.0, v1.70.0)

**Shape.** One consolidated span bundle, as `audit-review-history` defines it:

```
docs/revendor/2026-10-07-v1.69.0-v1.70.0/
  01_DELTA.md     line 1: "Delta: LibKa0s v1.68.1 -> v1.70.0 (span: v1.69.0 v1.70.0)"
  05_SUMMARY.md
```

- `01_DELTA.md` lists the two commits that carried the tags (`136cf54` v1.69.0, `7a1aabf` v1.70.0),
  the files each one added or moved, and the fact that both rolled the `CLAUDE.md` provenance line.
  Read all of this from `git show --stat`, never from memory.
  - v1.69.0 added `WidgetsLineChart.lua`, plus kit 37 with `mock_lines.lua` and a `mock_base.lua`
    hook.
  - v1.70.0 added `WidgetsAutocomplete.lua` and touched `WidgetsLineChart.lua`.
- `05_SUMMARY.md` records that the host adopted nothing. Both additions are `LibKa0s-Widgets-1.0`
  members, and that major is declined here (issue #11, `state:will-not-do`). It also records that the
  vendored-payload gate and the `diff -r` against `v1.70.0` were both green.
- **Why one bundle and not two:** neither re-vendor carried a host decision, so two folders would
  record deliberation that never happened. That is the reason the span form exists.
- **Check:** re-run `AUDIT.md`'s two-listing script. The unrecorded list must be empty.

**Prevention (optional, upstream).** Both commits are subject-only `chore:` commits made outside
`/dev-copilot:wow-revendor-libka0s`. The runner is not involved. The durable fix is to always
re-vendor through the command, because the command writes the bundle. A consumer-side gate
(`test_doc_structure`, or a kit case) that compares the CLAUDE.md tag with the newest bundle's tag
would make this red. That belongs in LibKa0s's kit as a proposal, not as a hand-written local
suite (`testing-§9`).

## PC-104: documentation drift (four items, one sync pass)

1. **`docs/ARCHITECTURE.md:418`, the LibKa0s majors paragraph.** Replace the false sentence with
   one that stays true across re-vendors. For example: "Item, Pool and Widgets are not consumed by
   this addon's own code. Inside the vendored payload, DebugLog resolves Widgets (its resize helper)
   and the Options files resolve Pool and Item, all with `LibStub(…, true)`. The folder is copied
   whole, so every file `LibKa0s.xml` lists ships." Drop the enumerated file list. It has gone stale
   on three of the last four re-vendors, and the XML is the authority.
2. **`docs/performance-sweep.md`.** Re-run the command at the page's head and paste the 43 lines
   verbatim. Change the header to name the commit that carries the re-take. Change the register row
   (`docs/ARCHITECTURE.md:284`, the *Why* cell) to name the same commit, or to say "last re-taken as
   recorded on that page". The second option removes the duplicate fact that let the two drift
   apart. The test-file rows will keep drifting while `tests/` stays in scope; that is deliberate,
   since `tests/` is in the sweep's scope. The page should say "re-take after any suite edit" or
   accept that its tests rows are as of its commit.
3. **`.luacheckrc:34-37`.** Either change "Seven" to "Ten" and add LifecycleSetup, LauncherSetup and
   OptionsSetup to the list, and change "eleven" to "twelve", or rewrite the comment as pure history
   ("until `M4c-06` … eleven files were fixed") with no live count. The second is better because
   `docs/ARCHITECTURE.md:81` already carries the live count. Run `luacheck .` afterwards (comment
   only, so 0/0 is expected).
4. **Digest ids.** Two acceptable shapes:
   - (a) **Rewrite each `PRETTYCHAT-A-NN`** to the in-repo bundle id it stands for. The 2026-09-23
     bundle's `02_DEVIATIONS.md` *ID map* gives `PC-NN` ↔ `PRETTYCHAT-C-NN`, and the consolidated
     `01_CONSOLIDATED_FINDINGS.md` in `Ka0sAddonsCommonTasks` gives `PRETTYCHAT-A-NN` ↔ `PC-NN`.
     For example, `A-07` → `PC-83`, `A-08` → `PC-84`, `A-09` → `PC-85`. Look each one up rather than
     inferring it.
   - (b) **Expand the form once** in the register preamble (`docs/ARCHITECTURE.md:276-280`): "A
     `PRETTYCHAT-A-NN` id is a finding in the 2026-09-23 cross-repo digest
     (`Ka0sAddonsCommonTasks/docs/2026-09-23-REVIEW_AND_STANDARDS_AUDIT_REMEDIATION/01_CONSOLIDATED_FINDINGS.md`),
     not the 2026-09-07 audit's id map, which reused the same prefix."
   - (a) is better for the code comments and tests, which a reader meets without the preamble.
     (b) is enough for the hub. Avoid citing the ambiguous form in new comments.

**Verification:** `lua tests/run.lua` (bounded) and `luacheck .` (bounded), with the
`test_doc_structure` suite green.

## PC-105: hub length (434 → about 360 lines)

- **Move** `docs/ARCHITECTURE.md:362-412` (the census's exemption explanation, the three
  conditions, what the gate checks, and the band note) into `docs/global-strings.md`, under a
  `## The cap exemption` heading. **Keep** in the hub the `### Files over the 1500-line cap`
  heading, the measuring command, the table, the one-line "no cap breach" verdict and the band
  status. The kit's `test_layout_cap` reads the **heading and table**, so they must stay put and
  keep their shape.
- **Shorten** the retired-row narratives (`:293-335`) to one sentence plus the retiring id per row.
  The full reasoning is already in the bundles they cite (`PC-61`, `PC-52`, `PC-88`, `PC-73`).
- Re-check that every Map row still resolves and that `docs/global-strings.md` stays a Tier 3 doc
  that links rather than duplicates (`documentation-§3`).
- **Risk:** `tests/test_doc_structure.lua` may pin text in the census block. Run the suite after the
  move and follow any red to the pinned string rather than weakening the test.

## PC-76: stale automated-test record (Info)

There is no design work. The next release run (`bash tests/_kit/run-automated-tests.sh --release
<ver>` through `ka0s-bounded`, from `/dev-copilot:bump-version`) regenerates `RESULTS.md`. That
picks up the `/dev-copilot:` wording, records `blindFiles`, the commit cell and the newly measured
`listSettings` at CCN 15. **Optional** code hygiene, only when `settings/Slash.lua` is next touched
for a reason of its own: lift the `category` and `formatstring` listings out of `listSettings` into
two named file-local functions (`listCategories()`, `listFormatStrings()`). Those are named for what
they print, not a generic helper (anti-pattern #52), and the tables are built per call as today (not
a per-frame path). A characterization case already exists in `tests/test_slash.lua` for `/pc list`
forms; confirm it covers both keywords before refactoring (`testing-§13`).

## PC-106: superseded issue #8 (Info)

Post one comment on issue #8. It should say that the Profiles page (`settings/Profiles.lua`,
`SP-PC-01`, 2026-09-29) exposes AceDBOptions' profile UI, including per-character, class, realm and
faction profiles; that `options-ui-§3` makes that page the standard's own; and that the refusal
recorded here is superseded. Relabel it `state:done` if the owner prefers the store to read
"shipped". Space the GitHub write per the collection's throttle rule. No register row is involved.

---

## Ordering constraints

- PC-103 is independent and can land first, as its own commit.
- PC-104(1) and PC-105 both edit `docs/ARCHITECTURE.md`. Do PC-104 first, then PC-105, so the
  line-count check happens on the final text.
- PC-104(2) re-takes the sweep. Do it **after** any `tests/` edit in the same pass (including the
  PC-104(4) comment edits in `tests/`), or the re-taken block is stale on arrival.
- PC-106 is a GitHub write and needs the owner's go-ahead.
