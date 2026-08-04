# CLAUDE.md — Ka0s Pretty Chat

**Ka0s Pretty Chat** — a WoW addon that reformats system chat messages by overriding Blizzard's `GlobalStrings.lua` format strings (not by parsing chat events).

- **Layout:** modular — source `.lua` lives under `core/`, `defaults/`, `locales/`, `modules/`, `settings/`; libraries are vendored under `libs/`. This is the single Ka0s layout (`layout-§1`), used by every addon regardless of size.
- **Library:** vendors **[LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.5.0** whole into `libs/LibKa0s/` (TOC: `libs\LibKa0s\LibKa0s.xml`, after Ace3) and the shared test kit into `tests/_kit/`. **Four of five majors are adopted** — Core (`core/CoreSetup.lua`), DebugLog (`core/DebugLogSetup.lua`), Slash (`settings/Slash.lua`) and Options (`settings/OptionsSetup.lua`). **Perf is declined**, on two structural grounds recorded at `LIBKA0S-12`: the addon registers no events, no timers and no ticker, so every bucket would read 0.000 by construction; and `suspend` would flip the player's chat formatting back to Blizzard's mid-fight for a capture that can only report zero. **Never edit anything under `libs/` or `tests/_kit/`** — a library problem is fixed in `../LibKa0s` and re-vendored back; the four vendor-gate diffs are in [docs/testing.md](./docs/testing.md), and every adoption decision is recorded under "LibKa0s adoption" in [docs/pending/LEDGER.md](./docs/pending/LEDGER.md).
- **Standard:** built to the [Ka0s WoW Addon Standard](https://github.com/tusharsaxena/WowAddonStandards) (`standards/STANDARDS.md` in that repo). The most recent compliance audit is frozen under [docs/audits/2026-08-04/](./docs/audits/2026-08-04/) (audited against Standard **v2.17.1**); the most recent engineering review is [docs/reviews/2026-08-03/](./docs/reviews/2026-08-03/). Earlier bundles are kept for history: [2026-07-18](./docs/audits/2026-07-18/) (Standard **v2.7.0**, its open MUST/SHOULD items remediated in `1c0248a`) and [2026-07-12](./docs/audits/2026-07-12/), which predates the modular restructure and carries the only `06_EXECUTION_OUTCOME`. Re-audit with `/wow-addon:standards-audit`. **Accepted, deliberate deviations are recorded as bullets in this file** — the six below cover the generated-data folder, the debug-console font, the TOC branding and omitted `X-Wago-ID`, the per-string editor layout, the test harness, and the TOC section order. That list is the source of truth for what intentionally diverges.
- **Generated-data exception (`layout`):** `GlobalStrings/` is a **generated-data folder at the repo root** — 10 machine-generated chunk files (~22,879 Blizzard reference strings) plus the source dump and `split_globalstrings.py` splitter. The modular layout has no home for bulk generated reference data, so it stays a documented root exception (loaded after `defaults/`, before `modules/`); regenerate with `python3 GlobalStrings/split_globalstrings.py`.
- **Accepted deviation — debug-console font (`debug-logging-§2`):** the on-screen debug console (`core/DebugLogSetup.lua`, drawn by `LibKa0s-DebugLog-1.0`) ships its monospace font (JetBrains Mono, OFL, under `media/fonts/`) and applies it via the `Const.FONT_MONO` path directly, **without** LibSharedMedia registration. This is a **deliberate design choice, not an oversight**: the debug console is intentionally fixed-monospace (readability of aligned log output does not depend on player taste), and PrettyChat ships **no font/texture/border picker** anywhere — every other font, texture, and border in the addon is a Blizzard default (see the 2026-07-17 media audit), so LSM has no consumer surface and the path constant alone suffices. Not to be "fixed" by adding LSM unless a user-facing media picker is deliberately introduced. The path is handed to the library as the console descriptor's `font`; the window itself is the library's.
- **Deliberate deviation from toc-file-§1 (TOC branding):** the `## Title:` keeps its rainbow `|cRRGGBB…|r` color escapes and `## Author:` keeps its stylized `aDd1kTeD2Ka0s` casing — both are the addon's brand mark, kept intentionally rather than plain-texted/normalized to the standard's `Ka0s Pretty Chat` / `add1kted2ka0s`. `## X-Wago-ID` is deliberately not carried: PrettyChat is distributed through CurseForge only (`## X-Curse-Project-ID: 919766`), so there is no Wago listing to reference. This is a settled decision, not a pending one — `toc-file-§1` asks for both ids once an addon is published anywhere, and this addon accepts that deviation rather than listing on Wago. Do not add the field, and do not commit a placeholder.
- **Accepted deviation — per-string editor layout (`options-ui-§6`):** the per-string editor in `settings/Panel.lua` uses a bespoke 40/60 three-row layout (`LEFT_W = 0.4` / `RIGHT_W = 0.6`) instead of the schema-driven 50/50 two-column grid. The right column holds full color-escaped format strings — Blizzard originals, the user's replacement, and the live preview — which need the extra width to be readable and editable without truncation; a 50/50 split clips them. Justified in-code above `buildStringRow` in `settings/Panel.lua`; recorded here because this file is the source of truth for what intentionally diverges. Re-checked against `LibKa0s-Options-1.0`'s caller-driven `RenderGrid` during the adoption and kept: `RenderGrid` offers `HALF` (0.5) or full width and no third ratio, so it cannot express 40/60 either (`LIBKA0S-06`). The library's `AttachTooltip`, `AddSpacer`, `EnsureScroll` and `SECTION_HEADING_H` are used throughout the block.
- **Accepted deviation — the test harness (`testing-§1`):** `tests/wow_mock.lua` is a thin extender over `tests/_kit/mock_base.lua` as the standard requires, but **`tests/loader.lua` survives** rather than deferring to `tests/_kit/loader.lua`. The kit builds one shared environment whose `__newindex` writes through to the real `_G`; this addon's entire feature is rewriting `_G[GLOBALNAME]` and half the suite asserts on what landed there, per instance. `tests/wow_mock.lua` points `_G` back at the mock table and `tests/loader.lua` builds a fresh mock per call, which is the isolation the kit has no mode for. The kit's `Loader.makeEnv` and `Loader.tocFiles` are both used, and the load list is derived from the TOC (`testing-§9`); the missing isolated-environment mode is reported upstream (`LIBKA0S-01`).
- **TOC section order (`toc-file-§5`) — standard-internal conflict, resolved in favor of section order:** the TOC file-listing follows `toc-file-§5` — `# Locales` sits immediately after `# Libraries` (`locales/enUS.lua` only builds `NS.L` and has no earlier-load dependency, so loading it first is safe). This is in **tension with `layout-§1`'s load-order list** (`defaults → locales`), which would place Locales after Defaults; the two standard rules disagree on where Locales belongs. Resolved here toward `toc-file-§5`. The conflict is **raised upstream** as [WowAddonStandards#2](https://github.com/tusharsaxena/WowAddonStandards/issues/2) (which also records a second contradiction between the same two sections: `layout-§1` orders `settings/* → modules/*`, `toc-file-§5` orders Modules → Settings — this TOC follows `toc-file-§5` there too). If that issue resolves in favor of `layout-§1`, revisit both orderings here. The non-canonical `# GlobalStrings` section is simply the TOC home of the generated-data root exception noted above.
## Standards compliance (read first)

This repo is built to the **Ka0s WoW Addon Standard**
(https://github.com/tusharsaxena/WowAddonStandards). All development here — features, refactors,
doc changes — MUST conform to it. The standard is the source of truth for layout, TOC shape, the
Ace substrate, schema-driven settings, slash/prefix conventions, locales, Compat, tests/lint, and
doc structure.

**If a change would deviate from the standard, STOP and flag the deviation explicitly.** Do not
silently deviate and do not silently "fix" to match. Surface it and let the user decide which of
two things it is:

1. **An accepted deviation** — this addon intentionally differs; record it as a documented
   deviation (e.g. in the TOC/README/`docs/` and in the audit bundle), with the reason.
2. **A change to the standard itself** — the standard's definition should evolve; the update
   belongs upstream in the WowAddonStandards repo, after which this addon conforms to the new rule.

When in doubt, treat standard conformance as a hard requirement and ask.

## The `docs/` set — there is no `agent-context.md`

The canonical `docs/` set is exactly three files: **`ARCHITECTURE.md`** (what this addon is),
**`testing.md`** (how to verify) and **`smoke-tests.md`** (in-game checks) — plus the generated
`test-cases.md` and the topic-detail docs.

**`docs/agent-context.md` does not exist in this repo and MUST NOT be created.** The standard
deleted it in **v2.17.0**; shipping it is **anti-pattern #49**. It held `NEW_ADDON_CONTEXT.md` —
the scaffolding pack — which is fetched at runtime and never stored: a copy in the repo describes
the addon on the day it was born, forever, and because it loads as *working context* a stale copy
does not go quiet, it gets **followed** (documentation-§3). This root `CLAUDE.md` is the repo's
only agent brief.

Older audit bundles, review bundles, ledgers and plans under `docs/` predate v2.17.0 and still
name the file, and some describe a four-file or a pre-v2.3.0 `agent-context.md`-based set. Those
are **frozen history** — never treat them as a live requirement, and never "restore" the file.

## Before touching code

Read the docs — start with **[docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)** (what this addon is: module map, namespace publishing table, invariants, working environment, doc index), then **[docs/testing.md](./docs/testing.md)** (how to verify), then the topic-detail docs it indexes. What to install: **[DEPENDENCIES.md](./DEPENDENCIES.md)**. User-facing reference: **[README.md](./README.md)**.

## Non-negotiable guardrails

- **Code invariants (detail in ARCHITECTURE).** Settings mutate only through `NS.Schema.Set`; `_G[GLOBALNAME]` is assigned only in `ApplyStrings`; all chat output goes through `NS.Print` (no raw `print`) and all gated logging through `NS.Debug`; user-facing strings go through `NS.L`.
- **Never edit `libs/` or `tests/_kit/`.** Both are vendored whole from the sibling `../LibKa0s` checkout. A local patch is a fork nobody knows about and the next re-vendor reverts it silently — so a library problem is fixed upstream and re-vendored back, whole folder, never file by file. The four vendor-gate diffs are in [docs/testing.md](./docs/testing.md).
- **Never hand a LibKa0s descriptor `NS.L`.** The locale table answers every key with the key, so a module handed it renders raw `SCREAMING_SNAKE` keys in place of English — every key at once, visible only in game. Translate by passing a **plain** table of just the keys you translate. `tests/test_libka0s.lua` greps every seam file for all three spellings.
- **Test gate.** After every change, `lua tests/run.lua` must be green and `luacheck .` clean.
- **Keep the test-case inventory & badge in sync (`testing-§5`).** When the suite changes — a case added/removed/renamed or the pass count moves (i.e. whenever a failing test is resolved) — regenerate `docs/test-cases.md` via `lua tests/run.lua --list` **and** update the README `Tests` badge count **in the same change**, not as a follow-up. `docs/test-cases.md` is generated (never hand-edited) and is the authoritative pass count.
- **Static README badges track their source of truth (`documentation-§1`).** The `[WoW]` and `[Tests]` badges are static shields.io images that go stale silently: `[WoW]` ↔ TOC `## Interface:` (they MUST show the same number — bump both together on every client-patch bump); `[Tests]` ↔ the regenerated `docs/test-cases.md` total (rule above). Update the badge in the **same change** that moves its source, never as a follow-up.
- **Never auto-stage, auto-commit, or auto-push.** Leave edits as unstaged working-tree changes unless explicitly told otherwise (the `/wow-addon:commit` skill is the exception — it runs its own confirmation gate).
- **Never bump the version** (`## Version:` in `PrettyChat.toc`, README badges/changelog) without an explicit instruction.
