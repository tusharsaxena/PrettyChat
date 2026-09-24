Delta: LibKa0s v1.56.0 -> v1.57.0

# 01 — Delta

Run: 2026-09-24, plan item M5-PC of the 2026-09-23 review and standards-audit remediation (milestone
M5, the always-on launcher status tooltip), written by hand by a workflow subagent in the shape the
RV-PC bundle (`docs/revendor/2026-09-23-v1.56.0/`) used. Steps 0 and 2 to 4 are taken here. Steps 5
to 7 are replaced by the M5 plan row itself: the one adoption this release owes (`launcher-§1`, the
tooltip's descriptor fields) is decided by the plan, not by an interview, and lands as the second
`M5-PC:` commit. Target: this repo, branch `feat/2026-09-23-review-audit-remediation` at `e40f1f7`.
No push.

Source: the sibling checkout `../LibKa0s`, **tag `v1.57.0` (tag object `d03e836` -> commit
`aa37bc9`)**, the newest tag (`git -C ../LibKa0s tag --sort=-v:refname | head -1`). Extracted with
`git -C ../LibKa0s archive v1.57.0 LibKa0s testkit | tar -x -C <scratch>/`, never from the working
tree (`git -C ../LibKa0s status --short | wc -l` -> `0`), and never checked out there. The tag is
local and not pushed; `tests/test_vendor_sync.lua` compares against the tag the provenance line
names, so the local tag is enough.

```
git -C ../LibKa0s log --oneline v1.56.0..v1.57.0
  aa37bc9 LK-36: record the v1.57.0 release run, its ANALYSIS.md and gate line
  281f26f LK-36: Launcher minor 3 — the library always draws the status tooltip
```

## Step 0 — Pre-flight on this addon's newest bundle

Newest single-tag bundle: `docs/revendor/2026-09-23-v1.56.0/`. Its line 1 names base `v1.55.0`, and
the commit that vendored v1.56.0 is `18b3e2e` (RV-PC), whose parent's `CLAUDE.md` names v1.55.0.
**ok**, no base correction is owed.

## 3a — Claimed version, and the delta base

`grep -n '[Bb]undles' CLAUDE.md` -> `CLAUDE.md:42`: Bundles
[LibKa0s](https://github.com/tusharsaxena/LibKa0s) **v1.56.0** (MIT), before the copy.

Cross-check: the payload before the copy matched the v1.56.0 tag exactly: `diff -rq <v1.56.0>/LibKa0s
libs/LibKa0s && diff -rq <v1.56.0>/testkit tests/_kit` printed `payload-matches-v1.56.0`. **Base:
v1.56.0.**

## 3b — Actual version, before the copy

The v1.56.0 minors (01_DELTA.md 3c of the v1.56.0 bundle). Kit revision 26 (`grep -n 'Kit.VERSION'
tests/_kit/framework.lua` -> `:20`).

## 3c — Per-file minor delta

One file moves. The tag's `LibKa0s/LibKa0s.xml` is unchanged (21 `<Script>` rows).

| File | Constant | v1.56.0 | v1.57.0 |
|---|---|---|---|
| `Launcher.lua` | `MINOR` | 2 | **3** |

Every other file is byte-identical: Core 8, Env 1, Compat 1, Lifecycle 2, Bus 2, Schema 2, Pool 3,
Item 2, Media 4, Widgets 10, WidgetsDragHandle 2, DebugLog 13, Slash 15, Options 24 (key
24.31.4.7.4), Perf 13, PerfPanel 5. No file is new and none is removed, so there is **no cross-major
skew**. No `NEEDS_*` floor rises (library CHANGELOG, v1.57.0).

## 3d — Both diffs

Before the copy:

```
diff -rq --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s   -> Launcher.lua differs (one line)
diff -rq <scratch>/LibKa0s libs/LibKa0s                        -> the same one line (bytes == content)
diff -rq --strip-trailing-cr <scratch>/testkit tests/_kit      -> empty
diff -rq <scratch>/testkit tests/_kit                          -> empty
```

After the copy (`rm -rf` both folders, then `cp -r` from the extracted tag), `diff -r
<scratch>/LibKa0s libs/LibKa0s` and `diff -r <scratch>/testkit tests/_kit` both print nothing, and
`test -x tests/_kit/run-automated-tests.sh` holds. The kit is copied whole although it did not move,
because the two payloads always travel together.

## 3e — Consumption map

Unchanged from the v1.56.0 bundle: nine majors consumed (Core, Env, Media, DebugLog, Launcher at
`core/LauncherSetup.lua:92`, Lifecycle, Options, Slash, Schema). The one major that moved, Launcher,
is consumed.

## 3f — Kit revision, and the pairing rule

**26** at the tag and **26** vendored: the kit did not move. Both payloads are copied whole in one
commit, so the pairing rule holds by construction.

## 3g — Contract delta

| Major | Old -> new document | What moved |
|---|---|---|
| Launcher | `Launcher/version-2-docs.md:15` -> version 3 | the library always sets the LDB object's `OnTooltipShow` and draws the status tooltip, enabled or disabled; new optional `version`, `isLocked`, `isTestMode`, `leftClickLabel`, `slash`; `onTooltipShow` now appends between the status block and the click hints instead of being the whole tooltip; fourteen `TOOLTIP_*` strings |

**Bound to what this addon hands over.** At `e40f1f7` the descriptor in `core/LauncherSetup.lua`
passes `name`, `label`, `icon`, `minimap`, `openSettings`, `print` and `debug`; no `onClick`, no
`isEnabled`, no `onTooltipShow`. So nothing this addon passes changes meaning: the hover simply
starts drawing the library's tooltip. Without adoption it would read `Enabled: Yes` even while the
addon is disabled (a host with no `isEnabled` is always Yes) and show no version. Both are owed by
`launcher-§1` and are the second `M5-PC:` commit.

### Blockers

**None.** `ka0s-bounded lua5.1 tests/run.lua` straight after the copy, with no other edit: **481
passed, 0 failed, 0 skipped, 481 total**. No existing case called the object's `OnTooltipShow`.
Lint 0/0 in 48 files.

## 3h — Tags this addon vendored and never recorded

None. Every tag up to v1.56.0 is recorded (the span bundle `docs/revendor/2026-09-24-v1.16.0-v1.54.2/`
and the single-tag bundles), and v1.57.0 is recorded by this bundle.
