Delta: LibKa0s v1.66.0 -> v1.67.0

# LibKa0s v1.66.0 -> v1.67.0: the delta (PrettyChat)

Item CA-PC-RV of the 2026-10-02 LibKa0s census adoption (Ka0sAddonsCommonTasks
`docs/2026-10-02-LIBKA0S_CENSUS_ADOPTION/`, design key LK42). Copied from the **local** tag `v1.67.0`
(LibKa0s commit `0bccf4c`). The sibling checkout's `HEAD` equals `v1.67.0^{commit}` and its tree is
clean, so the copy was taken from that checkout (`rsync -a --delete` of both folders).

## 3a. The base

```sh
grep -n '[Bb]undles' CLAUDE.md
# 42:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.66.0 (MIT).
git log -1 --format=%h -- libs/LibKa0s tests/_kit        # 7acf9c0 (GI-PC-RV re-vendor)
diff -rq --strip-trailing-cr <v1.66.0>/LibKa0s libs/LibKa0s && echo payload-matches
```

The provenance line, the last payload commit and the payload agree: the base is **v1.66.0**.
`git -C ../LibKa0s log --oneline v1.66.0..v1.67.0` lists 6 commits (four of them `CA-LK-0x`).
The newest single-tag bundle, `2026-10-01-v1.66.0/`, states base v1.65.0 and was followed by no
unrecorded tag, so no span bundle is owed.

## 3b. Claimed against actual

Before the copy, `diff -rq --strip-trailing-cr` of the addon's payload against the v1.67.0 tree named
only the three files whose minor the tag moves. Every other minor matched v1.66.0. No skew.

## 3c. Per-file minors (the tag's `LibKa0s.xml`, in load order)

| File | old | new |
|---|---|---|
| Core.lua | 9 | **10** |
| Env, Compat, Lifecycle, Bus, Schema, Pool, Item, Media | 1, 1, 3, 2, 2, 3, 2, 4 | unchanged |
| Widgets, WidgetsReorder, WidgetsDragHandle | 12, 1, 3 | unchanged |
| DebugLog, DebugLogDiagnostics, DebugLogGates | 19, 2, 1 | unchanged |
| Slash, SlashParse, Launcher | 19, 1, 5 | unchanged |
| Options.lua | 27 | **28** |
| OptionsRegistry, OptionsWidgets, OptionsIds | 2, 34, 2 | unchanged |
| OptionsIdList.lua | IDLIST 2 | **IDLIST 3** |
| OptionsTabs, OptionsCombat, OptionsCompose, OptionsScroll, OptionsNav | 8, 1, 7, 4, 2 | unchanged |
| Perf, PerfSampler, PerfCommands, PerfPanel | 14, 1, 1, 6 | unchanged |

Options key 27.2.34.2.2.8.1.7.4.2 -> **28.2.34.2.3.8.1.7.4.2**. No file is added or removed (still 32
payload files, fifteen majors), no `NEEDS_*` floor rises and the TOC is unchanged.

## 3d. Both diffs, before the copy

`diff -rq --strip-trailing-cr <tag>/LibKa0s libs/LibKa0s`: `Core.lua`, `Options.lua`,
`OptionsIdList.lua` differ (125 insertions, 36 deletions). Nothing only in the tag, nothing only in
the addon, so the copy deletes nothing.

`diff -rq --strip-trailing-cr <tag>/testkit tests/_kit`: empty. The kit did not move.

After the copy, `diff -r` with and without `--strip-trailing-cr` is **empty** for both payloads.
Vendored text files stay LF in the index and CRLF on disk (`* text=auto eol=crlf`), as at 7acf9c0.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
```

Core (`core/CoreSetup.lua:41`), Env (`core/EnvSetup.lua:60`), Media (`core/MediaSetup.lua:42`),
Lifecycle (`core/LifecycleSetup.lua:67`), DebugLog (`core/DebugLogSetup.lua:69`,
`settings/Panel.lua:84`), Launcher (`core/LauncherSetup.lua:98`), Slash (`settings/Slash.lua:158`,
`settings/Schema.lua:911`), Schema (`settings/Schema.lua:802`), Options
(`settings/OptionsSetup.lua:17`). Unchanged from v1.66.0.

## 3f. Kit revision

`Kit.VERSION` stays **35** (`tests/_kit/framework.lua:20`); the testkit tree is byte-identical between
the two tags. The revision-11 pairing rule holds: both payloads come from the one tag in this commit.

## 3g. Contract delta (moved majors this addon consumes: Core, Options)

- **Core 10** (`docs/api/Core/version-10-docs.md`, "The resize grip", `:36`-`:54`): `MakeResizable`
  gains the optional `canResize`, `onResizeStop` and `gripParent`. PrettyChat calls no
  `MakeResizable` (`grep -rn MakeResizable core settings modules` is empty); the console's grip is the
  library's own and passes none of the three, so it behaves as on v1.66.0. No member is added, so the
  Core degradation stub in `core/CoreSetup.lua` does not move. **No blocker.**
- **Options 28** (`docs/api/Options/version-28.2.34.2.3.8.1.7.4.2-docs.md:72`): docblock-only
  correction; the only code change is the `MINOR` line. **No blocker.**
- **OptionsIdList 3** (same document, `:48`-`:65`): an `O.IdList` help mark's default art takes the
  descriptor's `addonName` only when the client reports that addon loaded, and a fall past that rung
  writes one `Cfg` debug line per instance. PrettyChat builds no `O.IdList`
  (`grep -rn IdList core settings modules` hits only the library-absent stub at
  `settings/OptionsSetup.lua:129` and its comment) and its descriptor
  (`settings/OptionsSetup.lua:253`) passes no `addonName` yet, so nothing draws differently. **No
  blocker.**
- No Core, Options or Media member is added or removed, so no degradation stub under
  `Kit.assertSurfaceParity` moves.

**Blockers:** none.

## 3h. Tags vendored and never recorded

None. v1.66.0 is recorded in `2026-10-01-v1.66.0/`, and v1.67.0 here.
