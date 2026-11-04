local _, ns = ...
local unpack = unpack or table.unpack
local function NewList()
local L = { offset = 0, rows = {} }
function L.Select(key)
    if ns.db.settings.selected ~= key then
        ns.MaterialGrid.filter = nil
        ns.UI.CloseDropdown()
    end
    ns.db.settings.selected = key
    L.pendingDelete = nil
    if not L.settingsMode and ns.db.settings.fillRecipient ~= false then
        local _, err = ns.MailController.FillRecipient()
        if err then ns.Print(err) end
    end
    ns.MaterialGrid.page = 1
    ns.Refresh()
end
function L.Filtered()
    local result = {}
    local search = string.lower(L.search and L.search:GetText() or "")
    for _, row in ipairs(ns.CharacterManager.List()) do
        local character = row.character
        local text = row.key .. " " .. ns.ClassName(character.class) .. " " .. ns.ProfessionManager.Text(character.professions)
        if string.lower(text):find(search, 1, true) then result[#result + 1] = row end
    end
    return result
end
function L.Scroll(delta)
    L.offset = math.max(0, math.min(L.offset + delta, math.max(0, #L.Filtered() - #L.rows)))
    L.Refresh()
end
function L.Create(frame, options)
    L.settingsMode = options and options.settings
    ns.UI.Label(frame, "搜索角色／服务器／专业", 18, -46, 250, 10, ns.Theme.muted)
    L.search = ns.UI.Edit(frame, 18, -63, 250)
    L.search:SetScript("OnTextChanged", function() L.offset = 0; L.Refresh() end)
    ns.UI.Button(frame, "添加", 280, -63, 66, function() ns.UI.OpenEditor("character", nil, frame) end)
    L.edit = ns.UI.Button(frame, "编辑", 352, -63, 66, function() ns.UI.OpenEditor("character", ns.db.settings.selected, frame) end)
    L.delete = ns.UI.Button(frame, "删除", 424, -63, 80, function()
        if L.pendingDelete ~= ns.db.settings.selected then
            L.pendingDelete = ns.db.settings.selected; L.delete:SetText("确认删除"); return
        end
        local ok, err = ns.CharacterManager.Delete(L.pendingDelete)
        L.pendingDelete = nil
        if not ok then ns.Print(err) end
        ns.Refresh()
    end)
    ns.UI.Button(frame, "更新当前角色", 510, -63, 112, function()
        local _, err = ns.CharacterManager.RecordCurrent()
        if err then ns.Print(err) end
        ns.Refresh()
    end)
    for _, column in ipairs({ {"角色 / 服务器", 26, 210}, {"职业", 245, 90}, {"等级", 335, 50}, {"专业", 392, 200} }) do
        ns.UI.Label(frame, column[1], column[2], -104, column[3], 11, ns.Theme.muted)
    end
    for index = 1, 4 do
        local row = CreateFrame("Button", nil, frame, "BackdropTemplate")
        row:SetPoint("TOPLEFT", 18, -125 - (index - 1) * 36)
        row:SetSize(584, 35)
        ns.UI.Paint(row)
        row.name = ns.UI.Label(row, "", 8, -2, 210, 12)
        row.realm = ns.UI.Label(row, "", 8, -19, 210, 10, ns.Theme.muted)
        row.class = ns.UI.Label(row, "", 227, -10, 84, 12)
        row.level = ns.UI.Label(row, "", 317, -10, 45, 12)
        row.professions = ns.UI.Label(row, "", 374, -10, 202, 11)
        row:SetScript("OnClick", function(self) if self.key then L.Select(self.key) end end)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, delta) L.Scroll(-delta) end)
        row:SetScript("OnEnter", function(self)
            self:SetBackdropColor(unpack(ns.Theme.hover))
            if not self.key then return end
            local character = ns.db.characters[self.key]
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(character.name .. " - " .. character.realm)
            GameTooltip:AddLine(ns.ProfessionManager.Text(character.professions), 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(self)
            self:SetBackdropColor(unpack(self.key == ns.db.settings.selected and ns.Theme.selected or ns.Theme.surface))
            GameTooltip:Hide()
        end)
        L.rows[index] = row
    end
    ns.UI.Button(frame, "↑", 606, -125, 20, function() L.Scroll(-1) end)
    ns.UI.Button(frame, "↓", 606, -232, 20, function() L.Scroll(1) end)
    L.status = ns.UI.Label(frame, "", 18, -275, 600, 10, ns.Theme.muted)
    L.title = ns.UI.Label(frame, "", 18, -297, 600, 12, ns.Theme.accent)
    if L.settingsMode then return end
    L.fill = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    L.fill:SetPoint("TOPLEFT", 15, -318)
    L.fill:SetSize(25, 25)
    ns.UI.Label(L.fill, "切换角色时填写收件人；可在原生邮箱修改", 29, -6, 550, 11, ns.Theme.muted)
    L.fill:SetScript("OnClick", function(self) ns.db.settings.fillRecipient = not not self:GetChecked() end)
end
function L.Refresh()
    if not L.search then return end
    local filtered = L.Filtered()
    L.offset = math.min(L.offset, math.max(0, #filtered - #L.rows))
    for index, row in ipairs(L.rows) do
        local entry = filtered[L.offset + index]
        row.key = entry and entry.key
        row:SetShown(entry ~= nil)
        if entry then
            local character = entry.character
            row.name:SetText(character.name)
            row.realm:SetText(character.realm .. (character.source == "manual" and " · 手动" or " · 本账号"))
            row.class:SetText(ns.ClassName(character.class))
            local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[character.class]
            row.class:SetTextColor(color and color.r or 0.7, color and color.g or 0.75, color and color.b or 0.8)
            row.level:SetText(character.level and tostring(character.level) or "未知")
            row.professions:SetText(ns.ProfessionManager.Text(character.professions))
            row:SetBackdropColor(unpack(entry.key == ns.db.settings.selected and ns.Theme.selected or ns.Theme.surface))
        end
    end
    L.status:SetText(#filtered == 0 and "没有找到角色，请清空搜索或添加角色。" or
        string.format("%d 个角色 · 当前 %d–%d · 滚轮浏览，点击整行选择", #filtered, L.offset + 1, math.min(L.offset + #L.rows, #filtered)))
    local character = ns.CharacterManager.Selected()
    L.title:SetText(character and ("筛选目标：" .. character.name .. " - " .. character.realm) or "尚未选择收件角色，请点击上方角色行。")
    if L.fill then L.fill:SetChecked(ns.db.settings.fillRecipient ~= false) end
    local manual = character and character.source == "manual"
    L.edit:SetEnabled(not not manual)
    L.delete:SetEnabled(not not manual)
    if L.pendingDelete ~= ns.db.settings.selected then L.pendingDelete = nil end
    L.delete:SetText(L.pendingDelete and "确认删除" or "删除")
end
return L
end
ns.CreateCharacterList = NewList
ns.CharacterList = NewList()
