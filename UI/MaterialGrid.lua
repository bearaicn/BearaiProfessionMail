local _, ns = ...
local unpack = unpack or table.unpack
local G = { page = 1, rows = {}, columns = 11 }
ns.MaterialGrid = G
function G.ClearTooltip()
    if G.tooltipOwner then GameTooltip:Hide(); G.tooltipOwner = nil end
end
function G.FilterOptions(character)
    local options = { { value = 0, text = "按角色专业过滤" },
        { value = -1, text = "全部可邮寄物品" }, { value = -2, text = "全部材料" } }
    for _, profession in ipairs(ns.Professions) do
        options[#options + 1] = { value = profession.id, text = profession.name }
    end
    if not G.optionSignature then
        G.category:SetOptions(options)
        G.optionSignature = true
    end
    G.category:SetValue(G.filter or 0, true)
end
function G.Create(frame)
    ns.UI.Label(frame, "搜索材料名称或 ID", 18, -350, 280, 10, ns.Theme.muted)
    G.search = ns.UI.Edit(frame, 18, -367, 280)
    G.search:SetScript("OnTextChanged", function() G.page = 1; G.Refresh() end)
    G.category = ns.UI.Dropdown(frame, 310, -367, 186, function(value)
        G.filter = value ~= 0 and value or nil; G.page = 1; G.Refresh()
    end)
    ns.UI.Button(frame, "材料规则", 508, -367, 114, function() ns.UI.OpenEditor("rule") end)
    local area = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    area:SetPoint("TOPLEFT", 18, -408)
    area:SetSize(604, 110)
    ns.UI.Paint(area)
    area:EnableMouseWheel(true)
    area:SetScript("OnMouseWheel", function(_, delta) G.page = math.max(1, G.page - delta); G.Refresh() end)
    G.empty = ns.UI.Label(area, "", 20, -45, 564, 13, ns.Theme.muted)
    G.empty:SetJustifyH("CENTER")
    for index = 1, G.columns * 2 do
        local button = CreateFrame("Button", nil, area, "BackdropTemplate")
        button:SetSize(46, 46)
        button:SetPoint("TOPLEFT", 7 + ((index - 1) % G.columns) * 54, -7 - math.floor((index - 1) / G.columns) * 51)
        ns.UI.Paint(button)
        button:RegisterForDrag("LeftButton")
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetPoint("TOPLEFT", 2, -2)
        button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
        button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        button.count = ns.UI.Label(button, "", 2, -29, 40, 12)
        button.count:SetFont(STANDARD_TEXT_FONT or "Fonts\\ARKai_T.ttf", 12, "OUTLINE")
        button.count:SetJustifyH("RIGHT")
        button:SetScript("OnDragStart", function(self)
            if not self.item then return end
            local ok, err = ns.MailController.Pickup(self.item)
            if not ok then ns.Print(err) end
        end)
        button:SetScript("OnDoubleClick", function(self, mouseButton)
            if mouseButton ~= "LeftButton" or not self.item then return end
            local ok, err = ns.MailController.Add(self.item)
            if not ok then ns.Print(err) end
        end)
        button:SetScript("OnClick", function(self, mouseButton)
            if mouseButton ~= "RightButton" or not self.item then return end
            local ok, err = ns.MailController.Remove(self.item)
            if not ok then ns.Print(err) end
        end)
        button:SetScript("OnEnter", function(self)
            if not self.item then return end
            G.tooltipOwner = self
            self:SetBackdropColor(unpack(ns.Theme.hover))
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetBagItem(self.item.bag, self.item.slot)
            GameTooltip:AddLine("双击添加一堆附件；右击撤回同类附件；可直接拖拽。", 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function(self)
            G.ClearTooltip(); self:SetBackdropColor(unpack(ns.Theme.surface))
        end)
        button:EnableMouseWheel(true)
        button:SetScript("OnMouseWheel", function(_, delta) G.page = math.max(1, G.page - delta); G.Refresh() end)
        G.rows[index] = button
    end
    ns.UI.Label(frame, "原生邮件附件（不受筛选影响，右击撤回一堆）", 18, -528, 600, 11, ns.Theme.accent)
    G.attachments = {}
    local cellSize = math.min(44, math.floor((604 - (ns.Compatibility.AttachmentLimit() - 1) * 4) / ns.Compatibility.AttachmentLimit()))
    for index = 1, ns.Compatibility.AttachmentLimit() do
        local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
        button:SetPoint("TOPLEFT", 18 + (index - 1) * (cellSize + 4), -550)
        button:SetSize(cellSize, 44)
        ns.UI.Paint(button, ns.Theme.surface, ns.Theme.accent)
        button:RegisterForClicks("RightButtonUp")
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetPoint("TOPLEFT", 2, -2)
        button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
        button.count = ns.UI.Label(button, "", 2, -28, cellSize - 4, 12)
        button.count:SetJustifyH("RIGHT")
        button.count:SetFont(STANDARD_TEXT_FONT or "Fonts\\ARKai_T.ttf", 12, "OUTLINE")
        button:SetScript("OnClick", function(self)
            if not self.item then return end
            local ok, err = ns.MailController.Remove(self.item)
            if not ok then ns.Print(err) end
        end)
        button:SetScript("OnEnter", function(self)
            if not self.item then return end
            G.tooltipOwner = self
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSendMailItem(self.item.mailSlot)
            GameTooltip:AddLine("右击撤回此附件，退回背包；不会发送邮件。", 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", G.ClearTooltip)
        G.attachments[index] = button
    end
    G.previous = ns.UI.Button(frame, "上一页", 18, -605, 70, function() G.page = math.max(1, G.page - 1); G.Refresh() end)
    G.next = ns.UI.Button(frame, "下一页", 94, -605, 70, function() G.page = G.page + 1; G.Refresh() end)
    G.status = ns.UI.Label(frame, "", 180, -611, 440, 11, ns.Theme.muted)
end
function G.Refresh()
    if not G.category then return end
    G.ClearTooltip()
    local character, matched, total = ns.CharacterManager.Selected(), {}, 0
    G.FilterOptions(character)
    for _, row in ipairs(ns.InventoryScanner.Scan()) do
        if ns.MaterialMatcher.Match(row, character and character.professions, G.filter, G.search:GetText()) then
            matched[#matched + 1] = row; total = total + row.count
        end
    end
    for index, button in ipairs(G.attachments) do
        button.item = ns.MailController.IsOpen() and ns.Compatibility.Attachment(index) or nil
        button.icon:SetTexture(button.item and button.item.icon)
        button.count:SetText(button.item and tostring(button.item.count) or "")
    end
    local pages = math.max(1, math.ceil(#matched / #G.rows))
    G.page = math.min(G.page, pages)
    for index, button in ipairs(G.rows) do
        local row = matched[(G.page - 1) * #G.rows + index]
        button.item = row
        button:SetShown(row ~= nil)
        if row then
            button.icon:SetTexture(row.icon)
            button.icon:SetDesaturated(not not row.locked)
            button.count:SetText(tostring(row.count))
            local colors = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[row.quality or 1]
            button:SetBackdropBorderColor(colors and colors.r or 0.3, colors and colors.g or 0.35, colors and colors.b or 0.4, 1)
        end
    end
    G.empty:SetShown(#matched == 0)
    if #matched == 0 then
        local message = "当前背包没有匹配材料，可检查专业或自定义规则。"
        if not character and not G.filter then message = "请先选择角色，或切换为全部物品／独立专业。"
        elseif not G.filter and not next(character.professions) then message = "该角色尚未记录专业，请编辑或登录该角色更新。"
        elseif G.search:GetText() ~= "" then message = "没有符合搜索条件的材料。" end
        G.empty:SetText(message)
    end
    G.previous:SetEnabled(G.page > 1)
    G.next:SetEnabled(G.page < pages)
    G.status:SetText(string.format("%d 堆 / %d 件 · %d / %d 页 · 滚轮翻页", #matched, total, G.page, pages))
end
