# Candidates (PrettyChat, LibKa0s v1.66.0 -> v1.67.0)

Listed, **not interviewed**: the 2026-10-02 census adoption bundle (Ka0sAddonsCommonTasks
`docs/2026-10-02-LIBKA0S_CENSUS_ADOPTION/`, 01_DESIGN.md D1-D3) already decided every adoption for
this cycle, so each new surface below names the item that takes it. Nothing was declined or filed.

Sources: `git -C ../LibKa0s show v1.67.0:CHANGELOG.md` (the v1.67.0 block),
`docs/api/Core/version-10-docs.md` and `docs/api/Options/version-28.2.34.2.3.8.1.7.4.2-docs.md`.

## A. Delivered on the re-vendor alone (not offered)

- **Options 28**: the docblock now names `OptionsIdList.lua` as the reader of `addonName` and says the
  field is the folder name. No behaviour.
- **Kit 35**: unchanged.

## B. Host change required (candidates)

1. **Options descriptor `addonName`** (OptionsIdList 3, LibKa0s#42;
   `docs/api/Options/version-28.2.34.2.3.8.1.7.4.2-docs.md:76`). Pass `addonName = addonName` on the
   descriptor at `settings/OptionsSetup.lua:253`, with `local addonName, NS = ...` replacing
   `local _, NS = ...` at `settings/OptionsSetup.lua:1`. Latent here: PrettyChat builds no
   `O.IdList`, so no help mark is drawn today; it protects the first one added later. **Taken by
   CA-PC-NM** (01_DESIGN.md D2).
2. **`MakeResizable` `canResize` / `onResizeStop` / `gripParent`** (Core 10, LibKa0s#41;
   `docs/api/Core/version-10-docs.md:52`-`:54`). PrettyChat owns no resizable window: the debug
   console and copy window are the library's. **Taken by: none** (01_DESIGN.md D3 lists only
   BankLedger, LootHistory and MultiMeters).

## C. Whole-module adoption

None new. Item, Pool, Widgets, Compat, Bus and Perf keep their recorded status
(`docs/ARCHITECTURE.md`, External dependencies; `docs/revendor/2026-09-23-v1.55.0/`).
