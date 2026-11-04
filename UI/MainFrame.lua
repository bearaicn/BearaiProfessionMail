local _, ns = ...
local UI = {}
ns.UI = UI
function UI.Label(parent, text, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width or 470)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end
function UI.Button(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 100, 24)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    return button
end
function UI.Edit(parent, x, y, width)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetSize(width, 24)
    edit:SetPoint("TOPLEFT", x, y)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(80)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return edit
end
function UI.Panel(name, parent, width, height)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32,
        edgeSize = 24, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    return frame
end
function UI.Create()
    if ns.MainFrame then return end
    local frame = UI.Panel("BearaiProfessionMailMainFrame", MailFrame, 520, 610)
    ns.MainFrame = frame
    frame:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 8, 0)
    local available = UIParent:GetHeight() - 40
    if available < 610 then frame:SetScale(math.max(0.65, available / 610)) end
    frame:SetFrameStrata("DIALOG")
    UI.Label(frame, "BearAI · 专业材料邮寄助手", 20, -20)
    UI.Label(frame, "选收件角色 → 切到原生发送页 → 拖拽材料到附件栏", 20, -47)
    UI.Label(frame, "发送前请核对原生收件人、附件及邮资，由你点击发送。", 20, -568)
    ns.CharacterList.Create(frame)
    ns.MaterialGrid.Create(frame)
    frame:SetScript("OnShow", ns.Refresh)
    frame:SetScript("OnHide", function()
        if ns.Editor then ns.Editor:Hide() end
        if ns.MaterialGrid then ns.MaterialGrid.ClearTooltip() end
    end)
    frame:Hide()
end
-- 角色和规则共用小型编辑器，保存在源数据库中而非 UI 临时字段。
function UI.OpenEditor(mode, key)
    if not ns.Editor then
        local editor = UI.Panel("BearaiProfessionMailEditor", ns.MainFrame, 480, 410)
        ns.Editor = editor
        editor:SetPoint("CENTER")
        editor:SetFrameLevel(ns.MainFrame:GetFrameLevel() + 20)
        editor.title = UI.Label(editor, "", 20, -20, 420)
        editor.firstLabel = UI.Label(editor, "", 20, -57, 420)
        editor.first = UI.Edit(editor, 25, -80, 420)
        editor.secondLabel = UI.Label(editor, "服务器", 20, -116, 420)
        editor.second = UI.Edit(editor, 25, -139, 420)
        editor.checks = {}
        for index, profession in ipairs(ns.Professions) do
            local check = CreateFrame("CheckButton", nil, editor, "UICheckButtonTemplate")
            check:SetSize(26, 26)
            check:SetPoint("TOPLEFT", 20 + ((index - 1) % 3) * 150, -180 - math.floor((index - 1) / 3) * 30)
            UI.Label(check, profession.name, 28, -7, 115)
            editor.checks[profession.id] = check
        end
        editor.status = UI.Label(editor, "", 20, -312, 440)
        UI.Button(editor, "保存", 20, -365, 100, function()
            local chosen = {}
            for id, check in pairs(editor.checks) do if check:GetChecked() then chosen[id] = true end end
            local ok, err
            if editor.mode == "rule" then
                ok, err = ns.MaterialMatcher.SetRule(editor.first:GetText(), chosen)
            else
                ok, err = ns.CharacterManager.SaveManual(editor.key, editor.first:GetText(), editor.second:GetText(), chosen)
            end
            if ok then editor:Hide(); ns.Refresh()
            else editor.status:SetText(err) end
        end)
        editor.restore = UI.Button(editor, "恢复内置规则", 135, -365, 130, function()
            local id = tonumber(editor.first:GetText())
            local ok, err = ns.MaterialMatcher.SetRule(id, nil)
            if ok then editor:Hide(); ns.Refresh() else editor.status:SetText(err) end
        end)
        UI.Button(editor, "取消", 345, -365, 100, function() editor:Hide() end)
        editor.first:SetScript("OnTextChanged", function(self)
            if editor.mode ~= "rule" then return end
            local rule = ns.MaterialMatcher.Rule(tonumber(self:GetText()))
            for id, check in pairs(editor.checks) do check:SetChecked(rule[id] == true) end
        end)
    end
    local editor = ns.Editor
    editor.mode, editor.key = mode, key
    local character = key and ns.db.characters[key]
    editor.title:SetText(mode == "rule" and "自定义材料规则（覆盖该物品的内置规则）" or (key and "修改手动角色" or "添加其他账号角色"))
    editor.firstLabel:SetText(mode == "rule" and "物品 ID（输入后读取现有规则；全不选表示排除）" or "角色名称（不含服务器）")
    editor.secondLabel:SetShown(mode ~= "rule")
    editor.second:SetShown(mode ~= "rule")
    editor.restore:SetShown(mode == "rule")
    editor.first:SetText(character and character.name or "")
    editor.second:SetText(character and character.realm or GetRealmName())
    for id, check in pairs(editor.checks) do check:SetChecked(character and character.professions[id] ~= nil or false) end
    editor.status:SetText(mode == "rule" and "规则按客户端共享；无限服特有材料请按实际物品 ID 补充。" or "可设置多个专业；不会查询其他账号。")
    editor:Show()
end
