# 02 — Candidates: what v1.31.0 brings PrettyChat

Sources, in the spec's order:

```sh
git -C ../LibKa0s log --oneline v1.30.0..v1.31.0
# 30db4ed The v1.31.0 release record
# 2b312db v1.31.0: release pointers, standards v2.44.0, the case list
# f355fdc Kit 17: the Ace surfaces six consumer harnesses migrate onto
# 3162e53 Options 15.15.4.3: a record-backed bind arm for the composers (PanelMaster#48)
# 09099b1 docs(releasing): v1.30.0 is merged in all ten consumers
# 853c62e Merge branch 'fix/kit-27-30'
# 5193ebe Post-tag v1.30.0: consumers table sweep; AuraMaster is the tenth consumer
git -C ../LibKa0s show v1.31.0:CHANGELOG.md                                  # the v1.31.0 block
git -C ../LibKa0s show v1.31.0:docs/api/Options/version-15.15.4.3-docs.md    # C4 / W15
git -C ../LibKa0s show v1.31.0:docs/api/testkit/version-17-docs.md
```

## Class A: reached the addon on the re-vendor alone

| Item | Evidence | Why no host change is needed here |
|---|---|---|
| `OptionsWidgets.lua` minor 15: a row with a nil `path` reads and writes through its own `get` / `set` | CHANGELOG v1.31.0, "`OptionsWidgets.lua` minor 15" | The gate is `path == nil`. Every row PrettyChat renders carries a path (`settings/Schema.lua` `addRow` keys `byPath[row.path]`), so the flow engine reads and writes them through the descriptor exactly as before. 333/333 unchanged. |
| `OptionsCompose.lua` minor 4: `spec.bind`, the record-backed arm | CHANGELOG v1.31.0, "`OptionsCompose.lua` minor 4"; `version-15.15.4.3-docs.md:732`, `:840` | PrettyChat's only composer call is `H.MasterControls(MASTER_SPEC)` (`settings/Schema.lua:409`), path-keyed, with no `bind`. The library pins path-keyed callers byte-for-byte against `tests/fixture_compose_golden.lua`. The addon has no registry records (ARCHITECTURE.md → Settings Schema), so nothing here would ever bind. |
| Kit 17's AceEvent message half, `M.__fireEvent`, `M.__badEvents`, AceTimer, `M.__fireTimers` count, AceGUI `WidgetVersions` / layouts | CHANGELOG v1.31.0, "Kit revision 17"; `version-17-docs.md` "What changed at this version" table | PrettyChat embeds only `AceConsole-3.0` (`core/PrettyChat.lua:14`) and has no message bus (ARCHITECTURE.md → Message Bus). Its combat watcher is a plain frame whose `_events` recording is `tests/wow_mock.lua`'s own. None of these surfaces has a local copy to retire. |

## Class B: host change required

### B1. Forward `NewAddon`'s name and mixin list to the kit (kit revision 17)

- **What:** the kit's `NewAddon([object,] name, lib, ...)` now takes a faithful path when it gets a
  name. It names the object, registers it for `GetAddon`, stamps the fourteen AceAddon mixins and
  embeds the listed libraries through `LibStub`. AceConsole's embed stamps a real
  `RegisterChatCommand` that records into `AceConsole.commands` and runs through
  `AceConsole:__slash`. `tests/wow_mock.lua` override 9 replaced `AceAddon-3.0` wholesale and called
  the kit's `NewAddon` with the object alone, which keeps the kit on its revision-16 no-name path.
- **Evidence:** CHANGELOG v1.31.0, "Kit revision 17" (AceAddon and AceConsole bullets; "Two
  divergences are deliberate", which names PrettyChat's harness); `version-17-docs.md:247-252`
  ("It retires when those two wrappers forward the name and the list") and `:298-299`.
- **Files touched:** `tests/wow_mock.lua` (override 9 and its header entry), `tests/test_lifecycle.lua`
  (the `/pc` registration case), `docs/testing.md` (the harness bullet).
- **Retires:** the local `GetAddon`, the `object.name` stamp, and the `slashCommands` /
  `RegisterChatCommand` recorder.
- **Stays, with the reason:** the `Print` override. The kit's print mixin writes to the harness
  process's `DEFAULT_CHAT_FRAME` global (`tests/_kit/mock_base.lua:398-410`), which is never set.
  Without the override a failed reclaim would print nothing. `test_libka0s.lua`'s "the printer is
  reclaimed" case reads `msgs[#msgs]`, so it would then read an earlier `[PC]` line and pass. The
  override is what keeps that guard able to go red.
- **Blast radius:** test harness only, with no production code touched. The addon object now also
  carries AceAddon's fourteen mixins and `enabledState`, as it does in the client. No PrettyChat
  file uses any of those names (`grep` over `core/ modules/ settings/ defaults/ locales/` finds only
  `NS.name`, set to the same value).
- **Recommendation: adopt.** It is the example the owner's brief names (the `RegisterChatCommand`
  recording), and the suite stays green.

### B2. Drive the lifecycle through `AceAddon.frame` instead of `callIfPresent`

- **What:** the kit now runs `OnInitialize` / `OnEnable` from `ADDON_LOADED` / `PLAYER_LOGIN` on
  `AceAddon.frame`. `tests/loader.lua` calls `OnInitialize`, seeds the Blizzard originals, then
  calls `OnEnable` directly through its own `callIfPresent`.
- **Evidence:** `version-17-docs.md`, "AceAddon: the lifecycle, driven the way the client drives it".
- **Files touched:** `tests/loader.lua`.
- **Blast radius:** replaces how every instance boots, including the degraded loads that skip
  `libs/LibKa0s/*.lua`. The kit also changes error semantics: an error in `OnInitialize` is now
  raised only after the cascade finishes.
- **Recommendation: not now.** The brief asks for surfaces that retire a local layer the suite
  stays green without. `callIfPresent` is two lines, `loader.lua` is slated for deletion when
  `LIBKA0S-01` lands upstream, and the change would touch every instance's boot for no assertion
  the suite cannot already make.

## Class C: whole-module adoption

None raised. The unconsumed majors (`Item`, `Pool`, `Widgets`, `Perf`) did not move in v1.31.0.
`Perf` stays declined under the `performance-§12` row, and nothing in this release changes that
row's premise.
