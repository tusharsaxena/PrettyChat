# 02 — Candidates: LibKa0s v1.34.0

Sources: `git -C ../LibKa0s log --oneline v1.33.0..v1.34.0`, the v1.34.0 block of
`../LibKa0s/CHANGELOG.md`, `../LibKa0s/docs/releasing.md` ("Re-vendoring consumers"),
`../LibKa0s/docs/api/Slash/version-10-docs.md`, `../LibKa0s/docs/api/Options/version-18.15.5.3-docs.md`
and `../LibKa0s/docs/api/testkit/version-19-docs.md`.

## Class A: reached the addon on the re-vendor alone

- **The whole-value string parse (Slash minor 10).** **Not reached yet.** The descriptor's `parse`
  (`settings/Slash.lua:154`) answers every `string` row itself, taking the whole remainder and
  unescaping `||`, and hands only the other types to `lib.ParseValue`. The `string` rows are every
  `<Category>.<GLOBALNAME>.format` row (`settings/Schema.lua:271`): free text with no `values`. They
  kept multi-word values before this release through that adapter, so no row newly keeps one. The
  adapter's whitespace half is now redundant; see class B.
- **The *Reset all settings* tooltip (Options minor 18, OptionsCompose minor 5).** **Unchanged, and
  still correct.** The block is composed frameless through `H.MasterControls`
  (`settings/Schema.lua:409`). The descriptor supplies no `resetProfile`, so the text stays byte for
  byte *"Restore every setting in this addon to its default."* The button's `onResetAll`
  (`settings/Schema.lua:112`) raises `PRETTYCHAT_RESET_ALL`, whose accept runs `PrettyChat:ResetAll`:
  one `db:ResetProfile()` on the active profile. That resets every setting this addon has.
  `AceDB:New(…, true)` (`core/PrettyChat.lua:37`) puts every character on the one shared `Default`
  profile, and the addon ships no Profiles page, so a player has no other profile. The profile wording
  would promise *"your other profiles are not affected"* to someone who has none. `profilesPage` does
  not apply either.
- **Kit revision 19, `OnProfileReset` without a key.** **Reached, and nothing moves.** The harness
  builds on the kit's AceDB (`tests/wow_mock.lua:92`), and `tests/test_debuglog.lua:360` resets
  through it. The handler, `PrettyChat:OnProfileReset()` (`core/PrettyChat.lua:120`), reads no key.
  It names the profile from `GetCurrentProfile()`.
- **No surface change.** No member is added to either instance, so no surface-parity exclusion moves.

## Class B: host change required

- **Simplify the `parse` adapter to rely on the library.** Minor 10 gives a `string` row the whole
  remainder, so the adapter's own empty-check and whole-remainder return restate the library. What
  stays is the `||` → `|` unescape, which the library does not do and which mirrors `formatValue` on
  the way out, so a value copied from `/pc get` pastes back into `/pc set` unchanged. One thing
  differs: the library **trims both edges** and the adapter did not. That does not matter here. The
  library's `OnSlash` already trims the whole input at both ends before any verb runs
  (`libs/LibKa0s/Slash.lua:651`), so an edge space typed in chat never reached `parse` at minor 9
  either. The only caller the trim reaches is a direct `CliSet` call, and nothing in this addon
  makes one with a value. Interior whitespace is the part that matters: the shipped formats are
  full of runs such as `|cffffffff | |cff…`. The library keeps it verbatim. Recommended: adopt, and
  rely on the library's trim.
- **`profilesPage` / `resetProfile`.** Not a candidate. See the tooltip entry above.

## Class C: whole-module adoption

None. No module is new at this tag.

## Noted, not taken

- Six shipped defaults end in a space (`defaults/Defaults.lua:9`, `:17`, `:164`, `:188`, `:347`,
  `:351`, all ending `|cffffffff `). Pasting one of them back through `/pc set` loses that trailing
  space, because the dispatcher trims the input. It did so at minor 9 as well, so this release does
  not change it.
