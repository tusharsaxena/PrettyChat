# LibKa0s v1.76.0 -> v1.77.0: summary (PrettyChat)

- **Tag:** v1.76.0 -> v1.77.0 (local annotated tag `7380d36`, LibKa0s commit `78240f7`); base from
  the `CLAUDE.md` provenance line, confirmed by the payload diff against the tag v1.76.0 (now
  `e692491`, a README-only move after `7e81ff7`, so the same payload). Kit revision 41 -> 42.
  Per-file minors in `01_DELTA.md` 3c (Core 12, DebugLog 21, Options 30 with OptionsIds 3,
  OptionsCombat 2, OptionsCompose 8 and the new OptionsKeybinds 3, Widgets 15 with DragHandle 5 and
  Autocomplete 3, PerfPanel 9, SimPanel 6): no skew.
- **Span bundle:** none owed. **Base correction:** none.
- **Delivered for free (class A):** the debug console is toplevel and re-raises a shown
  confirmation (PRC-Z01 + Z02, fixed upstream by LK-01); clamped menus and the IdList combat close
  ride along unused.
- **Contract blocker (3g), fixed in this commit:** every Options degradation stub owes
  `KeybindingsTab`, `KeybindRows`, `KEYBINDS_UNCHANGED` and `StrataTooltip`
  (`docs/api/Options/version-30.2.34.3.5.9.2.8.4.2.1.3-docs.md` *Compatibility*; CHANGELOG v1.77.0
  *What a consumer owes*). The copy turned `tests/test_surface_parity.lua` red on exactly those four.
  `settings/OptionsSetup.lua`'s stub gains `KeybindingsTab`, `KeybindRows` and `StrataTooltip` as
  inert no-ops; `KEYBINDS_UNCHANGED` joins the parity case's live-only list beside the library's
  other English constants (`CLASS_COLOR_NOTE`, `VISIBILITY_VALUES`), since nothing here reads it.
- **Declaration:** `LibKa0s icons: clear, close, copy.` kept. Prune: kept 4 files, removed 5836
  (Open Iconic only; `media/icons/` unchanged in git).
- **Credits:** unchanged (Open Iconic only). **Dead stub mirrors removed:** none.
- **Live stamps rolled:** `docs/ARCHITECTURE.md` (vendored libraries), `docs/module-map.md` (the XML
  order gains `OptionsKeybinds` after `OptionsDrawer`) and `docs/testing.md` (the layout-cap gate,
  now kit revision 42) name v1.77.0.
- **Adopted:** nothing. **Deferred (run 2026-10-24):** every candidate in `02_CANDIDATES.md`;
  `O.StrataTooltip` and `mock_layers.lua` are PC-ZS's to decide. **Declined:** nothing, so no issue
  filed. **Unreached:** none.
- **Gates:** `ka0s-bounded luacheck .` 0 warnings / 0 errors in 56 files;
  `ka0s-bounded lua tests/run.lua` 574 passed, 0 failed, 1 skipped (575), `test_vendor_sync` green
  against v1.77.0; no authored `.lua` over the 1500-line cap (`test_layout_cap` green).
- **Owed in client:** nothing new; the item carries no smoke check.

## Re-vendor after the tag moved (M3)

- **Tag moved:** LK-95 re-closed the local annotated tag v1.77.0 with the settings-layout surfaces.
  Old: tag object `7380d36`, LibKa0s commit `78240f7`. New: tag object `b2b8ee2`
  (`b2b8ee25c5f9fa26db146254bf786b366dec986b`), LibKa0s commit `afae2f7`
  (`afae2f75cb7ff61c57156d9a3d8a6b2b9f4c5e10`). The provenance line stays v1.77.0; it records no
  sha and no kit revision, so nothing rolls there.
- **Per-file minors that moved:** OptionsCompose 8 -> 11 (minors 9-11: `tooltips` on the swatch
  composers, the noted master rows, and `O.ResetAllTooltip`). No other file under `LibKa0s/`
  changed, and `testkit/` is byte-identical, so the kit revision stays 42.
- **Contract blocker, fixed here:** the copy turned `tests/test_surface_parity.lua` red on exactly
  one member, `ResetAllTooltip is missing (live: function)`. `settings/OptionsSetup.lua`'s
  Options stub gains `ResetAllTooltip` as an inert no-op, as PC-RV did for the v1.77.0 members.
- **Declaration and prune:** `LibKa0s icons: clear, close, copy.` kept; the tag's
  `tools/prune-icons.lua` kept 4 files and removed 5836 (`media/icons/` unchanged in git).
- **Adopted:** nothing (PC-LY adopts). **Standard:** WS-95 touched only `options-ui` and
  `open-evolutions`; the three-place reference has no drift.
- **Gates:** `ka0s-bounded luacheck .` 0 warnings / 0 errors in 57 files;
  `ka0s-bounded lua tests/run.lua` 578 passed, 0 failed, 1 skipped (579), `test_vendor_sync` and
  `test_layout_cap` green.
