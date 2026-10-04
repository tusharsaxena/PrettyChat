# Summary (PrettyChat)

LibKa0s v1.68.0 -> v1.68.1 from the annotated tag `v1.68.1` (`9000cbd`; base from this repo's
CLAUDE.md provenance line, confirmed by the last payload commit `3670b81` and a payload-matches diff
against v1.68.0). Rename-only release: every LibStub minor unchanged across all 32 library files,
no file added or removed, nothing deleted. Kit revision 35 -> 36 (three `tests/_kit/` files:
`framework.lua`, `run-automated-tests.sh`, `test_eol.lua`). CLAUDE.md provenance rolled in the same
commit. Item DC-REV-01. Step 0 all `ok`; no span bundle owed, no base correction owed.

- **Delivered free (class A):** kit revision 36, which names the `/dev-copilot:*` commands where
  revision 35 named `/wow-addon:*`. No behavior change.
- **Contract blockers:** none (01_DELTA.md 3g: no major moved a minor).
- **Adopted:** nothing. **Zero adoption candidates**, so no interview was held.
- **Declined:** nothing; no issue filed.
- **Skipped or unreached:** none.
- **Docs:** live vendor stamps roll to v1.68.1 (CLAUDE.md; ARCHITECTURE External dependencies and
  the Slash minor note; module-map load order; debug.md; testing.md's layout-cap paragraph, which
  also moves "kit revision 35" to 36). `docs/testing.md`'s suite table keeps "(kit revision 35)" on
  the complexity row and `tests/run.lua:158` keeps "its own since revision 35": both name the
  revision that introduced the sighted complexity gate, not the revision vendored. `docs/test-cases.md`
  matches `lua tests/run.lua --list` byte-for-byte (CR-stripped); no case moved.
  `docs/automated-tests/RESULTS.md` still prints `/wow-addon:bump-version` in its runner-written
  lead-in; the next automated-test run rewrites that line (not hand-edited here).

Gates (all through `ka0s-bounded`):

- tests: before the copy 572 passed / 0 failed / 1 skipped / 573 total; after the copy and the
  provenance roll 572 / 0 / 1 / 573, including both vendor-sync cases
  (`libs/LibKa0s is the LibKa0s release CLAUDE.md says this addon bundles`,
  `tests/_kit is the test kit that shipped with that release`).
- luacheck: 0 warnings / 0 errors in 56 files (`.luacheckrc` excludes `libs` and `tests/_kit/`; no
  host seam changed, so nothing outside the checked set needed reading).
- vendor parity: `diff -r` of both payloads against the tag, with and without
  `--strip-trailing-cr`, is empty.
- perf / complexity: not run; the spec's gate is luacheck and the headless harness, and the payload
  change touches only comments, one printed line and the kit revision constant.
