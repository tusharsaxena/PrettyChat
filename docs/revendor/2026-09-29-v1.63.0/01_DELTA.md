# LibKa0s v1.62.0 -> v1.63.0: the delta (PrettyChat)

Copied from the local tag `v1.63.0` (commit `dd7a774`), never from a working tree. The delta base is
this repo's own CLAUDE.md provenance line (`v1.62.0`).

## libs/LibKa0s (`diff -rq --strip-trailing-cr`, before the copy)

```
Files <tag>/LibKa0s/Slash.lua and libs/LibKa0s/Slash.lua differ
```

- `Slash.lua`: minor 16 -> 17. The `profile` verb's behavior ships in the library, once:
  - a new optional descriptor field, `profiles` (a function answering the host's profile store,
    duck-typed on AceDB-3.0's `GetProfiles` / `GetCurrentProfile` / `SetProfile`);
  - two new instance members, `Sl:CliProfile(rest)` and `Sl:ProfileSwitch(name)`;
  - one new lib-level function, `lib.ProfileNames(store)`;
  - nine new `lib.STRINGS` keys (`PROFILE_UNAVAILABLE`, `PROFILE_LIST_HEADER`,
    `PROFILE_CURRENT_MARK`, `PROFILE_HINT`, `PROFILE_ALREADY`, `PROFILE_COMBAT`,
    `PROFILE_SWITCHED`, `PROFILE_UNKNOWN`, `PROFILE_DID_YOU_MEAN`).
- `profile` is not added to `lib.LIVE_VERBS` and is not reserved. No `NEEDS_*` floor moves, and no
  other file in the payload changed (`LibKa0s.xml` is byte-identical, so the load order is too).

## tests/_kit

Byte-identical to the vendored copy: kit revision 31 on both sides.

## What the re-vendor alone does here

`tests/test_surface_parity.lua`'s "the Slash stub carries the whole live surface" goes red, with the
message the Slash version-17 document predicts: the by-name `assertSurfaceParity` reads the live
dispatcher instance, which now carries `CliProfile` and `ProfileSwitch`, and the library-absent stub
in `settings/Slash.lua` carried neither. That is the only failed case (530 of 531 passed).
