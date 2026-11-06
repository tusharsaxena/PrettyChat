Delta: LibKa0s v1.85.0 -> v1.89.0

Part of Ka0sAddonsCommonTasks `docs/2026-11-06-REVENDOR_LIBKA0S_V1_89/` (V89-PC). Written before the copy. The tag is pushed (`0bd4839`). Payload taken with `git -C ../LibKa0s archive v1.89.0 LibKa0s testkit tools | tar -x` into a scratch directory, never the library's working tree.

## Base (3a, 3b)

- `grep -n '[Bb]undles' CLAUDE.md` names v1.85.0 on line 44.
- `git log -1 --format=%H -- libs/LibKa0s tests/_kit` gives `d9ccc92`, whose `CLAUDE.md` line names v1.85.0. No `CLAUDE.md` roll since. The two agree.
- `grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR ...' libs/LibKa0s/*.lua` gives the v1.85.0 minors (Widgets 22, Toast 3, DebugLogDiagnostics 6): the bytes agree with the line.

Step 0 pre-flight (the run's `inputs/step0-preflight.txt`): `PrettyChat  2026-11-01-v1.85.0  base v1.84.0  vendored-before v1.84.0@3e13b4c  ok`. No correction owed.

`git -C ../LibKa0s log --oneline v1.85.0..v1.89.0`: 22 commits, tags v1.86.0, v1.87.0, v1.88.0, v1.89.0.

## Per-file minors (3c), moved and new files only

`for f in the tag's LibKa0s.xml files: grep the [A-Z_]*MINOR constant, old against tag`

| File | old | new |
|---|---|---|
| Toast.lua | 3 | 4 |
| Widgets.lua | 22 | 23 |
| DebugLogDiagnostics.lua | 6 | 7 |
| IconBrowserSources.lua | (new) | 1 |
| IconBrowserWindow.lua | (new) | 1 |
| IconBrowser.lua | (new) | 1 |

Every other file is at its old minor. No file is behind the old tag: no cross-major skew.

## Diffs (3d), before the copy

`diff -rq --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s`, leaving out the undeclared `Only in <scratch>/LibKa0s/media/icons` lines: `DebugLogDiagnostics.lua`, `LibKa0s.xml`, `Toast.lua`, `Widgets.lua` differ; `IconBrowser.lua`, `IconBrowserSources.lua`, `IconBrowserWindow.lua` only in the tag. Nothing only in the addon.

`diff -rq --strip-trailing-cr <scratch>/testkit tests/_kit`: `README.md`, `framework.lua`, `mock_ace.lua` differ.

## Kit (3f)

`grep -n 'Kit.VERSION'`: revision 50 -> 51. The two payloads move together (the kit-pairing rule; both are copied whole).

## Consumption (3e)

`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v /libs/ | grep -v /tests/`: Skin and DebugLog (`core/SkinSetup.lua`), Lifecycle, Media, Core, DebugLog, Env, Launcher (`core/*Setup.lua`), Schema and Slash (`settings/Schema.lua`), DebugLog (`settings/Panel.lua`), Slash (`settings/Slash.lua`), Options (`settings/OptionsSetup.lua`). Unchanged from v1.85.0.

Toast, Widgets and IconBrowser have no lookup here. The addon has no `W.ContextMenu` use site (`grep -rn 'ContextMenu' --exclude-dir=libs --exclude-dir=_kit` finds only `tests/mock_menu.lua`, the mock for the library launcher's `MenuUtil` menu).

## Contract delta (3g)

Majors moved and consumed: DebugLog only (`DebugLogDiagnostics.lua` 6 -> 7).

`diff` of `docs/api/DebugLog/version-22.6.1.4-docs.md` (v1.85.0) against `version-22.7.1.4-docs.md` (v1.89.0): "No member change"; the diagnostics report's `LibKa0s running:` line also names IconBrowser when that major runs. The one host-observable note (`version-22.7.1.4-docs.md`, the compatibility paragraph): a host suite that pins `DebugLogDiagnostics 6` re-pins it at 7. `grep -rnE 'DebugLogDiagnostics|DIAG_MINOR' tests --include='*.lua' | grep -v _kit` finds no pin.

`grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=Libs --exclude-dir=_kit`: no site.

Toast minor 4's stub members (`SetStack`, `Visible`, `FrameFor`) are owed only by a host with a Toast stub; this addon has none.

### Blockers

None.

## Span check (3h)

The audit's walk plus the provenance-roll walk since the horizon `2026-08-25`, against the recorded bundle tags: 63 vendored, 63 recorded, `grep -vxF` prints nothing. No span bundle.

## Icons (3i, 3j)

`grep -n 'LibKa0s icons:' CLAUDE.md`: line 45, directly under the provenance line:
`LibKa0s icons: chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high.`

Kept as is. The only library-drawn names this range adds are the icon browser's `search` and `close` (the tag's `docs/releasing.md`, *Library-drawn icons*), owed only by an IconBrowser host. No provenance split owed.

`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v /_kit/`: `tests/test_libka0s.lua:558` (`info.tga`), `tests/test_mediasetup.lua:101` (loops over the declared names only), `tests/test_skin_preview.lua:223` (`eye.tga`), `tests/test_mediasetup.lua:75` (names against `Media.ICONS`, no file opened). Every file opened is declared. No 3j blocker.
