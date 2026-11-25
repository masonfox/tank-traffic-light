-- The fake world: a simulated WoW client the addon's files run against in tests.
--
--   local wow = require("spec.support.wow")
--   local world = wow.new()
--   world.units.nameplate1 = { attackable = true, combat = true, threat = 0, target = "party1" }
--   world.units.party1     = { inParty = true, role = "TANK", class = "WARRIOR", name = "Tanky" }
--
-- Every Unit* API resolves its token through world.units ("<unit>target" follows the
-- unit's `target` field). Any field may hold world.SECRET, which issecretvalue() reports
-- as secret. world.env is the strict sandbox the addon chunks run in: reading a global
-- that is neither provided (world.globals) nor listed in world.absent is an error.
--
-- Lua 5.1 only (setfenv), on purpose: the game client runs Lua 5.1.

assert(type(setfenv) == "function", "the fake world needs Lua 5.1 (setfenv)")

local M = {}

-- Lua 5.1 standard globals the game client also has. io/os/require/debug are not in
-- the client, so they are left out on purpose.
local LUA_STANDARD = {
    "assert", "error", "getmetatable", "setmetatable", "ipairs", "pairs", "next",
    "pcall", "xpcall", "select", "tonumber", "tostring", "type", "unpack",
    "rawget", "rawset", "rawequal", "loadstring", "string", "table", "math", "coroutine",
    "_VERSION",
}

-- Globals the addon owns: they read as nil until the addon (or a test) writes them.
local ADDON_GLOBALS = {
    TankTrafficLightDB = true,
    SLASH_TANKTRAFFICLIGHT1 = true,
    SLASH_TANKTRAFFICLIGHT2 = true,
}

-- Sound kit ids for every sound name Settings.lua offers.
local SOUNDKIT_IDS = {
    IG_PLAYER_INVITE = 880,
    TELL_MESSAGE = 3081,
    ALARM_CLOCK_WARNING_2 = 12867,
    ALARM_CLOCK_WARNING_3 = 12889,
    READY_CHECK = 8960,
    RAID_WARNING = 8959,
}

---------------------------------------------------------------------------
-- Permissive widgets (frames, textures, font strings, animations)
---------------------------------------------------------------------------

-- Method names a widget accepts without an explicit stub. Data fields the addon
-- reads off widgets (plate.UnitFrame, plate.TankTrafficLightFrame, f.lamps, ...)
-- must stay nil, so only verb-like names become no-op methods.
local METHOD_PREFIXES = {
    "Set", "Get", "Is", "Enable", "Disable", "Clear", "Create", "Register", "Unregister",
    "Show", "Hide", "Play", "Stop", "Pause", "Restart", "Finish", "Add", "Remove", "Has",
    "Can", "Hook", "Raise", "Lower", "Start", "Adjust", "Apply", "Click", "Lock", "Unlock",
}

local function IsMethodName(key)
    if type(key) ~= "string" then return false end
    for _, prefix in ipairs(METHOD_PREFIXES) do
        if key:sub(1, #prefix) == prefix and key:sub(#prefix + 1, #prefix + 1):match("^[%u]?$") then
            return true
        end
    end
    return false
end

local Widget = {}

local function NewWidget(world, objectType, parent, name)
    local w = setmetatable({
        _world = world, _type = objectType, _parent = parent, _name = name,
        _shown = true, _alpha = 1, _scale = 1, _level = parent and parent._level and parent._level + 1 or 1,
        _width = 100, _height = 20,
        _scripts = {}, _events = {}, _calls = {}, _playing = false,
    }, Widget)
    return w
end

Widget.__index = function(self, key)
    local method = rawget(Widget, key)
    if method then return method end
    if IsMethodName(key) then
        -- Any other method call is accepted, recorded, and returns nothing.
        local stub = function(widget, ...)
            local calls = rawget(widget, "_calls")
            if calls then calls[#calls + 1] = { key, ... } end
        end
        rawset(self, key, stub)
        return stub
    end
    return nil
end

function Widget:GetObjectType() return self._type end
function Widget:GetName() return self._name end
function Widget:GetParent() return self._parent end
function Widget:Show() self._shown = true end
function Widget:Hide() self._shown = false end
function Widget:SetShown(shown) self._shown = shown and true or false end
function Widget:IsShown() return self._shown end
function Widget:IsVisible() return self._shown end
function Widget:SetAlpha(a) self._alpha = a end
function Widget:GetAlpha() return self._alpha end
function Widget:SetScale(s) self._scale = s end
function Widget:GetScale() return self._scale end
function Widget:SetFrameLevel(l) self._level = l end
function Widget:GetFrameLevel() return self._level end
function Widget:SetSize(w, h) self._width, self._height = w, h end
function Widget:SetWidth(w) self._width = w end
function Widget:SetHeight(h) self._height = h end
function Widget:GetWidth() return self._width end
function Widget:GetHeight() return self._height end
function Widget:GetSize() return self._width, self._height end
function Widget:SetText(text) self._text = text end
function Widget:GetText() return self._text end

function Widget:SetScript(handler, fn) self._scripts[handler] = fn end
function Widget:GetScript(handler) return self._scripts[handler] end
function Widget:HookScript(handler, fn)
    local old = self._scripts[handler]
    self._scripts[handler] = old and function(...) old(...) fn(...) end or fn
end
function Widget:RegisterEvent(event) self._events[event] = true end
function Widget:UnregisterEvent(event) self._events[event] = nil end
function Widget:UnregisterAllEvents() self._events = {} end
function Widget:IsEventRegistered(event) return self._events[event] == true end

-- Animation groups and animations.
function Widget:Play() self._playing = true end
function Widget:Stop() self._playing = false end
function Widget:IsPlaying() return self._playing end

local function Child(self, objectType, name)
    local child = NewWidget(self._world, objectType, self, name)
    local children = rawget(self, "_children")
    if not children then children = {} rawset(self, "_children", children) end
    children[#children + 1] = child
    return child
end
function Widget:CreateTexture(name) return Child(self, "Texture", name) end
function Widget:CreateMaskTexture(name) return Child(self, "MaskTexture", name) end
function Widget:CreateFontString(name) return Child(self, "FontString", name) end
function Widget:CreateAnimationGroup(name) return Child(self, "AnimationGroup", name) end
function Widget:CreateAnimation(animType, name) return Child(self, animType or "Animation", name) end

M.Widget = Widget

---------------------------------------------------------------------------
-- The world
---------------------------------------------------------------------------

-- Every world built since the last test ended; spec/support/strict_globals.lua checks
-- their `missing` lists after each test and resets this.
M.worlds = {}

function M.new()
    local world = {}
    M.worlds[#M.worlds + 1] = world
    world.SECRET = setmetatable({}, { __tostring = function() return "SECRET" end })
    world.units = {
        player = { name = "Tanky", guid = "Player-0-00000001", class = "WARRIOR", role = "TANK" },
    }
    world.instance = { false, "none" } -- IsInInstance() returns
    world.time = 100                   -- GetTime()
    world.combatLockdown = false       -- InCombatLockdown()
    world.plates = {}                  -- nameplate token -> plate frame (C_NamePlate)
    world.played = {}                  -- PlaySound ids, in order
    world.playedChannels = {}          -- PlaySound channels, same order
    world.chat = {}                    -- print() lines
    world.timers = {}                  -- C_Timer.After delays, in order (callbacks run at once)
    world.frames = {}                  -- every CreateFrame result, in creation order
    world.absent = {}                  -- name -> true: global reads as nil (API missing on this client)
    world.missing = {}                 -- globals the addon read that the world lacks, in order

    local SECRET = world.SECRET

    -- Resolve a unit token to a world.units key, following "<unit>target" chains.
    -- Returns the key, SECRET when a target link is secret, or nil when no such unit.
    local function Resolve(token)
        if token == SECRET then return SECRET end
        if type(token) ~= "string" then return nil end
        if world.units[token] then return token end
        local base = token:match("^(.+)target$")
        if not base then return nil end
        local from = Resolve(base)
        if from == nil then return nil end
        if from == SECRET then return SECRET end
        local link = world.units[from].target
        if link == SECRET then return SECRET end
        return Resolve(link)
    end
    world.resolve = Resolve

    -- Unit data for a token: the data table, SECRET, or nil.
    local function Data(token)
        local key = Resolve(token)
        if key == nil or key == SECRET then return key end
        return world.units[key]
    end

    -- Read one field of a unit: SECRET propagates, a missing unit gives `missing`.
    local function Field(token, field, missing)
        local d = Data(token)
        if d == nil then return missing end
        if d == SECRET then return SECRET end
        local v = d[field]
        if v == nil then return missing end
        return v
    end

    local g = {}
    world.globals = g

    g.issecretvalue = function(v) return v == SECRET end

    g.UnitExists = function(unit)
        local d = Data(unit)
        if d == nil then return false end
        if d == SECRET then return SECRET end
        if d.exists ~= nil then return d.exists end
        return true
    end
    g.UnitName = function(unit)
        local d = Data(unit)
        if d == nil then return nil end
        if d == SECRET then return SECRET end
        return d.name, d.realm
    end
    g.UnitGUID = function(unit) return Field(unit, "guid", nil) end
    g.UnitCanAttack = function(_, unit) return Field(unit, "attackable", false) end
    g.UnitAffectingCombat = function(unit) return Field(unit, "combat", false) end
    -- nil: not on the unit's threat list. 0/1 not tanking, 2 insecurely, 3 securely.
    g.UnitThreatSituation = function(_, unit) return Field(unit, "threat", nil) end
    g.UnitDetailedThreatSituation = function(_, unit)
        local status = Field(unit, "threat", nil)
        if status == nil then return nil end
        if status == SECRET then return SECRET, SECRET, SECRET, SECRET, SECRET end
        local tanking = status >= 2
        return tanking, status, tanking and 100 or 50, tanking and 110 or 55, 1000
    end
    g.UnitIsUnit = function(a, b)
        local ra, rb = Resolve(a), Resolve(b)
        if ra == SECRET or rb == SECRET then return SECRET end
        for _, r in ipairs({ ra, rb }) do
            local override = r and world.units[r].isUnit
            if override ~= nil then return override end
        end
        return ra ~= nil and ra == rb
    end
    g.UnitInParty = function(unit) return Field(unit, "inParty", false) end
    g.UnitInRaid = function(unit) return Field(unit, "raidIndex", nil) end -- raid index or nil
    g.UnitGroupRolesAssigned = function(unit) return Field(unit, "role", "NONE") end
    g.UnitClass = function(unit)
        local d = Data(unit)
        if d == nil then return nil end
        if d == SECRET then return SECRET, SECRET, SECRET end
        local token = d.class
        if token == nil then return nil end
        if token == SECRET then return SECRET, SECRET, SECRET end
        local localized = d.className or (token:sub(1, 1) .. token:sub(2):lower())
        return localized, token, d.classId or 1
    end
    g.GetPartyAssignment = function(assignment, unit)
        local field = assignment == "MAINTANK" and "mainTank" or assignment == "MAINASSIST" and "mainAssist"
        if not field then return false end
        return Field(unit, field, false)
    end

    g.IsInInstance = function() return world.instance[1], world.instance[2] end
    g.GetTime = function() return world.time end
    g.InCombatLockdown = function() return world.combatLockdown end

    g.SOUNDKIT = {}
    for name, id in pairs(SOUNDKIT_IDS) do g.SOUNDKIT[name] = id end
    g.PlaySound = function(id, channel)
        world.played[#world.played + 1] = id
        world.playedChannels[#world.playedChannels + 1] = channel
        return true
    end

    g.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
        world.chat[#world.chat + 1] = table.concat(parts, " ")
    end

    g.C_Timer = {
        After = function(delay, fn)
            world.timers[#world.timers + 1] = delay
            fn()
        end,
    }

    g.C_NamePlate = {
        GetNamePlateForUnit = function(unit) return world.plates[unit] end,
        GetNamePlates = function()
            local list = {}
            for _, plate in pairs(world.plates) do list[#list + 1] = plate end
            return list
        end,
    }

    g.CreateFrame = function(objectType, name, parent)
        local f = NewWidget(world, objectType or "Frame", parent, name)
        world.frames[#world.frames + 1] = f
        return f
    end
    g.UIParent = NewWidget(world, "Frame", nil, "UIParent")
    g.UIParent._width, g.UIParent._height = 1024, 768
    g.CreateColor = function(r, g_, b, a) return { r = r, g = g_, b = b, a = a } end
    g.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
    g.SlashCmdList = {}
    g.date = os.date

    for _, name in ipairs(LUA_STANDARD) do g[name] = _G[name] end

    -- A plate frame for a nameplate token, as C_NamePlate would hand back.
    function world.newPlate(unit)
        local plate = NewWidget(world, "Frame", g.UIParent, nil)
        plate._level = 10
        if unit then world.plates[unit] = plate end
        return plate
    end

    ---------------------------------------------------------------------------
    -- Strict sandbox env for the addon's chunks
    ---------------------------------------------------------------------------

    local env = {}
    env._G = env
    setmetatable(env, {
        __index = function(_, key)
            if world.absent[key] then return nil end
            local v = g[key]
            if v ~= nil then return v end
            if ADDON_GLOBALS[key] then return nil end
            world.missing[#world.missing + 1] = tostring(key)
            error("fake world lacks global " .. tostring(key), 2)
        end,
    })
    world.env = env

    ---------------------------------------------------------------------------
    -- Events and the clock
    ---------------------------------------------------------------------------

    -- Deliver an event to every frame registered for it, in creation order.
    function world.fire(event, ...)
        local delivered = 0
        for _, f in ipairs(world.frames) do
            local handler = f._scripts.OnEvent
            if f._events[event] and handler then
                handler(f, event, ...)
                delivered = delivered + 1
            end
        end
        return delivered
    end

    -- Run every frame's OnUpdate handler once with the given elapsed seconds.
    function world.update(elapsed)
        for _, f in ipairs(world.frames) do
            local handler = f._scripts.OnUpdate
            if handler then handler(f, elapsed) end
        end
    end

    function world.advance(seconds) world.time = world.time + seconds end

    ---------------------------------------------------------------------------
    -- Builders: return the unit token, so a scenario is a few lines
    ---------------------------------------------------------------------------

    local function NextToken(prefix, max)
        for i = 1, max do
            if not world.units[prefix .. i] then return prefix .. i, i end
        end
        error("no free " .. prefix .. " token")
    end

    local function Build(defaults, spec)
        local data = {}
        for k, v in pairs(defaults) do data[k] = v end
        for k, v in pairs(spec or {}) do if k ~= "token" then data[k] = v end end
        return data
    end

    -- An enemy on a nameplate: attackable, in combat, not on the player's threat
    -- list until `threat` is set. Also gets a plate frame. Pass `target` as a token.
    function world.mob(spec)
        spec = spec or {}
        local token, i = spec.token, nil
        if not token then token, i = NextToken("nameplate", 40) end
        i = i or tonumber(token:match("(%d+)$")) or 0
        world.units[token] = Build({
            name = "Skeleton", guid = string.format("Creature-0-0-0-0-1000-%010d", i),
            attackable = true, combat = true,
        }, spec)
        if not world.plates[token] then world.newPlate(token) end
        return token
    end

    local function Member(prefix, max, defaults, spec)
        spec = spec or {}
        local token, i = spec.token, nil
        if not token then token, i = NextToken(prefix, max) end
        i = i or tonumber(token:match("(%d+)$")) or 0
        local d = { guid = string.format("Player-0-%08d", 100 + i), name = prefix:gsub("^%l", string.upper) .. i,
            class = "WARRIOR", role = "DAMAGER" }
        for k, v in pairs(defaults) do d[k] = v end
        if defaults.raidIndex == true then d.raidIndex = i end
        world.units[token] = Build(d, spec)
        return token
    end

    -- A party member (party1..party4): in party, DAMAGER warrior unless told otherwise.
    function world.partyMember(spec)
        return Member("party", 4, { inParty = true }, spec)
    end

    -- A raid member (raid1..raid40): raid index set, not in the player's party.
    function world.raidMember(spec)
        return Member("raid", 40, { inParty = false, raidIndex = true }, spec)
    end

    -- A player outside the group (a stranger the mob is fighting).
    function world.stranger(spec)
        return Member("stranger", 40, { inParty = false, role = "NONE" }, spec)
    end

    -- The player's pet.
    function world.pet(spec)
        spec = spec or {}
        world.units.pet = Build({ name = "Pet", guid = "Pet-0-00000001" }, spec)
        return "pet"
    end

    return world
end

return M
