# 05 — Execution Plan (remediation hand-off)

**Run date:** 2026-08-04 · **Standard:** v2.17.1 (2026-08-03)

Ordered, checkable steps closing the deviations in `02_DEVIATIONS.md`, per the design in
`04_TECHNICAL_DESIGN.md`. Each step names its deviation ID(s). This audit applied none of them.

**Gate on every commit:** `lua tests/run.lua` green **and** `luacheck .` clean. Trunk-based, no
branch, no push unless asked.

---

## Sprint 0 — Decisions (no code)

The only blocking work. Everything in Sprint 1 can proceed in parallel; Sprint 2 cannot start
until **0.1** is answered.

| # | Step | IDs | Owner |
|---|---|---|---|
| **0.1** | **Decide the performance question.** Present the two routes from `04_TECHNICAL_DESIGN.md` §A: **A1** wire the harness with an empty bucket set and an honest `suspend` (~1 file + 1 scenario + 4 cases), or **A2** take the decline upstream as a `performance` carve-out for addons with no post-login execution path. Record the answer in `docs/deviations.md` either way. | PC-40 … PC-45 | user |
| **0.2** | **Decide the generated-data route.** **D1** relocate to `defaults/globalstrings/` and re-split under 1500 lines (closes PC-25 + PC-49), or **D2** widen the written exception to name `layout-§1`'s cap, `layout-§2` and `toc-file-§5` (closes neither, but makes both explicit). Design recommends D1. | PC-25, PC-49 | user |
| **0.3** | **Decide the message-bus route.** **E1** one `Ka0s_PrettyChat_SettingsChanged` message with a single `NS.NewBusTarget()` receiver, or **E2** record the absence as an accepted deviation with the single-module rationale. | PC-50 | user |

**Exit criteria:** three recorded answers. Nothing else in this plan is ambiguous.

---

## Sprint 1 — Zero-risk doc corrections

No decision needed, no code touched, no test moves. Do these first so the open-MUST count drops
while Sprint 0 is being answered.

| # | Step | IDs | Verify |
|---|---|---|---|
| **1.1** | `README.md:116` — replace `` `/pc reset <setting>` `` with `` `/pc reset setting` ``. **Do not** run a blanket `<…>` sweep. | PC-46 | `grep -n '<[a-zA-Z][a-zA-Z_ -]*>' README.md` → no matches |
| **1.2** | Move `## Unreleased` (`README.md:15-19`). Preferred: fold its three bullets into the next version bump's `## What's new` + Version History row via `wow-addon:bump-version`. If no bump is imminent, merge them into `## What's new in 1.4.0` and delete the section. | PC-47 | README `##` headings match `documentation-§1`'s twelve, in order |
| **1.3** | Move `## Credits` (`README.md:120-122`) — the LibKa0s attribution — into the Description paragraph or `docs/ARCHITECTURE.md § External dependencies` (`:137`), and delete the section. | PC-47 | as above |
| **1.4** | Create **`docs/deviations.md`**; move `CLAUDE.md:8-13`'s six accepted-deviation records into it **verbatim**, one section each, cross-referenced to PC-23, PC-25, PC-27, PC-49, PC-51, PC-54 and to WowAddonStandards#2. | PC-48 (prep) | file exists; every ID in `02_DEVIATIONS.md` marked `documented` resolves to a section in it |
| **1.5** | Reduce root `CLAUDE.md` to `documentation-§2`'s five items **in order** (H1 → adherence → `## Standards compliance (read first)` **verbatim, unchanged** → read-the-docs pointers incl. `docs/deviations.md` → green-gate line). Keep the "no `agent-context.md`" note compressed inside item 4, and the three hard guardrails (never edit `libs/`/`tests/_kit/`; never hand a descriptor `NS.L`; keep inventory + badge in lockstep) as short bullets. | PC-48 | file is a stub; `documentation-§6`'s three places still complete (TOC `:12`, README `:6`, `CLAUDE.md`) |
| **1.6** | Add a `## Message Bus` heading to `docs/ARCHITECTURE.md` between `## Settings Schema` and `## Slash Commands`, carrying the sentence currently at `:119`. | PC-53 | `grep -n '^## Message Bus' docs/ARCHITECTURE.md` |
| **1.7** | Generate `docs/complexity.md` — `lizard core defaults settings modules locales > docs/complexity.md` — with a header line saying it is generated and how. If `lizard` is not installed, record that in `docs/deviations.md` rather than leaving PC-55 silent. | PC-55 | file exists **or** an explicit tooling note exists |

**Exit criteria:** `luacheck .` clean (unchanged — no Lua touched); `lua tests/run.lua` still
255/255; README section list matches the canonical twelve; `CLAUDE.md` under ~20 lines.

**Closes:** PC-46, PC-47, PC-48, PC-53, PC-55 — **3 MUST + 2 SHOULD**.

---

## Sprint 2 — Performance (gated on decision 0.1)

### If **A1** (wire it)

TDD throughout: each step's tests land red first.

| # | Step | IDs |
|---|---|---|
| **2.1** | **Test first.** Add `tests/test_perf.lua`: descriptor well-formed; `NS.Perf` exists with `on == false` at load; the stub answers every member the slash layer reaches. Red. | PC-40 |
| **2.2** | Create `core/PerfSetup.lua` — silent `LibStub("LibKa0s-Perf-1.0", true)`, `NS.Perf = lib:New(descriptor)` **only** `if lib`, member-answering stub otherwise. Descriptor: `buckets = {}` (honest — `performance-§3` forbids a bucket no bracket reaches), `svName = "PrettyChatPerfDB"`, `print` / `debug` as call-time forwarders. TOC-list it in `# Core` immediately after `core\CoreSetup.lua`. Green. | PC-40 |
| **2.3** | **Test first**, then implement `suspend`/`resume`: suspend restores every snapshotted `_G[GLOBALNAME]`; resume re-runs `ApplyStrings` from **current** state (not a snapshot taken at suspend). Assert inertness by checking the globals, not by checking a flag. Flag is session-only, never persisted. | PC-40 |
| **2.4** | Print a warning line at the head of a guided run — *"suspend restores Blizzard's chat formatting for the duration of the second arm"* — through `NS.Print`. This is the `LIBKA0S-12` objection converted into a documented property. | PC-40 |
| **2.5** | `PrettyChat.toc:7` → `## SavedVariables: PrettyChatDB, PrettyChatPerfDB`. | PC-41 |
| **2.6** | Add the `perf` triple to `NS.COMMANDS` (`settings/Slash.lua`, between `debug` and `version`), forwarding to the instance's command entry point and printing the returned lines through `NS.Print`. Extend `test_slash.lua` for the new verb and for the degraded path naming the missing library. | PC-42 |
| **2.7** | `.luacheckrc` — `debugprofilestop` → `read_globals`; `PrettyChatPerfDB` → `globals`, with a justifying comment beside `PrettyChatDB`. | PC-45 |
| **2.8** | `tests/perf.lua` — outside the gate, **not** run by `tests/run.lua`. Zero-overhead scenario over the `ApplyStrings` pass with capture off vs. instrumentation absent. Deterministic quantities only (allocations, call counts); **no wall-clock assertion**. Derive its load list from the TOC. | PC-43 |
| **2.9** | **Degraded-path test** (`testing-§8`): load with `libs/LibKa0s/Perf.lua` omitted from `tests/loader.lua`'s explicit LibKa0s list and assert the host's own stub answers — a real scenario, **never** a hand-written namespace stub. | PC-40 |
| **2.10** | `docs/performance.md` — what is bracketed (nothing, and **why**: move the LIBKA0S-12 reasoning here, where it belongs), how to run `/pc perf`, what the harness can and cannot resolve for this addon. `docs/perf-runs/README.md` — naming convention, schema summary, pointer to the library's canonical contract. | PC-44 |
| **2.11** | Regenerate `docs/test-cases.md` (`lua tests/run.lua --list > docs/test-cases.md`) **and** update the README `[tests]` badge in the same commit. | `testing-§5` |

### If **A2** (decline upstream)

| # | Step | IDs |
|---|---|---|
| **2.a** | Open the `performance` carve-out upstream in `WowAddonStandards`, citing this bundle's `03_EVIDENCE.md §PC-40` (the independently confirmed zero-hot-path sweep) and the suspend-visibility harm. | PC-40 … PC-45 |
| **2.b** | Once the standard lands, record the outcome in `docs/deviations.md` and close PC-40…PC-45 as compliant on the next audit. Until it lands, they stay open MUSTs — that is the correct state, not a failure. | — |

**Exit criteria (A1):** green gate; `/pc perf` answers in-game; `PrettyChatPerfDB` written by a
real run; badge and inventory in lockstep. **(A2):** an upstream issue exists and is linked from
`docs/deviations.md`.

**Closes (A1):** PC-40, PC-41, PC-42, PC-43, PC-44, PC-45 — **6 MUST**.

---

## Sprint 3 — Generated data (gated on decision 0.2)

### If **D1** (relocate + re-split)

| # | Step | IDs |
|---|---|---|
| **3.1** | Re-run `split_globalstrings.py` with a chunk target of ~1400 lines (~17 chunks), emitting into `defaults/globalstrings/`. | PC-49 |
| **3.2** | Move the source dump and the splitter to `_dev/globalstrings/` (already ignored at `.pkgmeta:14`); drop the now-redundant `.pkgmeta:21-23` ignore lines. | PC-25 |
| **3.3** | Rewrite the TOC: delete the `# GlobalStrings` section, list the new chunks under `# Defaults` after `defaults\Defaults.lua`, preserving load order relative to `settings\Panel.lua`. | PC-25 |
| **3.4** | Delete `GlobalStrings` from `.luacheckrc:14-21`'s `exclude_files` **only if** the new location is still excluded; otherwise re-point the entry at `defaults/globalstrings`. | PC-25 |
| **3.5** | Run the gate. `tests/loader.lua` derives from the TOC (`Loader.tocFiles`), so the load list follows automatically — `test_defaults.lua` and `test_override.lua` are the real check that nothing was lost. | — |

### If **D2** (widen the exception)

| # | Step | IDs |
|---|---|---|
| **3.a** | In `docs/deviations.md`, extend the generated-data record to name **all** the rules it breaks: `layout-§1` (root folder **and** the 1500-LOC cap on eight shipped chunks), `layout-§2` (PascalCase subfolder), `toc-file-§5` (the seventh TOC section). | PC-25, PC-49 |

**Exit criteria (D1):** green gate; `luacheck .` clean; no file over 1500 lines outside `libs/`;
TOC section list matches `toc-file-§5` exactly.

**Closes (D1):** PC-25, PC-49 — **2 MUST**.

---

## Sprint 4 — Message bus (gated on decision 0.3)

### If **E1**

| # | Step | IDs |
|---|---|---|
| **4.1** | **Test first:** two receivers of `Ka0s_PrettyChat_SettingsChanged` both fire (the mock already keys by target and fans out — `architecture-§4`, anti-pattern #33). Red. | PC-50 |
| **4.2** | Add `NS.NewBusTarget()` to `core/State.lua` or `core/Util.lua` — the one-line AceEvent-embed factory from `architecture-§4`. This **requires vendoring `AceEvent-3.0`**, which also settles PC-52's `library-stack-§1` half. | PC-50, PC-52 |
| **4.3** | Send `Ka0s_PrettyChat_SettingsChanged` from `Schema.Set` (`settings/Schema.lua:287-298`) and the three reset paths (`modules/Override.lua:99-135`); receive it on `settings/Panel.lua`'s own bus target, replacing the four direct `NotifyPanelChange` / `RefreshScalars` call sites. **One sender only.** | PC-50 |
| **4.4** | Document the message in `docs/ARCHITECTURE.md`'s new `## Message Bus` section (Sprint 1.6): name, sender, payload schema, all consumers. | PC-50, PC-53 |

### If **E2**

| # | Step | IDs |
|---|---|---|
| **4.a** | Record the absence in `docs/deviations.md` with the single-feature-module rationale and the note that `architecture-§4`'s clobber hazard cannot arise with one receiver. Keep `docs/ARCHITECTURE.md`'s `## Message Bus` section stating it plainly. | PC-50 |

**Closes (E1):** PC-50 — **1 MUST**, and settles PC-52.

---

## Sprint 5 — Standing / upstream (no local work)

| # | Item | IDs |
|---|---|---|
| **5.1** | Track **LIBKA0S-01** (isolated-environment mode in `testkit/`). When it lands: re-vendor, delete `tests/loader.lua`, close PC-51. **Do not** work around it locally. | PC-51 |
| **5.2** | Track **LIBKA0S-06** (a third `RenderGrid` ratio). When it lands: migrate the per-string editor off the bespoke 40/60 block, close PC-23. Push it upstream as an **additive** field, never a host-side fork (`anti-patterns` #47). | PC-23 |
| **5.3** | Report the British spelling at `tests/_kit/README.md:119` (*"behaviour"*) to the **LibKa0s** repo as a `localization-§5` fix. **Never** patch it here — both vendor diffs are currently empty and that is the property being protected. | — |
| **5.4** | Raise `library-stack-§1` vs `library-stack-§3` upstream: §1's "mandatory libs" table names `AceEvent-3.0`/`AceTimer-3.0` that §3 forbids vendoring unused. Suggest §1 read *"mandatory for an addon that uses them."* | PC-52 |
| **5.5** | Raise the `toc-file-§1` `Category-enUS` enumeration upstream, or narrow `PrettyChat.toc:10` to `Chat`. Low priority. | PC-56 |
| **5.6** | **No action:** PC-27 (TOC branding) and PC-54 (font not LSM-registered) are settled deviations with sound written reasons. Re-confirm PC-54 only if LSM is ever vendored for another purpose. | PC-27, PC-54 |

---

## Projected end state

| Route | MUST open | SHOULD open |
|---|---|---|
| Today | 12 | 6 |
| After Sprint 1 | 9 | 4 |
| After Sprint 1 + 2(A1) | 3 | 4 |
| After Sprint 1 + 2(A1) + 3(D1) | 1 | 4 |
| After Sprint 1 + 2(A1) + 3(D1) + 4(E1) | **0** | **4** (PC-23, PC-27, PC-51, PC-54 — all documented; two upstream-blocked) |

The four remaining SHOULDs are all recorded accepted deviations with written reasons, which is
exactly the state the standard asks for. **A full pass through Sprints 1–4 leaves PrettyChat
with zero open MUSTs.**
</content>
