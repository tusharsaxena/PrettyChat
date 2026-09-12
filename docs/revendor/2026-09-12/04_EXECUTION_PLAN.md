# 04 — Execution plan

One adopted candidate, B1. All four Step-7 fences hold: `libs/` and `tests/_kit/` are not touched
after the copy, no setup file changes, the diff changes no behavior beyond the deleted stamp, and no
close control is involved.

## B1. Take the kit's `Printf` on the `NewAddon` target (#30)

**Files:** `tests/wow_mock.lua` only.

1. Delete `object.Printf = noop` from the override-9 `NewAddon` (old line 349).
2. Delete `local function noop() end` (old line 95). Its only other use was that stamp, and keeping
   it would give luacheck W211 (unused function).

**Characterization before the change.** Nothing in the addon or its suites calls `Printf`:

```sh
grep -rn 'Printf' --include='*.lua' . | grep -v '^./libs/' | grep -v '^./tests/_kit/'
# tests/wow_mock.lua:349:            object.Printf = noop     (the stamp itself, and nothing else)
```

So "the suite still passes" says only that nothing depended on the no-op. The assertion that proves
the change is about **what `NS.Printf` renders**. An ad-hoc probe (scratch, not committed) boots
one instance through `tests/loader.lua` and calls `NS:Printf(frame, "%d items", 3)` with a
recording frame:

| Tree | `type(NS.Printf)` | Rendered | `NS.Print ~= NS.Printf` |
|---|---|---|---|
| Before (stamp present) | `function` | `nil`: the no-op printed nothing | `true` |
| After (stamp deleted) | `function` | `\|cff33ff99table: 0x…\|r: 3 items`, AceConsole's shape | `true` |

The kit's mixin now reaches `NS`, and `NS.Print` is still the addon's own printer, taken back by
`core/CoreSetup.lua:142`. No committed test was added. `Printf` has no caller in this addon, and
the kit's own `tests/test_mock_base.lua` owns the mixin's contract, so a consumer case would pin
the kit's behavior rather than PrettyChat's.

**Gate:** `lua tests/run.lua` gives 329 passed, 0 failed, 0 skipped. `luacheck .` gives 0 warnings
/ 0 errors in 44 files. The EOL case passes after the straggler repair
(`git add tests/wow_mock.lua && rm tests/wow_mock.lua && git checkout -- tests/wow_mock.lua`).

**Commit boundary:** its own commit, after the re-vendor commit `d35aa85`.
