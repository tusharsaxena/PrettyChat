# Summary

Part of Ka0sAddonsCommonTasks `docs/2026-11-06-REVENDOR_LIBKA0S_V1_89/` (SF1-RV-PC).

## Tag

LibKa0s v1.89.0 -> v1.90.0. The tag is local and not pushed (`4485b8f`). The base is the tag named on the `CLAUDE.md` provenance line (line 44). It matches both the last payload commit `a55dd18` and the vendored minors (01_DELTA.md, 3a and 3b).

| File | old | new |
|---|---|---|
| Core.lua | 15 | 16 |
| Skin.lua | 16 | 17 |
| SkinPaint.lua | 18 | 19 |
| SkinPaintExtras.lua | 17 | 18 |
| Widgets.lua | 23 | 24 |
| WidgetsAutocomplete.lua | 7 | 8 |
| OptionsAppearance.lua | 6 | 7 |

Kit revision 51 is unchanged, and the kit payload was copied whole in the same commit.

No span bundle was written, because the 3h listing printed nothing. No base correction was needed, because the Step 0 row reads `ok`.

## The copy

Both payloads were copied whole from a fresh `git -C ../LibKa0s archive v1.90.0 LibKa0s testkit tools` extract. Before the prune, `diff -r --strip-trailing-cr` and `diff -rq` came back empty for both `libs/LibKa0s` and `tests/_kit`. After the prune, the only library differences left are `Only in <extract>/LibKa0s/media/icons` lines for the undeclared icons. Nothing existed only in the addon, so nothing under `libs/` was deleted except by the prune.

## Delivered for free (class A)

- Pixel-exact Widgets edges (Core 16, Widgets 24, WidgetsAutocomplete 8, SkinPaint 19, SkinPaintExtras 18) on the library-drawn surfaces this addon shows.
- OptionsAppearance 7: a copy still carries the Scope to this owner, which does not register `keepScope`. No behavior moves here.

## Blockers

None. 3g found no contract change that this addon owes and no test that pins a moved minor. 3j found no test that assumes the whole icon folder.

## Icons and credits

The provenance line rolled to v1.90.0. The `LibKa0s icons:` line is unchanged and still sits directly under it:
`chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high`.
No provenance split was needed.

`tools/prune-icons.lua` at the tag printed `12 icon(s) declared; kept 13 file(s), removed 5827`. The 13th file kept is `LICENSE-open-iconic.txt`. Open Iconic is still the only set that ships, so the README's `## Credits` needed no change. There was no dead stub mirror.

## Decisions

These come from SF1, with no interview (see 03_DECISIONS.md). Nothing was adopted and no issue was filed. `keepScope` does not apply here. No candidate was left unreached, and no refresh file was written.

## Column headers (SF1, the owner's header ruling)

Pretty Chat draws no column-header row in a window of its own, so `SF1-PC-HDR` has nothing to fix. The addon's one `CreateFrame` is the combat watcher at `modules/Override.lua:218`. No addon file outside `libs/` calls `CreateTexture`. `SortHeaderBar` appears only in the degraded Skin facade's list of no-op names (`core/SkinSetup.lua:439`). Its settings pages are AceGUI pages built by the library.

## Gate

After the prune: `~/.claude/dev-copilot/bin/ka0s-bounded luacheck .` reported 0 warnings and 0 errors in 70 files. `~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua` reported 691 passed, 0 failed and 1 skipped (692 total). The skip is the existing diagnostics-contract opt-out case, which does not apply to this addon. No addon Lua changed, so the 1500-line cap and CCN are unchanged.
