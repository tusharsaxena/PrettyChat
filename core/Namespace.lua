local addonName, NS = ...

-- Shared namespace bootstrap. Records addon identity so any module can read
-- it without re-querying the TOC. `NS` is the addon's single private table — we never
-- create _G[addonName]. Loads right after Compat/Constants so metadata exists early.
NS.name    = addonName
NS.version = (NS.Compat and NS.Compat.GetAddOnMetadata(addonName, "Version")) or "1.4.0"
