-- tests/prose_waivers.lua -- the per-file, per-word waivers the kit's prose gate reads
-- (tests/_kit/test_prose.lua, localization-§5).
--
-- WHAT IS WAIVED, AND WHY IT IS NOT THIS REPO'S ENGLISH TO CORRECT. Every entry below is inside
-- `GlobalStrings/`, the dump of Blizzard's own GlobalStrings extracted from the client
-- (`GlobalStrings/GlobalStrings.lua:1` says so) and cut into chunks by
-- `GlobalStrings/split_globalstrings.py`. The spellings are the game's English arriving whole:
-- respelling one is a hand edit the next extraction overwrites, and it would make the fixture
-- tests/test_defaults.lua reads stop matching the client it was taken from. localization-§5 names
-- "a generated dump of the client's own strings" as a spelling that MAY be waived, per FILE and per
-- WORD, and forbids a whole-file waiver -- so each file lists exactly the words the gate found in
-- it, and a NEW British spelling arriving in any of them with the next regeneration still reddens.
--
-- WHY NOT `Kit.prose = { exempt = { "GlobalStrings/" } }`. The kit offers that folder-wide
-- carve-out, and the library's own v1.55.0 CHANGELOG records it as a deviation from
-- localization-§5 until the standard takes the amendment layout-§1 already took. It is not ratified
-- in docs/ARCHITECTURE.md's register, so it is not used here.
--
-- Measured 2026-09-23 against LibKa0s v1.55.0's gate (kit revision 25): 34 lines across these ten
-- files, and nothing outside `GlobalStrings/`.
return {
    waived = {
        ["GlobalStrings/GlobalStrings.lua"] = {
            ["amongst"] = true, ["cancelled"] = true, ["grey"] = true, ["travelling"] = true,
        },
        ["GlobalStrings/GlobalStrings_009.lua"] = { ["cancelled"] = true },
        ["GlobalStrings/GlobalStrings_010.lua"] = { ["cancelled"] = true },
        ["GlobalStrings/GlobalStrings_015.lua"] = { ["cancelled"] = true },
        ["GlobalStrings/GlobalStrings_016.lua"] = { ["amongst"] = true, ["grey"] = true },
        ["GlobalStrings/GlobalStrings_018.lua"] = { ["cancelled"] = true, ["grey"] = true },
        ["GlobalStrings/GlobalStrings_019.lua"] = { ["cancelled"] = true, ["grey"] = true },
        ["GlobalStrings/GlobalStrings_022.lua"] = { ["cancelled"] = true },
        ["GlobalStrings/GlobalStrings_023.lua"] = { ["travelling"] = true },
        ["GlobalStrings/GlobalStrings_024.lua"] = { ["grey"] = true },
    },
}
