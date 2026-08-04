# Proposed changes — HLD + LLD (2026-08-03)

**Standard resolved:** Ka0s WoW Addon Standard **v2.17.1 (2026-08-03)**. The index was fetched over
the network; the section files were read from the pinned clean checkout of the same repo at the same
version (header matched). The standards cross-check below was therefore **performed**, not skipped.

Every change here is a change to **this addon's own files**. Nothing in this document targets a path
under `libs/` or `tests/_kit/`; the one library defect is in its own section at the end, with a
cross-repo handoff.

---

## HLD — themes

### T1. Make the shipped format data provably consistent with Blizzard's

*Covers F-001, F-011.*

The addon's entire value proposition is substituting a template into a `format` call it does not
control. That makes the **conversion signature** — count, order and type of `%` conversions — a hard
contract with Blizzard, and today it is upheld by hand. Two of 81 templates break it in an
error-raising way and four more break it in a silent-information-loss way. Fix the two, decide and
annotate the four.

*Alternative rejected:* wrapping `_G[name]` writes in a guard that repairs a mismatched template at
apply time. It hides a data bug behind runtime cleverness, and it cannot know what the missing
argument *means*.

### T2. Put the contract behind the write seam and teach the preview to tell the truth

*Covers F-002, and structurally prevents recurrences of T1.*

`Schema.Set` is already the one write path (options-ui-§1, slash-commands-§3 both wire to it). Give
it the `validate` step architecture-§5 describes, sourced from the original template's own
signature, and give `NS.RenderSample` a mode that renders **as Blizzard will call it** so the
Preview and `/pc test` exercise the real argument list rather than a synthetic one derived from the
value under test.

*Alternative rejected:* validating in the panel's `OnEnterPressed` and in the CLI `parse` hook. Two
validators either side of one seam, guaranteed to drift; and slash-commands-§6 already says the
`parse` seam is for *parsing*, with the refusal belonging to the write.

### T3. One localized source of truth for "the original"

*Covers F-003 (locale half), enables T2.*

The addon already holds the correct, localized originals in `self.originalStrings`. Read them.
Retiring the enUS dump from the runtime removes ~1.9 MB of shipped Lua and 22,879 resident entries
as a side effect, but the reason to do it is correctness on non-enUS clients.

*Alternative rejected:* shipping localized dumps per client locale — nine times the payload to
duplicate data the client already has in `_G`.

### T4. Collapse the duplicated ordering and partition logic into the schema

*Covers F-007, F-008, F-009.*

Four sites re-derive the same sorted name list and two re-derive the same category partition; three
reset paths repeat the same post-write tail with raw DB writes. All of it belongs beside the rows,
in `settings/Schema.lua`, which is already the single source for order (`AllRows` returns
declaration order precisely so listing and panel cannot disagree).

### T5. Convention and documentation hygiene

*Covers F-004, F-005, F-010, F-012, F-013, F-014, F-015.*

Locale coverage for the strings that were left out, the trailing-colon house rule, the stale
`Config.lua` references and the `NS.Config` member that outlived the file, and two small doc/naming
nits.

---

## LLD — change set

Each change lists target files, the sketch, risk, and the finding IDs it closes.

### C-01 — Correct the two error-raising templates *(F-001)*

**File:** `defaults/Defaults.lua:162`, `:190`.

```lua
-- before (line 162): Blizzard passes ONE arg; this declares two
default = "|cff00ff00Rep|cffffffff | |cff76a5af%s|cffffffff | |cffffffff- %d|cffffffff",
-- after: match the original's signature exactly (%s only)
default = "|cff00ff00Rep|cffffffff | |cff76a5af%s|cffffffff | |cffffffffdecreased|cffffffff",

-- before (line 190): Blizzard passes (name, points); this declares only %d, which eats the name
default = "|cff00ff00Rep|cffffffff | |cffccccccGuardian|cffffffff | |cffffffff+ %d|cffffffff",
-- after: consume both, in Blizzard's order
default = "|cff00ff00Rep|cffffffff | |cffcccccc%s|cffffffff | |cffffffff+ %d|cffffffff",
```

**Risk:** the wording is a taste call the maintainer owns; the *signature* is not. Any wording is
acceptable so long as the conversion list equals Blizzard's.
**Note:** users who already customized these two paths keep their own (broken or fixed) string —
C-02's validator will reject the broken shape on their next edit, and `/pc reset <path>` restores
the corrected default.

**Standards conformance:** data change only; no rule engaged.

### C-02 — Signature validation on the write seam + a truthful preview *(F-002, F-011)*

**Files:** `settings/Schema.lua` (new local + `Schema.Set`), `modules/Override.lua`
(`NS.RenderSample`, `PrettyChat:Test`), `settings/Panel.lua` (Preview row), `locales/enUS.lua`.

1. New helper beside the rows (one implementation, both consumers):

```lua
-- settings/Schema.lua
-- The conversion signature of a format string: the ordered list of "[n$]type" tokens,
-- with %% stripped. Two strings are interchangeable to string.format iff these are equal.
function Schema.Signature(fmt) ... end          -- reuses the scanner extracted from buildSampleArgs
function Schema.SignatureError(row, value)      -- nil when compatible, else a reason string
```

2. `Schema.Set` gains the validate step architecture-§5 specifies:

```lua
function Schema.Set(path, value)
    local row = byPath[path]
    if not row then return false end
    local err = Schema.SignatureError(row, value)     -- string rows only
    if err then
        NS.Print(err)                                 -- names the path and what it expected
        NS.Debug("Set", "%s rejected: %s", path, err)
        return false
    end
    row.set(value) ... -- unchanged tail
end
```

3. `NS.RenderSample(fmt, referenceFmt)` — when a reference is given, the sample args are built from
   **the reference's** signature, so the preview renders the template the way the game will call it
   and surfaces the mismatch as the error it is. `PrettyChat:Test` and the panel Preview both pass
   the original (from C-03).

**Risk:** false rejections. Mitigate by accepting "same tokens in the same order, possibly truncated
at the tail" (which is exactly the F-011 shape) and rejecting only reordering, type changes and
extra conversions. Cover both arms with tests before wiring the UI.

**Standards conformance:** implements architecture-§5's `validate → write → onChange` and
slash-commands-§6's "MUST NOT silently store a value the addon cannot honor". The refusal message is
printed through `NS.Print` (slash-commands-§4) and carries no trailing colon. Rejected alternative:
per-call-site validation (would create a second write-adjacent code path, against options-ui-§1's
single write seam).

### C-03 — Read the original from the live snapshot; retire the eager GlobalStrings load *(F-003)*

**Files:** `settings/Panel.lua:180-182`, `modules/Override.lua` (accessor), `PrettyChat.toc:42-52`,
`.pkgmeta`, `docs/global-strings.md`, `docs/file-index.md`, `docs/module-map.md`,
`tests/test_panel.lua` (the two cases that assert against `NS.GlobalStrings`).

```lua
-- modules/Override.lua — one accessor, so the panel and the C-02 validator agree
function PrettyChat:GetOriginal(globalName)
    local snap = self.originalStrings
    if snap ~= nil and snap[globalName] ~= nil then return snap[globalName] end
    return _G[globalName]          -- a key added to Defaults.lua since load
end

-- settings/Panel.lua
local origValue = PrettyChat:GetOriginal(globalName) or L["(original not available)"]
```

Then remove the ten `GlobalStrings\GlobalStrings_0NN.lua` lines from the TOC. Keep the folder in the
repo as a developer reference (it is already `.pkgmeta`-ignored for the source dump; extend the
ignore to the chunks) and update `docs/global-strings.md` to describe it as build-time-only, with
the "any key, even one added since ship" workflow re-pointed at the checked-in dump.

**Risk:** `self.originalStrings` only covers keys present in `NS.Defaults` at `OnEnable` — which is
exactly the set the panel renders. The `_G` fallback covers a key added to `Defaults.lua` without a
reload; after C-04 that snapshot is authoritative for the session.
**Sequencing:** land C-04 first, so the snapshot this change starts trusting is the corrected one.

**Standards conformance:** localization-§4 in spirit — the addon stops keying a user-visible display
on a hardcoded English snapshot and uses the client's own localized data. No layout rule is engaged
by removing files from the TOC (toc-file-§5 governs section order, which is unchanged minus one
section).

### C-04 — Snapshot once, with a sentinel for absent keys *(F-006)*

**Files:** `core/PrettyChat.lua:37-44`, `modules/Override.lua:78-80`.

```lua
-- core/PrettyChat.lua
function PrettyChat:OnEnable()
    -- ONCE per session. AceAddon re-runs OnEnable on any Disable()/Enable() cycle, and by then
    -- _G holds OUR strings — re-snapshotting would record them as Blizzard's, permanently.
    if not self.originalStrings then
        self.originalStrings = {}
        for _, catData in pairs(NS.Defaults) do
            for globalName in pairs(catData.strings) do
                local v = _G[globalName]
                self.originalStrings[globalName] = (v ~= nil) and v or NS.Const.NO_ORIGINAL
            end
        end
    end
    ...
```

```lua
-- modules/Override.lua — restore arm distinguishes "was absent" from "not snapshotted"
elseif self.originalStrings then
    local orig = self.originalStrings[globalName]
    if orig ~= nil then
        _G[globalName] = (orig ~= NS.Const.NO_ORIGINAL) and orig or nil
        restored = restored + 1
    end
end
```

`NS.Const.NO_ORIGINAL` is a private sentinel table in `core/Constants.lua`.

**Risk:** low; `restored` counts change slightly for absent keys (they now count).

**Standards conformance:** no rule engaged; keeps the deterministic-order comment at
`modules/Override.lua:54-61` true.

### C-05 — One ordered index and one category partition, in the schema *(F-007, F-009)*

**Files:** `settings/Schema.lua`, `modules/Override.lua:64-84`, `settings/Panel.lua:277-285`,
`settings/Slash.lua:205-224`.

```lua
-- settings/Schema.lua — built once, in the same loop that builds the rows
Schema.orderedNames = {}        -- [category] = { GLOBALNAME, ... } sorted
byCategory          = {}        -- [category] = { row, ... } in declaration order
function Schema.OrderedNames(category) return Schema.orderedNames[category] or EMPTY end
function Schema.RowsByCategory(category) return byCategory[category] or EMPTY end
```

Call sites drop their local collect+sort and iterate `Schema.OrderedNames(category)`.
`EMPTY` is a shared frozen empty table; `RowsByCategory` now returns the live table, matching the
already-documented reasoning for `AllRows` (`settings/Schema.lua:300-303`).

**Risk:** a caller that mutated the returned table would now mutate the index — none do (verified:
both call sites only iterate). Note it in the function's comment.

**Standards conformance:** architecture-§5 (schema as single source of order). No performance rule is
engaged — this is not instrumentation, so the anti-pattern #43 gating idiom does not apply.

### C-06 — A batch write seam for the three reset paths *(F-008)*

**Files:** `settings/Schema.lua` (new `Schema.ApplyScope`), `modules/Override.lua:90-136`.

```lua
-- settings/Schema.lua
-- The BULK counterpart of Set: the caller performs the DB mutation, we run the single tail —
-- one ApplyStrings, one panel notify, one summary line. Row-by-row Set would run ApplyStrings
-- ~350 times and flood the console buffer (debug-logging-§9); this keeps the tail in one place
-- so a future validate/onChange step cannot be skipped by a reset.
function Schema.ApplyScope(scopeLabel, category, mutate)
    mutate()
    local applied, restored = PrettyChat:ApplyStrings()
    Schema.NotifyPanelChange(category)
    NS.Debug("Reset", "%s → applied %d restored %d", scopeLabel, applied, restored)
end
```

`ResetCategory`, `ResetAll` and `ResetString` become three-line callers.

**Risk:** none behavioral — the emitted debug lines keep their current text.

**Standards conformance:** satisfies architecture-§5's "one helper" while honoring debug-logging-§9's
one-summary-per-bulk-pass rule. Rejected alternative: routing resets through `Schema.Set` row by row
(explicitly rejected in `settings/Schema.lua:308-317` for the spam reason, and this change preserves
that reasoning rather than reversing it).

### C-07 — Locale coverage for the strings that were left out *(F-004, F-005)*

**Files:** `settings/Schema.lua:72-73`, `settings/Panel.lua:167-170`, `:392-394`,
`modules/Override.lua:220-288`, `settings/Slash.lua` (usage/error lines), `locales/enUS.lua`.

```lua
-- before
label   = "Enable " .. category,
tooltip = "Enable or disable all " .. category .. " string overrides.",
-- after — one key, one argument, translator-reorderable
label   = L["Enable %s"]:format(category),
tooltip = L["Enable or disable all %s string overrides."]:format(category),
```

`modules/Override.lua:220` loses its trailing colon in the same edit (F-005). Every new key is added
to the `enUS` manifest block so the file's stated invariant becomes true again.

**Risk:** `L[...]` returns the key on miss, so a missed manifest entry degrades to English rather
than erroring. `tests/test_locale.lua` already walks authored strings — extend it to assert that
every `L[...]` literal appears in the manifest.

**Standards conformance:** localization-§1/§2 (English-string keys, metatable fallback),
localization-§5 (US English — the new keys use `color`/`gray` spellings already in use),
slash-commands-§4 (no trailing colon). Rejected alternative: per-fragment keys (`L["Enable "] ..
category`), which is the word-order trap localization-§2 exists to avoid.

### C-08 — Naming and documentation hygiene *(F-010, F-012, F-013, F-014, F-015)*

**Files:** `core/Constants.lua:29,37`, `core/Namespace.lua:7`, `core/Util.lua:26-28`,
`settings/Schema.lua:8,167,249`, `settings/Panel.lua:421-423`, `core/PrettyChat.lua:50-51`,
`settings/OptionsSetup.lua:134`, `docs/file-index.md:58`, `docs/module-map.md`.

- `Config.lua` → `settings/Panel.lua` in all three comments; `§4.5` → `architecture-§5`.
- `NS.Config` → `NS.Panel` (three call sites, plus `tests/test_panel.lua`).
- `Color.yellow` gains a `gold` alias (or the `cmd()` comment names the code it uses) so the palette
  reads against slash-commands-§4 without a hop.
- `NS.version`'s literal fallback becomes `Const.VERSION_FALLBACK`, referenced from
  `core/Namespace.lua`, with a line in `docs/common-tasks.md`'s release steps.
- `docs/file-index.md:58` drops the `TODO.md` clause (no `TODO.md` is added — anti-pattern #27).

**Standards conformance:** naming-cheatsheet (module table `NS.<PascalCase>` matching its file),
CLAUDE.md/`filename-§N` cross-reference scheme, anti-pattern #27.

---

## Upstream change-set — lands in the LibKa0s repo, not here

### U-01 — Correct three cross-references in `LibKa0s-Options-1.0` *(F-016)*

- **Owning repo:** `LibKa0s` (sibling repository).
- **File within the library:** `LibKa0s/Options.lua` — lines corresponding to
  `libs/LibKa0s/Options.lua:117`, `:156` ("Ka0s standard §3.4" → `architecture-§5` / the intended
  rule) and `:216` (`options-ui-§41` → `options-ui-§1`).
- **Fix:** comment text only; no behavior change.
- **Minor bump:** `Options.lua`'s `MINOR` 5 → 6 (every released change to a lib file bumps its minor
  — library-stack-§7, anti-pattern #45).
- **Re-vendor:** copy the whole `LibKa0s/` ship folder into every consumer, each as its own commit,
  with `diff -r <LibRepo>/LibKa0s <Addon>/libs/LibKa0s` empty afterwards. In this addon that is a
  standalone commit that touches only `libs/LibKa0s/`.
- **Explicitly not:** editing `prettychat/libs/LibKa0s/Options.lua` in place. The next re-vendor
  would revert it with no commit in this repo to explain the regression.
