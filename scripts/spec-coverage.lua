-- Spec coverage report: which OpenSpec scenarios have a matching busted test.
--
-- Usage (from the repo root, plain Lua 5.1, no extra rocks):
--   lua scripts/spec-coverage.lua               runs `busted -o json` itself
--   lua scripts/spec-coverage.lua results.json  reads saved `busted -o json` output
-- The busted command can be overridden with the BUSTED environment variable.
--
-- Matching (design Decision 5): a test's top describe is the capability directory
-- under openspec/specs/, and its own name (the `it`) is the exact scenario title.
-- Requirement describes in between are ignored; `unit: ...` describes are skipped.
--
-- Writes markdown to $GITHUB_STEP_SUMMARY (stdout when unset). Always exits 0:
-- this is a report, never a gate.

local SPECS_DIR = "openspec/specs"

-- ---------------------------------------------------------------- JSON decoder

local function decodeJson(text)
    local pos = 1

    local function fail(msg)
        error(("JSON parse error at byte %d: %s"):format(pos, msg), 0)
    end

    local function skipSpace()
        pos = text:find("[^ \t\r\n]", pos) or (#text + 1)
    end

    local function utf8(code)
        if code < 0x80 then
            return string.char(code)
        elseif code < 0x800 then
            return string.char(0xC0 + math.floor(code / 0x40), 0x80 + code % 0x40)
        elseif code < 0x10000 then
            return string.char(0xE0 + math.floor(code / 0x1000), 0x80 + math.floor(code / 0x40) % 0x40,
                0x80 + code % 0x40)
        end
        return string.char(0xF0 + math.floor(code / 0x40000), 0x80 + math.floor(code / 0x1000) % 0x40,
            0x80 + math.floor(code / 0x40) % 0x40, 0x80 + code % 0x40)
    end

    local escapes = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }

    local function parseString()
        pos = pos + 1 -- opening quote
        local parts = {}
        while true do
            local stop = text:find('["\\]', pos)
            if not stop then fail("unterminated string") end
            parts[#parts + 1] = text:sub(pos, stop - 1)
            if text:sub(stop, stop) == '"' then
                pos = stop + 1
                return table.concat(parts)
            end
            local esc = text:sub(stop + 1, stop + 1)
            if esc == "u" then
                local hex = text:sub(stop + 2, stop + 5)
                local code = tonumber(hex, 16)
                if not code or #hex ~= 4 then fail("bad \\u escape") end
                pos = stop + 6
                if code >= 0xD800 and code <= 0xDBFF and text:sub(pos, pos + 1) == "\\u" then
                    local low = tonumber(text:sub(pos + 2, pos + 5), 16)
                    if low and low >= 0xDC00 and low <= 0xDFFF then
                        code = 0x10000 + (code - 0xD800) * 0x400 + (low - 0xDC00)
                        pos = pos + 6
                    end
                end
                parts[#parts + 1] = utf8(code)
            elseif escapes[esc] then
                parts[#parts + 1] = escapes[esc]
                pos = stop + 2
            else
                fail("bad escape \\" .. esc)
            end
        end
    end

    local parseValue

    local function parseArray()
        pos = pos + 1
        local arr = {}
        skipSpace()
        if text:sub(pos, pos) == "]" then
            pos = pos + 1
            return arr
        end
        while true do
            arr[#arr + 1] = parseValue()
            skipSpace()
            local c = text:sub(pos, pos)
            pos = pos + 1
            if c == "]" then return arr end
            if c ~= "," then fail("expected ',' or ']'") end
        end
    end

    local function parseObject()
        pos = pos + 1
        local obj = {}
        skipSpace()
        if text:sub(pos, pos) == "}" then
            pos = pos + 1
            return obj
        end
        while true do
            skipSpace()
            if text:sub(pos, pos) ~= '"' then fail("expected object key") end
            local key = parseString()
            skipSpace()
            if text:sub(pos, pos) ~= ":" then fail("expected ':'") end
            pos = pos + 1
            obj[key] = parseValue()
            skipSpace()
            local c = text:sub(pos, pos)
            pos = pos + 1
            if c == "}" then return obj end
            if c ~= "," then fail("expected ',' or '}'") end
        end
    end

    local literals = { ["true"] = true, ["false"] = false }

    function parseValue()
        skipSpace()
        local c = text:sub(pos, pos)
        if c == "{" then return parseObject() end
        if c == "[" then return parseArray() end
        if c == '"' then return parseString() end
        for word, value in pairs(literals) do
            if text:sub(pos, pos + #word - 1) == word then
                pos = pos + #word
                return value
            end
        end
        if text:sub(pos, pos + 3) == "null" then
            pos = pos + 4
            return nil
        end
        local num = text:match("^-?%d+%.?%d*[eE]?[-+]?%d*", pos)
        if num and num ~= "" and num ~= "-" then
            pos = pos + #num
            return tonumber(num)
        end
        fail("unexpected character '" .. c .. "'")
    end

    local value = parseValue()
    skipSpace()
    if pos <= #text then fail("trailing data") end
    return value
end

-- ------------------------------------------------------------------ Spec files

local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

local function listCapabilities()
    local caps = {}
    local p = io.popen('ls -1 "' .. SPECS_DIR .. '" 2>/dev/null')
    if p then
        for line in p:lines() do
            line = line:gsub("%s+$", "")
            if line ~= "" and readFile(SPECS_DIR .. "/" .. line .. "/spec.md") then
                caps[#caps + 1] = line
            end
        end
        p:close()
    end
    table.sort(caps)
    return caps
end

-- Returns { names = {cap...}, [cap] = { titles = {title...}, set = {title = true} } }
local function readScenarios()
    local specs = { names = listCapabilities() }
    for _, cap in ipairs(specs.names) do
        local entry = { titles = {}, set = {} }
        for line in (readFile(SPECS_DIR .. "/" .. cap .. "/spec.md") .. "\n"):gmatch("([^\n]*)\n") do
            local title = line:match("^####%s+Scenario:%s*(.-)%s*$")
            if title and title ~= "" and not entry.set[title] then
                entry.set[title] = true
                entry.titles[#entry.titles + 1] = title
            end
        end
        specs[cap] = entry
    end
    return specs
end

-- ---------------------------------------------------------------- Test results

local function readResults(path)
    local text
    if path then
        text = readFile(path)
        if not text then error("cannot read " .. path, 0) end
    else
        local cmd = (os.getenv("BUSTED") or "busted") .. " -o json"
        local p = io.popen(cmd .. " 2>/dev/null")
        if not p then error("cannot run `" .. cmd .. "`", 0) end
        text = p:read("*a")
        p:close()
    end
    -- The JSON handler writes one line at suite end; anything a test printed comes before it.
    local lastErr = "no JSON object in busted output"
    for start in text:gmatch("(){") do
        local ok, result = pcall(decodeJson, text:sub(start))
        if ok and type(result) == "table" then return result end
        if not ok then lastErr = result end
    end
    error(lastErr, 0)
end

local function location(test)
    local trace = test.element and test.element.trace or test.trace
    if type(trace) == "table" and trace.short_src then
        return trace.short_src .. ":" .. tostring(trace.currentline or "?")
    end
    return nil
end

-- --------------------------------------------------------------------- Report

local function md(s)
    return (tostring(s):gsub("([|*_`<>%[%]\\])", "\\%1"))
end

-- Code span: no backslash escapes apply inside, so only backticks need replacing.
local function code(s)
    return "`" .. tostring(s):gsub("`", "'") .. "`"
end

local function buildReport(specs, results)
    local covered, pendingOnly, unmatched = {}, {}, {}
    local errors = 0
    for _, cap in ipairs(specs.names) do
        covered[cap], pendingOnly[cap] = {}, {}
    end

    local function visit(test, isPending)
        local element = test.element or {}
        local full, title = test.name, element.name
        if type(full) ~= "string" or type(title) ~= "string" then return end
        local cap = full:match("^(%S+)")
        if not cap or cap == "unit:" or cap:sub(1, 5) == "unit:" then return end
        if full == title then return end -- not inside any describe; nothing to match on
        if specs[cap] and specs[cap].set[title] then
            if isPending then
                pendingOnly[cap][title] = true
            else
                covered[cap][title] = true
            end
        else
            unmatched[#unmatched + 1] = {
                cap = cap,
                full = full,
                title = title,
                known = specs[cap] ~= nil,
                where = location(test),
            }
        end
    end

    for _, list in ipairs({ "successes", "failures" }) do
        for _, test in ipairs(results[list] or {}) do visit(test, false) end
    end
    for _, test in ipairs(results.pendings or {}) do visit(test, true) end
    for _, test in ipairs(results.errors or {}) do
        errors = errors + 1
        -- An error inside an `it` still names a test that exists.
        if test.element and test.element.descriptor == "it" then visit(test, false) end
    end

    local out = {}
    local function add(s) out[#out + 1] = s or "" end

    add("### Spec coverage")
    add()
    add("Scenarios in `openspec/specs/` with a test named after them (see design Decision 5).")
    add()
    add("| Capability | Covered | Total | % |")
    add("| --- | ---: | ---: | ---: |")
    local sumCovered, sumTotal = 0, 0
    for _, cap in ipairs(specs.names) do
        local total, n = #specs[cap].titles, 0
        for _, title in ipairs(specs[cap].titles) do
            if covered[cap][title] then n = n + 1 end
        end
        sumCovered, sumTotal = sumCovered + n, sumTotal + total
        local pct = total > 0 and ("%d%%"):format(math.floor(n * 100 / total + 0.5)) or "-"
        add(("| %s | %d | %d | %s |"):format(md(cap), n, total, pct))
    end
    add(("| **Total** | **%d** | **%d** | **%s** |"):format(sumCovered, sumTotal,
        sumTotal > 0 and ("%d%%"):format(math.floor(sumCovered * 100 / sumTotal + 0.5)) or "-"))
    add()

    add("#### Uncovered scenarios")
    add()
    local anyUncovered = false
    for _, cap in ipairs(specs.names) do
        local missing = {}
        for _, title in ipairs(specs[cap].titles) do
            if not covered[cap][title] then
                local note = pendingOnly[cap][title] and " _(pending test)_" or ""
                missing[#missing + 1] = "- " .. md(title) .. note
            end
        end
        if #missing > 0 then
            anyUncovered = true
            add(("<details><summary>%s (%d)</summary>"):format(md(cap), #missing))
            add()
            for _, line in ipairs(missing) do add(line) end
            add()
            add("</details>")
            add()
        end
    end
    if not anyUncovered then
        add("None.")
        add()
    end

    add("#### Unmatched tests")
    add()
    if #unmatched == 0 then
        add("None.")
    else
        add("Tests under a capability whose name matches no scenario there (renamed or removed scenario?).")
        add()
        for _, u in ipairs(unmatched) do
            local why = u.known and "" or " _(no capability " .. code(u.cap) .. " in openspec/specs/)_"
            local where = u.where and (" (" .. code(u.where) .. ")") or ""
            add(("- **%s** › %s%s%s"):format(md(u.cap), md(u.title), where, why))
        end
    end
    add()
    if errors > 0 then
        add(("_%d busted error(s) during the run; see the test step's output._"):format(errors))
        add()
    end
    return table.concat(out, "\n")
end

-- ----------------------------------------------------------------------- Main

local function writeSummary(text)
    local path = os.getenv("GITHUB_STEP_SUMMARY")
    local f = path and path ~= "" and io.open(path, "a")
    if f then
        f:write(text, "\n")
        f:close()
    else
        io.write(text, "\n")
    end
end

local ok, err = pcall(function()
    local specs = readScenarios()
    if #specs.names == 0 then error("no capabilities found under " .. SPECS_DIR .. "/", 0) end
    local results = readResults(arg and arg[1])
    writeSummary(buildReport(specs, results))
end)

if not ok then
    writeSummary("### Spec coverage\n\nCould not build the spec coverage report: " .. md(err) .. "\n")
end
os.exit(0)
