-- Sample nameplate with a sample traffic light, shown across the top of the options window.
-- It is drawn from plain textures and font strings: no unit, nameplate or threat API is used,
-- and it never goes through evaluation, so it can't trigger alerts, trace entries or list rows.

local _, TT = ...
local P = {}
TT.Preview = P

local ZOOM = 1.5            -- the whole sample plate is drawn bigger so it's readable
local BAR_W, BAR_H = 120, 10
local CAST_H = 9
local AURA_SIZE, AURA_GAP = 14, 2
local STEP_SECONDS = 1

-- Fixed sample auras: icon path plus border color (debuffs colored by type, buffs dark).
local AURAS = {
    { icon = "Interface\\Icons\\Ability_Warrior_Sunder",          border = { 0.80, 0.00, 0.00 } }, -- physical
    { icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",     border = { 0.20, 0.60, 1.00 } }, -- magic
    { icon = "Interface\\Icons\\Ability_ThunderClap",             border = { 0.80, 0.00, 0.00 } },
    { icon = "Interface\\Icons\\Spell_Nature_NullifyPoison",      border = { 0.00, 0.60, 0.00 } }, -- poison
    { icon = "Interface\\Icons\\Spell_Holy_PowerWordShield",      border = { 0.10, 0.10, 0.10 } }, -- buff
}

local strip, light, bar
local step, elapsed = 1, 0

-- Lamp states the sample cycles through, in order; GREY only while the grey light is on.
local function Sequence()
    local S = TT.Lights.STATES
    if TankTrafficLightDB.showGrey then
        return { S.RED, S.YELLOW, S.GREEN, S.GREY }
    end
    return { S.RED, S.YELLOW, S.GREEN }
end

local function CurrentState()
    local seq = Sequence()
    if step > #seq then step = 1 end
    return seq[step]
end

local function NewBar(parent, width, height, value, r, g, b)
    local border = parent:CreateTexture(nil, "BACKGROUND")
    local sb = CreateFrame("StatusBar", nil, parent)
    sb:SetSize(width, height)
    sb:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    sb:SetStatusBarColor(r, g, b)
    sb:SetMinMaxValues(0, 1)
    sb:SetValue(value)
    local bg = sb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    border:SetColorTexture(0, 0, 0, 1)
    border:SetPoint("TOPLEFT", sb, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", sb, "BOTTOMRIGHT", 1, -1)
    return sb
end

local function BuildPlate(container)
    -- Health bar, slightly below centre so the decorations above it fit the strip.
    bar = NewBar(container, BAR_W, BAR_H, 0.7, 0.85, 0.10, 0.10)
    bar:SetPoint("TOP", container, "CENTER", 0, -11)

    -- Auras directly above the bar, left-aligned like a default plate.
    for i, aura in ipairs(AURAS) do
        local x = (i - 1) * (AURA_SIZE + AURA_GAP)
        local border = container:CreateTexture(nil, "BORDER")
        border:SetSize(AURA_SIZE, AURA_SIZE)
        border:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", x, 2)
        border:SetColorTexture(aura.border[1], aura.border[2], aura.border[3], 1)
        local icon = container:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", border, "TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -1, 1)
        icon:SetTexture(aura.icon)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end

    -- Name and level above the aura row.
    local name = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    name:SetPoint("BOTTOM", bar, "TOP", -8, AURA_SIZE + 4)
    name:SetText("Bonecrusher Brute")
    name:SetTextColor(1, 0.25, 0.2)
    local level = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    level:SetPoint("LEFT", name, "RIGHT", 4, 0)
    level:SetText("60")

    -- Skull raid marker above the name.
    local skull = container:CreateTexture(nil, "OVERLAY")
    skull:SetSize(14, 14)
    skull:SetPoint("BOTTOM", name, "TOP", 0, 1)
    skull:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    skull:SetTexCoord(0.75, 1, 0.25, 0.5)

    -- Cast bar with a spell name directly below the bar.
    local cast = NewBar(container, BAR_W, CAST_H, 0.45, 1.0, 0.7, 0.0)
    cast:SetPoint("TOP", bar, "BOTTOM", 0, -3)
    local spell = cast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    spell:SetPoint("CENTER", cast, "CENTER", 0, 0)
    spell:SetText("Shadow Bolt")
    local spellIcon = container:CreateTexture(nil, "ARTWORK")
    spellIcon:SetSize(CAST_H, CAST_H)
    spellIcon:SetPoint("RIGHT", cast, "LEFT", -2, 0)
    spellIcon:SetTexture("Interface\\Icons\\Spell_Shadow_ShadowBolt")
    spellIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
end

-- Builds the preview inside `parent` (a strip the options window lays out) and returns it.
function P.Create(parent)
    strip = CreateFrame("Frame", nil, parent)
    strip:SetAllPoints(parent)
    if strip.SetClipsChildren then strip:SetClipsChildren(true) end -- a big gap can't spill over the controls

    local container = CreateFrame("Frame", nil, strip)
    container:SetScale(ZOOM)
    container:SetPoint("CENTER", strip, "CENTER", 0, 0)
    container:SetSize(BAR_W * 3, 90)

    BuildPlate(container)
    light = TT.Lights.NewLight(container)

    -- Runs only while the window (and so this strip) is shown: closing it stops the cycle.
    strip:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed < STEP_SECONDS then return end
        elapsed = 0
        step = step % #Sequence() + 1
        TT.Lights.Paint(light, CurrentState())
    end)

    P.Refresh()
    return strip
end

-- Re-place and repaint the sample light from the current settings.
function P.Refresh()
    if not light then return end
    TT.Lights.Place(light, bar)
    light:Show()
    TT.Lights.Paint(light, CurrentState())
end
