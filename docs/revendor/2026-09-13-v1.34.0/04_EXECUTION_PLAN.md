# 04 — Execution plan

1. **Copy.** `libs/LibKa0s/` and `tests/_kit/` come whole from `git archive v1.34.0`. Afterwards both
   diffs are empty in content and in bytes.
2. **Ripple.** Roll every live reference to the bundled version:
   - `CLAUDE.md:34`, the provenance line;
   - `docs/ARCHITECTURE.md:332`, the vendored-library sentence;

   Dated records (reviews, audits, earlier revendor bundles) stay as they are. The test total does
   not move, so `docs/test-cases.md` and the README test badge do not move in this commit.
3. **Gate.** `lua tests/run.lua`, `luacheck .` and `lizard -C 15`, all green; CR == LF on every
   edited and new file.
4. **Commit.** One commit carrying both payloads, the provenance line, its reference and this
   bundle.
5. **Adopt, in its own commit.** Simplify `parseValue` in `settings/Slash.lua` to delegate to
   `lib.ParseValue` and unescape `||` on a `string` row's result. Correct the comments in
   `tests/test_slash.lua` and `tests/test_libka0s.lua` that describe the old first-token parse. Add
   one `tests/test_slash.lua` case: a multi-word value with `||` set through the slash keeps its
   interior spacing, and a direct `CliSet` has its edges trimmed. Confirm the case red before, then
   regenerate `docs/test-cases.md`, move the README badge and gate again.
