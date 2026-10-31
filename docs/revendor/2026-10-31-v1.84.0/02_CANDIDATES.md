# LibKa0s v1.83.0 -> v1.84.0: candidates (PrettyChat)

Sources: `git -C ../LibKa0s log --oneline v1.83.0..v1.84.0`, the CHANGELOG v1.84.0 block, and the
`docs/api` documents of every major whose minor moved.

## A. Delivered on the re-vendor alone

- The peels (Skin, SkinDefs, SimPanel, the skin picker, OptionsIds, OptionsWidgets, OptionsTabs, the
  kit's `mock_base.lua`): pure moves, no public member and no pixel moves.
- Real Friz measured and guarded (LibKa0s#69): no size moves.
- The diagnostics identity header names Charts (DebugLogDiagnostics minor 6).
- `ClearScroll` keeps the banner refresher, and `/list` and `resetall` skip a `note` row: unused here.
- WidgetsDragHandle minors 9 and 10: this addon has no drag handle, so nothing changes.

## B. Host change required

| Candidate | Evidence | Would touch | Recommendation | Blast radius |
|---|---|---|---|---|
| `opts.beforeGroup`, `opts.afterSubgroup` | Options 35.4.40.2... docs, flow seams | `settings/Panel.lua` | Decline: the General page's `afterGroup` hook is enough | additive |
| `note` row | Options and Schema 3 docs | `settings/Schema.lua` | Decline: the Categories footnote is a hand-built page row, not a schema row | additive |
| `O.PositionBlock` | Options docs, C15 | none | Decline: frameless, no position rows (`settings/Schema.lua:110`) | additive |
| `O.PageBanner{ acts }` | Options docs, T13 | `settings/Panel.lua` | Decline: no page needs a banner act | additive |

## C. Whole-module adoption

| Candidate | Evidence | Recommendation | Blast radius |
|---|---|---|---|
| `LibKa0s-Charts-1.0` | `docs/api/Charts/version-1.1-docs.md` | Decline: nothing here draws a chart | additive |

Settled and not re-offered: Compat, Bus and Perf (`docs/ARCHITECTURE.md`, the vendored-library section).
