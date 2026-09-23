# 04 — Execution plan: LibKa0s v1.55.0

One adopted candidate, C-1 `LibKa0s-Schema-1.0`, as one commit. C-2 and C-3 are filed declines and
touch no code.

## C-1: Schema, the seam adopter

### Characterization, written and green before any code moved

Eleven cases appended to `tests/test_schema.lua` under "the write seam, characterized". They ran
green against the host-owned seam at `365e3be`:
`ka0s-bounded lua tests/run.lua` gave **434 passed, 0 failed, 0 skipped, 434 total** (423 + 11), and
`ka0s-bounded luacheck .` gave **0 warnings / 0 errors in 48 files**.

| Case | What it pins | Why the adoption could move it |
|---|---|---|
| one write stores, re-applies once, refreshes once, logs one `[Set]` line, answers true | stored value and clear-to-absence, 1 pass, 1 refresh, 1 `[Set] Loot.enabled = ` line, **return arity 1** | `Set` moves to the library and the tail moves to `announce` |
| a format write renders its `[Set]` value through the shared formatter | the doubled pipes in the line, the override in `_G` | `format` becomes a descriptor field |
| a session-only write refreshes but re-applies nothing | 0 passes, 4 refreshes (2 seam + 2 window) | the `sessionOnly` filter moves into `announce` |
| a raising row store propagates, and nothing after it runs | error reaches the caller, 0 passes, 0 refreshes, no `[Set]` line | the library's store-then-log order |
| `/pc set` of a surplus-conversion format is refused once and stores nothing | store and `_G` unchanged, 1 refusal line, no `[Set] <path> = ` line; a valid value through the same verb writes and logs | the gate moves into `validate`, and the Slash descriptor binds `S.Set` directly |
| `/pc reset` of a format row restores the shipped default | default back in the store and `_G`, 1 pass, 1 `[Set]` line | `ApplyDefault` moves to the library |
| resetting the console row through `ApplyDefault` or `/pc reset` closes the console | the window hides on both paths | JC-5: the library's `default == nil` means no restore |
| `CountChangedRows` counts stored rows off their default, never the console | 0, then 3, then 0 | becomes `S.CountOffDefault` |
| `FindByPath`, `Get` and `AllRows` answer the one schema | nil for nil and number paths, nil for a row-less path, live-table identity, every path declared once and resolving to its own row | the index moves to the library, and the library is first-wins on a duplicate (JC-7) |
| library absent: `/pc disable` and `/pc enable` still write | the stored switch on both edges | the degraded arm now runs the host's stub |
| library absent: a category reset and the format gate still work | a write reaches `_G`, the gate refuses, the category reset restores both rows | same |

### The code change

- `settings/Schema.lua`: build `rows` as today. Resolve `LibStub("LibKa0s-Schema-1.0", true)` or
  the host stub (`version-1-docs.md` "The degradation stub"). `SchemaLib:New{ rows, announce,
  debug, format, print }`, stashed as `NS.SchemaRuntime`, with `NS.SchemaLib` the resolved library
  or stub. The public names `FindByPath`, `Get`, `Set`, `AllRows`, `ApplyDefault` and
  `CountChangedRows` bind to the members. `refusedBySignature` moves ahead of the builders. Each
  `string_format` row gets a `validate` that keeps the chat line, the snap-back refresh and the
  `refused` debug line. Each `set` is wrapped in `PrettyChat.Batch` where it is built.
  `MASTER_SPEC.defaults.debugConsole = false`. `InstallMasterControls` calls `S.AddRows(wired, 1)`.
- `settings/OptionsSetup.lua` and `settings/Slash.lua`: `get`, `set`, `applyDefault`, `allRows`
  and `findRow` become the instance members, as values. The degraded composer's console leaf
  carries `defaults.debugConsole`, as its comment says every leaf carries the caller's defaults.
- `modules/Override.lua`: the comment on `Batch` names its new callers. Comment only.

### The assertions that prove the change, added with the code

- `tests/test_surface_parity.lua`: the host stub instance against a live instance (the two-table
  form), and the host stub library against `LibKa0s-Schema-1.0` by name, ignoring `STRINGS`. The
  by-name case gets `["LibKa0s-Schema-1.0"]` in the file's `ctx.setSurfaceSource` map.
- `tests/test_schema.lua`: the schema passes `S.Validate` with `0, 0, 0` (JC-13). The live seam is
  the library's instance. JC-4: the `[Set]` line is written before the re-apply.
- Re-pins the spec prescribes, each named in the commit message: the console row's
  `default` goes `nil` → `false` (JC-5), and a refused `Set`'s first value stays `false`.

### Gate and commit boundary

`ka0s-bounded lua tests/run.lua` and `ka0s-bounded luacheck .` green, `git ls-files --eol` showing
`w/crlf` on every touched file, then one commit. A red that cannot be closed without changing a
pinned behavior rolls back to `365e3be` plus the characterization cases, and the candidate is
declined `state:triaged`.

## Close-out

- `docs/ARCHITECTURE.md`: `## Settings Schema`, `## Invariants` (single write path, the gate) and
  `## Message Bus` (the fan-out paragraph) name `LibKa0s-Schema-1.0`. No `## Documented deviations`
  row covers the schema seam, so none is retired.
- `docs/schema.md`: the seam section.
- Regenerate `docs/test-cases.md` with `lua tests/run.lua --list`. The README badge must agree
  with its total.
- Commit the bundle (`02`-`05`).
