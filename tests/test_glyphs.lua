-- tests/test_glyphs.lua — the display-glyph guard over this addon's own Lua (LibKa0s v1.82.0, kit
-- revision 45's tests/_kit/glyphs.lua; PC-02 of Ka0sAddonsCommonTasks
-- docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK, Addendum 07, ruling D-19).
--
-- Nine skins (Ka0s Default plus eight) draw this addon's text in a dozen faces, and a character one of them lacks is a box in
-- that skin only. So every string literal in a tracked .lua file outside libs/, tests/ and tools/
-- carries only characters every shipped face draws (the kit's safe set, read from their cmaps).
--
-- The guard's two hits were both in GlobalStrings/, the dump of the client's own strings: the
-- BLIZZARD_STORE_CURRENCY_FORMAT_EURO copies ("€%s", U+20AC) at GlobalStrings/GlobalStrings.lua
-- and GlobalStrings/GlobalStrings_003.lua. That dump is loaded by nothing and never drawn (the
-- Categories page's "Original" box shows the live snapshot, PC-R-04), so each line carries a
-- `glyph: data` mark, line by line rather than a folder-wide skip, the way tests/prose_waivers.lua
-- waives the dump's spellings word by word. Every authored file (core/, defaults/, locales/,
-- modules/, settings/) was already clean.

local ctx  = _G.PC_TEST
local test = ctx.test

test("glyphs: display strings use only characters every shipped skin face draws", function()
    -- red under: a ≈, →, ▼ or € (or any other character outside the kit's safe set) in a string
    -- the addon paints in a skin face, or a GlobalStrings/ line that lost its `glyph: data` mark.
    ctx.assertDisplayGlyphs{ label = "PrettyChat" }
end)
