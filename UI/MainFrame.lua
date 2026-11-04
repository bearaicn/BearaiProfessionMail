local _, ns = ...
local UI = ns.UI
function UI.Position()
    local frame = ns.MainFrame
    if not frame then return end
    local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
    local mailScale = MailFrame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local right = (MailFrame:GetRight() or 400) * mailScale
    local left = (MailFrame:GetLeft() or 0) * mailScale
    local available = math.max(screenWidth - right - 16, left - 16)
    local fit = math.max(0.65, math.min(1, (screenHeight - 32) / 680, available / 640))
    frame:SetScale(fit)
    frame:ClearAllPoints()
    if screenWidth - right - 16 >= 640 * fit then
        frame:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 8, 0)
    elseif left - 16 >= 640 * fit then
        frame:SetPoint("TOPRIGHT", MailFrame, "TOPLEFT", -8, 0)
    else
        frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -12, -30)
    end
end
function UI.Create()
    if ns.MainFrame then return end
    local frame = UI.Panel("BearaiProfessionMailMainFrame", UIParent, 640, 680)
    ns.MainFrame = frame
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    UI.Brand(frame, 18, -7)
    UI.Label(frame, ns.version, 500, -19, 80, 11, ns.Theme.muted)
    UI.Label(frame, "双击添加附件 · 右击撤回 · 也可拖拽。核对原生收件人后由你发送。", 18, -650, 605, 11, ns.Theme.muted)
    ns.CharacterList.Create(frame)
    ns.MaterialGrid.Create(frame)
    frame:SetScript("OnShow", function() UI.Position(); ns.Refresh() end)
    frame:SetScript("OnHide", function()
        UI.CloseDropdown()
        if ns.Editor and ns.Editor:GetParent() == frame then ns.Editor:Hide() end
        ns.MaterialGrid.ClearTooltip()
        GameTooltip:Hide()
    end)
    UI.Position()
    frame:Hide()
end
function UI.OpenEditor(mode, key, parent)
    UI.CloseDropdown()
    local host = parent or ns.MainFrame or UIParent
    if not ns.Editor then
        local editor = UI.Panel("BearaiProfessionMailEditor", host, 480, 470)
        ns.Editor = editor
        editor:SetPoint("CENTER")
        editor:SetFrameStrata("DIALOG")
        editor.title = UI.Label(editor, "", 20, -20, 420, 14, ns.Theme.accent)
        editor.firstLabel = UI.Label(editor, "", 20, -57, 440)
        editor.first = UI.Edit(editor, 25, -80, 420)
        editor.secondLabel = UI.Label(editor, "服务器", 20, -116, 420)
        editor.second = UI.Edit(editor, 25, -139, 420)
        editor.classLabel = UI.Label(editor, "职业", 20, -178, 200)
        editor.class = UI.Dropdown(editor, 25, -201, 220)
        local classes = { { value = "", text = "未知／不填写" } }
        for _, class in ipairs(ns.Classes) do classes[#classes + 1] = { value = class.id, text = class.name } end
        editor.class:SetOptions(classes)
        editor.levelLabel = UI.Label(editor, "等级（可选）", 270, -178, 170)
        editor.level = UI.Edit(editor, 275, -201, 170)
        editor.level:SetMaxLetters(4)
        editor.checks = {}
        for index, profession in ipairs(ns.Professions) do
            local check = CreateFrame("CheckButton", nil, editor, "UICheckButtonTemplate")
            check:SetSize(26, 26)
            check:SetPoint("TOPLEFT", 20 + ((index - 1) % 3) * 150, -245 - math.floor((index - 1) / 3) * 30)
            UI.Label(check, profession.name, 28, -7, 115)
            editor.checks[profession.id] = check
        end
        editor.status = UI.Label(editor, "", 20, -378, 440, 11, ns.Theme.muted)
        editor.status:SetHeight(38)
        editor.status:SetWordWrap(true)
        editor.save = UI.Button(editor, "保存", 20, -425, 100, function()
            local chosen = {}
            for id, check in pairs(editor.checks) do if check:GetChecked() then chosen[id] = true end end
            local ok, err
            if editor.mode == "rule" then
                ok, err = ns.MaterialMatcher.SetRule(editor.first:GetText(), chosen)
            else
                ok, err = ns.CharacterManager.SaveManual(editor.key, editor.first:GetText(), editor.second:GetText(), chosen,
                    editor.class.value, editor.level:GetText())
            end
            if ok then editor:Hide(); ns.Refresh() else editor.status:SetText(err) end
        end)
        editor.restore = UI.Button(editor, "恢复内置规则", 135, -425, 130, function()
            local ok, err = ns.MaterialMatcher.SetRule(editor.first:GetText(), nil)
            if ok then editor:Hide(); ns.Refresh() else editor.status:SetText(err) end
        end)
        UI.Button(editor, "取消", 345, -425, 100, function() editor:Hide() end)
        editor:SetScript("OnHide", UI.CloseDropdown)
        editor.first:SetScript("OnTextChanged", function(self)
            if editor.mode ~= "rule" then return end
            local rule = ns.MaterialMatcher.Rule(tonumber(self:GetText()))
            for id, check in pairs(editor.checks) do check:SetChecked(rule[id] == true) end
        end)
    end
    local editor = ns.Editor
    editor:SetParent(host)
    editor:SetFrameStrata(host:GetFrameStrata())
    editor:ClearAllPoints()
    editor:SetPoint("CENTER", host, "CENTER")
    editor:SetFrameLevel(host:GetFrameLevel() + 20)
    editor.mode, editor.key = mode, key
    local character = key and ns.db.characters[key]
    editor.title:SetText(mode == "rule" and "自定义材料规则" or (key and "修改手动角色" or "添加其他账号角色"))
    editor.firstLabel:SetText(mode == "rule" and "物品 ID（全不选表示排除该材料）" or "角色名称（不含服务器）")
    for _, field in ipairs({ editor.secondLabel, editor.second, editor.classLabel, editor.class, editor.levelLabel, editor.level }) do
        field:SetShown(mode ~= "rule")
    end
    editor.restore:SetShown(mode == "rule")
    editor.class:SetValue(character and character.class or "", true)
    editor.level:SetText(character and character.level and tostring(character.level) or "")
    editor.first:SetText(character and character.name or "")
    editor.second:SetText(character and character.realm or GetRealmName())
    for id, check in pairs(editor.checks) do check:SetChecked(character and character.professions[id] ~= nil or false) end
    editor.status:SetText(mode == "rule" and "覆盖该物品的内置归属；恢复内置规则可撤销覆盖。" or "职业和等级可选；其他账号信息由你填写。")
    editor:Show()
end
