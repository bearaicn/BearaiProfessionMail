local _, ns = ...
local L = {}
ns.CharacterList = L
function L.Select(key)
    ns.db.settings.selected = key
    if ns.db.settings.fillRecipient ~= false then
        local _, err = ns.MailController.FillRecipient()
        if err then ns.Print(err) end
    end
    ns.MaterialGrid.page = 1
    ns.Refresh()
end
function L.Step(delta)
    local rows = ns.CharacterManager.List()
    if #rows == 0 then return end
    local current = 0
    for i, row in ipairs(rows) do if row.key == ns.db.settings.selected then current = i end end
    L.Select(rows[((current - 1 + delta) % #rows) + 1].key)
end
function L.Create(frame)
    L.title = ns.UI.Label(frame, "", 20, -84, 470)
    L.professions = ns.UI.Label(frame, "", 20, -112, 470)
    ns.UI.Button(frame, "上个角色", 20, -145, 85, function() L.Step(-1) end)
    ns.UI.Button(frame, "下个角色", 110, -145, 85, function() L.Step(1) end)
    ns.UI.Button(frame, "添加", 200, -145, 65, function() ns.UI.OpenEditor("character") end)
    L.edit = ns.UI.Button(frame, "修改", 270, -145, 65, function() ns.UI.OpenEditor("character", ns.db.settings.selected) end)
    L.delete = ns.UI.Button(frame, "删除", 340, -145, 65, function()
        if L.pendingDelete ~= ns.db.settings.selected then
            L.pendingDelete = ns.db.settings.selected
            L.delete:SetText("确认删除")
            return
        end
        local ok, err = ns.CharacterManager.Delete(L.pendingDelete)
        L.pendingDelete = nil
        if not ok then ns.Print(err) end
        ns.Refresh()
    end)
    ns.UI.Button(frame, "刷新专业", 410, -145, 90, function()
        local _, err = ns.CharacterManager.RecordCurrent()
        if err then ns.Print(err) end
        ns.Refresh()
    end)
    L.fill = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    L.fill:SetPoint("TOPLEFT", 17, -178)
    L.fill:SetSize(26, 26)
    ns.UI.Label(L.fill, "切换角色时填写收件人（仍可在原生邮箱修改）", 28, -7, 440)
    L.fill:SetScript("OnClick", function(self) ns.db.settings.fillRecipient = not not self:GetChecked() end)
end
function L.Refresh()
    local character = ns.CharacterManager.Selected()
    L.title:SetText(character and ("收件角色：" .. character.name .. " - " .. character.realm ..
        (character.source == "manual" and " [手动]" or " [本账号]")) or "尚未选择收件角色（用上个/下个切换，或添加角色）")
    L.professions:SetText("专业：" .. ns.ProfessionManager.Text(character and character.professions))
    L.fill:SetChecked(ns.db.settings.fillRecipient ~= false)
    local manual = character and character.source == "manual"
    L.edit:SetEnabled(not not manual)
    L.delete:SetEnabled(not not manual)
    if L.pendingDelete ~= ns.db.settings.selected then L.pendingDelete = nil end
    L.delete:SetText(L.pendingDelete and "确认删除" or "删除")
end
