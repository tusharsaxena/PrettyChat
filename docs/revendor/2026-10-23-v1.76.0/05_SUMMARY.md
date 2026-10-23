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
