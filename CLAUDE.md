# CLAUDE.md — Ka0s Pretty Chat

**Ka0s Pretty Chat** — a WoW addon that reformats system chat messages by overriding Blizzard's `GlobalStrings.lua` format strings (not by parsing chat events).

- **Layout:** modular — source `.lua` lives under `core/`, `defaults/`, `locales/`, `modules/`, `settings/`; libraries are vendored under `libs/`. This is the single Ka0s layout (`layout-§1`), used by every addon regardless of size.
- **Standard:** built to the [Ka0s WoW Addon Standard](https://github.com/tusharsaxena/WowAddonStandards) (`standards/STANDARDS.md` in that repo). The most recent compliance audit is frozen under [docs/audits/2026-07-18/](./docs/audits/2026-07-18/) (audited against Standard **v2.7.0**; its open MUST/SHOULD items were remediated in `1c0248a`). The prior bundle — [docs/audits/2026-07-12/](./docs/audits/2026-07-12/), which predates the modular restructure and carries the only `06_EXECUTION_OUTCOME` — is kept for history. Re-audit with `/wow-addon:standards-audit`. **Accepted, deliberate deviations are recorded as bullets in this file** — the five below cover the generated-data folder, the debug-console font, the TOC branding and omitted `X-Wago-ID`, the per-string editor layout, and the TOC section order. That list is the source of truth for what intentionally diverges.
- **Generated-data exception (`layout`):** `GlobalStrings/` is a **generated-data folder at the repo root** — 10 machine-generated chunk files (~22,879 Blizzard reference strings) plus the source dump and `split_globalstrings.py` splitter. The modular layout has no home for bulk generated reference data, so it stays a documented root exception (loaded after `defaults/`, before `modules/`); regenerate with `python3 GlobalStrings/split_globalstrings.py`.
- **Accepted deviation — debug-console font (`debug-logging-§2`):** the on-screen debug console (`core/DebugLog.lua`) ships its monospace font (JetBrains Mono, OFL, under `media/fonts/`) and applies it via the `Const.FONT_MONO` path directly, **without** LibSharedMedia registration. This is a **deliberate design choice, not an oversight**: the debug console is intentionally fixed-monospace (readability of aligned log output does not depend on player taste), and PrettyChat ships **no font/texture/border picker** anywhere — every other font, texture, and border in the addon is a Blizzard default (see the 2026-07-17 media audit), so LSM has no consumer surface and the path constant alone suffices. Not to be "fixed" by adding LSM unless a user-facing media picker is deliberately introduced.
- **Deliberate deviation from toc-file-§1 (TOC branding):** the `## Title:` keeps its rainbow `|cRRGGBB…|r` colour escapes and `## Author:` keeps its stylised `aDd1kTeD2Ka0s` casing — both are the addon's brand mark, kept intentionally rather than plain-texted/normalised to the standard's `Ka0s Pretty Chat` / `add1kted2ka0s`. `## X-Wago-ID` is deliberately not carried: PrettyChat is distributed through CurseForge only (`## X-Curse-Project-ID: 919766`), so there is no Wago listing to reference. This is a settled decision, not a pending one — `toc-file-§1` asks for both ids once an addon is published anywhere, and this addon accepts that deviation rather than listing on Wago. Do not add the field, and do not commit a placeholder.
- **Accepted deviation — per-string editor layout (`options-ui-§6`):** the per-string editor in `settings/Panel.lua` uses a bespoke 40/60 three-row layout (`LEFT_W = 0.4` / `RIGHT_W = 0.6`) instead of the schema-driven 50/50 two-column grid. The right column holds full colour-escaped format strings — Blizzard originals, the user's replacement, and the live preview — which need the extra width to be readable and editable without truncation; a 50/50 split clips them. Justified in-code at `settings/Panel.lua:418`; recorded here because this file is the source of truth for what intentionally diverges.
- **TOC section order (`toc-file-§5`) — standard-internal conflict, resolved in favour of section order:** the TOC file-listing follows `toc-file-§5` — `# Locales` sits immediately after `# Libraries` (`locales/enUS.lua` only builds `NS.L` and has no earlier-load dependency, so loading it first is safe). This is in **tension with `layout-§1`'s load-order list** (`defaults → locales`), which would place Locales after Defaults; the two standard rules disagree on where Locales belongs. Resolved here toward `toc-file-§5`. The conflict is **raised upstream** as [WowAddonStandards#2](https://github.com/tusharsaxena/WowAddonStandards/issues/2) (which also records a second contradiction between the same two sections: `layout-§1` orders `settings/* → modules/*`, `toc-file-§5` orders Modules → Settings — this TOC follows `toc-file-§5` there too). If that issue resolves in favour of `layout-§1`, revisit both orderings here. The non-canonical `# GlobalStrings` section is simply the TOC home of the generated-data root exception noted above.

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

## Before touching code

Read the docs — start with **[docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)** (what this addon is: module map, namespace publishing table, invariants, working environment, doc index), then **[docs/testing.md](./docs/testing.md)** (how to verify), then the topic-detail docs it indexes. User-facing reference: **[README.md](./README.md)**.

## Non-negotiable guardrails

- **Code invariants (detail in ARCHITECTURE).** Settings mutate only through `NS.Schema.Set`; `_G[GLOBALNAME]` is assigned only in `ApplyStrings`; all chat output goes through `NS.Print` (no raw `print`) and all gated logging through `NS.Debug`; user-facing strings go through `NS.L`.
- **Test gate.** After every change, `lua tests/run.lua` must be green and `luacheck .` clean.
- **Keep the test-case inventory & badge in sync (`testing-§5`).** When the suite changes — a case added/removed/renamed or the pass count moves (i.e. whenever a failing test is resolved) — regenerate `docs/test-cases.md` via `lua tests/run.lua --list` **and** update the README `Tests` badge count **in the same change**, not as a follow-up. `docs/test-cases.md` is generated (never hand-edited) and is the authoritative pass count.
- **Static README badges track their source of truth (`documentation-§1`).** The `[WoW]` and `[Tests]` badges are static shields.io images that go stale silently: `[WoW]` ↔ TOC `## Interface:` (they MUST show the same number — bump both together on every client-patch bump); `[Tests]` ↔ the regenerated `docs/test-cases.md` total (rule above). Update the badge in the **same change** that moves its source, never as a follow-up.
- **Never auto-stage, auto-commit, or auto-push.** Leave edits as unstaged working-tree changes unless explicitly told otherwise (the `/wow-addon:commit` skill is the exception — it runs its own confirmation gate).
- **Never bump the version** (`## Version:` in `PrettyChat.toc`, README badges/changelog) without an explicit instruction.
