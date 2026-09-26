# Decisions (PrettyChat)

- No adoption in this item. The candidate-adoption interview is out of scope for the automated-tests
  sweep, and v1.62.0 offers no new surface anyway.
- The library-absent stub in `settings/OptionsSetup.lua` needs no new member: the id members it stubs
  (`IdInput`, `IdList`, `ResolveId`, `UnnamedCandidates`, `ID_NAME_HINT`) are unchanged, only relocated.
- `tests/test_libka0s.lua`'s "reads no descriptor L" source check follows the code it covered to its new
  files: `OptionsIds.lua`, `OptionsIdList.lua` and `OptionsRegistry.lua` join its list. Same case, more
  assertions; the case count does not move.
- Stale line citations of the library refreshed: the landing page's `OnRelease` is now at
  `OptionsWidgets.lua:352` (was 344) in `docs/ARCHITECTURE.md` and `docs/smoke-tests.md`, and
  `docs/module-map.md`'s LibKa0s XML load order is rewritten to the v1.62.0 file list.
- Plan: `Ka0sAddonsCommonTasks/docs/2026-09-26-AUTOMATED_TESTS_SWEEP/` (item PC-ATS-RV; ATS-20, ATS-21).
