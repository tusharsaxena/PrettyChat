# 02 — Proposed changes (HLD + LLD)

**Standard resolved:** Ka0s WoW Addon Standard **v2.38.0 (2026-09-02)**. The cross-check was
performed; every change below is stated against it and none introduces a new deviation.
This is a **guardrail on remediation**, not a compliance audit — pre-existing ratified deviations
are untouched and unenumerated.

**Scope rule observed throughout:** no change in this document targets a path under `libs/` or
`tests/_kit/`. There are no upstream findings in this review, so there is no upstream change-set
section — the one place the library came up (`PRETTYCHAT-R-02`) is a case where the library is
**already correct** and this addon must adopt it.

---

## HLD — themes

### Theme A — Move the format-signature invariant from the suite to the write path

**Rationale.** `docs/ARCHITECTURE.md` names *"Format-specifier signatures must match Blizzard's"* as
an invariant that "no test or lint will name" when broken — and then enforces it only against the
81 shipped defaults, at test time, using a parser (`conversionSequence`) that lives inside
`tests/test_defaults.lua` and is unreachable from anywhere else. The one input the invariant exists
to protect — what a **player** types — is unchecked, and the Preview that looks like a check
structurally cannot be one, because it synthesizes its arguments from the format under test.

The fix is not a new subsystem: it is one parser, moved to where three callers can reach it, plus a
refusal in the single write path that already exists. Covers `PRETTYCHAT-R-01`, `PRETTYCHAT-R-08`.

**Alternatives considered and rejected.**

- *Validate in the panel's `OnEnterPressed` only.* Rejected: `/pc set` bypasses it, and
  `architecture-§5` / this addon's own single-write-path invariant put exactly this kind of
  post-write policy in `Schema.Set`. Two validators would be the drift the seam exists to prevent.
- *Wrap `ApplyStrings`' `_G` write in `pcall`.* Rejected: the raise happens later, in Blizzard's
  chat handler, not in our write. A `pcall` here catches nothing.
- *Push the parser into `LibKa0s`.* Rejected on `library-stack-§4`'s three bars: one consumer, and
  the semantics are specific to Blizzard's GlobalStrings rather than general. High frequency inside
  one addon is explicitly not a promotion reason.
- *Warn rather than refuse.* Rejected for the panel's New box and `/pc set` alike: the failure mode
  is a repeating Lua error inside Blizzard code, which the player cannot attribute to us. Refusing
  with an explanation is recoverable; storing and warning is not.

### Theme B — Stop hand-rolling what `LibKa0s-Options-1.0` already renders

**Rationale.** `settings/Panel.lua`'s `buildParentBody` is a private copy of `O.BuildLandingPage`,
and the copy carries the exact texture-pooling defect the library's version was written to fix
(`libs/LibKa0s/OptionsWidgets.lua:288-301` documents the bug; `:323` is the half this addon is
missing). `anti-patterns` #47 and `options-ui-§5` both name this shape. Deleting the copy fixes the
defect and removes the addon's highest-CCN-but-one function at the same time.
Covers `PRETTYCHAT-R-02`, and moves `PRETTYCHAT-R-05`'s watch list.

**Alternatives considered and rejected.**

- *Add `group:SetCallback("OnRelease", function() tex:Hide() end)` to the private body.* Rejected: it
  fixes the symptom and keeps the fork. The library's version also owns the ClearScroll ordering, the
  `applyLabelFont` guard pair (`OptionsWidgets.lua:1266-1268` — the pair written out 28 times across
  six repos), the spacer constants and the notes-as-a-function deferral. Keeping a copy means keeping
  all of that in sync by hand.
- *Draw the logo through `NS.Icon`.* Rejected: `NS.Icon` addresses the **shared catalog**
  (`libs/LibKa0s/media/`). This logo is the addon's own art under `media/logos/` per `layout-§4`, and
  `library-stack-§3`'s "a missing mark is added upstream" applies to marks, not to per-addon
  branding. The path stays host-supplied, handed to the library as `spec.logo`.

### Theme C — Make the committed evidence say what the code says

**Rationale.** Three standing records now describe a prior state: the `performance-§12` sweep, the
`RESULTS.md` narrative, and the `localization-§1` register row plus the `ARCHITECTURE.md` invariant
that cites a test as proof of something the test cannot check. `audit-review-history` makes reading
the register before filing a MUST in both directions; a register that asserts a check exists is worse
than one that admits the gap. Covers `PRETTYCHAT-R-03`, `PRETTYCHAT-R-04`, `PRETTYCHAT-R-05`,
`PRETTYCHAT-R-09`, `PRETTYCHAT-R-10`.

**Alternative rejected.** *Regenerate `RESULTS.md` now.* Forbidden here: `automated-tests-§4` puts
regeneration at the **release** checkpoint, and a hand-edited report reads as measured. Change C3 is
a note for the next release, not a task that runs the tool.

### Theme D — Two small correctness/consistency repairs

`ApplyStrings`' truthiness-gated restore (`PRETTYCHAT-R-07`) and the in-place defaults mutation
(`PRETTYCHAT-R-12`). Both are one-line, both are behaviour-preserving on every shipping
configuration, and both remove a shape that is wrong for a reason a reader has to reconstruct.

### Theme E — Localization consistency in the slash surface

`PRETTYCHAT-R-06`. Deliberately **last** and deliberately optional: the addon holds a ratified
English-only deviation (`localization-§1`), so this buys structure rather than behaviour. It is
grouped with C2 because they touch the same claim.

---

## LLD — change-set

Change IDs are `PC-C-nn`. Each names its finding IDs, its files, and its standards conformance.

---

### PC-C-01 — Publish one conversion-sequence parser on the namespace

**Findings:** `PRETTYCHAT-R-08` (and prerequisite for `PRETTYCHAT-R-01`)
**Files:** `modules/Override.lua`, `tests/test_defaults.lua`

Move the parser out of the suite, beside the printf walker that already exists for
`buildSampleArgs`, and publish it.

Before — `tests/test_defaults.lua:174` (file-local, unreachable from the addon):

```lua
local function conversionSequence(fmt)   -- returns { [1]="s", [2]="d", n=2 }
```

After — `modules/Override.lua`, beside `buildSampleArgs`:

```lua
--- The ordered printf conversion sequence of a format string, honoring WoW's
--- positional `%n$type`. Published because THREE callers need the same answer:
--- Schema.Set's write-path guard (PC-C-02), buildSampleArgs' argument synthesis,
--- and tests/test_defaults.lua's shipped-defaults gate. One parser, because two
--- would disagree about `%%` or about a positional gap on exactly the input that
--- matters.
--- @return table  array of conversion letters, plus `n` = the highest index used
function NS.ConversionSequence(fmt) ... end
```

`tests/test_defaults.lua` drops its local and calls `NS.ConversionSequence`.

**Risk.** Low, and it is a **characterization** move: the suite's existing 81-default assertions are
the characterization test, and they must stay green byte-for-byte across the move. Do not "improve"
the parser in the same commit.

**Standards.** `architecture-§3` (module owns its domain logic). Stays host-side per
`library-stack-§4` — one consumer, Blizzard-GlobalStrings-specific semantics. No new deviation.

---

### PC-C-02 — Refuse a format whose conversion sequence does not match Blizzard's

**Findings:** `PRETTYCHAT-R-01`
**Files:** `settings/Schema.lua`, `locales/enUS.lua`, `tests/test_schema.lua`,
`docs/test-cases.md` (regenerated), `README.md` (badge)

In `Schema.Set` (`settings/Schema.lua:464`), before `row.set(value)`:

```lua
function Schema.Set(path, value)
    local row = byPath[path]
    if not row then return false end

    -- The one invariant a stored value can break from OUTSIDE this addon: a format
    -- that asks for conversions Blizzard does not pass makes string.format raise
    -- INSIDE Blizzard's chat handler, on every matching line, for the rest of the
    -- session. The Preview cannot catch it — buildSampleArgs synthesizes exactly the
    -- arguments the format asks for, so a wrong format previews perfectly. The
    -- reference is this client's own OnEnable snapshot, never the shipped
    -- GlobalStrings/ dump (PC-R-04).
    if row.kind == "string_format" then
        local ok, why = NS.FormatMatchesOriginal(PrettyChat, row.globalName, value)
        if not ok then
            NS.Print(L["That format cannot be used: %s"]:format(why))
            return false
        end
    end

    row.set(value)
    ...
```

`NS.FormatMatchesOriginal(addon, globalName, fmt)` lands in `modules/Override.lua` beside
`NS.ConversionSequence` and `NS.OriginalFormat`, and applies the **same rule the suite already
applies to the defaults**: the candidate's sequence must be a positional prefix of Blizzard's —
surplus conversions are refused (they raise), trailing truncation is allowed (`string.format` ignores
surplus arguments), and a type mismatch at any position is refused.

Callers get the refusal for free on both surfaces, because both already route through `Schema.Set`
(`settings/OptionsSetup.lua:225`, `settings/Slash.lua:173`).

**Degraded path.** `NS.OriginalFormat` falls back to the live `_G[globalName]`
(`modules/Override.lua:333-336`), and if that is nil too the guard **passes** rather than refusing —
an unknown reference must not lock a player out of their own setting.

**Regression pressure (required by `testing-§4`).** This adds cases to `tests/test_schema.lua`
(a surplus-conversion write is refused and stores nothing; a truncating write is accepted; a
type-mismatched write is refused; an unknown-reference write is accepted). The pass count moves from
**300**, so `docs/test-cases.md` and the README `[tests]` badge move **in the same commit** —
regenerated via `lua tests/run.lua --list`, never hand-edited. One key is added to
`locales/enUS.lua`'s manifest.

**Risk.** Medium, and it is a **behaviour change on a shipping verb**: `/pc set` and the panel now
reject inputs they used to accept. That is the point, but it needs the smoke test in
`03_SMOKE_TESTS.md` and a line in `05_FINAL_SUMMARY.md`'s API-changes list. Watch the refusal
message: it must name the expected sequence, or a user cannot act on it.

**Standards.** `architecture-§5` / the addon's own single-write-path invariant (one seam, one
policy). `slash-commands-§1` (a refused verb explains itself through the tagged printer).
`localization-§1` (the message is routed and carries a `%s` rather than being concatenated).
`savedvariables` (nothing new is stored). **Rejected option:** validating in the panel widget's
callback, which `architecture-§5` rules out by putting post-write policy in the single seam.

---

### PC-C-03 — Adopt `H.BuildLandingPage` and delete the private landing body

**Findings:** `PRETTYCHAT-R-02`, and it moves `PRETTYCHAT-R-05`'s watch list
**Files:** `settings/Panel.lua`, `settings/OptionsSetup.lua`, `tests/test_panel.lua`

Replace `buildParentBody` (`settings/Panel.lua:646-721`, 51 NLOC / CCN 11) with:

```lua
-- The landing page is the LIBRARY's renderer, not a private body. O.BuildLandingPage
-- owns the ClearScroll ordering, the logo block, the label-font guard pair and the
-- section spacers; what is ours is the DATA — which art, which one-liner, which rows.
-- The private copy this replaces never hid its Texture on release, so the 300px logo
-- rode AceGUI's pooled SimpleGroup frame into whatever acquired it next (PC-R-02); the
-- library fixed exactly that at OptionsWidgets.lua:323 and every host calls it.
local function buildParentBody(ctx)
    H.BuildLandingPage(ctx, {
        logo     = LOGO_PATH,
        logoSize = LOGO_SIZE,
        notes    = function() return TOC_NOTES end,
        sections = {
            {
                heading = L["Slash Commands"],
                rows    = function()
                    local out = { Color.gray .. L["/prettychat is an alias for /pc"] .. Color.reset }
                    for _, line in ipairs(NS.SlashCommands:LandingRows()) do
                        out[#out + 1] = line
                    end
                    return out
                end,
            },
        },
    })
end
```

`settings/OptionsSetup.lua`'s degradation stub gains `BuildLandingPage = function() end`, beside the
other no-ops, with the standing comment about why it is a no-op and not a lookalike (it sits after
the same `EnsureScroll` guard the rest do).

`core/Constants.lua`'s `SECTION_TOP_SPACER` / `SECTION_BOTTOM_SPACER` become unreferenced once the
private body goes — check before deleting them, and if they go, `tests/test_constants.lua` moves with
them in the same commit.

**Risk.** Medium-low and **visual**: the library's spacer constants may differ from the two this file
used, so the landing page's vertical rhythm can shift by a few pixels. That is the intended
direction (`options-ui-§8`: one set of values, and a host copy is the copy that goes stale). Verify
by eye in `03_SMOKE_TESTS.md`. `tests/test_panel.lua`'s two landing-page cases must stay green
without being rewritten to fit — if they need rewriting, the adoption changed content, which it
should not.

**Standards.** `options-ui-§5` (the landing body is host **data** through the library's renderer),
`anti-patterns` #47 (no private copy beside the library), `options-ui-§1` (the stub declares the new
member as a no-op, never a lookalike), `library-stack-§3` (per-addon branding art stays under
`media/logos/`; only shared marks come from the catalog). **Rejected option:** adding the
`OnRelease` hide to the private body — fixes the symptom, keeps the fork, keeps four other
library-owned details in sync by hand.

---

### PC-C-04 — Restore on `~= nil`, and say so when a global is missing

**Findings:** `PRETTYCHAT-R-07`
**Files:** `modules/Override.lua`, `core/PrettyChat.lua`, `tests/test_apply.lua`

`modules/Override.lua:154`:

```lua
-- before
elseif self.originalStrings and self.originalStrings[globalName] then
-- after
elseif self.originalStrings and self.originalStrings[globalName] ~= nil then
```

and in `core/PrettyChat.lua`'s `OnEnable` snapshot loop, count the globals this client does not
define and emit **one** `NS.Debug("Init", …)` line naming the count (never one line per global —
`debug-logging-§9`).

**Risk.** Very low. On every shipping Retail client the two expressions agree, because
`tests/test_defaults.lua` pins all 81 globals as present. Add one `tests/test_apply.lua` case that
loads with a global deliberately absent from the mock and asserts the restore still runs.

**Standards.** `savedvariables`' `== nil`-rather-than-`or` rule (a falsy stored value is a real
answer), applied to the snapshot; `debug-logging-§9` for the single summary line.

---

### PC-C-05 — Build the merged AceDB defaults without mutating `NS.ProfileDefaults`

**Findings:** `PRETTYCHAT-R-12`
**Files:** `core/PrettyChat.lua`

`core/PrettyChat.lua:20-25`:

```lua
-- before: grafts Database's `global` onto the module-level table defaults/Profile.lua published
local defaults = NS.ProfileDefaults
for k, v in pairs(NS.Database.defaults) do defaults[k] = defaults[k] or v end

-- after: a fresh table, so NS.ProfileDefaults keeps meaning what its file declares
local defaults = { profile = NS.ProfileDefaults.profile }
if NS.Database and NS.Database.defaults then
    for k, v in pairs(NS.Database.defaults) do
        if defaults[k] == nil then defaults[k] = v end
    end
end
```

**Risk.** Very low; AceDB already deep-copies defaults into the DB, so nothing stored changes.
`tests/test_database.lua` and `tests/test_lifecycle.lua` are the characterization.

**Standards.** `savedvariables-§2` (the defaults table is data, read once), and it removes the
"mutating the defaults table at runtime" shape without changing any stored value.

---

### PC-C-06 — Correct the `performance-§12` sweep and its result block

**Findings:** `PRETTYCHAT-R-03`
**Files:** `docs/performance.md`

Re-run the command at `docs/performance.md:33-36` **verbatim**, paste its real output in place of the
current block (`:40-45`), and add a disposition paragraph for the two new
`settings/Panel.lua:531-532` hits:

> `C_Timer.After(0, …)` is a **one-shot**, scheduled once per settings-page render to size the
> string-list tree after the client's own layout pass. It is not a ticker and it cannot fire during
> combat: `SetRenderer` refuses to render under lockdown, so the render that would schedule it never
> runs (`tests/test_libka0s.lua`, *"the settings panel refuses to render under combat"*). Criterion
> (a) is unaffected.

Also drop `combatWatcher:UnregisterEvent(event)` from the recorded result: the stated regex is
case-sensitive and cannot produce it. Re-read the `performance-§12` row's re-check trigger in
`docs/ARCHITECTURE.md` while there and confirm it is not fired (it names *"an event handler that runs
DURING combat"*, which this is not); if it is not, the row is unchanged.

**Risk.** None to runtime. **Do not widen the regex to suppress the hit** — the sweep's value is
that it is the same command every time.

**Standards.** `performance-§12` (the exemption's evidence is a committed, reproducible sweep),
`documentation-§3`.

---

### PC-C-07 — Correct the localization claims to match what is checked

**Findings:** `PRETTYCHAT-R-04`, and the comment half of `PRETTYCHAT-R-09` / `PRETTYCHAT-R-10`
**Files:** `docs/ARCHITECTURE.md`, `tests/test_locale.lua` (comment only),
`core/MediaSetup.lua` (comment only), `tests/test_vendor_sync.lua` (comment only)

1. `docs/ARCHITECTURE.md` `## Invariants`: change *"User-facing strings go through `NS.L`"* to state
   the real extent — the settings panel's static strings and the `COMMANDS` descriptions are routed;
   the per-string `label` values in `defaults/Defaults.lua`, the `/pc` error and usage lines in
   `settings/Slash.lua` and the `/pc test` report labels in `modules/Override.lua` are not.
2. The `localization-§1` register row: replace *"the routing SHOULD is **satisfied**"* with a
   statement of what is routed and what is not, keeping the English-only shipping decision and its
   re-check trigger intact. `localization-§3` still makes this a terminal compliant state; what
   changes is that the row stops claiming a check it does not have.
3. `tests/test_locale.lua:1-7`: the header currently claims an unwrapped string "surfaces here". It
   cannot. Say what the two drift cases actually guard (wrapped-but-unmanifested, and
   manifested-but-dead) and name the gap.
4. `core/MediaSetup.lua:54-58`: name `settings/Panel.lua`'s `LOGO_PATH` as the one host-side texture
   path and say why it is outside the shared catalog (per-addon branding art, `layout-§4`).
5. `tests/test_vendor_sync.lua:25`: drop the stale `v1.10.2` from the illustrative quote.

**Risk.** None — documentation and comments only. **No committed audit or automated-test bundle is
touched**; frozen evidence stays frozen.

**Standards.** `audit-review-history` (the register is the single home of a ratified deviation and
must be true), `documentation-§3`, `testing-§12` (a case's comment must not overstate what it
falsifies).

---

### PC-C-08 — Route the slash error and usage lines as whole sentences

**Findings:** `PRETTYCHAT-R-06`
**Files:** `settings/Slash.lua`, `locales/enUS.lua`, `tests/test_locale.lua`,
`docs/test-cases.md` if the pass count moves

Each concatenated line becomes one routed sentence with the colour escapes applied outside it, in
the shape `settings/Panel.lua:234-239` already uses:

```lua
-- before
NS.Print(note("unknown category '" .. arg .. "'. Valid: ") .. table.concat(CATEGORY_ORDER, ", "))
-- after
NS.Print(note(L["Unknown category '%s'. Valid: %s"]:format(arg, table.concat(CATEGORY_ORDER, ", "))))
```

Same treatment for the four `usage:` lines, the three-line `reset` deprecation notice, the two
`list` headers and `"all settings reset to defaults"`. Every new key joins the `locales/enUS.lua`
manifest in the same commit, or `tests/test_locale.lua`'s "every localized call site is in the enUS
manifest" case reddens immediately — which is exactly the guard working.

**Risk.** Low but wide — it touches most of `settings/Slash.lua`'s output. `tests/test_slash.lua`
asserts on some of these strings; expect to update those assertions, and check each edit changes the
**wrapping** and not the wording.

**Standards.** `localization-§1` (format strings, never concatenated fragments), `slash-commands-§1`
(output stays on the tagged printer). This does **not** retire the English-only deviation — the row
stays, corrected by PC-C-07.

---

### PC-C-09 — Note the expected complexity movement for the next release

**Findings:** `PRETTYCHAT-R-05`
**Files:** none in this change — a note carried into `05_FINAL_SUMMARY.md`

The next `automated-tests` regeneration (at release, per `automated-tests-§4`, via
`/wow-addon:bump-version`) should confirm:

- `buildParentBody` (CCN 11) **disappears** — PC-C-03 deletes it.
- `fitTree` (`settings/Panel.lua:413`, CCN **13**, today's maximum) **appears** on the
  nearest-threshold list, where the current narrative does not carry it.
- `PrettyChat:ApplyStrings` reads **12**, not the 11 the narrative records.
- `Schema.Set` gains one branch from PC-C-02 (CCN 10 → ~12) — still well under 15.
- The narrative's *"260 cases, across 17 suite files"* and *"Clean over 17 files"* re-derive to the
  post-change counts over 18 suite files.

**Do not run the tool into the repo as part of this work**, and do not gate a commit on complexity —
`automated-tests-§4` puts the checkpoint at the tag, and a commit-time complexity gate is a
documented anti-pattern.

---

## Standards conformance summary

| Change | Rules that shaped it | New deviation introduced? |
|---|---|---|
| PC-C-01 | `architecture-§3`, `library-stack-§4` (promotion bars **not** met → stays local) | No |
| PC-C-02 | `architecture-§5`, `slash-commands-§1`, `localization-§1`, `testing-§4` (inventory + badge move in the same change) | No |
| PC-C-03 | `options-ui-§5`, `options-ui-§1`, `options-ui-§8`, `anti-patterns` #47, `library-stack-§3` | No — it **removes** a #47 shape |
| PC-C-04 | `savedvariables` (`== nil`), `debug-logging-§9` | No |
| PC-C-05 | `savedvariables-§2` | No |
| PC-C-06 | `performance-§12`, `documentation-§3` | No |
| PC-C-07 | `audit-review-history`, `documentation-§3`, `testing-§12` | No — it **corrects** a register claim |
| PC-C-08 | `localization-§1`, `slash-commands-§1` | No — the English-only row stands |
| PC-C-09 | `automated-tests-§4`, `performance-§10` | No |

Nothing above proposes editing `libs/` or `tests/_kit/`, deleting or rewriting a frozen bundle under
`docs/audits/` or `docs/automated-tests/`, weakening or deleting a test to reach green, or
hand-editing `docs/test-cases.md`.
