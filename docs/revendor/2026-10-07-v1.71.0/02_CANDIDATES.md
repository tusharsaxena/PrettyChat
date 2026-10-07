# Candidates (PrettyChat, LibKa0s v1.70.0 -> v1.71.0)

Sources: `git -C ../LibKa0s log --oneline v1.70.0..v1.71.0`, the tag's `CHANGELOG.md` v1.71.0
block ("What a consumer owes") and `docs/api/testkit/version-38-docs.md`. Base v1.70.0 from this
repo's CLAUDE.md provenance line. This run is a mechanical re-vendor (RV-PC): candidates are listed,
none is offered.

## A. Delivered on the re-vendor alone (not offered)

- **Kit revision 38, `--list` Totals** (LK-01): `docs/test-cases.md` regenerated in this commit. Its
  one declared skip (`test_diagnostics_contract.lua`'s opt-out case) moves to a `| Skipped | 1 |`
  row and Total reads **572**, equal to the README badge `572/572` (closes PC-R-07).
- **Env 2, OptionsIdList 4**: dead bare-global rungs removed; no host change.
- **Slash 20.2**: `/pc set` refuses `nan` and the infinities on a number row; no host change.

## B. Host change required (candidates)

| # | Surface | Source | Status |
|---|---|---|---|
| B1 | `Kit.secret`, `Kit.isSecret`, `Kit.reveal`, `Kit.installSecretValue` (kit 38, `tests/_kit/secrets.lua`) | LK-02 | not adopted in this run |
| B2 | `WidgetsLineChart` 3: segments clipped to the plot, hover re-synced on render | LK-03 | not adopted in this run (Widgets declined, #11) |
| B3 | `WidgetsAutocomplete` 2: hooks re-installed per call, `maxRows` floored | LK-04 | not adopted in this run (Widgets declined, #11) |

B1 is opt-in; PrettyChat reads no secret value (Compat is declined for the same reason,
`docs/ARCHITECTURE.md` External dependencies), so it has no local simulator to replace. B2 and B3
touch a major this addon does not consume.

## C. Whole-module adoption

None new. No module's premise moved; Item, Pool, Widgets, Compat, Bus and Perf keep their recorded
status.
