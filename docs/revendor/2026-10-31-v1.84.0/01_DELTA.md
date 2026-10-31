Delta: LibKa0s v1.83.0 -> v1.84.0

Written before the copy. Tag v1.84.0 is local (`git -C ../LibKa0s ls-remote --tags origin v1.84.0`
prints nothing) at commit `e917ccd`; the payload was taken with
`git -C ../LibKa0s archive v1.84.0 LibKa0s testkit tools`.

## 3a. Claimed version

`grep -n '[Bb]undles' CLAUDE.md` gives line 44, v1.83.0. The newest commit touching either payload is
`d6ac61e` (PC-RV3), and its line names v1.83.0. The two agree. The base is v1.83.0.
`git -C ../LibKa0s log --oneline v1.83.0..v1.84.0` lists 26 commits;
`git -C ../LibKa0s diff --stat v1.83.0 v1.84.0` reports 145 files changed.

Step 0, this addon only: the newest single-tag bundle `2026-10-24-v1.77.0` states base v1.76.0, which
its summary confirms. No correction is owed.

## 3b. Actual version

`diff -rq` of the addon against `git archive v1.83.0` shows only the undeclared icons. No skew.

## 3c. Per-file minors (the loop over the tag's `LibKa0s.xml`; unchanged files omitted)

| File | Old | New |
|---|---|---|
| Schema.lua | 2 | 3 |
| Charts.lua | new | 1 |
| ChartsRender.lua | new | 1 |
| Skin.lua | 10 | 11 |
| SkinOwnerTokens.lua | new | 1 |
| SkinDefs.lua | 18 | 19 |
| SkinDefsOthers.lua | new | 1 |
| WidgetsDragHandle.lua | 8 | 10 |
| DebugLogDiagnostics.lua | 5 | 6 |
| Slash.lua | 20 | 21 |
| Options.lua | 34 | 35 |
| OptionsWidgets.lua | 38 | 40 |
| OptionsFlow.lua | new | 2 |
| OptionsIds.lua | 5 | 6 |
| OptionsIdSuggest.lua | new | 1 |
| OptionsTabs.lua | 11 | 13 |
| OptionsTabbed.lua | new | 2 |
| OptionsCompose.lua | 14 | 15 |
| OptionsSkinPicker.lua | 4 | 5 |
| OptionsSkinPickerRows.lua | new | 1 |
| SimPanel.lua | 8 | 9 |
| SimPanelRender.lua | new | 1 |

## 3d. Diffs

Before the copy: content against v1.83.0 is clean, so nothing has forked.

## 3e. Consumption map

`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)'` outside `libs/` and `tests/`: Core, Env, Media,
Skin, DebugLog, Launcher, Lifecycle (`core/`), Options, Slash, Schema, DebugLog (`settings/`). Charts
has no lookup.

## 3f. Kit revision

46 -> 47 (`grep -n 'Kit.VERSION'`). The two payloads move in one commit, as they always do.

## 3g. Contract delta

Docs read: Options 34.4.38... -> 35.4.40.2..., Schema 2 -> 3, Slash 20.2 -> 21.2, DebugLog 22.5.1.2 ->
22.6.1.2, Skin 10.18... -> 11.1.19..., Widgets 17.3.8... -> 17.3.10.... `grep -rn '__Attach'` outside the
payloads is empty, so this addon hands no members across an attach seam.

### Blockers

1. `O.PositionBlock` is a new public member, so the Options degradation stub owes it
   (Options `version-35.4.40.2.6.1.7.13.2.3.15.9.4.3.6.5.5.1.1.1-docs.md`, *What changed at this version*:
   the flow seams; CHANGELOG v1.84.0, "Consumers' degradation stubs owe the new `O.PositionBlock`").
   Fixed in the re-vendor commit, in `settings/OptionsSetup.lua`.

No contract tightened under an existing surface. A schema `note` row needs no host skip here because
this addon declares none: `modules/Diagnostics.lua:157` walks `AllRows`, and the only rows it sees are
its own.

## 3h. Unrecorded tags

None. v1.15.0 and v1.30.0 sit in the undated-tag bundles `2026-08-25` and `2026-09-12`, whose line 1
names them. No span bundle is owed.

## 3i. Icon declaration

`LibKa0s icons: clear, close, copy, settings.` is kept, directly under the provenance line.

## 3j. Tests that assume the whole icon folder

`tests/test_mediasetup.lua` and `tests/test_libka0s.lua:569` already read the declaration or a pruned
name. Not blockers.
