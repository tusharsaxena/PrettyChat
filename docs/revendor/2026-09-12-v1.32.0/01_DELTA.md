# 01 — Delta: PrettyChat vs LibKa0s v1.32.0

Run date: 2026-09-12, the bulk-logging rollout of the 2026-09-12 triage, on branch
`fix/2026-09-12-triage`. This is the third bundle dated 2026-09-12, after `docs/revendor/2026-09-12/`
(v1.30.0) and `docs/revendor/2026-09-12-v1.31.0/`, so this folder carries its tag in its name too.
Both earlier bundles are frozen and were not touched.

Library checkout: `../LibKa0s`, tag `v1.32.0` on `e18dd12` ("The v1.32.0 release record, re-taken on
the final tree"). The tag is local and has not been pushed. The payload came from the tag, not from
the working tree:

```sh
git -C ../LibKa0s tag --points-at e18dd12        # v1.32.0
git -C ../LibKa0s archive v1.32.0 LibKa0s testkit | tar -x -C <scratch>/
```

## 3a. Claimed version

```sh
grep -n '[Bb]undles' PrettyChat/CLAUDE.md
```

`CLAUDE.md:34` reads "Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.31.0 (MIT)."
`README.md` has no provenance line. `docs/ARCHITECTURE.md:332` (External dependencies) names v1.31.0
too, so it rolls in the same commit.

## 3b. Actual version: the vendored minors

```sh
grep -hoE 'local (MAJOR, )?(MINOR|WIDGETS_MINOR|SCROLL_MINOR|PANEL_MINOR|COMPOSE_MINOR) *= *("[^"]+", *)?[0-9]+' PrettyChat/libs/LibKa0s/*.lua
```

The claim matches the bytes: every vendored minor is the one v1.31.0 (`e7e1962`) shipped.

## 3c. Per-file minor delta

The file list comes from the tag's `LibKa0s/LibKa0s.xml` (14 files).

| File | Constant | Vendored (v1.31.0) | v1.32.0 | Delta |
|---|---|---|---|---|
| `Core.lua` | `MINOR` | 7 | 7 | none |
| `Env.lua` | `MINOR` | 1 | 1 | none |
| `Pool.lua` | `MINOR` | 3 | 3 | none |
| `Item.lua` | `MINOR` | 1 | 1 | none |
| `Media.lua` | `MINOR` | 3 | 3 | none |
| `Widgets.lua` | `MINOR` | 9 | 9 | none |
| `DebugLog.lua` | `MINOR` | 12 | 12 | none |
| `Slash.lua` | `MINOR` | 7 | **8** | +1 |
| `Options.lua` | `MINOR` | 15 | **16** | +1 |
| `OptionsWidgets.lua` | `WIDGETS_MINOR` | 15 | 15 | none |
| `OptionsCompose.lua` | `COMPOSE_MINOR` | 4 | 4 | none |
| `OptionsScroll.lua` | `SCROLL_MINOR` | 3 | 3 | none |
| `Perf.lua` | `MINOR` | 11 | 11 | none |
| `PerfPanel.lua` | `PANEL_MINOR` | 5 | 5 | none |

**No cross-major skew.** The vendored copy is behind the tag only on the two files v1.32.0 changes,
and the whole folder is copied in one step.

## 3d. Both diffs, both directions (before the copy)

```sh
diff -rq --strip-trailing-cr <scratch>/LibKa0s PrettyChat/libs/LibKa0s   # Options.lua, Slash.lua
diff -rq                     <scratch>/LibKa0s PrettyChat/libs/LibKa0s   # the same 2
diff -rq --strip-trailing-cr <scratch>/testkit PrettyChat/tests/_kit     # empty
diff -rq                     <scratch>/testkit PrettyChat/tests/_kit     # empty
```

- Library payload: **content dirty** on `Options.lua` and `Slash.lua`, the two files v1.32.0 changes.
  Nothing else differs, in content or in bytes.
- Test kit: clean in content and in bytes. v1.32.0 leaves `testkit/` alone.
- Neither side has an `Only in` line, so no file removed upstream survives here.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' PrettyChat --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
```

- `core/CoreSetup.lua:41`: Core
- `core/DebugLogSetup.lua:39`: DebugLog
- `core/EnvSetup.lua:59`: Env
- `core/MediaSetup.lua:42`: Media
- `settings/OptionsSetup.lua:17`: Options
- `settings/Schema.lua:457`: Slash
- `settings/Slash.lua:74`: Slash

The payload has four majors with no lookup here: `Item`, `Pool`, `Widgets`, `Perf`. `Perf` is declined
by the `performance-§12` row in `docs/ARCHITECTURE.md` → `## Documented deviations`. None of the four
changed in v1.32.0, so none is raised as a whole-module candidate.

## 3f. Kit revision and the pairing rule

```sh
grep -n 'Kit.VERSION' <scratch>/testkit/framework.lua PrettyChat/tests/_kit/framework.lua
```

Both read `Kit.VERSION = 17`. A consumer on LibKa0s v1.9.0 or newer must take kit revision 11 or later
in the same commit as the library. Before revision 11, `vendor_sync.lua` listed only one directory
level and normalized line endings on everything, so it read `media` as a file. Both payloads are copied
whole in one commit here, so the rule holds by construction, even though the kit bytes do not change
this time.

## Baseline before the copy

```sh
lua tests/run.lua                                             # 339 passed, 0 failed, 0 skipped, 339 total
luacheck .                                                    # 0 warnings / 0 errors in 44 files
lizard -l lua -x "./libs/*" -x "./tests/_kit/*" -C 15 -w .    # 1 warning: core/Database.lua:65 RunMigrations CCN 16
```

The lizard warning predates this run. `cbf9775` ("Database: the load pass drops stored keys that have
no schema row"), earlier on this branch, introduced it; `core/Database.lua` at `cbf9775^` is clean
under `-C 15`. The rollout's gate requires `-C 15` to be clean, so it is fixed in its own commit and is
not part of the re-vendor.

`.luacheckrc` excludes only `libs/`, `GlobalStrings/`, `tests/_kit/`, `docs/audits` and `docs/reviews`.
That leaves every seam file and `tests/wow_mock.lua` in the checked set.

## Verdict

The delta is not empty. The tag moves from v1.31.0 to v1.32.0, two library files change (`Options.lua`
minor 16 and `Slash.lua` minor 8, the optional `bulkBegin` / `bulkEnd` bracket), and the kit stays at
revision 17. The copy goes ahead.
