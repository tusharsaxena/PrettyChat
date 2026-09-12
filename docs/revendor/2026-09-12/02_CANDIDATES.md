# 02 — Candidates: what v1.30.0 brings PrettyChat

Sources, in the spec's order:

```sh
git -C ../LibKa0s log --oneline v1.29.0..v1.30.0
# e369e0f The v1.30.0 release record, re-taken on the review-fixed tree
# e5f6906 Kit 16 review: double release raises, the release wipe, RegisterEvent validates, a per-build event registry
# aaef20a The v1.30.0 release record
# 7aaf1fe Kit 16: AceGUI:Release, AceEvent's event half on an embed, Printf, and the runner's mode in every consumer
git -C ../LibKa0s show v1.30.0:CHANGELOG.md                     # the v1.30.0 block, lines 13-100
git -C ../LibKa0s show v1.30.0:docs/api/testkit/version-16-docs.md
```

No major's minor moved (01_DELTA.md §3c), so there is no `docs/api/<Major>/` surface diff to read.
The only versioned contract that changed is the test kit's, revision 15 to 16.

## Class A: reached the addon on the re-vendor alone

| Item | Evidence | Why no host change is needed here |
|---|---|---|
| `AceGUI:Release(w)` and `widget:Release()` (#27) | CHANGELOG v1.30.0 lines 31-57; `version-16-docs.md:32`, `:40-94` | PrettyChat never calls `AceGUI:Release`. `tests/test_panel.lua:1026-1033` fires `OnRelease` through `wow_mock.lua`'s `:Fire` alias (`w.Fire = w.__fire`), which does not depend on a release model. No local `Release` shim exists to delete. |
| AceEvent's event half on an `Embed` target (#29) | CHANGELOG lines 59-81; `version-16-docs.md:33`, `:110-113` | PrettyChat does not embed AceEvent. `modules/Override.lua:68` says it uses "A plain event frame rather than AceEvent-3.0". The `_events` recording in `tests/wow_mock.lua` (`frameMethods:RegisterEvent`/`UnregisterEvent`) is on the `CreateFrame` stub for `PrettyChatCombatWatcher`, not on an AceEvent embed, so #29 neither replaces nor touches it. |
| The runner's recorded mode, in every consumer (#28) | CHANGELOG lines 100-118 (the `vendor_sync.lua` block) | `tests/test_vendor_sync.lua` calls `VendorSync.register(_G.PC_TEST, {})`, so the new case arrives with the copy. `git ls-files -s tests/_kit/run-automated-tests.sh` shows `100755`, so it passes on the default path. The suite moves 328 to 329, and `docs/test-cases.md` and the README badge moved in the re-vendor commit (testing-§5). |

## Class B: host change required

### B1. Delete the `object.Printf = noop` stamp in `tests/wow_mock.lua` (#30)

- **What:** the kit's `NewAddon` now stamps AceConsole's `Printf` beside `Print`
  (`tests/_kit/mock_base.lua:577-578`). The local `AceAddon-3.0` override in `tests/wow_mock.lua`
  calls `baseNewAddon(self, object)` and then stamped `object.Printf = noop` (old line 349), which
  overwrote the kit's `Printf` with a no-op. While that line stays, #30 has no effect in this repo.
- **Evidence:** CHANGELOG v1.30.0 lines 83-98; `version-16-docs.md:34` and `:138` onward;
  `tests/_kit/README.md` "The Ace fakes, and the shims they replace" ("Delete the local copy when
  you re-vendor").
- **Files touched:** `tests/wow_mock.lua` only. The stamp line goes, and so does
  `local function noop() end` (old line 95), whose only other use was that stamp. Leaving it would
  put luacheck at 1 warning (W211).
- **What stays in the override:** `GetAddon`, the recorded `RegisterChatCommand` /
  `slashCommands`, and the `Print` that writes to this environment's `chatFrame`. The kit supplies
  none of these in this shape.
- **Characterization:** nothing in `tests/`, `core/`, `modules/` or `settings/` reads or calls
  `Printf` (`grep -rn Printf --include='*.lua'` outside `libs/` and `tests/_kit/` finds only the
  stamp). The addon publishes and takes back `NS.Print` and `NS.Format`
  (`core/CoreSetup.lua:142-143`), never `NS.Printf`. So the suite passing before and after proves
  only that nothing depended on the no-op. A separate probe (04_EXECUTION_PLAN.md) shows the
  adoption actually lands: `NS.Printf` renders AceConsole's shape afterwards and was silent before.
- **Blast radius:** subtractive in the test harness only, with no production code. Afterwards
  `NS.Printf` holds the AceConsole mixin, as it does in the live client, and nothing calls it.
- **Recommendation: adopt.** The owner's brief says to delete the line if the suite stays green,
  and it does.

## Class C: whole-module adoption

None raised. The unconsumed majors (`Item`, `Pool`, `Widgets`, `Perf`) did not move in this
release. `Perf` stays declined under the `performance-§12` row in `docs/ARCHITECTURE.md` →
`## Documented deviations`, and nothing in v1.30.0 changes that row's premise.

## Considered and not a candidate

- **A `#29` migration of the frame-stub `_events` field to the kit's `__events`.** It is not the
  same contract. `__events` belongs to an AceEvent target, and PrettyChat's watcher is a plain
  frame. The kit's own frame stub records only `RegisterUnitEvent`/`UnregisterAllEvents`
  (`tests/_kit/mock_base.lua`, `__unitEvents`), so there is nothing to adopt.
  `tests/test_override.lua:194-199` and `:228` read `f._events.PLAYER_REGEN_*` and keep working.
  **Nothing is declined.**
