Delta: LibKa0s v1.106.0 -> v1.107.0

Recorded for the re-vendor commit. Payload taken from the tag, never the sibling tree: `git -C ../LibKa0s archive v1.107.0 LibKa0s testkit tools` (tag 427e108, commit 5e96365; a local annotated tag, not yet on origin, which this run expects). Run under the adoption feedback run (Ka0sAddonsCommonTasks `docs/2026-11-19-ADOPTION_FEEDBACK/`), item AF-RV-PC: the copy, provenance, declaration and prune half of `/dev-copilot:wow-revendor-libka0s` only. The adoption interview is skipped by that run's design; it lists no adoption item for this addon.

## Step 0 pre-flight
For this addon: newest single-tag bundle `docs/revendor/2026-11-16-v1.105.0`, base v1.94.0, vendored-before v1.94.0@755bb76: `ok`. No base correction is owed.

## 3a Base
- `grep -n '[Bb]undles' CLAUDE.md` -> `45:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.106.0 (MIT).` before the roll.
- `git log -1 --format=%H -- libs/LibKa0s tests/_kit` = 1bc919c (Re-vendor LibKa0s v1.106.0); its CLAUDE.md names v1.106.0. They agree.
- Payload before the copy equalled the library at v1.106.0: `diff -rq` of a v1.106.0 extract against `libs/LibKa0s` (bar the undeclared icons and the sounds) and against `tests/_kit` printed nothing (payload-matches).
- Range: `git -C ../LibKa0s log --oneline v1.106.0..v1.107.0` is 6 commits (cbf3577 AF-LK-01 + #96, efbed58 AF-LK-02, f468fe7 AF-DR-LK, 24b9cea / 72653ec / 5e96365 AF-LK-03). `git diff --stat v1.106.0 v1.107.0 -- LibKa0s testkit`: `LibKa0s/WidgetsDragHandle.lua` and `LibKa0s/WidgetsDragHandleTip.lua` only.

## 3b/3c Per-file minors that moved (old = this addon, new = v1.107.0)
From the loop over the tag's `LibKa0s.xml`:
```
WidgetsDragHandle.lua     old: local DRAG_MINOR = 14     new: local DRAG_MINOR = 15
WidgetsDragHandleTip.lua  old: local DRAGTIP_MINOR = 1   new: local DRAGTIP_MINOR = 2
```
Every other file matched v1.106.0 before the copy; no file is new. Claimed and actual minors agree, so there is no cross-major skew.

## 3d Diffs
After the copy and before the prune, `diff -r --strip-trailing-cr` and `diff -r` of both payloads against the extract were empty. No `Only in libs/LibKa0s` line: nothing was removed upstream, so nothing is deleted by hand. After the prune the only difference is the undeclared icons and the sounds (`Only in <extract>/...`), and `tests/test_vendor_sync.lua` is green.

## 3e Consumption map
Unchanged from `../2026-11-16-v1.105.0/01_DELTA.md` 3e: Core, DebugLog, Env, Launcher, Lifecycle, Media, Skin, Options, Schema and Slash. No host lookup of `LibKa0s-Widgets-1.0`, and no `DragHandle` call: `grep -rn -E "DragHandle|TestStrip|tooltipPlace|LibKa0s-Widgets" --include='*.lua' .` outside `libs/` and `tests/_kit/` finds nothing. Inside the library, the only `DragHandle(` caller is `Callout.lua:709`, a major this addon does not consume.

## 3f Kit revision
`grep -n 'Kit.VERSION'`: addon 57, tag 57. Both payloads are copied whole in one commit (the pairing rule is met by construction).

## 3g Contract delta
The one major that moved, Widgets (WidgetsDragHandle 15, WidgetsDragHandleTip 2), is not looked up by this addon. The tag's `CHANGELOG.md` *What a consumer owes at its re-vendor* names three duties, all for a host with a drag strip: delete a strip `tooltipPlace` hook, pass `onClose` (and take the default settings mark), and declare `settings` on the icons line. PrettyChat has no strip, so none binds; `settings` is declared already. `grep -rn '__Attach[A-Za-z]*' . --include='*.lua' --exclude-dir=libs --exclude-dir=Libs --exclude-dir=_kit` finds no host attach site.

### Blockers
None.

## 3h Span
`vendored.txt` minus `recorded.txt` names v1.106.0 (vendored by 1bc919c, no bundle). A one-tag span bundle, `docs/revendor/2026-11-19-v1.106.0-v1.106.0/`, is written beside this one.

## 3i Icon declaration
`grep -n 'LibKa0s icons:' CLAUDE.md` -> line 46, directly under the provenance line: `chevron-down, chevron-up, clear, close, confirm, copy, eye, info, move, reset, settings, volume-high.` Kept as written: the run pre-decides no icon change, and `settings` (the strip's default mark from v1.107.0) is already declared. No `LibKa0s sounds:` line. Hand lists have drifted before (KickCD `tests/test_mediasetup.lua:28`, WhatGroup `tests/test_mediasetup.lua:19`); the owner's in-client smoke is the backstop.

Prune: `lua <extract>/tools/prune-icons.lua .` removed the undeclared icons and the 362 callout sounds the copy restored, leaving `git status` with only the two moved files; a second run printed `12 icon(s) declared; kept 13 file(s), removed 0` and `sounds none ... removed 0`.

## 3j Tests that assume the whole icon folder
Unchanged from the v1.105.0 bundle's 3j: no whole-catalog loop; the file assertions name declared icons only.

## Dead stub mirrors
`grep -rn '__releaseChrome' . --include='*.lua' --exclude-dir=libs --exclude-dir=_kit`: none.
