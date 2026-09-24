# Testing

Contributor-facing verification guide. (Player-facing docs live in the root [README](../README.md); this content was moved out of the README under the Ka0s Standard v2.1.0, which keeps the README player-only.)

## Headless harness

PrettyChat runs on the **shared LibKa0s test kit** (testing-§1), vendored whole to `tests/_kit/` and never edited there. The kit owns the case registry, the assertions, the runner, the `--list` renderer, the sandboxed source loader and the TOC reader; what stays in this repo is the instance factory, the mock extender and the suite list.

It runs under stock Lua 5.1 with no WoW client, loading the vendored library files and then the addon's own sources into a mock WoW environment, and exercises constants, string helpers, locale manifest, defaults data, schema, sample renderer, apply pipeline and override engine, migration runner, addon lifecycle, debug console, slash dispatcher, settings panel — and the six LibKa0s seams.

```sh
lua tests/run.lua          # run every suite (exits non-zero on failure)
lua tests/run.lua --list   # print the test-case inventory (runs nothing)
luacheck .                 # static analysis (config in .luacheckrc)
```

## How the harness works

```
tests/
  _kit/              -- VENDORED, never edited: framework.lua, loader.lua, mock_base.lua,
                     --                          mock_record.lua, mock_ids.lua, vendor_sync.lua,
                     --                          test_eol.lua, test_prose.lua, test_layout_cap.lua,
                     --                          run-automated-tests.sh, README.md
  run.lua            -- the suite list, the assertion aliases, Kit.layoutCap, and Kit.run
  prose_waivers.lua  -- the per-file, per-word waivers the kit's prose gate reads
  loader.lua         -- the instance factory: both load lists derived + per-call isolation
  wow_mock.lua       -- a thin EXTENDER over tests/_kit/mock_base.lua
  test_<module>.lua  -- one suite per module; each reads _G.PC_TEST
```

- `run.lua` builds the shared table with `Kit.expose` and hands the ordered suite list to `Kit.run`. `t.eq` / `t.truthy` / `t.falsy` / `t.nilv` are **aliases** onto `Kit.assertEqual` / `assertTrue` / `assertFalse` / `assertNil`, so the failure messages and the caller-line reporting are the kit's everywhere; `neq` is the one the kit does not carry and is a thin `Kit.fail` wrapper.
- `loader.lua` derives **both** load lists rather than restating either (testing-§9) — the addon's own from `PrettyChat.toc` with `Loader.tocFiles`, and the vendored-library list from `libs/LibKa0s/LibKa0s.xml` with `Loader.xmlFiles`, in XML order — seeds every schema-registered Blizzard global with a recognizable `ORIG:<NAME>` value, and runs the AceAddon lifecycle. `ctx.loadAddon()` returns a **fresh, fully-booted, isolated instance** (`{ env, NS, addon }`); `ctx.loadAddon({ skip = { … } })` loads with files genuinely absent, which is how the degraded-install cases are driven rather than by hand-stubbing (testing-§8) — `tests/test_surface_parity.lua` is where the four whole-surface ones live, one per adopted seam, and `{ mock = fn }` reshapes the environment before anything loads.

  **Why this file survives the kit adoption, and how little of it is left.** It is reduced to the isolated-environment need and nothing else; every capability the kit has is taken from the kit, and when `LIBKA0S-01` lands upstream the file is deleted outright rather than trimmed again. `tests/_kit/loader.lua` builds ONE environment whose `__newindex` writes through to the real `_G`. This addon's entire feature is rewriting `_G[GLOBALNAME]`, and half the suite asserts on what landed there — so each instance needs its own. `tests/wow_mock.lua` points `_G` back at the mock table and this file builds a fresh mock per call, which is what supplies the isolation the kit has no mode for. Chunks compile once and re-run per instance, and the cache doing that is **this file's own** `loadfile` cache rather than the kit's: `tests/loader.lua` takes only `Loader.makeEnv`, `Loader.tocFiles` and `Loader.xmlFiles` from the kit and calls none of `Loader.load` / `Loader.loadAll` / `Loader.loadSource`, which are the three entry points the kit's own chunk cache (revision 12 and later) sits behind — so that cache is never reached from here. The local one used to be load-bearing, because `loadfile` on the ~1.9 MB of generated `GlobalStrings/` chunks dominated the run; `PrettyChat.toc` no longer loads them (PC-R-05), so it is now merely cheap.
- `wow_mock.lua` is a **thin extender** (testing-§1): `local base = dofile("tests/_kit/mock_base.lua")`, then a builder that overwrites the fifteen keys this addon genuinely needs differently. Its own header documents each with the reason it cannot come from the base. The load-bearing ones:
  - **distinct `CreateFontString` / `CreateTexture` objects.** The base aliases them onto the frame itself — a divergence its own README documents as deliberate — and the debug console hangs three FontStrings off one title bar, so an aliased one would make `frame.debugToggle.text` read back the window *title*;
  - `Show()`/`Hide()` **fire** the OnShow/OnHide scripts and hooks; the base tracks visibility only, and every settings page builds its body on first show;
  - a **recording** `DEFAULT_CHAT_FRAME`; the base's stub frame answers `AddMessage` from its metatable and keeps nothing, which would silence every chat assertion in the suite;
  - `AceAddon:NewAddon`, wrapped rather than replaced. Since kit revision 17 the wrapper calls the kit's own `NewAddon` with the name and the mixin list, so the kit names the object, registers it for the `GetAddon` five PrettyChat files call (`modules/Override.lua:8`, `settings/Schema.lua:3`, `settings/Panel.lua:19`, `settings/Slash.lua:15`, and `settings/OptionsSetup.lua:181` through the addon object), and embeds AceConsole, whose `RegisterChatCommand` records into `AceConsole.commands` and runs through `AceConsole:__slash`. The wrapper keeps one thing of its own: AceConsole's `Print` shape landing in this environment's chat frame, because the kit's mixin writes to the harness process's never-set `DEFAULT_CHAT_FRAME`, and a failed reclaim that printed nothing would let the reclaim cases read a stale `[PC]` line and pass;
  - `SettingsPanel = nil`, so the private category-tree walk takes its guarded fallback rather than "succeeding" against a stub that answers every method;
  - `C_AddOns` / `GetAddOnMetadata`, deliberately absent from the base so the `core/EnvSetup.lua` seam's library-absent fallback branch stays drivable.

  **Every frame it builds is built on the kit's TRACKED stub**, and that one line is what makes `tests/test_disabled.lua` possible. The kit's recording mock surveys the frames a build actually made — `M.__registrations()`, `M.__shownFrames()` — and until this file adopted the tracked factory, the combat watcher (the one frame this addon registers anything on) was invisible to it. A stand-down suite that asserted "nothing is registered" over a table this repo's frames never reached would be green over a question it never asked. For the same reason the **event** methods are the kit's rather than this file's, and `_events` is answered through the metatable off the kit's live `__frameEvents` rather than kept as a second table that `UnregisterAllEvents` would leave stale; and the recording `DEFAULT_CHAT_FRAME` above records into the kit's transcript as well as its own, so `M.__printed()` can answer "zero lines reached the player".

What the mocks deliberately do *not* model is layout: they answer "which widget, seeded from what, wired to which schema path", never where anything lands on screen. Rendering, fonts, skinning, taint and live chat stay in the [smoke-test suite](./smoke-tests.md).

## The gate

Both `lua tests/run.lua` and `luacheck .` must be green before any commit. Lint config is `.luacheckrc` (`std=lua51`; excludes `libs/`, `GlobalStrings/`, `tests/_kit/`, `docs/audits`, `docs/reviews`). The suites register named `test(name, fn)` cases; the `Tests` badge in the README badge row shows the pass/total.

**The `luacheck` figure is scoped, not repo-wide.** What is excluded is vendored or generated, not ours: `libs/`, `GlobalStrings/`, and `tests/_kit/` — the byte copy of LibKa0s' `testkit/`, which is linted in the library as source. The rest of `tests/` **is** linted, so the figure now covers 48 files rather than the 18 it covered while the whole test tree sat outside the gate. Before quoting 0/0, confirm the seven seam files are inside the set that was actually checked:

```sh
luacheck . --formatter plain | tail -1     # and read the file count it reports
```

A warning inside `core/EnvSetup.lua`, `core/MediaSetup.lua`, `core/CoreSetup.lua`, `core/DebugLogSetup.lua`, `core/LauncherSetup.lua`, `settings/OptionsSetup.lua` or `settings/Slash.lua` is an adoption defect. A warning elsewhere is pre-existing host hygiene. Neither statement means anything if the lint never opened the file.

## The vendor gate — four diffs, and they answer two different questions

**Nothing else in this repo can see a stale vendored library.** `lua tests/run.lua` passes against a stale copy that still works, and the library's own suite passes against the library. So the sync is checked directly, from the repo root, with the sibling `../LibKa0s` checkout present:

```sh
diff -r --strip-trailing-cr ../LibKa0s/LibKa0s libs/LibKa0s    # content — empty vs the CLAIMED tag
diff -r ../LibKa0s/LibKa0s libs/LibKa0s                        # bytes  — SHOULD be empty
diff -r --strip-trailing-cr ../LibKa0s/testkit tests/_kit      # content — empty vs the CLAIMED tag
diff -r ../LibKa0s/testkit tests/_kit                          # bytes  — SHOULD be empty
```

### When these diffs are supposed to be non-empty

They compare against the sibling checkout's **working tree** — whatever `../LibKa0s` happens to have
checked out — which is a different question from *"is the vendored payload the release this addon
claims?"*. The two questions give the same answer only while the library has tagged nothing newer
than the tag this addon has taken.

Between a library release and the re-vendor that carries it they disagree, and that disagreement is
the normal state rather than a defect. It was the state on one earlier date: `../LibKa0s` sat on
**v1.27.0**, [`CLAUDE.md`](../CLAUDE.md) named **v1.26.0**, and the commands above reported **306**
differing lines for the library and **947** for the test kit. Re-vendoring to quiet them would be
the actual mistake — it would pull an untested library release for the sake of a clean diff.

**The authoritative comparison is against the tag `CLAUDE.md` names**, and that one must be empty at
every commit:

```sh
tag=$(grep -oE 'Bundles \[LibKa0s\]\([^)]*\) v[0-9]+\.[0-9]+\.[0-9]+' CLAUDE.md \
        | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
rm -rf "/tmp/libka0s-$tag" && mkdir -p "/tmp/libka0s-$tag"
git -C ../LibKa0s archive "$tag" | tar -x -C "/tmp/libka0s-$tag"
diff -r --strip-trailing-cr "/tmp/libka0s-$tag/LibKa0s" libs/LibKa0s   # MUST be empty
diff -r --strip-trailing-cr "/tmp/libka0s-$tag/testkit" tests/_kit     # MUST be empty
```

`tests/test_vendor_sync.lua` asks exactly this question inside the suite — it greps the tag out of
`CLAUDE.md` and reads that blob out of git — so **a green suite has already answered it**, and the
block above is only the by-eye version for when you want to see the hunks. Which leaves the
working-tree diffs above answering a real but different question: *how far behind the library is
this addon?* That is release planning, not a gate.


Run **both** of each pair and read the difference between them:

- **content differs** → a real fork in `libs/` or `tests/_kit/`, which is the one state the vendoring discipline forbids. Fix it upstream in `../LibKa0s` and re-vendor whole (`cp -r ../LibKa0s/LibKa0s/. libs/LibKa0s/`); never edit the vendored copy.
- **content same, bytes differ** → **nothing has forked.** The two checkouts merely disagree about line endings. Every repo here pins `* text=auto eol=crlf` while git stores LF blobs, so a working tree holding either ending round-trips to the same blob and `git status` stays clean on both sides — the state is invisible and self-perpetuating. Renormalize whichever side drifted (`git add --renormalize .`); re-vendoring will **not** converge it, it just moves the wrong endings downstream.

`tests/test_vendor_sync.lua` runs the same comparison mechanically whenever the sibling checkout is present. It is a ten-line call into the shared gate `tests/_kit/vendor_sync.lua`, vendored from LibKa0s like the rest of the kit rather than hand-copied here. It reads raw bytes and applies **exactly one** normalization — CR stripped from the working-tree side, because the other side is a `git show` blob (LF) while this working tree is CRLF — so a line-ending-only difference passes and a single content byte fails. A missing sibling is the one case where it can go quiet, and it reports **SKIP with that reason** rather than passing silently, which is why the commands above stay written down here.

**Which tag it compares against comes from the root [`CLAUDE.md`](../CLAUDE.md).** The gate greps the `Bundles [LibKa0s](…) vX.Y.Z (MIT).` provenance line out of that file — kit revision 9 moved it there from `README.md`, with **no fallback**, because the README is the player's page and no longer carries a bundled-library inventory at all. So the line moves in the same commit as the vendored bytes: bump `libs/LibKa0s/` or `tests/_kit/` without moving it and this gate fails, naming `CLAUDE.md`.

## The 1500-line cap gate

`tests/_kit/test_layout_cap.lua` — the kit's gate since LibKa0s v1.55.0 (kit revision 25), and still
the gate in the vendored LibKa0s v1.57.0 (kit revision 26), declared in `tests/run.lua` as
`{ name = "test_layout_cap", dir = "tests/_kit/" }` — compares two things: every authored
`.lua` git tracks, and the census under *Files over the 1500-line cap* in
[ARCHITECTURE.md](ARCHITECTURE.md). It reads them in both directions, so a file that crosses the
cap unremarked and a row left behind for a file that has stopped breaching are each a red.

`layout-§1` binds **every authored file the repository tracks**, `tests/` included, and carves out
vendored code (`libs/`, `tests/_kit/`) and generated non-shipping data. A red is cleared by giving
the file one of the three terminal states the rule allows — peel it, open an issue naming the seam
a peel would follow, or ratify a register row with a re-check trigger — and then adding its row to
the census. It is not cleared by raising the cap, and it must not be cleared by dropping the suite
from the runner's list: `Kit.assertSuiteInventory` reddens on that too, which is the point of
having one.

**The part specific to this repo is the carve-out, and the gate is handed it rather than inferring
it.** PrettyChat has no cap breach; what it has is `GlobalStrings/GlobalStrings.lua`, 23,842 lines
of generated dump, exempt only while all three of the carve-out's conditions hold — a comment at the
top saying it is generated, no load list carrying it, a `.pkgmeta` entry keeping it out of the zip.
No path betrays those facts, so `tests/run.lua` sets `Kit.layoutCap = { exempt = { "GlobalStrings/" } }`
before `Kit.run`, and the census marks the dump's row `exempt`. The gate checks only that the two
agree; whether the three conditions still hold is the auditor's. This repository used to carry a
hand-written `tests/test_layout_cap.lua` that re-derived them on every run; revision 25's pair-keyed
inventory, unchanged at revision 26, reports a local file beside the kit's as a collision (`testing-§9`), so it was retired.

The line figures in the census are dated measurements and nothing asserts them, so an ordinary edit
to a large file does not redden this gate. Membership is the invariant, not the numbers.

## The US-English prose gate

`tests/_kit/test_prose.lua`, declared as `{ name = "test_prose", dir = "tests/_kit/" }`, holds every
tracked authored file to `localization-§5`'s published `BRITISH` / `ALLOWED` lists. The only British
spellings it finds are inside `GlobalStrings/` — Blizzard's English, extracted from the client — and
they are waived **per file and per word** in `tests/prose_waivers.lua`, which is the form §5 names
for a generated dump of the client's strings. A new British spelling in any of those files, or any
spelling in a file the waiver does not name, still reddens. The kit also offers a folder-wide
`Kit.prose.exempt`; it is not used, because §5 forbids a whole-file waiver and no register row
ratifies one.

## The no-blanket-suppression gate

`tests/test_lintconfig.lua` guards the thing that makes `luacheck .` worth running: that 0/0 is a
statement about the code and not about `.luacheckrc`.

Until `M4c-06` this repo carried `ignore = { "212/self", "212/event", "211/addonName" }` at the top
level. The entries were already spelt in luacheck's `<code>/<variable>` form, which is what made it
look narrow and easy to leave alone — but the **scope** was every file in the repository, and scope
is what `M4-11` is about: an ignore that silences the wall reads as coverage and provides none.

Removing the line reported **sixteen** findings, and eleven of them were not conventions at all —
eleven files opened `local addonName, NS = ...` over a folder name they never read. Those were
fixed at source, not re-parked in a smaller suppression. A twelfth thing the blanket hid was one of
its own entries: `212/event` matched nothing in this addon and never had. Five findings remained,
each a method receiver a calling convention forces, and each now sits in a `files[...]` stanza
naming one file, with a comment saying which obligation forces it.

The gate checks four things, all the same rule from different sides:

| Case | What it refuses |
|------|-----------------|
| no top-level `ignore` | the blanket itself, in any spelling |
| no wholesale class switch | `unused_args = false` and eight relatives — the blanket as a switch |
| every `files[...]` ignore is narrow | a stanza keyed on a directory whose entry names no variable |
| no bare inline `-- luacheck: ignore` | the blanket wearing a different hat, one line at a time |

It reads `.luacheckrc` **as Lua**, under a sandbox whose environment auto-creates tables the way
luacheck's own config loader does, so what the gate inspects is the table luacheck obeys rather
than text that a different spelling would slip past. Like the cap gate and the EOL gate it **fails
rather than skips** when it cannot look: no config, an unreadable one, a chunk that will not
compile, no `io.popen`, no git — every one of those is a red, because a gate that goes quiet when
it is blind reports success.

Adding a suppression is not forbidden; adding a *wide* one is. Name the file in the stanza key, or
narrow the entry to `<code>/<variable>`, or put `-- luacheck: ignore <code>` beside the single line
that earns it — and say in a comment why the code is correct as written.

## Test-case inventory & badge sync (`testing-§5`)

### `tests/test_disabled.lua` — the stand-down conformance suite

`slash-commands-§7` requires every addon in the collection to carry one, and it says why: eleven addons implemented *disabled* as a **draw gate**, and a suite written against a handler's early return cannot tell a draw gate from a stand-down, because an early return is what a draw gate does. So every assertion in this suite is made against the **registration set**, through the kit's recording mock, and never against a handler's return value.

Its ten steps follow the section's: a non-vacuous enabled baseline (the addon has to register something for a stand-down to remove — which is why step 1 stores a combat-scoped visibility first); the disable written through the **single write seam**, never by calling a teardown function; the registration set empty by count and by name; nothing left armed; nothing drawn; the baseline events fired at the handler **unconditionally** — the client would not fire them, so `__fireUnconditional` is what proves a survivor would have been caught — with zero SavedVariables writes, zero printed lines and zero frames shown; the slash surface; the rung-(c) launcher; restoration from **current** state; and the latch's two holds in both orders.

It was proved red by reverting the latch read out of `SyncCombatWatch` and `ApplyStrings`, which is the shape this repo shipped before: **eight cases fail**, including all three the section asks for a falsification comment on. Step 5 stays green under that revert, which is exactly the point — the draw gate does restore the display, and the drawing axis is the one axis on which it is invisible.

The authoritative case count lives in the **generated** inventory [`test-cases.md`](./test-cases.md) — every case, grouped by suite, with per-suite and grand totals. It is produced by the runner's `--list` mode, never hand-edited:

```sh
lua tests/run.lua --list > docs/test-cases.md   # regenerate the inventory
# verify it's in sync (CR-agnostic, since docs are CRLF on disk):
diff --strip-trailing-cr <(lua tests/run.lua --list) docs/test-cases.md
```

Whenever the suite changes — a case added, removed, or renamed, or the pass count moves (i.e. whenever a failing test is resolved) — regenerate `docs/test-cases.md` and update the README `Tests` badge count **in the same change**, never as a follow-up.

## Automated test records — the consolidated run

All four out-of-game suites go through one vendored runner, and every run is recorded
(`automated-tests`):

```sh
tests/_kit/run-automated-tests.sh                            # all four, writes a bundle
tests/_kit/run-automated-tests.sh --suite complexity          # a subset
tests/_kit/run-automated-tests.sh --suite lint --suite tests --no-bundle   # the green gate; writes nothing
```

There are **two** checkpoints and a suite answers differently at each, so the table names both
(`automated-tests-§3`).

| Suite | Command | Gates the run and the commit? | Gates the tag? |
|---|---|---|---|
| `lint` | `luacheck .` | **yes** | **yes** |
| `tests` | `lua tests/run.lua` | **yes** | **yes** |
| `perf` | `lua tests/perf.lua` | no — recorded only | **yes** |
| `complexity` | `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` | no — recorded only | **yes** |

**`perf` and `complexity` never fail a run and never block a commit.** They are measured, recorded
and diffed — a threshold that fails a run teaches everyone to reach for `--no-verify`, after which
the gate protects nothing and the habit remains. They contribute `amber`, which is a signal rather
than a stop. **A missing tool is a skip recorded with its reason**, never a pass.

**The tag is gated on all four suites at `pass`, plus zero functions above CCN 15**
(`automated-tests-§3`, *The release gate*), evaluated by `/wow-addon:bump-version` from the
`manifest.json` the release run writes — not by the runner, whose exit code is unchanged. A `skip` is
**NOT EVALUATED** there rather than passed: install the tool and re-run. The one narrow exception is
`perf`, skipped under the ratified `performance-§12` no-combat-path exemption (register row in
`docs/ARCHITECTURE.md`), which the release notes name.

The runner is **vendored** from `LibKa0s`'s `testkit/`; never edit `tests/_kit/`. A kit fix goes
upstream and is re-vendored.

**At release, not at commit.** A full bundle is produced as part of every version bump, before the
tag, with an `ANALYSIS.md` write-up. Commits are gated on lint + tests only; the tag is gated on all
four, as above.

Results live in [`automated-tests/`](./automated-tests/): `RESULTS.md` is one row per run across all
four suites plus the current complexity watch list — **one file, overwritten in place**, so its git
history is the trend line — and each `<YYYYMMDD-HHMMSS>/` is a frozen bundle of that run's raw
output. Bundles are never edited and never pruned.

`docs/complexity.md` was this addon's standalone complexity report through standard v2.18.0; it is
**retired** — its raw output is each bundle's `complexity.txt` and its trend line is `RESULTS.md`.

## In-game validation

For behavior stock Lua can't cover (panel rendering, live chat overrides, positional `%n$s` formats), follow the manual [smoke-test suite](./smoke-tests.md) — it lists which invariant each test guards, so a failure can be tied back to a specific area of the addon.
