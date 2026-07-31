-- tests/test_lifecycle.lua — core/PrettyChat.lua: the AceAddon lifecycle
-- (OnInitialize's DB provisioning + slash registration, OnEnable's
-- original-string snapshot and first apply), the shared [PC] chat printer,
-- and the combat-gated OpenConfig with its four exit paths.

return function(ctx)
    local t     = ctx.t
    local test  = ctx.test
    local inst  = ctx.loadAddon()
    local NS    = inst.NS
    local addon = inst.addon
    local env   = inst.env
    local Color = NS.Const.Color

    local function last() return env.DEFAULT_CHAT_FRAME.messages[#env.DEFAULT_CHAT_FRAME.messages] end

    test("the addon object and the bootstrap namespace are one table", function()
        -- architecture-§2: NS IS the AceAddon object, so modules can hang
        -- methods off either name and reach the same table.
        t.eq(addon, NS, "GetAddon returns the NS table itself")
        t.eq(addon.name, "PrettyChat", "the addon registered under its folder name")
    end)

    test("OnInitialize provisions both AceDB namespaces", function()
        t.truthy(addon.db, "the DB is created")
        t.eq(type(addon.db.profile.categories), "table",
            "profile defaults supplied the categories table")
        t.eq(addon.db.global.schemaVersion, NS.Database.SCHEMA_VERSION,
            "global defaults supplied the schema version, migrated to current")
    end)

    test("OnInitialize registers /pc and its /prettychat alias", function()
        t.eq(addon.slashCommands["pc"], "OnSlashCommand", "/pc reaches the dispatcher")
        t.eq(addon.slashCommands["prettychat"], "OnSlashCommand",
            "/prettychat is an alias for the same handler")
    end)

    test("OnEnable snapshots a Blizzard original for every registered global", function()
        local registered = 0
        for _, catData in pairs(NS.Defaults) do
            for globalName in pairs(catData.strings) do
                registered = registered + 1
                t.eq(addon.originalStrings[globalName], "ORIG:" .. globalName,
                    globalName .. " was snapshotted before the first apply")
            end
        end
        t.truthy(registered > 0, "there were globals to snapshot")
    end)

    test("OnEnable applies the overrides so live chat is rewritten at load", function()
        local row
        for _, r in ipairs(NS.Schema.RowsByCategory("Loot")) do
            if r.kind == "string_format" then row = r break end
        end
        t.eq(env[row.globalName], row.default,
            "the shipped default is already in _G after OnEnable")
    end)

    test("NS.Print prepends the cyan [PC] tag to every line", function()
        NS.Print("plain message")
        t.eq(last(), NS.PREFIX .. "plain message", "the tag is prepended verbatim")
    end)

    test("NS.Print neutralises a value the concat probe rejects", function()
        -- events-frames-taint-§8: a combat "secret" must never reach the
        -- output path. The printer routes through Util.SafeToString.
        local secret = setmetatable({}, { __concat = function() error("secret") end })
        local ok = pcall(NS.Print, secret)
        t.truthy(ok, "printing a protected value never raises")
        t.eq(last(), NS.PREFIX .. "<secret>", "the value is replaced by the placeholder")
    end)

    test("OpenConfig refuses during combat without touching the Settings API", function()
        -- options-ui-§2: OpenToCategory triggers protected code; calling it in
        -- combat taints the panel for the session, so we refuse outright.
        local opens = #env._settings.opened
        env.InCombatLockdown = function() return true end
        addon:OpenConfig()
        env.InCombatLockdown = function() return false end
        t.eq(#env._settings.opened, opens, "the Settings API was not called")
        t.truthy(last():find("cannot open settings during combat", 1, true),
            "the refusal is surfaced to the user")
        t.truthy(last():find(Color.grey, 1, true), "the notice renders grey")
    end)

    test("OpenConfig opens the registered category out of combat", function()
        local opens = #env._settings.opened
        addon:OpenConfig()
        t.eq(#env._settings.opened, opens + 1, "Settings.OpenToCategory was called once")
        t.eq(env._settings.opened[#env._settings.opened], addon.optionsCategoryID,
            "it opened the category the panel registration recorded")
    end)

    test("the auto-expand fallback notice is printed once per session", function()
        -- SettingsPanel is private API and absent here, so expandMainCategory
        -- fails; the user gets one grey hint, never a per-open stream.
        addon._expandWarned = nil
        addon:OpenConfig()
        t.truthy(last():find("could not auto-expand", 1, true), "the first open hints")
        local after = #env.DEFAULT_CHAT_FRAME.messages
        addon:OpenConfig()
        t.eq(#env.DEFAULT_CHAT_FRAME.messages, after, "the second open prints nothing")
    end)

    test("OpenConfig reports a category Blizzard refused to open", function()
        env._settings.openResult = false
        addon:OpenConfig()
        env._settings.openResult = nil
        t.truthy(last():find("could not open settings panel", 1, true),
            "an explicit false from OpenToCategory is surfaced")
    end)

    test("OpenConfig is a silent no-op when the Settings API is unavailable", function()
        local savedSettings, savedID = env.Settings, addon.optionsCategoryID
        env.Settings = nil
        local before = #env.DEFAULT_CHAT_FRAME.messages
        local ok = pcall(function() addon:OpenConfig() end)
        env.Settings = savedSettings

        t.truthy(ok, "a missing Settings API never raises")
        t.eq(#env.DEFAULT_CHAT_FRAME.messages, before, "and prints nothing to chat")

        addon.optionsCategoryID = nil
        addon:OpenConfig()
        addon.optionsCategoryID = savedID
        t.eq(#env.DEFAULT_CHAT_FRAME.messages, before,
            "an unregistered category is equally quiet")
    end)
end
