-- TOC <-> root *.lua consistency check (plain Lua 5.1, no rocks).
-- For every *.toc in the repo root: each listed file must exist, and every
-- root-level .lua file must be listed. Files outside the root are ignored.
-- Run from the repo root: lua scripts/check-toc.lua

-- Root-level file names matching a pattern, via the shell (ubuntu CI).
local function RootFiles(glob)
    local names = {}
    local pipe = assert(io.popen("find . -maxdepth 1 -type f -name '" .. glob .. "'"))
    for line in pipe:lines() do
        local name = line:gsub("^%./", "")
        names[#names + 1] = name
    end
    pipe:close()
    table.sort(names)
    return names
end

local function Exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

-- Listed file paths from a TOC: non-empty lines that aren't ## metadata or # comments.
local function ReadToc(path)
    local listed = {}
    local f = assert(io.open(path, "r"))
    for line in f:lines() do
        line = line:gsub("\r$", ""):match("^%s*(.-)%s*$")
        if line ~= "" and not line:find("^#") then
            listed[#listed + 1] = (line:gsub("\\", "/"))
        end
    end
    f:close()
    return listed
end

local tocs = RootFiles("*.toc")
local roots = RootFiles("*.lua")
local failures = {}
local function Fail(text) failures[#failures + 1] = text end

if #tocs == 0 then Fail("no .toc file in the repo root") end

for _, toc in ipairs(tocs) do
    local listed = {}
    for _, file in ipairs(ReadToc(toc)) do
        listed[file] = true
        if not Exists(file) then Fail(toc .. ": listed file is missing: " .. file) end
    end
    for _, file in ipairs(roots) do
        if not listed[file] then Fail(toc .. ": root .lua file is not listed: " .. file) end
    end
end

if #failures > 0 then
    for _, text in ipairs(failures) do io.stderr:write("check-toc: " .. text .. "\n") end
    os.exit(1)
end
print(string.format("check-toc: OK (%d toc, %d root .lua files)", #tocs, #roots))
