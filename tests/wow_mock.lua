-- tests/wow_mock.lua
--
-- Builds a mock WoW global environment so the addon's Lua sources can be
-- loaded and exercised headlessly under stock Lua 5.1 (no WoW client).
--
-- Design notes:
--   * The DB and the _G global-string table ARE real Lua tables, so the
--     schema / apply / render logic is genuinely exercised (per the
--     harness design in docs/audits/2026-07-12/04_TECHNICAL_DESIGN.md §A).
--   * `_G` is the env itself, so `_G[GLOBALNAME] = value` writes in
--     ApplyStrings land back in the same table the loader reads.
--   * Frame and AceGUI widget mocks are stubs, not a layout engine — they
--     model *state and wiring* (scripts, callbacks, shown-ness, child
--     order, text) and nothing about pixels. That is deliberately enough
--     to drive settings/Panel.lua headlessly: the panel's contract is
--     "which widget, wired to which schema path", not where it lands.
--
-- Mock fidelity — three pieces are load-bearing and must not be
-- simplified away:
--   * the AceAddon mock stamps AceConsole's colliding `:Print` mixin, so
--     the tests exercise the real printer-reclaim path (anti-pattern #36);
--   * frames resolve UNKNOWN **PascalCase** keys to a self-returning
--     no-op (every WoW/AceGUI method is PascalCase) but resolve unknown
--     lowercase keys to nil — addon-owned fields (`panel.defaultsBtn`,
--     `frame.log`, `scroll.content`) are lowercase, and a catch-all that
--     answered those with a truthy function would silently invert every
--     `if not panel.defaultsBtn` guard in the addon;
--   * Show()/Hide() fire the OnShow/OnHide scripts and hooks, which is
--     what makes the panel's lazy first-OnShow body build testable.

local M = {}

-- Metadata returned by C_AddOns.GetAddOnMetadata (tests may override).
M.metadata = {
    Version  = "1.4.0",
    Notes    = "Prettier chat messages",
    Title    = "Ka0s Pretty Chat",
    IconTexture = "2056011",
}

local function noop() end

-- ---- Frame mock ------------------------------------------------------

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
            -- Anything else => an addon-owned field that genuinely is nil.
            if type(k) == "string" and k:find("^%u") then
                return function(self) return self end
            end
            return nil
        end,
    })
end
M.newFrame = newFrame

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

-- ScrollingMessageFrame surface. The scroll getters return real numbers so
-- DebugLog:UpdateScrollBar walks its whole body instead of bailing at the
-- type guard.
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

-- ---- AceGUI widget mock ---------------------------------------------

local widgetMethods = {}

local function newWidget(wtype)
    local w = {
        type      = wtype,
        frame     = newFrame(),
        children  = {},
        callbacks = {},
        disabled  = false,
    }
    -- Label / Heading expose a `.label` FontString in real AceGUI; the panel
    -- font-object branches key off it, so model it for those two types only.
    if wtype == "Label" or wtype == "Heading" then
        w.label = newFrame()
    end
    return setmetatable(w, { __index = widgetMethods })
end

function widgetMethods:SetText(text)  self.text = text;   return self end
function widgetMethods:GetText()      return self.text end
function widgetMethods:SetLabel(text) self.labelText = text; return self end
function widgetMethods:SetValue(v)    self.value = v;    return self end
function widgetMethods:GetValue()     return self.value end
function widgetMethods:SetDisabled(v) self.disabled = v and true or false; return self end
function widgetMethods:SetLayout(l)   self.layout = l;   return self end
function widgetMethods:SetFullWidth(v)     self.fullWidth = v and true or false; return self end
function widgetMethods:SetRelativeWidth(v) self.relativeWidth = v; return self end
function widgetMethods:SetHeight(h)   self.height = h;   return self end
function widgetMethods:SetWidth(w)    self.width = w;    return self end

function widgetMethods:SetCallback(name, fn)
    self.callbacks[name] = fn
    return self
end

-- Invoke a registered AceGUI callback the way the widget would
-- (widget, event, ...). Returns false when nothing is registered.
function widgetMethods:Fire(name, ...)
    local fn = self.callbacks[name]
    if not fn then return false end
    fn(self, name, ...)
    return true
end

function widgetMethods:AddChild(child)
    self.children[#self.children + 1] = child
    return self
end

-- Depth-first walk of a widget tree, newest-last (build order).
function M.walkWidgets(widget, out)
    out = out or {}
    for _, child in ipairs(widget.children or {}) do
        out[#out + 1] = child
        M.walkWidgets(child, out)
    end
    return out
end

local function deepcopy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = deepcopy(v) end
    return o
end

function M.newEnv()
    local env = {}

    -- Standard Lua 5.1 library passthrough.
    local passthrough = {
        "assert", "error", "ipairs", "next", "pairs", "pcall", "print",
        "select", "setmetatable", "getmetatable", "tonumber", "tostring",
        "type", "unpack", "rawget", "rawset", "rawequal", "xpcall",
        "collectgarbage", "string", "table", "math", "os", "io",
    }
    for _, name in ipairs(passthrough) do env[name] = _G[name] end
    env.setfenv    = setfenv
    env.getfenv    = getfenv
    env.loadstring = loadstring
    env._VERSION   = _VERSION
    env._G         = env

    -- ---- Blizzard surface -------------------------------------------
    local chatFrame = { messages = {} }
    function chatFrame:AddMessage(msg) self.messages[#self.messages + 1] = msg end
    env.DEFAULT_CHAT_FRAME = chatFrame

    -- Every frame the addon creates, in creation order, keyed by the global
    -- name when it has one (the debug console windows).
    local frames = { all = {}, byName = {} }
    env._frames = frames

    env.CreateFrame      = function(_, name)
        local f = newFrame(name)
        frames.all[#frames.all + 1] = f
        if name then frames.byName[name] = f end
        return f
    end
    env.UIParent         = newFrame("UIParent")
    env.InCombatLockdown = function() return false end
    -- Globals the on-screen debug console (core/DebugLog.lua) touches.
    env.date             = os.date
    env.wipe             = function(t) for k in pairs(t) do t[k] = nil end return t end
    env.UISpecialFrames  = {}
    env.C_Timer          = { After = function(_, fn) if fn then fn() end end }
    env.C_AddOns         = {
        GetAddOnMetadata = function(_, key) return M.metadata[key] end,
        LoadAddOn        = function() return true end,
    }
    env.GetAddOnMetadata = function(_, key) return M.metadata[key] end

    env.StaticPopupDialogs = {}
    env._popupsShown       = {}
    env.StaticPopup_Show   = function(which) env._popupsShown[#env._popupsShown + 1] = which end
    env.GameTooltip        = newFrame("GameTooltip")
    env.YES = "Yes"
    env.NO  = "No"

    -- ---- Settings API ------------------------------------------------
    -- Modelled (unlike the pre-1.4 mock, which omitted it so registerPanels
    -- early-returned) so settings/Panel.lua's registration path is exercised.
    -- SettingsPanel stays nil: its category-tree internals are private API the
    -- addon already pcall-guards, and OpenConfig's "could not auto-expand"
    -- fallback is the branch worth covering.
    local settings = { categories = {}, subcategories = {}, addonCategories = {}, opened = {} }
    env._settings = settings

    local function newCategory(name, frame)
        local id = "cat:" .. name
        return { name = name, frame = frame, GetID = function() return id end }
    end

    env.Settings = {
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
    env.SettingsPanel = nil

    -- Font objects referenced via _G.GameFont* — harmless placeholders.
    for _, fname in ipairs({
        "GameFontNormal", "GameFontNormalLarge", "GameFontNormalHuge",
        "GameFontHighlight", "GameFontDisable",
    }) do env[fname] = newFrame(fname) end

    -- ---- LibStub + Ace3 fakes ---------------------------------------
    local libs   = {}
    local addons = {}

    env.LibStub = function(name) return libs[name] end

    libs["AceAddon-3.0"] = {
        -- Real AceAddon:NewAddon([object,] name, ...mixins). If the first arg is
        -- a table it IS the addon object (the NS table, architecture-§2);
        -- otherwise a fresh object is created and the first arg is the name.
        NewAddon = function(_, first, ...)
            local object, name
            if type(first) == "table" then
                object, name = first, (...)
            else
                object, name = {}, first
            end
            object.name = name
            -- AceConsole mixin. Records the registrations so a suite can prove
            -- both /pc and its /prettychat alias reach the dispatcher.
            object.slashCommands = {}
            object.RegisterChatCommand = function(self, cmd, handler)
                self.slashCommands[cmd] = handler
            end
            object.Printf              = noop
            -- AceConsole embeds a :Print mixin onto the object. Stamp a
            -- colliding printer (its |cff33ff99Name|r: tag) so the suite can
            -- prove core/PrettyChat.lua reclaims NS.Print after registration
            -- (anti-pattern #36).
            object.Print = function(_, msg)
                chatFrame:AddMessage("|cff33ff99" .. tostring(name) .. "|r: " .. tostring(msg))
            end
            addons[name] = object
            return object
        end,
        GetAddon = function(_, name) return addons[name] end,
    }

    libs["AceDB-3.0"] = {
        New = function(_, _svName, defaults)
            -- Copy every declared namespace (profile, global, ...) so
            -- migration code that reads db.global works, and guarantee
            -- both common namespaces exist even when undeclared.
            local db = {}
            if defaults then
                for k, v in pairs(defaults) do db[k] = deepcopy(v) end
            end
            db.profile = db.profile or {}
            db.global  = db.global or {}
            -- Single shared Default profile (real AceDB was created with the default-profile
            -- flag). GetCurrentProfile lets the debug console's [Init] summary read it.
            db.GetCurrentProfile = function() return "Default" end
            return db
        end,
    }

    libs["AceConsole-3.0"] = { RegisterChatCommand = noop }

    -- AceGUI: records every widget it creates so a suite can walk the panel
    -- tree that settings/Panel.lua built.
    local created = {}
    env._widgets = created
    libs["AceGUI-3.0"] = {
        Create = function(_, wtype)
            local w = newWidget(wtype)
            created[#created + 1] = w
            return w
        end,
        RegisterAsContainer = noop,
        RegisterAsWidget    = noop,
    }

    return env
end

return M
