local addonName, NS = ...

-- core/MediaSetup.lua — the LibKa0s-Media-1.0 seam: where this addon's art and
-- its monospace face come from.
--
-- ── The face used to be ours, and that was the problem ──────────────────────
--
-- PrettyChat shipped its own copy of JetBrains Mono under media/fonts/, beside
-- its own copy of the OFL text, for one consumer: the debug console. Every other
-- Ka0s addon shipped the same bytes under the same name in its own folder, which
-- is one license to track per copy, one provenance story per copy, and a
-- collection whose addons stop looking like one author's work the first time one
-- copy is regenerated and the others are not. The face now ships inside LibKa0s
-- (LibKa0s-Media-1.0) and arrives with the payload this repo already vendors, so
-- there is exactly one set of bytes and this file is the address book.
--
-- ── Why the library has to be told our name ─────────────────────────────────
--
-- A texture or font path is absolute from `Interface\AddOns\`, and LibKa0s is
-- VENDORED: every consumer has its own copy at its own path, and a copy cannot
-- work out which addon folder it was copied into. So the library asks, and this
-- file is where the answer lives — `addonName`, the first vararg every TOC-loaded
-- file gets. Never a frame-name prefix, never the `## Title`, never a hand-typed
-- string that a folder rename would leave behind.
--
-- ── Why this loads before core/Constants.lua ────────────────────────────────
--
-- `Const.FONT_MONO` is resolved from `NS.MediaFont` AT LOAD, so the seam has to
-- be published first. That makes this one of the few files in core/ whose TOC
-- position is load-bearing rather than conventional, and the TOC line says so.
--
-- ── What a degraded install gets ────────────────────────────────────────────
--
-- No LibKa0s means no art and no face: they are inside the payload that is
-- missing. `NS.Icon` answers nil, and `NS.MediaFont` answers nil, which
-- core/Constants.lua turns into the client's own STANDARD_TEXT_FONT. Neither is
-- an error — the console still opens and still reads, in a proportional face.
-- What must never happen instead is a path built by concatenation to route
-- around a nil: a path to a file that is not there draws nothing and raises
-- nothing, which is the one failure no suite catches.

local Media = LibStub and LibStub("LibKa0s-Media-1.0", true)

--- The texture path for one shipped icon, or nil.
---
--- EXTENSIONLESS by the library's convention: the answer ends `...\media\icons\close`
--- and the client appends `.tga` itself. A path carrying the extension is one of the
--- spellings that draws nothing.
---
--- NIL IS A REAL ANSWER, twice over: the library may be absent, and the name may not
--- be one the library ships. Both mean the same thing to a caller — draw something
--- else — and both are better than a plausible path to a texture that does not load.
---
--- PrettyChat builds no frames of its own today, so nothing in this addon calls
--- this yet; the marks a player sees are drawn by LibKa0s' own console windows,
--- which are told the folder name through core/DebugLogSetup.lua's descriptor.
--- The seam is published anyway so the first window this addon does build asks the
--- catalog rather than typing a path.
---
--- @param name string  an entry of the library's `ICONS` catalog, e.g. "close"
--- @return string|nil
function NS.Icon(name)
    if not Media then return nil end
    return Media.Icon(addonName, name)
end

--- The path of one shipped font face, or nil when the library is absent.
---
--- @param name string  a key of the library's `FONTS`, e.g. "JetBrains Mono"
--- @return string|nil
function NS.MediaFont(name)
    if not Media then return nil end
    return Media.Font(addonName, name)
end

-- REGISTERED AT FILE LOAD, not at PLAYER_LOGIN. The library's own note explains
-- why: LibSharedMedia is vendored under libs/ and has therefore already run by the
-- time a TOC reaches core/, while a shipped default naming a face is read at load
-- too — deferring opens a window in which a default names a face LSM has never
-- heard of.
--
-- PrettyChat does not vendor LibSharedMedia-3.0, so this call is a documented
-- no-op here: `lib.RegisterLSM` opens by resolving LSM optionally and returns 0, 0
-- when it is absent. It is still written, because it costs nothing, because it
-- starts working the day LSM arrives in this install, and because the alternative
-- is every consumer deciding separately whether registration is worth it — which
-- is how six addons ended up with six answers about one font.
if Media then Media.RegisterLSM(addonName) end
