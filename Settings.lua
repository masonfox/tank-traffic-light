local _, TT = ...
local Settings = {
    Sections = { "Traffic lights", "Alerts", "Show in", "Diagnostics" },
    Entries = {
        { key = "lights", kind = "toggle", label = "Show traffic lights on enemy nameplates",
            section = "Traffic lights", slash = { "lights" } },
        { key = "tankOnly", kind = "toggle", label = "Only when my role is tank (or no role set)",
            section = "Traffic lights", slash = { "tankonly" } },
        { key = "pulse", kind = "toggle", label = "Pulse the yellow light when aggro is slipping",
            section = "Traffic lights", slash = { "pulse" } },
        { key = "showGrey", kind = "toggle", label = "Grey light on mobs that aren't yours",
            section = "Traffic lights", slash = { "grey", "gray" } },
        { key = "palette", kind = "choice", label = "Colors",
            section = "Traffic lights", slash = { "colors" }, values = { "classic", "colorblind" },
            labels = { classic = "Classic", colorblind = "Colorblind" } },
        { key = "side", kind = "choice", label = "Placement on the nameplate",
            section = "Traffic lights", slash = { "side" }, values = { "left", "right", "top" },
            labels = { left = "Left", right = "Right", top = "Top" } },
        { key = "lightScale", kind = "number", label = "Size", name = "size",
            section = "Traffic lights", slash = { "scale", "size" }, min = 0.5, max = 3 },
        { key = "topOffset", kind = "number", label = "Top placement height", name = "top placement height",
            section = "Traffic lights", slash = { "height" }, min = 0, max = 60 },
        { key = "slipSound", kind = "toggle", label = "Sound when aggro starts slipping",
            section = "Alerts", slash = { "slipsound" } },
        { key = "healerSound", kind = "toggle", label = "Sound when a mob attacks a healer",
            section = "Alerts", slash = { "healersound" } },
        { key = "healerFlash", kind = "toggle", label = "Flash the screen when a mob attacks a healer",
            section = "Alerts", slash = { "flash" } },
        { key = "showWorld", kind = "toggle", label = "Open world",
            section = "Show in", slash = { "world" } },
        { key = "showDungeon", kind = "toggle", label = "Dungeons",
            section = "Show in", slash = { "dungeon" } },
        { key = "showRaid", kind = "toggle", label = "Raids",
            section = "Show in", slash = { "raid" } },
        { key = "showPvP", kind = "toggle", label = "Battlegrounds and arenas",
            section = "Show in", slash = { "pvp" } },
        { key = "trace", kind = "toggle", label = "Print every light change to chat (/ttl trace)",
            section = "Diagnostics", slash = { "trace" } },
        { key = "autoProbe", kind = "toggle", label = "Record an API probe 3s into every pull",
            section = "Diagnostics", slash = { "auto" } },
    },
    ByKey = {},
    BySlash = {},
}
TT.Settings = Settings

for _, entry in ipairs(Settings.Entries) do
    Settings.ByKey[entry.key] = entry
    for _, command in ipairs(entry.slash) do
        Settings.BySlash[command] = entry
    end
end

local function ParseNumber(entry, raw)
    if type(raw) == "string" then raw = raw:gsub(",", ".") end
    local value = tonumber(raw)
    if value and value >= entry.min and value <= entry.max then return value end
end

function Settings.Set(key, raw)
    local entry = Settings.ByKey[key]
    if not entry then return false, "unknown setting: " .. tostring(key) end

    local value, display
    if entry.kind == "toggle" then
        if type(raw) ~= "boolean" then return false, entry.label .. " requires a boolean" end
        value, display = raw, raw and "ON" or "OFF"
    elseif entry.kind == "number" then
        value = ParseNumber(entry, raw)
        if value == nil then
            return false, string.format("%s must be a number from %s to %s (now %s)",
                entry.name, entry.min, entry.max, tostring(TankTrafficLightDB[key]))
        end
        display = value
    elseif entry.kind == "choice" then
        display = entry.labels[raw]
        if not display then
            return false, entry.label .. " must be one of: " .. table.concat(entry.values, ", ")
        end
        value = raw
    end

    TankTrafficLightDB[key] = value
    TT.Lights.UpdateAll()
    TT.RefreshOptions()
    return true, entry.label .. ": " .. display
end

function Settings.Cycle(key)
    local entry = Settings.ByKey[key]
    local values = entry.values
    local current = TankTrafficLightDB[key]
    for i, value in ipairs(values) do
        if value == current then
            return Settings.Set(key, values[i % #values + 1])
        end
    end
    return Settings.Set(key, values[1])
end

function Settings.CheckDefaults()
    for _, entry in ipairs(Settings.Entries) do
        if TT.DEFAULTS[entry.key] == nil then
            TT.Print("setting has no default: " .. entry.key)
        end
    end
end
