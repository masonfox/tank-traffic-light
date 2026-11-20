-- Tank Traffic Light options window (/ttl, or Options -> AddOns -> Tank Traffic Light).

local _, TT = ...
local SettingsRegistry = TT.Settings
local ByKey = SettingsRegistry.ByKey

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

local function NewCheck(parent, entry)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(26, 26)
    local fs = Label(parent, entry.label)
    fs:SetPoint("LEFT", cb, "RIGHT", 2, 1)
    cb:SetHitRectInsets(0, -(fs:GetStringWidth() + 6), 0, 0) -- label is clickable too
    cb:SetScript("OnClick", function(self)
        SettingsRegistry.Set(entry.key, self:GetChecked() and true or false)
    end)
    cb.Refresh = function(self) self:SetChecked(TankTrafficLightDB[entry.key] and true or false) end
    widgets.checks[#widgets.checks + 1] = cb
    return cb
end

-- Value applied on Enter or focus loss; Esc cancels.
local function NewEditBox(parent, width, entry)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(width, 20)
    eb:SetAutoFocus(false)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEscapePressed", function(self) self.cancel = true; self:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    eb:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
        if self.cancel then
            self.cancel = nil
        else
            local ok, message = SettingsRegistry.Set(entry.key, self:GetText())
            if ok then return end
            TT.Print(message)
        end
        TT.RefreshOptions()
    end)
    return eb
end

local function NumberLabel(entry)
    return string.format("%s (%s - %s):", entry.label, entry.min, entry.max)
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
    Row(NewCheck(lights, ByKey.lights), lights, 12, -20)
    Row(NewCheck(lights, ByKey.tankOnly), lights, 12, -46)
    Row(NewCheck(lights, ByKey.pulse), lights, 12, -72)

    Row(Label(lights, ByKey.side.label .. ":"), lights, 16, -106)
    widgets.side = CreateFrame("Button", nil, lights, "UIPanelButtonTemplate")
    widgets.side:SetSize(90, 22)
    Row(widgets.side, lights, 250, -106)
    widgets.side:SetScript("OnClick", function()
        SettingsRegistry.Cycle(ByKey.side.key)
    end)

    Row(Label(lights, NumberLabel(ByKey.lightScale)), lights, 16, -140)
    widgets.scale = Row(NewEditBox(lights, 40, ByKey.lightScale), lights, 256, -140)

    Row(Label(lights, NumberLabel(ByKey.topOffset)), lights, 16, -168)
    widgets.topOffset = Row(NewEditBox(lights, 40, ByKey.topOffset), lights, 256, -168)

    -- Where -----------------------------------------------------------------
    local where = NewBox("Show in", -296, 124)
    Row(NewCheck(where, ByKey.showWorld), where, 12, -20)
    Row(NewCheck(where, ByKey.showDungeon), where, 12, -46)
    Row(NewCheck(where, ByKey.showRaid), where, 12, -72)
    Row(NewCheck(where, ByKey.showPvP), where, 12, -98)

    -- Diagnostics -----------------------------------------------------------
    local diag = NewBox("Diagnostics", -448, 72)
    Row(NewCheck(diag, ByKey.trace), diag, 12, -20)
    Row(NewCheck(diag, ByKey.autoProbe), diag, 12, -46)

    -- Buttons ---------------------------------------------------------------
    widgets.demo = NewButton(nil, 1, -536, function()
        TT.Lights.SetDemo(not TT.Lights.IsDemo())
        TT.RefreshOptions()
    end)
    NewButton("Reset all settings", 2, -536, function() TT.ResetSettings() end)
end

function TT.RefreshOptions()
    if not panel then return end
    for _, cb in ipairs(widgets.checks) do cb:Refresh() end
    local side = ByKey.side
    widgets.side:SetText(side.labels[TankTrafficLightDB.side] or side.labels[side.values[1]])
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
