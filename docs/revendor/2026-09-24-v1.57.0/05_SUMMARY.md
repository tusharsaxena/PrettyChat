# 05 — Summary: LibKa0s v1.56.0 -> v1.57.0

Plan item M5-PC, 2026-09-24, branch `feat/2026-09-23-review-audit-remediation`. Written by hand in
the shape of the RV-PC bundle. Nothing pushed, and the addon version is not bumped.

## The tag, and the per-file minors

`v1.56.0` -> `v1.57.0` (tag object `d03e836`, commit `aa37bc9`, local). One file moves a minor:
**Launcher 2 -> 3**. Every other library file, and the whole kit (revision 26), is byte-identical.
The diffs are in `01_DELTA.md`, sections 3c to 3f.

## Delivered on the re-vendor, with nothing asked for

- The minimap button and any broker row now answer a hover with the library's status tooltip, in
  both states: `Ka0s Pretty Chat`, `Enabled: Yes`, `Left-click: Open settings`, `Right-click: Open
  settings`.

## Contract blockers

None (`01_DELTA.md` 3g). The suite stayed green across the copy: 481 of 481.

## Adopted

The `launcher-§1` descriptor fields, in the second `M5-PC:` commit (not a candidate interview; the M5
plan row decides it):

- `version` -> `NS.Version()`, the TOC's `## Version`, so the title reads `Ka0s Pretty Chat  v1.5.0`.
- `isEnabled` -> `PrettyChat:IsAddonEnabled()`, so `Enabled:` reads No while disabled; with the
  `disabledLine` the library requires beside it (the Slash dispatcher's own `DisabledLine()`). On
  rung (c) the pair gates nothing: the library gates only a left click that has an `onClick`.

## Not passed, and why

- `isLocked`, `isTestMode`: the addon is frameless and has neither state (no Lock frame row, no Test
  mode row; `/pc test` is a verb, not a switch).
- `leftClickLabel`: this addon is rung (c) in the standard's `ADDONS.md`; the library draws `Open
  settings` there and ignores the field.
- `onTooltipShow`: the addon had none and has no line of its own to add.
- `L`: the addon ships enUS only and `NS.L` answers every key with the key (anti-pattern #2).

## Gates

| Suite | After the copy | After adoption |
|---|---|---|
| `ka0s-bounded luacheck .` | 0 / 0 in 48 files | 0 / 0 in 48 files |
| `ka0s-bounded lua5.1 tests/run.lua` | 481 / 481 | 486 / 486 (five tooltip cases in `tests/test_launcher.lua`) |
| `ka0s-bounded lizard … -C 15 -w .` | — | no function over CCN 15 |
| `diff -r` of both payloads against the tag | empty | — |
