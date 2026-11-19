# 02 Candidates

Source: `git -C ../LibKa0s log --oneline v1.106.0..v1.107.0` and the tag's `CHANGELOG.md` v1.107.0 block.

## A. Delivered on the copy
- The drag strip's marks in header order and tints, the default settings mark, the strip tooltip above the strip, and `ApplyLevel` re-leveling the settings mark (LibKa0s#96). Library-internal for this addon: it draws no strip, and the one library strip (`Callout.lua:709`) belongs to a major it does not consume.

## B. Host change required
None for this addon. The tag's three consumer duties (`tooltipPlace` removal, `onClose`, the `settings` declaration) bind a host with a drag strip, and PrettyChat is frameless.

## C. Whole-module adoption
No change from `../2026-11-16-v1.105.0/02_CANDIDATES.md`: no major was added in this range.
