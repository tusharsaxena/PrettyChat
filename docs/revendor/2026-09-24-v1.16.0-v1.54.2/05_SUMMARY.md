# 05 — Summary: the consolidated span v1.16.0 to v1.54.2

Written 2026-09-24 as item PC-25 of the 2026-09-23 remediation plan (finding PRETTYCHAT-A-01).
A records-only back-fill: no code, library or kit file moved, and nothing was pushed.

## Why one bundle, not 29

The re-vendor record lapsed collection-wide at once: this store stopped naming tags after
v1.34.0 while the addon kept vendoring through collection sweeps and one-off re-vendors, and the
earlier gaps (v1.16.0 to v1.29.0) predate the convention settling. `audit-review-history` makes
the consolidated span bundle the sanctioned record for a lapsed span, and `AUDIT.md` asks for one
rolled-up remediation rather than a folder per tag, because a folder per tag would record
deliberation that never happened. So this folder holds `01_DELTA.md` and `05_SUMMARY.md` only.

The span's previous base is v1.15.0 (`01_DELTA.md`, "The true previous base"). With this folder in
place, the `AUDIT.md` re-vendor check's "vendored minus recorded" listing prints nothing.

The frozen earlier bundles stay unchanged: `2026-08-25/` (v1.15.0), `2026-09-12/` (v1.30.0),
`2026-09-12-v1.31.0/`, `2026-09-12-v1.32.0/`, `2026-09-12-v1.33.0/`, `2026-09-13-v1.34.0/`,
`2026-09-23-v1.55.0/` and `2026-09-23-v1.56.0/`.

## The two adoption decisions

- **v1.39.0, the Launcher.** `ed46f80` vendored LibKa0s-Launcher-1.0 without adopting it; the
  adoption was its own changeset the same day, `4821b7b` (a minimap button, a broker plugin and
  two reserved verbs), after `4e11432` vendored the broker pair.
- **v1.42.0, the Lifecycle latch.** `5232c3d` vendored LibKa0s-Lifecycle-1.0 and adopted it in the
  same commit: `core/LifecycleSetup.lua` owns the one stand-down latch, held by the stored
  `disabled` state and by a perf run.

## Per tag

- v1.16.0: carried by sweep, nothing adopted
- v1.18.0: `942f254`
- v1.18.1: carried by sweep, nothing adopted
- v1.19.0: carried by sweep, nothing adopted
- v1.23.0: `050403e`
- v1.24.0: `8ee771a`
- v1.25.0: `7603ca3`
- v1.26.0: carried by sweep, nothing adopted
- v1.27.0: `b302d0e`
- v1.28.0: carried by sweep, nothing adopted
- v1.29.0: carried by sweep, nothing adopted
- v1.35.0: carried by sweep, nothing adopted
- v1.36.0: carried by sweep, nothing adopted
- v1.36.1: carried by sweep, nothing adopted
- v1.36.2: carried by sweep, nothing adopted
- v1.37.0: carried by sweep, nothing adopted
- v1.38.0: `78f5ec7`
- v1.39.0: `4821b7b` (vendored by `ed46f80`)
- v1.42.0: `5232c3d`
- v1.43.0: carried by sweep, nothing adopted
- v1.44.0: carried by sweep, nothing adopted
- v1.45.0: carried by sweep, nothing adopted
- v1.46.1: carried by sweep, nothing adopted
- v1.47.0: carried by sweep, nothing adopted
- v1.50.0: carried by sweep, nothing adopted
- v1.51.0: carried by sweep, nothing adopted
- v1.52.0: carried by sweep, nothing adopted
- v1.53.0: carried by sweep, nothing adopted
- v1.54.2: `8421342`

What each other adopting commit took: `942f254` the profile-reset `ResetAll` (options-ui-§12) and
the profile callbacks it needs; `050403e` the tabbed settings page and page banner; `8ee771a` the
settings-revamp-v2 contract and a nested strip per rewritten string; `7603ca3` OptionsCompose's
`leadButton`, putting Test beside the reset; `b302d0e` the kit's working-tree line-ending suite;
`78f5ec7` Slash minor 11's bare `/pc`; `8421342` the kit's US-English prose gate in place of this
repo's own. Several "nothing adopted" tags still touched this repo's files to keep a surface in
step, and their messages say so: `7ec65aa` and `1372234` gave the Options degradation stub inert
parity members, and `5bbe28e` brought the docs and `tests/test_libka0s.lua` in line with the
library's combat lock. None of those consumes a new surface.

## Checks

- `AUDIT.md` re-vendor check, run after this folder was written: the "vendored minus recorded"
  listing prints nothing.
- `ka0s-bounded lua5.1 tests/run.lua`: green; `docs/revendor/` is a skipped prose directory.
