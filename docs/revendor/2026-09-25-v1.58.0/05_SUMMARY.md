# 05 — Summary: LibKa0s v1.57.0 -> v1.58.0

Plan item M6-PC, 2026-09-25, branch `feat/2026-09-23-review-audit-remediation`. Written by hand in
the shape of the M5-PC bundle. Nothing pushed, and the addon version is not bumped.

## The tag, and the per-file minors

`v1.57.0` -> `v1.58.0` (tag object `93cf3ad`, commit `34931c9`, local). One file moves a minor:
**Launcher 3 -> 4**. Every other library file, and the whole kit (revision 26), is byte-identical.
The diffs are in `01_DELTA.md`, sections 3c to 3f.

## Delivered on the re-vendor, with nothing asked for

- The tooltip's hints read `Left-click: Open settings` and `Right-click: Options menu`.
- Left-click keeps opening the settings panel (this addon was already rung (c)).

## Contract blockers

The right-click hint (`01_DELTA.md` 3g): two tooltip cases re-pinned in the copy commit. 486 / 486
after.

## Adopted

The `launcher-§2` menu pair, in the second `M6-PC:` commit (the M6 plan row decides it, not an
interview), matching the standard's `ADDONS.md` row for this addon, `Enabled`:

- `setEnabled` -> `NS.SetAddonEnabled`, the very function `/pc enable` and `/pc disable` call
  (settings/Slash.lua), so the menu writes `General.enabled` through the same seam and prints the
  same echo. `isEnabled` (from M5) is its accessor.
- `disabledLine` dropped: retired at Launcher version 4.

## Not passed, and why

- `isLocked` / `toggleLock`, `isTestMode` / `toggleTestMode`, `isWindowShown` / `toggleWindow`: the
  addon is frameless. It has no frame to lock, no test-mode switch (`/pc test` is a verb that prints
  samples, not a state) and no primary window.
- `onClick`, `leftClickLabel`: retired at version 4 (and never passed here).

## Gates

| Suite | After the copy | After adoption |
|---|---|---|
| `ka0s-bounded luacheck .` | 0 / 0 in 48 files | 0 / 0 in 49 files (`tests/mock_menu.lua` added) |
| `ka0s-bounded lua5.1 tests/run.lua` | 486 / 486 (two hints re-pinned) | 490 / 490 (menu cases in `tests/test_launcher.lua`, `disabled/8` rewritten) |
| `ka0s-bounded lizard … -C 15 -w .` | — | no function over CCN 15 |
| `diff -r` of both payloads against the tag | empty | — |
