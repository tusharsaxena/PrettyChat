# Profiles

PrettyChat stores **every setting per profile**, and shows AceDB's own profile management as a
settings page. That makes profiles part of what a player sees rather than an AceDB detail, which is
why they have a page here (`documentation-§3`, Tier 2).

The stored shape inside a profile is [schema.md](schema.md); the pages around this one are
[settings-panel.md](settings-panel.md).

## Where profiles sit

`core/PrettyChat.lua` opens the store with `AceDB:New("PrettyChatDB", defaults, true)`. The `true`
names a shared **Default** profile, so every character starts on the same setup rather than an empty
one. `defaults/Profile.lua` is the **only** place a default is declared (`savedvariables-§2`).

Everything a player can set lives in `db.profile`, so a profile carries all of it:

| In the profile | What it is |
|---|---|
| `enabled` | The master **Enable PrettyChat** switch (`General.enabled`) |
| `visibility` | **General visibility** (`General.visibility`): always, only in combat, only out of combat, never |
| `categories[<Cat>].enabled` | Each message category's Enable |
| `categories[<Cat>].disabledStrings[<NAME>]` | Each format string's Enable (stored inverted) |
| `categories[<Cat>].strings[<NAME>]` | Each format-string override |

A profile stores only what differs from the defaults (auto-clear, [schema.md](schema.md)), so a new
profile is an empty table until a player changes something in it.

Three things are deliberately **not** in a profile, and none of them moves when one does:

- **The minimap button**: `global.minimap.shown`, stored as LibDBIcon's `db.global.minimap.hide`
  with the button's dragged position beside it. It is a per-installation display preference
  (`launcher-§3`), so a profile switch, copy or reset never shows or hides the button.
- **`global.schemaVersion`**, the account-wide migration marker. `Database.RunMigrations` walks it
  to the current version, and a profile-scoped step runs on every stored profile, so a profile the
  player switches to later is already current.
- **The debug console's visibility and the session logging flag.** Both are session state.

## The Profiles page

`settings/Profiles.lua` registers a canvas sub-page, last in the rail, whose body hosts an AceGUI
`SimpleGroup`. `AceConfigDialog` draws **AceDBOptions'** own options table into it: create, switch,
copy, reset and delete, plus the per-character, per-class, per-realm, per-faction and default scope
choices.

Five decisions in that file are deliberate:

- **It is the one place AceConfig is used** (`options-ui-§3`, `library-stack-§2`). Every other page
  is drawn from `NS.Schema`. The options table here is Ace's, and re-expressing it as schema rows
  would mean keeping a copy of AceDB's profile model that goes stale the first time AceDB adds a
  scope.
- **No Defaults button.** The panel is created with `defaultsButton = false`. "Restore defaults"
  here would mean deleting the player's profiles, and the page already carries its own destructive
  controls. The global reset's veto names the page a second time (below).
- **Drawn into our canvas, not its own window.** `AceConfigDialog:Open` takes any AceGUI container
  as its target, so the widgets land under the addon's header and breadcrumb instead of in a
  floating dialog over the Settings panel. The container is built on first show and shown
  explicitly on every draw, because a pooled `SimpleGroup` comes back hidden.
- **Redrawn on a profile event, and on nothing else.** The draw is the page's `H.SetRenderer` body,
  so the library's combat cover reaches the Blizzard AddOns sidebar path too. SetRenderer also puts
  the page on the library's structural refresh; a renderer that re-opened on each of those would
  tear AceConfigDialog's tree down under an open dropdown (`options-ui-§11`). So the renderer draws
  once per profile event, counted: one frame later if the page is on screen (`C_Timer.After(0)`),
  on its next show if not (`H.RefreshPanel`). Never inside the event, because a change made with
  the page's *own* control fires it from inside AceConfigDialog's `ActivateControl`, which reads
  `user.rootframe` off that control's userdata after the callback returns. A re-open there
  releases the control, `AceGUI:Release` wipes the table, and the read raises (`attempt to index
  field 'rootframe'`) whenever the widget pool hands the re-open a different widget. Such a change
  is drawn twice, once by AceConfigDialog's own re-open after every control it activates and once
  by the deferred pass; the second is redundant and harmless. Several events in one frame queue
  one pass.
- **No tab strip.** It carries no schema rows, so there is nothing for a strip to partition. It is
  one of the two pages `options-ui-§13` exempts, the landing page being the other.

The page needs four libraries, each looked up silently: `AceDBOptions-3.0`, `AceConfig-3.0`,
`AceConfigDialog-3.0` and `AceGUI-3.0`. With any of them missing the builder answers `nil`, the page
is absent, and nothing else in the panel is affected (`library-stack-§4`).

## Reacting to a profile change

A profile act is not a settings change: every stored value can differ afterwards, and every surface
has to follow. `OnInitialize` registers **one** reaction for all three AceDB callbacks
(`OnProfileChanged`, `OnProfileCopied`, `OnProfileReset`), the file-local `reloadProfile` in
`core/PrettyChat.lua`:

1. **Migrations**, `Database.RunMigrations`. The version walk is a no-op here (the stamp is already
   at target); the work is the orphan repair, `Database.PruneOrphans`, on the incoming profile
   (`savedvariables-§1`).
2. **The latch.** `enabled` is a profile value, so a switch can turn the addon on or off with no
   verb and no checkbox touched. The `disabled` hold is re-taken from the incoming profile and the
   latch re-evaluated (`slash-commands-§7`). A `perf` hold, if one were held, would survive.
3. **The re-apply**, `PrettyChat.Reapply`: the combat watcher re-armed for the incoming visibility
   mode, every format string re-applied or restored, and every schema-drawn widget refreshed
   (`Schema.NotifyPanelChange`).
4. **The Profiles page**, `NS.Config.RefreshProfilesPage`: redrawn a frame later if it is on
   screen, on its next show if not.
5. **One debug line**, worded by the event (`debug-logging-§10`):
   - a switch: `[Profile] switched → applied N restored M`;
   - a copy: `[Set] copied profile 'A' → 'B'`;
   - a reset: `[Set] reset profile '<name>' to defaults (N rows)`, the count present only when
     `PrettyChat:ResetAll` started it.

   A copy or reset that raises partway still writes its line, ending ` (stopped by an error)`, and
   the error goes on up.

## The global reset

**Reset all settings**, the General page's **Defaults** button and `/pc resetall` are one act,
`PrettyChat:ResetAll`, and it is a **profile reset**: `db:ResetProfile()` on the active profile
(`options-ui-§12`). It is the same thing **Profiles → Reset Profile** does. It never touches another
profile or the profile list, and the player stays on the profile they were on. Its confirmation is
the collection's one wording: *"Reset this profile to the addon's defaults? Everything you have
configured or added in it is discarded — your other profiles are not affected."*

The library's `RestoreAllDefaults` is not on that path, but the Options descriptor tells it what the
reset is. `resetProfile` is `PrettyChat:ResetAll` itself, so a library reset reached from anywhere
sweeps the session-only rows and then runs the same profile reset. `profilesPage = true` says this
page exists, which picks the **Reset all settings** tooltip that names the equivalence (`options-ui-§12`):
*"Reset the current profile to its defaults — the same thing Profiles -> Reset Profile does. Your
other profiles are not affected."* The descriptor also carries the veto,
`skipRestoreAll = Schema.VetoedFromResetAll` (`settings/Schema.lua`, named once): the Profiles page and
every row whose value lives in the profile, so a row walk never writes profile rows one by one and
never reaches the Profiles page (`options-ui-§3`).

## Slash commands

`/pc profile` lists the profiles, sorted without regard to case, with the current one marked
`(current)`. `/pc profile <name>` switches to an **existing** profile: the name is case-sensitive,
may contain spaces, and may be wrapped in one pair of quotes (`/pc profile "My Main"`). The verb is
LibKa0s-Slash's `CliProfile` (Slash minor 17) over `PrettyChat.db`, which the descriptor's
`profiles` field hands it at call time.

- **A switch is `db:SetProfile`**, so it is the same act as picking the profile on the page: the
  reaction above runs once, logs its one `[Profile] switched` line, and redraws the page. The
  library itself logs nothing.
- **An unknown name is refused, and nothing is created.** Chat answers `No profile named '<name>'.`,
  adds `Did you mean '<name>'?` when exactly one profile matches without regard to case, then
  prints the list. Creating a profile stays the page's job, so a typo never leaves a stray profile
  behind.
- **In combat the switch is refused** (`Can't switch profiles in combat.`); the list still answers.
- **It answers while the addon is disabled.** `profile` is a host verb, not one of the standard's
  reserved thirteen, so `settings/Slash.lua` passes a `liveVerbs` built from `lib.LIVE_VERBS` plus
  `profile`. A profile holds its own `enabled`, so switching to one where the addon is on brings it
  back up through the latch (step 2 above).
- **With LibKa0s absent** the verb answers the one missing-library line and switches nothing.

`/pc resetall` is the profile reset above. Every verb that reads or writes a setting (`get`, `set`,
`list`, `reset`) acts on the active profile.

## Tests

`tests/test_profiles.lua` pins the page (last in the rail, AceDBOptions' table over the live db, no
Defaults action, drawn on first show into a shown container), the redraw (a switch, copy or reset
redraws the page, a plain structural refresh does not, a hidden page redraws on its next show, and a
change from the page's own control opens nothing under its callback and one pass the frame after), the
latch following the incoming profile's `enabled`, the global reset's blast radius and its veto, and
the page opting out when AceDBOptions is absent, and the `/pc profile` verb: the list, a switch
that runs the profile handler once, an unknown name refused with nothing created, quotes stripped,
the combat refusal, and the verb answering while the addon is disabled. `tests/test_debuglog.lua`
pins the three debug lines and `tests/test_database.lua` the load pass on a switch.
`tests/test_libka0s.lua` pins the library-absent answer.
