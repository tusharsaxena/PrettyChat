# 01 — Current State (Ka0s Pretty Chat)

**Run date:** 2026-08-04
**Addon:** Ka0s Pretty Chat (`PrettyChat`), version `1.4.0` (`PrettyChat.toc:5`)
**Repo HEAD at audit time:** `7af7453d03e93d2769cc81ec45399700ede5d6b2` — *"docs+i18n: adopt standard v2.17.1 — US English spelling throughout"*
**Deviation ID prefix:** `PC-` (assigned on the first audit; reused here)

---

## Standard version audited against

**Ka0s WoW Addon Standard v2.17.1 (2026-08-03)** — `standards/STANDARDS.md` header line 1.

### Provenance of the standard text (stated plainly, per this run's brief)

The **network fetch succeeded** and was used as the primary source. Every file below was
retrieved with `curl -fsSL` from
`https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master/…` into a scratch
directory and then **diffed against the local canonical checkout** at
`/mnt/d/Profile/Users/Tushar/Documents/GIT/WowAddonStandards`:

| Fetched | Result |
|---|---|
| `AUDIT.md` | fetched (9165 bytes); `diff` vs local → **identical** |
| `standards/STANDARDS.md` | fetched; `diff` vs local → **identical** |
| all **24** section files under `standards/standards/` | fetched via an 8-way parallel `curl` loop (exit 0, 24/24); `diff -r` vs local → **`ALL_SECTIONS_IDENTICAL`** |

The local checkout was verified clean at HEAD `2141229 v2.17.1 — finish the v2.17.0 rollout`
(`git status --porcelain` empty). Nothing in this audit is reconstructed from memory; **no
section was unassessed for want of text.** The standards repo was read only — nothing was
written to it.

**Sections read in full (24):** `layout`, `toc-file`, `library-stack`, `architecture`,
`savedvariables`, `options-ui`, `standalone-windows`, `preview-mode`, `slash-commands`,
`localization`, `events-frames-taint`, `public-api`, `compat`, `debug-logging`, `packaging`,
`lint`, `testing`, `performance`, `documentation`, `audit-review-history`, `versioning-git`,
`naming-cheatsheet`, `anti-patterns`, `open-evolutions`.

---

## What this addon is

PrettyChat rewrites Blizzard's system-message **format strings** — it assigns
`_G[GLOBALNAME]` at `OnEnable` and on every settings write, and lets WoW's own chat code read
the replaced template lazily (`modules/Override.lua:50-88`). It registers **no events, no
timers, no ticker, no chat filter and no chat-frame hook**
(`docs/ARCHITECTURE.md:117-119`, confirmed by a whole-repo grep in this run: zero
`RegisterEvent` / `OnUpdate` / `C_Timer` / `AceEvent` in `core/ defaults/ settings/ modules/
locales/`). It draws **no main window** — its only UI surfaces are the Blizzard Settings
canvas and the LibKa0s debug console.

That shape decides which sections apply: `standalone-windows` and `preview-mode` are **N/A**,
`events-frames-taint-§1–§7` is largely **N/A**, and `performance` is where the addon has
deliberately stopped short (see below).

---

## Section-by-section snapshot

### layout

Modular layout present: `core/` (9 files), `defaults/` (2), `settings/` (4), `locales/` (1),
`modules/` (1), plus `libs/`, `media/`, `tests/`, `docs/`. Subfolders lowercase; Lua files
PascalCase. Media is in typed subfolders — `media/logos/` (`.tga` runtime + `.jpg`/`.png`
source), `media/fonts/` (JetBrains Mono + `OFL.txt`), `media/screenshots/`. Nothing loose in
`media/`.

**One structural exception:** `GlobalStrings/` is an eleventh, **PascalCase, root-level**
source folder holding ten machine-generated chunk files plus a ~23.8k-line source dump and a
Python splitter (`GlobalStrings/split_globalstrings.py`). Eight of the ten shipped chunks are
**over the 1500-LOC cap** (2176–3285 lines each). Recorded as an accepted deviation in
`CLAUDE.md:8`. → **PC-25**, **PC-49**.

Largest addon-owned file otherwise: `settings/Panel.lua` at 423 lines — comfortably inside the
cap.

### toc-file

`PrettyChat.toc` metadata block is in the exact mandated field order, with no blank lines:
Interface `120007` (single, latest Retail) → Title → Notes → Author → Version → IconTexture →
SavedVariables → OptionalDeps → DefaultState → Category-enUS → X-License `MIT` → X-Standard →
X-Curse-Project-ID `919766`. No `Dependencies:`. No multi-flavor Interface list.

Departures: `## SavedVariables:` declares **one** global (`PrettyChatDB`), not the mandated two
(`PrettyChat.toc:7`) → **PC-41**. The file listing carries a non-canonical `# GlobalStrings`
section between `# Defaults` and `# Modules` (`PrettyChat.toc:42-52`) → **PC-25** (which absorbs the former PC-33; its `# Locales` half is fixed). `## Title:`
carries rainbow color escapes and `## Author:` stylized casing (`PrettyChat.toc:2,4`) →
**PC-27**. `## Category-enUS: Chat & Communication` is outside the standard's enumerated set →
**PC-56**.

`## X-Wago-ID` is absent — and under v2.17.1's `toc-file-§1` that is now **correct**, since
Wago/WoWI ids are MAY and included only when actually listed. The old **PC-10** is therefore
**resolved by the standard**, not by a code change.

Section order is `Libraries → Locales → Core → Defaults → (GlobalStrings) → Modules →
Settings`, matching `toc-file-§5`. `CLAUDE.md:13` records the standard-internal
`toc-file-§5` vs `layout-§1` ordering conflict, raised upstream as WowAddonStandards#2.

### library-stack

`libs/` holds `LibStub`, `CallbackHandler-1.0`, `AceAddon-3.0`, `AceDB-3.0`, `AceConsole-3.0`,
`AceGUI-3.0` and `LibKa0s` — all vendored and committed, each listed **directly** in the TOC's
`# Libraries` section, `libs\LibKa0s\LibKa0s.xml` last, after Ace3 (`PrettyChat.toc:16-22`). No
`embeds.xml`. No Ace fork. No suite dependency.

`AceEvent-3.0` and `AceTimer-3.0` — in `library-stack-§1`'s mandatory table — are **not**
vendored; the addon uses neither. → **PC-52** (advisory; §1 and §3 pull opposite ways here).

**Vendoring is whole and byte-identical.** `diff -r ../LibKa0s/LibKa0s libs/LibKa0s` → empty.
`diff -r ../LibKa0s/testkit tests/_kit` → empty. The harness is under `tests/`, never `libs/`.
No `#45` drift, no `#48` partial vendoring.

### architecture

`local addonName, NS = ...` at the head of every addon file; no `_G[addonName]`.
`AceAddon:NewAddon(NS, addonName, "AceConsole-3.0")` passes `NS` first
(`core/PrettyChat.lua:14`), and `core/CoreSetup.lua:109` **reclaims** `NS.Print` from the
AceConsole embed immediately after — anti-pattern #36 handled, and the mock reproduces the
clobber (`tests/_kit/mock_base.lua:387-392`).

Schema-as-single-source is strong: `settings/Schema.lua` builds every row at load, validates
each path against `NS.Defaults` and stashes the counts (`settings/Schema.lua:186-196`), and
`Schema.Set` is the **single write seam** both the panel and `/pc set` take
(`settings/Schema.lua:287-298`).

**There is no message bus at all** — `docs/ARCHITECTURE.md:119` states so explicitly, and
cross-file wiring is direct table access (`modules/Override.lua:100-102` → `NS.Schema.
NotifyPanelChange`). → **PC-50**.

### savedvariables

`PrettyChatDB` via AceDB with profile + global namespaces; `schemaVersion` declared in
`core/Database.lua:21` with a migration runner at `core/Database.lua:32-44`. Profile defaults
live in `defaults/Profile.lua` (the old PC-39 is resolved). The sanctioned second global,
`PrettyChatPerfDB`, is absent → **PC-41**.

### options-ui

Fully on `LibKa0s-Options-1.0`. `settings/OptionsSetup.lua:104-153` resolves the major with
`LibStub(..., true)`, builds one instance from a descriptor, and **is** the namespace member
(`NS.Helpers = lib:New{…}`) rather than a copy-across. `get`/`set`/`applyDefault` route through
`NS.Schema` — the same seam `/pc set` takes. Fields deliberately not passed (`colorDecode`,
`getLSM`, `scheduleTimer`, `skipRestoreAll`, `validate`, `onAceGUI`) each carry a written
reason (`settings/OptionsSetup.lua:137-153`).

The degradation stub (`settings/OptionsSetup.lua:58-96`) is the standard's **documented
load-completing** exception, and the addon has done the measurement the standard asks for: its
load-time member set is **empty**, pinned by loading with the library absent and comparing row
counts (`tests/test_libka0s.lua`). It copies **no** widget maker, flow engine or layout
constant, and says so.

Panel behavior: category registered eagerly at `OnEnable` (`core/PrettyChat.lua:50-52`), body
lazy on first `OnShow`, Defaults button built in `OnShow` not at registration
(pinned by `test_panel.lua` — *"the Defaults button is deferred to first show"*), combat gate
inside the library's `OpenOptionsPanel` with a one-line host delegate
(`core/PrettyChat.lua:71-73`). Landing page renders logo + tagline + the command list generated
from `NS.COMMANDS`.

One departure: the per-string editor is a bespoke **40/60** three-row block
(`settings/Panel.lua:127-128`, `buildStringRow` at `:130`) rather than the 50/50 grid →
**PC-23**, documented in `CLAUDE.md:11`.

### standalone-windows / preview-mode

**N/A.** The addon draws no main window; the debug console and its copy window are the
library's and take the normative Ka0s edge unmodified (`core/DebugLogSetup.lua:143-151`
records the deliberate decision to pass no `skin`, no `applySkin`, no `makeCloseButton`).
`/pc test` is a preview-style verb but there is no positionable display.

### slash-commands

On `LibKa0s-Slash-1.0`. `NS.COMMANDS` stays the host's, as positional triples
(`settings/Slash.lua:45-66`), passed into the descriptor as plain data; registration is
AceConsole `RegisterChatCommand("pc" / "prettychat")` (`core/PrettyChat.lua:33-34`); no
`SLASH_*`. The cyan `[PC]` tag is a single shared constant (`core/Constants.lua:51-52`) and the
mandated `slash-commands-§5` palette is pinned with a comment saying it is a MUST
(`core/Constants.lua:41-46`). `reset` takes a **path**, with the old category form intercepted
and answered (`settings/Slash.lua:265-282`). `parse`/`format` are supplied at the sanctioned
descriptor seams rather than by forking (`settings/Slash.lua:134,147-153`). The stub answers
every member the addon calls.

Missing: the reserved **`perf`** verb → **PC-42**.

### localization

`locales/enUS.lua` exports `NS.L` with the key-returning metatable; keys are English strings;
enUS only, so no locale gate is needed. Game data is matched on **non-localized global-string
names** (`_G[GLOBALNAME]`), never on translated display text — `localization-§4` is satisfied
by construction. A repo sweep for British spellings in authored text found **none**; the single
hit (`tests/_kit/README.md:119`) is vendored library text, byte-identical to upstream, and is
an upstream finding rather than this addon's.

### events-frames-taint

No event registration, no frames beyond the AceGUI panel content, no secure writes, no Blizzard
frame replacement, no `AddMessage` hook. The addon is architecturally taint-free — the
`events-frames-taint-§5` reference pattern (override globals rather than hook chat) is what it
does.

`events-frames-taint-§8` is satisfied through the library: `NS.Util.IsConcatSafe` /
`NS.Util.SafeToString` are bound to `LibKa0s-Core-1.0`'s own function values and `NS.Print` is
built from `lib:New{…}` (`core/CoreSetup.lua:90-104`). A repo-wide grep for a raw `print(` call
site in addon source returns **nothing** — every line goes through the single seam.

### public-api

None exposed. Correctly absent.

### compat

`core/Compat.lua` exists and is loaded first; it owns the one moved API this addon touches
(`GetAddOnMetadata` → `C_AddOns.GetAddOnMetadata`). No `WOW_PROJECT_ID` branch anywhere.

### debug-logging

On `LibKa0s-DebugLog-1.0`. `core/DebugLogSetup.lua:109-152` builds one instance per host from a
descriptor with all five required fields (`name`, `title`, `font`, `isEnabled`, `setEnabled`)
plus `slash`, `print`, `safeToString`, `initSummary`, `onVisibilityChanged`. `print` and
`safeToString` are **thin call-time forwarders**, not captured references. The sink is bound
bare (`NS.Debug = NS.DebugLog.Debug`, `:157`). The flag is session-only in `NS.State.debug`
(`core/State.lua:6`), never persisted. The stub (`:41-106`) answers every member the addon
calls, still flips the flag, still prints the ack, and deliberately copies **no** formatter.
Coverage: the `[Set]` line is emitted once at the write seam
(`settings/Schema.lua:296`) and bulk resets emit one coalesced summary each
(`modules/Override.lua:105,115,135`) rather than ~350 per-row lines.

Font: JetBrains Mono vendored with `OFL.txt`, handed over as the descriptor's `font`.
**Not** registered with LibSharedMedia — a documented SHOULD-deviation
(`core/Constants.lua:54-60`, `CLAUDE.md:9`) → **PC-54**.

### packaging

`.pkgmeta` present, `package-as: PrettyChat`, **no `externals:`**, ignores `.luacheckrc`,
`.gitignore`, `.gitattributes`, `docs`, `tests`, `_dev`, `*.bak`, plus commented project-specific
blocks for the GlobalStrings source assets and the non-runtime project-page art. No
`enable-toc-creation`. Compliant.

### lint

`.luacheckrc` present: `std = "lua51"`, `max_line_length = false`, `codes = true`, excludes
`libs/`, `GlobalStrings/`, `docs/audits/`, `docs/reviews/`, `tests/`, and declares its writable
globals with comments. `luacheck .` → **0 warnings / 0 errors in 17 files** (run this session).
Missing `debugprofilestop` in `read_globals` and `PrettyChatPerfDB` in `globals` → **PC-45**.

### testing

Kit vendored whole to `tests/_kit/`, byte-identical to `../LibKa0s/testkit`, never under
`libs/`. `tests/run.lua` uses `Kit.expose` / `Kit.run`, aliases assertions onto the kit's rather
than re-implementing them, and derives the addon's file list from the TOC via
`Loader.tocFiles`; the eight `LibKa0s` files are spelled out explicitly in XML order
(`tests/loader.lua:32-41`). `tests/wow_mock.lua` is a thin extender over `mock_base` and models
the AceConsole `:Print` clobber. `lua tests/run.lua` → **255 passed, 0 failed**.
`docs/test-cases.md` reports **255** and the README badge reads **255/255** — in lockstep.

`tests/loader.lua` survives as an addon-side per-instance isolation factory over the kit's
loader — documented at `CLAUDE.md:12` and reported upstream as LIBKA0S-01 → **PC-51**.
`tests/perf.lua` does not exist → **PC-43**.

### performance

**This is the addon's largest open gap, and it is a deliberate, recorded decision.** There is
no `core/PerfSetup.lua`, no `NS.Perf` instance, no declared buckets, no bracket, no `perf`
verb, no `PrettyChatPerfDB`, and no `tests/perf.lua`. `Perf.lua` and `PerfPanel.lua` *are*
vendored, because the folder is copied whole.

The decline is argued at `docs/pending/LEDGER.md:66` (LIBKA0S-12) and summarized at
`docs/ARCHITECTURE.md:141` on two grounds: (1) there is no hot path — zero events, timers or
tickers, so every bucket would read `0.000` by construction; (2) `suspend` would flip the
player's chat formatting back to Blizzard's mid-fight for a capture that can only report zero.

The reasoning is sound and specific to this addon. It is nonetheless measured here against the
standard as written, where `performance`'s adoption strength is **MUST for the wiring** →
**PC-40**, **PC-41**, **PC-42**, **PC-43**, **PC-44**, **PC-45**.

### documentation

Root ships `README.md`, `CLAUDE.md`, `LICENSE` and nothing else. The canonical `docs/` trio is
present (`ARCHITECTURE.md`, `testing.md`, `smoke-tests.md`), plus the generated
`docs/test-cases.md` and nine topic-detail docs. **There is no `docs/agent-context.md`** — and
`CLAUDE.md:33-48` states it must never be created, citing anti-pattern #49. No `TODO.md`
anywhere; `docs/pending/LEDGER.md` is a decision record maintained by a skill, not a backlog.

README: all five badges present in the mandated order and canonical templates, including the
`_`-not-`%20` standard badge. `## What's new in 1.4.0` sits immediately above `## Screenshots`
and agrees with the top Version History row. Slash commands render as the mandated
`Command | What it does` table, settings as a `Tab | Covers` table (PC-36 resolved).

Departures: an angle-bracket placeholder survives at `README.md:116` → **PC-46**; two
non-canonical sections, `## Unreleased` (`README.md:15`) and `## Credits` (`README.md:120`),
break the fixed section order → **PC-47**. `docs/performance.md` and `docs/perf-runs/README.md`
are absent → **PC-44**; `docs/complexity.md` is absent → **PC-55**. `docs/ARCHITECTURE.md` has
no `Message Bus` heading (the content is folded into `Event Subscriptions`) → **PC-53**.

Root `CLAUDE.md` carries the `## Standards compliance (read first)` section verbatim in
substance (PC-31 resolved) — but at 64 lines with six multi-sentence accepted-deviation
paragraphs, code invariants and seven guardrails, it has grown past the mandated **stub** and
the deviation records precede the compliance section → **PC-48**.

The three-place standards reference is complete: TOC `X-Standard:` (`PrettyChat.toc:12`),
README badge (`README.md:6`), `CLAUDE.md` compliance section (`CLAUDE.md:14`).

### audit-review-history

`docs/audits/2026-07-12/`, `docs/audits/2026-07-18/` and `docs/reviews/2026-08-03/` are all
retained and untouched; this run writes a new dated folder beside them. Compliant.

### versioning-git

Semver `1.4.0` in TOC, README badges and Version History. Working tree clean at a green gate.
Trunk-based; no stray feature branch.

---

## Compliance summary

**Compliant, with evidence, in:** `library-stack` (whole-folder vendoring, both diffs empty),
`packaging`, `lint` (0/0), `compat`, `public-api`, `events-frames-taint-§8`, `localization`,
`audit-review-history`, `versioning-git`, and the **wiring** of all four adopted LibKa0s
modules — Core, DebugLog, Slash and Options — each with a descriptor, a correct TOC slot, and a
degradation stub that answers **every** member the addon reaches (verified by enumerating call
sites against each stub this run).

**N/A:** `standalone-windows`, `preview-mode`, most of `events-frames-taint`.

**Open:** 12 MUST, 6 SHOULD, 2 advisory — catalogued in `02_DEVIATIONS.md`.
</content>
</invoke>
