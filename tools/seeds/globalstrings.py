#!/usr/bin/env python3
"""tools/seeds/globalstrings.py — re-validate PrettyChat's GlobalStrings data against a wago.tools build.

WHAT THIS IS
    PrettyChat seeds no game ids. What it depends on from the client is UI strings: the 79
    GLOBALNAMEs in defaults/Defaults.lua, each a Blizzard format string the addon rewrites, and the
    copy of the client's GlobalStrings in GlobalStrings/GlobalStrings.lua ("AUTOMATICALLY
    GENERATED", never loaded, never shipped; docs/global-strings.md). That copy has exactly one
    reader, tests/test_defaults.lua, which checks every default's conversion sequence against
    Blizzard's real one. So the copy is a test fixture that mirrors one client build, and when it
    goes stale the fixture vouches for signatures the game no longer has.

    The source is the client's own GlobalStrings DB2 (columns BaseTag, TagText_lang, Flags). Rows
    with Flags bit 0x1 are the FrameXML strings, the set the client puts in _G and the set the copy
    holds (on Retail 12.1.5.70783 the copy's 23,840 keys plus 925 new minus 33 gone is exactly the
    build's 24,732 bit-0x1 rows). TagText_lang carries Lua escapes (`\\32`, `\\n`, `\\"`) alongside
    raw CR/LF, so a value is compared DECODED, and written back in the copy's own escape style.

    Per flavor (a client: `retail` reads product `wow`, `forever` reads `wowf`):

    Flags (key `<kind>:<GLOBALNAME>`, ruled keep or fix), over every key defaults/Defaults.lua
    depends on. This is the check that matters: a key that is gone breaks a feature.
        gone        the build has no FrameXML row for the key
        breaks      the default's conversion sequence is not a positional prefix of the build's
                    (tests/test_defaults.lua's rule, NS.SequenceIsPrefix, against this build)
        signature   the build's conversion sequence differs from the reference copy's, though the
                    default is still a prefix of it
        reworded    the build's text differs from the reference copy's, same conversions
    The reference copy is GlobalStrings/GlobalStrings.lua on both flavors: Retail's own previous
    build, and for Forever the one list docs/ARCHITECTURE.md ("Per-client features") measured as
    serving both clients.

    The copy's delta (retail only): keys the build added, keys it dropped, keys whose text changed.
    It is reported, never ruled: the copy is generated data, and a hand-pruned copy would lose
    layout-§1's generated-data exemption (docs/global-strings.md, "The cap exemption", condition
    1). So `apply` is a REGENERATION: the copy becomes the build's FrameXML rows verbatim, and the
    existing splitter (tools/split_globalstrings.py) re-cuts the chunks. Forever has no copy, so its
    `apply` writes nothing.

THE STEPS
    python3 tools/seeds/globalstrings.py status [--flavor retail|forever]
    python3 tools/seeds/globalstrings.py derive --flavor F --bundle docs/seed-research/<date>-F --date <date> [--build V] [--replay]
    python3 tools/seeds/globalstrings.py check  --bundle docs/seed-research/<date>-F
    python3 tools/seeds/globalstrings.py rule   --tsv rulings.tsv --bundle docs/seed-research/<date>-F
    python3 tools/seeds/globalstrings.py report --bundle docs/seed-research/<date>-F --date <date>
    python3 tools/seeds/globalstrings.py apply  --bundle docs/seed-research/<date>-F --date <date>

    The date is always an argument; nothing here reads the clock. `derive` pins one build (the live
    one of the flavor's product, or --build), caches the download in tools/seeds/.cache/ and freezes
    it gzipped into the bundle's raw/, so `--replay` re-derives offline. `rule` is the only writer of
    tools/seeds/<flavor>_rulings.json. `check` exits 1 while anything is unruled; `apply` refuses
    then, reads only the bundle's raw/, keeps the copy's CRLF and layout, and a second run changes
    nothing.

Python 3.8+, standard library only. The pattern is copied from AuraMaster's tools/spell-research/
retail.py, never imported across repos; whether a shared helper should carry the build pin, the
cache, the bundle and the rulings is LibKa0s#91.
"""

from __future__ import annotations

import argparse
import csv
import gzip
import json
import re
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
DUMP_PATH = REPO / "GlobalStrings" / "GlobalStrings.lua"
DEFAULTS_PATH = REPO / "defaults" / "Defaults.lua"
SPLITTER_PATH = REPO / "tools" / "split_globalstrings.py"
RESEARCH = REPO / "docs" / "seed-research"
CACHE_DIR = HERE / ".cache"

PRODUCTS = {"retail": "wow", "forever": "wowf"}
CLIENT_NAMES = {"retail": "Retail", "forever": "WoW Forever"}
TABLE = "GlobalStrings"
COLUMNS = ("BaseTag", "TagText_lang", "Flags")
FRAMEXML = 0x1
BUILDS_URL = "https://wago.tools/api/builds"
CSV_URL = "https://wago.tools/db2/{table}/csv?build={build}"
USER_AGENT = "ka0s-seed-validation"
DOWNLOAD_CHUNK = 1 << 20

# The coverage gate: keys every client has, chosen from the game rather than from this tool's
# output, plus a floor on the row count. A truncated or wrong table fails here, loudly, instead of
# reading as a plausible diff (clients-§10).
SENTINELS = ("OKAY", "CANCEL", "ACCEPT", "LOOT_ITEM_SELF", "CHAT_SAY_GET", "ERR_FRIEND_ONLINE_SS")
MIN_FRAMEXML_ROWS = 20000

BANNER = "-- AUTOMATICALLY GENERATED -- Your benefactors send their regards."
GLYPH_BEGIN = ("-- glyph: data begin (a copy of the client's own GlobalStrings, never drawn: the panel "
               "shows the live snapshot)")
GLYPH_END = "-- glyph: data end"

FLAG_KINDS = ("gone", "breaks", "signature", "reworded")
FLAG_RULINGS = ("keep", "fix")
KEY_RE = re.compile(r"^(?P<kind>[a-z]+):(?P<name>[A-Za-z0-9_]+)$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
LINE_RE = re.compile(r'^(?:(?P<plain>[A-Za-z_][A-Za-z0-9_]*)|_G\["(?P<g>[^"]+)"\])\s*=\s*"(?P<v>.*)"\s*;\s*$')
IDENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def log(message: str) -> None:
    print(message, file=sys.stderr)


# ---------------------------------------------------------------------------
# Lua string literals
# ---------------------------------------------------------------------------

_ESCAPES = {"n": "\n", "r": "\r", "t": "\t", '"': '"', "'": "'", "\\": "\\",
            "a": "\a", "b": "\b", "f": "\f", "v": "\v"}


def decode(text: str) -> str:
    """The runtime value of a Lua-escaped string: the copy's literal or a DB2 TagText_lang.

    `\\ddd` is a decimal byte, the named escapes are Lua's, and an unknown escape keeps its
    backslash (the client's `PARTY_PLAYER_CHROMIE_TIME_FMT` is `\\%s` in DB2 and `\\\\%s` in the
    copy, the same runtime string)."""
    out, i = [], 0
    while i < len(text):
        ch = text[i]
        if ch != "\\" or i + 1 == len(text):
            out.append(ch)
            i += 1
            continue
        digits = re.match(r"\d{1,3}", text[i + 1:])
        if digits:
            out.append(chr(int(digits.group(0))))
            i += 1 + len(digits.group(0))
            continue
        nxt = text[i + 1]
        out.append(_ESCAPES.get(nxt, "\\" + nxt))
        i += 2
    return "".join(out)


def encode(value: str) -> str:
    """A runtime value as the copy writes it: backslash, quote, LF and CR escaped; any other control
    character as a decimal escape (none occurs on Retail 12.1.5.70783)."""
    out = []
    for ch in value:
        if ch == "\\":
            out.append("\\\\")
        elif ch == '"':
            out.append('\\"')
        elif ch == "\n":
            out.append("\\n")
        elif ch == "\r":
            out.append("\\r")
        elif ord(ch) < 32:
            out.append("\\%03d" % ord(ch))
        else:
            out.append(ch)
    return "".join(out)


def lhs(key: str) -> str:
    """How the copy names a key: bare when it is a Lua identifier, else `_G["..."]`."""
    return key if IDENT_RE.match(key) else '_G["%s"]' % key


# ---------------------------------------------------------------------------
# Conversion sequences (a port of NS.ConversionSequence, modules/Override.lua)
# ---------------------------------------------------------------------------

CONVERSION_CLASS = dict([(c, "string") for c in "s"] + [(c, "int") for c in "diuxXoc"]
                        + [(c, "float") for c in "fgeGE"])
CONVERSION_RE = re.compile(r"%(\d*\$?)[-+ #0]*\d*\.?\d*([A-Za-z])")


def conversion_sequence(fmt: str) -> list[str]:
    """The class at each argument position, `gap` where a `%n$` list skips one."""
    seq: dict[int, str] = {}
    append_idx = 0
    for pos, ftype in CONVERSION_RE.findall(fmt.replace("%%", "")):
        if pos.endswith("$"):
            idx = int(pos[:-1]) if pos[:-1] else 0
            if idx <= 0:
                continue
        else:
            append_idx += 1
            idx = append_idx
        seq[idx] = CONVERSION_CLASS.get(ftype, "unknown:" + ftype)
    return [seq.get(i, "gap") for i in range(1, max(seq, default=0) + 1)]


def is_prefix(seq: list[str], reference: list[str]) -> bool:
    """NS.SequenceIsPrefix: never longer, never class-mismatched at a shared position."""
    return len(seq) <= len(reference) and seq == reference[:len(seq)]


# ---------------------------------------------------------------------------
# The repo's files
# ---------------------------------------------------------------------------

def read_dump(path: Path = DUMP_PATH) -> dict[str, str]:
    """`{key: decoded value}` of the copy. A line that is neither an entry, a comment nor blank is
    fatal: the regeneration would silently drop it."""
    out: dict[str, str] = {}
    for number, line in enumerate(path.read_bytes().decode("utf-8").splitlines(), 1):
        if not line.strip() or line.startswith("--"):
            continue
        match = LINE_RE.match(line)
        if not match:
            raise SystemExit("%s:%d is not a `KEY = \"...\";` entry: %r" % (path, number, line[:80]))
        out[match.group("plain") or match.group("g")] = decode(match.group("v"))
    return out


DEFAULT_ENTRY_RE = re.compile(r"^ {12}([A-Z][A-Z0-9_]*) = \{\s*$")
DEFAULT_VALUE_RE = re.compile(r'^\s+default = "(.*)",\s*$')
CATEGORY_RE = re.compile(r"^ {4}([A-Za-z]+) = \{\s*$")


def read_defaults(path: Path = DEFAULTS_PATH) -> list[dict]:
    """`[{key, category, default}]`: every GLOBALNAME defaults/Defaults.lua overrides, in file order."""
    out: list[dict] = []
    category, current = None, None
    for line in path.read_bytes().decode("utf-8").splitlines():
        cat = CATEGORY_RE.match(line)
        if cat:
            category = cat.group(1)
            continue
        entry = DEFAULT_ENTRY_RE.match(line)
        if entry:
            current = entry.group(1)
            continue
        value = DEFAULT_VALUE_RE.match(line)
        if value and current:
            out.append({"key": current, "category": category, "default": decode(value.group(1))})
            current = None
    if not out:
        raise SystemExit("%s: no `default = \"...\"` entries found; the parser and the file disagree." % path)
    return out


def glyph_data_keys(path: Path = SPLITTER_PATH) -> set[str]:
    """The splitter's GLYPH_DATA_KEYS, read from its source so the two can never disagree."""
    match = re.search(r"^GLYPH_DATA_KEYS = \{([^}]*)\}", path.read_text(encoding="utf-8"), re.M)
    if not match:
        raise SystemExit("%s: GLYPH_DATA_KEYS not found." % path)
    return set(re.findall(r'"([^"]+)"', match.group(1)))


def write_crlf(path: Path, text: str) -> None:
    """Text with CRLF terminators: .gitattributes pins `* text=auto eol=crlf` and
    tests/_kit/test_eol.lua checks every tracked file, so write the bytes git expects."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.replace("\r\n", "\n").replace("\n", "\r\n").encode("utf-8"))


def write_json(path: Path, doc) -> None:
    write_crlf(path, json.dumps(doc, indent=1, sort_keys=True, ensure_ascii=False) + "\n")


# ---------------------------------------------------------------------------
# The build
# ---------------------------------------------------------------------------

def http_get(url: str, accept: str = "*/*"):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": accept})
    return urllib.request.urlopen(req, timeout=120)


def live_build(flavor: str) -> str:
    """The newest build of the flavor's own product (wago's builds API lists newest first)."""
    data = json.load(http_get(BUILDS_URL, accept="application/json"))
    builds = data.get(PRODUCTS[flavor]) or []
    if not builds:
        raise SystemExit("The builds API returned no %r builds; pass --build." % PRODUCTS[flavor])
    return builds[0]["version"]


def fetch(build: str, cache_dir: Path = CACHE_DIR) -> Path:
    """The table's CSV for `build`, streamed into the cache once (a `.part` renamed when whole)."""
    cache_dir.mkdir(parents=True, exist_ok=True)
    dest = cache_dir / ("%s-%s.csv" % (TABLE, build))
    if dest.exists():
        log("  %s cached (%.1f MB)" % (TABLE, dest.stat().st_size / 1e6))
        return dest
    url = CSV_URL.format(table=TABLE, build=build)
    log("  %s fetching %s" % (TABLE, url))
    tmp = dest.with_suffix(".csv.part")
    with http_get(url, accept="text/csv") as response, tmp.open("wb") as handle:
        shutil.copyfileobj(response, handle, DOWNLOAD_CHUNK)
    tmp.replace(dest)
    return dest


def freeze(source: Path, member: Path) -> None:
    """Gzip `source` into the bundle, deterministically (mtime 0), so a re-freeze is byte-identical."""
    member.parent.mkdir(parents=True, exist_ok=True)
    with source.open("rb") as src, member.open("wb") as raw, \
            gzip.GzipFile(filename="", mode="wb", fileobj=raw, compresslevel=9, mtime=0) as dst:
        shutil.copyfileobj(src, dst, DOWNLOAD_CHUNK)


def read_table(path: Path) -> dict[str, str]:
    """`{BaseTag: decoded value}` of the FrameXML rows, streamed (a `.gz` is opened as one).
    Columns are addressed by header name; a missing one is fatal."""
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rt", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        missing = [c for c in COLUMNS if c not in (reader.fieldnames or ())]
        if missing:
            raise SystemExit("%s: no %s column(s); header is %s" % (path, ", ".join(missing), reader.fieldnames))
        out: dict[str, str] = {}
        for row in reader:
            if int(row["Flags"] or 0) & FRAMEXML:
                out[row["BaseTag"]] = decode(row["TagText_lang"])
    return out


def coverage_gate(strings: dict[str, str]) -> list[str]:
    """What the gate misses: sentinels absent, or too few rows. Empty means the table is whole."""
    missing = ["sentinel %s" % key for key in SENTINELS if key not in strings]
    if len(strings) < MIN_FRAMEXML_ROWS:
        missing.append("only %d FrameXML rows (floor %d)" % (len(strings), MIN_FRAMEXML_ROWS))
    return missing


# ---------------------------------------------------------------------------
# Derive
# ---------------------------------------------------------------------------

def dependency_flags(defaults: list[dict], build: dict[str, str], reference: dict[str, str]) -> tuple[list[dict], list[dict]]:
    """`(rows, flags)`: one row per dependent key, and one flag per (kind, key) it fails."""
    rows, flags = [], []
    for entry in defaults:
        key = entry["key"]
        own = conversion_sequence(entry["default"])
        ref = reference.get(key)
        now = build.get(key)
        row = {"key": key, "category": entry["category"], "default": own, "present": now is not None,
               "reference": conversion_sequence(ref) if ref is not None else None,
               "build": conversion_sequence(now) if now is not None else None}
        rows.append(row)
        kinds = []
        if now is None:
            kinds.append("gone")
        else:
            if not is_prefix(own, row["build"]):
                kinds.append("breaks")
            elif ref is not None and row["build"] != row["reference"]:
                kinds.append("signature")
            if ref is not None and now != ref and row["build"] == row["reference"]:
                kinds.append("reworded")
        for kind in kinds:
            flags.append({"key": "%s:%s" % (kind, key), "kind": kind, "name": key,
                          "category": entry["category"], "default": own, "build": row["build"],
                          "reference": row["reference"]})
    return rows, flags


def copy_delta(copy: dict[str, str], build: dict[str, str]) -> dict:
    return {"new": sorted(k for k in build if k not in copy),
            "gone": sorted(k for k in copy if k not in build),
            "changed": sorted(k for k in copy if k in build and copy[k] != build[k])}


def derive_doc(flavor: str, build_id: str, date: str, strings: dict[str, str], copy: dict[str, str],
               defaults: list[dict]) -> dict:
    missing = coverage_gate(strings)
    if missing:
        raise SystemExit("Coverage gate FAILED for %s %s: %s. Fix the fetch before ruling anything."
                         % (flavor, build_id, "; ".join(missing)))
    rows, flags = dependency_flags(defaults, strings, copy)
    doc = {"flavor": flavor, "product": PRODUCTS[flavor], "build": build_id, "date": date,
           "tool": "tools/seeds/globalstrings.py derive", "table": TABLE,
           "frameXmlRows": len(strings), "copyEntries": len(copy),
           "dependencies": rows, "flags": flags, "candidates": []}
    if flavor == "retail":
        doc["copyDelta"] = copy_delta(copy, strings)
    return doc


def format_sources(doc: dict) -> str:
    url = CSV_URL.format(table=TABLE, build=doc["build"])
    return "\n".join([
        "# Sources — GlobalStrings re-validation, %s (%s)" % (doc["date"], doc["flavor"]), "",
        "Generated by `tools/seeds/globalstrings.py derive`. Frozen: this directory is never edited",
        "after the run, apart from the hand-written `ANALYSIS.md`.", "",
        "| Field | Value |", "| --- | --- |",
        "| Client | `%s` (%s, wago product `%s`) |" % (doc["flavor"], CLIENT_NAMES[doc["flavor"]], doc["product"]),
        "| Build | `%s` |" % doc["build"],
        "| Fetched | %s (the run's date argument; the tool never reads the clock) |" % doc["date"],
        "| Builds API | <%s> |" % BUILDS_URL,
        "| FrameXML rows (Flags bit 0x1) | %d |" % doc["frameXmlRows"],
        "| Reference copy | `GlobalStrings/GlobalStrings.lua`, %d entries at derive time |" % doc["copyEntries"],
        "", "## Tables", "",
        "| Table | Why | URL |", "| --- | --- | --- |",
        "| `%s` | BaseTag, TagText_lang, Flags: the client's UI strings | <%s> |" % (TABLE, url), "",
        "The gzipped export is `raw/%s.csv.gz`. `derive --replay` re-derives from it offline." % TABLE, ""])


def format_diff(doc: dict) -> str:
    lines = ["# Diff — GlobalStrings, %s build %s against the copy" % (doc["flavor"], doc["build"]), "",
             "Generated by `tools/seeds/globalstrings.py derive`. Keys only: the values are in",
             "`raw/%s.csv.gz` and, after `apply`, in `GlobalStrings/GlobalStrings.lua`." % TABLE, ""]
    rows = doc["dependencies"]
    lines += ["## Dependent keys — %d" % len(rows), "",
              "The GLOBALNAMEs `defaults/Defaults.lua` overrides. %d present on the build, %d flagged."
              % (sum(1 for r in rows if r["present"]), len({f["name"] for f in doc["flags"]})), ""]
    delta = doc.get("copyDelta")
    if delta is None:
        lines += ["No copy delta: %s has no copy of its own (`docs/ARCHITECTURE.md`, Per-client"
                  % CLIENT_NAMES[doc["flavor"]], "features). Only the dependent keys are checked.", ""]
        return "\n".join(lines)
    for title in ("new", "gone", "changed"):
        keys = delta[title]
        lines += ["## %s — %d" % (title.capitalize(), len(keys)), ""]
        lines += ["- `%s`" % k for k in keys] or ["None."]
        lines.append("")
    return "\n".join(lines)


def bundle_build(bundle: Path) -> str:
    return json.loads((bundle / "candidates.json").read_text(encoding="utf-8"))["build"]


def flavor_bundles(flavor: str, root: Path = RESEARCH) -> list[Path]:
    """Every bundle of the flavor that holds a candidates.json, oldest first (dates sort by name)."""
    return sorted(p for p in root.glob("*-" + flavor) if (p / "candidates.json").exists())


def status_line(live: str, bundles: list[Path]) -> str:
    """`CURRENT <build> (<bundle>)` or `NEW <build> ...`; the first word is what
    /dev-copilot:validate-seeds reads."""
    if not bundles:
        return "NEW %s (no bundle yet)" % live
    built = bundle_build(bundles[-1])
    if built == live:
        return "CURRENT %s (%s)" % (live, bundles[-1].name)
    return "NEW %s (last ruled %s, %s)" % (live, built, bundles[-1].name)


# ---------------------------------------------------------------------------
# Rulings
# ---------------------------------------------------------------------------

def rulings_path(flavor: str, base: Path = HERE) -> Path:
    return base / ("%s_rulings.json" % flavor)


def load_rulings(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}


def save_rulings(path: Path, rulings: dict) -> None:
    write_crlf(path, json.dumps(rulings, indent=2, sort_keys=True, ensure_ascii=False) + "\n")


def set_ruling(rulings: dict, key: str, ruling: str, reason: str) -> None:
    match = KEY_RE.match(key)
    if not match or match.group("kind") not in FLAG_KINDS:
        raise SystemExit("%r is not <kind>:<GLOBALNAME> with kind one of %s." % (key, ", ".join(FLAG_KINDS)))
    if ruling not in FLAG_RULINGS:
        raise SystemExit("the ruling for %s must be %s; got %r." % (key, " or ".join(FLAG_RULINGS), ruling))
    reason = (reason or "").strip()
    if not reason or "\n" in reason:
        raise SystemExit("the reason for %s must be one non-empty line." % key)
    rulings[key] = {"ruling": ruling, "reason": reason}


def read_tsv(path: Path) -> list[tuple[str, str, str]]:
    out = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) != 3:
            raise SystemExit("%s: a ruling line is key<TAB>ruling<TAB>reason; got %r" % (path, line))
        out.append((parts[0].strip(), parts[1].strip(), parts[2].strip()))
    return out


def unruled_keys(doc: dict, rulings: dict) -> list[str]:
    return [f["key"] for f in doc["flags"] if f["key"] not in rulings]


# ---------------------------------------------------------------------------
# Apply: regenerate the copy
# ---------------------------------------------------------------------------

def render_dump(strings: dict[str, str], glyph_keys: set[str]) -> str:
    """The copy's text: the banner, a blank line, then one entry per key sorted by how the line
    names it, with the glyph-data comment pair around each GLYPH_DATA_KEYS entry."""
    lines = [BANNER, ""]
    for key in sorted(strings, key=lhs):
        entry = '%s = "%s";' % (lhs(key), encode(strings[key]))
        lines += [GLYPH_BEGIN, entry, GLYPH_END] if key in glyph_keys else [entry]
    return "\n".join(lines) + "\n"


def apply_bundle(doc: dict, rulings: dict, bundle: Path, dump: Path = DUMP_PATH,
                 splitter: Path | None = SPLITTER_PATH) -> list[str]:
    """Refuse while anything is unruled; for retail, regenerate the copy from the bundle's raw/ and
    re-run the splitter. Returns the change log (empty when the copy already matched)."""
    unruled = unruled_keys(doc, rulings)
    if unruled:
        raise SystemExit("apply refused: %d flag(s) unruled (check lists them)." % len(unruled))
    owed = [k for k in sorted(rulings) if rulings[k]["ruling"] == "fix"
            and k in {f["key"] for f in doc["flags"]}]
    changes = ["owed (ruled fix, defaults/Defaults.lua): %s" % k for k in owed]
    if doc["flavor"] != "retail":
        changes.append("nothing to write: %s has no copy of its own" % CLIENT_NAMES[doc["flavor"]])
        return changes
    strings = read_table(bundle / "raw" / ("%s.csv.gz" % TABLE))
    if coverage_gate(strings):
        raise SystemExit("apply refused: %s/raw fails the coverage gate." % bundle)
    text = render_dump(strings, glyph_data_keys(splitter or SPLITTER_PATH))
    before = dump.read_bytes() if dump.exists() else b""
    write_crlf(dump, text)
    if dump.read_bytes() != before:
        delta = doc.get("copyDelta") or {}
        changes.append("%s regenerated from %s: +%d new, -%d gone, %d changed" % (
            dump.name, doc["build"], len(delta.get("new", ())), len(delta.get("gone", ())),
            len(delta.get("changed", ()))))
    if splitter is not None:
        result = subprocess.run([sys.executable, str(splitter)], capture_output=True, text=True)
        if result.returncode != 0:
            raise SystemExit("the splitter failed:\n%s%s" % (result.stdout, result.stderr))
        log(result.stdout.strip().splitlines()[-2] if result.stdout.strip() else "splitter ran")
    return changes


# ---------------------------------------------------------------------------
# RULINGS.md
# ---------------------------------------------------------------------------

def _seq(seq) -> str:
    return "-" if seq is None else "[%s]" % ",".join(seq)


def format_rulings(doc: dict, rulings: dict, date: str) -> str:
    flags = doc["flags"]
    unruled = unruled_keys(doc, rulings)
    lines = ["# Rulings — GlobalStrings re-validation, %s %s (build %s)" % (doc["flavor"], doc["date"], doc["build"]), "",
             "Generated by `tools/seeds/globalstrings.py report` on %s from this bundle's `candidates.json`" % date,
             "and `tools/seeds/%s_rulings.json`. Do not edit by hand." % doc["flavor"], "",
             "%d dependent keys checked, %d present, %d flags, %d unruled." % (
                 len(doc["dependencies"]), sum(1 for r in doc["dependencies"] if r["present"]), len(flags), len(unruled)), ""]
    lines += ["## Flags — %d" % len(flags), ""]
    if flags:
        lines += ["| Kind | Key | Category | Default | Build | Reference | Ruling | Reason |",
                  "| --- | --- | --- | --- | --- | --- | --- | --- |"]
        for f in flags:
            r = rulings.get(f["key"], {})
            lines.append("| %s | `%s` | %s | %s | %s | %s | %s | %s |" % (
                f["kind"], f["name"], f["category"], _seq(f["default"]), _seq(f["build"]), _seq(f["reference"]),
                r.get("ruling", "**unruled**"), (r.get("reason", "")).replace("|", "\\|")))
    else:
        lines.append("None: every dependent key is on the build with the reference copy's text.")
    lines.append("")
    delta = doc.get("copyDelta")
    lines += ["## The copy", ""]
    if delta is None:
        lines.append("%s has no copy; nothing is regenerated." % CLIENT_NAMES[doc["flavor"]])
    else:
        lines += ["Regenerated by `apply`, never ruled key by key (`docs/validate-seeds.md`, Rules): "
                  "%d new, %d gone, %d changed. The keys are in `DIFF.md`."
                  % (len(delta["new"]), len(delta["gone"]), len(delta["changed"]))]
    lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def _date(value: str) -> str:
    if not DATE_RE.match(value):
        raise argparse.ArgumentTypeError("a date is YYYY-MM-DD; got %r" % value)
    return value


def load_doc(bundle: Path) -> dict:
    path = bundle / "candidates.json"
    if not path.exists():
        raise SystemExit("%s has no candidates.json: run derive first." % bundle)
    return json.loads(path.read_text(encoding="utf-8"))


def cmd_status(args) -> int:
    for flavor in ([args.flavor] if args.flavor else list(PRODUCTS)):
        line = status_line(live_build(flavor), flavor_bundles(flavor, args.root))
        print(line if args.flavor else "%s: %s" % (flavor, line))
    return 0


def cmd_derive(args) -> int:
    member = args.bundle / "raw" / ("%s.csv.gz" % TABLE)
    if args.replay:
        if not member.exists():
            raise SystemExit("--replay: %s is missing; derive once without --replay." % member)
        build_id = args.build or bundle_build(args.bundle)
    else:
        build_id = args.build or live_build(args.flavor)
        log("Pinned %s build %s" % (PRODUCTS[args.flavor], build_id))
        freeze(fetch(build_id, args.cache_dir), member)
    doc = derive_doc(args.flavor, build_id, args.date, read_table(member), read_dump(args.dump),
                     read_defaults(args.defaults))
    write_json(args.bundle / "candidates.json", doc)
    write_crlf(args.bundle / "SOURCES.md", format_sources(doc))
    write_crlf(args.bundle / "DIFF.md", format_diff(doc))
    unruled = unruled_keys(doc, load_rulings(args.rulings or rulings_path(args.flavor)))
    delta = doc.get("copyDelta")
    if delta:
        log("copy delta: %d new, %d gone, %d changed" % (len(delta["new"]), len(delta["gone"]), len(delta["changed"])))
    log("%d dependent keys, %d flags, %d unruled; %d FrameXML rows on %s"
        % (len(doc["dependencies"]), len(doc["flags"]), len(unruled), doc["frameXmlRows"], build_id))
    return 0


def cmd_rule(args) -> int:
    todo = [(k, args.ruling, args.reason) for k in (args.key or ())]
    if args.tsv:
        todo += read_tsv(args.tsv)
    if not todo:
        raise SystemExit("rule needs --key (with --ruling and --reason) or --tsv.")
    doc = load_doc(args.bundle)
    known = {f["key"] for f in doc["flags"]}
    path = args.rulings or rulings_path(doc["flavor"])
    rulings = load_rulings(path)
    for key, ruling, reason in todo:
        if key not in known:
            raise SystemExit("%s is not a flag in %s/candidates.json." % (key, args.bundle))
        set_ruling(rulings, key, ruling, reason)
    save_rulings(path, rulings)
    log("Recorded %d ruling(s) in %s" % (len(todo), path))
    return 0


def cmd_check(args) -> int:
    doc = load_doc(args.bundle)
    unruled = unruled_keys(doc, load_rulings(args.rulings or rulings_path(doc["flavor"])))
    if not unruled:
        print("OK: every flag in %s is ruled (%d)." % (args.bundle.name, len(doc["flags"])))
        return 0
    print("%d unruled:" % len(unruled))
    for flag in doc["flags"]:
        if flag["key"] in unruled:
            print("  %s  %s  default %s, build %s, reference %s" % (
                flag["key"], flag["category"], _seq(flag["default"]), _seq(flag["build"]), _seq(flag["reference"])))
    return 1


def cmd_report(args) -> int:
    doc = load_doc(args.bundle)
    rulings = load_rulings(args.rulings or rulings_path(doc["flavor"]))
    write_crlf(args.bundle / "RULINGS.md", format_rulings(doc, rulings, args.date))
    log("Wrote %s" % (args.bundle / "RULINGS.md"))
    return 0


def cmd_apply(args) -> int:
    doc = load_doc(args.bundle)
    rulings = load_rulings(args.rulings or rulings_path(doc["flavor"]))
    changes = apply_bundle(doc, rulings, args.bundle, args.dump, None if args.no_split else SPLITTER_PATH)
    for line in changes:
        log("  " + line)
    log("%d change(s)" % len(changes))
    return 0


def parse_args(argv):
    parser = argparse.ArgumentParser(description="Re-validate PrettyChat's GlobalStrings data against a wago.tools build.",
                                     epilog="See docs/validate-seeds.md.")
    parser.add_argument("--rulings", type=Path, default=None, help="the rulings file (default: per flavor)")
    parser.add_argument("--dump", type=Path, default=DUMP_PATH, help="the copy")
    parser.add_argument("--defaults", type=Path, default=DEFAULTS_PATH, help="defaults/Defaults.lua")
    parser.add_argument("--cache-dir", type=Path, default=CACHE_DIR)
    sub = parser.add_subparsers(dest="command", required=True)
    status = sub.add_parser("status", help="is there a live build newer than the newest bundle?")
    status.add_argument("--flavor", choices=sorted(PRODUCTS))
    status.add_argument("--root", type=Path, default=RESEARCH)
    derive = sub.add_parser("derive", help="freeze a build and write candidates.json, SOURCES.md, DIFF.md")
    derive.add_argument("--flavor", choices=sorted(PRODUCTS), required=True)
    derive.add_argument("--bundle", type=Path, required=True)
    derive.add_argument("--date", type=_date, required=True)
    derive.add_argument("--build", default=None, help="pin this build instead of the live one")
    derive.add_argument("--replay", action="store_true", help="read only the bundle's raw/, no network")
    rule = sub.add_parser("rule", help="record rulings (the only writer of the rulings file)")
    rule.add_argument("--bundle", type=Path, required=True)
    rule.add_argument("--key", action="append")
    rule.add_argument("--ruling")
    rule.add_argument("--reason")
    rule.add_argument("--tsv", type=Path, help="key<TAB>ruling<TAB>reason lines")
    check = sub.add_parser("check", help="exit 1 while anything is unruled")
    check.add_argument("--bundle", type=Path, required=True)
    for name, helptext in (("report", "write the bundle's RULINGS.md"),
                           ("apply", "regenerate the copy (retail) once everything is ruled")):
        cmd = sub.add_parser(name, help=helptext)
        cmd.add_argument("--bundle", type=Path, required=True)
        cmd.add_argument("--date", type=_date, required=True)
        if name == "apply":
            cmd.add_argument("--no-split", action="store_true", help="skip re-running the splitter")
    return parser.parse_args(argv)


def main(argv=None) -> int:
    args = parse_args(argv)
    return {"status": cmd_status, "derive": cmd_derive, "rule": cmd_rule, "check": cmd_check,
            "report": cmd_report, "apply": cmd_apply}[args.command](args)


if __name__ == "__main__":
    sys.exit(main())
