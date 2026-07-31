local addonName, NS = ...

-- NS.Compat — thin shims over WoW API surfaces that have moved between
-- client versions, so the rest of the addon calls one stable entry point.
NS.Compat = NS.Compat or {}
local Compat = NS.Compat

-- GetAddOnMetadata moved from the _G global to the C_AddOns namespace in
-- 10.1. Prefer the namespaced form; fall back to the legacy global on
-- older/edge clients. Returns nil if neither exists.
function Compat.GetAddOnMetadata(name, key)
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(name, key)
    end
    if GetAddOnMetadata then
        return GetAddOnMetadata(name, key)
    end
    return nil
end
