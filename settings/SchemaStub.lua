local _, NS = ...

-- settings/SchemaStub.lua — NS.SchemaStub, the host's degradation stub for LibKa0s-Schema-1.0.
-- Peeled out of settings/Schema.lua, the one file that reads it.

-- THE DEGRADATION STUB, for a load with no LibKa0s (every major floors on Core, so
-- they are absent together). WRITE-COMPLETING AND LOG-SILENT, the class the
-- library's document names (LibKa0s docs/api/Schema/version-2-docs.md, "The
-- degradation stub"): reads, writes, the row's `validate` (so the PC-R-01 gate still refuses),
-- `announce` (so the re-apply still happens) and the sweep veto all work, because a
-- player still reaches them through `/pc enable` / `/pc disable` (slash-commands-§1)
-- and the Options stub's Reset All (options-ui-§1). What it does not reproduce is
-- what only feeds the debug console: the [Set] line, the bracket's tally and the
-- reset count. core/DebugLogSetup.lua's library-less sink discards those lines
-- anyway.
--
-- The instance id a caller passes is forwarded the way Schema minor 2 forwards it:
-- Get hands it to the row's own `get`, ApplyDefault(row, id) hands it to Set, and
-- Set hands it to validate, normalize, onChange and announce. This addon keeps one
-- instance and no row reads the id today, so this is shape, not behavior: a stub that
-- dropped it would be the one path where a future per-instance row reads nil.
--
-- A DELIBERATE, DOCUMENTED DUPLICATION of the library's reference stub
-- (LibKa0s tests/test_schema.lua, `referenceStub`), kept close to it so the two
-- read alike. tests/test_surface_parity.lua pins its member set against a live
-- instance and against the library by name. Refusals are in this addon's own
-- words, not a copy of the library's STRINGS.
local function stubCopy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = stubCopy(x) end
    return out
end

NS.SchemaStub = NS.SchemaStub or {}
local SchemaStub = NS.SchemaStub

function SchemaStub.SplitPath(path)
    local parts = {}
    if path ~= nil then
        for seg in tostring(path):gmatch("[^%.]+") do parts[#parts + 1] = seg end
    end
    return parts
end

local function stubParts(p) return type(p) == "table" and p or SchemaStub.SplitPath(p) end

function SchemaStub.Read(root, p, first)
    local parts, node = stubParts(p), root
    first = first or 1
    if type(root) ~= "table" or #parts < first then return nil end
    for i = first, #parts do
        if type(node) ~= "table" then return nil end
        node = node[parts[i]]
    end
    return node
end

function SchemaStub.Write(root, p, value, first)
    local parts, node = stubParts(p), root
    first = first or 1
    if type(root) ~= "table" or #parts < first then return end
    for i = first, #parts - 1 do
        if type(node[parts[i]]) ~= "table" then node[parts[i]] = {} end
        node = node[parts[i]]
    end
    node[parts[#parts]] = value
end

function SchemaStub.SameValue(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for k, v in pairs(a) do if not SchemaStub.SameValue(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

-- The instance's reads and registry. Split from its writes only to keep each
-- builder under the CCN 15 the complexity gate holds this repo to.
local function stubReads(S, d, resolve)
    local held = d.rows
    function S.AllRows() return held end
    function S.FindRow(path)
        if type(path) ~= "string" then return nil end
        for _, row in ipairs(held) do
            if type(row) == "table" and row.path == path then return row end
        end
    end
    function S.AddRows(list, at)
        if type(list) ~= "table" then return 0 end
        at = type(at) == "number" and math.floor(at) or #held + 1
        if at > #held + 1 then at = #held + 1 elseif at < 1 then at = 1 end
        for i, row in ipairs(list) do table.insert(held, at + i - 1, row) end
        return #list
    end
    function S.Reindex() end
    function S.Get(path, id)
        local row = S.FindRow(path)
        if row and type(row.get) == "function" then return row.get(id) end
        if type(path) ~= "string" or (row and row.sessionOnly) then return nil end
        local parts = SchemaStub.SplitPath(path)
        local root, first = resolve(parts, id)
        if type(root) ~= "table" then return nil end
        return SchemaStub.Read(root, parts, first)
    end
end

-- Everything the stub checks before it stores, shared by Set and SetMany so a batch
-- refuses on exactly the rules a single write does: the row's validate, then its
-- normalize (which answers the value to store, or nil and why). Answers
-- `true, value` with the value to store, or `false, nil, err, why`.
local function stubPrepare(row, path, value, rid)
    if type(row.validate) == "function" then
        local ok, why = row.validate(value, rid)
        if not ok then return false, nil, "PrettyChat: invalid value for " .. path, why end
    end
    if type(row.normalize) == "function" then
        local out, why = row.normalize(value, rid)
        if out == nil then return false, nil, "PrettyChat: invalid value for " .. path, why end
        value = out
    end
    return true, value
end

-- Where a stored row's write lands: the split path, the root resolveRoot answers (nil
-- when it answers none) with its first segment, and the instance id resolveRoot may
-- rewrite. Split from stubSet, with stubStored, to hold every stub function at CCN
-- 10 or below.
local function stubStored(row) return type(row.set) ~= "function" and not row.sessionOnly end
local function stubTarget(path, id, resolve)
    local parts = SchemaStub.SplitPath(path)
    local r, f, got = resolve(parts, id)
    if type(r) ~= "table" then r, f = nil, nil end
    if got == nil then got = id end
    return parts, r, f, got
end

-- The write seam's order without its log and tally: refuse, validate and normalize,
-- store, react, announce.
local function stubSet(S, d, resolve)
    return function(path, value, id)
        local row = S.FindRow(path)
        if not row then return false, "PrettyChat: no setting " .. tostring(path) end
        local stored = stubStored(row)
        local parts, root, first, rid = nil, nil, nil, id
        if stored then parts, root, first, rid = stubTarget(path, id, resolve) end
        local ok, prepared, err, why = stubPrepare(row, path, value, rid)
        if not ok then return false, err, why end
        value = prepared
        if stored and not root then return false, "PrettyChat: nowhere to store " .. path end
        if type(row.set) == "function" then
            row.set(value)
        elseif stored then
            SchemaStub.Write(root, parts, stubCopy(value), first)
        end
        if type(row.onChange) == "function" then row.onChange(value, rid) end
        if type(d.announce) == "function" then d.announce(row, path, value, rid) end
        return true
    end
end

-- The all-or-nothing batch, without the library's announceBatch tail: this descriptor
-- declares none, so each write's own announce runs, as the live fallback does.
-- Phase 1 checks every entry before anything is stored; phase 2 writes through S.Set,
-- inside one bracket when opts.act is given.
local function stubSetMany(S)
    return function(entries, opts)
        if type(entries) ~= "table" then entries = {} end
        if type(opts) ~= "table" then opts = {} end
        local prepared = {}
        for i, e in ipairs(entries) do
            local row = type(e) == "table" and S.FindRow(e.path)
            if not row then return false, "PrettyChat: no setting " .. tostring(type(e) == "table" and e.path), nil, i end
            local ok, value, err, why = stubPrepare(row, e.path, e.value, opts.instanceId)
            if not ok then return false, err, why, i end
            prepared[i] = value
        end
        local function commit()
            for i, e in ipairs(entries) do S.Set(e.path, prepared[i], opts.instanceId) end
        end
        if opts.act ~= nil then S.BulkRun(opts.act, opts.scope, commit) else commit() end
        return true
    end
end

-- Colon-called like the library's own constructor (`SchemaLib:New{...}`); the
-- receiver is unused because the stub keeps no library-level state.
function SchemaStub.New(_, d)
    local S, depth = {}, 0
    local function resolve(parts, id)
        if type(d.resolveRoot) ~= "function" then return nil end
        return d.resolveRoot(parts, id)
    end
    stubReads(S, d, resolve)
    S.Set = stubSet(S, d, resolve)
    S.SetMany = stubSetMany(S)
    function S.Default(path)
        local row = S.FindRow(path)
        return row and stubCopy(row.default)
    end
    function S.ApplyDefault(row, id)
        if type(row) ~= "table" or type(row.path) ~= "string" or row.default == nil then return false end
        local exempt = d.resetExempt
        if depth > 0 and type(exempt) == "table" and exempt[row.path] then return false end
        return S.Set(row.path, stubCopy(row.default), id)
    end
    -- The bracket keeps its depth, because the sweep veto above reads it; it counts nothing.
    function S.BulkBegin() depth = depth + 1 end
    function S.BulkEnd() if depth > 0 then depth = depth - 1 end end
    function S.BulkRun(act, scope, fn)
        S.BulkBegin(act, scope)
        local ok, err = pcall(fn, { profileReset = false })
        S.BulkEnd(act, scope)
        if not ok then error(err, 0) end
    end
    function S.BulkAdd() end
    function S.InBulk() return depth > 0 end
    function S.CountOffDefault() return 0 end
    function S.ResetCounted(fn) fn() end
    function S.ConsumeResetCount() return nil end
    function S.Validate()
        if type(d.print) == "function" then
            d.print(NS.LIBKA0S_MISSING .. ", so the schema was not checked.")
        end
        return 0, 0, 0
    end
    return S
end
