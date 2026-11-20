-- Tank Traffic Light options window (/ttl, or Options -> AddOns -> Tank Traffic Light).

local _, TT = ...

local PANEL_NAME = "TankTrafficLightOptions"
local PANEL_W, PANEL_H = 400, 586
local BOX_X, BOX_W = 20, 360
local BUTTON_W, BUTTON_GAP = 175, 10
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

local panel
local widgets = { checks = {} }

local function Label(parent, text, template)
    local fs = parent:CreateFontString(nil, "ARTWORK", template or "GameFontHighlight")
    fs:SetJustifyH("LEFT")
    if text then fs:SetText(text) end
    return fs
end

-- Left edge at (x, y) from the parent's top-left, vertically centred on y.
local function Row(region, parent, x, y)
    region:SetPoint("LEFT", parent, "TOPLEFT", x, y)
    return region
end

local function NewBox(title, top, height)
    local box = CreateFrame("Frame", nil, panel, BACKDROP_TEMPLATE)
    box:SetPoint("TOPLEFT", panel, "TOPLEFT", BOX_X, top)
    box:SetSize(BOX_W, height)
    if box.SetBackdrop then
        box:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        box:SetBackdropColor(0.05, 0.05, 0.05, 0.55)
        box:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end
    Label(panel, title, "GameFontNormal"):SetPoint("BOTTOMLEFT", box, "TOPLEFT", 8, 3)
    return box
end

local function NewCheck(parent, text, dbKey, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(26, 26)
    local fs = Label(parent, text)
    fs:SetPoint("LEFT", cb, "RIGHT", 2, 1)
    cb:SetHitRectInsets(0, -(fs:GetStringWidth() + 6), 0, 0) -- label is clickable too
    cb:SetScript("OnClick", function(self)
        TankTrafficLightDB[dbKey] = self:GetChecked() and true or false
        if onChange then onChange() end
        TT.Lights.UpdateAll()
    end)
    cb.Refresh = function(self) self:SetChecked(TankTrafficLightDB[dbKey] and true or false) end
    widgets.checks[#widgets.checks + 1] = cb
    return cb
end

-- Value applied on Enter or focus loss; Esc cancels.
local function NewEditBox(parent, width, onCommit)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(width, 20)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(4)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEscapePressed", function(self) self.cancel = true; self:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    eb:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
        if self.cancel then self.cancel = nil else onCommit(self:GetText()) end
        TT.RefreshOptions()
    end)
    return eb
end

local function NewButton(text, column, top, onClick)
    local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    b:SetSize(BUTTON_W, 22)
    b:SetPoint("TOPLEFT", panel, "TOPLEFT", BOX_X + (column - 1) * (BUTTON_W + BUTTON_GAP), top)
    if text then b:SetText(text) end
    b:SetScript("OnClick", onClick)
    return b
end

local function CreatePanel()
    panel = CreateFrame("Frame", PANEL_NAME, UIParent, BACKDROP_TEMPLATE)
    panel:SetSize(PANEL_W, PANEL_H)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetToplevel(true)
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:Hide()
    table.insert(UISpecialFrames, PANEL_NAME) -- close with Esc
    if panel.SetBackdrop then
        panel:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
    end

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -6, -6)

    local header = panel:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetPoint("TOP", panel, "TOP", 0, 12)
    local title = Label(panel, "Tank Traffic Light", "GameFontNormal")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    header:SetSize(math.max(256, math.floor(title:GetStringWidth() + 150)), 64) -- widen to fit
    Label(panel, "Traffic lights on nameplates: who is on you, who is slipping",
        "GameFontDisableSmall"):SetPoint("TOP", panel, "TOP", 0, -32)

    -- Traffic lights --------------------------------------------------------
    local lights = NewBox("Traffic lights", -70, 198)
    Row(NewCheck(lights, "Show traffic lights on enemy nameplates", "lights"), lights, 12, -20)
    Row(NewCheck(lights, "Only when my role is tank (or no role set)", "tankOnly"), lights, 12, -46)
    Row(NewCheck(lights, "Pulse the yellow light when aggro is slipping", "pulse"), lights, 12, -72)

    Row(Label(lights, "Placement on the nameplate:"), lights, 16, -106)
    widgets.side = CreateFrame("Button", nil, lights, "UIPanelButtonTemplate")
    widgets.side:SetSize(90, 22)
    Row(widgets.side, lights, 250, -106)
    widgets.side:SetScript("OnClick", function()
        local nextSide = { left = "right", right = "top", top = "left" }
        TankTrafficLightDB.side = nextSide[TankTrafficLightDB.side] or "left"
        TT.Lights.UpdateAll()
        TT.RefreshOptions()
    end)

    Row(Label(lights, "Size (0.5 - 3):"), lights, 16, -140)
    widgets.scale = Row(NewEditBox(lights, 40, function(text)
        local n = tonumber((text:gsub(",", ".")))
        if n and n >= 0.5 and n <= 3 then
            TankTrafficLightDB.lightScale = n
            TT.Lights.UpdateAll()
        else
            TT.Print("size must be a number from 0.5 to 3")
        end
    end), lights, 256, -140)

    Row(Label(lights, "Top placement height (0 - 60):"), lights, 16, -168)
    widgets.topOffset = Row(NewEditBox(lights, 40, function(text)
        local n = tonumber(text)
        if n and n >= 0 and n <= 60 then
            TankTrafficLightDB.topOffset = n
            TT.Lights.UpdateAll()
        else
            TT.Print("height must be a number from 0 to 60")
        end
    end), lights, 256, -168)

    -- Where -----------------------------------------------------------------
    local where = NewBox("Show in", -296, 124)
    Row(NewCheck(where, "Open world", "showWorld"), where, 12, -20)
    Row(NewCheck(where, "Dungeons", "showDungeon"), where, 12, -46)
    Row(NewCheck(where, "Raids", "showRaid"), where, 12, -72)
    Row(NewCheck(where, "Battlegrounds and arenas", "showPvP"), where, 12, -98)

    -- Diagnostics -----------------------------------------------------------
    local diag = NewBox("Diagnostics", -448, 72)
    Row(NewCheck(diag, "Print every light change to chat (/ttl trace)", "trace"), diag, 12, -20)
    Row(NewCheck(diag, "Record an API probe 3s into every pull", "autoProbe"), diag, 12, -46)

    -- Buttons ---------------------------------------------------------------
    widgets.demo = NewButton(nil, 1, -536, function()
        TT.Lights.SetDemo(not TT.Lights.IsDemo())
        TT.RefreshOptions()
    end)
    NewButton("Reset all settings", 2, -536, function()
        TT.ResetAll()
        TT.Lights.UpdateAll()
        TT.RefreshOptions()
        TT.Print("settings reset")
    end)
end

function TT.RefreshOptions()
    if not panel then return end
    for _, cb in ipairs(widgets.checks) do cb:Refresh() end
    local sideLabels = { left = "Left", right = "Right", top = "Top" }
    widgets.side:SetText(sideLabels[TankTrafficLightDB.side] or "Left")
    widgets.scale:SetText(tostring(TankTrafficLightDB.lightScale))
    widgets.topOffset:SetText(tostring(TankTrafficLightDB.topOffset))
    widgets.demo:SetText(TT.Lights.IsDemo() and "Stop demo" or "Demo: cycle colors")
end

function TT.ToggleOptions(forceShow)
    if not TankTrafficLightDB then return end
    if not panel then CreatePanel() end
    if panel:IsShown() and not forceShow then
        panel:Hide()
    else
        TT.RefreshOptions()
        panel:Show()
        panel:Raise()
    end
end

-- Entry in the standard Options -> AddOns menu with a button that opens the window.
local function RegisterBlizzardCategory()
    local stub = CreateFrame("Frame")
    stub.name = "Tank Traffic Light"

    local title = stub:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", stub, "TOPLEFT", 16, -16)
    title:SetText("Tank Traffic Light")

    local desc = stub:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Options open in a separate window. Command: /ttl")

    local open = CreateFrame("Button", nil, stub, "UIPanelButtonTemplate")
    open:SetSize(180, 24)
    open:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -12)
    open:SetText("Open options")
    open:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() then pcall(HideUIPanel, SettingsPanel) end
        if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then pcall(HideUIPanel, InterfaceOptionsFrame) end
        TT.ToggleOptions(true)
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(stub, stub.name))
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(stub)
    end
end

pcall(RegisterBlizzardCategory)
