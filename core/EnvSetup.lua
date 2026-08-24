local addonName, NS = ...

-- core/EnvSetup.lua — the LibKa0s-Env-1.0 seam: where this addon's own identity,
-- read off its packaged TOC, comes from.
--
-- ── What this replaced ──────────────────────────────────────────────────────
--
-- `core/Compat.lua` and its one shim, `Compat.GetAddOnMetadata`. The same reader
-- had been written ELEVEN times across nine Ka0s addons before the library had
-- it — six copies in a core/Compat.lua, in four different spellings, and five
-- more inlined straight at the call site where no audit of the shim files would
-- ever have found them. Not one of the eleven behaved differently from any
-- other, and that sameness is the whole case: it makes the reader the library's
-- business rather than this addon's.
--
-- The shim was the WHOLE of core/Compat.lua here, so that file went with it
-- rather than staying behind as an empty shim seam for the next one to land in
-- without anyone asking whether it should. If PrettyChat ever grows a genuinely
-- addon-specific client-version shim, `core/Compat.lua` comes back for it; a
-- library-owned reader does not qualify.
--
-- ── Why the library has to be told our name ─────────────────────────────────
--
-- Same reason core/MediaSetup.lua passes it: LibKa0s is VENDORED, so a copy
-- cannot work out which addon folder it was copied into. `addonName` is the
-- FIRST VARARG every TOC-loaded file gets — never the slash prefix, never the
-- `## Title`, never a hand-typed literal. Here those three read "PrettyChat",
-- "/pc" and "Ka0s |cffff0000P|cffff9900r|…|r", and only the first is the folder.
-- A wrong name reads some other addon's manifest, or none at all, and answers
-- nil without raising a thing.
--
-- ── Why this loads before core/Namespace.lua ────────────────────────────────
--
-- Three call sites read the TOC at FILE SCOPE rather than inside a function:
-- `NS.version` in core/Namespace.lua, `TOC_NOTES` in settings/Panel.lua and
-- `VERSION` in settings/Slash.lua. Each resolves ONCE, at load, and keeps the
-- answer for the whole session, so this file's TOC position is LOAD-BEARING the
-- same way core/MediaSetup.lua's is, and the TOC line says so.
--
-- All three call the seam UNGUARDED — `NS.Meta("Version")`, not
-- `NS.Meta and NS.Meta(...)`. That is deliberate and it is a change from the
-- shim they replaced, which core/Namespace.lua guarded with `NS.Compat and`.
-- The guard turned a mis-ordered TOC into a version silently pinned to a
-- literal, for the whole session, with nothing to see; without it the same
-- mistake raises on the first load, in the file that made it. A seam whose
-- position matters should say so by failing, not by quietly answering second
-- best. tests/test_envsetup.lua pins what the three reads resolve to.
--
-- ── What a degraded install gets ────────────────────────────────────────────
--
-- Exactly what this addon got before the library existed. Both helpers below
-- repeat the ladder the deleted shim ran, so an install missing LibKa0s still
-- reads its own TOC. That is why the fallbacks are written out rather than left
-- to answer nil: this is a seam, not a feature. Nothing here may CHANGE an
-- answer either — the shim already agreed with the library rung for rung, so a
-- difference in what comes back is a defect in the adoption rather than an
-- improvement. tests/test_envsetup.lua pins both halves.

local Env = LibStub and LibStub("LibKa0s-Env-1.0", true)

--- One field of this addon's TOC manifest, or nil.
---
--- NIL IS A REAL ANSWER, twice over: the library may be absent AND the client may
--- expose no metadata reader at all, which is exactly what a headless run looks
--- like. A field the TOC does not carry also answers nil on a perfectly healthy
--- client. Callers that need a value supply their own — `or ""`, `or NS.version`.
---
--- @param field string  a TOC key: "Version", "Notes", "Title", "Author", …
--- @return string|nil
function NS.Meta(field)
    if Env then return Env.GetAddOnMetadata(addonName, field) end
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(addonName, field)
    end
    if GetAddOnMetadata then
        return GetAddOnMetadata(addonName, field)
    end
    return nil
end

--- This addon's version string, preferring the TOC over the in-code constant.
--- Never nil.
---
--- The fallback stays visible HERE rather than inside the library because which
--- constant this addon falls back to is genuinely its own business — and because
--- a packaged addon whose TOC can be read should never report the constant
--- somebody forgot to edit. A bare "?" is the last rung and not a good one: it
--- is what `/pc version` would answer at the exact moment a user is being asked
--- what version they are running.
---
--- `NS.version` is read at CALL time rather than captured as an upvalue, because
--- core/Namespace.lua publishes it and loads after this file.
---
--- @return string
function NS.Version()
    if Env then return Env.Version(addonName, NS.version) or "?" end
    return NS.Meta("Version") or NS.version or "?"
end
