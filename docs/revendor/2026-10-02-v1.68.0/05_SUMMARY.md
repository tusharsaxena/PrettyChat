# Summary (PrettyChat)

LibKa0s v1.67.0 -> v1.68.0 from the local annotated tag `v1.68.0` (`cc9f5eb`; base from this
repo's CLAUDE.md provenance line, confirmed by the last payload commit `19b37be` and a
payload-matches diff against v1.67.0). Moved minors: WidgetsDragHandle 3 -> 4 (Widgets key 12.1.3
-> 12.1.4); every other file unchanged. No file added or removed (32 payload files), TOC
unchanged, nothing deleted. Kit revision stays 35 (testkit unchanged). CLAUDE.md provenance rolled
in the same commit. Item TP-PC-01. No span bundle owed, no base correction owed.

- **Delivered free (class A):** the drag handle's no-hook path, byte-for-byte minor 3's call order;
  PrettyChat draws no strip, so nothing it shows moves.
- **Contract blockers:** none (01_DELTA.md 3g: moved majors and consumed majors do not intersect).
- **Adopted:** nothing.
- **Declined:** `tooltipPlace` / descriptor `place` -> not applicable, PrettyChat has no drag
  strip (03_DECISIONS.md B1). No GitHub issue: the owner's plan files a decline only for a real gap,
  and this is not one.
- **Skipped or unreached:** none.
- **Docs:** live vendor stamps roll to v1.68.0 (CLAUDE.md; ARCHITECTURE External dependencies and the
  Slash minor note; module-map load order; debug.md; testing.md's layout-cap paragraph).
  `docs/test-cases.md` matches `lua tests/run.lua --list` byte-for-byte (CR-stripped) and the README
  badge stays 572/572: no case was added. No smoke check: nothing a player sees changes.
- **Observation, not changed here:** `docs/ARCHITECTURE.md` External dependencies says no other
  vendored LibKa0s file `LibStub`s Widgets, but `libs/LibKa0s/DebugLog.lua:33` does (for its copy
  window). Pre-existing and unrelated to this delta; left for a doc sync.

Gates (all through `ka0s-bounded`):

- tests: before the copy 572 passed / 0 failed / 1 skipped / 573 total; after the copy and the
  provenance roll 572 / 0 / 1 / 573, including both vendor-sync cases
  (`libs/LibKa0s is the LibKa0s release CLAUDE.md says this addon bundles`,
  `tests/_kit is the test kit that shipped with that release`).
- luacheck: 0 warnings / 0 errors in 56 files.
- complexity, sighted (`bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle`):
  pass, max CCN 15, 0 warnings, 1314 functions.
- vendor parity: `diff -r` of both payloads against the tag, with and without
  `--strip-trailing-cr`, is empty.
