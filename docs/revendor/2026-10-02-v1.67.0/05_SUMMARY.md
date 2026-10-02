# Summary (PrettyChat)

LibKa0s v1.66.0 -> v1.67.0 from the local tag `v1.67.0` (`0bccf4c`; base from this repo's CLAUDE.md
provenance line). Moved minors: Core 9 -> 10, Options 27 -> 28, OptionsIdList 2 -> 3 (Options key
28.2.34.2.3.8.1.7.4.2). No file added or removed (32 payload files), TOC unchanged. Kit revision
stays 35 (testkit unchanged). CLAUDE.md provenance rolled in the same commit. Item CA-PC-RV.

- **Delivered free (class A):** the Options 28 docblock correction.
- **Contract blockers:** none (01_DELTA.md 3g).
- **Candidates:** `addonName` on the Options descriptor -> CA-PC-NM (latent: no `O.IdList` here);
  the three `MakeResizable` fields -> none (no host-owned resizable window). No interview, no issue.
- **Docs:** the live vendor stamps (CLAUDE.md, ARCHITECTURE External dependencies and the Slash
  minor note, module-map load order, debug.md, testing.md) roll to v1.67.0. `docs/test-cases.md`
  regenerates byte-identical and the README badge stays 571/571, because no case was added.
  No smoke check: nothing a player sees changes.

Gates after the copy:

- tests: 571 passed, 0 failed, 1 skipped, 572 total, the same as before the copy. Between the copy
  and the provenance roll the vendor-sync gate failed as designed
  (`libs/LibKa0s is the LibKa0s release CLAUDE.md says this addon bundles`); no consumer test broke.
- luacheck: 0 warnings / 0 errors in 56 files.
- complexity, sighted (`bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle`):
  pass, max CCN 15, 0 warnings, 1313 functions.
- vendor parity: `diff -r` of both payloads against the tag is empty.
