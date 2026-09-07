# 01 — Current State (Ka0s Pretty Chat)

**Run date:** 2026-09-07
**Audited against:** Ka0s WoW Addon Standard **v2.38.0 (2026-09-02)** — index `standards/STANDARDS.md`
plus all 26 section files it links, fetched verbatim with `curl -fsSL`.
**Playbook:** `AUDIT.md` @ `WowAddonStandards` master, fetched the same way.
**ID prefix:** `PC-` (stable across runs). The consolidated digest for this cycle mirrors each ID as
`PRETTYCHAT-A-NN`; the mapping is in `02_DEVIATIONS.md`.
**Previous run:** `docs/audits/2026-08-05/` (against v2.21.0).
**Rule set used:** the **addon** sections — the repo ships `PrettyChat.toc`, so it is an addon and not
a Ka0s-owned library repo (`AUDIT.md` step 1).

---

## Layout (`layout`)

Modular skeleton, all lowercase: `core/`, `defaults/`, `locales/`, `modules/`, `settings/`, plus
`libs/`, `media/`, `docs/`, `tests/`. One out-of-skeleton root folder, `GlobalStrings/` — a
**ratified** deviation (`docs/ARCHITECTURE.md:221`, `layout-§2`, decided 2026-08-05), unshipped and
unloaded (`.pkgmeta:24`).

Source sizes: `settings/Panel.lua` 779, `settings/Schema.lua` 534, `modules/Override.lua` 433,
`settings/Slash.lua` 390, `defaults/Defaults.lua` 368 — no shipped file in `layout-§1`'s 1000–1500
on-notice band. `media/` holds only `logos/` and `screenshots/`; nothing under it duplicates
`libs/LibKa0s/media/` (`library-stack-§8`, anti-pattern #63).

## TOC (`toc-file`)

`PrettyChat.toc:1-13` carries the full metadata block in order, single Retail `## Interface: 120007`,
`## X-License: MIT`, `## X-Standard:` and `## X-Curse-Project-ID: 919766` (published, so the field is
mandatory and present). `## SavedVariables: PrettyChatDB` declares one global, which is correct under
the recorded `performance-§12` exemption (no `PrettyChatPerfDB` ring).

File listing sections are `# Libraries → # Locales → # Core → # Defaults → # Modules → # Settings`
(`:15,24,27,46,50,53`) — the canonical order, and the same order `layout-§1:53` now states. The
non-canonical `# GlobalStrings` section of earlier runs is gone. Two load-bearing positions carry
at-line annotations naming what resolves (`:28-32` for `core\EnvSetup.lua`, `:34-35` for
`core\MediaSetup.lua`); several others do not — see PC-60.

`libs\LibKa0s\LibKa0s.xml` is listed once, after Ace3 (`:21`); no individual LibKa0s `.lua` line.

## Libraries (`library-stack`)

Vendored: LibStub, CallbackHandler-1.0, AceAddon-3.0, AceDB-3.0, AceConsole-3.0, AceGUI-3.0, and
**LibKa0s v1.25.0** as the whole ship folder. `AceEvent-3.0`/`AceTimer-3.0` are deliberately not
vendored — a ratified row (`docs/ARCHITECTURE.md:230`) recording the `library-stack-§1` vs `§3`
contradiction, which still stands in v2.38.0 (`library-stack.md:13-14` vs `:39`).

Vendored-payload diffs against the tag the provenance line names (`CLAUDE.md:30`, v1.25.0), run
against the sibling `../../LibKa0s` checkout: **both empty**. Details in `03_EVIDENCE.md`.

Six of ten majors adopted through setup files, each with a descriptor and a degradation stub:
`core/CoreSetup.lua` (Core), `core/EnvSetup.lua` (Env), `core/MediaSetup.lua` (Media),
`core/DebugLogSetup.lua` (DebugLog), `settings/Slash.lua` (Slash), `settings/OptionsSetup.lua`
(Options). **Perf is declined** under a recorded `performance-§12` exemption
(`docs/ARCHITECTURE.md:220`, re-checked 2026-09-02). Item/Pool/Widgets are unwired, each with a
closed `state:will-not-do` issue (#11, #12, #13). The addon carries **no** hand-rolled console,
widget maker, dispatcher or test framework — anti-pattern #47 does not fire.

The one `MakeCloseButton` wrapper is `core/CoreSetup.lua:111-113`, three-argument and fed
`addonName`; the whole-repo grep finds no other host call site.

## Patterns (`architecture`, `public-api`, `naming-cheatsheet`)

`NS`-on-vararg namespace, one AceAddon object (`core/PrettyChat.lua:14`), schema-as-single-source
(`settings/Schema.lua`), one write path `Schema.Set`. There is **no** message bus:
`docs/ARCHITECTURE.md:123-129` records the absence and what stands in its place. Since the settings
revamp, `modules/Override.lua:78-96` registers two game events on `PrettyChatCombatWatcher`, which
trips `architecture-§4`'s applicability clause — see PC-62.

## Settings (`options-ui`)

Two rendered pages plus the host landing page. **General** (`settings/Panel.lua:736,741`) draws the
composed `Master controls` tab through `H.RenderTabbedSchema`; **Categories**
(`settings/Panel.lua:745,773`) draws an eight-tab strip via `H.TabStrip`
(`settings/Panel.lua:616-623`). The landing page is the host's `buildParentBody`
(`settings/Panel.lua:646`) — one of the two pages `options-ui-§13` exempts.

The `Master controls` block is **composed**, never hand-written (`settings/Schema.lua:79-120`
`MASTER_SPEC`), with `frameless = true` proven by a whole-repo `SetMovable` sweep that returns only
the two comments saying so. The row set is enable + general visibility + debug console + reset all,
which is the canonical subsequence for a frameless addon. `General.visibility` is **new** at that
path (introduced 2026-09-02 in `8ee771a`), so no stored-type migration is owed.

No color rows, so `options-ui-§17`'s companion/`disabledIf` checks do not apply. No `LSM30_*`
control, no chat-scroll reorder art, no `InlineGroup`/backdrop box around a chrome band.

## Slash (`slash-commands`)

Ten verbs in one host-owned `COMMANDS` table (`settings/Slash.lua:45-66`), crossing to
`LibKa0s-Slash-1.0` as plain data. `perf` is correctly **not** registered under the exemption and
stays reserved. `reset` takes a path.

## Debug (`debug-logging`)

`core/DebugLogSetup.lua` builds `NS.DebugLog` from a `LibKa0s-DebugLog-1.0` descriptor with
`addonName`, and carries a member-answering stub (`:41-108`). The console font reaches the library as
`Const.FONT_MONO`; LSM registration is a documented no-op (`docs/ARCHITECTURE.md:224`,
`core/MediaSetup.lua:88`).

## Tests (`testing`, `automated-tests`)

`tests/run.lua` + 18 suite files, `tests/_kit/` vendored from the library repo root, plus the
addon-side `tests/loader.lua` isolation factory — a ratified `testing-§1` row
(`docs/ARCHITECTURE.md:227`). Measured today: **300 passed, 0 failed, 0 skipped**; `luacheck .`
**0 warnings / 0 errors in 18 files**. `docs/automated-tests/` holds seven frozen bundles,
`README.md` and `RESULTS.md`; the newest bundle is `20260825-103457`, and no run has been recorded
since the 2026-09-03 settings work — see PC-65.

## Performance (`performance`)

No harness, under the ratified `performance-§12` no-combat-path exemption
(`docs/ARCHITECTURE.md:220`, decided 2026-08-05, re-checked 2026-09-02, reasoned at issue #10). No
`docs/perf-analysis/` store, which is the compliant state for that exemption, and no retired
`docs/perf-runs/` directory.

## Packaging (`packaging`)

`.pkgmeta` ignores `.luacheckrc`, `.gitignore`, `.gitattributes`, `docs`, `tests`, `_dev`, `*.bak`,
`GlobalStrings`, `media/screenshots` and the non-loadable logo formats, each with a comment.
`.claude/` is **not** ignored — see PC-63.

## Line endings (`line-endings`)

`.gitattributes` present at root, client-bound variant, pin recorded verbatim: `* text=auto eol=crlf`
(`.gitattributes:26`), `*.sh text eol=lf` (`.gitattributes:34`), 20 `binary` rows, and the
renormalize recipe in the trailer. The body matches the canonical client-bound file. Working-tree
agreement measured at **4 files** — see PC-66.

## Root docs (`documentation-§1/§2/§7`)

`README.md` — 13-section canonical order with no `## Unreleased`, no `## Credits`, no bundled-library
inventory, and the standard badge in the bare `![Standard](…)` form (`README.md:6`). Badges are in
sync: `WoW-Midnight_12.0.7` vs `## Interface: 120007`, `Tests-300%2F300` vs `docs/test-cases.md:385`.
`CLAUDE.md` — 64-line stub carrying `## Standards compliance (read first)`, the docs pointer list, the
green gate and the LibKa0s provenance line at `:30`; the provenance line is **absent** from
`README.md`, which is where the gate requires it not to be. `DEPENDENCIES.md` — evidence-based, split
runtime / development / release / verification.

## `docs/` (`documentation-§3`)

Tier 1 complete under canonical names. Tier 2 fully accounted for — `slash-dispatch.md` present, six
*Not applicable* rows each carrying its trigger, all six verified against the code today. Verification
set complete (`test-cases.md`, `performance.md`, `automated-tests/README.md`,
`automated-tests/RESULTS.md`; `perf-analysis/README.md` correctly absent under the exemption). One
Tier 3 doc, `global-strings.md`. No `file-index.md`, no `conventions.md`, no `complexity.md`, no
`docs/perf-runs/`, no `docs/agent-context.md`, no non-canonical Tier 1/2 filename. Hub is 269 lines
with no mandated section past 44. `## Documented deviations` holds eleven ratified rows.

## Recorded-deviation register and issue store

`docs/ARCHITECTURE.md:207-230` — eleven rows, each with rule, reason, Decided date and re-check
trigger. `gh issue list` returns 13 issues, every one carrying a `state:` and a `severity:` label, no
`[status]` title prefix, no surviving `docs/pending/LEDGER.md`. Every `state:will-not-do` issue that
records a **standards** decline has a matching register row; issues #11/#12/#13 (unwired LibKa0s
majors) and #8 (profile scoping, a `MAY`) are not deviations and correctly have none. One register row
is stale against the current standard — PC-61.
