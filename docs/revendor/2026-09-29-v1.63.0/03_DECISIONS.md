# Decisions (PrettyChat)

- **Adopted: the Slash minor 17 profile surface, and only it.** The adoption is not this skill's
  interview: it is item SP-PC-02 of the collection run
  `Ka0sAddonsCommonTasks/docs/2026-09-29-SMOKE_REWORK_AND_PROFILE_VERB/` (spec S3, owner decisions
  D1-D3), which re-vendors and then adds `/pc profile` through `CliProfile`. No adoption interview was
  run and no GitHub issue was filed for this re-vendor.
- **In the re-vendor commit:** the library-absent stub in `settings/Slash.lua` gains `CliProfile` and
  `ProfileSwitch`, because the parity case compares it against the live instance (see
  `01_DELTA.md`). Both take the Slash version-17 document's route (b): each prints the stub's one
  missing-library line and switches nothing, and `ProfileSwitch` answers `false`.
  `tests/test_libka0s.lua`'s degraded-Slash case pins both (one line each, no switch, no profile
  created); it gains assertions, not a case, so the count stays 531.
- **In the second SP-PC-02 commit:** the `profile` COMMANDS row, the `profiles` descriptor field, a
  `liveVerbs` built from `lib.LIVE_VERBS` plus `"profile"` so the verb answers while disabled, and
  its tests and docs.
- Version-now lines rolled with the provenance line: `docs/ARCHITECTURE.md` (library inventory and the
  gate's minor), `docs/module-map.md` (the load order is unchanged), `docs/testing.md` and
  `docs/slash-dispatch.md` (the gate's minor). The `docs/performance-sweep.md` sweep citations into
  `tests/test_libka0s.lua` move by the 24 lines the degraded case gained.
