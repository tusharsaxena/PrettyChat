# Summary

Part of Ka0sAddonsCommonTasks `docs/2026-11-06-REVENDOR_LIBKA0S_V1_89/` (V89-PC).

## Tag

LibKa0s v1.85.0 -> v1.89.0. The base is the tag named on the `CLAUDE.md` provenance line (line 44), and it matches both the last payload commit `d9ccc92` and the vendored minors (01_DELTA.md, 3a and 3b).

| File | old | new |
|---|---|---|
| Toast.lua | 3 | 4 |
| Widgets.lua | 22 | 23 |
| DebugLogDiagnostics.lua | 6 | 7 |
| IconBrowserSources.lua | (new) | 1 |
| IconBrowserWindow.lua | (new) | 1 |
| IconBrowser.lua | (new) | 1 |

Kit revision 50 -> 51, in the same commit as the library payload.

No span bundle was written because the 3h listing printed nothing. No base correction was needed, since the Step 0 row reads `ok`.

## The copy

Both payloads came from a fresh `git -C ../LibKa0s archive v1.89.0 LibKa0s testkit tools` extract and were copied whole. Before the prune, `diff -r --strip-trailing-cr` and `diff -rq` came back empty for `libs/LibKa0s` and for `tests/_kit`. After the prune, the only remaining library difference is the `Only in <extract>/LibKa0s/media/icons` lines, one for each undeclared icon. The kit diff is still empty.

Nothing was only in the addon, so no file was deleted under `libs/` except by the prune.

## Delivered for free (class A)

- DebugLogDiagnostics minor 7: the diagnostics report names IconBrowser when it runs.
- Kit revision 51: the CallbackHandler unregister guard, which fixes the `invalid key to 'next'` flake.
- Widgets minor 23 and Toast minor 4 change nothing that this addon draws, because it has no `W.ContextMenu` use site and no Toast lookup.

## Blockers

None. 3g found no contract change under a consumed major, and 3j found no test that assumes the whole icon folder.

## Icons and credits

The provenance line rolled to v1.89.0. The `LibKa0s icons:` line is unchanged and stays directly under it:
`chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high`.
No provenance split was needed.

`tools/prune-icons.lua` at the tag printed `12 icon(s) declared; kept 13 file(s), removed 5827`. The 13th kept file is `LICENSE-open-iconic.txt`. The removed files are every undeclared Open Iconic, Phosphor (`ph:`) and Game-icons (`gi:`) file. Open Iconic is the only set that ships, as it was before, so the README's `## Credits` needed no change. No dead stub mirror (`__releaseChrome`) exists, and none was removed.

## Decisions

These come from the run plan, with no interview. Nothing was adopted and no issue was filed (see 03_DECISIONS.md):

- Widgets 23 cascading-menu fields: not applicable (no `W.ContextMenu` use site).
- Toast 4 stack: not applicable (Toast is not consumed).
- IconBrowser: settled (no icon chooser).

No candidate went unreached, and no refresh file was written.

## Gate

`~/.claude/dev-copilot/bin/ka0s-bounded luacheck .` and `~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua`, run after the prune. The figures are in the commit `V89-PC: Re-vendor LibKa0s v1.89.0`.
