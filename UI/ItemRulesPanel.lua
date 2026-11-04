local _, ns = ...
local UI, M = ns.UI, ns.MaterialMatcher
local unpack = unpack or table.unpack
local R = { rows={}, cache={}, offset=0 }
ns.ItemRulesPanel = R
local function validID(text)
    local id = tonumber(text)
    return id and id > 0 and id == math.floor(id) and id or nil
end
local function sourceText(id)
    local source, hasAssistant = M.Source(id)
    if source == "user" then return hasAssistant and "用户数据（覆盖助手）" or "用户数据" end
    return source == "assistant" and "助手数据" or "游戏分类（用途未收录）"
end
local function professionText(professions)
    return next(professions) and ns.ProfessionManager.Text(professions) or "排除专业匹配"
end
local function itemInfo(id)
    if not R.cache[id] then
        local name, icon = ns.Compatibility.ItemPreview(id)
        R.cache[id] = { name=name, icon=icon }
    end
    return R.cache[id]
end
local function preview()
    local editor = R.editor
    local id = validID(editor.first:GetText())
    editor.itemDrop.itemID = id
    local info = id and itemInfo(id) or {}
    editor.itemDrop.icon:SetTexture(info.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    editor.itemName:SetText(id and (info.name or ("物品 " .. id .. "（名称待读取）")) or "拖入物品，或输入 ID")
    local source = id and sourceText(id) or "尚未保存"
    if id and M.Source(id)=="new" then
        local class,_,_,subclass=ns.Compatibility.ItemDetails(id)
        local _, category=ns.ItemClassifier.Classify({classID=class,subclassID=subclass})
        source=source .. " · " .. category
    end
    editor.source:SetText("来源：" .. source)
    editor.restore:SetEnabled(id ~= nil and ns.db.rules[id] ~= nil)
end
function R.Edit(id)
    R.selected = id
    R.editor.first:SetText(id and tostring(id) or "")
    R.editor.status:SetText("新增和修改均保存为用户数据。\n全不选表示排除专业匹配；删除用户规则可恢复助手数据。")
    R.Refresh()
end
function R.ReceiveItem()
    if not R.frame:IsShown() then return end
    local id = ns.Compatibility.CursorItemID()
    if not id then R.editor.status:SetText("请从背包拖入一个物品；也可输入 ID。"); return end
    if not ClearCursor then R.editor.status:SetText("客户端缺少光标归还接口，请输入 ID。"); return end
    ClearCursor()
    R.Edit(id)
    R.editor.first:ClearFocus()
    R.editor.status:SetText("已读取物品，原物品仍在背包。\n勾选专业后点击“保存为用户规则”。")
end
function R.Filtered()
    local result = {}
    local query = string.lower((R.search:GetText() or ""):match("^%s*(.-)%s*$"))
    local entries = M.List()
    if R.filter.value=="unmapped" then
        entries={}
        local seen={}
        for _, row in ipairs(ns.InventoryScanner.Scan()) do
            if not seen[row.itemID] and M.Source(row.itemID)=="new" then
                local _, categoryName = ns.ItemClassifier.Classify(row)
                entries[#entries+1]={itemID=row.itemID,professions={},source="unmapped",categoryName=categoryName}
                seen[row.itemID]=true
            end
        end
        table.sort(entries,function(a,b) return a.itemID<b.itemID end)
    end
    for _, entry in ipairs(entries) do
        local info = itemInfo(entry.itemID)
        local text = tostring(entry.itemID) .. " " .. (info.name or "")
        if (R.filter.value == "all" or R.filter.value == entry.source) and string.lower(text):find(query, 1, true) then
            result[#result+1] = entry
        end
    end
    return result
end
function R.Scroll(delta)
    R.offset = math.max(0, R.offset + delta)
    R.Refresh()
end
function R.Refresh()
    if not R.frame or not R.frame:IsShown() then return end
    local entries = R.Filtered()
    R.offset = math.max(0, math.min(R.offset, math.max(0, #entries - #R.rows)))
    for index, row in ipairs(R.rows) do
        local entry = entries[R.offset + index]
        row.itemID = entry and entry.itemID
        row:SetShown(entry ~= nil)
        if entry then
            local info = itemInfo(entry.itemID)
            row.icon:SetTexture(info.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.name:SetText((info.name or "物品名称待读取") .. " · " .. entry.itemID)
            row.professions:SetText(entry.source=="unmapped" and (entry.categoryName .. " · 专业用途未收录") or professionText(entry.professions))
            row.source:SetText(sourceText(entry.itemID))
            row:SetBackdropColor(unpack(entry.itemID == R.selected and ns.Theme.selected or ns.Theme.surface))
        end
    end
    R.count:SetText(string.format("%d 个物品 · %d–%d · 滚轮浏览", #entries,
        #entries > 0 and R.offset+1 or 0, math.min(R.offset+#R.rows, #entries)))
    preview()
end
local function tooltip(button)
    if not button.itemID then return end
    R.tooltipOwner = button
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink("item:" .. button.itemID)
    GameTooltip:AddLine(sourceText(button.itemID), 1, 0.82, 0, true)
    if M.Source(button.itemID)=="new" then
        local class,_,_,subclass=ns.Compatibility.ItemDetails(button.itemID)
        local _, category=ns.ItemClassifier.Classify({classID=class,subclassID=subclass})
        GameTooltip:AddLine(category .. " · 专业用途未收录",0.85,0.9,1,true)
    else GameTooltip:AddLine(professionText(M.Rule(button.itemID)), 0.85, 0.9, 1, true) end
    GameTooltip:Show()
end
local function hideTooltip()
    if R.tooltipOwner then GameTooltip:Hide(); R.tooltipOwner = nil end
end
function R.Create()
    if R.frame then return end
    local frame = UI.Panel("BearaiProfessionMailItemRules", UIParent, 960, 590)
    R.frame = frame
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    UI.Brand(frame, 18, -12)
    UI.Label(frame, "物品规则管理", 600, -20, 280, 16, ns.Theme.accent)
    UI.Label(frame, "按名称 / ID 搜索", 18, -64, 260, 10, ns.Theme.muted)
    R.search = UI.Edit(frame, 18, -82, 280)
    R.search:SetScript("OnTextChanged", function() R.offset=0; R.Refresh() end)
    R.filter = UI.Dropdown(frame, 310, -82, 250, function() R.offset=0; R.Refresh() end)
    R.filter:SetOptions({ {value="all",text="全部来源"}, {value="assistant",text="助手数据（当前生效）"}, {value="user",text="用户数据（优先生效）"}, {value="unmapped",text="用途未收录（当前背包）"} })
    R.filter:SetValue("all", true)
    UI.Label(frame, "物品 / ID / 生效专业", 24, -121, 325, 11, ns.Theme.muted)
    UI.Label(frame, "生效来源", 378, -121, 180, 11, ns.Theme.muted)
    for index=1,9 do
        local row = CreateFrame("Button", nil, frame, "BackdropTemplate")
        row:SetPoint("TOPLEFT", 18, -143-(index-1)*43)
        row:SetSize(542, 42)
        UI.Paint(row)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("TOPLEFT", 4, -4); row.icon:SetSize(34,34)
        row.name = UI.Label(row, "", 46, -3, 306, 12)
        row.professions = UI.Label(row, "", 46, -23, 306, 10, ns.Theme.muted)
        row.source = UI.Label(row, "", 360, -14, 176, 11, ns.Theme.accent)
        row:SetScript("OnClick", function(self) if self.itemID then R.Edit(self.itemID) end end)
        row:SetScript("OnEnter", tooltip)
        row:SetScript("OnLeave", hideTooltip)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, delta) R.Scroll(-delta) end)
        R.rows[index] = row
    end
    R.count = UI.Label(frame, "", 18, -548, 458, 11, ns.Theme.muted)
    UI.Button(frame, "↑", 488, -541, 32, function() R.Scroll(-9) end)
    UI.Button(frame, "↓", 528, -541, 32, function() R.Scroll(9) end)
    local editor = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    R.editor = editor
    editor:SetPoint("TOPLEFT", 580, -78); editor:SetSize(360, 492)
    UI.Paint(editor)
    UI.Label(editor, "物品归属 · 编辑后保存为用户规则", 14, -13, 330, 12, ns.Theme.accent)
    UI.Label(editor, "物品 ID", 84, -47, 150, 10, ns.Theme.muted)
    editor.first = UI.Edit(editor, 84, -64, 260)
    editor.itemDrop = CreateFrame("Button", nil, editor, "BackdropTemplate")
    editor.itemDrop:SetPoint("TOPLEFT", 14, -47); editor.itemDrop:SetSize(56,56)
    UI.Paint(editor.itemDrop, ns.Theme.surface, ns.Theme.accent)
    editor.itemDrop.icon = editor.itemDrop:CreateTexture(nil, "ARTWORK")
    editor.itemDrop.icon:SetPoint("TOPLEFT",3,-3); editor.itemDrop.icon:SetPoint("BOTTOMRIGHT",-3,3)
    editor.itemDrop:RegisterForClicks("LeftButtonUp")
    editor.itemDrop:SetScript("OnReceiveDrag", R.ReceiveItem)
    editor.itemDrop:SetScript("OnClick", R.ReceiveItem)
    editor.itemDrop:SetScript("OnEnter", tooltip); editor.itemDrop:SetScript("OnLeave", hideTooltip)
    editor.itemName = UI.Label(editor, "", 14, -112, 330, 12)
    editor.itemName:SetHeight(34); editor.itemName:SetWordWrap(true)
    editor.source = UI.Label(editor, "", 14, -150, 330, 11, ns.Theme.accent)
    editor.checks = {}
    for index, profession in ipairs(ns.Professions) do
        local check = CreateFrame("CheckButton", nil, editor, "UICheckButtonTemplate")
        check:SetSize(24,24)
        check:SetPoint("TOPLEFT", 10+((index-1)%3)*114, -180-math.floor((index-1)/3)*29)
        UI.Label(check, profession.name, 25,-5,85,11)
        editor.checks[profession.id] = check
    end
    editor.save = UI.Button(editor, "保存为用户规则", 14,-338,330,function()
        local chosen = {}
        for id, check in pairs(editor.checks) do if check:GetChecked() then chosen[id]=true end end
        local ok, err = M.SetRule(editor.first:GetText(), chosen)
        if not ok then editor.status:SetText(err); return end
        R.selected = tonumber(editor.first:GetText())
        ns.Refresh()
        editor.status:SetText("已保存到用户数据，优先于助手数据。\n退出游戏或 /reload 时写入磁盘。")
    end)
    editor.restore = UI.Button(editor, "删除用户规则 / 恢复助手数据",14,-375,330,function()
        local id = validID(editor.first:GetText())
        if not id or ns.db.rules[id] == nil then return end
        M.SetRule(id,nil)
        R.Edit(id)
        ns.Refresh()
        editor.status:SetText("已删除该物品的用户规则。\n有助手数据则自动恢复，否则从规则列表移除。")
    end)
    editor.status = UI.Label(editor, "",14,-417,330,11,ns.Theme.muted)
    editor.status:SetHeight(62); editor.status:SetWordWrap(true)
    editor.first:SetScript("OnTextChanged",function(self)
        local id = validID(self:GetText())
        R.selected = id
        local rule = id and M.Rule(id) or {}
        for key, check in pairs(editor.checks) do check:SetChecked(rule[key] == true) end
        preview()
    end)
    R.newButton = UI.Button(frame,"新增物品",600,-48,120,function()
        R.filter:SetValue("all", true); R.search:SetText(""); R.offset=0; R.Edit(nil)
    end)
    frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    frame:SetScript("OnEvent",function(_,_,id,success)
        if success == false then return end
        id = tonumber(id)
        if id and R.cache[id] then
            local name, icon = ns.Compatibility.ItemPreview(id)
            R.cache[id] = {name=name,icon=icon}
            R.Refresh()
        end
    end)
    frame:SetScript("OnShow",function()
        frame:SetScale(math.max(0.6,math.min(1,(UIParent:GetWidth()-32)/960,(UIParent:GetHeight()-32)/590)))
        R.Refresh()
    end)
    frame:SetScript("OnHide",function() UI.CloseDropdown(); hideTooltip(); R.search:ClearFocus(); editor.first:ClearFocus() end)
    frame:Hide()
end
function R.Open(id)
    UI.CloseDropdown()
    R.Create()
    R.frame:Show()
    R.Edit(id)
end
