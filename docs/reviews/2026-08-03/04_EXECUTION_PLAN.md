# Execution plan — agent team (2026-08-03)

Source: `01_FINDINGS.md` (F-001…F-016) and `02_PROPOSED_CHANGES.md` (C-01…C-08, U-01).

House rules that bind this plan: work **trunk-based** — no branch unless the user asks
(anti-pattern #21, versioning-git); commit only on **green** `lua tests/run.lua` **and** clean
`luacheck .` (anti-pattern #23); every logic change lands with a covering test (anti-pattern #24,
testing); nothing under `libs/` or `tests/_kit/` is edited by any task in M1–M4.

---

## M0 — Baseline

**Done when:** `lua tests/run.lua` is green (255/255 today), `luacheck .` is clean, and both numbers
are recorded in the commit message of the first task.

| Task | Owner role | Implements | Files touched |
|---|---|---|---|
| T-00 | build-verifier | — | none (read-only) |

---

## M1 — Correctness of the shipped data and the write seam

**Done when:** the two bad templates are fixed, `Schema.Set` refuses a signature-incompatible string
on both the panel and the CLI, `NS.RenderSample` renders against the original's argument list, and
new tests cover: accept-valid, reject-extra-conversion, reject-reordered, accept-tail-truncation,
and preview-uses-reference-signature.

| Task | Owner role | Implements | Files touched | Parallel? |
|---|---|---|---|---|
| T-01 | wow-data-fixer | C-01 (F-001) | `defaults/Defaults.lua` | yes (disjoint) |
| T-02 | lua-refactorer | C-02 signature helper + `Schema.Set` validate (F-002) | `settings/Schema.lua`, `locales/enUS.lua`, `tests/test_schema.lua` | no — serializes with T-04, T-05, T-06 (all `settings/Schema.lua`) |
| T-03 | lua-refactorer | C-02 preview arm (F-002, F-011) | `modules/Override.lua`, `settings/Panel.lua`, `tests/test_render.lua`, `tests/test_panel.lua` | after T-02 (uses `Schema.Signature`) |

**Checkpoint CP-1 (human):** in-client, run `03_SMOKE_TESTS.md` sections **C-01** and **C-02**. Do not
start M2 until the refusal path is confirmed on both surfaces and no valid edit is being rejected.

---

## M2 — The original, and the snapshot it comes from

**Done when:** the panel's Original box is fed by the live snapshot, the snapshot is taken once with
a sentinel, the ten `GlobalStrings_0NN.lua` TOC lines are gone, and `tests/test_panel.lua`'s two
`NS.GlobalStrings` cases are rewritten against the new accessor.

| Task | Owner role | Implements | Files touched | Parallel? |
|---|---|---|---|---|
| T-04 | lua-refactorer | C-04 (F-006) | `core/PrettyChat.lua`, `core/Constants.lua`, `modules/Override.lua`, `tests/test_apply.lua`, `tests/test_lifecycle.lua` | **first** in M2 — T-05 trusts its snapshot |
| T-05 | lua-refactorer | C-03 accessor + panel read (F-003) | `modules/Override.lua`, `settings/Panel.lua`, `tests/test_panel.lua`, `tests/test_override.lua` | after T-04; shares `modules/Override.lua` with T-03/T-04 → **serialize** |
| T-06 | packaging-cleanup | C-03 TOC/pkgmeta/doc half (F-003) | `PrettyChat.toc`, `.pkgmeta`, `docs/global-strings.md`, `docs/file-index.md`, `docs/module-map.md`, `tests/loader.lua`, `tests/test_locale.lua` | after T-05 (the runtime must not need the chunks before they leave the TOC) |

**Checkpoint CP-2 (human):** run smoke sections **C-03**, **C-04**, the **Localization sanity** block
on a deDE client, and perf spot-checks 1 and 2 — record the before/after memory numbers, they are
this milestone's evidence.

---

## M3 — Structure: one order, one partition, one bulk tail

**Done when:** no file outside `settings/Schema.lua` sorts a name list or partitions rows, and the
three reset paths call one seam.

| Task | Owner role | Implements | Files touched | Parallel? |
|---|---|---|---|---|
| T-07 | lua-refactorer | C-05 (F-007, F-009) | `settings/Schema.lua`, `modules/Override.lua`, `settings/Panel.lua`, `settings/Slash.lua`, `tests/test_schema.lua`, `tests/test_apply.lua` | serializes behind T-02 (`settings/Schema.lua`) |
| T-08 | lua-refactorer | C-06 (F-008) | `settings/Schema.lua`, `modules/Override.lua`, `tests/test_override.lua` | after T-07 (same two files) |

**Checkpoint CP-3 (human):** smoke sections **C-05**, **C-06**, plus regression rows R-06, R-07,
R-10. This is the milestone most likely to regress panel refresh — verify the panel repaints without
a `/reload` after every reset shape.

---

## M4 — Hygiene

**Done when:** the locale manifest covers every `L[...]` literal (asserted by
`tests/test_locale.lua`), no chat line ends in a colon, and no comment names `Config.lua` or `§4.5`.

| Task | Owner role | Implements | Files touched | Parallel? |
|---|---|---|---|---|
| T-09 | ux-cleanup | C-07 (F-004, F-005) | `settings/Schema.lua`, `settings/Panel.lua`, `modules/Override.lua`, `settings/Slash.lua`, `locales/enUS.lua`, `tests/test_locale.lua` | serializes behind T-07/T-08 |
| T-10 | doc-cleanup | C-08 (F-010, F-012, F-013, F-014, F-015) | `core/Constants.lua`, `core/Namespace.lua`, `core/Util.lua`, `settings/Schema.lua`, `settings/Panel.lua`, `core/PrettyChat.lua`, `settings/OptionsSetup.lua`, `docs/file-index.md`, `docs/module-map.md`, `tests/test_panel.lua`, `tests/test_constants.lua` | last (touches nearly everything, all trivially) |

**Checkpoint CP-4 (human):** smoke sections **C-07**, **C-08**, and the full regression table.

---

## M5 — Upstream (cross-repo) — **separate, never folded into M1–M4**

**Done when:** the LibKa0s repo carries the comment fix with `Options.lua`'s minor bumped, and this
addon carries a **re-vendor commit** whose only changed paths are under `libs/LibKa0s/`, with
`diff -r <LibRepo>/LibKa0s prettychat/libs/LibKa0s` empty.

| Task | Owner role | Implements | Repo | Files |
|---|---|---|---|---|
| T-11 | library-maintainer | U-01 (F-016) | **LibKa0s** | `LibKa0s/Options.lua` (comments + `MINOR` 5→6), `CHANGELOG.md` |
| T-12 | vendor-sync | U-01 landing | **prettychat** | `libs/LibKa0s/**` only — whole-folder copy |
| T-13 | vendor-sync | U-01 landing | every other LibKa0s consumer | `libs/LibKa0s/**` only |

**Handoff note:** T-12 must not begin until T-11 is committed in the library repo; the re-vendor is a
copy of the ship folder, never a hand-edit of the differing lines.

---

## Critical path / concurrency map

```
T-00 ──► T-01 (independent, may run any time)
      └► T-02 ──► T-03 ──► T-04 ──► T-05 ──► T-06 ──► T-07 ──► T-08 ──► T-09 ──► T-10
                                        (CP-1)        (CP-2)         (CP-3)      (CP-4)
T-11 ──► T-12 ──► T-13     (independent repo; land any time after M0)
```

- **Serialize:** `settings/Schema.lua` is touched by T-02, T-07, T-08, T-09, T-10 → strict order.
  `modules/Override.lua` is touched by T-03, T-04, T-05, T-07, T-08 → strict order.
  `settings/Panel.lua` is touched by T-03, T-05, T-09, T-10 → strict order.
- **Parallelizable:** T-01 (`defaults/Defaults.lua` only) against anything; the whole M5 chain
  against M1–M4 (different repo / disjoint paths).

---

## Incremental commit strategy

One commit per task, each green on tests + lint before it lands.

| Task | Suggested message |
|---|---|
| T-01 | `fix(defaults): match Blizzard's argument list on the two reputation templates (F-001)` |
| T-02 | `feat(schema): validate a format string's conversion signature at the write seam (F-002)` |
| T-03 | `fix(preview): render samples from the ORIGINAL's argument list, not the replacement's (F-002)` |
| T-04 | `fix(core): snapshot the Blizzard originals once, with a sentinel for absent keys (F-006)` |
| T-05 | `fix(panel): read the original from the live localized snapshot (F-003)` |
| T-06 | `chore(toc): retire the eager enUS GlobalStrings load from the runtime (F-003)` |
| T-07 | `refactor(schema): one ordered name index and one category partition (F-007, F-009)` |
| T-08 | `refactor(schema): route the three bulk resets through one apply/notify/log tail (F-008)` |
| T-09 | `i18n: localize the remaining user-facing strings; drop the trailing colon (F-004, F-005)` |
| T-10 | `docs+naming: retire the Config.lua references and the §4.5 cross-ref (F-010, F-012…F-015)` |
| T-12 | `chore(libs): re-vendor LibKa0s (Options minor 6) — upstream comment fix (F-016)` |
