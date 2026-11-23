local ADDON_NAME, TT = ...
local Settings = TT.Settings

function TT.Print(text) print("|cff66ccffTank Traffic Light|r " .. text) end
local Say = TT.Print

TT.DEFAULTS = {
    lights = true,
    tankOnly = false,
    pulse = true,
    showGrey = true,
    greyAlpha = 0.45,
    palette = "classic",
    side = "left",
    align = "middle",
    lightScale = 1,
    gap = 4,
    showWorld = true,
    showDungeon = true,
    showRaid = true,
    showPvP = false,
    slipSound = true,
    slipSoundName = "ping",
    healerSound = true,
    healerSoundName = "raidwarning",
    healerFlash = true,
    trace = false,
    autoProbe = false,
}

-- Earlier versions saved a top-only height; it becomes the gap for every placement.
-- Runs before ApplyDefaults, or the default gap would replace the saved height.
-- The removed mob list's settings and position are dropped.
local function MigrateSettings()
    local db = TankTrafficLightDB
    if db.gap == nil and db.topOffset ~= nil then db.gap = db.topOffset end
    db.topOffset = nil
    db.mobList, db.listMinimized, db.listLocked, db.listRows, db.listPos = nil, nil, nil, nil, nil
end

local function ApplyDefaults()
    for k, v in pairs(TT.DEFAULTS) do
        if TankTrafficLightDB[k] == nil then TankTrafficLightDB[k] = v end
    end
end

function TT.ResetAll()
    for k, v in pairs(TT.DEFAULTS) do TankTrafficLightDB[k] = v end
end

function TT.ResetSettings()
    TT.ResetAll()
    TT.Lights.UpdateAll()
    TT.RefreshOptions()
    Say("settings reset")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
    if name ~= ADDON_NAME then return end
    TankTrafficLightDB = TankTrafficLightDB or {}
    TankTrafficLightDB.probeLog = TankTrafficLightDB.probeLog or {}
    TankTrafficLightDB.traceLog = TankTrafficLightDB.traceLog or {}
    MigrateSettings()
    ApplyDefaults()
    Settings.CheckDefaults()
    self:UnregisterEvent("ADDON_LOADED")
end)

local function RunSetting(entry, arg)
    local key = entry.key
    if entry.kind == "toggle" then
        return Settings.Set(key, not TankTrafficLightDB[key])
    elseif entry.kind == "choice" and arg == "" then
        return Settings.Cycle(key)
    end
    return Settings.Set(key, arg)
end

local function PrintHelp()
    Say("commands:")
    for _, section in ipairs(Settings.Sections) do
        local commands = {}
        for _, entry in ipairs(Settings.Entries) do
            if entry.section == section then
                local usage = table.concat(entry.slash, "|")
                if entry.kind == "number" then
                    usage = usage .. string.format(" <%s-%s>", entry.min, entry.max)
                elseif entry.kind == "choice" then
                    usage = usage .. " [" .. table.concat(entry.values, "|") .. "]"
                end
                commands[#commands + 1] = usage
            end
        end
        if section == "Alerts" then
            commands[#commands + 1] = "testalert"
        end
        if section == "Diagnostics" then
            commands[#commands + 1] = "why"
            commands[#commands + 1] = "probe"
            commands[#commands + 1] = "clear"
        end
        Say(section .. ": /ttl " .. table.concat(commands, ", "))
    end
    Say("Actions: /ttl (or options|config) - toggle the options window, reset")
end

SLASH_TANKTRAFFICLIGHT1 = "/tanktrafficlight"
SLASH_TANKTRAFFICLIGHT2 = "/ttl"
SlashCmdList.TANKTRAFFICLIGHT = function(msg)
    local cmd, arg = (msg or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
    local entry = Settings.BySlash[cmd]
    if entry then
        local _, message = RunSetting(entry, arg)
        Say(message)
    elseif cmd == "" or cmd == "options" or cmd == "config" then
        TT.ToggleOptions()
    elseif cmd == "probe" then
        TT.Probe.Run("manual")
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
    elseif cmd == "testalert" then
        TT.Alerts.Test()
        Say("testing alerts: slipping sound, then healer sound and flash")
    elseif cmd == "reset" then
        TT.ResetSettings()
    else
        PrintHelp()
    end
end
