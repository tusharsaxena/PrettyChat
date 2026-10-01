# Summary (PrettyChat)

LibKa0s v1.65.0 -> v1.66.0 from the local tag (base from this repo's CLAUDE.md provenance line).
Moved minors: Widgets 11 -> 12, DebugLog 18 -> 19, Slash 18 -> 19, OptionsWidgets 33 -> 34,
OptionsTabs 7 -> 8, Perf 13 -> 14; new files WidgetsReorder 1, SlashParse 1, PerfSampler 1,
PerfCommands 1 (payload 28 -> 32 files, all loaded through `libs\LibKa0s\LibKa0s.xml`, so the TOC is
unchanged). Kit revision 34 -> 35. CLAUDE.md provenance rolled in the same commit. Item GI-PC-RV.

- **Span bundle:** `docs/revendor/2026-10-01-v1.64.0-v1.65.0/` records the two tags vendored since
  v1.63.0 without a bundle. No base correction was owed.
- **Delivered free (class A):** the Slash parser peel, DebugLog 19's refactor, and kit 35's sighted
  complexity suite. Perf and Widgets changes are vendored but not consumed.
- **Contract blockers:** none (01_DELTA.md 3g).
- **Adopted:** nothing. **Declined:** nothing. **Unreached:** the three class-B candidates in
  02_CANDIDATES.md, deferred by plan to GI-LK-13's census; no interview was held and no issue filed.
- **Wiring:** `{ name = "test_lizard_sighted", dir = "tests/_kit/" }` in `tests/run.lua`;
  `docs/test-cases.md` regenerated (+8 cases); README badge 571/571. The live vendor stamps
  (ARCHITECTURE, module-map load order, debug.md, testing.md) roll to v1.66.0, and the raw
  `lizard` lines in `DEPENDENCIES.md` and `docs/testing.md` now point at the runner's sighted
  complexity suite.

Gates after the copy:

- tests: 571 passed, 0 failed, 1 skipped, 572 total (563 / 0 / 1 / 564 before; the +8 are
  `test_lizard_sighted.lua`'s cases, lizard on PATH). No consumer test broke.
- luacheck: 0 warnings / 0 errors in 56 files.
- complexity, sighted (`bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle`):
  pass, maxCcn 15, warnings 0, blindFiles 0, 1313 functions (raw lizard listed 1230; the 83 it
  never saw are all at or under CCN 15).
- vendor parity: `diff -r` of both payloads against the tag is empty.
