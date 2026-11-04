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
    ns.UI.Label(frame, "当前筛选内搜索：名称 / ID", 18, -350, 166, 10, ns.Theme.muted)
    ns.UI.Label(frame, "用途 / 专业", 192, -350, 166, 10, ns.Theme.muted)
    ns.UI.Label(frame, "游戏物品类别", 366, -350, 142, 10, ns.Theme.muted)
    G.search = ns.UI.Edit(frame, 18, -367, 166)
    G.search:SetScript("OnTextChanged", function() G.page = 1; G.Refresh() end)
    G.category = ns.UI.Dropdown(frame, 192, -367, 166, function(value)
        G.filter = value ~= 0 and value or nil; G.page = 1; G.Refresh()
    end)
    G.itemCategory = ns.UI.Dropdown(frame, 366, -367, 142, function() G.page=1; G.Refresh() end)
    G.itemCategory:SetOptions(ns.ItemClassifier.Options())
    G.itemCategory:SetValue("all",true)
    G.rulesButton = ns.UI.Button(frame, "物品规则", 516, -585, 106, function() ns.ItemRulesPanel.Open() end)
    local area = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    area:SetPoint("TOPLEFT", 18, -408)
    area:SetSize(604, 161)
    ns.UI.Paint(area)
    area:EnableMouseWheel(true)
    area:SetScript("OnMouseWheel", function(_, delta) G.page = math.max(1, G.page - delta); G.Refresh() end)
    G.empty = ns.UI.Label(area, "", 20, -70, 564, 13, ns.Theme.muted)
    G.empty:SetJustifyH("CENTER")
    for index = 1, G.columns * 3 do
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
        button.attachedMark=button:CreateTexture(nil,"OVERLAY")
        button.attachedMark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        button.attachedMark:SetSize(18,18)
        button.attachedMark:SetPoint("TOPLEFT",0,0)
        button:SetScript("OnDragStart", function(self)
            if not self.item then return end
            if self.item.mailSlot then ns.Print("该堆已在附件中，右键可撤回。"); return end
            local ok, err = ns.MailController.Pickup(self.item)
            if not ok then ns.Print(err) end
        end)
        button:SetScript("OnDoubleClick", function(self, mouseButton)
            if mouseButton ~= "LeftButton" or not self.item then return end
            local ok, err = ns.QuantityDialog.Open(self.item)
            if not ok then ns.Print(err) end
        end)
        button:SetScript("OnClick", function(self, mouseButton)
            if mouseButton ~= "RightButton" or not self.item then return end
            local ok, err = ns.MailController.ToggleItem(self.item)
            if not ok then ns.Print(err) end
        end)
        button:SetScript("OnEnter", function(self)
            if not self.item then return end
            G.tooltipOwner = self
            self:SetBackdropColor(unpack(ns.Theme.hover))
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.item.mailSlot then GameTooltip:SetSendMailItem(self.item.mailSlot)
            else GameTooltip:SetBagItem(self.item.bag, self.item.slot) end
            local _, category, state = ns.ItemClassifier.Describe(self.item)
            GameTooltip:AddLine("类别：" .. category .. " · " .. state, 0.75, 0.85, 1, true)
            GameTooltip:AddLine(self.item.mailSlot and "此堆已添加；右键只撤回此附件。" or "此堆未添加；右键添加整堆，双击选择数量，也可拖拽。", 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function(self)
            G.ClearTooltip(); self:SetBackdropColor(unpack(ns.Theme.surface))
        end)
        button:EnableMouseWheel(true)
        button:SetScript("OnMouseWheel", function(_, delta) G.page = math.max(1, G.page - delta); G.Refresh() end)
        G.rows[index] = button
    end
    -- 已添加堆叠只在原材料格保留状态，不增加独立附件栏。
    G.previous = ns.UI.Button(frame, "上一页", 18, -585, 70, function() G.page = math.max(1, G.page - 1); G.Refresh() end)
    G.next = ns.UI.Button(frame, "下一页", 94, -585, 70, function() G.page = G.page + 1; G.Refresh() end)
    G.status = ns.UI.Label(frame, "", 180, -591, 296, 11, ns.Theme.muted)
    G.addAll = ns.UI.Button(frame, "一键添加", 516, -367, 106, function()
        local _, _, message = ns.MailController.AddProfession(G.filter, G.search:GetText(), G.itemCategory.value)
        ns.Print(message)
    end)
    G.addAll:SetScript("OnEnter", function(self)
        G.tooltipOwner = self
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("一键添加当前具体专业的材料", 1, 0.82, 0, true)
        GameTooltip:AddLine("包含当前搜索匹配的所有分页，整堆加入；附件满或操作受阻即停止，不发送邮件。", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    G.addAll:SetScript("OnLeave", G.ClearTooltip)
    G.hint=ns.UI.Label(frame, "一键添加仅具体专业可用；操作附件需切到原生发送页。", 18, -627, 604, 11, ns.Theme.muted)
    if SendMailFrame then
        SendMailFrame:HookScript("OnShow", ns.Refresh)
        SendMailFrame:HookScript("OnHide", ns.Refresh)
    end
end
function G.Refresh()
    if not G.category then return end
    G.ClearTooltip()
    local character, matched, total = ns.CharacterManager.Selected(), {}, 0
    G.FilterOptions(character)
    local attached = ns.MailController.AttachedRows()
    local attachedSlots = {}
    for _, row in ipairs(attached) do
        attachedSlots[row.bag .. ":" .. row.slot] = row
    end
    for _, row in ipairs(ns.InventoryScanner.Scan()) do
        -- 部分客户端附加后仍返回原背包中的锁定物品。该槽位只显示附件记录，
        -- 否则会生成两个相同格子，并把其他堆叠挤到不同的位置。
        local sent = attachedSlots[row.bag .. ":" .. row.slot]
        local duplicate = sent and row.locked and sent.itemID == row.itemID
            and sent.count == row.count and (not sent.link or sent.link == row.link)
        if not duplicate and ns.MaterialMatcher.Match(row, character and character.professions, G.filter, G.search:GetText())
            and ns.ItemClassifier.Match(row, G.itemCategory.value) then
            matched[#matched + 1] = row; total = total + row.count
        end
    end
    for _,row in ipairs(attached) do
        if ns.MaterialMatcher.Match(row, character and character.professions, G.filter, G.search:GetText())
            and ns.ItemClassifier.Match(row,G.itemCategory.value) then matched[#matched+1]=row end
    end
    -- 同种物品连续排列；组内按原背包位置稳定排序，名称缓存不会改变分组。
    table.sort(matched,function(a,b)
        if a.itemID~=b.itemID then return a.itemID<b.itemID end
        if (a.link or "")~=(b.link or "") then return (a.link or "")<(b.link or "") end
        if a.bag~=b.bag then return a.bag<b.bag end
        if a.slot~=b.slot then return a.slot<b.slot end
        if not not a.mailSlot~=not not b.mailSlot then return a.mailSlot~=nil end
        return (a.mailSlot or 0)<(b.mailSlot or 0)
    end)
    local pages = math.max(1, math.ceil(#matched / #G.rows))
    G.page = math.min(G.page, pages)
    for index, button in ipairs(G.rows) do
        local row = matched[(G.page - 1) * #G.rows + index]
        button.item = row
        button.attachedMark:SetShown(row~=nil and row.mailSlot~=nil)
        button:SetShown(row ~= nil)
        if row then
            button.icon:SetTexture(row.icon)
            button.icon:SetDesaturated(not not (row.mailSlot or row.locked))
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
    local specific = G.filter and G.filter > 0 and ns.ProfessionByID[G.filter] ~= nil
    local ready = ns.MailController.Guard()
    local free, available = false, false
    for index=1, ns.Compatibility.AttachmentLimit() do
        if not ns.Compatibility.HasAttachment(index) then free = true; break end
    end
    for _, row in ipairs(matched) do if not row.mailSlot and not row.locked then available = true; break end end
    G.addAll:SetEnabled(not not (specific and ready and free and available and ClickSendMailItemButton and GetSendMailItem))
    G.hint:SetText(ns.MailController.pendingQuantity and "正在等待拆分堆叠解锁后加入附件，最长4秒；请勿移动物品。"
        or "一键添加仅具体专业可用；操作附件需切到原生发送页。")
    local attached=0
    for _,row in ipairs(matched) do if row.mailSlot then attached=attached+1 end end
    G.status:SetText(string.format("背包%d件 · 已加%d堆 · %d/%d页",total,attached,G.page,pages))
end
