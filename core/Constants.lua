local addonName, NS = ...

NS.Const = NS.Const or {}
local Const = NS.Const

-- The panel layout constants that used to live here — PANEL_PADDING_X,
-- PANEL_HEADER_TOP, PANEL_HEADER_HEIGHT, PANEL_DEFAULTS_W, BUTTON_PAIR_REL,
-- SECTION_HEADING_H and ROW_VSPACER — are gone, and MUST NOT come back.
-- They are LibKa0s-Options-1.0's `LAYOUT` table now, and options-ui-§8 is
-- explicit about why: every Ka0s panel renders identically because every panel
-- reads ONE set of values, and a host copy is the copy that goes stale. Where
-- settings/Panel.lua needs one for a widget it draws itself, it reads it off the
-- instance (`NS.Helpers.ROW_VSPACER`, `NS.Helpers.SECTION_HEADING_H`).
--
-- The two below stay, because neither is the library's.

-- The spacers around a section heading. These belong to the landing page's own
-- body, which is the host's half of the panel (options-ui-§5), and the library's
-- flow engine applies its own internally.
Const.SECTION_TOP_SPACER    = 10
Const.SECTION_BOTTOM_SPACER = 6

-- Per-string entry — vertical gap that bottoms each string entry and
-- keeps adjacent strings from butting against each other. Specific to the
-- bespoke 40/60 editor in settings/Panel.lua; the library has no equivalent.
Const.STRING_VSPACER = 14

-- Single source for the chat-color escapes used across PrettyChat.lua
-- (slash output, [PC] prefix, Test header/footer) and settings/Panel.lua (panel
-- captions, alias label). `cyan` is the [PC] prefix color — the cyan
-- /reset pair is the addon's brand mark and must not change without a
-- visual review.
Const.Color = {
    gold   = "|cffffd700",
    gray   = "|cffaaaaaa",
    red    = "|cffff5050",
    yellow = "|cffffff00",   -- also the slash-commands-§5 schema-path/key color (ffff00)
    white  = "|cffffffff",   -- also the slash-commands-§5 value color (ffffff)
    cyan   = "|cff00ffff",
    green  = "|cff40ff40",   -- brand green (Test labels + existing UI)
    -- slash-commands-§5 mandated schema-output palette. These exact codes are a MUST —
    -- they read identically across every Ka0s addon, so MUST NOT be substituted. Note the
    -- header green (33ff99) is deliberately distinct from the brand green above (40ff40).
    listHead = "|cff33ff99",  -- `list` "Available settings" header
    azure    = "|cff3399ff",  -- `list` [category] group headers
    reset  = "|r",
}

-- Shared cyan [PC] chat tag. Single source for every module's chat
-- output — NS.Print prepends it. Cyan is the addon's brand mark.
Const.PREFIX = Const.Color.cyan .. "[PC]" .. Const.Color.reset .. " "
NS.PREFIX    = Const.PREFIX

-- Monospace font for the on-screen debug console (debug-logging-§2). The face is
-- JetBrains Mono (OFL) and it now arrives inside the LibKa0s payload this repo already
-- vendors — core/MediaSetup.lua resolves it — rather than from a second copy of the same
-- bytes under this addon's own media/fonts/. It is handed to LibKa0s-DebugLog-1.0 as the
-- console descriptor's `font` (core/DebugLogSetup.lua), which applies it to the log, the
-- line counter and the copy box.
--
-- THE FALLBACK IS A REAL CLIENT FONT, deliberately. `SetFont` accepts a path to a file that
-- is not there, fails to load it, and the text simply does not draw — so a degraded install
-- (no LibKa0s, hence no payload and no face) gets Blizzard's own STANDARD_TEXT_FONT and a
-- readable console in a proportional face, never a dead path.
--
-- LibSharedMedia registration is no longer this file's business either: the library
-- registers every face it ships, from core/MediaSetup.lua's RegisterLSM call. PrettyChat
-- does not vendor LibSharedMedia-3.0, so that call is a no-op in this install — the
-- registration happens the day LSM arrives, and nothing here has to decide.
Const.FONT_MONO_NAME = "JetBrains Mono"
Const.FONT_MONO      = NS.MediaFont and NS.MediaFont(Const.FONT_MONO_NAME) or _G.STANDARD_TEXT_FONT
