# LibKa0s v1.71.0 -> v1.75.0: summary (PrettyChat)

- **Tag:** v1.71.0 -> v1.75.0 (local annotated tag, LibKa0s commit `265a89e`); base from the
  `CLAUDE.md` provenance line, confirmed by `payload-matches`. Kit revision 38 -> 41. Per-file
  minors in `01_DELTA.md` 3c: no skew.
- **Span bundle:** none. v1.72.0 to v1.74.0 were never vendored here. No base correction.
- **Delivered for free (class A):** DebugLog 20 / DebugLogDiagnostics 3, Options 29 (OptionsTabs 9,
  OptionsIdList 5, OptionsDrawer 1), Core 11, Media 5 / MediaIcons 1, Widgets 13, Item 3,
  Perf 15 / PerfPanel 7, and the new Glow-1.0 and Sim-1.0 files (not wired here).
- **Contract blockers, fixed in the re-vendor commit:** the Options stub's `Drawer`, the
  whole-catalog icon test, the `info.tga` assertion, and the `docs/testing.md` complexity row for
  kit 41's crashed bucket. The kit 39 `__fireUnconditional` change left `disabled/6` green as
  predicted.
- **Declaration:** `LibKa0s icons: clear, close, copy.` written under the provenance line; no
  provenance split. Prune: kept 4 files, removed 5836 (Open Iconic 221, Phosphor 1435,
  Game-icons 4180).
- **Credits:** the README gains one Open Iconic paragraph; no set's credit removed (none was there).
- **Dead stub mirrors removed:** `__releaseChrome` in `settings/OptionsSetup.lua`.
- **Adopted:** nothing. **Declined:** nothing, so no issue filed. **Unreached:** none.
- **Gates:** `ka0s-bounded luacheck .` 0 warnings / 0 errors in 56 files;
  `ka0s-bounded lua tests/run.lua` 574 passed, 0 failed, 1 skipped (575), `test_vendor_sync`
  green against v1.75.0; no authored `.lua` over the 1500-line cap outside the census.
- **Owed in client:** `docs/smoke-tests.md` RV-75 (icons after the prune), RV-76 (clean load) and
  RV-77 (scroll kept), each `Result: owed`.
