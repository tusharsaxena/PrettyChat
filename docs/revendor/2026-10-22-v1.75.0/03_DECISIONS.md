# LibKa0s v1.71.0 -> v1.75.0: decisions (PrettyChat)

Every decision here was pre-decided by the run's item spec (PC-RV in
`Ka0sAddonsCommonTasks/docs/2026-10-22-LIBKA0S_ISSUES_45_58/`), so none was interviewed.

1. **The declaration: `LibKa0s icons: clear, close, copy.`**, on its own line directly under the
   `CLAUDE.md` provenance line, which was already a standalone sentence (no split). Derivation in
   `01_DELTA.md` 3i: the DebugLog console draws `copy`, `clear` and `close` from this copy because
   `core/DebugLogSetup.lua:190` passes `addonName`; the copy window's close is the same `close`;
   `NS.Icon` and `NS.MakeCloseButton` have no production caller; no IdList is drawn, so no `info`.
2. **The Options degradation stub gains `Drawer`** (`settings/OptionsSetup.lua`, after `NavRail`),
   an inert no-op, because `tests/test_surface_parity.lua`'s Options case iterates the live surface.
3. **The dead `__releaseChrome` mirror is removed** from the same stub (LibKa0s#45, OptionsTabs 9).
   The other `__` mirrors stay: their live members still exist.
4. **Two icon tests rewritten to the declaration.**
   `tests/test_mediasetup.lua`'s whole-catalog loop becomes
   `MediaSetup: every icon CLAUDE.md declares has a file in the vendored copy, and nothing else ships`,
   reading the line through the kit's `VendorSync.iconDeclaration`. `tests/test_libka0s.lua`'s
   `info.tga` half now asserts that no IdList is drawn outside the stub, that the declaration does
   not name `info` and that `info.tga` is absent. Both were confirmed red with `info.tga` put back.
5. **README `## Credits` gains the Open Iconic paragraph** (documentation-§1 item 12, a SHOULD for a
   shipped MIT set). Only Open Iconic ships after the prune, so there is no Game-icons MUST and no
   Phosphor line.
