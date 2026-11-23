-- Tank Traffic Light options window (/ttl, or Options -> AddOns -> Tank Traffic Light).

local _, TT = ...
local SettingsRegistry = TT.Settings
local ByKey = SettingsRegistry.ByKey

local PANEL_NAME = "TankTrafficLightOptions"
-- Preview strip across the top, then two columns, so the window fits a 768px-tall UI at scale 1:
-- left = Traffic lights, right = Alerts / Show in / Diagnostics, reset button at the bottom.
local BOX_W, COL_GAP, MARGIN = 360, 20, 20
local LEFT_X, RIGHT_X = MARGIN, MARGIN + BOX_W + COL_GAP
local PANEL_W, PANEL_H = MARGIN * 2 + BOX_W * 2 + COL_GAP, 636
local PREVIEW_TOP, PREVIEW_H = -48, 140
local BOXES_TOP = PREVIEW_TOP - PREVIEW_H - 24 -- -212: leaves room for the box titles
local BUTTON_W = 175
local SLIDER_X, SLIDER_W = 180, 130
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

local panel
local widgets = { checks = {}, sliders = {} }

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

local function NewBox(title, x, top, height, width)
    local box = CreateFrame("Frame", nil, panel, BACKDROP_TEMPLATE)
    box:SetPoint("TOPLEFT", panel, "TOPLEFT", x, top)
    box:SetSize(width or BOX_W, height)
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
    if title then Label(panel, title, "GameFontNormal"):SetPoint("BOTTOMLEFT", box, "TOPLEFT", 8, 3) end
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

-- Horizontal slider for a number setting, with its value shown to the right.
-- Dragging applies live through SettingsRegistry.Set, the same validation as slash input.
-- Refresh shows db[key] as saved, so an off-step value typed in chat (1.23) reads as entered.
local sliderCount = 0
local function NewSlider(parent, entry, step)
    sliderCount = sliderCount + 1
    local name = "TankTrafficLightOptionsSlider" .. sliderCount -- named so template regions resolve
    local ok, s = pcall(CreateFrame, "Slider", name, parent, "OptionsSliderTemplate")
    if ok and s then
        for _, suffix in ipairs({ "Low", "High", "Text" }) do
            local region = s[suffix] or _G[name .. suffix]
            if region then region:Hide() end
        end
    else
        s = CreateFrame("Slider", nil, parent)
    end
    if not s:GetThumbTexture() then -- no template (or one without a thumb): build track and thumb by hand
        s:SetOrientation("HORIZONTAL")
        s:SetHeight(17)
        local track = s:CreateTexture(nil, "BACKGROUND")
        track:SetColorTexture(0.25, 0.25, 0.25, 0.9)
        track:SetPoint("LEFT", s, "LEFT", 0, 0)
        track:SetPoint("RIGHT", s, "RIGHT", 0, 0)
        track:SetHeight(6)
        s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        local thumb = s:GetThumbTexture()
        if thumb then thumb:SetSize(32, 32) end
        s:EnableMouse(true)
    end
    s:SetWidth(SLIDER_W)
    s:SetMinMaxValues(entry.min, entry.max)
    s:SetValueStep(step)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end

    local valueText = Label(parent, nil, "GameFontHighlightSmall")
    valueText:SetPoint("LEFT", s, "RIGHT", 6, 0)

    -- Round to the step's precision so 0.45 doesn't become 0.45000001.
    local fraction = tostring(step):match("%.(%d+)")
    local precision = "%." .. (fraction and #fraction or 0) .. "f"

    s:SetScript("OnValueChanged", function(_, v)
        if widgets.refreshing then return end -- our own SetValue from Refresh
        v = tonumber(string.format(precision, math.floor(v / step + 0.5) * step))
        if v == TankTrafficLightDB[entry.key] then return end
        local applied, message = SettingsRegistry.Set(entry.key, v)
        if not applied then
            TT.Print(message)
            TT.RefreshOptions()
        end
    end)
    s.Refresh = function(self)
        local current = TankTrafficLightDB[entry.key]
        widgets.refreshing = true
        self:SetValue(current)
        widgets.refreshing = false
        valueText:SetText(tostring(current))
    end
    widgets.sliders[#widgets.sliders + 1] = s
    return s
end

-- Button that cycles a choice setting; its text is refreshed in TT.RefreshOptions.
local function CycleButton(parent, entry)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(90, 22)
    b:SetScript("OnClick", function() SettingsRegistry.Cycle(entry.key) end)
    return b
end

local function ChoiceText(entry)
    return entry.labels[TankTrafficLightDB[entry.key]] or entry.labels[entry.values[1]]
end

local function SetButtonEnabled(b, enabled)
    if b.SetEnabled then
        b:SetEnabled(enabled)
    elseif enabled then
        b:Enable()
    else
        b:Disable()
    end
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

    -- Preview (sample nameplate, see Preview.lua) ---------------------------
    local previewBox = NewBox(nil, MARGIN, PREVIEW_TOP, PREVIEW_H, PANEL_W - MARGIN * 2)
    local previewArea = CreateFrame("Frame", nil, previewBox)
    previewArea:SetPoint("TOPLEFT", previewBox, "TOPLEFT", 5, -5)
    previewArea:SetPoint("BOTTOMRIGHT", previewBox, "BOTTOMRIGHT", -5, 5)
    TT.Preview.Create(previewArea)
    Label(previewBox, "Preview", "GameFontDisableSmall"):SetPoint("TOPLEFT", previewBox, "TOPLEFT", 10, -8)

    -- Traffic lights --------------------------------------------------------
    local lights = NewBox("Traffic lights", LEFT_X, BOXES_TOP, 286)
    Row(NewCheck(lights, ByKey.lights), lights, 12, -20)
    Row(NewCheck(lights, ByKey.tankOnly), lights, 12, -46)
    Row(NewCheck(lights, ByKey.pulse), lights, 12, -72)
    Row(NewCheck(lights, ByKey.showGrey), lights, 12, -98)

    Row(Label(lights, ByKey.greyAlpha.label .. ":"), lights, 16, -126)
    Row(NewSlider(lights, ByKey.greyAlpha, 0.05), lights, SLIDER_X, -126)

    Row(Label(lights, ByKey.palette.label .. ":"), lights, 16, -154)
    widgets.palette = Row(CycleButton(lights, ByKey.palette), lights, 250, -154)

    Row(Label(lights, ByKey.side.label .. ":"), lights, 16, -182)
    widgets.side = Row(CycleButton(lights, ByKey.side), lights, 250, -182)

    Row(Label(lights, ByKey.align.label .. ":"), lights, 16, -210)
    widgets.align = Row(CycleButton(lights, ByKey.align), lights, 250, -210)

    Row(Label(lights, ByKey.lightScale.label .. ":"), lights, 16, -238)
    Row(NewSlider(lights, ByKey.lightScale, 0.05), lights, SLIDER_X, -238)

    Row(Label(lights, ByKey.gap.label .. ":"), lights, 16, -264)
    Row(NewSlider(lights, ByKey.gap, 1), lights, SLIDER_X, -264)

    -- Alerts ----------------------------------------------------------------
    local alerts = NewBox("Alerts", RIGHT_X, BOXES_TOP, 122)
    Row(NewCheck(alerts, ByKey.slipSound), alerts, 12, -20)
    widgets.slipSoundName = Row(CycleButton(alerts, ByKey.slipSoundName), alerts, 262, -20)
    Row(NewCheck(alerts, ByKey.healerSound), alerts, 12, -46)
    widgets.healerSoundName = Row(CycleButton(alerts, ByKey.healerSoundName), alerts, 262, -46)
    Row(NewCheck(alerts, ByKey.healerFlash), alerts, 12, -72)
    local test = CreateFrame("Button", nil, alerts, "UIPanelButtonTemplate")
    test:SetSize(120, 22)
    test:SetText("Test alerts")
    Row(test, alerts, 16, -100)
    test:SetScript("OnClick", function() TT.Alerts.Test() end)

    -- Where -----------------------------------------------------------------
    local where = NewBox("Show in", RIGHT_X, BOXES_TOP - 150, 124)
    Row(NewCheck(where, ByKey.showWorld), where, 12, -20)
    Row(NewCheck(where, ByKey.showDungeon), where, 12, -46)
    Row(NewCheck(where, ByKey.showRaid), where, 12, -72)
    Row(NewCheck(where, ByKey.showPvP), where, 12, -98)

    -- Diagnostics -----------------------------------------------------------
    local diag = NewBox("Diagnostics", RIGHT_X, BOXES_TOP - 302, 72)
    Row(NewCheck(diag, ByKey.trace), diag, 12, -20)
    Row(NewCheck(diag, ByKey.autoProbe), diag, 12, -46)

    -- Button ----------------------------------------------------------------
    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(BUTTON_W, 22)
    reset:SetPoint("BOTTOM", panel, "BOTTOM", 0, 18)
    reset:SetText("Reset all settings")
    reset:SetScript("OnClick", function() TT.ResetSettings() end)
end

function TT.RefreshOptions()
    if not panel then return end
    for _, cb in ipairs(widgets.checks) do cb:Refresh() end
    for _, slider in ipairs(widgets.sliders) do slider:Refresh() end
    local side = TankTrafficLightDB.side
    widgets.side:SetText(ChoiceText(ByKey.side))
    widgets.align:SetText(ChoiceText(ByKey.align)) -- the saved alignment, even while disabled
    SetButtonEnabled(widgets.align, side == "top" or side == "bottom")
    widgets.palette:SetText(ChoiceText(ByKey.palette))
    widgets.slipSoundName:SetText(ChoiceText(ByKey.slipSoundName))
    widgets.healerSoundName:SetText(ChoiceText(ByKey.healerSoundName))
    TT.Preview.Refresh()
end

function TT.IsOptionsShown()
    return panel ~= nil and panel:IsShown()
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
