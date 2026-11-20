local _, TT = ...
local S = {}
TT.Safe = S

-- True when a value can be read by addon code (not a hidden "secret" value).
function S.Public(value)
    if type(issecretvalue) ~= "function" then return true end
    local ok, restricted = pcall(issecretvalue, value)
    return ok and type(restricted) == "boolean" and not restricted
end

-- pcall(fn, ...) that refuses to call anything that isn't a readable function.
function S.Call(fn, ...)
    if not S.Public(fn) or type(fn) ~= "function" then return false, "function unavailable" end
    return pcall(fn, ...)
end

-- Describe a single value for logging without ever touching a secret one.
function S.Describe(value)
    if not S.Public(value) then return "SECRET" end
    if value == nil then return "nil" end
    local ok, text = pcall(tostring, value)
    return ok and text or "UNPRINTABLE"
end

-- Call fn(...) and describe every return value. Errors are reported, not raised.
function S.Probe(fn, ...)
    if type(fn) ~= "function" then return "MISSING API" end
    local results = { pcall(fn, ...) }
    if not results[1] then return "ERROR: " .. S.Describe(results[2]) end
    if #results == 1 then return "(no returns)" end
    local parts = {}
    for i = 2, #results do parts[#parts + 1] = S.Describe(results[i]) end
    return table.concat(parts, ", ")
end
