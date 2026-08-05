# 02 — Proposed changes (HLD + LLD)

Standard resolved for this review: **Ka0s WoW Addon Standard v2.21.0 (2026-08-04)**, fetched from
`https://github.com/tusharsaxena/WowAddonStandards` (`standards/STANDARDS.md` plus every section file
its Sections list links). The conformance check below is a **guardrail on this remediation**, not a
compliance audit — pre-existing deviations unrelated to these changes are out of scope and belong to
`/wow-addon:standards-audit`.

No change in this document targets a path under `libs/` or `tests/_kit/`.

---

## HLD

### Theme A — the defaults table must agree with the strings it replaces

**Findings:** F-001, F-002, F-003.

PrettyChat's whole contract is "write a replacement format string into `_G[GLOBALNAME]` and let
Blizzard's own code format it". That makes the *caller's* argument list — Blizzard's, not the
addon's — the binding contract for every entry in `defaults/Defaults.lua`. Two entries break it, and
they break it in the only direction that is unsafe: extra or re-typed conversions raise inside
Blizzard's chat handler, where dropping trailing conversions is silently fine.

The repo already ships the evidence needed to check this mechanically: `NS.GlobalStrings` is a
complete reference copy of Blizzard's strings, loaded in the test environment. So the fix is two data
edits plus one real test to replace a tautological one.

*Alternative considered and rejected:* make `RenderSample` / `ApplyStrings` defensive — pad missing
arguments, or refuse to write an over-specified override. Rejected on two grounds. It would put a
runtime guard in the addon's one hot pass to compensate for bad static data, and it would mask the
same class of defect in every future default rather than surface it at the point it is authored.
`anti-patterns` is explicit that a workaround around a data defect is not a fix for it.

*Trade-off:* the corrected `FACTION_STANDING_*` lines change what two users' chat messages look like.
That is unavoidable — the current lines do not render at all.

### Theme B — one source of truth for "the Blizzard original"

**Findings:** F-004, and F-005 as its downstream consequence.

`self.originalStrings` is the addon's live, per-client, per-locale snapshot of exactly the strings it
overrides, taken before the first write. The panel ignores it and reads a shipped enUS dump instead.
Making the panel prefer the snapshot removes a locale bug, removes a staleness class, and makes the
panel agree with `/pc test`, which already reads the snapshot.

`architecture-§2`'s single-namespace shape means the snapshot is reachable from the panel with no new
plumbing (`PrettyChat.originalStrings`, the same object `settings/Panel.lua:15` already holds).

*Alternative considered and rejected:* keep the dump and localize it (ship `NS.GlobalStrings` per
locale). Rejected: it multiplies a 2 MB artifact by the number of supported locales to reproduce data
the client already has in memory.

*Deliberately deferred, not folded in:* dropping the eager GlobalStrings load (F-005). It is a
packaging/load-order change with its own verification, and `docs/global-strings.md` records why a
naive removal is not enough. Change **C-03** below is the fallback-preserving step; the removal
itself is a follow-up with a measurement attached.

### Theme C — the translatable surface must match what the manifest claims

**Finding:** F-006.

Four user-visible settings strings are built by concatenation and never reach `L`, while
`locales/enUS.lua` presents its seeded block as the authoritative manifest. `localization-§4` requires
format strings rather than concatenated fragments precisely because the fragment order is
language-specific.

### Theme D — small correctness and honesty repairs

**Findings:** F-008, F-009, F-010. Three one-line changes; no behavior change on the live path.

---

## Upstream change-set (lands in `LibKa0s`, not here)

### U-01 — clamp and de-falsify the kit's suite durations `[F-007]`

* **Repo:** `LibKa0s`
* **File within the library:** `testkit/run-automated-tests.sh` (vendored here read-only as
  `tests/_kit/run-automated-tests.sh`)
* **Fix:** derive each suite's elapsed time from a monotonic source where the shell offers one, and
  in all cases clamp the computed difference at zero before emitting it, so a wall-clock step cannot
  produce a negative `durationMs`. Either raise the resolution above whole seconds or rename the
  emitted field to reflect its true resolution — the current pairing of a `Ms` suffix with a
  seconds-resolution source is the part that misleads.
* **Version movement:** bump the testkit revision recorded in the kit's own `README.md` and in the
  manifest it emits.
* **Consumer work:** re-vendor the whole `testkit/` folder into `prettychat` (currently at testkit
  rev 6 per `f5ebb36`) **and every other consumer**, each as its own commit whose only content is the
  vendored copy.
* **Explicitly not done here:** no edit to `tests/_kit/run-automated-tests.sh` in this repo. Already
  committed bundles are append-only evidence and are **not** to be corrected retrospectively — the
  `-1000` in `docs/automated-tests/20260804-233338/manifest.json` stays exactly as the runner emitted
  it, for the same reason `RESULTS.md` already leaves the `Max CCN 0` fault in place.

---

## LLD

### C-01 — correct the two arity-broken defaults `[F-001, F-002]`

**File:** `defaults/Defaults.lua`

`FACTION_STANDING_DECREASED_GENERIC` (lines 162-165) — the reference takes one argument:

```lua
-- before
default = "|cff00ff00Rep|cffffffff | |cff76a5af%s|cffffffff | |cffffffff- %d|cffffffff",
-- after  (reference: "Reputation with %s decreased." — one %s, no amount to show)
default = "|cff00ff00Rep|cffffffff | |cff76a5af%s|cffffffff | |cffffffffdecreased|cffffffff",
```

`FACTION_STANDING_INCREASED_GUARDIAN` (lines 190-193) — the reference passes `(name, points)`:

```lua
-- before  (%d lands on the guardian's NAME)
default = "|cff00ff00Rep|cffffffff | |cffccccccGuardian|cffffffff | |cffffffff+ %d|cffffffff",
-- after   (explicit positions, so the intent survives a re-read)
default = "|cff00ff00Rep|cffffffff | |cff76a5af%1$s|cffffffff | |cffccccccGuardian|cffffffff | |cffffffff+ %2$d|cffffffff",
```

**Risk:** these are `default` values, so a user who has already overridden either row keeps their
(equally broken) stored value. `Schema.Set`'s auto-clear compares against the default
(`settings/Schema.lua:111-115`), so a stored value that used to equal the old default now persists as
an explicit override. Called out in `03_SMOKE_TESTS.md` and in the release notes; a user recovers with
that row's **Reset** button or `/pc reset Reputation.FACTION_STANDING_*.format`. No migration is
warranted — `Database.SCHEMA_VERSION` governs *storage shape*, which is unchanged
(`savedvariables-§4`), and a migration that rewrote a user's stored text would be the addon editing
the user's own edit.

**Regression pressure:** none on the pass count by itself; C-02 moves it.

### C-02 — replace the tautological defaults case with a reference-arity check `[F-003]`

**File:** `tests/test_defaults.lua`

Keep `test("every default format string renders with sample arguments", …)` — it is a cheap syntax
guard and it is honest about *that*. **Add** a case beside it that asserts the thing the suite
currently claims:

```lua
-- red under: restore either FACTION_STANDING_* default from before C-01, or add a
-- trailing "%d" to any entry whose reference string has none.
test("every default's conversions fit the Blizzard string it replaces", function()
    for _, e in ipairs(entries) do
        local ref = NS.GlobalStrings[e[2]]
        t.truthy(ref, ("%s.%s has a reference string"):format(e[1], e[2]))
        local want, got = conversions(ref), conversions(e[3].default)
        t.truthy(#got <= #want, ("%s.%s: %d conversions over a reference with %d")
            :format(e[1], e[2], #got, #want))
        for i = 1, #got do
            t.eq(class(got[i]), class(want[i]),
                ("%s.%s: slot %d is %s but Blizzard passes %s")
                :format(e[1], e[2], i, got[i], want[i]))
        end
    end
end)
```

`conversions` / `class` are two small file-locals in this suite (walk `%[n$][flags][width][.prec]type`,
honouring `%n$`; class `s` as *string* and `dioufgexc` as *number*). They are **not** a second copy of
`RenderSample` — that function synthesizes values, this one only classifies positions.

**Risk:** the four *safe* mismatches (`COMBATLOG_DISHONORGAIN`, `LOOT_DISENCHANT_CREDIT`,
`OPEN_LOCK_OTHER`, `OPEN_LOCK_SELF` — each drops trailing conversions) must stay green; the `#got <=
#want` shape above allows exactly that and forbids the unsafe direction. Re-run the suite and confirm
those four still pass before landing.

**Regression pressure:** this **adds one case**, 255 → 256. Per `testing-§7`, `docs/test-cases.md`
must be regenerated (`lua tests/run.lua --list > docs/test-cases.md`) and `README.md:7`'s `[Tests]`
badge moved to `256/256` **in the same commit** — not as a follow-up. This review does not do that;
the implementing change does.

### C-03 — the panel's Original row reads the live snapshot first `[F-004]`

**File:** `settings/Panel.lua` (`buildStringRow`, lines 176-185)

```lua
-- before
local origValue = (NS.GlobalStrings and NS.GlobalStrings[globalName])
                 or L["(original not available)"]
-- after
-- The OnEnable snapshot is this client's own value, in this client's locale, taken
-- before the first override was written (core/PrettyChat.lua:38-43). The shipped
-- GlobalStrings dump is an enUS reference and only a fallback for a key the snapshot
-- missed (a global that does not exist on this client).
local origValue = (PrettyChat.originalStrings and PrettyChat.originalStrings[globalName])
                 or (NS.GlobalStrings and NS.GlobalStrings[globalName])
                 or L["(original not available)"]
```

**Risk:** the panel builds after `OnEnable` (`core/PrettyChat.lua:50-52` →
`NS.Config.RegisterPanels` → `H.CreateOptionsPanel`), so the snapshot is always populated by then;
the two fallbacks cover the degenerate orderings anyway.

**Test movement:** `tests/test_panel.lua:309-317` currently asserts against
`NS.GlobalStrings[sorted[1]]`. It must assert against the seeded snapshot instead — `tests/loader.lua`
already seeds `"ORIG:<GLOBALNAME>"` for every registered global (`seedOriginals`, lines 58-69), which
makes the *new* behavior distinguishable from the old one in a single `t.eq`. The companion case at
`:320-327` (degraded load with the `GlobalStrings/` chunks skipped) keeps its meaning and should now
assert the **snapshot** still renders — which is a stronger statement than the one it makes today.
Case count unchanged by C-03.

### C-04 — route the four unmanifested strings through `L` `[F-006]`

**Files:** `settings/Schema.lua`, `settings/Panel.lua`, `locales/enUS.lua`

```lua
-- settings/Schema.lua:72-73
label    = L["Enable %s"]:format(category),
tooltip  = L["Enable or disable all %s string overrides."]:format(category),

-- settings/Panel.lua:392-394
defaultsTooltip = (not isGeneral)
    and L["Reset all %s strings to defaults."]:format(category) or nil,

-- settings/Panel.lua:167-169
enableTooltip = enableTooltip .. "\n\n" .. Color.gray
    .. L["Shared with %s — both registrations write the same Blizzard global; the last category to apply wins on /reload."]
       :format(table.concat(others, ", "))
    .. Color.reset
```

`settings/Schema.lua` currently has no `local L`; add `local L = NS.L` beside its other file-locals.
`locales/enUS.lua` gains the four keys in its seeded block, under the existing comment structure.

**Risk:** none functionally — `NS.L`'s metatable returns the key verbatim, so enUS output is
byte-identical except that the interpolation point moves from concatenation to `%s`. Category names
stay untranslated, which is correct: they are schema path segments (`Loot.enabled`), not prose.

**Test movement:** `tests/test_locale.lua` asserts the manifest against call-site usage; the four new
keys satisfy it by construction. No case count change expected — confirm by re-running.

### C-05 — three one-line repairs `[F-008, F-009, F-010]`

**File:** `settings/Panel.lua`

* `:368` — `NS.SlashCommands:LandingRows()` (colon), matching `libs/LibKa0s/Slash.lua:460`'s
  declaration. The degradation stub (`settings/Slash.lua:111-115`) already tolerates the extra
  argument; leave it alone.
* `:182` and `:248` — parenthesize the `gsub`, matching `core/Util.lua:18` and
  `settings/Schema.lua:245`.

**File:** `settings/OptionsSetup.lua`

* `:90-95` — comment only. Replace "sits behind a maker that is a no-op on this path, so a nil
  reaches nothing" with the actual invariant: *every page body returns early when `H.EnsureScroll`
  answers `nil`, which it always does on this path, so no consumer of these constants is reached —
  including `settings/Panel.lua:275`, which does arithmetic and would raise rather than no-op.* The
  constants stay out of the stub.

**Risk:** none. No behavior change.

---

## Standards conformance (per change)

| Change | Conformance |
|---|---|
| **C-01** | Data-only. No new deviation. The rejected alternative (runtime argument padding in `ApplyStrings`) was declined as a workaround masking a data defect (`anti-patterns`), and because it would add work to the addon's only write pass (`performance-§2`). No migration added, per `savedvariables-§4` — the stored *shape* is unchanged. |
| **C-02** | Required by `testing-§12` (a case must be able to go red; the new one carries its `-- red under:` line naming the exact mutation). Adds no duplicate of library coverage (`testing-§8`) — the check is over this addon's own data. Triggers `testing-§7`: `docs/test-cases.md` regenerated by `--list` and the README badge moved **in the same change**; never hand-edited. Explicitly **not** done: weakening or deleting the existing tautological case to change a result. |
| **C-03** | Keeps the panel inside `options-ui-§5`'s host-half boundary — it changes only what the host's own bespoke block reads, not any library-drawn widget. No layout constant is copied (`options-ui-§8`). |
| **C-04** | `localization-§4` (format strings, not concatenated fragments) and `localization-§1` (user-facing strings are wrapped). Rejected alternative: leaving them as-is and softening `locales/enUS.lua`'s manifest claim — that trades a real defect for a weaker promise. |
| **C-05** | `options-ui-§8` is why F-009's repair is a **comment**, not an import of `ROW_VSPACER` into the stub: a host copy of a library layout constant is forbidden, and the stub's omission is right even though its stated reason is not. |
| **U-01** | Routed as an upstream change with a kit-revision bump and a re-vendor commit per consumer, per the vendored-code rule. No local edit under `tests/_kit/`. Committed bundles under `docs/automated-tests/` are left untouched — `performance-§10`'s prohibition on hand-editing a generated figure applies to correcting one after the fact as much as to inventing one. |

---

## Expected movement for the next release's regeneration

* **Complexity:** C-02 adds a test-suite case with two small file-locals. Today's fresh lizard run
  shows `tests/test_defaults.lua` at 15 functions / avg CCN 2.5 and **zero** functions above CCN 15
  repo-wide; the new case and helpers are each straight-line loops and should land well under the
  threshold. Nothing on the watch list's five-nearest set (`Database.RunMigrations` 12,
  `buildParentBody` 11, `runTest` 11, `PrettyChat:ApplyStrings` 11, `sampleArg` 11) is touched by any
  change here. To be **confirmed by the next release's regeneration**, not measured now.
* **Tests:** 255 → 256 (C-02). `docs/test-cases.md` and the README badge move with it.
* **Perf:** no offline scenarios exist to move (LIBKA0S-12). If F-005 is ever acted on, that is the
  change that should come with a measurement, not this set.
