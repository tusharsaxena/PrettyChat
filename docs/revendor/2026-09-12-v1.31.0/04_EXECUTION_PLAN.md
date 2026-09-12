# 04 — Execution plan

One adopted candidate, B1. All four Step-7 fences hold: `libs/` and `tests/_kit/` are not touched
after the copy (`8a2fdf9`), no setup file changes, the diff changes no production behavior, and no
close control is involved.

## B1. `NewAddon` takes the kit's faithful path

**Files:** `tests/wow_mock.lua`, `tests/test_lifecycle.lua`, `docs/testing.md`.

1. **Characterization first.** `tests/test_lifecycle.lua`'s "OnInitialize registers /pc and its
   /prettychat alias" read `addon.slashCommands[...]`, a table only the mock's recorder filled. It now
   asserts `AceConsole.commands["pc"] == "ACECONSOLE_PC"` (and `prettychat`), then runs
   `AceConsole:__slash(command, "version")` for both and checks that the printed line carries
   `NS.version`. That proves typing the command reaches `PrettyChat:OnSlashCommand`, not merely
   that a method name was handed over.
   - Against the old mock: **red**, `/pc is registered (expected ACECONSOLE_PC, got nil)`;
     332 passed, 1 failed.
2. **The change.** Override 9 no longer replaces `M.__libs["AceAddon-3.0"]`. It wraps the kit's
   `NewAddon`, calls it with every argument, and layers only `Print` on the returned object. The
   local `addons` table, `GetAddon`, `object.name`, `object.slashCommands` and the
   `RegisterChatCommand` stamp are deleted. The header's item 9 says what stays and why.
3. **Docs.** The `docs/testing.md` harness bullet that described the mock's own `GetAddon` now
   describes the wrapper.

**Gate:** `lua tests/run.lua` 333 passed, 0 failed, 0 skipped. `luacheck .` 0 warnings / 0 errors in
44 files. `docs/test-cases.md` is unchanged, because the case kept its name
(`lua tests/run.lua --list | diff --strip-trailing-cr - docs/test-cases.md` is empty), so the README
`Tests` badge stays 333/333. CR == LF in every edited file.

**Commit:** `de344d3`, after the re-vendor commit `8a2fdf9`.
