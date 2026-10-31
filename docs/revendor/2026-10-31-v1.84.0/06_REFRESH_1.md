# Refresh 1 of the v1.84.0 re-vendor

The tag moved before it was pushed, so this is a refresh and not a new re-vendor: the owner's ruling of
2026-11-01 makes `Ka0sMedia_*` the only media picker in the collection, and LibKa0s re-cut v1.84.0 to
carry it. `git -C ../LibKa0s ls-remote --tags origin v1.84.0` prints nothing. Line 1 of `01_DELTA.md`
stays as it was.

## The tag

| | `git -C ../LibKa0s rev-parse 'v1.84.0^{commit}'` |
|---|---|
| Old | `e917ccd` (from `05_SUMMARY.md`) |
| New | `7a8bc0f133ed118d2c79c7c5288b97964e24fae5` |

## Per-file minors

The Step 3c loop, the vendored copy against the extract of the new tag. Only these moved:

| File | Old | New |
|---|---|---|
| `Options.lua` | 35 | 36 |
| `OptionsWidgets.lua` | 40 | 41 |
| `OptionsCompose.lua` | 15 | 16 |
| `OptionsScroll.lua` | 9 | 10 |
| `OptionsMedia.lua` | 1 | 2 |
| `SkinAce.lua` | 5 | 6 |

Kit revision 47 on both sides, and `testkit/` did not change (`git -C ../LibKa0s diff --stat e917ccd
7a8bc0f -- testkit` is empty). Six files changed in `libs/LibKa0s/`, nothing was added or removed, and
no icon moved.

## What this addon owed

Nothing in code, so no contract blocker. `tests/test_skin_picker.lua` and the descriptor's `getLSM` are
unchanged, and PrettyChat's only media rows are the Skin tab's Font and Texture, which were already
`Ka0sMedia_*`. No host code calls `__PatchLSM30Border` or `AceGUI:Create("LSM30_*")`
(`grep -rn 'LSM30_\|__PatchLSM30Border' core settings modules` is empty), and this repo never vendored
AceGUI-3.0-SharedMediaWidgets. The copy of `lib.__MediaWidgetType` is class A: it reaches the addon on
the re-vendor. No adoption and no GitHub issue, as the run's scope set.

## Gate

The icon prune kept 5 files against the 4 declared names and removed 5835 from the copy.
`ka0s-bounded lua tests/run.lua` 656 passed, 0 failed, 1 skipped (657 total);
`ka0s-bounded luacheck .` 0 warnings / 0 errors in 67 files.
