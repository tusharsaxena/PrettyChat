Delta: LibKa0s v1.57.0 -> v1.58.0

# 01 — Delta

Run: 2026-09-25, plan item M6-PC of the 2026-09-23 review and standards-audit remediation (milestone
M6, the launcher's left-click settings and right-click options menu), written by hand by a workflow
subagent in the shape the M5-PC bundle (`docs/revendor/2026-09-24-v1.57.0/`) used. Steps 0 and 2 to 4
are taken here. Steps 5 to 7 are replaced by the M6 plan row itself: the one adoption this release
owes (`launcher-§2`, the menu's accessor-and-toggle pairs) is decided by the plan, not by an
interview, and lands as the second `M6-PC:` commit. Target: this repo, branch
`feat/2026-09-23-review-audit-remediation` at `eb3f9e2`. No push.

Source: the sibling checkout `../LibKa0s`, **tag `v1.58.0` (tag object `93cf3ad` -> commit
`34931c9`)**, the newest tag. Extracted with `git -C ../LibKa0s archive v1.58.0 LibKa0s testkit |
tar -x -C <scratch>/`, never from the working tree (`git -C ../LibKa0s status --short | wc -l` ->
`0`), and never checked out there. The tag is local and not pushed; `tests/test_vendor_sync.lua`
compares against the tag the provenance line names, so the local tag is enough.

```
git -C ../LibKa0s log --oneline v1.57.0..v1.58.0
  34931c9 LK-37: record the v1.58.0 release run, its ANALYSIS.md and gate line
  02999d0 LK-37: Launcher minor 4 — left-click settings, right-click options menu
```

## Step 0 — Pre-flight on this addon's newest bundle

Newest single-tag bundle: `docs/revendor/2026-09-24-v1.57.0/`. Its line 1 names base `v1.56.0`, and
the commit that vendored v1.57.0 is `e7829c7` (M5-PC), whose parent's `CLAUDE.md` names v1.56.0.
**ok**, no base correction is owed.

## 3a — Claimed version, and the delta base

`CLAUDE.md`'s provenance line named **v1.57.0** before the copy. Cross-check: the payload before the
copy differed from the v1.58.0 tag in `LibKa0s/Launcher.lua` only, and `tests/_kit` not at all, which
is the v1.57.0 payload. **Base: v1.57.0.**

## 3b — Actual version, before the copy

The v1.57.0 minors (01_DELTA.md 3c of the v1.57.0 bundle). Kit revision 26 (`grep -n 'Kit.VERSION'
tests/_kit/framework.lua` -> `:20`).

## 3c — Per-file minor delta

One file moves. The tag's `LibKa0s/LibKa0s.xml` is unchanged.

| File | Constant | v1.57.0 | v1.58.0 |
|---|---|---|---|
| `Launcher.lua` | `MINOR` | 3 | **4** |

Every other file is byte-identical: Core 8, Env 1, Compat 1, Lifecycle 2, Bus 2, Schema 2, Pool 3,
Item 2, Media 4, Widgets 10, WidgetsDragHandle 2, DebugLog 13, Slash 15, Options 24, Perf 13,
PerfPanel 5. No file is new and none is removed, so there is **no cross-major skew**. No `NEEDS_*`
floor rises.

## 3d — Both diffs

Before the copy:

```
diff -rq --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s   -> Launcher.lua differs
diff -rq <scratch>/LibKa0s libs/LibKa0s                        -> the same one file (bytes == content)
diff -rq --strip-trailing-cr <scratch>/testkit tests/_kit      -> empty
diff -rq <scratch>/testkit tests/_kit                          -> empty
```

After the copy (`rm -rf` both folders, then `cp -r` from the extracted tag), `diff -r
<scratch>/LibKa0s libs/LibKa0s` and `diff -r <scratch>/testkit tests/_kit` both print nothing, and
`test -x tests/_kit/run-automated-tests.sh` holds. The kit is copied whole although it did not move,
because the two payloads always travel together.

## 3e — Consumption map

Unchanged from the v1.57.0 bundle: nine majors consumed (Core, Env, Media, DebugLog, Launcher in
`core/LauncherSetup.lua`, Lifecycle, Options, Slash, Schema). The one major that moved, Launcher, is
consumed.

## 3f — Kit revision, and the pairing rule

**26** at the tag and **26** vendored: the kit did not move. Both payloads are copied whole in one
commit, so the pairing rule holds by construction.

## 3g — Contract delta

| Major | Old -> new document | What moved |
|---|---|---|
| Launcher | `Launcher/version-3-docs.md` -> version 4 | left-click always calls `openSettings`; right-click opens the client's context menu (`MenuUtil.CreateContextMenu`) built from the accessor-and-toggle pairs `isEnabled`+`setEnabled`, `isLocked`+`toggleLock`, `isTestMode`+`toggleTestMode`, `isWindowShown`+`toggleWindow`, gated entries grayed while disabled; with no pair (or no `MenuUtil`) right-click still opens the panel; `onClick`, `leftClickLabel`, `disabledLine` and `slash` retired (ignored if passed); the tooltip hints are fixed at `Left-click: Open settings` / `Right-click: Options menu` |

**Bound to what this addon hands over.** At `eb3f9e2` the descriptor passes `name`, `label`, `icon`,
`minimap`, `openSettings`, `print`, `debug`, `version`, `isEnabled` and `disabledLine`; no `onClick`.
So the click behavior does not move on the copy alone: left opens the panel (it did, rung (c)), and
right still opens the panel because no `setEnabled` is passed yet. `disabledLine` becomes dead
configuration (it served only the retired refusal). The one visible change is the tooltip's second
hint, `Right-click: Options menu`, which on this descriptor is not yet true: that is closed by the
adoption commit.

### Blockers

**One contract change under a signature that did not move**: the tooltip's right-click hint. Two
cases in `tests/test_launcher.lua` pinned minor 3's `Right-click: Open settings`, and went red on the
copy (484 / 486). They are re-pinned to `Right-click: Options menu` in the same commit as the copy,
as the version-4 doc's Compatibility section says a consumer does. After that: **486 passed, 0
failed**. Lint 0/0 in 48 files.

## 3h — Tags this addon vendored and never recorded

None. v1.58.0 is recorded by this bundle.
