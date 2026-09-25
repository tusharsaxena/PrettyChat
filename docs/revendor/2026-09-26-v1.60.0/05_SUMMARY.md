# 05 — Summary: LibKa0s v1.58.0 -> v1.60.0

Plan item DR-PC-01, 2026-09-26, branch `feat/2026-09-25-diagnostics-rollout`. Nothing pushed, and
the addon version is not bumped.

## The tag, and the per-file minors

`v1.58.0` -> `v1.60.0` (tag object `ac59511`, commit `bed0eb1`), spanning v1.59.0, which this addon
never vendored. **DebugLog 13 -> 14**, **DebugLogDiagnostics new at 1**, **Slash 15 -> 16**,
**WidgetsDragHandle 2 -> 3**; the kit **26 -> 27**. Every other file is byte-identical. After the
copy, `diff -r` of both payloads against the tag is empty and the runner keeps its +x bit.

## Delivered on the re-vendor, with nothing asked for

- A 3000-line debug console (was 1500), and the copy window with it.
- `diagnostics` in the live set while disabled, ready for the verb DR-PC-03 registers.
- The copy-timing switch `lib.TIME_COPY`, off.

## Contract churn, fixed in the copy commit

No host member changed meaning. The copy commit also carries:

- `core/DebugLogSetup.lua`: the library-absent stub gains `RunDiagnostics` (prints
  `/pc diagnostics is unavailable: the LibKa0s library did not load.`, writes nothing, returns 0),
  `BuildDiagnostics` (the live shape, empty) and `DebugVerb`. That line is recorded as locale
  residue in `tests/test_locale.lua`, as the collection's sentence.
- `tests/run.lua`: the kit's `test_diagnostics_contract` declared. It is one declared skip until
  DR-PC-03 wires `Kit.diagnostics`.
- `tests/test_debuglog.lua` (the cap and counter cases) and `tests/test_libka0s.lua` (the counter)
  are re-pinned on `lib.MAX_BUFFER`, with no literal.
- `tests/test_disabled.lua`: the reserved-verb literal gains `diagnostics` (thirteen).
- `tests/test_libka0s.lua`: a new case drives the stub's `RunDiagnostics`, `BuildDiagnostics` and
  `DebugVerb` on a library-absent load.
- `settings/Slash.lua`: the descriptor comment now says `liveVerbs` replaces the live set; it no
  longer says the field widens it.

## Adopted, declined, unreached

Nothing adopted here. The diagnostics report and verb are adopted in DR-PC-03 by the rollout plan.
Nothing was declined and no issue was filed. The WidgetsDragHandle X is not a candidate, because
this addon has no drag handle.

## Gates (all through `ka0s-bounded`)

| Suite | Before | After the copy commit |
|---|---|---|
| `luacheck .` | 0 / 0 in 49 files | 0 / 0 in 49 files |
| `lua tests/run.lua` | 490 / 490 | 491 passed, 0 failed, 1 skipped (the kit's diagnostics contract, unwired), 492 total |
| `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" -C 15 -w .` | — | no function over CCN 15 |
| `diff -r` of both payloads against the tag | two payloads differ | empty |
