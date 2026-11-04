local _, ns = ...
local UI, T = {}, ns.Theme
ns.UI = UI
local unpack = unpack or table.unpack
function UI.Paint(frame, background, border)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(unpack(background or T.surface))
    frame:SetBackdropBorderColor(unpack(border or T.border))
end
function UI.Label(parent, text, x, y, width, size, color)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetFont(STANDARD_TEXT_FONT or "Fonts\\ARKai_T.ttf", size or 12, "")
    label:SetPoint("TOPLEFT", x, y)
    label:SetSize(width or 470, (size or 12) + 7)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetTextColor(unpack(color or T.text))
    label:SetText(text)
    return label
end
function UI.Button(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 100, 28)
    button:SetPoint("TOPLEFT", x, y)
    UI.Paint(button)
    button.label = UI.Label(button, text, 4, -5, (width or 100) - 8)
    button.label:SetJustifyH("CENTER")
    function button:SetText(value) self.label:SetText(value) end
    button:SetScript("OnEnter", function(self) self:SetBackdropColor(unpack(T.hover)) end)
    button:SetScript("OnLeave", function(self) self:SetBackdropColor(unpack(T.surface)) end)
    button:SetScript("OnEnable", function(self) self.label:SetTextColor(unpack(T.text)) end)
    button:SetScript("OnDisable", function(self) self.label:SetTextColor(unpack(T.muted)) end)
    button:SetScript("OnClick", callback)
    return button
end
function UI.Edit(parent, x, y, width)
    local edit = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    edit:SetSize(width, 28)
    edit:SetPoint("TOPLEFT", x, y)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetTextInsets(8, 8, 0, 0)
    UI.Paint(edit)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(80)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEditFocusGained", function(self) self:SetBackdropBorderColor(unpack(T.accent)) end)
    edit:SetScript("OnEditFocusLost", function(self) self:SetBackdropBorderColor(unpack(T.border)) end)
    return edit
end
function UI.Panel(name, parent, width, height)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    frame:SetSize(width, height)
    UI.Paint(frame, T.background)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    UI.Button(frame, "×", width - 34, -7, 26, function() frame:Hide() end)
    return frame
end
function UI.Brand(parent, x, y)
    local logo = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    logo:SetPoint("TOPLEFT", x, y)
    logo:SetSize(32, 32)
    logo.texture = logo:CreateTexture(nil, "ARTWORK")
    logo.texture:SetAllPoints(logo)
    logo.texture:SetTexture("Interface\\AddOns\\BearaiProfessionMail\\Media\\Logo.tga")
    UI.Label(parent, "熊智专业邮寄助手", x + 43, y, 360, 15, T.accent)
    UI.Label(parent, "BearAI Profession Mail", x + 43, y - 21, 360, 10, T.muted)
    return logo
end
function UI.CloseDropdown()
    if UI.openDropdown then UI.openDropdown.menu:Hide(); UI.openDropdown = nil end
    if UI.menuShield then UI.menuShield:Hide() end
end
function UI.Dropdown(parent, x, y, width, callback)
    local control = UI.Button(parent, "", x, y, width, function(self) self:ToggleMenu() end)
    control.options, control.offset = {}, 0
    -- 图标使用客户端纹理，不依赖当前字体是否包含 Unicode 符号。
    control.arrow = control:CreateTexture(nil, "OVERLAY")
    control.arrow:SetSize(18,18)
    control.arrow:SetPoint("RIGHT",control,"RIGHT",-5,0)
    control.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    control.label:SetWidth(width - 28)
    control.label:SetJustifyH("LEFT")
    control.label:ClearAllPoints()
    control.label:SetPoint("TOPLEFT", 8, -5)
    function control:SetValue(value, silent)
        self.value = value
        self.label:SetText("请选择")
        for _, option in ipairs(self.options) do
            if option.value == value then self.label:SetText(option.text); break end
        end
        if not silent and callback then callback(value) end
    end
    function control:SetOptions(options)
        self.options = options
        self:SetValue(self.value, true)
        if UI.openDropdown == self then UI.CloseDropdown() end
    end
    function control:Choose(index)
        local option = self.options[index]
        if not option then return end
        UI.CloseDropdown()
        self:SetValue(option.value)
    end
    function control:RefreshMenu()
        self.offset = math.max(0, math.min(self.offset, math.max(0, #self.options - 8)))
        for index, row in ipairs(self.menuRows) do
            local option = self.options[self.offset + index]
            row:SetShown(option ~= nil)
            row.selected = option ~= nil and option.value == self.value
            row.check:SetShown(row.selected)
            if option then
                row:SetText(option.text)
                row:SetBackdropColor(unpack(row.selected and T.selected or T.surface))
            end
        end
        self.menu.status:SetText(#self.options > 8 and "滚轮翻页" or "选择一项")
    end
    function control:ToggleMenu()
        if UI.openDropdown == self then UI.CloseDropdown(); return end
        UI.CloseDropdown()
        if not UI.menuShield then
            UI.menuShield = CreateFrame("Frame", nil, UIParent)
            UI.menuShield:SetAllPoints(UIParent)
            UI.menuShield:SetFrameStrata("DIALOG")
            UI.menuShield:EnableMouse(true)
            UI.menuShield:SetScript("OnMouseDown", UI.CloseDropdown)
            UI.menuShield:Hide()
        end
        if not self.menu then
            self.menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            self.menu:SetSize(width, 8 * 27 + 36)
            self.menu:SetFrameStrata("DIALOG")
            self.menu:SetClampedToScreen(true)
            self.menu:EnableMouse(true)
            UI.Paint(self.menu, T.background, T.accent)
            self.menuRows = {}
            for index = 1, 8 do
                local optionIndex = index
                local row = UI.Button(self.menu, "", 4, -4 - (index - 1) * 27, width - 8,
                    function() self:Choose(self.offset + optionIndex) end)
                row:SetHeight(26)
                row.check = row:CreateTexture(nil,"OVERLAY")
                row.check:SetSize(18,18)
                row.check:SetPoint("LEFT",row,"LEFT",3,0)
                row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                row.label:ClearAllPoints()
                row.label:SetPoint("TOPLEFT",24,-5)
                row.label:SetWidth(width-38)
                row.label:SetJustifyH("LEFT")
                row:SetScript("OnLeave",function(self)
                    self:SetBackdropColor(unpack(self.selected and T.selected or T.surface))
                end)
                self.menuRows[index] = row
            end
            self.menu.status = UI.Label(self.menu, "", 7, -225, width - 65, 10, T.muted)
            self.menu.up = UI.Button(self.menu, "", width - 60, -222, 26, function()
                self.offset = self.offset - 1; self:RefreshMenu()
            end)
            self.menu.down = UI.Button(self.menu, "", width - 31, -222, 26, function()
                self.offset = self.offset + 1; self:RefreshMenu()
            end)
            for _, spec in ipairs({ {self.menu.up,"ScrollUp"}, {self.menu.down,"ScrollDown"} }) do
                local icon = spec[1]:CreateTexture(nil,"OVERLAY")
                icon:SetSize(18,18); icon:SetPoint("CENTER",spec[1],"CENTER")
                icon:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-" .. spec[2] .. "-Up")
                spec[1].icon = icon
            end
            self.menu:EnableMouseWheel(true)
            self.menu:SetScript("OnMouseWheel", function(_, delta)
                self.offset = self.offset - delta; self:RefreshMenu()
            end)
        end
        UI.menuShield:SetFrameLevel(parent:GetFrameLevel() + 40)
        UI.menuShield:SetFrameStrata(parent:GetFrameStrata())
        self.menu:SetFrameStrata(parent:GetFrameStrata())
        self.menu:SetFrameLevel(UI.menuShield:GetFrameLevel() + 2)
        self.menu:ClearAllPoints()
        self.menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -3)
        self.offset = 0
        self:RefreshMenu()
        UI.menuShield:Show()
        self.menu:Show()
        UI.openDropdown = self
    end
    return control
end
