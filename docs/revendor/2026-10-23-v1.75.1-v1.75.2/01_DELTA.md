Delta: LibKa0s v1.75.1 -> v1.75.2 (span: v1.75.1 v1.75.2)

# The consolidated span v1.75.1 to v1.75.2 (PrettyChat)

Written 2026-10-23 beside `2026-10-23-v1.76.0/`, by item PC-RV of the 2026-10-23 "sim auto-run, QC
preview selector, mode strips, MM/KCD simulators" run, because the re-vendor command's 3h listing
named two tags this addon vendored with no bundle of their own. Records only: no code moved for
this folder.

The base before the span is **v1.75.0**, recorded in `2026-10-22-v1.75.0/` (and its `06_REFRESH.md`).

```sh
horizon=$(ls -1 docs/revendor | sort | head -1 | cut -c1-10)   # 2026-08-25
# the AUDIT.md walk over libs/LibKa0s, tests/_kit and the CLAUDE.md line at each such commit,
# then: grep -vxF -f recorded.txt vendored.txt
v1.75.1
v1.75.2
```

```sh
git log --format='%h %ad %s' --date=short -3 -- CLAUDE.md   # before PC-RV
082ffca 2026-10-23 Re-vendor LibKa0s v1.75.2 (SimPanel minor 4)
a708988 2026-10-23 Re-vendor LibKa0s v1.75.1 (SimPanel minor 3)
6ef60f5 2026-10-22 PC-RV: re-vendor LibKa0s v1.75.0 and prune icons to the declaration
```

## v1.75.1, commit `a708988`

LibKa0s tag `v1.75.1` (commit `39dfb98`). `git -C ../LibKa0s diff --stat v1.75.0 v1.75.1 -- LibKa0s testkit`:

- `LibKa0s/SimPanel.lua`, `SIM_PANEL_MINOR` 2 -> 3 (a disabled row or control still shows its tip).
- Kit unchanged at revision 41.

The commit rolled the `CLAUDE.md` provenance line.

## v1.75.2, commit `082ffca`

LibKa0s tag `v1.75.2` (commit `154599c`). `git -C ../LibKa0s diff --stat v1.75.1 v1.75.2 -- LibKa0s testkit`:

- `LibKa0s/SimPanel.lua`, `SIM_PANEL_MINOR` 3 -> 4 (the simulation picker's scenario dropdown takes
  the width the bar leaves).
- Kit unchanged at revision 41.

The commit rolled the `CLAUDE.md` provenance line.

## What reached this addon

Both tags move only `SimPanel.lua`, under `LibKa0s-Sim-1.0`, which PrettyChat does not consume
(`2026-10-22-v1.75.0/02_CANDIDATES.md`: nothing to simulate). No consumed major moved a minor, so no
host contract could move. Both re-vendors were carried by the post-run simulator fix sweeps, which
made the whole-folder copies across the collection; there was no deliberation in this addon to
record.
