# Dependencies — Ka0s Pretty Chat

Everything you need installed to build, run, test or release this addon, with the evidence for each
entry and a WSL2 / Ubuntu install command that actually works. Per `documentation-§7` of the
[Ka0s WoW Addon Standard](https://github.com/tusharsaxena/WowAddonStandards).

This file answers **what to install**. [`docs/testing.md`](./docs/testing.md) answers **how to
verify**; neither repeats the other.

Every entry below names *what needs it* and *how that is known* — a file and line, a script's
import, or a documented command. Nothing here is listed because it seemed likely.

---

## 1. Runtime (in-game) — what a player needs

**World of Warcraft (Retail), and nothing else.**

| Requirement | Version | Evidence |
|---|---|---|
| World of Warcraft, Retail | Interface `120007` (Midnight 12.0.7) | `PrettyChat.toc:1` — `## Interface: 120007`, the single latest-Retail line |

Every library the addon uses is **vendored and committed** under `libs/` and listed in the TOC's
`# Libraries` section (`PrettyChat.toc:15-21`), so a player installs no library packs:

- `LibStub`, `CallbackHandler-1.0`, `AceAddon-3.0`, `AceDB-3.0`, `AceConsole-3.0`, `AceGUI-3.0`,
  and the Ka0s umbrella `LibKa0s` (vendored whole from the sibling `../LibKa0s` checkout).

The TOC's `## OptionalDeps: Ace3, LibStub, CallbackHandler-1.0` (`PrettyChat.toc:8`) is a **load-order
hint**, not an install requirement: if a standalone Ace3 is present it loads first, and if it is not,
the vendored copies serve. There is no `## Dependencies` line, and there is nothing for a player to
install alongside this addon.

The monospace console font (JetBrains Mono, `media/fonts/JetBrainsMono-Regular.ttf`, referenced at
`core/Constants.lua:60`) is a **bundled asset**, not a dependency — it ships in the package and is
loaded by path. The same is true of the `.tga` logo. Neither needs anything installed, at runtime or
at build time.

---

## 2. Development — the contributor toolchain

This is the set you need to run the gate (`lua tests/run.lua` + `luacheck .`) and the complexity
report. Install all of it; it is small.

### Lua 5.1 — a hard version requirement, not a preference

| | |
|---|---|
| **Version** | **5.1 exactly.** Not 5.2, not 5.3, not LuaJIT-as-5.2. |
| **Why** | The headless harness sandboxes each loaded chunk with **`setfenv`**, which was **removed in Lua 5.2**. Evidence: `tests/loader.lua:95` and the vendored kit's `tests/_kit/loader.lua:31,50`. There is no fallback path — under 5.2+ the suite does not degrade, it fails to load the addon at all. |
| **Install** | `sudo apt install -y lua5.1` |
| **Verify** | `lua -v` → must print `Lua 5.1.x` |

If `lua` on your `PATH` is a newer Lua, invoke the tests as `lua5.1 tests/run.lua`, or put `lua5.1`
ahead of it. Do not "upgrade" to make the version banner look modern.

### luacheck — the lint half of the commit gate

| | |
|---|---|
| **Version** | **Any recent.** Verified here with 1.2.0; the config uses nothing version-specific, so pinning would be false precision. |
| **Why** | `luacheck .` is one of the two green-gate commands (`CLAUDE.md`, "Test gate"; `docs/testing.md`, "The gate"). Its configuration is `.luacheckrc` (`std = "lua51"`, with `libs/`, `GlobalStrings/`, `tests/` and the frozen `docs/audits/`, `docs/reviews/` bundles excluded). |
| **Install** | `sudo apt install -y lua5.1 luarocks && sudo luarocks install luacheck` |
| **Verify** | `luacheck --version` |

`luarocks` is pulled in only as luacheck's installer — nothing in this repo calls it.

### lizard — the complexity report

| | |
|---|---|
| **Version** | **Any recent.** Verified here with 1.23.0. The report records the version it was generated with in its own header, so a diff across versions is visible rather than silent. |
| **Why** | Generates [`docs/complexity.md`](./docs/complexity.md), refreshed at every release (`performance-§10`). |
| **Install** | `sudo apt install -y pipx && pipx ensurepath && pipx install lizard` |
| **Verify** | `lizard --version` |

**Do not use `pip install lizard` on Ubuntu 24.04.** The system Python is marked
`EXTERNALLY-MANAGED` (PEP 668) and the command fails with an error that reads as though the package
is unavailable rather than as though the instruction is wrong. `pipx` is the working route. The
documented alternative, if you would rather not install `pipx`, is:

```sh
pip3 install --user --break-system-packages lizard
```

After `pipx ensurepath` you may need a new shell (or `source ~/.bashrc`) before `lizard` resolves.

`lizard` is **optional**: without it the complexity report is *stale*, which the report's own header
dates for you. It does not make the addon non-compliant, and it is never a commit gate
(`performance-§10`).

### git — the vendor-sync check shells out to it

| | |
|---|---|
| **Version** | Any recent. |
| **Why** | Beyond version control: `tests/test_harness.lua:120-121` runs `io.popen('git -C "<root>/../LibKa0s" show …')` to compare the vendored `libs/LibKa0s` and `tests/_kit` against the sibling checkout. Without `git` on `PATH` that case goes quiet rather than failing — the one gate in the suite that can pass by not looking. |
| **Install** | `sudo apt install -y git` |
| **Verify** | `git --version` |

### diffutils and a POSIX shell — the documented verification commands

| | |
|---|---|
| **Version** | Any recent. Present by default on Ubuntu; listed because the commands are documented and will be run. |
| **Why** | `docs/testing.md` documents `diff -r --strip-trailing-cr ../LibKa0s/LibKa0s libs/LibKa0s` (the four-diff vendor gate) and `diff --strip-trailing-cr <(lua tests/run.lua --list) docs/test-cases.md` (the test-inventory sync check). The second uses **process substitution**, so it needs `bash` or `zsh` — it fails under `dash`/`sh`. |
| **Install** | `sudo apt install -y diffutils` (both are normally already present) |
| **Verify** | `diff --version` |

### Not required, and deliberately not listed

- **A WoW client** is not needed for the headless suite; it is needed only for the manual
  [smoke tests](./docs/smoke-tests.md).
- **The sibling `../LibKa0s` checkout** is not a dependency — the library is vendored and committed.
  It is needed only to *re-vendor* or to run the vendor-sync diffs above; without it those checks
  skip.
- **`AceEvent-3.0` / `AceTimer-3.0`** are not vendored and not needed — this addon `LibStub`s
  neither (recorded as PC-52 in `docs/audits/2026-08-04/02_DEVIATIONS.md`).

---

## 3. Release / assets — regenerating committed data

**None of this is needed to build, run or test the addon.** Skip this whole section unless you are
regenerating the GlobalStrings chunks. A contributor fixing a typo installs nothing from here.

### Python 3 — one generator script, standard library only

| | |
|---|---|
| **Version** | **Python 3.6 or newer** (the script uses f-strings). Verified here with 3.12.3. |
| **Why** | `GlobalStrings/split_globalstrings.py` regenerates the ten committed `GlobalStrings/GlobalStrings_0NN.lua` chunks from Blizzard's `GlobalStrings.lua` dump. It is run **by hand after a WoW patch** — see `docs/common-tasks.md`, "Regenerate `GlobalStrings_*.lua` after a WoW patch" — and its output is committed. Nothing in the build, the TOC, the tests or the packager invokes it. |
| **Packages** | **None.** Its imports are `collections`, `glob`, `os`, `re`, `sys` (`GlobalStrings/split_globalstrings.py:12-16`) — all standard library. There is no `requirements.txt`, no virtualenv, and no `pip install` step. |
| **Install** | `sudo apt install -y python3` (present by default on Ubuntu 24.04) |
| **Verify** | `python3 --version` |
| **Run** | `python3 GlobalStrings/split_globalstrings.py`, from the repo root |

The script's inputs and the ~1.6 MB `GlobalStrings/GlobalStrings.lua` dump it reads are excluded from
the shipped package by `.pkgmeta` — they are build-time-only assets.

### Image tooling — none, and none is claimed

The repo ships `media/logos/*.png`, `*.jpg` and the runtime `*.tga`, plus `media/screenshots/`. There
is **no committed script, Makefile target or documented command that regenerates any of them**, so
there is no image dependency to install. The `.tga` was produced out-of-band; converting a new one
would need some `.tga`-capable image tool, but naming a specific one here would be inventing a
requirement this repo has never recorded. **Plausible, not evidenced — left out deliberately.**

### Packaging

Packaging is done by the **BigWigs/CurseForge packager on the release side**, driven by `.pkgmeta`
(`enable-nolib-creation: no`; libraries stay vendored, no externals are pulled). There is nothing to
install locally to package this addon.

---

## 4. Am I set up correctly?

Run these from the repo root. All three should be green.

```sh
lua tests/run.lua                                     # headless suite — exits non-zero on failure
luacheck .                                            # lint (config: .luacheckrc)
lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .     # complexity report (performance-§10)
```

The first two are the **commit gate**; the third is a **release** checkpoint and never gates a
commit. What each one covers, and how to read its output, is in
[`docs/testing.md`](./docs/testing.md).

---

## Keeping this file honest

This list is **checked at release** along with the rest of the doc set (`documentation-§5`). A new
script, a new import, a dropped tool, or a Lua version change edits this file **in the same change**
— not at the next audit. A dependency list that is wrong is the thing that makes a new contributor's
first hour their last (`anti-patterns` #50).
