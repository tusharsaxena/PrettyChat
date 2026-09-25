Delta: LibKa0s v1.58.0 -> v1.60.0

# 01 — Delta

Run: 2026-09-26, plan item DR-PC-01 of the 2026-09-25 diagnostics rollout
(`Ka0sAddonsCommonTasks/docs/2026-09-25-DIAGNOSTICS_COMMAND/`, milestone M3), through
`/wow-addon:revendor-libka0s --tag v1.60.0`. Target: this repo, branch
`feat/2026-09-25-diagnostics-rollout`, cut from `master` at `1edc320`. No push.

Source: the sibling checkout `../LibKa0s`, **tag `v1.60.0` (tag object `ac59511` -> commit
`bed0eb1`)**, the newest tag. Extracted with `git -C ../LibKa0s archive v1.60.0 LibKa0s testkit |
tar -x -C <scratch>/`, never from the working tree (`git -C ../LibKa0s status --short | wc -l` ->
`0`).

This one re-vendor spans two releases. v1.59.0 (tag object `080ee07` -> commit `53c141a`) was never
vendored here, because the rollout plan skips it: it carries neither the buffer change nor the
diagnostics helper, so taking it first would mean a second re-vendor. It is recorded by this bundle.

```
git -C ../LibKa0s log --oneline v1.58.0..v1.60.0
  bed0eb1 DR-LK-06: record the v1.60.0 release run, its ANALYSIS.md and gate line
  2fdca6e DR-LK-06: date v1.60.0 and roll the release pointers
  db0c54a Merge feat/2026-09-25-diagnostics-rollout: v1.60.0 (unreleased) - DebugLog 14.1 ...
  c01db86 Merge feat/2026-09-25-draghandle-close: DragHandle close mark (Widgets 10.3, ...), v1.59.0
  db21a1c DR-LK-05R ... 0e80b4c DR-LK-02 ... 747ecfc DR-LK-03 ... 43f062c DR-LK-04 ... 58e3794 DR-LK-01
  53c141a B8-P8: record the v1.59.0 release run, its ANALYSIS.md and gate line
  e8faa5d B8-P8: WidgetsDragHandle minor 3 - an opt-in close mark beside the help mark
```

## 3a — Claimed version

`grep -n -i 'bundles' CLAUDE.md` -> `42: Bundles [LibKa0s](...) v1.58.0 (MIT).`

## 3b — Actual version, before the copy

`grep -hoE 'local (MAJOR, )?([A-Z_]*MINOR) *= *...' libs/LibKa0s/*.lua` gives the v1.58.0 minors
(DebugLog 13, Slash 15, WidgetsDragHandle 2, every other file as below), and
`grep -n 'Kit.VERSION' tests/_kit/framework.lua` -> `:20 Kit.VERSION = 26`. Line and bytes agree:
**base v1.58.0**.

## 3c — Per-file minor delta

The tag's `LibKa0s/LibKa0s.xml` adds one file, `DebugLogDiagnostics.lua`, after `DebugLog.lua`.

| File | Constant | v1.58.0 | v1.60.0 |
|---|---|---|---|
| `DebugLog.lua` | `MINOR` | 13 | **14** |
| `DebugLogDiagnostics.lua` (new, second file of DebugLog) | `DIAG_MINOR` | — | **1** |
| `Slash.lua` | `MINOR` | 15 | **16** |
| `WidgetsDragHandle.lua` | `DRAG_MINOR` | 2 | **3** (v1.59.0) |

Unchanged: Core 8, Env 1, Compat 1, Lifecycle 2, Bus 2, Schema 2, Pool 3, Item 2, Media 4,
Widgets 10, Launcher 4, Options 24 (Widgets 31, Tabs 4, Compose 7, Scroll 4), Perf 13, PerfPanel 5.
No file is removed and no `NEEDS_*` floor rises, so there is **no cross-major skew**.

## 3d — Both diffs, before the copy

```
diff -rq --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s
  DebugLog.lua, LibKa0s.xml, Slash.lua, WidgetsDragHandle.lua differ; Only in <scratch>: DebugLogDiagnostics.lua
diff -rq <scratch>/LibKa0s libs/LibKa0s              -> the same list (bytes == content)
diff -rq --strip-trailing-cr <scratch>/testkit tests/_kit
  README.md, framework.lua differ; Only in <scratch>: test_diagnostics_contract.lua
diff -rq <scratch>/testkit tests/_kit                -> the same list
```

Content-dirty only where the tag moved; no line-ending drift; nothing `Only in` this repo.

## 3e — Consumption map

`grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua'` outside `libs/` and
`tests/`: Core (`core/CoreSetup.lua`), Env, Media, DebugLog (`core/DebugLogSetup.lua`,
`settings/Panel.lua`), Launcher, Lifecycle, Options (`settings/OptionsSetup.lua`), Slash
(`settings/Slash.lua`, `settings/Schema.lua`), Schema. Nine majors, as at v1.58.0.

Of the three that moved, **DebugLog** and **Slash** are consumed. **Widgets** (and its
`WidgetsDragHandle` file) is not looked up by this addon at all: it has no drag handle, so the
v1.59.0 close mark does not reach it.

## 3f — Kit revision, and the pairing rule

**26 -> 27** (`Kit.VERSION` at `testkit/framework.lua:20`). The kit gains its fourth own suite,
`test_diagnostics_contract.lua`. Both payloads move in one commit, so the pairing rule holds by
construction.

## 3g — Contract delta

| Major | Old -> new document | What moved |
|---|---|---|
| DebugLog | `DebugLog/version-13-docs.md` -> `version-14.1-docs.md` | Additive: `TIME_COPY`, `BUFFER_SLACK`, `DIAG_MAX_LINES`, `DIAG_MAX_PER_LIST`, `RunDiagnostics`, `BuildDiagnostics`, `DebugVerb`, descriptor `brandName` and `diagnostics`. **One existing behavior moves**: `MAX_BUFFER` 1500 -> 3000, `BUFFER_SLACK` 64 -> 128 (`version-14.1-docs.md:463`, `:504`, Compatibility `:605-620`). |
| Slash | `Slash/version-15-docs.md` -> `version-16-docs.md` | `lib.LIVE_VERBS` gains `diagnostics` after `perf` (`version-16-docs.md:39-61`). No member or descriptor field moves. |

**Bound to what this addon hands over.** No `__Attach*` site exists outside `libs/`. The DebugLog
descriptor (`core/DebugLogSetup.lua`) passes no `brandName` and no `diagnostics` yet, so nothing it
supplies is called at a new time. The Slash descriptor (`settings/Slash.lua`) passes **no
`liveVerbs`**, so it inherits `diagnostics` in its live set on the copy; the addon does not register
the verb yet, so until DR-PC-03 `/pc diagnostics` is `unknown command` in either state
(`version-16-docs.md`, "a host that has not registered `diagnostics` yet").

### Blockers

No host member changes meaning. What the copy turns red is test and stub churn, which the
library's own "What a consumer owes on re-vendoring v1.60.0" (`CHANGELOG.md`, v1.60.0 block) lists,
and which rides in the copy commit so it is green on its own:

1. **Surface parity.** `tests/test_surface_parity.lua` ("the DebugLog stub carries the whole live
   surface") goes red until the library-absent stub in `core/DebugLogSetup.lua` gains
   `RunDiagnostics`, `BuildDiagnostics` and `DebugVerb` (`version-14.1-docs.md:615-619`).
2. **The kit's new suite.** `Kit.assertSuiteInventory` fails the run until `tests/run.lua` declares
   `{ name = "test_diagnostics_contract", dir = "tests/_kit/" }`. With `Kit.diagnostics` unset it
   is one declared skip.
3. **The buffer.** `tests/test_debuglog.lua:184-212` writes 1520 lines and pins `1500` and
   `"1 / 1500 lines"`; `tests/test_libka0s.lua:204` pins `"/ 1500 lines"`. Re-pinned on
   `lib.MAX_BUFFER`.
4. **The live set.** `tests/test_disabled.lua:272-276` copies the reserved verbs as a literal; it
   gains `diagnostics` so it stays the standard's thirteen.
5. **A wrong comment.** `settings/Slash.lua`'s descriptor comment says `liveVerbs` *widens* the live
   set. It replaces it (`version-16-docs.md:590`: "a host MAY narrow it"); the comment is corrected.

## 3h — Tags this addon vendored and never recorded

None. v1.59.0 was skipped rather than vendored, and is recorded here.
