-- tests/test_doc_structure.lua — the shapes documentation-§1 and §3 fix in place for the README
-- and the architecture hub.
--
-- WHAT IT PROVES, in six cases:
--   1. docs/ARCHITECTURE.md carries the TEN sections `documentation-§3` names for the hub.
--   2. Every mandated section that has a canonical topic doc stays inside the spill threshold.
--   3. Every markdown link pointing INTO one of the hub's headings lands on a heading that exists.
--   4. README.md carries the two player-facing history surfaces `documentation-§1` allows, and the
--      tracked markdown carries no third.
--   5. README.md's top-level sections are the ones §1 names, in the order it names them.
--   6. README.md's `## Reporting a bug` is §1 item 9's fixed text, with the real slash and no link.
--
-- WHY IT EXISTS. `documentation-§3` states the hub rule as two thresholds "because 'keep it short'
-- demonstrably did not hold": a mandated section past roughly 60 lines MUST spill into its canonical
-- topic doc leaving a summary and a link, and the whole file SHOULD stay under roughly 400. The
-- failure it describes is a 1071-line hub in which "a reader looking for the settings schema has no
-- landmark, and an agent editing it rewrites sections it never needed to open". Nothing measured it,
-- so nothing stopped it, and a hub does not grow past a screen in one commit — it grows a paragraph
-- at a time, each one defensible.
--
-- WHY THE THRESHOLD CASE EXEMPTS TWO SECTIONS. `## Documentation map` and `## Documented deviations`
-- are REGISTERS: §3 makes the hub their single home, so their storage IS the hub and they have no
-- canonical topic doc to spill into. Holding them to the spill threshold would be asking them to
-- move somewhere the same section forbids. Every other mandated section has a named home —
-- Overview → scope.md, Module Map → module-map.md, Settings Schema → schema.md, Message Bus →
-- message-bus.md, Slash Commands → slash-dispatch.md, Taint Notes → midnight-quirks.md, Known
-- Limitations → scope.md, Event Subscriptions → module-map.md — and is held.
--
-- WHAT IT DOES NOT DO, DELIBERATELY. It does not assert the 400-line whole-file SHOULD: the two
-- registers are legitimately large here and the section says an audit "reports the shape, not the
-- arithmetic". It does not check heading ORDER inside ARCHITECTURE.md, does not check that
-- `## Version History`'s top row names the TOC's version (that is `wow-addon:bump-version`'s, and
-- pinning it here would redden the tree between that command's own two edits), and does not count links per section
-- — "exactly one link" is the spill's shape, but a compliant section may also cite a second doc, as
-- §3's own Module Map example does.
--
-- IT FAILS RATHER THAN PASSES WHEN IT CANNOT LOOK. No `io.popen`, no git, no ARCHITECTURE.md and no
-- README.md are each a failure, not a skip — the same bargain tests/_kit/test_eol.lua strikes.

local T = _G.PC_TEST
local test, fail, assertTrue = T.test, T.fail, T.assertTrue
local ROOT = T.root or "."

local ARCHITECTURE = "docs/ARCHITECTURE.md"
local README       = "README.md"

-- `documentation-§3`'s ten mandated hub sections, named rather than counted because a bare count
-- goes stale silently. Matched case-insensitively: the collection is split between `## Module map`
-- and `## Module Map`, and the section names a section, not a capitalization.
local MANDATED = {
    "Overview", "Module Map", "Settings Schema", "Message Bus", "Slash Commands",
    "Event Subscriptions", "Taint Notes", "Known Limitations",
    "Documentation map", "Documented deviations",
}

-- The two of those ten whose storage IS the hub, and which therefore have nowhere to spill to.
local REGISTERS = { ["documentation map"] = true, ["documented deviations"] = true }

-- §3's spill threshold, stated there as "roughly 60 lines". Held as a hard number here because a
-- gate cannot assert "roughly"; the slack is that the rule's own failure case is 189 lines, not 61.
local SPILL_LINES = 60

-- The history surfaces `documentation-§1` does NOT allow, as case-insensitive headings. A fourth
-- spelling someone invents is caught by none of these, which is why the two ALLOWED forms are
-- asserted positively below rather than this list being the whole gate.
local FORBIDDEN_HISTORY = {
    "unreleased", "changelog", "change log", "release notes", "upcoming",
    "next release", "recent changes", "in development",
}

-- `documentation-§1`'s README section list, in its order. Item 4 (Description) and the badge row are
-- not headings, so the sequence starts at item 5. `## How <it> works` is domain-titled by the
-- section's own instruction, which is why it is a pattern and not a name. `required = false` marks
-- the SHOULD and MAY sections — omit one only when it would be empty, but when present the relative
-- order MUST hold.
local README_ORDER = {
    { pattern = "^Screenshots$",                required = false, name = "## Screenshots" },
    { pattern = "^Usage$",                      required = true,  name = "## Usage" },
    { pattern = "^How .+ works?$",              required = true,  name = "## How <it> works" },
    { pattern = "^FAQ$",                        required = false, name = "## FAQ" },
    { pattern = "^Troubleshooting$",            required = false, name = "## Troubleshooting" },
    { pattern = "^Reporting a bug$",            required = true,  name = "## Reporting a bug" },
    { pattern = "^Issues and feature requests$",required = true,  name = "## Issues and feature requests" },
    { pattern = "^Version History$",            required = true,  name = "## Version History" },
    { pattern = "^Credits$",                    required = false, name = "## Credits" },
}

--- A file's contents with line endings normalized, or a failure.
local function read(rel)
    local fh = io.open(ROOT .. "/" .. rel, "r")
    if not fh then fail("doc gate: " .. rel .. " could not be opened", 2) end
    local body = fh:read("*a") or ""
    fh:close()
    return (body:gsub("\r\n", "\n"))
end

--- A file's lines, in order.
local function lines(rel)
    local out = {}
    for line in (read(rel) .. "\n"):gmatch("([^\n]*)\n") do out[#out + 1] = line end
    return out
end

--- Every heading in a file, as { level, text }, in document order.
local function headings(rel)
    local out = {}
    for _, line in ipairs(lines(rel)) do
        local hashes, text = line:match("^(#+)%s+(.-)%s*$")
        if hashes then out[#out + 1] = { level = #hashes, text = text } end
    end
    return out
end

--- `## <Name>` as a case-insensitive whole-line pattern.
local function heading(name)
    return "^##%s+" .. name:gsub("%a", function(c)
        return "[" .. c:upper() .. c:lower() .. "]"
    end):gsub(" ", "%%s+") .. "%s*$"
end

--- GitHub's heading-fragment slug: lowercased, formatting and punctuation dropped, spaces hyphened.
local function slug(text)
    local s = text:lower():gsub("`", "")
    s = s:gsub("[^%w%s%-]", "")
    s = s:gsub("%s+", "-")
    return s
end

--- Every markdown path git tracks, minus the vendored and frozen trees.
---
--- `git ls-files` rather than a directory walk: Lua 5.1 has no directory API, and the tracked set is
--- the right set anyway. `libs/` and `tests/_kit/` are vendored whole and byte-pinned by
--- tests/test_vendor_sync.lua; the dated bundles under `docs/audits/`, `docs/reviews/`,
--- `docs/automated-tests/`, `docs/revendor/`, `docs/perf-analysis/` and `docs/superpowers/` are
--- frozen records of the tree as it stood on their stamp, so a heading this repository no longer
--- carries is history inside one of them rather than a defect.
local function trackedMarkdown()
    if not io.popen then
        fail("doc gate: io.popen is unavailable, so this gate cannot run and must not be reported "
            .. "as passing", 2)
    end
    local p = io.popen("git ls-files '*.md' 2>/dev/null")
    if not p then
        fail("doc gate: io.popen returned no handle, so this gate cannot run and must not be "
            .. "reported as passing", 2)
    end
    local out = {}
    for path in p:lines() do
        local frozen = path:match("^libs/") or path:match("^tests/_kit/")
            or path:match("^docs/audits/") or path:match("^docs/reviews/")
            or path:match("^docs/automated%-tests/") or path:match("^docs/revendor/")
            or path:match("^docs/perf%-analysis/") or path:match("^docs/superpowers/")
        if not frozen then out[#out + 1] = path end
    end
    p:close()
    if #out == 0 then
        fail("doc gate: git tracks no markdown outside the vendored and frozen trees, which cannot "
            .. "be true here — treating a blind gate as a failure", 2)
    end
    return out
end

test("docs/ARCHITECTURE.md carries the ten sections documentation-§3 names", function()
    local body, missing = read(ARCHITECTURE), {}
    for _, name in ipairs(MANDATED) do
        local pattern, found = heading(name), false
        for line in (body .. "\n"):gmatch("([^\n]*)\n") do
            if line:match(pattern) then found = true break end
        end
        if not found then missing[#missing + 1] = "## " .. name end
    end
    assertTrue(#missing == 0, ARCHITECTURE .. " is missing " .. table.concat(missing, ", ")
        .. " — §3 names all ten rather than counting them, because a count goes stale in silence")
end)

test("every mandated hub section that has a topic doc has spilled into it", function()
    local all, over = lines(ARCHITECTURE), {}
    local current, start
    local function close(at)
        if current and not REGISTERS[current:lower()] then
            local span = at - start
            if span > SPILL_LINES then
                over[#over + 1] = string.format("## %s (%d lines)", current, span)
            end
        end
    end
    for i, line in ipairs(all) do
        local text = line:match("^##%s+(.-)%s*$")
        if text and not line:match("^###") then
            close(i)
            current, start = nil, nil
            for _, name in ipairs(MANDATED) do
                if line:match(heading(name)) then current, start = text, i break end
            end
        end
    end
    close(#all + 1)
    assertTrue(#over == 0, "hub sections past the " .. SPILL_LINES .. "-line spill threshold: "
        .. table.concat(over, ", ") .. ". §3: a mandated section that exceeds roughly 60 lines MUST "
        .. "spill into its canonical topic doc, leaving a summary and a link. The two registers "
        .. "(Documentation map, Documented deviations) are exempt — the hub is their single home")
end)

test("every anchor pointing into docs/ARCHITECTURE.md resolves to a heading", function()
    local slugs = {}
    for _, h in ipairs(headings(ARCHITECTURE)) do slugs[slug(h.text)] = true end
    local dead = {}
    for _, path in ipairs(trackedMarkdown()) do
        local body = read(path)
        for frag in body:gmatch("%]%([^%)%s]-ARCHITECTURE%.md#([^%)%s]+)%)") do
            if not slugs[frag] then dead[#dead + 1] = path .. " -> #" .. frag end
        end
        if path == ARCHITECTURE then
            for frag in body:gmatch("%]%(#([^%)%s]+)%)") do
                if not slugs[frag] then dead[#dead + 1] = path .. " -> #" .. frag end
            end
        end
    end
    assertTrue(#dead == 0, "anchors into " .. ARCHITECTURE .. " that land on no heading: "
        .. table.concat(dead, ", "))
end)

test("the player-facing history has the ONE home documentation-§1 allows, and no second", function()
    local versionHistory = 0
    for _, h in ipairs(headings(README)) do
        if h.level == 2 then
            if h.text:lower() == "version history" then versionHistory = versionHistory + 1 end
        end
    end
    assertTrue(versionHistory == 1, README .. " must carry exactly one `## Version History`; found "
        .. versionHistory)

    -- And nowhere in the tracked markdown — §3's "docs/ is not where a forbidden root doc goes to
    -- live" is the same rule one directory down.
    local extra = {}
    for _, path in ipairs(trackedMarkdown()) do
        for _, h in ipairs(headings(path)) do
            local text = h.text:lower():gsub("[^%a%s]", ""):gsub("^%s+", ""):gsub("%s+$", "")
            for _, word in ipairs(FORBIDDEN_HISTORY) do
                if text == word then extra[#extra + 1] = path .. " -> ## " .. h.text end
            end
        end
        if path:match("CHANGELOG%.md$") then extra[#extra + 1] = path end
    end
    assertTrue(#extra == 0, "a third player-facing history surface, which documentation-§1 gives "
        .. "exactly two homes: " .. table.concat(extra, ", "))
end)

test("README.md's top-level sections are the ones documentation-§1 names, in its order", function()
    local cursor, out, seen = 1, {}, {}
    for _, h in ipairs(headings(README)) do
        if h.level == 2 then
            local at
            for i = cursor, #README_ORDER do
                if h.text:match(README_ORDER[i].pattern) then at = i break end
            end
            if at then
                cursor, seen[at] = at, true
            else
                out[#out + 1] = "## " .. h.text
            end
        end
    end
    assertTrue(#out == 0, README .. " carries a top-level section §1 does not name, or names in a "
        .. "different position: " .. table.concat(out, ", ") .. ". Detail that wants a home of its "
        .. "own folds into the listed section it belongs to, or moves under docs/")

    local absent = {}
    for i, entry in ipairs(README_ORDER) do
        if entry.required and not seen[i] then absent[#absent + 1] = entry.name end
    end
    assertTrue(#absent == 0, README .. " is missing " .. table.concat(absent, ", "))
end)

-- documentation-§1 item 9 (debug-logging-§14): the body is fixed text, verbatim apart from the real
-- slash, and names no destination. The owner ruled it carries no GitHub or issues link, because the
-- report goes to the maintainer privately. Falsified by dropping step 2, by changing "include it with
-- your bug report" back to an issue destination, or by adding a github.com link: each fails here.
local REPORTING_A_BUG = {
    "1. Type `/pc debug on` and reproduce the bug.",
    "2. Type `/pc diagnostics`.",
    "3. If the debug window isn't open, open it with `/pc debug`. Press **Copy**, copy the entire "
        .. "output, and include it with your bug report.",
    "The report is added after the debug trace in the same window, so one copy carries both.",
}

test("README.md's Reporting a bug section is documentation-§1 item 9 verbatim, with no link", function()
    local body, inside, got = read(README), false, {}
    for line in (body .. "\n"):gmatch("([^\n]*)\n") do
        if line:match("^## ") then inside = (line == "## Reporting a bug") end
        if inside and line ~= "" and not line:match("^## ") then got[#got + 1] = line end
    end
    assertTrue(#got == #REPORTING_A_BUG, README .. "'s ## Reporting a bug has " .. #got
        .. " non-blank line(s), item 9 fixes " .. #REPORTING_A_BUG)
    for i, want in ipairs(REPORTING_A_BUG) do
        assertTrue(got[i] == want, README .. "'s ## Reporting a bug line " .. i .. " reads `"
            .. tostring(got[i]) .. "`, item 9 fixes `" .. want .. "`")
    end
    for _, line in ipairs(got) do
        assertTrue(not line:lower():match("github") and not line:match("%]%("),
            README .. "'s ## Reporting a bug carries a link or a destination: " .. line)
    end
end)

test("root CLAUDE.md carries the adherence line documentation-§2 puts second", function()
    local body, adherence, section = read("CLAUDE.md"), nil, nil
    local n = 0
    for line in (body .. "\n"):gmatch("([^\n]*)\n") do
        n = n + 1
        if not adherence and line:match("Ka0s WoW Addon Standard")
            and line:match("^[^#]") then adherence = n end
        if not section and line:match("^##%s+Standards compliance") then section = n end
    end
    assertTrue(adherence ~= nil, "CLAUDE.md states no adherence to the Ka0s WoW Addon Standard")
    assertTrue(section ~= nil, "CLAUDE.md has no `## Standards compliance (read first)` heading")
    assertTrue(adherence < section, "CLAUDE.md's adherence statement first appears at line "
        .. tostring(adherence) .. ", inside or after `## Standards compliance` at line "
        .. tostring(section) .. ". §2 orders the stub H1, adherence line, then that section — the "
        .. "line is what a reader who never scrolls past the title still sees")
end)

test("the README's settings table is page-granular, not per-tab", function()
    local rows = {}
    for _, line in ipairs(lines(README)) do
        local first = line:match("^|%s*%*?%*?([%w ]-)%*?%*?%s*|")
        if first and first:lower():gsub("%s+", "") == "tab" then rows[#rows + 1] = line end
    end
    assertTrue(#rows == 0, README .. " carries a `| Tab |` table: " .. table.concat(rows, " / ")
        .. ". documentation-§1 keeps NO settings table in the README — `## Usage` is prose — and "
        .. "puts both the page summary and the per-tab breakdown in "
        .. "docs/settings-panel.md, which is where options-ui-§13's strip makes it derivable")
end)

-- ── The smoke suite's non-English-client section ───────────────────────────────

-- WHAT IT PROVES, AND WHAT IT DOES NOT. That docs/smoke-tests.md still carries a section addressed
-- to a non-English client, that the section names the locale to run it on, and that it says what a
-- failure looks like rather than only what a pass does. It proves nothing whatever about that
-- section having been RUN -- a checklist is a checklist, and this repository has no client.
--
-- WHY THIS REPOSITORY IN PARTICULAR. This addon's entire function is overwriting localized _G chat
-- format strings, and for 797 lines its smoke document had no locale step at all. Its own header
-- already named "positional %n$s formats" as something stock Lua cannot exercise, and nothing
-- followed that sentence anywhere. tests/test_defaults.lua checks every override against Blizzard's
-- real signature -- out of GlobalStrings/, which is an enUS dump. So the arity a German client
-- passes is checked against the arity an English one does, and the suite is green either way.
--
-- The failure vocabulary is matched loosely on purpose: this file says "Failure mode" in some tests
-- and "Expected" in others, and pinning one spelling would redden the tree for a rewording.
local LOCALE_HEADING = "[Nn]on%-English client"
local FAILURE_WORDS = { "Failure", "failure", "Fail", "the finding" }

test("docs/smoke-tests.md carries a non-English-client section", function()
    local body = read("docs/smoke-tests.md")

    local capture, level, section = false, nil, {}
    for line in (body .. "\n"):gmatch("([^\n]*)\n") do
        local hashes = line:match("^(#+)%s")
        if hashes and capture and #hashes <= level then break end
        if hashes and not capture and line:match(LOCALE_HEADING) then
            capture, level = true, #hashes
        end
        if capture then section[#section + 1] = line end
    end
    assertTrue(capture, "docs/smoke-tests.md has no heading naming a non-English client. The step "
        .. "is unconditional (M5-08): where an addon reads nothing localized the section still "
        .. "ships and says what it checked and why it came back empty")

    local text = table.concat(section, "\n")
    assertTrue(text:find("deDE", 1, true) or text:find("frFR", 1, true),
        "the non-English-client section names no client to run it on -- deDE and frFR are the two "
        .. "the collection's other locale steps use")

    local named = false
    for _, word in ipairs(FAILURE_WORDS) do
        if text:find(word, 1, true) then named = true break end
    end
    assertTrue(named, "the non-English-client section says what passing looks like and never what "
        .. "failing looks like. A step whose only outcome is 'it works' is unfalsifiable in a "
        .. "client the operator booted specially")

    assertTrue(#section >= 10, "the non-English-client section is " .. #section .. " lines -- a "
        .. "heading with a sentence under it records the gap as coverage, which is the failure "
        .. "M5-08 was filed for")
end)

-- ── Authored source: the self-naming header and the idempotent publish ─────────────────────────

-- WHAT IT PROVES. Two source-shape rules, read off every authored file the TOC loads (libs/ are the
-- kit loader's to drop, and GlobalStrings/ is loaded by nothing). documentation-§9: directly under
-- the `local ..., NS = ...` bootstrap, the first comment names the file's own path and one-line
-- purpose, `-- <path> — <purpose>`, so a reader who lands in the file from a grep knows where they
-- are. architecture-§3: a module publishes onto NS with `NS.<X> = NS.<X> or {}`, never with a bare
-- constructor that would replace a table something earlier seeded (PRETTYCHAT-A-20, A-25).
--
-- WHAT IT DOES NOT DO. It does not judge the purpose text, and it does not catch a data table
-- published as a filled literal (`NS.Defaults = { Loot = ... }`) -- that is a declaration, not a
-- module table, and nothing seeds it earlier.
local Loader = dofile("tests/_kit/loader.lua")

local function authoredSources()
    return Loader.tocFiles(ROOT .. "/PrettyChat.toc")
end

test("every TOC-loaded authored file names its own path in its first comment", function()
    local files, bad = authoredSources(), {}
    assertTrue(#files > 0, "PrettyChat.toc lists no authored .lua file")
    for _, rel in ipairs(files) do
        local seenVararg, first = false, nil
        for _, line in ipairs(lines(rel)) do
            if not seenVararg then
                seenVararg = line:match("^local [%w_, ]+= %.%.%.%s*$") ~= nil
            elseif line:match("^%-%-") then
                first = line
                break
            end
        end
        local want = "-- " .. rel .. " — "
        if not (first and first:sub(1, #want) == want) then
            bad[#bad + 1] = rel .. " (first comment: " .. tostring(first) .. ")"
        end
    end
    assertTrue(#bad == 0, "documentation-§9 wants `-- <path> — <purpose>` as the first comment "
        .. "under the vararg line; these do not lead with their own path: " .. table.concat(bad, "; "))
end)

test("no module publishes NS.<X> with a bare table constructor", function()
    local bad = {}
    for _, rel in ipairs(authoredSources()) do
        local bareLocals = {}
        for n, line in ipairs(lines(rel)) do
            local ns = line:match("^NS%.(%u[%w_]*)%s*=%s*{}%s*$")
            if ns then bad[#bad + 1] = ("%s:%d NS.%s = {}"):format(rel, n, ns) end
            local loc = line:match("^local ([%a_][%w_]*)%s*=%s*{}%s*$")
            if loc then bareLocals[loc] = n end
            local key, rhs = line:match("^NS%.(%u[%w_]*)%s*=%s*([%a_][%w_]*)%s*$")
            if key and bareLocals[rhs] then
                bad[#bad + 1] = ("%s:%d local %s = {} published as NS.%s at line %d")
                    :format(rel, bareLocals[rhs], rhs, key, n)
            end
        end
    end
    assertTrue(#bad == 0, "architecture-§3 publishes a module as `NS.<X> = NS.<X> or {}`; a bare "
        .. "constructor replaces whatever an earlier file seeded: " .. table.concat(bad, "; "))
end)

-- ── The hub's load-order line against the TOC ──────────────────────────────────────────────────

-- WHAT IT PROVES. docs/ARCHITECTURE.md's Module Map carries ONE load-order line, the `a → b → c`
-- chain inside backticks, and that chain names every authored file PrettyChat.toc loads (libs/
-- excluded), in TOC order, with `.lua` dropped. The TOC is the source of truth and the line is its
-- prose copy; a file added to the TOC without the line following -- core/LifecycleSetup did exactly
-- that (PRETTYCHAT-A-03) -- leaves the hub describing a load order the client never runs.
--
-- WHAT IT DOES NOT DO. It does not read docs/module-map.md's numbered list, whose entries carry
-- prose per step, and it does not check the libraries' order, which the line summarizes in words.
test("ARCHITECTURE's load-order line names every TOC-loaded authored file in TOC order", function()
    local want = {}
    for _, rel in ipairs(authoredSources()) do want[#want + 1] = (rel:gsub("%.lua$", "")) end

    local chain
    for _, line in ipairs(lines(ARCHITECTURE)) do
        if line:find("Load order is `PrettyChat.toc`", 1, true) then
            for span in line:gmatch("`([^`]+)`") do
                if span:find("→", 1, true) then chain = span end
            end
        end
    end
    assertTrue(chain ~= nil, "docs/ARCHITECTURE.md has no `Load order is `PrettyChat.toc`` line "
        .. "carrying a backticked `a → b` chain -- the gate cannot look, so it fails")

    local got = {}
    for step in (chain .. " → "):gmatch("(.-)%s*→%s*") do
        got[#got + 1] = step:match("^%s*(.-)%s*$")
    end
    assertTrue(table.concat(got, " → ") == table.concat(want, " → "),
        "docs/ARCHITECTURE.md's load-order line does not match PrettyChat.toc.\n  TOC:  "
        .. table.concat(want, " → ") .. "\n  line: " .. table.concat(got, " → "))
end)
