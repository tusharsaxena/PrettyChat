local addonName, NS = ...

-- core/LauncherSetup.lua — wires the addon into LibKa0s-Launcher-1.0.
--
-- ONE OBJECT, REGISTERED TWICE (launcher-§1). The library builds a single
-- LibDataBroker-1.1 object of `type = "launcher"` and hands that same object to
-- LibDBIcon-1.0: LibDBIcon draws the minimap button from it, and any broker
-- display the player runs — Titan Panel, ElvUI's data texts, Bazooka — draws its
-- own row from it too. One OnClick, one icon, one label, one identity. What is
-- ours is the half a vendored library cannot know: this addon's folder name, its
-- logo, how its settings panel opens, and which rung its left click sits on.
--
-- ── THE RUNG, AND WHY THERE IS NO `onClick` BELOW ───────────────────────────
--
-- launcher-§2's three rungs are first-match-wins, and the standard's ADDONS.md
-- roster records Ka0s Pretty Chat on rung **(c)**: it has no primary window —
-- `grep -rn CreateFrame core/ modules/ settings/` finds one combat watcher and
-- nothing a player ever sees — and no preview switch either, because it is
-- FRAMELESS (settings/Schema.lua's MASTER_SPEC says so, and there is no Test
-- mode row and no Lock frame row on the composed tab). Its display IS the chat
-- text it rewrites, which cannot be previewed by toggling a frame.
--
-- ── THE CLICK WHILE THE ADDON IS DISABLED, AND WHY NOTHING CHANGES HERE ─────
--
-- slash-commands-§7 refuses the LEFT click of a disabled addon on rungs (a) and
-- (b): those drive a primary window and a preview switch, and both are features.
-- **Rung (c) is carved out, in launcher-§2's own words, and this addon is the
-- rostered rung-(c) addon the clause was written for.** A rung-(c) left click
-- opens the settings panel — which §7 itself lists among the things that SURVIVE
-- the disabled state, because the panel is SETUP and not a feature — and refusing
-- it would decline one button for doing exactly what the other button beside it is
-- required to keep doing. Right-click opens that same panel in either state on
-- every addon in the collection.
--
-- So BOTH buttons open the panel, in both states. The descriptor DOES carry
-- `isEnabled` (and the `disabledLine` the library requires beside it) since
-- Launcher minor 3, but for the TOOLTIP's `Enabled: Yes|No` line and nothing
-- else: the library gates the left click only where `onClick` is present, so on
-- rung (c) the pair gates nothing and the refusal line is never printed. The
-- other half of §7's launcher rule holds for the same reason: a click here writes
-- NO SavedVariables, because all it does is open a panel. tests/test_disabled.lua
-- drives both buttons while the addon is off and asserts exactly that, and
-- tests/test_launcher.lua pins that isEnabled did not start gating.
--
-- ── THE TOOLTIP IS THE LIBRARY'S (launcher-§1, Launcher minor 3) ────────────
--
-- LibKa0s-Launcher draws the same status tooltip in all eleven addons, enabled or
-- disabled: `<label>  v<version>`, `Enabled: Yes|No`, the rung's click hints. This
-- file only answers its questions, and answers only the ones this addon has:
-- `version` (the TOC's `## Version`, through NS.Version()) and `isEnabled`. There
-- is no `isLocked` and no `isTestMode` because a frameless addon has no frame to
-- lock and no preview switch (the rung paragraph above); no `leftClickLabel`
-- because on rung (c) the library draws `Open settings` and ignores the field;
-- and no `onTooltipShow`, because this addon has no line of its own to add.
--
-- So left-click opens the settings panel, and the way that is expressed is by
-- passing NO `onClick` AT ALL. The rung is the ABSENCE, deliberately: the
-- library dispatches both buttons into `openSettings` when `onClick` is nil, and
-- passing `openSettings` a second time under `onClick` would make a rung that
-- was decided look like a rule that was skipped. `/pc test` is the closest thing
-- this addon has to a preview and it is a VERB, not a switch — there is no state
-- for a left click to toggle.
--
-- ── WHY REGISTER HAPPENS IN OnEnable, NOT HERE ──────────────────────────────
--
-- The descriptor is built at file load because that is when the seam has to be
-- published, but `Register` resolves both broker libraries AND the `minimap`
-- table at CALL time, and `db.global.minimap` does not exist until AceDB has run
-- in PrettyChat:OnInitialize. Registering at load would hand the library a
-- descriptor whose `minimap` answers nil, which it reports honestly and then
-- draws no button — the failure this file exists to avoid. core/PrettyChat.lua's
-- OnEnable makes the call, and it is idempotent, so a second caller costs
-- nothing and cannot build a second button over the first.
--
-- `minimap` is therefore a FUNCTION rather than the table. A table captured at
-- file load is a table AceDB later replaces, and the object LibDBIcon holds
-- would then stop being the table settings/Schema.lua's row writes.
--
-- ── WHAT A DEGRADED INSTALL GETS, AND WHY THERE IS NO STUB ──────────────────
--
-- Every other LibKa0s seam in this addon carries a member-answering stub,
-- because something calls into it at load or from a page body and a nil member
-- would raise there. This one does not, and that is the library's own documented
-- shape rather than an omission: nothing in this addon calls back into the
-- launcher except the Register line in OnEnable and the `global.minimap.shown`
-- wiring in settings/Schema.lua, and BOTH already guard on `NS.Launcher`. A stub
-- here would be a second no-op object for two guarded call sites to find, and the
-- checkbox would go on working either way because its `get` reads the STORE, not
-- the button.
--
-- Three absences, three different outcomes, and none of them raises:
--
--   no LibKa0s            NS.Launcher is nil; no broker object, no button. The
--                         Minimap button checkbox still reads and writes
--                         db.global.minimap.hide, so the player's choice is kept
--                         and takes effect the day the payload is whole again.
--   no LibDataBroker-1.1  Register returns false and says so once, by name.
--   no LibDBIcon-1.0      Register returns false; a broker display still shows
--                         the plugin, and there is simply no minimap button.
--
-- TOC slot: after core/PrettyChat.lua (the AceAddon object this file's
-- openSettings hook calls OpenConfig on) and after core/DebugLogSetup.lua (the
-- NS.Debug seam handed in as `debug`). Nothing here resolves at load beyond the
-- LibStub lookup, so the position is conventional rather than load-bearing.

local Launcher = LibStub and LibStub("LibKa0s-Launcher-1.0", true)

-- The addon's face in THREE places — the AddOns list (PrettyChat.toc's
-- `## IconTexture`), the minimap button and a broker display's row — and it MUST
-- be the same file in all three (launcher-§4). 128x128, uncompressed 32-bit TGA,
-- generated from the 2000x2000 .png beside it by layout-§4's recipe.
--
-- Hand-concatenated for the same reason settings/Panel.lua's LOGO_PATH is: a
-- per-addon logo is not a LibKa0s-Media catalog entry and could not be one — the
-- catalog holds the marks the COLLECTION shares, resolved per folder, and this is
-- the one file nothing else ever asks for. `addonName` is the TOC's own first
-- vararg, never a hand-typed folder name that a rename would leave behind.
--
-- The EXTENSION is carried, unlike NS.Icon's catalog answers: `## IconTexture`
-- names this path with `.tga` and launcher-§4 requires the two to be the same
-- file, spelled the same way.
local ICON_PATH = "Interface\\AddOns\\" .. addonName
                  .. "\\media\\logos\\prettychat.logo.128.tga"

if Launcher then
    NS.Launcher = Launcher:New({
        -- The FOLDER name, for BOTH registrations, and it is not cosmetic:
        -- LibDBIcon keys the button's SAVED POSITION by it, so a second spelling
        -- drops the angle the player dragged the button to and labels the broker
        -- plugin with the other name. `addonName` is the one name this addon
        -- cannot change without changing what the client loads.
        name = addonName,

        -- THE BRAND NAME, IN PLAIN TEXT — `Ka0s <Name>` (launcher-§1). This is
        -- the string a broker display prints in its own row, and it prints it
        -- BESIDE THE OTHER TEN, so it is the single field that decides whether
        -- the collection reads as one collection in Titan Panel or as eleven
        -- unrelated addons that happen to be installed together. A display
        -- sorting alphabetically files `Absorb Tracker` under A while the rest
        -- sit under K; the rule exists because across eleven adoptions this came
        -- out three ways with nothing saying what it was.
        --
        -- DELIBERATELY NOT THE TOC'S `## Title`, and this addon is the case that
        -- wording was written for: PrettyChat.toc's Title is
        -- `Ka0s |cffff0000P|cffff9900r|cffffff00e|…`, a ratified `toc-file-§1`
        -- deviation kept as the addon's brand mark. Handed to a display that
        -- draws the string raw it would splatter across a list in which every
        -- other row is plain text; handed to one that strips escapes it would
        -- arrive mangled. So the two fields are NEVER wired to each other, and
        -- this one carries no escape sequence of any kind.
        --
        -- Not the folder name either. `name` above is the folder — an identifier
        -- LibDBIcon keys the saved position by, which a player reads nowhere as
        -- prose. Two fields, two jobs; without this one the library would fall
        -- back to "PrettyChat", which is the folder, not the product.
        label = "Ka0s Pretty Chat",

        icon = ICON_PATH,

        -- A FUNCTION, not the table — see the header. Resolved at Register time,
        -- which is after AceDB has provisioned `global` from
        -- NS.GlobalDefaults (defaults/Profile.lua).
        minimap = function()
            return NS.db and NS.db.global and NS.db.global.minimap
        end,

        -- RIGHT-click always, and LEFT-click too, because no `onClick` is passed
        -- (rung (c)). PrettyChat:OpenConfig is the one combat-gated open path
        -- this addon has — options-ui-§2 forbids a second one — so the launcher
        -- takes it rather than reaching for the library's OpenOptionsPanel
        -- directly. NS IS the AceAddon object (architecture-§2), so this is the
        -- same method `/pc config` calls.
        openSettings = function() NS:OpenConfig() end,

        print = function(line) NS.Print(line) end,
        debug = function(tag, message) NS.Debug(tag, "%s", message) end,

        -- The tooltip's title reads `Ka0s Pretty Chat  v<version>`. The TOC's own
        -- `## Version`, through the same NS.Version() `/pc version` prints, so a
        -- bump that edits the TOC moves both. A function: asked on every show.
        version = function() return NS.Version() end,

        -- The tooltip's `Enabled: Yes|No`, asked on every show and never cached.
        -- The master switch the General page's Enable row reads (settings/Schema.lua)
        -- and the Slash dispatcher gates on (settings/Slash.lua). It gates NOTHING
        -- here: there is no `onClick`, and the library gates only a left click that
        -- has one (see the header).
        isEnabled = function() return NS:IsAddonEnabled() end,

        -- Required by the library beside `isEnabled`. The dispatcher's own line,
        -- resolved at CALL time because settings/Slash.lua loads after this file.
        -- On rung (c) nothing prints it; it is here so the pair is whole.
        disabledLine = function()
            return NS.SlashCommands and NS.SlashCommands:DisabledLine() or nil
        end,

        -- Deliberately NOT passed:
        --
        --   onClick        the rung, and it is an absence — see the header.
        --   isLocked       no lock: the addon is frameless (no Lock frame row).
        --   isTestMode     no test mode: `/pc test` is a verb, not a switch.
        --   leftClickLabel rung (c): the library draws `Open settings` itself and
        --                  ignores the field, so passing one would be dead config.
        --   onTooltipShow  this addon has no line of its own to append; the title,
        --                  status and click hints are the library's (drawing any
        --                  of them here is anti-pattern #89).
        --   L              NS.L answers EVERY key with the key itself, so a
        --                  descriptor holding it renders raw SCREAMING_SNAKE at
        --                  the player (anti-pattern #2). This addon translates
        --                  none of the library's four reports or its fourteen
        --                  tooltip strings (it ships enUS only), so it passes
        --                  none — the same call settings/Slash.lua makes. A
        --                  translator passes a PLAIN table of TOOLTIP_* keys.
    })
end
