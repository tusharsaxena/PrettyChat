local addonName, NS = ...

-- Shared namespace bootstrap. Records addon identity so any module can read
-- it without re-querying the TOC. `NS` is the addon's single private table — we never
-- create _G[addonName]. Loads after core/EnvSetup.lua, which publishes the seam this
-- file reads AT FILE SCOPE — see the TOC, where that position is load-bearing.
NS.name    = addonName
NS.version = NS.Meta("Version") or "1.4.0"
