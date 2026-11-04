local _, ns = ...
local G = { page = 1, rows = {}, filterIndex = 1 }
ns.MaterialGrid = G
function G.ClearTooltip()
    if GameTooltip and G.tooltipOwner then GameTooltip:Hide(); G.tooltipOwner = nil end
end
function G.Create(frame)
    G.search = ns.UI.Edit(frame, 25, -219, 230)
    G.search:SetScript("OnTextChanged", function() G.page = 1; G.Refresh() end)
    ns.UI.Label(frame, "搜索名称或 ID", 25, -205, 220)
    G.category = ns.UI.Button(frame, "全部专业", 270, -219, 110, function()
        G.filterIndex = G.filterIndex % (#ns.Professions + 1) + 1
        local profession = ns.Professions[G.filterIndex - 1]
        G.filter = profession and profession.id
        G.category:SetText(profession and profession.name or "全部专业")
        G.page = 1
        G.Refresh()
    end)
    ns.UI.Button(frame, "材料规则", 390, -219, 110, function() ns.UI.OpenEditor("rule") end)
    for index = 1, 8 do
        local button = CreateFrame("Button", nil, frame)
        button:SetSize(476, 32)
        button:SetPoint("TOPLEFT", 22, -253 - (index - 1) * 34)
        button:RegisterForDrag("LeftButton")
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetSize(30, 30)
        button.icon:SetPoint("LEFT")
        button.name = ns.UI.Label(button, "", 40, -3, 350)
        button.count = ns.UI.Label(button, "", 395, -8, 75)
        button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        button:SetScript("OnDragStart", function(self)
            if not self.item then return end
            local ok, err = ns.MailController.Pickup(self.item)
            if not ok then ns.Print(err) end
        end)
        button:SetScript("OnEnter", function(self)
            if not self.item then return end
            G.tooltipOwner = self
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetBagItem(self.item.bag, self.item.slot)
            GameTooltip:AddLine("拖到原生邮箱附件栏；每行对应一个真实背包堆叠。", 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", G.ClearTooltip)
        G.rows[index] = button
    end
    ns.UI.Button(frame, "上一页", 20, -533, 80, function() G.page = math.max(1, G.page - 1); G.Refresh() end)
    ns.UI.Button(frame, "下一页", 105, -533, 80, function() G.page = G.page + 1; G.Refresh() end)
    G.status = ns.UI.Label(frame, "", 200, -539, 300)
end
function G.Refresh()
    if not G.search then return end
    G.ClearTooltip()
    local character, matched = ns.CharacterManager.Selected(), {}
    if character then
        for _, row in ipairs(ns.InventoryScanner.Scan()) do
            if ns.MaterialMatcher.Match(row, character.professions, G.filter, G.search:GetText()) then
                matched[#matched + 1] = row
            end
        end
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
            button.name:SetText(row.name or ("物品 " .. row.itemID .. "（资料加载中）"))
            button.count:SetText("×" .. row.count)
        end
    end
    G.status:SetText(string.format("%d 个背包堆叠 · %d / %d 页", #matched, G.page, pages))
end
