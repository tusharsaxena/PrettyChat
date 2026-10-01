# Candidates (PrettyChat, LibKa0s v1.65.0 -> v1.66.0)

Listed, **not interviewed**: the 2026-10-01 GitHub issue pass (02_SPEC.md S4) defers every adoption
decision this cycle to its library-side census, item GI-LK-13 (`docs/api/CONSUMERS.md` in LibKa0s).
Nothing below was adopted, declined or filed.

Sources: `git -C ../LibKa0s show v1.66.0:CHANGELOG.md` (the v1.66.0 block) and the `Since` markers in
the new documents for the majors whose minor moved.

## A. Delivered on the re-vendor alone (not offered)

- **Slash 19 / SlashParse 1**: the parser peeled to `SlashParse.lua`; `set` keeps working.
- **DebugLog 19**: `lib:New` below CCN 15, no surface change.
- **Perf 14 / PerfSampler 1 / PerfCommands 1**: vendored only; Perf is declined here under the
  ratified `performance-§12` no-combat-path exemption (`docs/ARCHITECTURE.md`), so the budget and
  zero-parent changes do not reach this addon. Settled, premise unchanged.
- **Widgets 12 / WidgetsReorder 1**: vendored only; Widgets is not consumed here.
- **Kit 35**: the sighted complexity suite and `test_lizard_sighted.lua` (wired in the RV commit).

## B. Host change required (candidates)

1. **Forward Slash 19's resolver through the host `parse` hook.** `settings/Slash.lua:280` could take
   `(row, text, textOf)` and pass `textOf` to `lib.ParseValue`. Evidence:
   `docs/api/Slash/version-19.1-docs.md:59`, `:759`. Blast radius: additive, one function. Value
   today: none visible, because the descriptor passes no `L` and `NS.L` echoes keys, so the
   refusal reads in `lib.STRINGS` either way. Recommendation for GI-LK-13: low; adopt only if the
   addon ever ships a non-English Slash `L`.
2. **`RenderGrid(ctx, items, parent, opts)`** (`docs/api/Options/version-27.2.34.2.2.8.1.7.4.2-docs.md:1364`).
   PrettyChat does not use `RenderGrid` (`settings/Panel.lua:165` records why: no tree-plus-content
   ratio). Recommendation: not applicable.
3. **`RenderTabbedSchema` opts `untabbedSkipRender`, `disabledReplaces`, `disabledNoticeFont`,
   `rerender`** (same document, `:49`-`:54`). `settings/Panel.lua:141` (General) passes no `opts`, and
   the Categories page does not use `RenderTabbedSchema` (`settings/Panel.lua:558`). No current page
   has an all-`skipRender` group, a disabled-page notice or chrome above the strip that a tab click
   loses. Recommendation: not applicable today.

## C. Whole-module adoption

None new. Item, Pool, Widgets, Compat, Bus and Perf keep their recorded status
(`docs/ARCHITECTURE.md`, External dependencies; `docs/revendor/2026-09-23-v1.55.0/`).
