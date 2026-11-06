# Candidates

Range `v1.85.0..v1.89.0` (`git -C ../LibKa0s log --oneline v1.85.0..v1.89.0`), read from the tag's `CHANGELOG.md` blocks v1.86.0 to v1.89.0 and the API documents of the majors that moved.

## A. Delivered on the re-vendor

- **DebugLogDiagnostics minor 7** (`CHANGELOG.md`, v1.86.0, "DebugLogDiagnostics minor 7"; `docs/api/DebugLog/version-22.7.1.4-docs.md`, "What changed at this version"): the diagnostics report's `LibKa0s running:` line names IconBrowser when it runs. No member change; this addon pins no diagnostics minor.
- **Kit revision 51** (`CHANGELOG.md`, v1.89.0, "The kit's unregister guard"): `mock_ace.lua`'s CallbackHandler registry clears only an entry that exists, so an unregister during a dispatch no longer can raise `invalid key to 'next'`. A consumer owes only the re-vendor.
- **Widgets minor 23** flat menus draw what minor 22 drew (`CHANGELOG.md`, v1.87.0); the library launcher's right-click menu here goes through `MenuUtil`, not `W.ContextMenu`.
- **Toast minor 4** without `stack` is the minor 3 toast (`CHANGELOG.md`, v1.88.0); this addon does not consume Toast.

## B. Host change required

- **Widgets 23 `submenu`, `radio`, `selected`, `opts.check` on `W.ContextMenu` rows** (`docs/api/Widgets/version-23.5.12.6.7.5-docs.md`; `CHANGELOG.md` v1.87.0). Not applicable: the addon has no `W.ContextMenu` use site (`grep -rn ContextMenu --include='*.lua' --exclude-dir=libs --exclude-dir=_kit` finds only `tests/mock_menu.lua`). Additive if it ever had one.
- **Toast 4 stack** (`docs/api/Toast/version-4-docs.md`; `CHANGELOG.md` v1.88.0). Not applicable: no Toast lookup (3e).

## C. Whole-module adoption

- **`LibKa0s-IconBrowser-1.0`** (new in v1.86.0; `docs/api/IconBrowser/version-1.1.1-docs.md`). Pretty Chat has no icon chooser: its settings pick colors, formats and fonts, never a catalog icon. Settled by the owner's ruling (the run plan's decisions table: IconBrowser for every addon without an icon chooser is settled, recorded, no issue).

No candidate outside the plan's decisions table.
