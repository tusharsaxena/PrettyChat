Delta: LibKa0s v1.65.0 -> v1.66.0

# LibKa0s v1.65.0 -> v1.66.0: the delta (PrettyChat)

Item GI-PC-RV of the 2026-10-01 GitHub issue pass (Ka0sAddonsCommonTasks
`docs/2026-10-01-GITHUB_ISSUE_PASS/`, 02_SPEC.md S4). Copied from the **local** tag `v1.66.0`
(LibKa0s commit `e4c5ef7`) through `git -C ../LibKa0s archive v1.66.0 LibKa0s testkit`, never from a
working tree or a branch tip.

## 3a. The base

```sh
grep -n '[Bb]undles' CLAUDE.md
# 42:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.65.0 (MIT).
c=$(git log -1 --format=%H -- libs/LibKa0s tests/_kit)     # 7548ece (DG-PC-01 re-vendor)
git show "$c:CLAUDE.md" | grep -oE 'Bundles \[LibKa0s\]\([^)]*\) v[0-9.]+'
# Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.65.0
diff -rq <v1.65.0>/LibKa0s libs/LibKa0s && diff -rq <v1.65.0>/testkit tests/_kit && echo payload-matches
# payload-matches
```

The provenance line, the last payload commit and the payload itself agree: the base is **v1.65.0**.
`git -C ../LibKa0s log --oneline v1.65.0..v1.66.0` lists 24 commits.

Step 0 for this addon: the newest single-tag bundle, `2026-09-29-v1.63.0/`, states base v1.62.0,
and the provenance line before its re-vendor commit `40a2b5f` was v1.62.0. No correction is owed.

## 3b. Claimed against actual

Every minor in `libs/LibKa0s/` before the copy matched v1.65.0's (3c's `old:` column). No skew.

## 3c. Per-file minors (the tag's `LibKa0s.xml`, in load order)

| File | old | new |
|---|---|---|
| Core, Env, Compat, Lifecycle, Bus, Schema, Pool, Item, Media | 9, 1, 1, 3, 2, 2, 3, 2, 4 | unchanged |
| Widgets.lua | 11 | **12** |
| WidgetsReorder.lua | (new) | **REORDER_MINOR 1** |
| WidgetsDragHandle.lua | DRAG 3 | 3 |
| DebugLog.lua | 18 | **19** |
| DebugLogDiagnostics.lua, DebugLogGates.lua | DIAG 2, GATES 1 | unchanged |
| Slash.lua | 18 | **19** |
| SlashParse.lua | (new) | **PARSE_MINOR 1** |
| Launcher.lua | 5 | 5 |
| Options.lua, OptionsRegistry.lua | 27, REGISTRY 2 | unchanged |
| OptionsWidgets.lua | WIDGETS 33 | **34** |
| OptionsIds.lua, OptionsIdList.lua | IDS 2, IDLIST 2 | unchanged |
| OptionsTabs.lua | TABS 7 | **8** |
| OptionsCombat, OptionsCompose, OptionsScroll, OptionsNav | 1, 7, 4, 2 | unchanged |
| Perf.lua | 13 | **14** |
| PerfSampler.lua | (new) | **SAMPLER_MINOR 1** |
| PerfCommands.lua | (new) | **COMMANDS_MINOR 1** |
| PerfPanel.lua | PANEL 6 | 6 |

Command: the 3c loop over `git -C ../LibKa0s show v1.66.0:LibKa0s/LibKa0s.xml`. Four files are new
(28 -> 32 payload files), no `NEEDS_*` floor rises and no major is added.

## 3d. Both diffs, before the copy

`diff -rq --strip-trailing-cr <tag>/LibKa0s libs/LibKa0s`: `DebugLog.lua`, `LibKa0s.xml`,
`OptionsTabs.lua`, `OptionsWidgets.lua`, `Perf.lua`, `Slash.lua`, `Widgets.lua` differ; only in the
tag: `PerfCommands.lua`, `PerfSampler.lua`, `SlashParse.lua`, `WidgetsReorder.lua`. Nothing only in
the addon, so the copy deletes nothing.

`diff -rq --strip-trailing-cr <tag>/testkit tests/_kit`: `README.md`, `asserts.lua`, `framework.lua`,
`inventory.lua`, `mock_base.lua`, `run-automated-tests.sh`, `test_eol.lua` differ; only in the tag:
`lizard_sighted.lua`, `test_lizard_sighted.lua`.

After the copy (`rsync -a --delete` of both folders), `diff -r` with and without
`--strip-trailing-cr` is **empty** for both payloads.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
```

Core (`core/CoreSetup.lua:41`), Env (`core/EnvSetup.lua:60`), Media (`core/MediaSetup.lua:42`),
Lifecycle (`core/LifecycleSetup.lua:67`), DebugLog (`core/DebugLogSetup.lua:69`,
`settings/Panel.lua:84`), Launcher (`core/LauncherSetup.lua:98`), Slash (`settings/Slash.lua:158`,
`settings/Schema.lua:911`), Schema (`settings/Schema.lua:802`), Options
(`settings/OptionsSetup.lua:17`). Unchanged from v1.65.0. Widgets and Perf are not looked up here.

## 3f. Kit revision

`Kit.VERSION` 34 -> **35** (`tests/_kit/framework.lua:20`). Both payloads move in this one commit,
which also satisfies the revision-11 pairing rule by construction.

## 3g. Contract delta (moved majors this addon consumes: Slash, DebugLog, Options)

- **Slash 19** (`docs/api/Slash/version-19.1-docs.md:59`, `:759`, `:914`): a host `parse` is now
  handed `Sl:Text` as a third argument. `settings/Slash.lua:280` `parseValue(row, text)` takes two
  arguments and ignores a third, so nothing changes; it calls `lib.ParseValue(row, text)` with no
  resolver, which answers in `lib.STRINGS` exactly as minor 18 did. `settings/Schema.lua:915`
  calls `slashLib.FormatValue(row, v)` with two arguments, as before. The descriptor passes no `L`,
  so `Sl:Text` resolves to the library's own strings either way. **No blocker.**
- **SlashParse 1**: `lib.ParseValue` moved file, unchanged; whole-folder copy carries it.
- **DebugLog 19**: `lib:New`'s field reads moved to file-level helpers; no member, field, default or
  string moves. **No blocker.**
- **OptionsWidgets 34** (`docs/api/Options/version-27.2.34.2.2.8.1.7.4.2-docs.md:1364`): `RenderGrid`
  gains `parent` and `opts`. PrettyChat does not call `RenderGrid` (its degradation stub at
  `settings/OptionsSetup.lua:73` is a no-op that ignores arguments). **No blocker.**
- **OptionsTabs 8** (same document, `:49`-`:54`, `:1338`): three opt-in `RenderTabbedSchema` fields,
  all off by default. `settings/Panel.lua:141` passes no `opts`. **No blocker.**
- No Slash, Options, Launcher, Lifecycle or DebugLog member is added or removed (CHANGELOG v1.66.0,
  "What a consumer owes"), so no degradation stub under `Kit.assertSurfaceParity` moves.

**Blockers:** none.

## 3h. Tags vendored and never recorded

The 3h listing printed `v1.64.0` and `v1.65.0` (vendored by `fa4f9fd`/`49edc8b` and `7548ece`,
no bundle). They are recorded in the span bundle beside this one,
`docs/revendor/2026-10-01-v1.64.0-v1.65.0/`.
