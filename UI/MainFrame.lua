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
    UI.Label(frame, "双击选数量 · 右击添加／撤回 · 可拖拽。核对原生收件人后由你发送。", 18, -650, 605, 11, ns.Theme.muted)
    ns.CharacterList.Create(frame)
    ns.MaterialGrid.Create(frame)
    frame:SetScript("OnShow", function() UI.Position(); ns.Refresh() end)
    frame:SetScript("OnHide", function()
        ns.MailController.CancelQuantity("助手已关闭。")
        UI.CloseDropdown()
        if ns.Editor and ns.Editor:GetParent() == frame then ns.Editor:Hide() end
        if ns.QuantityDialog.frame then ns.QuantityDialog.frame:Hide() end
        ns.MaterialGrid.ClearTooltip()
        GameTooltip:Hide()
    end)
    UI.Position()
    frame:Hide()
end
-- 此编辑器只负责角色。旧的规则入口转至独立面板，不复用角色窗口。
function UI.OpenEditor(mode, key, parent)
    if mode == "rule" then ns.ItemRulesPanel.Open(tonumber(key)); return end
    UI.CloseDropdown()
    local host = parent or ns.MainFrame or UIParent
    if not ns.Editor then
        local extra = math.max(0, math.ceil(#ns.Professions / 3) - 4) * 30
        local editor = UI.Panel("BearaiProfessionMailEditor", host, 480, 470 + extra)
        ns.Editor = editor
        editor:SetFrameStrata("DIALOG")
        editor.title = UI.Label(editor, "", 20, -20, 420, 14, ns.Theme.accent)
        UI.Label(editor, "角色名称（不含服务器）", 20, -57, 440)
        editor.first = UI.Edit(editor, 25, -80, 420)
        UI.Label(editor, "服务器", 20, -116, 420)
        editor.second = UI.Edit(editor, 25, -139, 420)
        UI.Label(editor, "职业", 20, -178, 200)
        editor.class = UI.Dropdown(editor, 25, -201, 220)
        local classes = { { value = "", text = "未知／不填写" } }
        for _, class in ipairs(ns.Classes) do classes[#classes + 1] = { value = class.id, text = class.name } end
        editor.class:SetOptions(classes)
        UI.Label(editor, "等级（可选）", 270, -178, 170)
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
        editor.status = UI.Label(editor, "", 20, -378 - extra, 440, 11, ns.Theme.muted)
        editor.status:SetHeight(38)
        editor.status:SetWordWrap(true)
        editor.save = UI.Button(editor, "保存", 20, -425 - extra, 100, function()
            local chosen = {}
            for id, check in pairs(editor.checks) do if check:GetChecked() then chosen[id] = true end end
            local ok, err = ns.CharacterManager.SaveManual(editor.key, editor.first:GetText(), editor.second:GetText(), chosen,
                editor.class.value, editor.level:GetText())
            if ok then editor:Hide(); ns.Refresh() else editor.status:SetText(err) end
        end)
        UI.Button(editor, "取消", 345, -425 - extra, 100, function() editor:Hide() end)
        editor:SetScript("OnHide", UI.CloseDropdown)
    end
    local editor = ns.Editor
    editor:SetParent(host)
    editor:SetFrameStrata(host:GetFrameStrata())
    editor:ClearAllPoints()
    editor:SetPoint("CENTER", host, "CENTER")
    editor:SetFrameLevel(host:GetFrameLevel() + 20)
    editor.mode, editor.key = "character", key
    local character = key and ns.db.characters[key]
    editor.title:SetText(key and "修改手动角色" or "添加其他账号角色")
    editor.class:SetValue(character and character.class or "", true)
    editor.level:SetText(character and character.level and tostring(character.level) or "")
    editor.first:SetText(character and character.name or "")
    editor.second:SetText(character and character.realm or GetRealmName())
    for id, check in pairs(editor.checks) do check:SetChecked(character and character.professions[id] ~= nil or false) end
    editor.status:SetText("职业和等级可选；其他账号信息由你填写。")
    editor:Show()
end
