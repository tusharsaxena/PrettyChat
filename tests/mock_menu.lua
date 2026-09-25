-- tests/mock_menu.lua — a headless stand-in for the client's context-menu API (11.0+).
--
-- LibKa0s-Launcher-1.0's right click (minor 4, launcher-§2) opens the client's own
-- context menu, `MenuUtil.CreateContextMenu(ownerRegion, generator)`. The generator
-- is handed a root description and builds the menu on it: `root:CreateTitle(text)`
-- and `root:CreateCheckbox(text, isSelected, setSelected, data)`, the second
-- answering an element whose `SetEnabled(false)` grays the entry. Clicking an
-- enabled checkbox calls `setSelected(data)`, and what it returns is the menu's
-- response (`MenuResponse.Close` closes).
--
-- MODELED ON THE LIBRARY'S OWN, NOT COPIED FROM THE KIT. LibKa0s keeps its fake at
-- tests/mock_menu.lua in its own repo (v1.58.0), repo-local rather than in
-- tests/_kit/, and its Launcher version-4 doc tells a host suite that pins its menu
-- entries to install one of its own modeled on that file. This is that file, in
-- this repo's indentation, with the same fidelity and the same helper names, so a
-- case reads the same in either suite.
--
-- Installed through a loader `opts.mock`, into the mock table the environment
-- resolves globals through, BEFORE any source loads: the library resolves
-- `MenuUtil` at CALL time (every right click), so it sees the fake exactly as it
-- would see the client's.
--
-- FIDELITY. Two things the real API does that a convenient fake would not:
--   * a disabled element is never clicked. `Click` refuses a grayed entry the way
--     the client does; a case that wants the library's own gate calls `ForceClick`;
--   * `CreateContextMenu` runs the generator when the menu opens, once per open, so
--     anything cached across opens reads stale here as it would in the client.

return function(mocks)
    local M = { menus = {}, opens = 0 }
    local RESPONSE = { Close = 1, Refresh = 2, Open = 3 }

    --- One opened menu: its owner, its titles and its entries in creation order.
    local function newRoot(owner)
        local menu = { owner = owner, titles = {}, entries = {} }
        local root = {}
        function root.CreateTitle(_, text)
            menu.titles[#menu.titles + 1] = text
            return {}
        end
        function root.CreateCheckbox(_, text, isSelected, setSelected, data)
            local entry = { text = text, isSelected = isSelected,
                            setSelected = setSelected, data = data, enabled = true }
            local element = {}
            function element.SetEnabled(_, on) entry.enabled = on and true or false end
            function element.IsEnabled() return entry.enabled end
            menu.entries[#menu.entries + 1] = entry
            return element
        end

        --- The entries' texts, in order.
        function menu:Texts()
            local out = {}
            for i, e in ipairs(self.entries) do out[i] = e.text end
            return out
        end
        --- The entry whose text starts with `prefix`, or nil.
        function menu:Find(prefix)
            for _, e in ipairs(self.entries) do
                if e.text:sub(1, #prefix) == prefix then return e end
            end
        end
        --- Whether an entry draws checked, as the client asks it.
        function menu:Checked(prefix)
            local e = self:Find(prefix)
            return e and e.isSelected(e.data) and true or false
        end
        --- Click an entry as a player can: a grayed one does nothing and answers nil.
        function menu:Click(prefix)
            local e = assert(self:Find(prefix), "no menu entry " .. prefix)
            if not e.enabled then return nil end
            return e.setSelected(e.data)
        end
        --- Run an entry's handler regardless of its gray, to reach the library's gate.
        function menu:ForceClick(prefix)
            local e = assert(self:Find(prefix), "no menu entry " .. prefix)
            return e.setSelected(e.data)
        end
        return root, menu
    end

    M.MenuUtil = {
        CreateContextMenu = function(owner, generator)
            if owner == nil then error("CreateContextMenu: an owner region is required", 2) end
            local root, menu = newRoot(owner)
            M.opens = M.opens + 1
            generator(owner, root)
            M.menus[#M.menus + 1] = menu
            M.last = menu
            return menu
        end,
    }

    --- Put the fake API in the environment, or take it away (a client before 11.0).
    function M.install()
        mocks.MenuUtil = M.MenuUtil
        mocks.MenuResponse = RESPONSE
    end
    function M.remove()
        mocks.MenuUtil = nil
        mocks.MenuResponse = nil
    end

    M.RESPONSE = RESPONSE
    M.install()
    return M
end
