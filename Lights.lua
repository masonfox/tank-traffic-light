local _, TT = ...
local S = TT.Safe
local L = {}
TT.Lights = L

-- Traffic light states
local GREEN, YELLOW, RED = "green", "yellow", "red"
local ORDER = { RED, YELLOW, GREEN } -- top to bottom, like a real light

local COLORS = {
    [RED]    = { 0.95, 0.15, 0.10 },
    [YELLOW] = { 1.00, 0.80, 0.05 },
    [GREEN]  = { 0.15, 0.90, 0.25 },
}
local DIM = 0.18          -- brightness multiplier for unlit lamps
local LAMP_SIZE = 9
local LAMP_GAP = 1
local CIRCLE_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

local lights = {}         -- unit token -> light frame
local demoMode = false
local demoStep = 0

---------------------------------------------------------------------------
-- Reading the situation (every read is guarded against secret values)
---------------------------------------------------------------------------

local function Read(fn, ...)
    local ok, a = S.Call(fn, ...)
    if ok and S.Public(a) then return true, a end
    return false, nil
end

local function IsGroupMember(unit)
    local okP, isPlayer = Read(UnitIsUnit, unit, "player")
    if okP and isPlayer then return true end
    local okPet, isPet = Read(UnitIsUnit, unit, "pet")
    if okPet and isPet then return true end
    local okParty, inParty = Read(UnitInParty, unit)
    if okParty and inParty then return true end
    local okRaid, inRaid = Read(UnitInRaid, unit)
    if okRaid and inRaid ~= nil then return true end
    return false
end

-- Returns GREEN / YELLOW / RED (or nil for no light), plus a reason string for tracing.
function L.StateFor(unit)
    local okAtk, canAttack = Read(UnitCanAttack, "player", unit)
    if not okAtk or not canAttack then return nil, "not attackable" end
    local okCombat, inCombat = Read(UnitAffectingCombat, unit)
    if not okCombat then return nil, "combat SECRET" end
    if not inCombat then return nil, "not in combat" end

    local target = unit .. "target"
    local targetName = S.Describe((select(2, Read(UnitName, target))))

    -- Preferred: the game's own threat status.
    -- 3 = securely tanking, 2 = tanking but about to lose it, 0/1 = not on you.
    local okStatus, status = Read(UnitThreatSituation, "player", unit)
    local why = "status=" .. (okStatus and S.Describe(status) or "SECRET") .. " target=" .. targetName
    if okStatus then
        if status == 3 then return GREEN, why end
        if status == 2 then return YELLOW, why end
        if status == 0 or status == 1 then
            -- Only red when it's loose on *your* group. A mob you tagged that is
            -- fighting a stranger in the open world isn't your problem.
            local okEx, ex = Read(UnitExists, target)
            if okEx and ex and not IsGroupMember(target) then
                return nil, why .. " (on someone outside your group)"
            end
            return RED, why
        end
        -- status nil: you are not on its threat list at all.
    end

    -- Fallback: who is the mob hitting?
    local okExists, exists = Read(UnitExists, target)
    if not okExists or not exists then return nil, why .. " (no target)" end
    local okMe, onMe = Read(UnitIsUnit, target, "player")
    if okMe and onMe then
        -- Without a readable status we can't tell "slipping", only "on you".
        return GREEN, why .. " (fallback)"
    end
    if IsGroupMember(target) then return RED, why .. " (fallback)" end
    return nil, why .. " (target not in group)"
end

---------------------------------------------------------------------------
-- Trace: records every color change so odd flips can be diagnosed
---------------------------------------------------------------------------

local MAX_TRACE = 300

local function Trace(unit, from, to, why)
    local name = S.Describe((select(2, Read(UnitName, unit))))
    local okGuid, guid = Read(UnitGUID, unit)
    local id = okGuid and type(guid) == "string" and guid:sub(-6) or "?"
    local line = string.format("%s %s %s(%s) %s -> %s | %s", date("%H:%M:%S"), unit, name, id,
        from or "none", to or "none", why or "")
    local log = TankTrafficLightDB.traceLog
    log[#log + 1] = line
    while #log > MAX_TRACE do table.remove(log, 1) end
    if TankTrafficLightDB.trace then print("|cff66ccffTank Traffic Light|r " .. line) end
end

---------------------------------------------------------------------------
-- Nameplate visuals
---------------------------------------------------------------------------

local function AnchorTarget(plate)
    if plate.unitFrame and plate.unitFrame.healthBar then return plate.unitFrame.healthBar end -- Plater
    if plate.UnitFrame and plate.UnitFrame.healthBar then return plate.UnitFrame.healthBar end -- Blizzard
    return plate
end

-- Stand the light up (left/right of the bar) or lay it on its side (top).
local function Layout(f, horizontal)
    if f.horizontal == horizontal then return end
    f.horizontal = horizontal
    local long = LAMP_SIZE * 3 + LAMP_GAP * 2 + 4
    local short = LAMP_SIZE + 4
    if horizontal then f:SetSize(long, short) else f:SetSize(short, long) end
    for i, state in ipairs(ORDER) do
        local lamp = f.lamps[state]
        local offset = 2 + (i - 1) * (LAMP_SIZE + LAMP_GAP)
        lamp:ClearAllPoints()
        if horizontal then
            lamp:SetPoint("LEFT", f, "LEFT", offset, 0)   -- red, yellow, green left to right
        else
            lamp:SetPoint("TOP", f, "TOP", 0, -offset)    -- red, yellow, green top to bottom
        end
    end
end

local function CreateLight(plate)
    local f = CreateFrame("Frame", nil, plate)
    f:SetFrameLevel(plate:GetFrameLevel() + 20)

    local housing = f:CreateTexture(nil, "BACKGROUND")
    housing:SetAllPoints()
    housing:SetColorTexture(0.05, 0.05, 0.05, 0.85)

    f.lamps = {}
    for _, state in ipairs(ORDER) do
        local lamp = f:CreateTexture(nil, "ARTWORK")
        lamp:SetSize(LAMP_SIZE, LAMP_SIZE)
        lamp:SetColorTexture(1, 1, 1, 1)
        local mask = f:CreateMaskTexture()
        mask:SetTexture(CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(lamp)
        lamp:AddMaskTexture(mask)
        f.lamps[state] = lamp
    end

    -- Pulse used while yellow, so "slipping" catches the eye.
    local pulse = f:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local fade = pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0.35)
    fade:SetDuration(0.35)
    f.pulse = pulse

    return f
end

local function Paint(f, state)
    for lampState, lamp in pairs(f.lamps) do
        local c = COLORS[lampState]
        local k = (lampState == state) and 1 or DIM
        lamp:SetVertexColor(c[1] * k, c[2] * k, c[3] * k, 1)
    end
    if state == YELLOW and TankTrafficLightDB.pulse then
        if not f.pulse:IsPlaying() then f.pulse:Play() end
    elseif f.pulse:IsPlaying() then
        f.pulse:Stop()
        f:SetAlpha(1)
    end
end

local function GetPlate(unit)
    if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return nil end
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if ok then return plate end
end

-- Always resolve the plate fresh from the unit token: the game recycles
-- nameplate frames between mobs, so a cached unit -> light map goes stale.
local function Attach(unit)
    local plate = GetPlate(unit)
    if not plate then return end
    local f = plate.TankTrafficLightFrame
    if not f then
        f = CreateLight(plate)
        plate.TankTrafficLightFrame = f
    end
    local okGuid, guid = Read(UnitGUID, unit)
    guid = okGuid and guid or nil
    if f.unit ~= unit or f.guid ~= guid then
        -- This frame now belongs to a different mob: forget the old color.
        f.unit, f.guid, f.state = unit, guid, nil
        f.pulse:Stop()
        f:SetAlpha(1)
    end
    local side = TankTrafficLightDB.side
    Layout(f, side == "top")
    f:ClearAllPoints()
    if side == "top" then
        -- Anchor to the health bar, not the name text: Plater can hide or
        -- un-anchor its name label, which would leave the light with no position.
        f:SetPoint("BOTTOM", AnchorTarget(plate), "TOP", 0, TankTrafficLightDB.topOffset or 4)
    elseif side == "right" then
        f:SetPoint("LEFT", AnchorTarget(plate), "RIGHT", 4, 0)
    else
        f:SetPoint("RIGHT", AnchorTarget(plate), "LEFT", -4, 0)
    end
    f:SetScale(TankTrafficLightDB.lightScale or 1)
    lights[unit] = f
    return f
end

local function Detach(unit)
    local f = lights[unit]
    if f and f.unit == unit then
        f.pulse:Stop()
        f:Hide()
        f.unit, f.guid, f.state = nil, nil, nil
    end
    lights[unit] = nil
end

-- Which "Show in" setting applies to where the player is right now.
local ZONE_SETTING = {
    none = "showWorld",
    scenario = "showWorld",
    party = "showDungeon",
    raid = "showRaid",
    pvp = "showPvP",
    arena = "showPvP",
}

local function ZoneAllowed()
    local ok, inInstance, instanceType = S.Call(IsInInstance)
    if not ok or not S.Public(instanceType) then return true end
    local key = ZONE_SETTING[inInstance and instanceType or "none"] or "showWorld"
    return TankTrafficLightDB[key] and true or false
end

local function ShouldRun()
    if not TankTrafficLightDB.lights then return false end
    if not ZoneAllowed() then return false end
    if TankTrafficLightDB.tankOnly then
        local ok, role = Read(UnitGroupRolesAssigned, "player")
        if ok and role ~= "TANK" and role ~= "NONE" then return false end
    end
    return true
end

function L.Update(unit)
    local f = Attach(unit)
    if not f then return end
    local state, why
    if demoMode then
        state = ORDER[(demoStep % 3) + 1]
    elseif ShouldRun() then
        state, why = L.StateFor(unit)
        if state ~= f.state then Trace(unit, f.state, state, why) end
    end
    f.state = state
    if state then
        Paint(f, state)
        f:Show()
    else
        f.pulse:Stop()
        f:Hide()
    end
end

function L.UpdateAll()
    for i = 1, 40 do
        local unit = "nameplate" .. i
        local ok, exists = Read(UnitExists, unit)
        if ok and exists then L.Update(unit) else Detach(unit) end
    end
end

function L.SetDemo(on)
    demoMode = on
    L.UpdateAll()
end

function L.IsDemo() return demoMode end

-- Prints, for every visible nameplate, what the light decided and why.
function L.Explain(say)
    say("lights=" .. tostring(TankTrafficLightDB.lights) .. " tankOnly=" .. tostring(TankTrafficLightDB.tankOnly)
        .. " shouldRun=" .. tostring(ShouldRun()) .. " demo=" .. tostring(demoMode))
    local count = 0
    for i = 1, 40 do
        local unit = "nameplate" .. i
        local ok, exists = Read(UnitExists, unit)
        if ok and exists then
            count = count + 1
            local okRun, state, why = pcall(L.StateFor, unit)
            local plate = GetPlate(unit)
            local f = plate and plate.TankTrafficLightFrame
            say(string.format("%s %s: %s | %s | plate=%s light=%s shown=%s",
                unit, S.Describe((select(2, Read(UnitName, unit)))),
                okRun and tostring(state or "no light") or "ERROR",
                okRun and tostring(why) or tostring(state),
                tostring(plate ~= nil), tostring(f ~= nil), tostring(f ~= nil and f:IsShown())))
            local okUpd, err = pcall(L.Update, unit)
            if not okUpd then say("  Update ERROR: " .. tostring(err)) end
        end
    end
    say("visible nameplates: " .. count)
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
events:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
events:RegisterEvent("UNIT_TARGET")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_ROLES_ASSIGNED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:SetScript("OnEvent", function(_, event, unit)
    if not TankTrafficLightDB then return end
    if event == "NAME_PLATE_UNIT_ADDED" then
        L.Update(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        Detach(unit)
    elseif type(unit) == "string" and unit:find("^nameplate") then
        L.Update(unit)
    else
        L.UpdateAll()
    end
end)

-- Safety net: targets and threat can shift without an event we see,
-- so refresh a few times a second while in combat (or demoing).
local elapsedTotal, demoElapsed = 0, 0
events:SetScript("OnUpdate", function(_, elapsed)
    if not TankTrafficLightDB then return end
    if demoMode then
        demoElapsed = demoElapsed + elapsed
        if demoElapsed >= 1 then
            demoElapsed = 0
            demoStep = demoStep + 1
            L.UpdateAll()
        end
        return
    end
    if not InCombatLockdown() then return end
    elapsedTotal = elapsedTotal + elapsed
    if elapsedTotal >= 0.25 then
        elapsedTotal = 0
        L.UpdateAll()
    end
end)
