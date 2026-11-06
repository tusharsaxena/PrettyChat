Delta: LibKa0s v1.89.0 -> v1.90.0

Part of Ka0sAddonsCommonTasks `docs/2026-11-06-REVENDOR_LIBKA0S_V1_89/` (SF1-RV-PC, from `SF1_SMOKE_FEEDBACK.md`). Written before the copy. The tag is local and not pushed (`4485b8f`): `git -C ../LibKa0s ls-remote --tags origin v1.90.0` prints nothing, as expected. This is a new tag for this addon, not a refresh. Payload taken with `git -C ../LibKa0s archive v1.90.0 LibKa0s testkit tools | tar -x` into a scratch directory, never the library's working tree.

## Base (3a, 3b)

- `grep -n '[Bb]undles' CLAUDE.md` names v1.89.0 on line 44.
- `git log -1 --format=%H -- libs/LibKa0s tests/_kit` gives `a55dd18` (`V89-PC: Re-vendor LibKa0s v1.89.0`), whose `CLAUDE.md` line names v1.89.0. `git log "a55dd18..HEAD" -- CLAUDE.md` shows no later roll. The two agree.
- `grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR ...' libs/LibKa0s/*.lua` gives the v1.89.0 minors (Core 15, Skin 16, SkinPaint 18, SkinPaintExtras 17, Widgets 23, WidgetsAutocomplete 7, OptionsAppearance 6). The bytes agree with the line.

Step 0 pre-flight for this addon: `PrettyChat  2026-11-06-v1.89.0  base v1.85.0  vendored-before v1.85.0@a55dd18  ok`. No correction owed.

`git -C ../LibKa0s log --oneline v1.89.0..v1.90.0`: 7 commits (`7d42f4e` SF1-L1, `b9f7651` SF1-L2, `4ac9f3c` and `4485b8f` SF1-L3, plus the harvest merge and its sync-docs).

## Per-file minors (3c), moved files only

`for f in the tag's LibKa0s.xml files: grep the [A-Z_]*MINOR constant, old against tag`

| File | old | new |
|---|---|---|
| Core.lua | 15 | 16 |
| Skin.lua | 16 | 17 |
| SkinPaint.lua | 18 | 19 |
| SkinPaintExtras.lua | 17 | 18 |
| Widgets.lua | 23 | 24 |
| WidgetsAutocomplete.lua | 7 | 8 |
| OptionsAppearance.lua | 6 | 7 |

Every other file is at its old minor. No file is new. No file is behind the old tag, so there is no cross-major skew.

## Diffs (3d), before the copy

`diff -rq --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s`, leaving out the undeclared `Only in <scratch>/LibKa0s/media/icons` lines: the seven files above differ. Nothing is only in the tag and nothing is only in the addon.

`diff -rq --strip-trailing-cr <scratch>/testkit tests/_kit`: empty.

## Kit (3f)

`grep -n 'Kit.VERSION'`: revision 51 on both sides. The kit payload is still copied whole with the library (the kit-pairing rule).

## Consumption (3e)

`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v /libs/ | grep -v /tests/`: Core (`core/CoreSetup.lua:41`), DebugLog (`core/DebugLogSetup.lua:69`, `core/SkinSetup.lua:283`, `settings/Panel.lua:101`), Env, Launcher, Lifecycle, Media (`core/*Setup.lua`), Skin (`core/SkinSetup.lua:77`), Options (`settings/OptionsSetup.lua:17`), Schema and Slash (`settings/Schema.lua`, `settings/Slash.lua`). Unchanged from v1.89.0. Widgets has no host lookup here.

## Contract delta (3g)

The majors that moved a minor and are consumed: Core (16), Skin (key 17.1.27.8.19.18.17.4.9) and Options (OptionsAppearance 7).

- **Core 16** (`docs/api/Core/version-16-docs.md:23-25`, *What changed at this version: pixel edges*): no public member is added, removed or renamed. The four new members (`__PixelSize`, `__WatchPixels`, `__OnPixelScale`, `__PixelBackdrop`) are internal. Line 83: "What a host must change: nothing."
- **Skin 17** (`docs/api/Skin/version-17.1.27.8.19.18.17.4.9-docs.md:19-21`): `RegisterOwner`'s `opts.keepScope`, additive. The member manifest is unchanged, so a host's Skin facade owes nothing. `core/SkinSetup.lua:512` calls `Skin:RegisterOwner(addonName, {...})` without `keepScope`, which is the old behavior.
- **OptionsAppearance 7** (`docs/api/Options/version-37.4.44.2.7.2.9.15.2.4.19.13.5.5.7.7.11.1.1.4-docs.md:20-26`): `lib.__copySkinTo` skips the Scope only for a `keepScope` owner. "What a host owes: a host whose Scope is a documented deviation registers with `keepScope = true`; every other host owes nothing." Pretty Chat documents no Scope deviation. The SF1 ruling gives `keepScope` to the Skin Tester alone (`SF1-ST`).
- **SkinPaint 19 / SkinPaintExtras 18 / Widgets 24 / WidgetsAutocomplete 8**: these change no member. Widgets is not looked up by this addon.

`grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=Libs --exclude-dir=_kit`: no site.

`grep -rnE '(Core|Skin|Widgets|...)...(minor)' tests --include='*.lua' | grep -v _kit`: no test pins a moved minor. The only hit is a comment, `tests/test_surface_parity.lua:108` ("Core minor 8's pcalled event registration helper").

### Blockers

None.

## Span check (3h)

The audit's walk plus the provenance-roll walk since the horizon `2026-08-25`, compared against the recorded bundle tags, gives 64 vendored and 64 recorded. `grep -vxF` prints nothing, so no span bundle is needed.

## Icons (3i, 3j)

`grep -n 'LibKa0s icons:' CLAUDE.md`: line 45, directly under the provenance line:
`LibKa0s icons: chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high.`

Kept as it is. This range adds no library-drawn icon (`git -C ../LibKa0s diff v1.89.0 v1.90.0 -- docs/releasing.md` changes no row of *Library-drawn icons*). No provenance split is owed.

`grep -rn "media/icons\|lib.ICONS\|\.ICONS)" tests --include='*.lua' | grep -v /_kit/`: `tests/test_libka0s.lua:558` (`info.tga`), `tests/test_skin_preview.lua:223` (`eye.tga`), `tests/test_mediasetup.lua:75` (names against `Media.ICONS`, no file opened) and `tests/test_mediasetup.lua:101` (loops over the declared names only). Every file opened is declared, so there is no 3j blocker.

`grep -rn '__releaseChrome' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit`: no mirror.
