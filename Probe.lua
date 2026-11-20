local _, TT = ...
local S = TT.Safe
local P = {}
TT.Probe = P

local MAX_LOG_LINES = 400

local function NameplateUnits()
    local units = {}
    for i = 1, 40 do
        local unit = "nameplate" .. i
        local ok, exists = pcall(UnitExists, unit)
        if ok and S.Public(exists) and exists then units[#units + 1] = unit end
    end
    return units
end

-- Runs every API Tank Traffic Light would rely on against every visible nameplate and
-- records which return usable values, which are SECRET, and which error.
function P.Run(reason)
    local lines = {}
    local function add(text) lines[#lines + 1] = text end

    add(string.format("=== Probe (%s) at %s, inCombat=%s ===", reason or "manual",
        date("%H:%M:%S"), S.Probe(InCombatLockdown)))
    add("API present: issecretvalue=" .. tostring(type(issecretvalue) == "function")
        .. " C_NamePlate=" .. tostring(type(C_NamePlate) == "table")
        .. " UnitThreatSituation=" .. tostring(type(UnitThreatSituation) == "function")
        .. " UnitDetailedThreatSituation=" .. tostring(type(UnitDetailedThreatSituation) == "function")
        .. " UnitGroupRolesAssigned=" .. tostring(type(UnitGroupRolesAssigned) == "function"))
    add("player role: " .. S.Probe(UnitGroupRolesAssigned, "player"))

    local units = NameplateUnits()
    add("visible nameplates: " .. #units)

    for _, unit in ipairs(units) do
        local target = unit .. "target"
        add("-- " .. unit .. " name=" .. S.Probe(UnitName, unit))
        add("   canAttack=" .. S.Probe(UnitCanAttack, "player", unit)
            .. " | inCombat=" .. S.Probe(UnitAffectingCombat, unit)
            .. " | guid=" .. S.Probe(UnitGUID, unit))
        add("   threatSituation=" .. S.Probe(UnitThreatSituation, "player", unit))
        add("   detailedThreat(isTanking,status,scaled%,raw%,value)=" .. S.Probe(UnitDetailedThreatSituation, "player", unit))
        add("   target exists=" .. S.Probe(UnitExists, target)
            .. " | name=" .. S.Probe(UnitName, target)
            .. " | isPlayer=" .. S.Probe(UnitIsUnit, target, "player"))
        add("   target role=" .. S.Probe(UnitGroupRolesAssigned, target)
            .. " | class=" .. S.Probe(UnitClass, target)
            .. " | mainTank=" .. S.Probe(GetPartyAssignment, "MAINTANK", target))
        local okHealer, healer, healerWhy = pcall(TT.Alerts and TT.Alerts.IsHealer or error, target)
        local okCo, coTank, coWhy = pcall(TT.Lights and TT.Lights.IsCoTank or error, target)
        add("   target healer=" .. (okHealer and (tostring(healer) .. " (" .. tostring(healerWhy) .. ")") or "ERROR")
            .. " | coTank=" .. (okCo and (tostring(coTank) .. (coWhy and (" (" .. coWhy .. ")") or "")) or "ERROR"))
        local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
        add("   plate frame=" .. tostring(plate ~= nil)
            .. " | UnitFrame=" .. tostring(plate ~= nil and plate.UnitFrame ~= nil)
            .. " | Plater=" .. tostring(plate ~= nil and plate.unitFrame ~= nil))
    end

    local log = TankTrafficLightDB.probeLog
    for _, line in ipairs(lines) do
        log[#log + 1] = line
        print("|cff66ccffTank Traffic Light|r " .. line)
    end
    while #log > MAX_LOG_LINES do table.remove(log, 1) end
end

-- Auto mode: probe a few seconds into each combat so values are taken mid-fight.
local autoFrame = CreateFrame("Frame")
autoFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" and TankTrafficLightDB.autoProbe then
        C_Timer.After(3, function()
            if InCombatLockdown() then P.Run("auto, 3s into combat") end
        end)
    end
end)
autoFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
