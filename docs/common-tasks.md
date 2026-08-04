# Common tasks

Recipes for the routine modifications. For deeper context on any module, see [module-map.md](./module-map.md) and the per-topic docs.

## Add a new format string to an existing category

The single source of truth is `defaults/Defaults.lua` — Schema, Config, and slash UI all derive from it.

1. In `defaults/Defaults.lua`, add a new entry under the relevant category's `strings` table:
   ```lua
   YOUR_GLOBAL_NAME = {
       label = "Friendly Label (Self)",
       default = "|cffff0000Loot|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s|cffffffff",
   },
   ```
   - `label` is what the panel shows as the block's full-width `Heading` above the Enable row (`GameFontNormalLarge`).
   - `default` is the PrettyChat format. Match Blizzard's `%`-conversion signature exactly — see [Fix a broken format string](#fix-a-broken-format-string) below for what happens if you don't.
2. `/reload` in-game. The schema rebuilds at file-load, so the new row appears in `/pc list <Category>`, in the panel sub-page, and the override pipeline starts targeting `_G[YOUR_GLOBAL_NAME]`.

No code changes needed. The Schema row, panel widgets, slash-set parsing, Test preview, and the per-category **Defaults** button all pick the new entry up automatically.

## Add a new category

Categories are top-level keys in `NS.Defaults`. Adding one requires:

1. **`defaults/Defaults.lua`** — add a top-level entry:
   ```lua
   YourCategory = {
       enabled = true,
       strings = { /* one or more entries as above */ },
   },
   ```
2. **`settings/Schema.lua`** — append the category name to `CATEGORY_ORDER` (controls display order in the panel left rail and `/pc list`):
   ```lua
   local CATEGORY_ORDER = {
       "General",
       "Loot", "Currency", "Money", "Reputation",
       "Experience", "Honor", "Tradeskill", "Misc",
       "YourCategory",   -- new
   }
   ```
3. (Optional) Add a category-color line to the [color palette](./settings-panel.md#color-palette) section of `docs/settings-panel.md` if you're introducing a new label color.
4. `/reload`. The category appears as a sibling sub-page beneath "Ka0s Pretty Chat" in the addon list, the schema picks up its rows, and `/pc list YourCategory` works.

No `settings/Panel.lua` edits — `buildCategoryBody` is generic and iterates whatever's in `NS.Defaults[category].strings`.

## Fix a broken format string

A format string "breaks" when the panel-edited (or `/pc set`-edited) value's `%`-conversions don't match Blizzard's signature. Symptom: the chat line errors at `string.format` time, sometimes silently dropping the message, sometimes throwing a Lua error.

1. Open the panel sub-page for the category and read the **Original Format String** disabled input for the affected key. That's Blizzard's exact signature (read from the addon-private `NS.GlobalStrings` — no `_G` global; PC-14).
2. Edit the **New Format String** input: keep every `%`-conversion (`%s`, `%d`, `%.1f`, `%2$s`, …) in the same order, but freely change surrounding text and `|cAARRGGBB...|r` color escapes.
3. The Preview disabled `EditBox` (bottom-right of the block) renders the format with sample arguments substituted in via `NS.RenderSample` (which wraps `buildSampleArgs` from `modules/Override.lua`). It always reflects the saved value and updates after every commit (Enter). On `string.format` failure, the preview shows the error message instead.
4. To revert: (a) click the per-string **Reset** button (bottom-left of the block — always visible, no-op when the value already equals the default — the simplest path); (b) set the format back to the PrettyChat default exactly — the auto-clear kicks in and removes the override (see [schema.md](./schema.md#auto-clear-on-default)); (c) disable the per-string Enable checkbox, which restores Blizzard's original via the snapshot path; or (d) the category page's header **Defaults** button — which is now the only category-scoped reset, since `/pc reset` takes a setting path (`LIBKA0S-10`).

## Edit the PrettyChat default for a string

If you want the *shipped* default for a key to change (not just per-user overrides):

1. Edit the `default` field of the entry in `defaults/Defaults.lua`.
2. Existing users with a saved override won't see the change — their stored value still wins. The auto-clear on default match doesn't help retroactively (a value that was the *old* default isn't the *new* default).
3. If you want to force-reset existing users to the new default for that one string, there's no graceful path — they'd need the category page's **Defaults** button (clears every override in that category, not just yours) or to set the format to the new default text exactly (which then auto-clears).
4. For most cases, prefer "ship the new default; existing overrides keep working" — that's the contract.

## Regenerate `GlobalStrings_*.lua` after a WoW patch

See [global-strings.md](./global-strings.md#regenerating-chunks-after-a-wow-patch). Short version:

1. Drop the new `GlobalStrings.lua` into `GlobalStrings/`.
2. `python3 GlobalStrings/split_globalstrings.py` — it rewrites the chunk files *and* `PrettyChat.toc`'s `# GlobalStrings` block, so commit the TOC alongside them. The chunk count changes whenever the entry count crosses a multiple of 900.
3. `/reload` in-game; verify the panel's "Original Format String" inputs still resolve.
4. If Blizzard renamed any keys or changed signatures, update the corresponding entries in `defaults/Defaults.lua`.

## Add a new slash command

One row in the `COMMANDS` table near the top of `settings/Slash.lua`:

```lua
{"yourverb", L["Description shown in /pc help"],
    function(rest) yourFunctionBody(rest) end},
```

Positional triple, and the handler takes **`rest` alone** — `LibKa0s-Slash-1.0` dispatches with `entry[3](rest)`. A table of named fields is silently invisible to it: every verb becomes unknown and the help block renders empty.

The dispatcher, the help printer and the settings landing page all read the same table. If your command needs the schema, guard with `if not schemaReady() then return end` (the same pattern the existing schema-touching commands use).

Two follow-ups the harness enforces:

1. Wrap the description in `L[…]` **and** add that exact string to the enUS manifest in `locales/enUS.lua` — `test_locale` scans the sources for `L["…"]` call sites and fails on any that the manifest doesn't carry (and on any manifest entry nothing references).
2. Run the gate. `test_slash` drives the real `/pc` entry point and asserts every line carries the `[PC]` tag, so a new verb that prints raw fails immediately. If you add or rename a **test case**, also regenerate `docs/test-cases.md` and update the README `Tests` badge in the same change (testing-§5).

## Adjust the per-string panel block layout

The per-string block lives in `settings/Panel.lua`'s `buildStringRow(scroll, category, globalName, strData, refreshers)`. It renders a `Heading` followed by three Flow rows — Enable/Original, GLOBALNAME/New, Reset/Preview — and attaches a `refresh()` closure to `refreshers` so subsequent DB-mutations (`/pc set`, category toggle, Defaults click) re-sync this block's widgets.

Each row is an AceGUI `SimpleGroup` with `Flow` layout containing two children at `LEFT_W = 0.4` / `RIGHT_W = 0.6` relative widths so the two columns align across rows. The right-column EditBoxes carry `:SetLabel("Original" / "New" / "Preview")`. `STRING_VSPACER` is this block's own and lives in `NS.Const`; the shared spacing it sits beside (`ROW_VSPACER`, `SECTION_HEADING_H`) is read off `NS.Helpers`, because the library owns the layout constants now (options-ui-§8). See [settings-panel.md](./settings-panel.md).

When you add or remove a widget, also update the block's `refresh()` closure so the new widget syncs from the DB on every mutation.

## Verify a behavior change

Two layers, in order. **Headless first:** `lua tests/run.lua` + `luacheck .` must both be green before any commit ([testing.md](./testing.md)). The suites are data-driven — a new format string or a new category is picked up and asserted automatically (`test_defaults` cross-checks the defaults table against the schema built on top of it), so most additions need no test edit. **Then in-game**, for what stock Lua can't reach:

See [smoke-tests.md](./smoke-tests.md). The quick recipe at the top handles routine work; the full suite groups (Boot / Override pipeline / Settings panel / Slash / Cross-surface sync / Persistence) catch the rest. If you touched `OnEnable` / `ApplyStrings` / `settings/Schema.lua` / `settings/Panel.lua` / slash dispatch, that doc lists which test groups to run.

If you can only reason about a change from code and cannot test it in WoW, say so explicitly — don't claim it works.

## Cut a release

Before the tag, in the **same change** that bumps `## Version:` in `PrettyChat.toc` and rolls the README's `## What's new` and `## Version History` forward:

1. Regenerate the complexity report — `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .`, verbatim, from the repo root — overwrite [`complexity.md`](./complexity.md), and **read its diff**: give every newly-crossed threshold a one-line disposition in the `## Watch list`. This is a release checkpoint, **not** a commit gate. Full rules and the stale-tooling case: [testing.md](./testing.md#complexity-report--a-release-checkpoint-not-a-commit-gate-performance-10) and `performance-§10`.
2. Re-check [`../DEPENDENCIES.md`](../DEPENDENCIES.md) against what the repo now actually needs (documentation-§5/§7) — a new script, a new import or a dropped tool belongs there already, but the release is the backstop.
3. Regenerate `docs/test-cases.md` and sync the README `Tests` badge if the suite moved (testing-§5).
