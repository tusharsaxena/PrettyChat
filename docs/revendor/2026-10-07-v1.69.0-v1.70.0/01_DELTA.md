Delta: LibKa0s v1.69.0 -> v1.70.0 (span: v1.69.0 v1.70.0)

# The consolidated span v1.69.0 to v1.70.0 (PrettyChat)

Written 2026-10-07 beside `2026-10-07-v1.71.0/`, by item RV-PC of the 2026-10-07 review and
standards-audit remediation, because the audit's two-listing check named two tags this addon
vendored with no bundle of their own (`docs/audits/2026-10-07/`, PC-103; remediation finding
PC-A-01). Records only: no code moved for this folder.

The base before the span is **v1.68.1**, recorded in `2026-10-04-v1.68.1/`.

```sh
horizon=$(ls -1 docs/revendor | sort | head -1 | cut -c1-10)   # 2026-08-25
# the AUDIT.md walk over libs/LibKa0s, tests/_kit and the CLAUDE.md line at each such commit,
# then: grep -vxF -f recorded.txt vendored.txt
v1.69.0
v1.70.0
```

```sh
git log --format='%h %ad %s' --date=short -2 -- CLAUDE.md   # before RV-PC
7a1aabf 2026-10-07 chore: re-vendor LibKa0s v1.70.0
136cf54 2026-10-06 chore: re-vendor LibKa0s v1.69.0 (kit 37; adds the line chart widget)
```

## v1.69.0, commit `136cf54`

LibKa0s tag `v1.69.0` (commit `5949f4c`). `git -C ../LibKa0s diff --stat v1.68.1 v1.69.0 -- LibKa0s testkit`:

- `LibKa0s/WidgetsLineChart.lua`, **new** (WidgetsLineChart minor 1, under `LibKa0s-Widgets-1.0`),
  and its line in `LibKa0s.xml`.
- Kit revision **36 -> 37**: `testkit/mock_lines.lua`, **new** (the mock answers Line regions),
  loaded from `mock_base.lua`; `framework.lua` carries the revision constant; `README.md` lists the
  new file.

The commit also rolled the live vendor stamps (`CLAUDE.md`, `docs/ARCHITECTURE.md`, `docs/debug.md`,
`docs/module-map.md`, `docs/testing.md`).

## v1.70.0, commit `7a1aabf`

LibKa0s tag `v1.70.0` (commit `162a7fd`). `git -C ../LibKa0s diff --stat v1.69.0 v1.70.0 -- LibKa0s testkit`:

- `LibKa0s/WidgetsAutocomplete.lua`, **new** (WidgetsAutocomplete minor 1, under
  `LibKa0s-Widgets-1.0`), and its line in `LibKa0s.xml`.
- `LibKa0s/WidgetsLineChart.lua` minor 1 -> 2 (the `pxPerPoint` option).
- Kit unchanged at revision 37.

The commit rolled the same five live stamps.

## What reached this addon

Both tags move only `LibKa0s-Widgets-1.0` files and the kit. PrettyChat does not consume Widgets
(declined, [#11](https://github.com/tusharsaxena/PrettyChat/issues/11), `state:will-not-do`); inside
the payload only `DebugLog.lua` resolves Widgets, for the resize helper, which neither tag touched.
No consumed major moved a minor, so no host contract could move. Both re-vendors were carried by the
LibKa0s line-chart and autocomplete sweeps, which made the whole-folder copies across the collection;
there was no deliberation in this addon to record.
