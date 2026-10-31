# LibKa0s v1.83.0 -> v1.84.0: summary (PrettyChat)

- **Tag:** v1.83.0 -> v1.84.0 (local tag, LibKa0s commit `e917ccd`); base from the `CLAUDE.md` provenance
  line, confirmed by the payload diff against v1.83.0. Kit revision 46 -> 47. Minors are in
  `01_DELTA.md` 3c: no skew.
- **Span bundle:** none owed. **Base correction:** none.
- **Delivered for free (class A):** the peels, the Friz guard, Charts in the diagnostics header.
- **Contract blocker (3g), fixed in this commit:** the Options stub owes `O.PositionBlock`; the copy
  turned `tests/test_surface_parity.lua` red on exactly that. `settings/OptionsSetup.lua` answers no
  rows and no hook.
- **Pins moved:** the descriptor-L sweep in `tests/test_libka0s.lua` follows the code to `OptionsFlow`,
  `OptionsTabbed` and `OptionsIdSuggest`. `tests/loader.lua` derives its list from the XML, so it needed
  nothing, and no suite here pins `DebugLogDiagnostics 5`.
- **Declaration:** `LibKa0s icons: clear, close, copy, settings.` kept. Prune: kept 5 files, removed
  5835 (Open Iconic, Phosphor and Game-icons; `media/icons/` unchanged in git). No provenance split.
- **Credits:** unchanged. **Dead stub mirrors removed:** none.
- **Live stamps rolled:** `docs/ARCHITECTURE.md` (v1.84.0, twenty majors), `docs/module-map.md` (the XML
  order, including the files added since v1.81.0), `docs/testing.md` (kit revision 47) and
  `docs/debug.md` (DebugLogDiagnostics 6).
- **Smoke checks added:** SKIN-26 (the moved files) and DIAG-28 (Charts in the header). Result empty.
- **Adopted:** nothing. **Declined:** the four class B candidates and Charts, in `03_DECISIONS.md`, with
  no issues filed, as the run's dispatch said (not the bundle; see `03_DECISIONS.md`).
  **Unreached:** none.
- **Gate:** `ka0s-bounded lua tests/run.lua` 656 passed, 0 failed, 1 skipped (657 total);
  `ka0s-bounded luacheck .` 0 warnings / 0 errors in 67 files.
