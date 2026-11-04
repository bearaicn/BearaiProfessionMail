local _, ns = ...
local Q = {}
ns.QuantityDialog = Q
function Q.Open(row)
    local ready, reason = ns.MailController.Guard()
    if not ready then return false, reason end
    if not row or not row.count or row.count < 1 then return false, "物品数量尚未加载。" end
    local allowed, blocked = ns.MailController.QuantityAllowed(row)
    if not allowed then return false, blocked end
    if not Q.frame then
        local UI = ns.UI
        local frame = UI.Panel("BearaiProfessionMailQuantity", ns.MainFrame or UIParent, 360, 238)
        Q.frame = frame
        frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG")
        frame:SetFrameLevel((ns.MainFrame and ns.MainFrame:GetFrameLevel() or 10)+30)
        UI.Label(frame,"选择添加数量",18,-16,300,14,ns.Theme.accent)
        Q.name = UI.Label(frame,"",18,-48,324,12)
        Q.name:SetHeight(35); Q.name:SetWordWrap(true)
        Q.limit = UI.Label(frame,"",18,-87,324,11,ns.Theme.muted)
        Q.input = UI.Edit(frame,18,-109,140)
        Q.input:SetMaxLetters(8)
        local function change(delta)
            local value = math.floor(tonumber(Q.input:GetText()) or 1)
            Q.input:SetText(tostring(math.max(1,math.min(Q.row.count,value+delta))))
        end
        UI.Button(frame,"−",168,-109,36,function() change(-1) end)
        UI.Button(frame,"＋",210,-109,36,function() change(1) end)
        UI.Button(frame,"整堆",252,-109,90,function() Q.input:SetText(tostring(Q.row.count)) end)
        Q.status = UI.Label(frame,"",18,-148,324,11,ns.Theme.muted)
        Q.status:SetHeight(38); Q.status:SetWordWrap(true)
        Q.confirm = UI.Button(frame,"添加附件",18,-196,146,function()
            if not Q.row then return end
            local quantity = tonumber(Q.input:GetText())
            if not quantity or quantity < 1 or quantity ~= math.floor(quantity) or quantity > Q.row.count then
                Q.status:SetText("请输入 1 到 " .. Q.row.count .. " 之间的整数。"); return
            end
            local ok, err = ns.MailController.Add(Q.row, false, quantity)
            if ok then frame:Hide() else Q.status:SetText(err) end
        end)
        Q.cancel = UI.Button(frame,"取消",196,-196,146,function() frame:Hide() end)
        frame:SetScript("OnHide",function() Q.row=nil; Q.input:ClearFocus() end)
        frame:Hide()
    end
    Q.row = {}
    for key,value in pairs(row) do Q.row[key]=value end
    Q.name:SetText(row.name or ("物品 " .. row.itemID))
    Q.limit:SetText("可选数量：1–" .. row.count .. "（仅此背包堆叠）")
    Q.input:SetText(tostring(row.count))
    Q.status:SetText("部分数量需一个普通背包空格；确认后加入附件，不发送邮件。")
    Q.frame:Show()
    return true
end
