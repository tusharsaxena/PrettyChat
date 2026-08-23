-- tests/test_mediasetup.lua — core/MediaSetup.lua, the LibKa0s-Media-1.0 seam.
--
-- WHAT THIS FILE EXISTS TO CATCH is a failure that leaves every other suite green.
-- A font or texture path is a plain string handed to the client, and a string that
-- names a file which is not there draws NOTHING and raises NOTHING. So the two
-- things worth pinning are the ones no assertion elsewhere can see: that the seam
-- answers the path the vendored payload actually carries, and that `nil` — the
-- honest answer when the library is absent or the name is not one it ships — comes
-- back as nil rather than as a plausible-looking path built by concatenation.
--
-- PrettyChat draws no icons of its own today: it builds no frames at all, and the
-- marks a player sees on the debug console are drawn by LibKa0s from the folder
-- name core/DebugLogSetup.lua's descriptor passes it. The catalog cases below
-- therefore pin the names THAT descriptor makes the library reach for — copy,
-- clear and close — so a rename upstream is caught here rather than by someone
-- noticing a multiplication sign.

local ctx = _G.PC_TEST
local t    = ctx.t
local test = ctx.test

local inst = ctx.loadAddon()
local NS   = inst.NS

local VENDORED = "Interface\\AddOns\\PrettyChat\\libs\\LibKa0s\\media\\"

local function media(instance)
    return (instance or inst).mocks.LibStub("LibKa0s-Media-1.0", true)
end

-- ── the seam ────────────────────────────────────────────────────────────────

test("MediaSetup: NS.Icon answers the vendored path, EXTENSIONLESS", function()
    -- Extensionless is not a preference. The client appends `.tga` itself, and a
    -- path that already carries it is one of the two spellings that draw nothing.
    t.eq(NS.Icon("close"), VENDORED .. "icons\\close")
end)

test("MediaSetup: an icon the library does not ship answers nil", function()
    -- nil is a value a caller can branch on. A plausible path to art that is not
    -- there is a control that is simply absent, forever, silently.
    t.nilv(NS.Icon("nosuchicon"))
end)

test("MediaSetup: NS.MediaFont answers the vendored face, and only for a face it ships",
function()
    t.eq(NS.MediaFont("JetBrains Mono"), VENDORED .. "fonts\\JetBrainsMono-Regular.ttf")
    t.nilv(NS.MediaFont("Comic Sans"))
end)

test("MediaSetup: the font this addon names is one the library carries", function()
    -- Two names for one thing, in two repos: Const.FONT_MONO_NAME is what this addon
    -- asks for, and the library's FONTS is what it registers with LibSharedMedia and
    -- resolves paths from. A name nobody carries resolves to nil, and the console
    -- then renders in the proportional fallback — the exact outcome shipping a
    -- monospace face was meant to prevent.
    local Media = media()
    t.truthy(Media ~= nil, "the vendored LibKa0s-Media-1.0 did not load")
    t.truthy(Media.FONTS[NS.Const.FONT_MONO_NAME] ~= nil,
        "FONT_MONO_NAME is '" .. tostring(NS.Const.FONT_MONO_NAME)
        .. "', which the library's FONTS does not carry")
    t.eq(NS.Const.FONT_MONO, NS.MediaFont(NS.Const.FONT_MONO_NAME))
end)

-- ── the catalog, against what this addon actually causes to be drawn ─────────

test("MediaSetup: every mark the console title bar reaches for is one the library ships",
function()
    -- These three are not spelled anywhere in this addon's source: the descriptor
    -- passes the FOLDER NAME and LibKa0s asks its own catalog for them. That is
    -- precisely why they are pinned here — a rename upstream would reach this repo
    -- through a re-vendor with nothing in it to fail.
    local Media = media()
    local known = {}
    for _, name in ipairs(Media.ICONS) do known[name] = true end
    for _, name in ipairs({ "copy", "clear", "close" }) do
        t.truthy(known[name] == true,
            "the console draws '" .. name .. "', which LibKa0s-Media does not ship")
        t.truthy(NS.Icon(name) ~= nil, "NS.Icon answered nil for " .. name)
    end
end)

test("MediaSetup: every name the library ships has a file in the vendored copy", function()
    -- The library's own suite checks its catalog against its own directory. This
    -- checks THE COPY: a re-vendor that dropped a file, or a packaging rule that
    -- filtered one out, leaves a catalog naming art this build does not carry.
    local Media = media()
    local root = (ctx.root or ".") .. "/libs/LibKa0s/media/icons/"
    local missing = {}
    for _, name in ipairs(Media.ICONS) do
        local fh = io.open(root .. name .. ".tga", "rb")
        if fh then fh:close() else missing[#missing + 1] = name end
    end
    t.eq(table.concat(missing, ", "), "")
end)

test("MediaSetup: the vendored face is on disk where the seam says it is", function()
    -- Same argument as the icons, for the one asset this addon genuinely consumes.
    -- media/fonts/ used to be a second copy of these bytes in this repo; it is gone,
    -- so the payload is now the only place the console's face can come from.
    local rel = NS.MediaFont(NS.Const.FONT_MONO_NAME)
        :gsub("^Interface\\AddOns\\PrettyChat\\", ""):gsub("\\", "/")
    local fh = io.open((ctx.root or ".") .. "/" .. rel, "rb")
    t.truthy(fh ~= nil, "no file at " .. rel)
    if fh then fh:close() end
end)

-- ── degraded ────────────────────────────────────────────────────────────────

test("MediaSetup: with no library there is no art and no face, and that is not an error",
function()
    -- The art and the font are INSIDE the payload that is missing, so a degraded
    -- install has neither. Both seams answering nil is the contract — and it is what
    -- lets core/Constants.lua fall back to the client's own STANDARD_TEXT_FONT
    -- rather than to a path pointing at nothing.
    local bare = ctx.loadAddon({ skip = { "libs/LibKa0s/Media.lua" } })
    t.nilv(bare.NS.Icon("close"))
    t.nilv(bare.NS.MediaFont("JetBrains Mono"))
    t.eq(bare.NS.Const.FONT_MONO, bare.env.STANDARD_TEXT_FONT,
        "a degraded console must get a real client font, never a dead path")
end)
