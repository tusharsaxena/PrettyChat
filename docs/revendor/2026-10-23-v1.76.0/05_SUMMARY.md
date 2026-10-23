# LibKa0s v1.75.2 -> v1.76.0: summary (PrettyChat)

- **Tag:** v1.75.2 -> v1.76.0 (local annotated tag `546e284`, LibKa0s commit `9949368`); base from
  the `CLAUDE.md` provenance line, confirmed by the payload diff. Kit revision 41 unchanged.
  Per-file minors in `01_DELTA.md` 3c (SimTimeline 3, SimPanel 5, Widgets 14): no skew.
- **Span bundle:** `2026-10-23-v1.75.1-v1.75.2/`, the two simulator fix tags vendored here with no
  bundle. No base correction.
- **Delivered for free (class A):** nothing this addon consumes; Sim and Widgets ride along whole.
- **Contract blockers:** none. Neither moved major is consumed here, and the kit did not move.
- **Declaration:** `LibKa0s icons: clear, close, copy.` kept. Prune: kept 4 files, removed 5836.
- **Credits:** unchanged (Open Iconic only).
- **Dead stub mirrors removed:** none.
- **Live stamps rolled:** `docs/ARCHITECTURE.md` (vendored libraries), `docs/module-map.md` (the
  XML order, unchanged at v1.76.0) and `docs/testing.md` (the layout-cap gate) now name v1.76.0.
- **Adopted:** nothing. **Declined:** nothing, so no issue filed. **Unreached:** none.
- **Gates:** `ka0s-bounded luacheck .` 0 warnings / 0 errors in 56 files;
  `ka0s-bounded lua tests/run.lua` 574 passed, 0 failed, 1 skipped (575), `test_vendor_sync`
  green against v1.76.0; no authored `.lua` over the 1500-line cap outside the census.
- **Owed in client:** nothing new; the run's own smoke file carries no PrettyChat check for this item.

## Addendum: the tag moved (PC-RV2)

The local tag `v1.76.0` was moved for LK-91 (step-panel labels bounded before the command column,
the BankLedger `/bl sim` overlap): LibKa0s commit `9949368` (tag object `546e284`) -> `7e81ff7`
(tag object `2949c78`). The payload was re-copied whole from the moved tag, the same way, and
`media/icons/` re-pruned to `LibKa0s icons: clear, close, copy.` (kept 4, removed 5836).

- **Files that changed:** `libs/LibKa0s/PerfPanel.lua` (PerfPanel minor 7 -> 8, Perf key
  15.1.1.7 -> 15.1.1.8) and `libs/LibKa0s/SimPanel.lua` (still minor 5). `tests/_kit/` did not
  move (kit revision 41).
- **Consumption:** PrettyChat opens neither panel, so nothing here changes and nothing is adopted.
  The provenance line already names v1.76.0 and is kept.
- **Gates:** `ka0s-bounded luacheck .` 0 / 0 in 56 files; `ka0s-bounded lua tests/run.lua` 574
  passed, 0 failed, 1 skipped (575), `test_vendor_sync` green against the moved tag.
