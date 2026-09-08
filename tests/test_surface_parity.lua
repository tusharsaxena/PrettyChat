-- tests/test_surface_parity.lua — the degradation stubs against the live surfaces.
--
-- One case per adopted seam (testing-§8). Each asks the same question: if LibKa0s
-- is not installed, does the arm this addon falls back to still answer everything
-- the live arm answered? Three of this collection's surviving High findings are one
-- omitted stub member — a stub returns without assigning a formatter, and the verb
-- raises on exactly the path the stub exists to survive.
--
-- Split out of tests/test_libka0s.lua by M4-09, which asks all nine addons for a
-- file of this name so the gate is findable by the same path in every repo. The
-- cases are unchanged in what they assert; what moved is the calling form of three
-- of the four, below.
--
-- The degraded arm comes from feeding the loader a PARTIAL FILE LIST — skipping
-- libs/LibKa0s/Core.lua, which takes the whole library out, since every other
-- module returns before LibStub:NewLibrary when Core is absent. Never by
-- hand-stubbing the member under test: that would assert the test's own typing.
--
-- `assertSurfaceParity` reports every divergence in one message, counting a key
-- that is a function live and something else degraded — the shape
-- `X = lib and lib.X` leaves behind when the library is absent. A check that only
-- asks "is the key set?" waves that one through.
--
-- `ignore` carries the live-only members AS DATA, with the reason each one is
-- live-only. Without it an intentional omission and a bug read the same, and the
-- usual resolution for that is to delete the case.

local ctx = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

-- BOTH arms are freshly loaded, differing only by the file list, so the two
-- surfaces are read at the same point in their lives. A shared instance is not
-- usable as the live arm: LibKa0s-DebugLog-1.0 attaches `_frameForTest` and
-- `_toggleClickForTest` to its instance when the console frame is first built, so
-- whether that surface carries them depends on which case ran before this one.
local parityLive = ctx.loadAddon()
local parityBare = ctx.loadAddon({ skip = { "libs/LibKa0s/Core.lua" } })

-- ── where the by-name form looks the live half up ──────────────────────────
--
-- Kit 15 (vendored by M4-01) added `assertSurfaceParity(stub, majorName, ignore)`,
-- which NAMES the live surface instead of the case rebuilding it, and compares only
-- `Kit.publicMembers` — every `__`-prefixed key dropped, because those are the
-- library talking to itself across a file boundary and no stub is obliged to mirror
-- them. That filter is the kit's rule now rather than this file's typing, which is
-- the point of the move: the `__` exemptions used to have to be added here by hand
-- on every re-vendor that published a new internal.
--
-- The kit cannot resolve the name on its own, so the harness supplies the source, and
-- in THIS repo nothing supplies it implicitly. `Kit.expose` auto-wires a LibStub off
-- the exposed table's mock, which is right for a repo whose stubs mirror LIBRARY
-- TABLES; PrettyChat's `tests/wow_mock.lua` returns a callable BUILDER carrying only
-- `.metadata`, so `t.mock.LibStub` is nil and expose registers nothing. Watched, with
-- the three lines below removed: all three by-name cases fail with the kit's own "no
-- surface source is registered … this gate cannot run". That is the kit failing CLOSED
-- rather than reporting a stub it never compared, and it is why the registration is a
-- visible line here instead of an inherited default nobody would notice going missing.
--
-- What the three names answer is an INSTANCE — what `lib:New(descriptor)` returned —
-- not the library table a LibStub lookup would give. `NS.Helpers` IS the Options
-- instance, decorated in place (settings/OptionsSetup.lua), and it is the surface the
-- page files call; the library table behind that major publishes four public members
-- (LAYOUT, New, PatchAlwaysShowScrollbar, STRINGS) against the instance's fifty-one,
-- so a lookup-based source would compare the stub against almost nothing and say it
-- was fine.
--
-- Registered HERE rather than in tests/run.lua — which is where AbsorbTracker's
-- equivalent line sits — because the live instances belong to `parityLive`, three
-- lines up, and this runner holds no addon instance of its own: it hands each suite a
-- `loadAddon` factory instead. Registering in the runner would mean loading a fourth
-- full addon instance there purely to name it, and naming instances loaded at a
-- different point in the run than the arms compared against them, which is the one
-- thing the two-arms-together comment above exists to prevent.
ctx.setSurfaceSource{
    ["LibKa0s-Options-1.0"]  = parityLive.NS.Helpers,
    ["LibKa0s-DebugLog-1.0"] = parityLive.NS.DebugLog,
    ["LibKa0s-Slash-1.0"]    = parityLive.NS.SlashCommands,
}

-- LibKa0s-Core-1.0 is the one seam this addon does not keep as an instance, and so
-- the one case that KEEPS the four-argument form: the printer's members are
-- re-published under the addon's own keys (anti-pattern #36 reclaim), so there is no
-- major whose surface this is. Both halves are two blocks of core/CoreSetup.lua and
-- what they have in common is a set of names hung on NS, derived from the file by
-- grep — there is no name for the by-name form to look up.
-- Members from: grep -nE "^\s*(function )?(NS|Util)\.[A-Za-z]+" core/CoreSetup.lua
local function coreSurface(instance)
    return {
        Print        = instance.NS.Print,
        Format       = instance.NS.Format,
        IsConcatSafe = instance.NS.Util.IsConcatSafe,
        SafeToString = instance.NS.Util.SafeToString,
        -- PC-A-05: published PAST the degraded branch's `return`, so the live arm
        -- had it and the stub arm did not. Nothing calls it yet, which is the
        -- whole hazard -- the first caller would work everywhere the library is
        -- installed and answer nil in the one install this branch exists for.
        MakeCloseButton = instance.NS.MakeCloseButton,
    }
end

test("the Core stub carries the whole live surface", function()
    local live = coreSurface(parityLive)
    -- Non-vacuity: a projection that read nothing would pass parity trivially.
    for _, key in ipairs({ "Print", "Format", "IsConcatSafe", "SafeToString", "MakeCloseButton" }) do
        t.eq(type(live[key]), "function", "the live Core seam publishes " .. key)
    end
    ctx.assertSurfaceParity(live, coreSurface(parityBare), "Core stub")
end)

test("the DebugLog stub carries the whole live surface", function()
    ctx.assertSurfaceParity(parityBare.NS.DebugLog, "LibKa0s-DebugLog-1.0", {
        -- debug-logging-§3/§7: the stub MUST NOT re-implement the line format, so
        -- the two formatters are live-only by rule, not by oversight.
        FormatPlain   = true,
        FormatColored = true,
        -- The library's own string resolver. Nothing in this addon calls it —
        -- `grep -rn "DebugLog[:.]Text" core settings modules` is empty — and a stub
        -- copy would be a second place the library's English could drift.
        Text          = true,
    })
end)

test("the Options stub carries the whole live surface", function()
    ctx.assertSurfaceParity(parityBare.NS.Helpers, "LibKa0s-Options-1.0", {
        -- options-ui-§8: the layout constants MUST NOT be copied into the host, so
        -- the stub omits them deliberately. See settings/OptionsSetup.lua's comment
        -- on the guard that keeps a nil from reaching anything.
        PADDING_X         = true,
        ROW_VSPACER       = true,
        SECTION_HEADING_H = true,
        BUTTON_PAIR_REL   = true,
        -- Minor 13/14 published three more of them (the chrome gap, one tab row's
        -- height, the banner floor) for a host that lays out its own strip. This
        -- addon lays out none: settings/Panel.lua hands H.TabStrip a tab list and
        -- the library places the buttons, so nothing here measures a band and a
        -- stub copy of the numbers would be exactly the stale copy options-ui-§8
        -- forbids. The FUNCTIONS of both minors are in the stub, by name.
        CHROME_GAP        = true,
        TAB_H             = true,
        BANNER_H          = true,
        -- Live-only because nothing in this addon reads them: settings/Panel.lua
        -- resolves AceGUI itself, builds its own landing page and its own rows, and
        -- never asks the library to patch a scrollbar or restore one page's
        -- defaults. `grep -rn "Helpers.\(AceGUI\|BuildLandingPage\|RestoreDefaults\|PatchAlwaysShowScrollbar\)" core settings modules` is empty.
        -- TextRow LEFT this list when the Categories page took it for its footnote.
        AceGUI                   = true,
        RestoreDefaults          = true,
        PatchAlwaysShowScrollbar = true,
        -- OptionsCompose 1. Four of the five composers are live-only because this
        -- addon has none of the surfaces they compose: `grep -rn 'type = "color"'
        -- settings defaults` is empty, and so is `grep -rn 'LSM30_' settings` —
        -- the schema is bool and string only, with no swatch, no font picker, no
        -- border and no status bar anywhere in it. MasterControls is the one this
        -- addon does call, and it is NOT here: it is in the stub, doing real work,
        -- because settings/Schema.lua composes the General page through it at
        -- load. The five published CONSTANTS go with the four composers, for the
        -- reason the layout constants above do — a stub copy of the library's
        -- English or of its visibility value table is the copy that goes stale.
        ColorPair                = true,
        FontGroup                = true,
        BorderGroup              = true,
        BarGroup                 = true,
        FONT_FLAGS               = true,
        FONT_FLAGS_SORT          = true,
        VISIBILITY_VALUES        = true,
        VISIBILITY_SORT          = true,
        CLASS_COLOR_NOTE         = true,
        -- Read by settings/Panel.lua, but only inside the General page's builder
        -- and only AFTER the EnsureScroll guard the degraded page returns at, so
        -- it is never reached here. Spelling the literal into the stub would put
        -- the tab's name — which is also the afterGroup hook's key — in two
        -- places, and a rename would then detach the hook silently.
        MASTER_GROUP             = true,
        -- `__print` USED to need an entry here, added at v1.27.0 with the library's
        -- own comment at O.__print saying a degradation stub does not mirror it
        -- because Kit.assertSurfaceParity skips the `__` prefix. That was true of
        -- the by-name form and not of the four-argument form this case used to use,
        -- which walked every key of the live table. It uses the by-name form now, so
        -- the entry is gone and the next internal the library publishes needs none.
    })
end)

test("the Slash stub carries the whole live surface", function()
    ctx.assertSurfaceParity(parityBare.NS.SlashCommands, "LibKa0s-Slash-1.0", {
        -- Live-only because the degraded PrintHelp writes its own header inline and
        -- nothing else asks for one: settings/Panel.lua:368 is the addon's only
        -- caller of the help-index surface and it takes LandingRows, on a page that
        -- never builds without the library. The day a degraded caller appears, this
        -- entry is what has to be deleted first.
        HelpHeader = true,
    })
end)
