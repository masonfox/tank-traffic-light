-- luacheck config for Tank Traffic Light (WoW client runs Lua 5.1).
-- Globals list: everything `luacheck --std lua51 --no-config *.lua` reported as
-- undefined in the root addon files (W111/W112/W113), sorted by kind below.

std = "lua51"
max_line_length = 126 -- the longest existing line (Probe.lua); not reflowing code for lint

-- Dirs CI tooling may create inside the checkout (gh-actions-lua / -luarocks, local rock trees).
exclude_files = {
    ".lua/**/*.lua",
    ".luarocks/**/*.lua",
    ".lua_modules/**/*.lua",
    "lua_modules/**/*.lua",
    ".install/**/*.lua",
    "node_modules/**/*.lua",
}

-- Written by the addon: SavedVariables and slash command registration.
globals = {
    "TankTrafficLightDB",
    "SLASH_TANKTRAFFICLIGHT1",
    "SLASH_TANKTRAFFICLIGHT2",
    "SlashCmdList",
}

-- Read-only WoW API and constants.
read_globals = {
    -- Units, threat and group
    "UnitAffectingCombat",
    "UnitCanAttack",
    "UnitClass",
    "UnitDetailedThreatSituation",
    "UnitExists",
    "UnitGroupRolesAssigned",
    "UnitGUID",
    "UnitInParty",
    "UnitInRaid",
    "UnitIsUnit",
    "UnitName",
    "UnitThreatSituation",
    "GetPartyAssignment",

    -- Game state, time, sound
    "GetTime",
    "InCombatLockdown",
    "IsInInstance",
    "PlaySound",
    "SOUNDKIT",
    "date",
    "issecretvalue",
    "C_NamePlate",
    "C_Timer",

    -- Frames and UI
    "BackdropTemplateMixin",
    "CreateColor",
    "CreateFrame",
    "HideUIPanel",
    "STANDARD_TEXT_FONT",
    "UIParent",
    "UISpecialFrames",

    -- Options registration (Options.lua): modern Settings API, legacy InterfaceOptions
    "Settings",
    "SettingsPanel",
    "InterfaceOptionsFrame",
    "InterfaceOptions_AddCategory",
}

-- Tests and dev scripts run under plain Lua 5.1 with busted, not in the client.
files["spec/"] = { std = "lua51+busted" }
files["scripts/"] = { std = "lua51+busted" }
