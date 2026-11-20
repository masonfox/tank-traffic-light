-- Mob list: one fixed panel listing every nameplate mob the lights have classified
-- RED, YELLOW or GREEN. It never classifies mobs itself: Lights.lua calls
-- M.OnState after classifying a nameplate and M.Remove when one goes away.
-- Display-only: rows never take the mouse and never target anything.

local _, TT = ...
local S = TT.Safe
local M = {}
TT.MobList = M

local WIDTH = 200
local HEADER_H = 18
local ROW_H = 14
local PAD = 3
local MARKER = 8
local DEFAULT_POS = { "TOPLEFT", "LEFT", 40, 120 } -- point, UIParent relative point, x, y

local rows = {}        -- unit token -> { guid, state, since }
local entryCounter = 0 -- bumps each time a mob enters a state, for stable ordering
local dirty = true
local demo = false

local DEMO_ROWS = {
    { state = "red", name = "Defias Trapper", target = "Heidi" },
    { state = "red", name = "Defias Smuggler", target = "Loki" },
    { state = "yellow", name = "Goretusk" },
    { state = "green", name = "Defias Pillager" },
    { state = "green", name = "Riverpaw Gnoll" },
    { state = "green", name = "Murloc Raider" },
}

---------------------------------------------------------------------------
-- State from Lights.lua
---------------------------------------------------------------------------

local function Rank(state)
    local st = TT.States -- defined by Lights.lua; read at call time only
    if state == st.RED then return 1 end
    if state == st.YELLOW then return 2 end
    if state == st.GREEN then return 3 end
end

function M.OnState(unit, guid, state)
    if not Rank(state) then -- GREY or no light: not listed
        M.Remove(unit)
        return
    end
    local row = rows[unit]
    if not row or row.guid ~= guid then
        entryCounter = entryCounter + 1
        rows[unit] = { guid = guid, state = state, since = entryCounter }
    elseif row.state ~= state then
        entryCounter = entryCounter + 1
        row.state, row.since = state, entryCounter
    end
    dirty = true -- even without a state change: a RED mob's target can change
end

function M.Remove(unit)
    if rows[unit] then
        rows[unit] = nil
        dirty = true
    end
end

function M.SetDemo(on)
    demo = on and true or false
    dirty = true
end

-- Settings that change the list without reclassifying (lock, minimize, rows, palette).
function M.Refresh()
    dirty = true
end

---------------------------------------------------------------------------
-- Guarded reads
---------------------------------------------------------------------------

local function Read(fn, ...)
    local ok, a = S.Call(fn, ...)
    if ok and S.Public(a) then return true, a end
    return false, nil
end

local function NameOf(unit)
    local ok, name = Read(UnitName, unit)
    if ok and type(name) == "string" and name ~= "" then return name end
    return "?"
end

local function Hex(c)
    return string.format("ff%02x%02x%02x", math.floor(c[1] * 255 + 0.5),
        math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

---------------------------------------------------------------------------
-- Frame
---------------------------------------------------------------------------

local frame = CreateFrame("Frame", nil, UIParent)
frame:SetSize(WIDTH, HEADER_H)
frame:SetFrameStrata("MEDIUM")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(false) -- the row area never takes the mouse
frame:Hide()

local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0, 0, 0, 0.5)

local header = CreateFrame("Frame", nil, frame)
header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
header:SetHeight(HEADER_H)
header:RegisterForDrag("LeftButton")
header:EnableMouse(false)

local headerBg = header:CreateTexture(nil, "BACKGROUND")
headerBg:SetAllPoints()
headerBg:SetColorTexture(0, 0, 0, 0.45)

local title = header:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
title:SetPoint("LEFT", header, "LEFT", 5, 0)
title:SetText("Threat")

local minButton = CreateFrame("Button", nil, header)
minButton:SetSize(16, 16)
minButton:SetPoint("RIGHT", header, "RIGHT", -2, 0)
minButton:SetNormalFontObject("GameFontHighlight")
minButton:SetHighlightFontObject("GameFontNormal")
minButton:SetText("-")
minButton:SetScript("OnClick", function()
    TT.Settings.Set("listMinimized", not TankTrafficLightDB.listMinimized)
end)

local counts = header:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
counts:SetPoint("RIGHT", minButton, "LEFT", -4, 0)

header:SetScript("OnDragStart", function()
    if TankTrafficLightDB and not TankTrafficLightDB.listLocked then frame:StartMoving() end
end)
header:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    -- Save as TOPLEFT so minimizing never moves the header.
    local left, top = frame:GetLeft(), frame:GetTop()
    if left and top and TankTrafficLightDB then
        TankTrafficLightDB.listPos = { "TOPLEFT", "BOTTOMLEFT", left, top }
    end
    M.ApplyPosition()
end)

function M.ApplyPosition()
    local pos = TankTrafficLightDB and TankTrafficLightDB.listPos
    if type(pos) ~= "table" or #pos < 4 then pos = DEFAULT_POS end
    frame:ClearAllPoints()
    frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

-- Pooled lines: marker texture plus text. Created on demand, never destroyed.
local lines = {}

local function Line(i)
    local line = lines[i]
    if line then return line end
    line = {}
    local y = -(HEADER_H + PAD + (i - 1) * ROW_H) - ROW_H / 2
    line.marker = frame:CreateTexture(nil, "ARTWORK")
    line.marker:SetSize(MARKER, MARKER)
    line.marker:SetColorTexture(1, 1, 1, 1)
    line.marker:SetPoint("LEFT", frame, "TOPLEFT", 6, y)
    line.text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    line.text:SetJustifyH("LEFT")
    line.text:SetWordWrap(false)
    line.text:SetPoint("LEFT", frame, "TOPLEFT", 6 + MARKER + 5, y)
    line.text:SetWidth(WIDTH - (6 + MARKER + 5) - 6) -- fixed width: long text truncates
    lines[i] = line
    return line
end

local function ShowLine(i, color, text)
    local line = Line(i)
    if color then
        line.marker:SetVertexColor(color[1], color[2], color[3], 1)
        line.marker:Show()
    else
        line.marker:Hide()
    end
    line.text:SetText(text)
    line.text:Show()
end

---------------------------------------------------------------------------
-- Redraw (coalesced: at most once per frame, only when something changed)
---------------------------------------------------------------------------

local function Collect()
    local list = {}
    if demo then
        for i, d in ipairs(DEMO_ROWS) do
            list[#list + 1] = { state = d.state, since = i, name = d.name, target = d.target }
        end
        return list
    end
    for unit, row in pairs(rows) do
        if Rank(row.state) then
            list[#list + 1] = { unit = unit, state = row.state, since = row.since }
        end
    end
    table.sort(list, function(a, b)
        local ra, rb = Rank(a.state), Rank(b.state)
        if ra ~= rb then return ra < rb end
        return a.since < b.since
    end)
    return list
end

local function RowText(item)
    local st = TT.States
    local name = item.name or NameOf(item.unit)
    if item.state == st.RED then
        return name .. " -> " .. (item.target or NameOf(item.unit .. "target"))
    elseif item.state == st.YELLOW then
        return name .. " (slipping)"
    end
    return name
end

local function Redraw()
    local db = TankTrafficLightDB
    local list = Collect()
    local st = TT.States
    local colors = TT.Lights.Colors()

    local n = { [st.RED] = 0, [st.YELLOW] = 0, [st.GREEN] = 0 }
    for _, item in ipairs(list) do n[item.state] = n[item.state] + 1 end
    counts:SetText(string.format("|c%sR%d|r |c%sY%d|r |c%sG%d|r",
        Hex(colors[st.RED]), n[st.RED], Hex(colors[st.YELLOW]), n[st.YELLOW],
        Hex(colors[st.GREEN]), n[st.GREEN]))

    local locked = db.listLocked and true or false
    -- While the options window is open, stay visible so list settings show their effect.
    local optionsOpen = TT.IsOptionsShown and TT.IsOptionsShown()
    local shown = db.mobList and (#list > 0 or not locked or demo or optionsOpen)
    header:EnableMouse(not locked) -- drag only when unlocked; the button always works
    minButton:SetText(db.listMinimized and "+" or "-")

    local used = 0
    if not db.listMinimized then
        local cap = math.floor(tonumber(db.listRows) or 8)
        for i = 1, math.min(#list, cap) do
            local item = list[i]
            used = used + 1
            ShowLine(used, colors[item.state], RowText(item))
        end
        if #list > cap then
            used = used + 1
            ShowLine(used, nil, string.format("+%d more", #list - cap))
        elseif #list == 0 and not locked then
            used = used + 1
            ShowLine(used, nil, "Drag the header to move")
        end
    end
    for i = used + 1, #lines do
        lines[i].marker:Hide()
        lines[i].text:Hide()
    end

    frame:SetHeight(HEADER_H + (used > 0 and (PAD * 2 + used * ROW_H) or 0))
    if shown then frame:Show() else frame:Hide() end
end

-- Separate always-shown driver: the list frame's own OnUpdate would stop while it is hidden.
local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function()
    if not dirty or not TankTrafficLightDB then return end
    dirty = false
    local ok, err = pcall(Redraw)
    if not ok and TankTrafficLightDB.trace then TT.Print("mob list error: " .. tostring(err)) end
end)
