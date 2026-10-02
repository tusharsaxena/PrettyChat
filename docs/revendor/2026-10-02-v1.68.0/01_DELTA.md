Delta: LibKa0s v1.67.0 -> v1.68.0

# LibKa0s v1.67.0 -> v1.68.0: the delta (PrettyChat)

Item TP-PC-01 of the 2026-10-02 LibKa0s tooltip-place re-vendor (Ka0sAddonsCommonTasks
`docs/2026-10-02-LIBKA0S_TOOLTIP_PLACE/00_PLAN.md`). Copied from the **local** annotated tag `v1.68.0`
(LibKa0s commit `cc9f5eb`) by `git -C ../LibKa0s archive v1.68.0 LibKa0s testkit | tar -x`. The
sibling checkout's `HEAD` is the tag commit and `git -C ../LibKa0s diff --quiet v1.68.0 -- LibKa0s
testkit` is clean, so the archive and the working tree carry the same bytes.

## Step 0 / 3a. The base

```sh
grep -n '[Bb]undles' CLAUDE.md
# 42:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.67.0 (MIT).
git log -1 --format='%h %s' -- libs/LibKa0s tests/_kit
# 19b37be CA-PC-RV: re-vendor LibKa0s v1.67.0 (Core 10, Options 28, OptionsIdList 3; kit revision 35)
git show 19b37be:CLAUDE.md | grep -oE 'Bundles \[LibKa0s\]\([^)]*\) v[0-9.]+'   # ... v1.67.0
git log --format='%h %s' 19b37be..HEAD -- CLAUDE.md                              # (none)
diff -rq <v1.67.0>/LibKa0s libs/LibKa0s && diff -rq <v1.67.0>/testkit tests/_kit && echo payload-matches
# payload-matches
```

The provenance line, the last payload commit and the payload agree: the base is **v1.67.0**.
Step 0 for this addon: the newest single-tag bundle, `2026-10-02-v1.67.0/`, states base v1.66.0 on
line 1, and the provenance line at `19b37be^` is v1.66.0. No base correction is owed.

```sh
git -C ../LibKa0s log --oneline v1.67.0..v1.68.0
# cc9f5eb DA-LK-07R ... ee9dcfe DA-LK-05 ... 2cc8a03 DA-LK-01: WidgetsDragHandle minor 4 - tooltipPlace ...
# (8 DA-LK-* commits; the only payload change is 2cc8a03's LibKa0s/WidgetsDragHandle.lua)
git -C ../LibKa0s diff --stat v1.67.0 v1.68.0 -- LibKa0s testkit
# LibKa0s/WidgetsDragHandle.lua | 84 +++-  (testkit: nothing)
```

## 3b. Claimed against actual

Before the copy, `diff -rq` of the addon's payload against the v1.67.0 tree is empty (above), so every
vendored minor is v1.67.0's. No skew.

## 3c. Per-file minors (the tag's `LibKa0s.xml`, in load order)

The step's loop over the tag's XML prints exactly one moved constant:

| File | old | new |
|---|---|---|
| WidgetsDragHandle.lua | DRAG 3 | **DRAG 4** |
| every other file (31) | as v1.67.0 | unchanged |

`LibKa0s-Widgets-1.0` key 12.1.3 -> **12.1.4**. No file added or removed (32 payload files), no
`NEEDS_*` floor rises, the TOC is unchanged.

## 3d. Both diffs, before the copy

`diff -rq --strip-trailing-cr <tag>/LibKa0s libs/LibKa0s` and the byte diff both name only
`WidgetsDragHandle.lua`. Nothing only in the tag, nothing only in the addon, so the copy deletes
nothing. `diff -rq` of `<tag>/testkit` against `tests/_kit`, with and without
`--strip-trailing-cr`: empty. The kit did not move.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '^\./libs/' | grep -v '^\./tests/'
```

Core (`core/CoreSetup.lua:41`), Env (`core/EnvSetup.lua:60`), Media (`core/MediaSetup.lua:42`),
Lifecycle (`core/LifecycleSetup.lua:67`), DebugLog (`core/DebugLogSetup.lua:69`,
`settings/Panel.lua:84`), Launcher (`core/LauncherSetup.lua:98`), Slash (`settings/Slash.lua:158`,
`settings/Schema.lua:911`), Schema (`settings/Schema.lua:802`), Options
(`settings/OptionsSetup.lua:17`). Unchanged from v1.67.0. **PrettyChat looks up no
`LibKa0s-Widgets-1.0`**, and nothing in `core/`, `settings/` or `modules/` names `DragHandle`,
`tooltipPlace` or `tooltipOwner`. Widgets reaches this addon only inside the library (DebugLog's
copy window, `libs/LibKa0s/DebugLog.lua:33`), which uses `CopyWindow`, not `DragHandle`.

## 3f. Kit revision

`Kit.VERSION` stays **35** (`tests/_kit/framework.lua:20`); the testkit tree is byte-identical
between the two tags. The revision-11 pairing rule holds: both payloads come from the one tag in this
commit.

## 3g. Contract delta

Moved majors (3c: Widgets) intersected with consumed majors (3e: no Widgets lookup) is **empty**, so
no host contract can have moved under this addon. Read anyway, for the record:
`docs/api/Widgets/version-12.1.4-docs.md:46`-`:48` ("Without a hook nothing changes ... What a host
must change: nothing"). The code diff confirms it: without `tooltipPlace` / `place`,
`dhShowTooltip` makes minor 3's calls in minor 3's order. `grep -rn '__Attach' core settings modules`
is empty, so no host-supplied member exists to have had its call site moved.

**Blockers:** none.

## 3h. Tags vendored and never recorded

The step's listing (vendored tags since the store's horizon, minus recorded ones) prints nothing:
every vendored tag is recorded, v1.67.0 in `2026-10-02-v1.67.0/`. No span bundle is owed.
