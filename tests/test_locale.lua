-- tests/test_locale.lua — locales/enUS.lua. `NS.L` is an identity table with an
-- English-key fallback, so a missing translation can never blank a string; the
-- seeded manifest is the authoritative list of the addon's translatable surface
-- (localization-§1). The drift cases below scan the real sources for `L["…"]`
-- call sites and check them against that manifest in both directions, so a
-- manifest entry left behind by a deleted call site, or a call site the
-- manifest never learned about, surfaces here instead of at a translator's desk.
--
-- Those cases cannot see a string that was never wrapped, and for four audits
-- this header claimed otherwise. The literal scan at the foot of the file is
-- the half that can: same TOC-derived source list, but it reports the prose
-- literals that are NOT subscripts of `L`, and every one of them has to be
-- recorded with a reason before it will go green (M4-21).

local function readFile(path)
    local fh = io.open(path, "r")
    if not fh then return nil end
    local body = fh:read("*a")
    fh:close()
    return body
end

local ctx = _G.PC_TEST
local t    = ctx.t
local test = ctx.test
local inst = ctx.loadAddon()
local NS   = inst.NS
local L    = NS.L

-- Sources that may reference L, DERIVED from the TOC rather than hand-listed. A
-- hand-maintained list goes stale silently in the direction that matters: a file
-- renamed or added is simply never scanned, and the drift cases below then report
-- green over a surface they never looked at. locales/ itself is excluded — its
-- `L[s] = s` loop is the seeding, not a call site. The `^GlobalStrings/` filter
-- is a guard rather than a live exclusion: the TOC stopped loading the generated
-- dump at PC-R-05, and if a runtime consumer ever brings it back it still
-- carries no user-facing prose and must not be scanned.
local L_CONSUMERS = {}
for _, rel in ipairs(ctx.loadAddon.tocFiles) do
    if not rel:find("^locales/") and not rel:find("^GlobalStrings/") then
        L_CONSUMERS[#L_CONSUMERS + 1] = rel
    end
end

-- Every `L["…"]` literal in the addon's own sources, mapped to the file
-- it was found in.
local callSites = {}
for _, rel in ipairs(L_CONSUMERS) do
    -- Hard assert rather than a tolerant skip: a source the scan cannot open is a
    -- surface it did not look at, and a drift check that goes quiet when it cannot
    -- look is worse than no check. (test_harness.lua pins existence separately.)
    local body = assert(readFile(ctx.root .. "/" .. rel), rel .. " is unreadable")
    for key in body:gmatch('L%[%s*"(.-)"%s*%]') do
        callSites[key] = callSites[key] or rel
    end
end

test("NS.L is published as a table", function()
    t.truthy(L, "NS.L exists")
    t.eq(type(L), "table", "NS.L is a table")
end)

test("an unknown key falls back to itself verbatim", function()
    -- The fallback is what guarantees an unwrapped string still renders.
    t.eq(L["a string nobody translated"], "a string nobody translated",
        "unknown key returns the key")
    t.eq(L["%d items"], "%d items", "the fallback preserves format conversions")
end)

test("every seeded manifest entry is an identity mapping", function()
    local n = 0
    for k, v in pairs(L) do
        n = n + 1
        t.eq(v, k, ("manifest entry %q maps to itself"):format(k))
    end
    t.truthy(n > 0, "the manifest seeded entries")
end)

test("the scan found the L call sites it is meant to guard", function()
    -- A guard on the guard: if the scan silently matched nothing, the two
    -- drift cases below would pass vacuously.
    local n = 0
    for _ in pairs(callSites) do n = n + 1 end
    t.truthy(n > 20, "the source scan found the localized string surface")
end)

test("every localized call site is in the enUS manifest", function()
    for key, file in pairs(callSites) do
        t.truthy(rawget(L, key) ~= nil,
            ("%s: L[%q] is missing from the enUS manifest"):format(file, key))
    end
end)

test("the manifest carries no entry that nothing references", function()
    for key in pairs(L) do
        t.truthy(callSites[key] ~= nil,
            ("manifest entry %q is still referenced by a call site"):format(key))
    end
end)

test("every slash-command description is localized", function()
    -- The COMMANDS table is the single source for /pc help AND the parent
    -- panel's command list, so its descriptions must be translatable.
    for _, entry in ipairs(NS.COMMANDS) do
        t.truthy(rawget(L, entry[2]) ~= nil,
            ("description for /pc %s is in the manifest"):format(entry[1]))
    end
end)

-- ---------------------------------------------------------------------
-- The other direction: literals that never reached `L` at all.
--
-- Everything above scans for `L["…"]`, which can only ever find strings that
-- are ALREADY wrapped — a coverage case that measures its own subject is
-- `testing-§12`'s failure mode, and it is why `settings/Slash.lua`'s usage
-- lines sat in English through four audits without one case going red.
--
-- What follows scans the SAME TOC-derived source list for string literals that
-- read as prose and are NOT wrapped, and requires each one to be recorded below
-- with a reason. A new bare sentence in a settings file is therefore red on the
-- next run, which is the whole point of the pass.
-- ---------------------------------------------------------------------

-- `defaults/Defaults.lua` is the addon's DATA table — 81 rows of Blizzard global
-- name, English display label and replacement format string — and the format
-- strings are content the player edits, not prose the addon speaks. Scanning it
-- would report every colour-escaped default as an unrouted sentence. It is
-- excluded by name and with a reason rather than by a silent omission, and the
-- shape case below pins that its literals really are only those two fields, so
-- the exclusion cannot quietly widen into a place a sentence could hide.
local DATA_SOURCES = {
    ["defaults/Defaults.lua"] = "the row/label/default data table (see the shape case below)",
}

-- Lua's own lexer, reduced to the one question asked here: where does each
-- string literal start, and what is immediately in front of it. A `gmatch` for
-- `"…"` cannot be used instead, because this repository's comments are prose and
-- quote strings freely — `body:gmatch('"(.-)"')` reports a paragraph about a
-- string as a string. Long-bracket literals are not handled because the addon
-- has none; if one ever appears it is simply not scanned, which the residue
-- register would not hide, so the failure direction is a missed report and never
-- a false one.
local function scanLiterals(src)
    local out, i, n, line, lineStart = {}, 1, #src, 1, 1
    while i <= n do
        local c = src:sub(i, i)
        if c == "\n" then
            line, i = line + 1, i + 1
            lineStart = i
        elseif c == "-" and src:sub(i + 1, i + 1) == "-" then
            -- To end of line. `--[[` block comments are absent from this addon
            -- and would be swallowed to the newline, which again only loses a
            -- report rather than inventing one.
            i = src:find("\n", i, true) or (n + 1)
        elseif c == '"' or c == "'" then
            local q, j = c, i + 1
            while j <= n do
                local d = src:sub(j, j)
                if d == "\\" then j = j + 2
                elseif d == q or d == "\n" then break
                else j = j + 1 end
            end
            out[#out + 1] = {
                text = src:sub(i + 1, j - 1),
                line = line,
                -- Wrapped means the literal IS the subscript: `L["…"]`, which is
                -- how every routed string in this addon is written.
                wrapped = src:sub(math.max(1, i - 8), i - 1):match("L%s*%[%s*$") ~= nil,
                -- `NS.Debug(tag, fmt, …)` is the debug console's sink, not chat:
                -- its format strings are developer diagnostics that the standard's debug-logging section
                -- governs and no translator should ever see. Every such call in
                -- this addon opens on the line its format string sits on, which
                -- is what makes the same-line test sufficient.
                debugArg = src:sub(lineStart, i - 1):find("NS.Debug(", 1, true) ~= nil,
                statement = src:sub(lineStart, i - 1),
            }
            i = j + 1
        else
            i = i + 1
        end
    end
    return out
end

-- Prose, as distinct from an identifier, a pattern, an event name or a path: at
-- least one three-letter run, and two alphabetic words with a space between
-- them. A leading `/` exempts a slash-command SYNTAX literal (`/pc test category
-- <name>`) — the player types those verbatim in every language.
--
-- The floor is honest about what it cannot see: a single-word label ("Reset",
-- "Category: ") reads the same as a table key or an event token to any
-- mechanical test, so this gate does not claim to catch one. The remaining
-- one-word labels are named in docs/ARCHITECTURE.md's `localization-§1` row,
-- which is where that half of the surface is recorded.
local function isProse(s)
    if s:match("^%s*/") then return false end
    return s:find("%a%a%a") ~= nil and s:find("%a+%s+%a+") ~= nil
end

-- Known residue: user-facing text this addon does NOT route, each entry with the
-- reason it is not routed. This is a register, not a mute button — the second
-- case below fails when an entry stops matching the tree, so a line that gets
-- wrapped, reworded or deleted takes its entry with it.
--
-- Two reasons recur, and both come out of PC-R-06, which removed the concatenated
-- fragments that had pinned English word order and left a translator nothing to
-- reorder:
--   * SPLIT COLOUR — the sentence's parts carry different mandated colours
--     (slash-commands-§4/§5), so one key would have to carry `|c…|r` escapes
--     inside translatable text, and keying the halves separately re-creates
--     exactly the fragments PC-R-06 removed.
--   * SHARED STEM — core/CoreSetup.lua:29-34 makes the degraded-install sentence
--     one stem plus a per-site tail, so a degraded install says the same thing
--     about WHY at four sites. Four whole-sentence keys would be four copies of
--     the stem and would end that.
local RESIDUE = {
    -- Not prose the addon speaks.
    {"core/Constants.lua", "JetBrains Mono",
     "a font FACE name — an identifier LibSharedMedia and the console descriptor match on"},
    {"settings/OptionsSetup.lua", "Ka0s Pretty Chat",
     "the addon's brand name, and a LibKa0s descriptor field besides (see below)"},
    {"core/DebugLogSetup.lua", "Pretty Chat",
     "the same brand name, handed to LibKa0s-DebugLog-1.0 as its window title"},
    {"core/DebugLogSetup.lua", "Debug console",
     "a descriptor field crossing to LibKa0s. NS.L must never be handed to a library "
     .. "descriptor as its `L` (LIBKA0S-05, 'The L trap'); a translator restores these "
     .. "by passing a PLAIN table of just these keys, which locales/enUS.lua records"},

    -- Developer diagnostics that happen to print to chat.
    {"core/Database.lua", "schema migration ",
     "names a migration step number and a Lua error; actionable only by a developer "
     .. "reading a bug report"},
    {"settings/Schema.lua", "schema: unresolved path (no backing default): ",
     "the same: it names a schema path, and reaching it at all is a defect"},
    {"core/DebugLogSetup.lua", "%s v%s, schema v%s, profile '%s'",
     "the debug console's session header, which is copied INTO bug reports and is "
     .. "read by whoever receives them"},
    {"core/Util.lua", " (stopped by an error)",
     "debug-console text like every NS.Debug argument, held in one constant so the "
     .. "four bulk-act lines that append it agree; the console translates nothing"},

    -- SHARED STEM — the degraded-install sentence.
    {"core/CoreSetup.lua", "The LibKa0s library is missing from this installation of Ka0s Pretty Chat ",
     "SHARED STEM: the one sentence four seams append their own tail to"},
    {"core/CoreSetup.lua", "(expected in libs/LibKa0s)",
     "SHARED STEM: the stem's second half, naming the path a user has to go and look at"},
    {"core/CoreSetup.lua", "; running on reduced built-in fallbacks.", "SHARED STEM: CoreSetup's tail"},
    {"core/DebugLogSetup.lua", ", so the debug console window is unavailable.",
     "SHARED STEM: the console's tail"},
    {"settings/OptionsSetup.lua", ", so the settings panel is unavailable.",
     "SHARED STEM: the panel's tail"},
    {"settings/Slash.lua", ", so the settings CLI is unavailable.", "SHARED STEM: the CLI's tail"},

    -- SPLIT COLOUR — the degraded `/pc debug on|off` acknowledgement.
    {"core/DebugLogSetup.lua", "debug logging ",
     "SPLIT COLOUR: the state word is green ON or red OFF, concatenated at the call site; "
     .. "one key would have to carry the escapes and an English on/off pair"},

    -- SPLIT COLOUR — settings/Slash.lua's `/pc reset <category>` migration notice.
    {"settings/Slash.lua", "` now takes a setting PATH, not a category.", "SPLIT COLOUR"},
    {"settings/Slash.lua", "  To reset one setting: ", "SPLIT COLOUR"},
    {"settings/Slash.lua", "  To reset all of ", "SPLIT COLOUR"},
    {"settings/Slash.lua", " button on its settings page, or ", "SPLIT COLOUR"},
    {"settings/Slash.lua", " for everything.", "SPLIT COLOUR"},

    -- SPLIT COLOUR — the four `usage:` lines. Below the prose floor above (none of
    -- them holds two adjacent words), so the scan does not report them; they are
    -- recorded anyway because they are the sites the M4-21 plan row names, and
    -- because a register that only lists what a heuristic happens to catch is a
    -- register of the heuristic rather than of the addon.
    {"settings/Slash.lua", "usage: ",
     "SPLIT COLOUR: uncoloured word, then a gold command syntax the player types verbatim"},
    {"settings/Slash.lua", ". Valid: ", "SPLIT COLOUR: white clause between a gold command and a plain list"},
    {"settings/Slash.lua", " — try ", "SPLIT COLOUR: white clause between two gold commands"},

    -- The `/pc test` report's footer.
    {"modules/Override.lua", "end of test output (%d %s shown",
     "pluralised by concatenating 'string'/'strings' at the call site, which no key "
     .. "can express; wrapping the half-sentence would key an English plural rule"},
    {"modules/Override.lua", ", %d errored", "the same footer's optional clause"},
    {"modules/Override.lua", "(empty format)",
     "the reason half of the gray `(error: %s)` line, whose wrapper is itself unrouted; "
     .. "keying one half of a two-part diagnostic is the fragment-keying PC-R-06 removed"},
}

-- Every unwrapped prose literal in the sources, keyed file -> text -> line.
local unrouted, unroutedCount, scannedLiterals = {}, 0, 0
for _, rel in ipairs(L_CONSUMERS) do
    if not DATA_SOURCES[rel] then
        local body = assert(readFile(ctx.root .. "/" .. rel), rel .. " is unreadable")
        for _, lit in ipairs(scanLiterals(body)) do
            scannedLiterals = scannedLiterals + 1
            if not lit.wrapped and not lit.debugArg and isProse(lit.text) then
                unrouted[rel] = unrouted[rel] or {}
                if not unrouted[rel][lit.text] then
                    unrouted[rel][lit.text] = lit.line
                    unroutedCount = unroutedCount + 1
                end
            end
        end
    end
end

-- The register, in the same shape, so both directions are a lookup.
local recorded = {}
for _, entry in ipairs(RESIDUE) do
    recorded[entry[1]] = recorded[entry[1]] or {}
    recorded[entry[1]][entry[2]] = entry[3]
end

test("the literal scan sees the sources it is meant to guard", function()
    -- The guard on THIS guard. A lexer that silently matched nothing would make
    -- the routing case below pass over an addon full of bare English.
    t.truthy(scannedLiterals > 200,
        ("the scan read %d string literals across %d sources"):format(scannedLiterals, #L_CONSUMERS))
    t.truthy(unroutedCount > 0, "and it still reports the known residue rather than an empty set")
end)

test("every user-facing literal is routed through L or recorded as residue", function()
    for rel, texts in pairs(unrouted) do
        for text, line in pairs(texts) do
            t.truthy(recorded[rel] and recorded[rel][text] ~= nil,
                ("%s:%d: %q is user-facing text that neither goes through L nor is recorded "
                 .. "as residue in tests/test_locale.lua"):format(rel, line, text))
        end
    end
end)

test("every recorded residue literal is still unrouted in the file that names it", function()
    -- The direction that keeps the register from becoming a mute button: an entry
    -- whose literal was wrapped, reworded or deleted goes red here instead of
    -- sitting on as a licence for a string that no longer exists.
    for _, entry in ipairs(RESIDUE) do
        local rel, text = entry[1], entry[2]
        local body = assert(readFile(ctx.root .. "/" .. rel), rel .. " is unreadable")
        local found = false
        for _, lit in ipairs(scanLiterals(body)) do
            if lit.text == text and not lit.wrapped then found = true break end
        end
        t.truthy(found,
            ("%s no longer holds the unrouted literal %q — drop its residue entry"):format(rel, text))
    end
end)

test("the excluded data table holds only row labels and default format strings", function()
    -- DATA_SOURCES buys one file an exemption; this is the fence around it. Every
    -- prose literal in Defaults.lua must be the value of a `label` or a `default`
    -- field, so a sentence cannot be added to the one file the gate does not read.
    for rel in pairs(DATA_SOURCES) do
        local body = assert(readFile(ctx.root .. "/" .. rel), rel .. " is unreadable")
        for _, lit in ipairs(scanLiterals(body)) do
            if isProse(lit.text) and not lit.wrapped then
                t.truthy(lit.statement:match("[%s{,]label%s*=%s*$")
                      or lit.statement:match("[%s{,]default%s*=%s*$"),
                    ("%s:%d: %q is not a label or a default — the data exemption does not cover it")
                        :format(rel, lit.line, lit.text))
            end
        end
    end
end)
