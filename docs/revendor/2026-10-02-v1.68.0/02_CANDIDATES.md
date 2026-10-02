# Candidates (PrettyChat, LibKa0s v1.67.0 -> v1.68.0)

Sources: `git -C ../LibKa0s log --oneline v1.67.0..v1.68.0` (8 `DA-LK-*` commits, one payload
change), `git -C ../LibKa0s show v1.68.0:CHANGELOG.md` (the v1.68.0 block: "WidgetsDragHandle minor
4 ... Every other file is unchanged from v1.67.0") and `docs/api/Widgets/version-12.1.4-docs.md`
against `version-12.1.3-docs.md`. Base v1.67.0 from this repo's CLAUDE.md provenance line.

## A. Delivered on the re-vendor alone (not offered)

- **Widgets 12.1.4 without a hook** (`version-12.1.4-docs.md:46`-`:48`): a strip that sets neither
  `tooltipPlace` nor a descriptor `place` makes minor 3's calls in minor 3's order. PrettyChat draws
  no strip, so nothing it shows moves.
- **Kit 35**: unchanged.

## B. Host change required (candidates)

1. **`tooltipPlace(tip, frame)` on a drag-handle spec, or `place` on a tooltip descriptor**
   (WidgetsDragHandle 4, AuraMaster#22; `docs/api/Widgets/version-12.1.4-docs.md:22`, `:692`,
   `:725`-`:756`). Lets the host anchor the strip's tooltip itself (beside the strip) instead of the
   cursor or the strip-owned default.
   - Files it would touch: none exist. PrettyChat builds no `lib.DragHandle`; 3e shows no
     `LibKa0s-Widgets-1.0` lookup in `core/`, `settings/` or `modules/`, and
     `grep -rn 'DragHandle\|tooltipPlace\|tooltipOwner' core settings modules` is empty. Its only
     windows are the library's debug console and copy window, neither of which is a drag strip.
   - Blast radius: additive, but there is nothing to add it to.
   - Recommendation: **decline, not applicable** (no drag strip). See 03_DECISIONS.md.

## C. Whole-module adoption

None new. Widgets stays unconsumed by the host, as recorded in `docs/ARCHITECTURE.md` (External
dependencies: "Item, Pool and Widgets are not consumed here at all"); this release changes no
premise of that, since the only new surface is a field on a widget PrettyChat has no use for.
Item, Pool, Compat, Bus and Perf keep their recorded status.
