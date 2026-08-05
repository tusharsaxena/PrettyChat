# CLAUDE.md — Ka0s Pretty Chat

**Ka0s Pretty Chat** — a WoW addon that reformats system chat messages by overriding Blizzard's `GlobalStrings.lua` format strings (not by parsing chat events).

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

## Repo facts an agent needs before reading anything else

- **Layout:** modular — source `.lua` lives under `core/`, `defaults/`, `locales/`, `modules/`, `settings/`; libraries are vendored under `libs/`. This is the single Ka0s layout (`layout-§1`), used by every addon regardless of size.
- **Library:** vendors **[LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.8.0** whole into `libs/LibKa0s/` (TOC: `libs\LibKa0s\LibKa0s.xml`, after Ace3) and the shared test kit into `tests/_kit/`. **Four of five majors are adopted** — Core (`core/CoreSetup.lua`), DebugLog (`core/DebugLogSetup.lua`), Slash (`settings/Slash.lua`) and Options (`settings/OptionsSetup.lua`). **Perf is declined** under a recorded `performance-§12` no-combat-path exemption — the register row in [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md), its committed sweep in [docs/performance.md](./docs/performance.md), and its reasoning at `LIBKA0S-12`. **Never edit anything under `libs/` or `tests/_kit/`** — a library problem is fixed in `../LibKa0s` and re-vendored back; the four vendor-gate diffs are in [docs/testing.md](./docs/testing.md), and every adoption decision is recorded under "LibKa0s adoption" in [docs/pending/LEDGER.md](./docs/pending/LEDGER.md).
- **Standard:** built to the [Ka0s WoW Addon Standard](https://github.com/tusharsaxena/WowAddonStandards) (`standards/STANDARDS.md` in that repo). The most recent compliance audit is frozen under [docs/audits/2026-08-04/](./docs/audits/2026-08-04/) (audited against Standard **v2.17.1**); the most recent engineering review is [docs/reviews/2026-08-03/](./docs/reviews/2026-08-03/). Earlier bundles are kept for history: [2026-07-18](./docs/audits/2026-07-18/) (Standard **v2.7.0**, its open MUST/SHOULD items remediated in `1c0248a`) and [2026-07-12](./docs/audits/2026-07-12/), which predates the modular restructure and carries the only `06_EXECUTION_OUTCOME`. Re-audit with `/wow-addon:standards-audit`. **Accepted, deliberate deviations live in one place only: `## Documented deviations` in [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)** (`documentation-§3`). That register carries the `filename-§N` rule, what differs, why, the date decided and the re-check trigger for each of the eight — the declined perf harness, the `GlobalStrings/` root folder, the TOC section order, the TOC branding and omitted `X-Wago-ID`, the debug-console font, the per-string editor layout, the test loader, and the two Ace libs this addon does not vendor. Do not re-record a deviation in this file: a deviation not in the register is not ratified.

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
