-- Sound and on-screen alerts: slipping aggro, and loose mobs on a healer.
-- Alerts never classify mobs themselves: Lights.lua calls A.OnState with the
-- old and new light state of every nameplate it updates.

local _, TT = ...
local S = TT.Safe
local A = {}
TT.Alerts = A

local SLIP_THROTTLE = 2          -- seconds between slipping sounds, across all mobs
local HEALER_THROTTLE = 1.5      -- seconds between mob-on-healer alerts, across all mobs
local HEALER_MOB_THROTTLE = 5    -- seconds before the same mob can alert again

local HEALER_CLASSES = { PRIEST = true, DRUID = true, PALADIN = true, SHAMAN = true }
local GENERIC_TEXT = "Mob on your healer!"

local lastSlip, lastHealer = nil, nil
local mobLastAlert = {}          -- mob GUID -> time of its last healer alert

---------------------------------------------------------------------------
-- Guarded reads
---------------------------------------------------------------------------

local function Read(fn, ...)
    local ok, a = S.Call(fn, ...)
    if ok and S.Public(a) then return true, a end
    return false, nil
end

local function Now()
    local ok, t = Read(GetTime)
    if ok and type(t) == "number" then return t end
end

local function ReadString(fn, ...)
    local ok, value = Read(fn, ...)
    if ok and type(value) == "string" and value ~= "" then return value end
end

---------------------------------------------------------------------------
-- Sounds
---------------------------------------------------------------------------

-- Sound choice (a TT.SOUNDS key) -> SOUNDKIT id, or nil if missing on this client.
local function SoundId(choice)
    local name = TT.SOUNDS and TT.SOUNDS[choice]
    if type(name) ~= "string" then return nil end
    if not S.Public(SOUNDKIT) or type(SOUNDKIT) ~= "table" then return nil end
    local ok, id = pcall(function() return SOUNDKIT[name] end)
    if ok and S.Public(id) and type(id) == "number" then return id end
end

-- Play a sound choice once; a missing sound is silent, never an error.
function A.PlayChoice(choice)
    local ok, id = pcall(SoundId, choice)
    if ok and id then S.Call(PlaySound, id, "Master") end
end
local Play = A.PlayChoice
local function SlipSound() return TankTrafficLightDB.slipSoundName or "ping" end
local function HealerSound() return TankTrafficLightDB.healerSoundName or "raidwarning" end

---------------------------------------------------------------------------
-- Flash: red screen-edge glow plus center text, click-through
---------------------------------------------------------------------------

local FLASH_DEPTH = 80
local FLASH_ALPHA = 0.7
local flash

local function Gradient(tex, orientation, a1, a2)
    tex:SetColorTexture(1, 1, 1, 1)
    tex:SetVertexColor(1, 0, 0, (a1 + a2) / 2) -- solid fallback if no gradient API works
    if CreateColor and tex.SetGradient then
        local ok = pcall(tex.SetGradient, tex, orientation, CreateColor(1, 0, 0, a1), CreateColor(1, 0, 0, a2))
        if ok then return end
    end
    if tex.SetGradientAlpha then
        pcall(tex.SetGradientAlpha, tex, orientation, 1, 0, 0, a1, 1, 0, 0, a2)
    end
end

local function Edge(f, p1, p2, horizontal, a1, a2)
    local tex = f:CreateTexture(nil, "BACKGROUND")
    tex:SetPoint(p1, f, p1)
    tex:SetPoint(p2, f, p2)
    if horizontal then tex:SetWidth(FLASH_DEPTH) else tex:SetHeight(FLASH_DEPTH) end
    Gradient(tex, horizontal and "HORIZONTAL" or "VERTICAL", a1, a2)
end

local function CreateFlash()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetAllPoints(UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:EnableMouse(false)
    f:Hide()

    -- HORIZONTAL gradients run left -> right, VERTICAL bottom -> top.
    Edge(f, "TOPLEFT", "BOTTOMLEFT", true, FLASH_ALPHA, 0)
    Edge(f, "TOPRIGHT", "BOTTOMRIGHT", true, 0, FLASH_ALPHA)
    Edge(f, "TOPLEFT", "TOPRIGHT", false, 0, FLASH_ALPHA)
    Edge(f, "BOTTOMLEFT", "BOTTOMRIGHT", false, FLASH_ALPHA, 0)

    local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    pcall(text.SetFont, text, STANDARD_TEXT_FONT, 32, "THICKOUTLINE")
    text:SetTextColor(1, 0.25, 0.15, 1)
    f.text = text

    -- Hold at full alpha, then fade out; the next alert restarts it.
    local anim = f:CreateAnimationGroup()
    local fade = anim:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0)
    fade:SetStartDelay(0.6)
    fade:SetDuration(1.2)
    anim:SetScript("OnFinished", function() f:Hide() end)
    f.anim = anim
    return f
end

local function ShowFlash(message)
    if not flash then flash = CreateFlash() end
    flash.anim:Stop()
    local okH, height = Read(UIParent.GetHeight, UIParent)
    flash.text:ClearAllPoints()
    flash.text:SetPoint("CENTER", flash, "TOP", 0, -((okH and type(height) == "number" and height or 768) * 0.3))
    flash.text:SetText(message)
    flash:SetAlpha(1)
    flash:Show()
    flash.anim:Play()
end

---------------------------------------------------------------------------
-- Healer identification
---------------------------------------------------------------------------

-- Group member, not the player or pet; HEALER role, or no/unreadable role and a
-- healing class. TANK/DAMAGER rule it out. Returns verdict plus a short reason.
function A.IsHealer(unit)
    local okP, isPlayer = Read(UnitIsUnit, unit, "player")
    if not okP then return false, "player check SECRET" end
    if isPlayer then return false, "is player" end
    local okPet, isPet = Read(UnitIsUnit, unit, "pet")
    if not okPet then return false, "pet check SECRET" end
    if isPet then return false, "is pet" end
    local L = TT.Lights
    if not (L and L.IsGroupMember and L.IsGroupMember(unit)) then return false, "not in group" end

    local okRole, role = Read(UnitGroupRolesAssigned, unit)
    if okRole and role == "HEALER" then return true, "role HEALER" end
    if okRole and (role == "TANK" or role == "DAMAGER") then return false, "role " .. role end

    local okClass, _, classToken = S.Call(UnitClass, unit)
    if okClass and S.Public(classToken) and type(classToken) == "string" then
        if HEALER_CLASSES[classToken] then return true, "no role, class " .. classToken end
        return false, "no role, class " .. classToken
    end
    return false, "no role, class unreadable"
end

---------------------------------------------------------------------------
-- State hook (called by Lights.lua from L.Update, inside pcall)
---------------------------------------------------------------------------

local function HealerText(unit, target)
    local mobName = ReadString(UnitName, unit)
    local healerName = ReadString(UnitName, target)
    if mobName and healerName then return mobName .. " -> " .. healerName end
    return GENERIC_TEXT
end

local function OnHealer(unit, target, now)
    local db = TankTrafficLightDB
    if not (db.healerSound or db.healerFlash) then return end
    local okM, mobGuid = Read(UnitGUID, unit)
    mobGuid = okM and type(mobGuid) == "string" and mobGuid or nil
    if mobGuid and mobLastAlert[mobGuid] and now - mobLastAlert[mobGuid] < HEALER_MOB_THROTTLE then return end
    if lastHealer and now - lastHealer < HEALER_THROTTLE then return end
    lastHealer = now
    if mobGuid then mobLastAlert[mobGuid] = now end
    if db.healerSound then Play(HealerSound()) end
    if db.healerFlash then ShowFlash(HealerText(unit, target)) end
end

function A.OnState(unit, frame, old, new)
    local States = TT.States
    if not States or not frame then return end
    local now = Now()

    -- Slipping: a light turns YELLOW from anything else.
    if new == States.YELLOW and old ~= States.YELLOW and TankTrafficLightDB.slipSound and now then
        if not lastSlip or now - lastSlip >= SLIP_THROTTLE then
            lastSlip = now
            Play(SlipSound())
        end
    end

    -- On a healer: RED and the current target is a healer. A new event is a
    -- change of the (mob, healer) pairing stored on the frame.
    if new ~= States.RED then frame.alertHealerKey = nil return end
    local target = unit .. "target"
    if not A.IsHealer(target) then frame.alertHealerKey = nil return end
    local okG, guid = Read(UnitGUID, target)
    local key = okG and type(guid) == "string" and guid or "?"
    if frame.alertHealerKey == key then return end
    frame.alertHealerKey = key
    if now then OnHealer(unit, target, now) end
end

-- Test: both sounds and the flash, ignoring settings, throttles and gating.
function A.Test()
    pcall(Play, SlipSound())
    local function Second()
        pcall(Play, HealerSound())
        pcall(ShowFlash, "Skeleton -> Priestly (test)")
    end
    if C_Timer and C_Timer.After then
        local ok = pcall(C_Timer.After, 0.7, Second)
        if ok then return end
    end
    Second()
end

-- Per-mob throttle lives only for one fight.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function() mobLastAlert = {} end)
