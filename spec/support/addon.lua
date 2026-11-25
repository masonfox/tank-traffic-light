-- Loads the addon's own files the way the client does: TOC order, each chunk called
-- as chunk("TankTrafficLight", TT) against one fresh TT, inside the fake world's
-- strict sandbox. Then fires ADDON_LOADED so Core.lua migrates and defaults the
-- saved variables.
--
--   local addon = require("spec.support.addon")
--   local ctx
--   before_each(function() ctx = addon.load({ db = { gap = 8 } }) end)
--   -- ctx.TT, ctx.world, ctx.env, ctx.db(), ctx.slash("grey")
--
-- Options:
--   db       the TankTrafficLightDB the client would restore (nil = first install)
--   exclude  extra file names to skip, e.g. { "Probe.lua" }
--   world    a pre-built world (default: a fresh one), to set world.absent etc. first
--   setup    function(world) run before any file loads
--   loaded   false to skip firing ADDON_LOADED

local wow = require("spec.support.wow")

local M = {}

M.ADDON_NAME = "TankTrafficLight"
M.TOC = "TankTrafficLight.toc"
-- Files the tests never load: the options window and its preview (design Non-Goals).
M.SKIP = { ["Options.lua"] = true, ["Preview.lua"] = true }

-- Repo root holding the TOC. Relative paths keep chunk names short ("Safe.lua"), which
-- is what the .luacov include patterns match.
local function Root()
    local f = io.open(M.TOC, "r")
    if f then f:close() return nil end
    local source = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
    local dir = source:match("^(.*)/spec/support/[^/]+$")
    return dir
end

local function PathOf(root, file)
    if root then return root .. "/" .. file end
    return file
end

-- File names listed in the TOC, in order.
function M.TocFiles(root)
    local files = {}
    local f = assert(io.open(PathOf(root, M.TOC), "r"))
    for line in f:lines() do
        line = line:gsub("\r$", ""):match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^#") then files[#files + 1] = line end
    end
    f:close()
    return files
end

function M.load(opts)
    opts = opts or {}
    local root = Root()
    local world = opts.world or wow.new()
    local env = world.env
    if opts.setup then opts.setup(world) end

    local skip = {}
    for name in pairs(M.SKIP) do skip[name] = true end
    for _, name in ipairs(opts.exclude or {}) do skip[name] = true end

    local TT = {}
    -- Options.lua is not loaded; Settings and Core still call these.
    world.optionsRefreshed, world.optionsToggled = 0, 0
    TT.RefreshOptions = function() world.optionsRefreshed = world.optionsRefreshed + 1 end
    TT.ToggleOptions = function() world.optionsToggled = world.optionsToggled + 1 end

    rawset(env, "TankTrafficLightDB", opts.db)

    local loadedFiles = {}
    for _, file in ipairs(M.TocFiles(root)) do
        if not skip[file] then
            local chunk = assert(loadfile(PathOf(root, file)))
            setfenv(chunk, env)
            chunk(M.ADDON_NAME, TT)
            loadedFiles[#loadedFiles + 1] = file
        end
    end

    if opts.loaded ~= false then world.fire("ADDON_LOADED", M.ADDON_NAME) end

    return {
        TT = TT,
        world = world,
        env = env,
        files = loadedFiles,
        db = function() return rawget(env, "TankTrafficLightDB") end,
        slash = function(msg) return env.SlashCmdList.TANKTRAFFICLIGHT(msg) end,
    }
end

return M
