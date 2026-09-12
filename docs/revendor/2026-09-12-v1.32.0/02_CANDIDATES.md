# 02 — Candidates: what v1.32.0 brings PrettyChat

Sources, in the order the procedure requires:

```sh
git -C ../LibKa0s log --oneline v1.31.0..v1.32.0
# e18dd12 The v1.32.0 release record, re-taken on the final tree
# c6314d6 CLAUDE.md: the luacheck scope is fifty-four files at v1.32.0
# 4083889 v1.32.0 review: bulkEnd's info names a profile reset (debug-logging-§10 final ruling)
# 4353908 The v1.32.0 release record
# f7d78cd v1.32.0: Options 16 and Slash 8 bracket their reset walks (debug-logging-§10)
# 807925a v1.31.0 post-tag docs and test: the verifier's findings
git -C ../LibKa0s show v1.32.0:CHANGELOG.md                                  # the v1.32.0 block, :13-79
git -C ../LibKa0s show v1.32.0:docs/api/Options/version-16.15.4.3-docs.md    # O16
git -C ../LibKa0s show v1.32.0:docs/api/Slash/version-8-docs.md              # Slash 8
```

Only two majors changed: Options (15 to 16) and Slash (7 to 8). Both changes are the same thing, an
optional `bulkBegin(act, scope)` / `bulkEnd(act, scope, count, err, info)` pair on the descriptor.

## Class A: reached PrettyChat on the re-vendor alone

| Item | Evidence | Why nothing else is needed |
|---|---|---|
| Options 16: the bracket is **optional**; a descriptor with neither field runs minor 15's walk exactly | CHANGELOG v1.32.0 `:31-34` ("A host that supplies neither new field runs the exact walk it ran at v1.31.0, with no `pcall` on the path"); `version-16.15.4.3-docs.md:791` | PrettyChat's descriptor (`settings/OptionsSetup.lua`) supplies neither field, so `RestoreDefaults` / `RestoreAllDefaults` behave byte for byte as before. |
| Slash 8: the same optional pair around `CliResetAll` | CHANGELOG v1.32.0 `:66`; `version-8-docs.md:43`, `:269-270` | The Slash descriptor (`settings/Slash.lua`) stubs `CliResetAll` on its degraded path (`:127`) and never delegates `resetall` to it on the live path (`runResetAll`, `:296`). |

## Class B: host change required

### B1. Adopt `bulkBegin` / `bulkEnd` on the Options and Slash descriptors

- **What:** mute the per-row `[Set]` line inside a library reset walk and emit one
  `[Set] reset <scope>: N rows` line from `bulkEnd` (nothing when `info.profileReset`).
- **Evidence:** `version-16.15.4.3-docs.md:48-49`, `:69`, `:790-791`, `:877-878`; worked host example
  `:113-161`. `version-8-docs.md:58-59`, `:269-270`.
- **Files it would touch:** `settings/OptionsSetup.lua` and `settings/Slash.lua` (descriptors), plus a
  mute counter at the write seam in `settings/Schema.lua`.
- **Blast radius:** additive.
- **Recommendation: do not adopt.** No PrettyChat act reaches a bracketed walk:
  - Every Defaults press goes through the host's `defaultsOnClick` (`settings/Panel.lua:748`) to
    `PrettyChat:ResetCategory`. The library's button calls only `panel.defaultsOnClick`
    (`libs/LibKa0s/Options.lua:583-584`) and has no fallback to `RestoreDefaults`.
  - `RestoreAllDefaults` exists only on the degraded stub (`settings/OptionsSetup.lua:179`), which
    calls `PrettyChat:ResetAll()`, a host act.
  - `/pc resetall` is `runResetAll` → `PrettyChat:ResetAll` (`settings/Slash.lua:296`), never
    `Sl:CliResetAll`.
  - `tests/test_surface_parity.lua:145` pins that no host file calls `Helpers.RestoreDefaults`.

  The bracket would therefore be dead wiring, and it would add a second mute mechanism beside
  PrettyChat's own resets. Those own resets are where debug-logging-§10 actually applies. They are
  converted in this rollout (see `04_EXECUTION_PLAN.md`), not through the bracket.

## Class C: whole-module adoption

None raised. The unconsumed majors (`Item`, `Pool`, `Widgets`, `Perf`) did not change in v1.32.0.
`Perf` stays declined by the `performance-§12` row in `docs/ARCHITECTURE.md` →
`## Documented deviations`. v1.32.0 does not touch the premise (no combat path).

## Not a library candidate, but in scope for this run

The standard's v2.44.0 debug-logging-§10 ruling applies to PrettyChat's **own** reset acts, whatever
the library does. Those are the rollout's conversions, recorded in `04_EXECUTION_PLAN.md`:
`Schema.ResetRows` (category and string resets), `PrettyChat:ResetAll` (profile reset), and the
`OnProfileCopied` wording.
