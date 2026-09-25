Delta: LibKa0s v1.55.0 -> v1.56.0

# 01 — Delta

Run: 2026-09-24, plan item RV-PC of the 2026-09-23 review and standards-audit remediation, written by
hand by a workflow subagent. It follows the local `../wow-addon/commands/revendor-libka0s.md` as
amended by WA-01 (`d4b5950`, `aa0d7d5`). The installed plugin does not carry WA-01 yet, so the command
itself was not run. Steps 0 and 2 to 4 are taken here. Steps 5 to 7 (candidates, interview, adoption)
are **not**: every adoption decision is one of this addon's M3 plan items (PC-01 to PC-25). The folder
is dated for the plan (2026-09-23), as the plan names it. Target: this repo, branch
`feat/2026-09-23-review-audit-remediation` at `e561b79`. No push.

Source: the sibling checkout `../LibKa0s`, **tag `v1.56.0` (tag object `4622018` -> commit
`514fc0a`)**. The tag was resolved with `git -C ../LibKa0s tag --sort=-v:refname | head -1` and
extracted with `git -C ../LibKa0s archive v1.56.0 LibKa0s testkit | tar -x -C <scratch>/`, never from
the working tree (`git -C ../LibKa0s status --short | wc -l` -> `0`). The tag is local and not yet
pushed. `tests/test_vendor_sync.lua` compares against the tag the provenance line names, so the local
tag is enough.

```
git -C ../LibKa0s log --oneline v1.55.0..v1.56.0 | wc -l      -> 54
git -C ../LibKa0s log --oneline v1.55.0..v1.56.0 | head -4
  514fc0a LK-34: Retire the provisional options-ui-§9 row; cite the v2.65.0 ruling
  a77211f LK-33: address review — re-rule test_slash.lua's band cell, align the options-ui-§9 trigger
  446b7c1 LK-33: record the v1.56.0 release run, its ANALYSIS.md and dispositions
  326494e LK-33: date v1.56.0, name what a consumer owes, roll release pointers
  ... LK-01 to LK-32 below them, then ab6404d / 46ccaa6 (the review record and the sweep merge)
```

## Step 0 — Pre-flight on this addon's newest bundle

Newest single-tag bundle: `docs/revendor/2026-09-23-v1.55.0/`. Its line 1 names base `v1.54.2`. The
commit that vendored v1.55.0 is `365e3be`, and `git show 365e3be^:CLAUDE.md | grep -oE 'Bundles
\[LibKa0s\]\([^)]*\) v[0-9.]+[0-9]'` gives `v1.54.2`. **ok**, so no base correction is owed.

That bundle's line 1 is a heading, `# 01 — Delta: LibKa0s v1.54.2 → v1.55.0`, not the bare form WA-01
now fixes. The audit reads the tags off it all the same, and a frozen bundle is never rewritten, so
it stays as written.

## 3a — Claimed version, and the delta base

`grep -n '[Bb]undles' CLAUDE.md` -> `CLAUDE.md:42`: Bundles
[LibKa0s](https://github.com/tusharsaxena/LibKa0s) **v1.55.0** (MIT).

Cross-check: `git log -1 --format=%h -- libs/LibKa0s tests/_kit` -> `365e3be`, whose `CLAUDE.md`
names v1.55.0. The two answers agree. The payload before the copy also matched the v1.55.0 tag
exactly: `diff -rq <v1.55.0>/LibKa0s libs/LibKa0s && diff -rq <v1.55.0>/testkit tests/_kit` printed
`payload-matches`. **Base: v1.55.0.**

## 3b — Actual version, before the copy

`grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR *= *("[^"]+", *)?[0-9]+' libs/LibKa0s/*.lua`: the v1.55.0
block in the old column of 3c. Kit revision 25 (`grep -n 'Kit.VERSION' tests/_kit/framework.lua` ->
`:20`). The line and the bytes agreed.

## 3c — Per-file minor delta

The file list comes from the tag's `LibKa0s/LibKa0s.xml` (21 `<Script>` rows, unchanged from
v1.55.0). The minors come from the 3b grep over the vendored copy (old) and the extracted tag (new).

| File | Constant | v1.55.0 | v1.56.0 |
|---|---|---|---|
| `Core.lua` | `MINOR` | 7 | **8** |
| `Env.lua` | `MINOR` | 1 | 1 |
| `Compat.lua` | `MINOR` | 1 | 1 |
| `Lifecycle.lua` | `MINOR` | 1 | **2** |
| `Bus.lua` | `MINOR` | 1 | **2** |
| `Schema.lua` | `MINOR` | 1 | **2** |
| `Pool.lua` | `MINOR` | 3 | 3 |
| `Item.lua` | `MINOR` | 1 | **2** |
| `Media.lua` | `MINOR` | 3 | **4** |
| `Widgets.lua` | `MINOR` | 9 | **10** |
| `WidgetsDragHandle.lua` | `DRAG_MINOR` | 2 | 2 |
| `DebugLog.lua` | `MINOR` | 12 | **13** |
| `Slash.lua` | `MINOR` | 14 | **15** |
| `Launcher.lua` | `MINOR` | 1 | **2** |
| `Options.lua` | `MINOR` | 23 | **24** |
| `OptionsWidgets.lua` | `WIDGETS_MINOR` | 30 | **31** |
| `OptionsTabs.lua` | `TABS_MINOR` | 3 | **4** |
| `OptionsCompose.lua` | `COMPOSE_MINOR` | 7 | 7 |
| `OptionsScroll.lua` | `SCROLL_MINOR` | 3 | **4** |
| `Perf.lua` | `MINOR` | 12 | **13** |
| `PerfPanel.lua` | `PANEL_MINOR` | 5 | 5 |

No file is new and none is removed. Every file moves forward or stays put, so there is **no
cross-major skew** before or after. The library's CHANGELOG says no `NEEDS_*` floor rises.

## 3d — Both diffs

Before the copy:

```
diff -rq --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s   -> 15 "differ" lines: Bus, Core, DebugLog,
    Item, Launcher, Lifecycle, Media, Options, OptionsScroll, OptionsTabs, OptionsWidgets, Perf, Schema,
    Slash, Widgets (.lua). No "Only in" line.
diff -rq <scratch>/LibKa0s libs/LibKa0s                        -> the same 15 lines (bytes == content)
diff -rq --strip-trailing-cr <scratch>/testkit tests/_kit
    README.md, framework.lua, mock_base.lua, mock_record.lua, run-automated-tests.sh, test_eol.lua,
    test_layout_cap.lua, test_prose.lua differ
    Only in <scratch>/testkit: asserts.lua, mock_events.lua, prose_lists.lua
diff -rq <scratch>/testkit tests/_kit                          -> the same 11 lines
```

Content is dirty in both payloads for the expected reason, a newer tag. There is no `Only in
libs/LibKa0s` or `Only in tests/_kit` line, so nothing was removed upstream and nothing is deleted
here. There is no content-clean, bytes-dirty drift.

After the copy (`rm -rf` both folders, then `cp -r` from the extracted tag), `diff -r
<scratch>/LibKa0s libs/LibKa0s` and `diff -r <scratch>/testkit tests/_kit` both print nothing, and
`test -x tests/_kit/run-automated-tests.sh` holds.

## 3e — Consumption map

```
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' core modules settings --include='*.lua'
  core/CoreSetup.lua:41        Core
  core/EnvSetup.lua:59         Env
  core/MediaSetup.lua:42       Media
  core/DebugLogSetup.lua:39    DebugLog
  core/LauncherSetup.lua:92    Launcher
  core/LifecycleSetup.lua:67   Lifecycle
  settings/OptionsSetup.lua:17 Options
  settings/Slash.lua:131       Slash
  settings/Schema.lua:715      Schema  (adopted at e741973)
  settings/Schema.lua:824      Slash   (second Slash site, already known)
```

This addon consumes nine majors. Unadopted in the payload: Perf (declined under the
`performance-§12` register row), Pool, Item and Widgets (reached inside the library only), Compat and
Bus (declined, issues #16 and #17).

## 3f — Kit revision, and the pairing rule

`grep -n 'Kit.VERSION' <scratch>/testkit/framework.lua tests/_kit/framework.lua` -> **26** at the tag,
**25** vendored before the copy. Both payloads are copied whole in one commit, so the pairing rule
(LibKa0s v1.9.0 or newer takes kit revision 11 or newer in the same commit) holds by construction.
That rule is why the two payloads move together.

## 3g — Contract delta

The majors that both moved a minor (3c) and are looked up here (3e): Core, Lifecycle, Schema, Media,
DebugLog, Slash, Launcher and Options. Each old document's `Superseded by` row, read at the tag:

| Major | Old -> new document | What moved |
|---|---|---|
| Core | `Core/version-7-docs.md:15` -> version 8 | `Format` survives a secret in a numeric slot; the `SafeRegisterEvent` family is added |
| Lifecycle | `Lifecycle/version-1-docs.md:15` -> version 2 | documentation and pins only; "the code is unchanged" |
| Schema | `Schema/version-1-docs.md:15` -> version 2 | `SetMany`, `row.normalize`, `writeThrough`; the instance id reaches `row.get` and `ApplyDefault` |
| Media | `Media/version-3-docs.md:15` -> version 4 | `RegisterLSM` flags the face western + ruRU and counts only what LSM holds |
| DebugLog | `DebugLog/version-12-docs.md:15` -> version 13 | the buffer trim is batched at the cap (`version-13-docs.md:14`, `:49`) |
| Slash | `Slash/version-14-docs.md:15` -> version 15 | `CliSet` / `CliReset` print the write seam's refusal (`version-15-docs.md:39-56`) |
| Launcher | `Launcher/version-1-docs.md:15` -> version 2 | optional `isEnabled` / `disabledLine`; the missing-library notice prints once, without the `[LibKa0s] ` prefix |
| Options | `Options/version-23.30.3.7.3-docs.md:16` -> 24.31.4.7.4 | `CreateOptionsPanel` parks in combat and replays at `PLAYER_REGEN_ENABLED`; `OpenOptionsPanel` answers a boolean (`version-24.31.4.7.4-docs.md:33-45`) |

**Bound to what this addon hands over.** `grep -rn '__Attach[A-Za-z]*' . --include='*.lua'
--exclude-dir=libs --exclude-dir=_kit` -> empty, so there is no attach seam. The host-supplied members
that the moved contracts can reach:

- **Schema `row.get(instanceId)`.** Every `get` in `settings/Schema.lua` (`:178`, `:207`, `:231`,
  `:253`, `:357`, `:382`, `:408`) is a zero-argument closure, so the forwarded id is ignored. No
  change.
- **Slash `set`.** `settings/Slash.lua:266` passes `NS.SchemaRuntime.Set` straight through. Under
  minor 15 a refused `/pc set` prints `INVALID` plus the reason from the library, where minor 14
  echoed the old value. That improvement arrives without being asked for, and the existing
  "one chat line, nothing stored" pins stay green. PC-02 pins the echo.
- **Options `CreateOptionsPanel`.** PrettyChat has no park of its own, so nothing needs deleting
  (`options-ui-§9`, standard v2.65.0: a host MUST NOT add its own park).

### Blockers

**None in the library.** No host-supplied member's call site moved in a way that breaks this addon.

**What the stricter kit and library turn red** is recorded as suite reds, not as blockers fixed here.
The RV commit is copy-only: it carries the payload, the provenance line and this bundle, and nothing
else (spec Part B). `ka0s-bounded lua5.1 tests/run.lua` after the copy: **435 passed, 3 failed,
0 skipped, 438 total**. These are exactly the three the library's release dry-run predicted
(`../LibKa0s` `docs/automated-tests/20260924-040553/ANALYSIS.md:216-221`):

1. `tests/test_surface_parity.lua`, *the Schema stub carries the whole live surface, library and
   instance*: `SetMany is missing (live: function)`. Schema minor 2. Cleared by **PC-01**.
2. `tests/test_libka0s.lua:451`, *a settings page shown in combat is covered, not drawn and not
   closed*: `attempt to index field 'Categories' (a nil value)`. Options minor 24 parks the panel
   created under the test's held combat, so the subcategory does not exist until
   `PLAYER_REGEN_ENABLED`. The standard (v2.65.0, `options-ui-§5` / `§9`) keeps the park, so the test
   moves with the contract. No M3 item names it. It is owed by PC-DOCS at the latest (spec Part B).
3. `tests/test_debuglog.lua:187`, *the buffer is capped and drops its oldest lines first*: `expected
   1500, got 1520`. DebugLog minor 13 trims in batches at the cap. The pin moves with the documented
   contract. No M3 item names it either. It is owed by PC-DOCS at the latest.

Lint: `ka0s-bounded luacheck .` -> 0 warnings / 0 errors in 48 files.

## 3h — Tags this addon vendored and never recorded

The 3h listing, run before this commit, with horizon `2026-08-25`, prints **29** tags:

```
v1.16.0 v1.18.0 v1.18.1 v1.19.0 v1.23.0 v1.24.0 v1.25.0 v1.26.0 v1.27.0 v1.28.0 v1.29.0 v1.35.0
v1.36.0 v1.36.1 v1.36.2 v1.37.0 v1.38.0 v1.39.0 v1.42.0 v1.43.0 v1.44.0 v1.45.0 v1.46.1 v1.47.0
v1.50.0 v1.51.0 v1.52.0 v1.53.0 v1.54.2
```

**Not written here.** The consolidated span bundle is plan item **PC-25**, and this commit may touch
only `docs/revendor/2026-09-23-v1.56.0/` (spec Part B). PC-25's item text says 26 tags,
v1.18.0 to v1.53.0. This listing also prints v1.16.0 (the store's first bundle is dated 2026-08-25,
the same day v1.16.0's commit landed) and v1.54.2, so PC-25 should re-derive its tag list rather than
trust the count. v1.56.0 is recorded by this bundle.
