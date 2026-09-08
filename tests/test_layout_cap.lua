-- tests/test_layout_cap.lua — the 1500-line cap gate (layout-§1).
--
-- WHAT IT PROVES. That no authored `.lua` file this repository tracks sits over layout-§1's
-- 1500-line cap without a disposition, that no disposition outlives the breach it was written
-- for, and — the part that is this repository's alone — that the ONE carve-out this repo leans on
-- still holds, condition by condition. It reads the tracked set from git and the census table
-- from docs/ARCHITECTURE.md and compares them in both directions.
--
-- WHY IT EXISTS. `layout-§1` used to cap "any single `.lua` file" without saying what that bound,
-- and four repositories in the collection answered the silence four different ways in the same
-- audit cycle. PrettyChat's answer was the deviation still in ARCHITECTURE.md's register, which
-- asked in as many words for "a `layout` revision that sanctions a generated-data folder". The
-- revision landed (M1-STD-08, standard v2.39.0): the cap now binds every authored file the repo
-- tracks, `tests/` included, and carves out exactly two things — vendored code, and generated
-- non-shipping data. A file over the cap has three terminal states, peeled or an open issue
-- naming the seam or a ratified register row with a re-check trigger, and what the rule refuses
-- is a fourth: silence, "the count sitting in a bundle manifest that no document reads".
--
-- WHY THIS REPO'S GATE IS NOT ITS SIBLINGS'. MultiMeters and LibKa0s wrote the same census and
-- said, in the same function, that the generated-data carve-out "has no instance here; if one
-- ever arrives it needs a rule in this function". Here it has an instance, and it is the only
-- thing standing between a 23,842-line file and a `layout-§1` MUST:
-- `GlobalStrings/GlobalStrings.lua` is exempt only while all THREE of the carve-out's conditions
-- hold — generated with a comment at the top saying so, loaded by nothing, `.pkgmeta`-ignored.
-- Each of the three is a line in a file somebody could edit for an unrelated reason: one TOC
-- line, one `.pkgmeta` entry, one banner. So the exemption is not spelt as a path in a skip list.
-- It is CHECKED, and a broken condition names itself in the failure rather than turning a MUST
-- back on silently. That is the whole reason this suite exists in a repo with zero breaches.
--
-- WHAT IT DOES NOT ASSERT: the line figures printed in the census. They are dated measurements,
-- and pinning them would redden the suite on every ordinary edit to a large file — a gate with a
-- standing reason to be switched off stops being run. Membership is the invariant; the numbers
-- are prose.
--
-- IT FAILS RATHER THAN PASSES WHEN IT CANNOT LOOK. No `io.popen`, no git, no ARCHITECTURE.md, no
-- census heading, no `.pkgmeta`, an unreadable TOC, or a second load list appearing beside the
-- TOC — every one of those is a failure, not a skip. A gate that goes quiet when it is blind
-- reports success, which is worse than not existing. Same bargain tests/_kit/test_eol.lua strikes.

local ctx  = _G.PC_TEST
local test = ctx.test
local fail = ctx.fail
local ROOT = ctx.root or "."

local CAP            = 1500
local ARCHITECTURE   = "docs/ARCHITECTURE.md"
local TOC            = "PrettyChat.toc"
local PKGMETA        = ".pkgmeta"
local CENSUS_HEADING = "### Files over the 1500-line cap"

local function readFile(rel)
    local fh = io.open(ROOT .. "/" .. rel, "r")
    if not fh then return nil end
    local body = fh:read("*a") or ""
    fh:close()
    return (body:gsub("\r\n", "\n"))
end

--- Split a NUL-delimited blob. `git ls-files -z` because a path may contain anything but NUL, and
--- the line-oriented form QUOTES such a path instead of printing it — a quoted path would not
--- match a file on disk, and this gate would then report a breach that is really a parse failure.
local function splitNul(blob)
    local out, start = {}, 1
    while true do
        local i = blob:find("\0", start, true)
        if not i then break end
        if i > start then out[#out + 1] = blob:sub(start, i - 1) end
        start = i + 1
    end
    return out
end

local function gitLsFiles(pattern)
    if not io.popen then
        fail("io.popen is unavailable, so the tracked set cannot be read")
    end
    local pipe = io.popen("git -C '" .. ROOT .. "' ls-files -z -- '" .. pattern .. "'")
    if not pipe then fail("could not start `git ls-files`") end
    local blob = pipe:read("*a") or ""
    pipe:close()
    return splitNul(blob)
end

--- Every `.lua` path git tracks, minus carve-out ONE. `libs/` and `tests/_kit/` arrive by
--- whole-folder copy from upstream and are audited in the repo that writes them, so the cap does
--- not bind a file this repo MUST NOT edit. Carve-out TWO — generated non-shipping data — is
--- deliberately NOT applied here: it is applied per row, against the three conditions, so that a
--- file which stops qualifying reappears as a breach instead of vanishing out of the denominator.
local function trackedAuthoredLua()
    local paths = {}
    for _, path in ipairs(gitLsFiles("*.lua")) do
        if not (path:find("^libs/") or path:find("^tests/_kit/")) then
            paths[#paths + 1] = path
        end
    end
    if #paths == 0 then
        fail("`git ls-files` reported no tracked .lua files, which cannot be true here")
    end
    return paths
end

--- Lines in `rel`, counted as `wc -l` counts them, plus a final unterminated line if there is one.
--- Returns nil when the file cannot be opened, which the callers report rather than skip.
local function countLines(rel)
    local body = readFile(rel)
    if not body then return nil end
    if body == "" then return 0 end
    local n = 0
    for _ in body:gmatch("\n") do n = n + 1 end
    if body:sub(-1) ~= "\n" then n = n + 1 end
    return n
end

-- ---------------------------------------------------------------------------
-- Carve-out two, condition by condition
-- ---------------------------------------------------------------------------

--- Condition ONE — generated rather than authored, and saying so.
---
--- `layout-§1` asks for "a comment at the top of the file" recording that a machine wrote it and
--- that the next regeneration overwrites any hand edit. Five lines is "the top": far enough for a
--- banner, not so far that a mention buried in prose halfway down a source file would qualify.
local function saysItIsGenerated(rel)
    local body = readFile(rel)
    if not body then return false, "the file cannot be opened at all" end
    local n = 0
    for line in (body .. "\n"):gmatch("([^\n]*)\n") do
        n = n + 1
        if n > 5 then break end
        if line:match("^%s*%-%-") and line:upper():find("GENERATED", 1, true) then
            return true
        end
    end
    return false, "no comment in its first five lines says it is generated, so a reader has " ..
                  "nothing telling them the next regeneration will overwrite their edit"
end

--- Every `.lua` PrettyChat.toc loads, as forward-slash paths.
---
--- The TOC is this repo's ONLY load list: there is no non-vendored `.xml`, and the headless
--- harness derives its own file list from this same TOC through the kit's `Loader.tocFiles`. That
--- makes one file answer for both the client and the suite — but only while it stays the only
--- one, which is why a second load list appearing is a failure below rather than something this
--- function quietly does not read.
local function tocLoadList()
    local body = readFile(TOC)
    if not body then fail(TOC .. " could not be opened; it is the load list this gate reads") end
    local loaded = {}
    for line in (body .. "\n"):gmatch("([^\n]*)\n") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed ~= "" and trimmed:sub(1, 1) ~= "#" and trimmed:lower():find("%.lua$") then
            loaded[(trimmed:gsub("\\", "/"))] = true
        end
    end
    return loaded
end

--- Condition TWO — nothing loads it.
---
--- "Absent from the TOC and from every test load list — a fixture a test READS AS DATA still
--- qualifies." That last clause is why `tests/test_defaults.lua` calling `loadfile` on the
--- generated chunks does not disqualify them: they are read to check this addon's overrides
--- against Blizzard's real signature, which is a fixture being read, not the addon loading them.
--- What the condition is about is the client and the harness booting the addon WITH the file in
--- it, and both of those read the TOC.
local function nothingLoadsIt(rel, loaded)
    if loaded[rel] then
        return false, TOC .. " loads it, so it is a shipped source file with an unusual origin " ..
                      "and the cap binds it exactly as it binds hand-written source"
    end
    return true
end

--- The `.pkgmeta` ignore list, one entry per line under `ignore:`, quotes stripped.
--- Reading stops at the next top-level key so a later list cannot leak into this one.
local function pkgmetaIgnores()
    local body = readFile(PKGMETA)
    if not body then
        fail(PKGMETA .. " could not be opened; the third condition of layout-§1's generated-data " ..
             "carve-out is read from its ignore list and cannot be assumed")
    end
    local entries, inside, found = {}, false, false
    for line in (body .. "\n"):gmatch("([^\n]*)\n") do
        if line:match("^ignore:%s*$") then
            inside, found = true, true
        elseif inside and line:match("^%S") then
            break
        elseif inside then
            local entry = line:match("^%s*%-%s*([^#]+)")
            if entry then
                entry = entry:match("^%s*(.-)%s*$"):gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
                entries[#entries + 1] = entry
            end
        end
    end
    if not found then
        fail(PKGMETA .. " carries no `ignore:` list; without one nothing in this repo is " ..
             "excluded from the player's download and the carve-out cannot apply to anything")
    end
    return entries
end

--- Condition THREE — `.pkgmeta`-ignored, so no player downloads it.
---
--- An entry matches a path when it IS the path or is a directory containing it. Globs are not
--- expanded: an entry that would only match through a glob is treated as no match, which errs
--- toward reporting a breach rather than toward excusing one.
local function notShipped(rel, ignores)
    for _, entry in ipairs(ignores) do
        if entry == rel or rel:sub(1, #entry + 1) == entry .. "/" then
            return true
        end
    end
    return false, "no " .. PKGMETA .. " ignore entry covers it, so it is in the zip every player " ..
                  "downloads and the carve-out's third condition fails"
end

--- All three, in the order `layout-§1` states them. Returns true, or false and the first reason.
local function isExemptGeneratedData(rel, loaded, ignores)
    local ok, why = saysItIsGenerated(rel)
    if not ok then return false, why end
    ok, why = nothingLoadsIt(rel, loaded)
    if not ok then return false, why end
    ok, why = notShipped(rel, ignores)
    if not ok then return false, why end
    return true
end

-- ---------------------------------------------------------------------------
-- The census
-- ---------------------------------------------------------------------------

--- The census table under CENSUS_HEADING in docs/ARCHITECTURE.md, as { path, disposition } rows.
---
--- A row is a table line whose first cell is a single backticked path; the heading row and the
--- `|---|` separator have no backticks and fall out on their own. Reading stops at the next
--- heading of any level, so a later section growing a table of its own cannot leak into this one.
local function censusRows()
    local body = readFile(ARCHITECTURE)
    if not body then fail(ARCHITECTURE .. " could not be opened") end

    local rows, inside, found = {}, false, false
    for line in (body .. "\n"):gmatch("([^\n]*)\n") do
        if line == CENSUS_HEADING then
            inside, found = true, true
        elseif inside and line:sub(1, 1) == "#" then
            break
        elseif inside then
            local path, _, disposition = line:match("^|%s*`([^`]+)`%s*|%s*(.-)%s*|%s*(.-)%s*|%s*$")
            if path then
                rows[#rows + 1] = { path = path, disposition = disposition }
            end
        end
    end

    if not found then
        fail(ARCHITECTURE .. " carries no '" .. CENSUS_HEADING .. "' section; the cap census is " ..
             "where every file over the cap is remarked on and it must not be removed")
    end
    return rows
end

-- ---------------------------------------------------------------------------
-- The cases
-- ---------------------------------------------------------------------------

test("layoutcap: PrettyChat.toc is still the only load list this gate has to read", function()
    local stray = {}
    for _, path in ipairs(gitLsFiles("*.xml")) do
        if not path:find("^libs/") then stray[#stray + 1] = path end
    end
    if #stray > 0 then
        fail("a second load list has appeared beside " .. TOC .. ": " ..
             table.concat(stray, ", ") .. " — the generated-data carve-out's second condition is " ..
             "'absent from the TOC and from every test load list', and this gate only reads the " ..
             "TOC because until now there was nothing else to read. Teach `tocLoadList` about " ..
             "the new file before clearing this")
    end
end)

test("layoutcap: every authored file over 1500 lines is named in the ARCHITECTURE.md census", function()
    local listed = {}
    for _, row in ipairs(censusRows()) do listed[row.path] = true end

    local unremarked = {}
    for _, path in ipairs(trackedAuthoredLua()) do
        local n = countLines(path)
        if n == nil then
            fail("git tracks " .. path .. " but it cannot be opened")
        elseif n > CAP and not listed[path] then
            unremarked[#unremarked + 1] = path .. " (" .. n .. ")"
        end
    end

    if #unremarked > 0 then
        fail("over layout-§1's " .. CAP .. "-line cap and remarked on nowhere: " ..
             table.concat(unremarked, ", ") ..
             " — peel it, open an issue naming the seam it would peel on, or ratify a register " ..
             "row with a re-check trigger; then add the row to " .. ARCHITECTURE .. "'s census")
    end
end)

test("layoutcap: no census row outlives the breach it records", function()
    local rows = censusRows()
    if #rows == 0 then
        fail("the census table under '" .. CENSUS_HEADING .. "' has no rows; if this repository " ..
             "really has nothing over the cap left, delete the section rather than leaving an " ..
             "empty table for a later reader to mistake for a census that was never filled in")
    end

    local spent = {}
    for _, row in ipairs(rows) do
        local n = countLines(row.path)
        if n == nil then
            spent[#spent + 1] = row.path .. " (no such file)"
        elseif n <= CAP then
            spent[#spent + 1] = row.path .. " (" .. n .. ", under the cap)"
        end
    end

    if #spent > 0 then
        fail(ARCHITECTURE .. "'s cap census carries rows for files that no longer sit over the " ..
             "cap: " .. table.concat(spent, ", ") .. " — delete the row, and retire the register " ..
             "row or close the issue that backs it. The register must not become a graveyard")
    end
end)

test("layoutcap: every census row carries a disposition that can be followed", function()
    local unfollowable = {}
    for _, row in ipairs(censusRows()) do
        -- layout-§1's two non-peel terminal states, plus the carve-out: an issue number to open,
        -- the register row above to read, or an exemption — which the next case then has to
        -- prove. A disposition cell naming none of the three is a note, and a note is exactly
        -- what this section exists to stop being enough.
        if not (row.disposition:find("#%d")
                or row.disposition:find("[Rr]egister row")
                or row.disposition:find("[Ee]xempt")) then
            unfollowable[#unfollowable + 1] = row.path
        end
    end

    if #unfollowable > 0 then
        fail("cap census rows whose disposition names neither an issue, nor the register row, " ..
             "nor an exemption: " .. table.concat(unfollowable, ", "))
    end
end)

test("layoutcap: every row claiming layout-§1's generated-data carve-out still earns all three of its conditions", function()
    local loaded  = tocLoadList()
    local ignores = pkgmetaIgnores()

    local claimed, broken = 0, {}
    for _, row in ipairs(censusRows()) do
        if row.disposition:find("[Ee]xempt") then
            claimed = claimed + 1
            local ok, why = isExemptGeneratedData(row.path, loaded, ignores)
            if not ok then
                broken[#broken + 1] = row.path .. " — " .. why
            end
        end
    end

    if #broken > 0 then
        fail("a census row claims layout-§1's generated-data carve-out but no longer earns it: " ..
             table.concat(broken, "; ") .. ". The carve-out needs ALL THREE of generated, loaded " ..
             "by nothing, and .pkgmeta-ignored; a file failing any one of them is an ordinary " ..
             "source file with an unusual origin and the cap binds it. Restore the condition, or " ..
             "give the file one of the three terminal states instead")
    end

    -- The exemption is the only thing keeping a 23,842-line file out of a layout-§1 MUST here, so
    -- a census that has stopped claiming it at all is a change worth being told about rather than
    -- something to discover from a green run. If the dump is genuinely gone, delete this case.
    if claimed == 0 then
        fail("no census row claims the generated-data carve-out any more. If " ..
             "GlobalStrings/GlobalStrings.lua was deleted or peeled that is fine and this case " ..
             "goes with it; if its row merely changed wording, the conditions above are no " ..
             "longer being checked and the exemption has become an assertion nobody tests")
    end
end)
