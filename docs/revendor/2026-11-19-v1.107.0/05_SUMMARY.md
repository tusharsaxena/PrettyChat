# 05 Summary

- Tag moved v1.106.0 -> v1.107.0, base taken from the CLAUDE.md provenance line. Kit revision 57 -> 57. Two files moved a minor: WidgetsDragHandle 14 -> 15, WidgetsDragHandleTip 1 -> 2. No file added or removed.
- Span bundle: `docs/revendor/2026-11-19-v1.106.0-v1.106.0/` (one tag, v1.106.0). Base correction: none.
- Delivered for free (class A): the drag strip's header-order marks, tints and tooltip placement, and the settings-mark re-level fix (LibKa0s#96). None of it draws in this frameless addon.
- Contract blockers: none. The tag's consumer duties bind a host with a drag strip; PrettyChat has none.
- LibKa0s icons: line kept as written (12 names, `settings` among them). The prune removed what the copy restored and nothing else; a second run removed 0. README credits unchanged: only Open Iconic ships, as before. No provenance split, no dead stub mirror.
- Host files changed: none. Docs: `CLAUDE.md` provenance line, `docs/midnight-quirks.md` vendored block (v2.103.1 -> v2.115.0), `docs/smoke-tests.md` RV-107.
- Adopted: nothing. Declined: nothing. Unreached: nothing.
- Gate: `ka0s-bounded lua tests/run.lua` 696 passed, 0 failed, 1 skipped (697; the skip is the pre-existing diagnostics opt-out case); `KA0S_KIT_CLIENT=forever` the same; `ka0s-bounded luacheck .` 0 warnings / 0 errors in 70 files; `docs/test-cases.md` matches `lua tests/run.lua --list`.
- Smoke owed (owner): RV-107, a clean load on the new payload.
