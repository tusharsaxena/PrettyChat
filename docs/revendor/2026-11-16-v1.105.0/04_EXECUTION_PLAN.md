# 04 Execution plan

Nothing adopted, so no characterization tests and no adoption commits. The run is one commit, RV-PC:

- both payloads copied whole from the v1.105.0 extract, then pruned by the tag's `tools/prune-icons.lua`;
- the CLAUDE.md provenance line rolled to v1.105.0, the `LibKa0s icons:` line kept;
- `core/DebugLogSetup.lua`: the library-absent DebugLog stub gains `Report` (streams the report's lines to chat with no pointer line, returns the count) and `Serialize` (one safe line), both as methods like the live instance;
- `settings/OptionsSetup.lua`: the library-absent Options stub gains `SideTabs`, a no-op beside `NavRail`;
- this bundle and the v1.94.0 span bundle.

No test was changed, skipped or deleted; the suite count is unchanged at 695.
