"""Tests for tools/seeds/globalstrings.py (no network).

The unit cases work on fixtures/GlobalStrings-tiny.csv and a tiny copy and defaults file in a temp
dir. The repo cases at the end read the real GlobalStrings/GlobalStrings.lua, defaults/Defaults.lua
and the newest bundles, so a hand edit of the copy, a parser that drifts from the copy's layout, or a
flag left unruled fails here.

Mutation-checked (2026-11-15): deleting the `if unruled: raise SystemExit(...)` guard in
apply_bundle turns test_apply_refuses_while_unruled red; restoring it turns it green.
"""

from __future__ import annotations

import gzip
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

import globalstrings as g  # noqa: E402

FIXTURE = HERE / "fixtures" / "GlobalStrings-tiny.csv"

COPY = "\n".join([
    g.BANNER, "",
    'ACCEPT = "Accept";',
    'CANCEL = "Cancel";',
    'CHAT_SAY_GET = "%s says: ";',
    'GONE_STRING = "Dropped by the build";',
    'LOOT_ITEM = "%s receives loot: %s.";',
    'LOOT_ITEM_MULTIPLE = "%s receives loot: %sx%d.";',
    'LOOT_ITEM_SELF = "You receive loot: %s";',
    'OKAY = "Okay";',
    'OLD_DEFAULT = "%s";',
    "",
])

DEFAULTS = """local _, NS = ...
NS.Defaults = {
    Loot = {
        enabled = true,
        strings = {
            LOOT_ITEM = {
                order = 1,
                label = "Item Looted (Other)",
                default = "|cffff0000Loot|r %s + %s",
            },
            LOOT_ITEM_MULTIPLE = {
                order = 2,
                label = "Item Looted Multiple (Other)",
                default = "%s + %sx%d",
            },
            LOOT_ITEM_SELF = {
                order = 3,
                label = "Item Looted (Self)",
                default = "You + %s",
            },
            OLD_DEFAULT = {
                order = 4,
                label = "Gone",
                default = "%s",
            },
        },
    },
}
"""


class Sandbox:
    """A temp dir holding a copy, a defaults file, a bundle with the fixture frozen into raw/."""

    def __init__(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        self.dump = self.root / "GlobalStrings.lua"
        g.write_crlf(self.dump, COPY)
        self.defaults = self.root / "Defaults.lua"
        self.defaults.write_text(DEFAULTS, encoding="utf-8")
        self.bundle = self.root / "2026-11-15-retail"
        g.freeze(FIXTURE, self.bundle / "raw" / "GlobalStrings.csv.gz")
        self.rulings = self.root / "retail_rulings.json"

    def derive(self, flavor="retail"):
        strings = g.read_table(self.bundle / "raw" / "GlobalStrings.csv.gz")
        return g.derive_doc(flavor, "1.0.0.1", "2026-11-15", strings, g.read_dump(self.dump),
                            g.read_defaults(self.defaults))

    def close(self):
        self._tmp.cleanup()


class Floor(unittest.TestCase):
    """The fixture is tiny, so the row floor is lowered for the unit cases and restored after."""

    def setUp(self):
        self._floor = g.MIN_FRAMEXML_ROWS
        g.MIN_FRAMEXML_ROWS = 1
        self.box = Sandbox()

    def tearDown(self):
        g.MIN_FRAMEXML_ROWS = self._floor
        self.box.close()


class TestCodec(unittest.TestCase):
    def test_decode_handles_db2_and_copy_escapes(self):
        self.assertEqual(g.decode("%s says:\\32"), "%s says: ")
        self.assertEqual(g.decode('Abandon \\"%s\\"?'), 'Abandon "%s"?')
        self.assertEqual(g.decode("a\\nb\\r\\n"), "a\nb\r\n")
        self.assertEqual(g.decode("%s\\n\\n\\%s"), "%s\n\n\\%s", "an unknown escape keeps its backslash")
        self.assertEqual(g.decode("%s\\n\\n\\\\%s"), "%s\n\n\\%s", "and equals the copy's spelling")

    def test_encode_is_the_copy_style_and_round_trips(self):
        value = 'Say "hi"\r\n\\ and \x15'
        self.assertEqual(g.encode(value), 'Say \\"hi\\"\\r\\n\\\\ and \\021')
        self.assertEqual(g.decode(g.encode(value)), value)

    def test_lhs_uses_G_for_non_identifiers(self):
        self.assertEqual(g.lhs("OKAY"), "OKAY")
        self.assertEqual(g.lhs("90POA_BOSS_01"), '_G["90POA_BOSS_01"]')


class TestConversions(unittest.TestCase):
    def test_sequence(self):
        self.assertEqual(g.conversion_sequence("%s x%d"), ["string", "int"])
        self.assertEqual(g.conversion_sequence("%2$s %1$d"), ["int", "string"])
        self.assertEqual(g.conversion_sequence("100%% %s"), ["string"])
        self.assertEqual(g.conversion_sequence("%3$s"), ["gap", "gap", "string"])
        self.assertEqual(g.conversion_sequence("%.1f%%"), ["float"])
        self.assertEqual(g.conversion_sequence("none"), [])

    def test_prefix(self):
        self.assertTrue(g.is_prefix(["string"], ["string", "string"]))
        self.assertTrue(g.is_prefix([], ["string"]))
        self.assertFalse(g.is_prefix(["string", "int"], ["string"]))
        self.assertFalse(g.is_prefix(["int"], ["string"]))


class TestDerive(Floor):
    def test_table_keeps_framexml_rows_only(self):
        strings = g.read_table(self.box.bundle / "raw" / "GlobalStrings.csv.gz")
        self.assertNotIn("GLUE_ONLY", strings)
        self.assertEqual(strings["NEW_STRING"], 'Say "hi"')
        self.assertEqual(strings["CHAT_SAY_GET"], "%s says: ")

    def test_missing_column_is_fatal(self):
        bad = self.box.root / "bad.csv"
        bad.write_text("ID,BaseTag,Text\n1,OKAY,Okay\n", encoding="utf-8")
        with self.assertRaises(SystemExit):
            g.read_table(bad)

    def test_coverage_gate_fails_loudly(self):
        g.MIN_FRAMEXML_ROWS = 10 ** 6
        with self.assertRaises(SystemExit) as caught:
            self.box.derive()
        self.assertIn("Coverage gate FAILED", str(caught.exception))

    def test_flags_on_dependent_keys(self):
        doc = self.box.derive()
        kinds = {f["key"] for f in doc["flags"]}
        self.assertEqual(kinds, {"gone:OLD_DEFAULT", "breaks:LOOT_ITEM", "reworded:LOOT_ITEM_SELF"})
        multiple = [r for r in doc["dependencies"] if r["key"] == "LOOT_ITEM_MULTIPLE"][0]
        self.assertEqual(multiple["build"], ["string", "string", "int"])

    def test_signature_flag_when_the_default_stays_a_prefix(self):
        g.write_crlf(self.box.dump, COPY.replace('"%s receives loot: %s.";', '"%s receives loot.";'))
        g.write_crlf(self.box.defaults, DEFAULTS.replace("|cffff0000Loot|r %s + %s", "%s"))
        doc = self.box.derive()
        self.assertIn("signature:LOOT_ITEM", {f["key"] for f in doc["flags"]})

    def test_copy_delta(self):
        delta = self.box.derive()["copyDelta"]
        self.assertIn("NEW_STRING", delta["new"])
        self.assertIn("90POA_BOSS_01", delta["new"])
        self.assertEqual(delta["gone"], ["GONE_STRING", "OLD_DEFAULT"])
        self.assertIn("LOOT_ITEM_SELF", delta["changed"])
        self.assertNotIn("CHAT_SAY_GET", delta["changed"], "`\\32` and a trailing space are one value")

    def test_forever_has_no_copy_delta(self):
        self.assertNotIn("copyDelta", self.box.derive("forever"))


class TestRulings(Floor):
    def test_set_ruling_validates(self):
        rulings = {}
        g.set_ruling(rulings, "gone:OLD_DEFAULT", "fix", "the row needs removing")
        self.assertEqual(rulings["gone:OLD_DEFAULT"]["ruling"], "fix")
        for key, ruling, reason in (("nope:OLD_DEFAULT", "keep", "x"), ("gone:OLD_DEFAULT", "accept", "x"),
                                    ("gone:OLD_DEFAULT", "keep", ""), ("gone:OLD_DEFAULT", "keep", "a\nb")):
            with self.assertRaises(SystemExit):
                g.set_ruling({}, key, ruling, reason)

    def test_check_and_rule_through_main(self):
        g.write_json(self.box.bundle / "candidates.json", self.box.derive())
        common = ["--rulings", str(self.box.rulings)]
        self.assertEqual(g.main(common + ["check", "--bundle", str(self.box.bundle)]), 1)
        tsv = self.box.root / "r.tsv"
        tsv.write_text("gone:OLD_DEFAULT\tfix\tremove the row\n"
                       "breaks:LOOT_ITEM\tfix\tthe build passes a number second\n"
                       "reworded:LOOT_ITEM_SELF\tkeep\tsame conversions\n", encoding="utf-8")
        g.main(common + ["rule", "--tsv", str(tsv), "--bundle", str(self.box.bundle)])
        self.assertEqual(g.main(common + ["check", "--bundle", str(self.box.bundle)]), 0)
        self.assertIn(b"\r\n", self.box.rulings.read_bytes(), "the rulings file is CRLF")

    def test_rule_refuses_a_key_the_bundle_lacks(self):
        g.write_json(self.box.bundle / "candidates.json", self.box.derive())
        with self.assertRaises(SystemExit):
            g.main(["--rulings", str(self.box.rulings), "rule", "--bundle", str(self.box.bundle),
                    "--key", "gone:OKAY", "--ruling", "keep", "--reason", "x"])


class TestApply(Floor):
    def test_apply_refuses_while_unruled(self):
        doc = self.box.derive()
        before = self.box.dump.read_bytes()
        with self.assertRaises(SystemExit) as caught:
            g.apply_bundle(doc, {}, self.box.bundle, self.box.dump, splitter=None)
        self.assertIn("refused", str(caught.exception))
        self.assertEqual(self.box.dump.read_bytes(), before, "a refused apply writes nothing")

    def _ruled(self, doc):
        return {f["key"]: {"ruling": "keep", "reason": "test"} for f in doc["flags"]}

    def test_apply_regenerates_and_is_idempotent(self):
        doc = self.box.derive()
        changes = g.apply_bundle(doc, self._ruled(doc), self.box.bundle, self.box.dump, splitter=None)
        self.assertTrue(any("regenerated" in c for c in changes))
        raw = self.box.dump.read_bytes()
        self.assertEqual(raw.count(b"\r\n"), raw.count(b"\n"), "every line ends CRLF")
        text = raw.decode("utf-8").split("\r\n")
        self.assertEqual(text[0], g.BANNER)
        self.assertIn('_G["90POA_BOSS_01"] = "Kalisthene";', text)
        self.assertIn('NEW_STRING = "Say \\"hi\\"";', text)
        self.assertIn('CHAT_SAY_GET = "%s says: ";', text)
        self.assertIn('PARTY_PLAYER_CHROMIE_TIME_FMT = "%s\\n\\n\\\\%s";', text)
        euro = text.index('BLIZZARD_STORE_CURRENCY_FORMAT_EURO = "€%s";')
        self.assertEqual((text[euro - 1], text[euro + 1]), (g.GLYPH_BEGIN, g.GLYPH_END))
        self.assertNotIn("GLUE_ONLY", raw.decode("utf-8"))
        entries = [line.split(" = ", 1)[0] for line in text[2:] if line and not line.startswith("--")]
        self.assertEqual(entries, sorted(entries))
        again = g.apply_bundle(doc, self._ruled(doc), self.box.bundle, self.box.dump, splitter=None)
        self.assertFalse(any("regenerated" in c for c in again))
        self.assertEqual(self.box.dump.read_bytes(), raw)

    def test_forever_apply_writes_nothing(self):
        doc = self.box.derive("forever")
        before = self.box.dump.read_bytes()
        changes = g.apply_bundle(doc, self._ruled(doc), self.box.bundle, self.box.dump, splitter=None)
        self.assertTrue(any("nothing to write" in c for c in changes))
        self.assertEqual(self.box.dump.read_bytes(), before)


class TestRepo(unittest.TestCase):
    def test_the_copy_re_renders_byte_for_byte(self):
        """render_dump is the copy's own layout: parse it and write it back, nothing moves."""
        text = g.render_dump(g.read_dump(), g.glyph_data_keys())
        self.assertEqual(text.replace("\n", "\r\n").encode("utf-8"), g.DUMP_PATH.read_bytes())

    def test_the_prefix_port_agrees_with_test_defaults(self):
        """The Python walk finds exactly tests/test_defaults.lua's SANCTIONED_TRUNCATIONS and no
        break, so a `breaks` flag means what the Lua case would say."""
        source = (g.REPO / "tests" / "test_defaults.lua").read_text(encoding="utf-8")
        block = re.search(r"SANCTIONED_TRUNCATIONS = \{(.*?)\n\}", source, re.S).group(1)
        sanctioned = set(re.findall(r"^\s+([A-Z_]+)\s+=", block, re.M))
        copy = g.read_dump()
        truncated, broken = set(), []
        for entry in g.read_defaults():
            own, ref = g.conversion_sequence(entry["default"]), g.conversion_sequence(copy[entry["key"]])
            if not g.is_prefix(own, ref):
                broken.append(entry["key"])
            elif len(own) < len(ref):
                truncated.add(entry["key"])
        self.assertEqual(broken, [])
        self.assertEqual(truncated, sanctioned)

    def test_newest_bundles_are_ruled_and_the_copy_is_the_retail_build(self):
        for flavor in g.PRODUCTS:
            bundles = g.flavor_bundles(flavor)
            self.assertTrue(bundles, "no %s bundle under docs/seed-research/" % flavor)
            doc = json.loads((bundles[-1] / "candidates.json").read_text(encoding="utf-8"))
            self.assertEqual(g.unruled_keys(doc, g.load_rulings(g.rulings_path(flavor))), [])
        raw = g.flavor_bundles("retail")[-1] / "raw" / "GlobalStrings.csv.gz"
        with gzip.open(raw, "rb") as handle:
            self.assertTrue(handle.read(64).startswith(b"ID,BaseTag,TagText_lang,Flags"))
        self.assertEqual(g.read_dump(), g.read_table(raw),
                         "GlobalStrings/GlobalStrings.lua is the newest retail bundle's build, verbatim")


if __name__ == "__main__":
    unittest.main()
