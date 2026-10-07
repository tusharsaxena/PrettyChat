# GlobalStrings sub-tree

`GlobalStrings/` holds a copy of Blizzard's `GlobalStrings.lua` (~22,879 entries), split into 26 chunk files, each a contiguous alphabetical range of keys. Each chunk assigns into an addon-private `NS.GlobalStrings` table (`local _, NS = ...; NS.GlobalStrings = NS.GlobalStrings or {}` — no `_G` global is created; PC-14).

## Nothing loads these chunks at runtime (PC-R-05)

**`PrettyChat.toc` carries no `GlobalStrings\` line and no `# GlobalStrings` section.** The folder is not shipped either — `.pkgmeta` ignores it whole.

It used to be loaded eagerly at addon startup, to serve one reader: the settings panel's "Original Format String" box. That box now reads **this client's `OnEnable` snapshot** through `NS.OriginalFormat`, the same source `/pc test` uses (PC-R-04) — which is not merely cheaper but more correct, since the snapshot is what the running client loaded while the dump is a build artifact of whichever patch it was cut from. With its last reader gone, the eager load was 1.89 MB and 22,879 entries parsed at every login to answer zero lookups, and `performance-§9` is unambiguous about that.

Measured on the repo's own toolchain (`lua5.1`, mean of five cold runs): **24.3 ms to compile the 26 chunks, 2.1 ms to execute them, 26.4 ms total, plus ~1.25 MB resident.** The client's Lua is the same 5.1, so treat that as the order of magnitude rather than the exact figure. What the addon's own files cost the parser at login fell from 2.01 MB across 43 files to 123 KB across 17. The full table is in [performance-sweep.md](./performance-sweep.md).

What remains is **repo-local reference data**. `tests/test_defaults.lua` loads the chunks directly, with `loadfile`, to assert that every override's conversion sequence is a positional prefix of Blizzard's — the check that catches a default asking for an argument the game does not pass. That is the only consumer, and it is a test.

Historically there was a third path: `GlobalStrings/GlobalStrings.toc`, a `LoadOnDemand: 1` sub-addon (`PrettyChat - GlobalStrings`). Nothing ever called `C_AddOns.LoadAddOn("GlobalStrings")`, and it was broken as written — after PC-14 the chunks key off `...`, so under the sub-addon they would have populated **that sub-addon's** private table rather than PrettyChat's. It was removed rather than left as a fallback that could not work.

**Do not re-add the TOC block.** `tools/split_globalstrings.py` used to rewrite it and now asserts its absence instead, exiting non-zero if a `# GlobalStrings` section or a `GlobalStrings\…` line reappears. If a real runtime consumer ever comes back, change that check and this section together.

## Files

| Path | Purpose |
|------|---------|
| `GlobalStrings/GlobalStrings.lua` | Full Blizzard reference (~1.6 MB, source file). Input to `tools/split_globalstrings.py`. |
| `GlobalStrings/GlobalStrings_001.lua` … `_026.lua` | Chunk files, each a contiguous alphabetical range of keys. Each emits `NS.GlobalStrings["KEY"] = "value"` assignments. **Not in the TOC, not in the shipped zip** — read only by `tests/test_defaults.lua`. |
| `tools/split_globalstrings.py` | Splitter script — re-run after a WoW patch. It lives under `tools/` (`layout-§1`, "Where an authored generator lives") and reads and writes `GlobalStrings/` by repo-root path. |
| `GlobalStrings/README.md` | Splitter usage instructions. |

## The `NS.GlobalStrings` table

Keyed by Blizzard's `GLOBALNAME` constants, valued with the Blizzard-default format string as of the client patch the dump was cut from. **It is not built at runtime any more** — only inside `tests/test_defaults.lua`, which loads the chunks into a local table of its own.

At runtime the equivalent data is `addon.originalStrings`, snapshotted from `_G` at `OnEnable`. It covers only the 79 keys `NS.Defaults` mentions, which is every key any surface draws: the panel builds one block per `NS.Defaults` entry and `/pc test` prints one row per entry. The old argument for the full 22,879 was that a key added to `defaults/Defaults.lua` since the last ship would still resolve — but a key can only reach `NS.Defaults` by editing a file, which needs a `/reload`, after which the snapshot covers it too. The load-time nature of the snapshot is recorded under Known Limitations in [ARCHITECTURE.md](./ARCHITECTURE.md).

## Regenerating chunks after a WoW patch

When Blizzard ships a new client (TWW patch, Midnight feature drop, etc.) the `GlobalStrings.lua` reference may add / rename / remove entries. To resync:

1. Drop the new `GlobalStrings.lua` into `GlobalStrings/`. Source: [townlong-yak.com](https://www.townlong-yak.com/framexml/live/Helix/GlobalStrings.lua).
2. From the project root: `python3 tools/split_globalstrings.py`.

The script:

1. Parses the source for `KEY = "value";` entries (ignoring `_G["KEY"]` forms).
2. Cuts the sorted entries into the fewest even chunks that all fit under `MAX_ENTRIES_PER_CHUNK` (900 entries, so 902 lines — under `layout-§1`'s 1000-LOC on-notice band, not merely under its 1500-LOC cap).
3. Cleans up old `GlobalStrings_*.lua` files.
4. Writes the new chunk files as `NS.GlobalStrings["KEY"] = "value"` assignments.
5. Fails loudly if a chunk would exceed the cap, and **asserts `PrettyChat.toc` still does not load the chunks** (PC-R-05), exiting non-zero if the block has come back.

After regenerating, run `lua tests/run.lua` — `tests/test_defaults.lua` is what reads the chunks, so a re-split that changed a Blizzard signature shows up there rather than in game. If a Blizzard format-string signature changed (e.g. `%s` → `%2$s`), the corresponding `NS.Defaults` entry in `defaults/Defaults.lua` needs updating to match — see [common-tasks.md](./common-tasks.md#fix-a-broken-format-string). Run the full [smoke-test suite](./smoke-tests.md) — a client patch can shift behavior anywhere in the override pipeline, not just in the keys you re-split.

## The cap exemption

`GlobalStrings/GlobalStrings.lua` (23,842 lines) is the one tracked `.lua` file over `layout-§1`'s 1500-line cap. The census in [ARCHITECTURE.md](./ARCHITECTURE.md#files-over-the-1500-line-cap) records it as `exempt` under the generated-data carve-out; this section is the reasoning behind that row.

**The exemption is earned condition by condition, and each condition is one line somebody could
delete for an unrelated reason.** `layout-§1` grants it only when **all three** hold:

1. **Generated, and saying so.** `GlobalStrings/GlobalStrings.lua:1` reads
   `-- AUTOMATICALLY GENERATED -- Your benefactors send their regards.` It is an extraction from
   the client, and the next extraction overwrites any hand edit wholesale.
2. **Nothing loads it.** `PrettyChat.toc` carries no `GlobalStrings\` line and has not since
   PC-R-05, and the headless harness derives its file list from that same TOC, so one absence
   answers for the client and for the suite. `tests/test_defaults.lua` reading the chunks through
   `loadfile` is a fixture being read as data, which the rule names explicitly as still qualifying.
3. **`.pkgmeta`-ignored.** The `- GlobalStrings` entry drops the whole folder from the packaged
   zip, so no player downloads a byte of it.

**Re-checked against the generator's move to `tools/` (2026-09-24, `PC-83`).** The
splitter left `GlobalStrings/` for `tools/split_globalstrings.py`, as `layout-§1`'s "Where an
authored generator lives" requires, and all three conditions still hold because only the program
moved. The dump's banner (condition 1) is unchanged, and the dump is still the client extraction,
not the script's output. The TOC still names neither folder (condition 2), and the script is
Python, so the harness's TOC-derived load list could not reach it anyway. The `- GlobalStrings`
entry still covers the dump and the chunks (condition 3), and a separate `- tools` entry covers the
generator, which the same rule makes `.pkgmeta`-ignored in its own right. The generator is
authored, so the cap binds it like any other file; at under 250 lines it is nowhere near.

A file failing any one of the three "is an ordinary source file with an unusual origin, and the cap
binds it". **What the gate checks, and what it leaves to a reader.** Since LibKa0s v1.55.0 the cap
gate is the kit's (`tests/_kit/test_layout_cap.lua`, declared by the pair in `tests/run.lua`), and it
cannot read any of the three conditions — they are facts about the repository, not properties a
path betrays (`layout-§1`). So the exempt set arrives through `Kit.layoutCap.exempt`, and the gate
asserts only that the ARCHITECTURE.md census table and that set agree about which paths were exempted: a row marked
`exempt` must name a path in the set, and an over-cap path in the set must be marked `exempt` or
absent from that census, never given a terminal state. Whether the exemption is *legitimate* is the auditor's
call. Until that revision this repository ran a hand-written gate that re-derived all three
conditions from the TOC, `.pkgmeta` and the banner on every run; it was retired rather than wired
beside the kit's, because `testing-§9` reports the two as a collision. Nothing in the suite now
re-derives the banner or the TOC and `.pkgmeta` conditions for this folder, so a TOC line added back
or the `.pkgmeta` entry tidied away would reach an audit before it reached a red run.

## Why split into chunks?

Two reasons, and they set two different limits.

WoW will refuse to load a Lua file beyond a certain size threshold (the exact limit varies by client version; `GlobalStrings.lua` at ~1.6 MB has historically been over). Any split fixes that. This no longer binds, since no chunk is loaded by the client at all — but the split is kept because `layout-§1`'s LOC cap still applies to a repo file.

The *chunk size* is set by `layout-§1`'s 1500-LOC cap, which the shipped chunks used to break — eight of the ten ran 2176–3285 lines (deviation **PC-49**). Splitting by first letter cannot fix that: `S` alone is 3283 entries, and `E`, `C`, `P` and `B` are each over a 900-line budget too, so any scheme that keeps a letter whole ships an oversized file. The splitter therefore cuts by entry count. Because the source is sorted by key, each chunk is still a contiguous alphabetical range, which is what made the letter split readable in the first place.

Keys do move between chunks when the entry count changes, so a re-split after a WoW patch produces a wider diff than the old scheme did. That is the cost of the cap; the chunk boundaries are load-bearing for nothing, since every chunk only assigns into the same `NS.GlobalStrings` table.
