# 01 — Delta: PrettyChat vs LibKa0s v1.30.0

Run date: 2026-09-12. Library checkout: `../LibKa0s`, working tree clean, on branch
`fix/kit-27-30` (not yet merged to `master`). The payload is taken from the annotated tag, not
from that branch's working tree.

Resolved tag: `git -C ../LibKa0s tag --sort=-v:refname | head -1` gives **v1.30.0** (commit
`e369e0f`). The payload was extracted from the tag:
`git -C ../LibKa0s archive v1.30.0 LibKa0s testkit | tar -x -C <scratch>/`.

## 3a. Claimed version

```sh
grep -n '[Bb]undles' PrettyChat/CLAUDE.md
```

`CLAUDE.md:34`: "Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.29.0 (MIT)."

## 3b. Actual version: the vendored minors

```sh
grep -hoE 'local (MAJOR, )?(MINOR|WIDGETS_MINOR|SCROLL_MINOR|PANEL_MINOR) *= *("[^"]+", *)?[0-9]+' PrettyChat/libs/LibKa0s/*.lua
grep -nE '^local [A-Z_]*MINOR' PrettyChat/libs/LibKa0s/OptionsCompose.lua   # COMPOSE_MINOR
```

The claim and the bytes agree: every vendored minor is the one v1.29.0 shipped.

## 3c. Per-file minor delta

The file list is read from the tag's `LibKa0s/LibKa0s.xml` (14 files), not from the spec's table.
That list includes `OptionsCompose.lua`, whose constant is `COMPOSE_MINOR`.

| File | Constant | Vendored (v1.29.0) | v1.30.0 | Delta |
|---|---|---|---|---|
| `Core.lua` | `MINOR` | 7 | 7 | none |
| `Env.lua` | `MINOR` | 1 | 1 | none |
| `Pool.lua` | `MINOR` | 3 | 3 | none |
| `Item.lua` | `MINOR` | 1 | 1 | none |
| `Media.lua` | `MINOR` | 3 | 3 | none |
| `Widgets.lua` | `MINOR` | 9 | 9 | none |
| `DebugLog.lua` | `MINOR` | 12 | 12 | none |
| `Slash.lua` | `MINOR` | 7 | 7 | none |
| `Options.lua` | `MINOR` | 15 | 15 | none |
| `OptionsWidgets.lua` | `WIDGETS_MINOR` | 14 | 14 | none |
| `OptionsCompose.lua` | `COMPOSE_MINOR` | 3 | 3 | none |
| `OptionsScroll.lua` | `SCROLL_MINOR` | 3 | 3 | none |
| `Perf.lua` | `MINOR` | 10 | 10 | none |
| `PerfPanel.lua` | `PANEL_MINOR` | 5 | 5 | none |

**No cross-major skew.** The v1.30.0 changelog says it in its own words: "No file in `LibKa0s/`
moved, so every minor above is the one v1.29.0 shipped." The whole release is kit revision 16.

## 3d. Both diffs, both directions (before the copy)

```sh
diff -r --strip-trailing-cr <scratch>/LibKa0s PrettyChat/libs/LibKa0s   # 0 lines
diff -rq                    <scratch>/LibKa0s PrettyChat/libs/LibKa0s   # 0 lines
diff -r --strip-trailing-cr <scratch>/testkit PrettyChat/tests/_kit     # content differs
diff -rq                    <scratch>/testkit PrettyChat/tests/_kit     # 4 files differ
```

- Library payload: content clean and bytes clean. Nothing to copy there, and the copy will not
  change it.
- Test kit: **content dirty**, which is the real delta. Four files differ: `README.md`,
  `framework.lua` (`Kit.VERSION` 15 to 16), `mock_base.lua` (`AceGUI:Release`, the AceEvent event
  half on an embed, `Printf` beside `Print`) and `vendor_sync.lua` (the runner-mode case). No
  `Only in` line on either side, so no file removed upstream survives here.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' PrettyChat --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
```

- `core/CoreSetup.lua:41`: Core
- `core/DebugLogSetup.lua:39`: DebugLog
- `core/EnvSetup.lua:59`: Env
- `core/MediaSetup.lua:42`: Media
- `settings/OptionsSetup.lua:17`: Options
- `settings/Schema.lua:405`: Slash
- `settings/Slash.lua:74`: Slash

Majors in the payload with no lookup in this addon: `Item`, `Pool`, `Widgets`, `Perf`. `Perf` is
declined by the `performance-§12` row in `docs/ARCHITECTURE.md` → `## Documented deviations`. None
of the four moved in this release, so none is raised as a whole-module candidate.

## 3f. Kit revision and the pairing rule

```sh
grep -n 'Kit.VERSION' <scratch>/testkit/framework.lua PrettyChat/tests/_kit/framework.lua
```

The tag reads `Kit.VERSION = 16`; the vendored copy reads `15`. A consumer on LibKa0s v1.9.0 or
newer must take kit revision 11 or later in the same commit as the library, because
`vendor_sync.lua` before revision 11 listed one directory level and normalized line endings on
everything, so it read `media` as a file. Both payloads are copied whole in one commit, so the rule
holds by construction. That rule is why the two payloads move together.

The runner is already recorded executable, so the new `vendor_sync.lua` case (#28) passes here on
its default path:

```sh
git -C PrettyChat ls-files -s tests/_kit/run-automated-tests.sh
# 100755 f6cd8b0a86aaf87d394e9ebaf0decf9e13c4e10c 0	tests/_kit/run-automated-tests.sh
```

## Verdict

The delta is not empty: the tag moved v1.29.0 to v1.30.0, the library bytes are identical, and the
kit moves from revision 15 to 16. The copy goes ahead.
