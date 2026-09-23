# 01 — Delta: LibKa0s v1.54.2 → v1.55.0

Run: 2026-09-23, Steps 2–4 of `/wow-addon:revendor-libka0s` taken non-interactively by a workflow
subagent (Phase 5 of the suite standards sweep). Steps 5–8 (candidates, interview, adoption,
summary) belong to a later run and are **not** taken here: nothing is adopted in this bundle. No
filing, no push. Target: this repo, branch `suite/2026-09-22-standards-sweep` @ `bc9669c`.

Source: the sibling checkout `../LibKa0s`, **tag `v1.55.0` (tag object `bb161b7` → commit
`6f9c5e0`)**, resolved with `git -C ../LibKa0s tag --sort=-v:refname | head -1` and extracted with
`git -C ../LibKa0s archive v1.55.0 LibKa0s testkit | tar -x -C <scratch>/`, never the working tree
(`git -C ../LibKa0s status --short | wc -l` → `0`). The tag is local and not yet pushed;
`tests/test_vendor_sync.lua` compares against the tag the provenance line names, so the local tag is
enough.

```
git -C ../LibKa0s log --oneline v1.54.2..v1.55.0
  6f9c5e0 Record the v1.55.0 release run
  ae48f3f Make the v1.55.0 record true after the complexity split
  244c752 Bring collectKitHoles and repoKind under the CCN 15 ceiling
  be91249 Split Schema's Set and Validate under the CCN 15 gate
  18ca82a Release v1.55.0
  c051bef Re-vendor the standards reference, and make the v1.55.0 docs true
  06b4051 Add three majors: Compat, Bus, and the Schema runtime's portable half
  2a5e06f Test-kit revision 25: the four gates standard v2.63.0 already cites
```

## 3a — Claimed version, before this run

`grep -n '[Bb]undles' CLAUDE.md` → `CLAUDE.md:42`: Bundles
[LibKa0s](https://github.com/tusharsaxena/LibKa0s) **v1.54.2** (MIT).

## 3b — Actual version, before this run

`grep -hoE 'local (MAJOR, )?[A-Z_]*MINOR *= *("[^"]+", *)?[0-9]+' libs/LibKa0s/*.lua`: Core 7,
DebugLog 12, Env 1, Item 1, Launcher 1, Lifecycle 1, Media 3, Options 23, OptionsCompose 7,
OptionsScroll 3, OptionsTabs 3, OptionsWidgets 30, Perf 12, PerfPanel 5, Pool 3, Slash 14,
Widgets 9, WidgetsDragHandle 2; kit revision 24 (`grep -n 'Kit.VERSION' tests/_kit/framework.lua`).
That is v1.54.2's version block, so the line and the bytes agreed before the copy.

## 3c — Per-file minor delta

File list read from the tag's `LibKa0s/LibKa0s.xml` (21 `<Script>` rows), minors by the same grep
over the extracted tree.

| File | Constant | v1.54.2 | v1.55.0 |
|---|---|---|---|
| `Core.lua` | `MINOR` | 7 | 7 |
| `Env.lua` | `MINOR` | 1 | 1 |
| `Compat.lua` | `MINOR` | — | **1 (new major `LibKa0s-Compat-1.0`)** |
| `Lifecycle.lua` | `MINOR` | 1 | 1 |
| `Bus.lua` | `MINOR` | — | **1 (new major `LibKa0s-Bus-1.0`)** |
| `Schema.lua` | `MINOR` | — | **1 (new major `LibKa0s-Schema-1.0`)** |
| `Pool.lua` | `MINOR` | 3 | 3 |
| `Item.lua` | `MINOR` | 1 | 1 |
| `Media.lua` | `MINOR` | 3 | 3 |
| `Widgets.lua` | `MINOR` | 9 | 9 |
| `WidgetsDragHandle.lua` | `DRAG_MINOR` | 2 | 2 |
| `DebugLog.lua` | `MINOR` | 12 | 12 |
| `Slash.lua` | `MINOR` | 14 | 14 |
| `Launcher.lua` | `MINOR` | 1 | 1 |
| `Options.lua` | `MINOR` | 23 | 23 |
| `OptionsWidgets.lua` | `WIDGETS_MINOR` | 30 | 30 |
| `OptionsTabs.lua` | `TABS_MINOR` | 3 | 3 |
| `OptionsCompose.lua` | `COMPOSE_MINOR` | 7 | 7 |
| `OptionsScroll.lua` | `SCROLL_MINOR` | 3 | 3 |
| `Perf.lua` | `MINOR` | 12 | 12 |
| `PerfPanel.lua` | `PANEL_MINOR` | 5 | 5 |

No existing file's minor moved. **No cross-major skew** before or after.

## 3d — Both diffs, before the copy

```
diff -rq --strip-trailing-cr <scratch>/LibKa0s libs/LibKa0s
  Only in <scratch>/LibKa0s: Bus.lua
  Only in <scratch>/LibKa0s: Compat.lua
  Files <scratch>/LibKa0s/LibKa0s.xml and libs/LibKa0s/LibKa0s.xml differ   (+3 <Script> rows)
  Only in <scratch>/LibKa0s: Schema.lua
diff -rq <scratch>/LibKa0s libs/LibKa0s          -> the same four lines (bytes == content)
diff -rq --strip-trailing-cr <scratch>/testkit tests/_kit
  README.md, framework.lua, run-automated-tests.sh, test_eol.lua, test_prose.lua differ
  Only in <scratch>/testkit: test_layout_cap.lua
diff -rq <scratch>/testkit tests/_kit            -> the same six lines
```

Content dirty in both payloads for the expected reason (a newer tag), no `Only in libs/LibKa0s` or
`Only in tests/_kit` line (nothing removed upstream, so nothing to delete), and no
content-clean/bytes-dirty line-ending drift.

## 3e — Consumption map

```
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
  core/CoreSetup.lua:41       Core
  core/EnvSetup.lua:59        Env
  core/MediaSetup.lua:42      Media
  core/DebugLogSetup.lua:39   DebugLog
  core/LauncherSetup.lua:92   Launcher
  core/LifecycleSetup.lua:67  Lifecycle
  settings/OptionsSetup.lua:17 Options
  settings/Slash.lua:131      Slash
  settings/Schema.lua:546     Slash   (second Slash site, already known)
```

Eight majors consumed. **Unadopted majors in the payload:** Perf (declined, ratified in
`docs/ARCHITECTURE.md`'s register under `performance-§12`), Pool, Item and Widgets (reached
internally by the library only), and the three new ones — **Compat, Bus, Schema** — which no site
here looks up (`grep -rnE 'LibKa0s-(Bus|Compat|Schema)' . --include='*.lua' --exclude-dir=libs
--exclude-dir=_kit` → empty). They feed Step 5, which is not taken in this run.

## 3f — Kit revision, and the pairing rule

`grep -n 'Kit.VERSION' <scratch>/testkit/framework.lua tests/_kit/framework.lua` → **25** at the
tag, **24** vendored. Both payloads are copied whole in one commit, so the pairing rule (LibKa0s
v1.9.0+ takes kit revision 11+ in the same commit) is satisfied by construction — the reason the two
payloads move together.

## 3g — Contract delta

**Library: nothing.** The majors 3c says moved a minor are none, intersected with the eight 3e says
this addon looks up: the empty set. The only API documents that changed under an existing major are
`docs/api/Widgets/version-9.1-docs.md` / `version-9.2-docs.md`
(`git -C ../LibKa0s diff --stat v1.54.2 v1.55.0 -- docs/api`), a status-table correction for the
DragHandle minor 2 that v1.54.2 already shipped; no Widgets byte moved and PrettyChat does not look
Widgets up. `grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit`
→ empty, so no host-supplied member exists whose call site could have moved.

**Kit: three contract changes a consumer is wrong about the moment the bytes land.** None is in a
library surface; all three are in the kit this repo runs its gate on, and all three are resolved in
the vendor commit rather than left red.

### Blockers

1. **The suite inventory is keyed by the pair (basename, directory)** (`testkit/framework.lua`
   `suiteDeclarations` / `collectKitHoles`, kit revision 25; `testing-§9`, standard v2.64.0
   `standards/testing.md:240-278`). Under revision 24 the bare `"test_prose"` at `tests/run.lua:65`
   wired this repo's own `tests/test_prose.lua` **and** was accepted as covering
   `tests/_kit/test_prose.lua`, which therefore never ran. Under 25 that is a reported collision, and
   so is the bare `"test_layout_cap"` at `tests/run.lua:58` against the newly shipped
   `tests/_kit/test_layout_cap.lua`. **Fix:** retire both hand-written copies (`tests/test_prose.lua`,
   `tests/test_layout_cap.lua`) and wire the kit's by the pair form, as the kit README's
   `test_layout_cap.lua` section and `localization-§5` ("wires one or the other, never both") direct.
2. **The prose gate reads the tracked set with no `GlobalStrings/` skip of its own.** The local copy
   skipped the folder in its own `SKIPPED_DIRS`; the kit's does not, and the library's CHANGELOG
   (v1.55.0, *Kit.prose*) measures this repo red on 34 lines, all inside `GlobalStrings/`, on the swap.
   **Fix:** see *Deviation flagged* below — the per-file, per-word waiver `localization-§5` names for
   "a generated dump of the client's own strings", not the whole-folder `Kit.prose.exempt`.
3. **The census gate needs the generated-data carve-out handed to it** (`Kit.layoutCap.exempt`,
   `layout-§1` `standards/layout.md:75`, `:81`). Without it `GlobalStrings/GlobalStrings.lua`
   (23,842 lines) is an unremarked breach or a disagreeing row. **Fix:**
   `Kit.layoutCap = { exempt = { "GlobalStrings/" } }` before `Kit.run`, and the census row marked
   `exempt` in the form `layout-§1` defines.

`test_eol.lua`'s new second case (the `.gitattributes` body against `line-endings-§5`) is not a
blocker here: `bc9669c` already brought `.gitattributes` to the canonical client-bound body.

### Deviation flagged, not made

This run's checklist asked for `Kit.prose = { exempt = { "GlobalStrings/" } }`. Standard v2.64.0's
`localization-§5` (`standards/localization.md:253-289`) publishes four exclusions, none of which is
generated data, and lists "a generated dump of the client's own strings, such as a vendored
`GlobalStrings` table" among the shapes that **MAY be waived, per FILE and per WORD**, with "a
whole-file waiver is forbidden". A folder-wide `Kit.prose.exempt` is therefore a deviation from
§5, and the library's own v1.55.0 CHANGELOG says so ("a documented deviation until the standard says
otherwise ... until §5 takes it too, `Kit.prose.exempt` is flagged here"). It is **not** made in this
run. The compliant form — `tests/prose_waivers.lua`'s `waived` table, per file and per word, with
the reason beside it — is used instead, and the choice between that and a ratified register row
(or an upstream amendment to §5 matching the one `layout-§1` took) is left to the owner.
