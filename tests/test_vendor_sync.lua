-- tests/test_vendor_sync.lua — the consumer-side vendored-payload gate (testing-§11).
--
-- The ~80 hand-written lines that used to live at the bottom of tests/test_harness.lua are gone.
-- The gate is now `tests/_kit/vendor_sync.lua`, vendored from LibKa0s like everything else in
-- tests/_kit/, and this file is the factory call that registers it. The case names are unchanged,
-- so docs/test-cases.md's counts do not move — they only move suite.
--
-- ONE NORMALIZATION, AND ONLY ONE — the reason it stays, carried in verbatim from
-- AbsorbTracker/tests/test_vendor_sync.lua:28-32:
--
--   `git show` hands back the stored blob, which is LF, while the working tree is CRLF because
--   `.gitattributes` pins `* text=auto eol=crlf`. CR is stripped from the working-tree side so the
--   file is compared to the blob it round-trips to. Nothing else is normalized — a real fork in
--   content still fails.
--
-- Line endings are decided per checkout by `.gitattributes`, so the same commit legitimately
-- materialises as CRLF here and LF in a repo that does not pin them; treating that as a content
-- fork would redden this gate for a fact about the checkout rather than about the bytes.
--
-- Where the sibling ../LibKa0s checkout is absent the two cases report SKIP carrying that reason —
-- not PASS, which is what the old bare `return` did, and not a failure either, because a missing
-- sibling means the comparison did not run rather than that it disagreed.
--
-- No `opts` are needed: this repo's root is ".", its sibling is ../LibKa0s, and its provenance
-- line — the "Bundles [LibKa0s](...) v1.8.1 (MIT)." sentence in CLAUDE.md's repo-facts list — is
-- matched by the kit's default pattern, whose default `provenanceFile` is already "CLAUDE.md".
--
-- Kit revision 9 moved that input out of README.md, with no fallback. README.md is the player's
-- page and no longer carries a bundled-library inventory at all; CLAUDE.md is where this repo
-- keeps the build facts a maintainer or an agent needs, so the line lives there and the gate
-- follows it. The line is deliberately cited by content, not by line number, so moving it again
-- does not leave a false `CLAUDE.md:NNN` here.

local VendorSync = dofile("tests/_kit/vendor_sync.lua")

VendorSync.register(_G.PC_TEST, {})
