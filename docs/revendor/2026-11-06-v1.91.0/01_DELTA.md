Delta: LibKa0s v1.90.0 -> v1.91.0

Part of Ka0sAddonsCommonTasks `docs/2026-11-06-FOLLOWUPS_V1_91/` (FU-RV-PC). Written before the copy. The tag is local and not pushed (`55bfbb4`): `git -C ../LibKa0s ls-remote --tags origin v1.91.0` prints nothing, as expected. This is a new tag for this addon, not a refresh. The payload was taken with `git -C ../LibKa0s archive v1.91.0 LibKa0s testkit tools | tar -x` into a scratch directory, never from the library's working tree.

Step 0 was skipped. Its roster regex expects markdown links, but `ADDONS.md` writes `` `../../<Folder>/` ``, so it matches nothing in the installed skill (dev-copilot 2.7.0). FU-DC1 fixes that upstream in this run.

## Base (3a, 3b)

- `grep -n '[Bb]undles' CLAUDE.md` names v1.90.0 on line 44.
- `git log -1 --format=%H -- libs/LibKa0s tests/_kit` gives `fd42e5d`, whose `CLAUDE.md` line names v1.90.0. `git log "fd42e5d..HEAD" -- CLAUDE.md` shows no later roll. The two agree.
- `diff -rq` of a v1.90.0 extract against `libs/LibKa0s` and `tests/_kit` shows only the undeclared icons. The bytes agree with the line.

`git -C ../LibKa0s log --oneline v1.90.0..v1.91.0` lists 7 commits: `55d3b0f` FU-L1, `d72dc4a`, `c1ed261`, `acc9640` and `3f7be30` FU-L2, and `1938837` and `55bfbb4` FU-L3.

## Per-file minors (3c), moved and new files only

Command: for each file in the tag's `LibKa0s.xml`, grep the `[A-Z_]*MINOR` constant in the old copy and at the tag.

| File | old | new |
|---|---|---|
| Core.lua | 16 | 17 |
| CorePixel.lua | (new) | 1 |
| SkinPaintExtras.lua | 18 | 19 |
| SkinPaintHud.lua | (new) | 1 |
| SkinAceConfirm.lua | (new) | 1 |
| Widgets.lua | 25 | 26 |
| WidgetsDropdown.lua | (new) | 1 |
| WidgetsLineChart.lua | 6 | 7 |

Every other file stays at its old minor. Four files are new, all peels. No file is behind the old tag, so there is no cross-major skew.

## Diffs (3d), before the copy

`diff -rq --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s`, leaving out the undeclared `Only in <scratch>/LibKa0s/media/icons` lines: `Core.lua`, `LibKa0s.xml`, `SkinPaintExtras.lua`, `Widgets.lua` and `WidgetsLineChart.lua` differ. `CorePixel.lua`, `SkinAceConfirm.lua`, `SkinPaintHud.lua` and `WidgetsDropdown.lua` exist only in the tag. Nothing exists only in the addon.

`diff -rq --strip-trailing-cr <scratch>/testkit tests/_kit`: empty.

## Consumption (3e)

Host lookups outside `libs/` and `tests/`: Core, Env, Lifecycle, Media, Skin, DebugLog, Launcher, Options, Slash, Schema. The host makes no Widgets lookup of its own. Widgets reaches the addon through the library's own files (DebugLog, SimPanel, IconBrowser).

## Kit (3f)

`grep -n 'Kit.VERSION'`: revision 51 on both sides. The kit payload is still copied whole with the library (the kit-pairing rule).

## Contract delta (3g)

Two majors moved and are also looked up by the host: Core (key 16 -> 17.1) and Skin (key 17.1.27.8.19.18.17.4.9 -> 17.1.27.8.19.19.1.1.17.4.9). Widgets (25.6.13.6.8.5 -> 26.1.6.13.7.8.5) moved too, but the host does not look it up. The new documents' *Superseded by* rows and the v1.91.0 `CHANGELOG.md` block describe four pure moves, with no member, option or behaviour change: the pixel-edge section into `CorePixel.lua`; `BarGloss`/`HudFont` into `SkinPaintHud.lua`; the AceConfig confirm box into `SkinAceConfirm.lua`; and the dropdown and menu into `WidgetsDropdown.lua`. They also describe one behaviour change that arrives on the copy: WidgetsLineChart 7 draws its lines in physical pixels. This addon draws no line chart, so that change does not apply here. `grep -rn '__Attach' --include='*.lua' --exclude-dir=libs --exclude-dir=_kit` is empty, so the host passes the library no callback member.

### Blockers

- **Library file lists:** none. `tests/loader.lua:43` derives its list from `libs/LibKa0s/LibKa0s.xml` (`Loader.xmlFiles`), so the four new files join in XML order without an edit. The other named-file reads are not load lists: the Core-only `skip` sets and `tests/test_libka0s.lua:124,382` (source tripwires on files that did not move out).
- **Minor pins:** none. `grep -rnE 'MINOR *[=><~]=* *[0-9]' tests/*.lua` finds no exact pin. `tests/test_harness.lua:88` asserts only `MINOR > 0`.
- **Stub mirrors:** none. No host file names a moved `__Pixel*` member, and the degraded Skin facade in `core/SkinSetup.lua` names no member that moved major.

## Span bundles (3h)

The listing (with `tag_at` rewritten on a named variable, `rev=$1`), from horizon 2026-08-25, prints nothing unrecorded. No span bundle is written.

## Icons (3i, 3j)

`CLAUDE.md:45` keeps `LibKa0s icons: chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high.`, as decided by the plan (no new library-drawn name in v1.91.0's *What a consumer owes*). The line sits directly under the provenance line, so no split is needed. Hand lists have drifted before (KickCD `tests/test_mediasetup.lua:28`, WhatGroup `tests/test_mediasetup.lua:19`), and the owner's in-client smoke test is the backstop for a name the host forgot to declare. 3j's grep finds only declared-name assertions (`info.tga`, `eye.tga`) and a declaration-aware loop (`tests/test_mediasetup.lua:75-101`). None of them is a whole-catalog blocker.
