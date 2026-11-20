local ADDON_NAME, TT = ...

function TT.Print(text) print("|cff66ccffTank Traffic Light|r " .. text) end
local Say = TT.Print

TT.DEFAULTS = {
    lights = true,
    tankOnly = false,
    pulse = true,
    side = "left",
    lightScale = 1,
    topOffset = 4,
    showWorld = true,
    showDungeon = true,
    showRaid = true,
    showPvP = false,
    trace = false,
    autoProbe = false,
}

local function ApplyDefaults()
    for k, v in pairs(TT.DEFAULTS) do
        if TankTrafficLightDB[k] == nil then TankTrafficLightDB[k] = v end
    end
end

function TT.ResetAll()
    for k, v in pairs(TT.DEFAULTS) do TankTrafficLightDB[k] = v end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
    if name ~= ADDON_NAME then return end
    TankTrafficLightDB = TankTrafficLightDB or {}
    TankTrafficLightDB.probeLog = TankTrafficLightDB.probeLog or {}
    TankTrafficLightDB.traceLog = TankTrafficLightDB.traceLog or {}
    ApplyDefaults()
    self:UnregisterEvent("ADDON_LOADED")
end)

local function OnOff(v) return v and "ON" or "OFF" end

SLASH_TANKTRAFFICLIGHT1 = "/tanktrafficlight"
SLASH_TANKTRAFFICLIGHT2 = "/ttl"
SlashCmdList.TANKTRAFFICLIGHT = function(msg)
    local cmd, arg = strsplit(" ", strlower(strtrim(msg or "")), 2)
    if cmd == "" or cmd == "options" or cmd == "config" then
        TT.ToggleOptions()
    elseif cmd == "probe" then
        TT.Probe.Run("manual")
    elseif cmd == "auto" then
        TankTrafficLightDB.autoProbe = not TankTrafficLightDB.autoProbe
        Say("auto probe on combat start: " .. OnOff(TankTrafficLightDB.autoProbe))
    elseif cmd == "clear" then
        TankTrafficLightDB.probeLog = {}
        TankTrafficLightDB.traceLog = {}
        Say("probe and trace logs cleared")
    elseif cmd == "why" then
        TT.Lights.Explain(function(line)
            Say(line)
            local log = TankTrafficLightDB.traceLog
            log[#log + 1] = "WHY " .. line
        end)
    elseif cmd == "trace" then
        TankTrafficLightDB.trace = not TankTrafficLightDB.trace
        Say("print every light color change to chat: " .. OnOff(TankTrafficLightDB.trace)
            .. " (always saved to the log either way)")
    elseif cmd == "lights" then
        TankTrafficLightDB.lights = not TankTrafficLightDB.lights
        TT.Lights.UpdateAll()
        Say("nameplate traffic lights: " .. OnOff(TankTrafficLightDB.lights))
    elseif cmd == "tankonly" then
        TankTrafficLightDB.tankOnly = not TankTrafficLightDB.tankOnly
        TT.Lights.UpdateAll()
        Say("only show lights when in the tank role: " .. OnOff(TankTrafficLightDB.tankOnly))
    elseif cmd == "scale" then
        local n = tonumber(arg)
        if n and n >= 0.5 and n <= 3 then
            TankTrafficLightDB.lightScale = n
            TT.Lights.UpdateAll()
            Say("light scale: " .. n)
        else
            Say("usage: /ttl scale 0.5-3 (now " .. TankTrafficLightDB.lightScale .. ")")
        end
    elseif cmd == "demo" then
        TT.Lights.SetDemo(not TT.Lights.IsDemo())
        Say("demo mode (cycles every visible nameplate): " .. OnOff(TT.Lights.IsDemo()))
    else
        Say("commands:")
        Say("  /ttl - open the options window")
        Say("  /ttl lights | demo | tankonly | scale <0.5-3>")
        Say("  /ttl why - explain each visible light")
        Say("  /ttl trace | probe | auto | clear - diagnostics")
    end
    TT.RefreshOptions()
end
