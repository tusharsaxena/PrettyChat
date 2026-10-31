# Refresh 2 of the v1.84.0 re-vendor

The tag moved again before it was pushed, so this is a second refresh and not a new re-vendor: the
owner's ruling of 2026-11-01 deletes `lib.__PatchLSM30Border` with no stub, and LibKa0s re-cut v1.84.0
to carry it. `git -C ../LibKa0s ls-remote --tags origin v1.84.0` prints nothing. Line 1 of `01_DELTA.md`
stays as it was.

## The tag

| | `git -C ../LibKa0s rev-parse 'v1.84.0^{commit}'` |
|---|---|
| Old | `7a8bc0f133ed118d2c79c7c5288b97964e24fae5` |
| New | `b5229b876e803768322fb4d8c66be69f01c8e4a1` |

## Per-file minors

The Step 3c loop, the vendored copy against the extract of the new tag. Only these moved:

| File | Old | New |
|---|---|---|
| `Options.lua` | 36 | 37 |
| `OptionsDrawer.lua` | 3 | 4 |
| `OptionsMedia.lua` | 2 | 3 |

Kit revision 47 on both sides, and `testkit/` did not change (`diff -rq` of the two commits' extracts
is empty). Three files changed in `libs/LibKa0s/`, nothing was added or removed, and no icon moved.
`OptionsDrawer.lua` changed in a comment only.

## What this addon owed

Nothing in code, so no contract blocker. PrettyChat never called the member:
`grep -rn 'PatchLSM30Border' core settings modules tests` is empty before and after, so no call, test,
stub or guard was removed or added. No authored test pins these minors. The one remaining hit in
`libs/` is `Options.lua:46`, the library's own history comment on minor 36, which is upstream's.
No adoption and no GitHub issue, as the run's scope set.

## Gate

Both payloads' content diffs were empty on the whole copy before the prune. The icon prune kept 5 files
against the 4 declared names and removed 5835 from the copy.
`ka0s-bounded lua tests/run.lua` 656 passed, 0 failed, 1 skipped (657 total);
`ka0s-bounded luacheck .` 0 warnings / 0 errors in 67 files.
