local _, TT = ...

-- Built-in alert sounds: choice value -> SOUNDKIT name (looked up at play time;
-- a name missing on this client means silence). Shared by both alert sounds.
TT.SOUNDS = {
    ping = "IG_PLAYER_INVITE",
    whisper = "TELL_MESSAGE",
    bell = "ALARM_CLOCK_WARNING_2",
    alarm = "ALARM_CLOCK_WARNING_3",
    readycheck = "READY_CHECK",
    raidwarning = "RAID_WARNING",
}
local SOUND_VALUES = { "ping", "whisper", "bell", "alarm", "readycheck", "raidwarning" }
local SOUND_LABELS = { ping = "Ping", whisper = "Whisper", bell = "Bell", alarm = "Alarm",
    readycheck = "Ready check", raidwarning = "Raid warning" }

-- onChange for sound choices: play the newly chosen sound once as a preview.
local function PreviewSound(value)
    if TT.Alerts and TT.Alerts.PlayChoice then TT.Alerts.PlayChoice(value) end
end

local Settings = {
    Sections = { "Traffic lights", "Mob list", "Alerts", "Show in", "Diagnostics" },
    Entries = {
        { key = "lights", kind = "toggle", label = "Show traffic lights on enemy nameplates",
            section = "Traffic lights", slash = { "lights" } },
        { key = "tankOnly", kind = "toggle", label = "Only when my role is tank (or no role set)",
            section = "Traffic lights", slash = { "tankonly" } },
        { key = "pulse", kind = "toggle", label = "Pulse the yellow light when aggro is slipping",
            section = "Traffic lights", slash = { "pulse" } },
        { key = "showGrey", kind = "toggle", label = "Grey light on mobs that aren't yours",
            section = "Traffic lights", slash = { "grey", "gray" } },
        { key = "greyAlpha", kind = "number", label = "Grey light opacity", name = "grey light opacity",
            section = "Traffic lights", slash = { "greyalpha", "grayalpha" }, min = 0.1, max = 1 },
        { key = "palette", kind = "choice", label = "Colors",
            section = "Traffic lights", slash = { "colors" }, values = { "classic", "colorblind" },
            labels = { classic = "Classic", colorblind = "Colorblind" } },
        { key = "side", kind = "choice", label = "Placement on the nameplate",
            section = "Traffic lights", slash = { "side" }, values = { "left", "right", "top", "bottom" },
            labels = { left = "Left", right = "Right", top = "Top", bottom = "Bottom" } },
        { key = "align", kind = "choice", label = "Alignment",
            section = "Traffic lights", slash = { "align" }, values = { "left", "middle", "right" },
            labels = { left = "Left", middle = "Middle", right = "Right" } },
        { key = "lightScale", kind = "number", label = "Size", name = "size",
            section = "Traffic lights", slash = { "scale", "size" }, min = 0.5, max = 3 },
        { key = "gap", kind = "number", label = "Gap", name = "gap",
            section = "Traffic lights", slash = { "gap", "height" }, min = 0, max = 60 },
        { key = "mobList", kind = "toggle", label = "Show the mob list",
            section = "Mob list", slash = { "list" } },
        { key = "listMinimized", kind = "toggle", label = "Minimize the mob list",
            section = "Mob list", slash = { "listmin" } },
        { key = "listLocked", kind = "toggle", label = "Lock the mob list",
            section = "Mob list", slash = { "listlock" } },
        { key = "listRows", kind = "number", label = "Maximum rows", name = "maximum rows",
            section = "Mob list", slash = { "listrows" }, min = 3, max = 20, integer = true },
        { key = "slipSound", kind = "toggle", label = "Sound when aggro starts slipping",
            section = "Alerts", slash = { "slipsound" } },
        { key = "slipSoundName", kind = "choice", label = "Slipping sound",
            section = "Alerts", slash = { "slipsoundname" }, values = SOUND_VALUES, labels = SOUND_LABELS,
            onChange = PreviewSound },
        { key = "healerSound", kind = "toggle", label = "Sound when a mob attacks a healer",
            section = "Alerts", slash = { "healersound" } },
        { key = "healerSoundName", kind = "choice", label = "Healer sound",
            section = "Alerts", slash = { "healersoundname" }, values = SOUND_VALUES, labels = SOUND_LABELS,
            onChange = PreviewSound },
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
    if not value or value < entry.min or value > entry.max then return nil end
    if entry.integer and value % 1 ~= 0 then return nil end
    return value
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
            return false, string.format("%s must be %s from %s to %s (now %s)",
                entry.name, entry.integer and "a whole number" or "a number",
                entry.min, entry.max, tostring(TankTrafficLightDB[key]))
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
    TT.MobList.Refresh() -- lock, minimize, row cap and palette change the list without reclassifying
    TT.RefreshOptions()
    if entry.onChange then pcall(entry.onChange, value) end -- optional per-entry hook (e.g. sound preview)
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
