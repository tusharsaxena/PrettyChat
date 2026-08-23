-- tests/wow_mock.lua
--
-- PrettyChat's EXTENDER over the shared kit's mock_base (testing-§1). The base
-- builder owns everything universal — LibStub with a real NewLibrary, AceDB's
-- merge-in-place copyDefaults, AceConsole's :Print clobber, the AceGUI widget
-- recorder, the Settings registrars, the timer queue. This file overwrites the
-- handful of keys PrettyChat genuinely needs differently, and adds the ones the
-- base deliberately omits.
--
-- ── Why this is an extender and not a swap ──────────────────────────────────
--
-- The base's own README names the divergence that forces most of what follows:
-- its `CreateTexture` / `CreateFontString` answer from the frame stub's
-- metatable and therefore return THE FRAME ITSELF. PrettyChat's debug console
-- hangs three distinct FontStrings off one title bar (the title, the ON/OFF
-- toggle label, the line counter) and asserts on each independently, so an
-- aliased FontString would make `frame.debugToggle.text` read back the window
-- TITLE and the header-label case would pass on the wrong string. WhatGroup's
-- and KickCD's mocks make them distinct for the same reason and the kit README
-- agrees they are right; this is the third.
--
-- The documented overrides, each with the reason it cannot come from the base:
--
--   1.  CreateFrame           — a registry (`_frames.all` / `.byName`) so a suite
--                               can reach `PrettyChatDebugWindow` by its global
--                               name, which is the only handle on a window the
--                               console keeps private.
--   2.  frame CreateFontString / CreateTexture
--                             — distinct objects (see above).
--   3.  frame Show/Hide       — FIRE the OnShow/OnHide scripts and hooks. The
--                               base tracks `__shown` only; every settings page
--                               builds its body on first OnShow, so a Show that
--                               did not fire would leave the whole panel layer
--                               untestable.
--   4.  frame setters/getters — SetText/GetText, SetSize/GetWidth/GetHeight and
--                               GetTextColor return real values (fidelity rule 2):
--                               the header divider tints from `titleFS:GetTextColor()`.
--   5.  ScrollingMessageFrame — AddMessage/Clear recording into `.messages`, plus
--                               numeric GetMaxScrollRange/GetScrollOffset, so the
--                               console's scroll sync walks its whole body.
--   6.  DEFAULT_CHAT_FRAME    — records `.messages`. The base's stub frame answers
--                               AddMessage from the metatable and keeps nothing,
--                               which would silence every chat assertion in the suite.
--   7.  Settings              — records categories / subcategories / addonCategories
--                               and OpenToCategory calls, so a suite can assert WHICH
--                               category the panel-open asked for, and how many times.
--                               The base records only the last main panel.
--   8.  SettingsPanel = nil   — the base ships a stub frame whose metatable answers
--                               every PascalCase key with a self-returning function, so
--                               the library's private category-tree walk would appear to
--                               SUCCEED against a stub rather than take the guarded
--                               fallback a live client can actually hit.
--   9.  AceAddon              — adds GetAddon (three PrettyChat files call it) and
--                               records RegisterChatCommand, which the base no-ops.
--  10.  AceGUI Create         — adds `:Fire(name, ...)` beside the base's `__fire`
--                               and mirrors creation order into `_widgets`.
--  11.  C_AddOns / GetAddOnMetadata
--                             — deliberately absent from the base so a Compat shim's
--                               fallback branch stays drivable; added here, where this
--                               addon's own tests manage them.
--  12.  StaticPopup_Show      — records into `_popupsShown`; the base no-ops it.
--  13.  GameTooltip AddLine   — records into `.lines` so a tooltip body is assertable.
--  14.  YES / NO / GameFont*  — plain globals the base has no reason to carry.
--  15.  _G = M               — see below.
--
-- ── `_G` is the mock table itself ───────────────────────────────────────────
--
-- PrettyChat's whole feature is rewriting `_G[GLOBALNAME]`, and `tests/loader.lua`
-- builds a FRESH mock per instance, so pointing `_G` back at the mock is what
-- gives each loaded instance its own isolated global-string table: a write in
-- ApplyStrings lands in the same table the suite reads back through `inst.env`.
-- The kit loader's env resolves unknown keys to the real `_G`, which stays the
-- home of the standard Lua library and nothing else.

local base = dofile("tests/_kit/mock_base.lua")

-- Metadata returned by C_AddOns.GetAddOnMetadata. Module-level so `ctx.mock.metadata`
-- and every built environment name the same table.
local METADATA = {
    Version     = "1.4.0",
    Notes       = "Prettier chat messages",
    Title       = "Ka0s Pretty Chat",
    IconTexture = "2056011",
}

local function noop() end

-- ---- the richer frame stub -------------------------------------------------

local frameMethods = {}

local function newFrame(name)
    local f = {
        _name     = name,
        _shown    = true,
        _scripts  = {},   -- script name -> primary handler
        _hooks    = {},   -- script name -> { handler, ... }
        _width    = 600,
        _height   = 400,
        _children = {},
        messages  = {},   -- ScrollingMessageFrame line sink
    }
    return setmetatable(f, {
        __index = function(_, k)
            local m = frameMethods[k]
            if m then return m end
            -- PascalCase => an (unmodelled) WoW method: inert, self-returning.
            -- Anything else => an addon-owned field that genuinely is nil. A
            -- catch-all answering lowercase keys with a truthy function would
            -- silently invert every `if not panel.defaultsBtn` guard in the addon.
            if type(k) == "string" and k:find("^%u") then
                return function(self) return self end
            end
            return nil
        end,
    })
end

function frameMethods:SetScript(script, handler)
    self._scripts[script] = handler
    return self
end

function frameMethods:GetScript(script)
    return self._scripts[script]
end

function frameMethods:HookScript(script, handler)
    self._hooks[script] = self._hooks[script] or {}
    table.insert(self._hooks[script], handler)
    return self
end

-- Run a script + every hook attached to it, in registration order.
function frameMethods:FireScript(script, ...)
    local primary = self._scripts[script]
    if primary then primary(self, ...) end
    for _, h in ipairs(self._hooks[script] or {}) do h(self, ...) end
    return self
end

-- The kit's own name for the same thing, so a suite written to the kit idiom
-- and one written to this repo's drive the same handler.
frameMethods.__fire = frameMethods.FireScript

function frameMethods:Show()
    self._shown = true
    return self:FireScript("OnShow")
end

function frameMethods:Hide()
    self._shown = false
    return self:FireScript("OnHide")
end

function frameMethods:SetShown(v)
    if v then return self:Show() end
    return self:Hide()
end

function frameMethods:IsShown() return self._shown and true or false end
function frameMethods:IsVisible() return self._shown and true or false end

function frameMethods:GetName() return self._name end

function frameMethods:SetText(text) self.text = text; return self end
function frameMethods:GetText() return self.text end

function frameMethods:SetWidth(w)  self._width  = w; return self end
function frameMethods:SetHeight(h) self._height = h; return self end
function frameMethods:SetSize(w, h) self._width, self._height = w, h; return self end
function frameMethods:GetWidth()  return self._width  end
function frameMethods:GetHeight() return self._height end

function frameMethods:GetTextColor() return 1, 1, 1, 1 end

-- GameTooltip surface: SetText lands in `text` (above) and each AddLine is
-- recorded, so a suite can read back what a tooltip would show.
function frameMethods:AddLine(text)
    self.lines = self.lines or {}
    self.lines[#self.lines + 1] = text
    return self
end

-- Distinct child objects, NOT the frame itself — the base's documented divergence.
function frameMethods:CreateFontString()
    local fs = newFrame()
    table.insert(self._children, fs)
    return fs
end

function frameMethods:CreateTexture()
    local tex = newFrame()
    table.insert(self._children, tex)
    return tex
end

-- ScrollingMessageFrame surface. The scroll getters return real numbers so the
-- console's UpdateScrollBar walks its whole body instead of bailing at the type guard.
function frameMethods:AddMessage(msg)
    self.messages[#self.messages + 1] = msg
    return self
end

function frameMethods:Clear()
    for i = #self.messages, 1, -1 do self.messages[i] = nil end
    return self
end

function frameMethods:GetMaxScrollRange() return self._maxScroll or 0 end
function frameMethods:GetScrollOffset()   return self._scrollOffset or 0 end
function frameMethods:SetScrollOffset(v)  self._scrollOffset = v; return self end

function frameMethods:SetMinMaxValues(lo, hi)
    self._min, self._max = lo, hi
    return self
end

function frameMethods:SetValue(v) self._value = v; return self end
function frameMethods:GetValue()  return self._value end

-- ---- the builder -----------------------------------------------------------

local function build()
    local M = base()

    -- `_G` is this table. See the header.
    M._G = M
    M.__metadata = METADATA

    -- 1/2/3/4/5 — the richer frame, plus the creation registry.
    local frames = { all = {}, byName = {} }
    M._frames = frames
    M.__stubFrame = newFrame
    M.CreateFrame = function(_, name)
        local f = newFrame(name)
        frames.all[#frames.all + 1] = f
        if name then frames.byName[name] = f end
        return f
    end
    M.UIParent = newFrame("UIParent")

    -- 6 — a recording chat frame.
    local chatFrame = newFrame("DEFAULT_CHAT_FRAME")
    M.DEFAULT_CHAT_FRAME = chatFrame

    -- 13 — a recording tooltip.
    M.GameTooltip = newFrame("GameTooltip")

    -- 7 — the Settings registrars, recorded.
    local settings = { categories = {}, subcategories = {}, addonCategories = {}, opened = {} }
    M._settings = settings

    local function newCategory(name, frame)
        local id = "cat:" .. tostring(name)
        return { name = name, frame = frame, GetID = function() return id end }
    end

    M.Settings = {
        RegisterCanvasLayoutCategory = function(frame, name)
            local cat = newCategory(name, frame)
            settings.categories[#settings.categories + 1] = cat
            return cat
        end,
        RegisterCanvasLayoutSubcategory = function(parent, frame, name)
            local sub = newCategory(name, frame)
            sub.parent = parent
            settings.subcategories[#settings.subcategories + 1] = sub
            return sub
        end,
        RegisterAddOnCategory = function(cat)
            settings.addonCategories[#settings.addonCategories + 1] = cat
        end,
        OpenToCategory = function(id)
            settings.opened[#settings.opened + 1] = id
            return settings.openResult
        end,
    }

    -- 8 — absent, so the private category-tree walk takes its guarded fallback.
    M.SettingsPanel = nil

    -- 12 — the confirm popup, recorded.
    M._popupsShown     = {}
    M.StaticPopup_Show = function(which) M._popupsShown[#M._popupsShown + 1] = which end

    -- 11 — the metadata surfaces the base deliberately leaves out.
    M.C_AddOns = {
        GetAddOnMetadata = function(_, key) return METADATA[key] end,
        LoadAddOn        = function() return true end,
    }
    M.GetAddOnMetadata = function(_, key) return METADATA[key] end

    -- 14 — plain globals.
    M.YES = "Yes"
    M.NO  = "No"
    -- The client's own default face, and the one core/Constants.lua falls back to when
    -- the media seam answers nil. Present here because a nil fallback would let the
    -- degraded-console case pass on nil == nil while the real client drew nothing.
    M.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
    for _, fname in ipairs({
        "GameFontNormal", "GameFontNormalSmall", "GameFontNormalLarge", "GameFontNormalHuge",
        "GameFontHighlight", "GameFontDisable",
    }) do M[fname] = newFrame(fname) end

    -- 9 — AceAddon with GetAddon and a recorded chat-command registry, keeping the
    -- base's AceConsole :Print clobber (which core/CoreSetup.lua has to reclaim).
    local addons = {}
    local baseNewAddon = M.__libs["AceAddon-3.0"].NewAddon
    M.__libs["AceAddon-3.0"] = {
        -- Real signature: NewAddon([object,] name, ...mixins). When the first arg is
        -- a table it IS the addon object (the NS table, architecture-§2).
        NewAddon = function(self, first, ...)
            local object, name
            if type(first) == "table" then
                object, name = first, (...)
            else
                object, name = {}, first
            end
            baseNewAddon(self, object)
            object.name = name
            object.slashCommands = {}
            object.RegisterChatCommand = function(s, cmd, handler)
                s.slashCommands[cmd] = handler
            end
            object.Printf = noop
            -- AceConsole's embed, faithful to the base's shape but landing in THIS
            -- environment's chat frame rather than a real global that is never set.
            object.Print = function(selfOrMsg, ...)
                local parts = { "|cff33ff99" .. tostring(selfOrMsg) .. "|r:" }
                for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
                chatFrame:AddMessage(table.concat(parts, " "))
            end
            addons[name] = object
            return object
        end,
        GetAddon = function(_, name) return addons[name] end,
    }

    -- 10 — AceGUI: creation order plus the `:Fire` alias this repo's suites drive.
    local aceGUI  = M.__libs["AceGUI-3.0"]
    local created = {}
    M._widgets = created
    local baseCreate = aceGUI.Create
    aceGUI.Create = function(self, wtype)
        local w = baseCreate(self, wtype)
        w.Fire = w.__fire
        -- Label / Heading expose a `.label` FontString in real AceGUI; the panel's
        -- font-object branches key off it, so model it for those two types.
        if (wtype == "Label" or wtype == "Heading") and not w.label then
            w.label = newFrame()
        end
        created[#created + 1] = w
        return w
    end

    return M
end

-- A callable table: `dofile("tests/wow_mock.lua")()` builds an environment
-- (testing-§1's shape), while `.metadata` stays reachable for the suites that
-- assert the TOC values reached the addon.
return setmetatable({ metadata = METADATA }, { __call = build })
