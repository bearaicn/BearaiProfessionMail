local _, ns = ...
local M = { open = false, trackedAttachments = {} }
ns.MailController = M
function M.IsOpen() return M.open and MailFrame and MailFrame:IsShown() end
function M.FillRecipient()
    local character = ns.CharacterManager.Selected()
    if not M.IsOpen() or not character or not SendMailNameEditBox then return false end
    if InCombatLockdown() then return false, "战斗中不修改收件人。" end
    local recipient = character.name
    if character.realm:gsub("%s", "") ~= GetRealmName():gsub("%s", "") then
        recipient = recipient .. "-" .. character.realm:gsub("%s", "")
    end
    SendMailNameEditBox:SetText(recipient)
    return true
end
function M.Guard()
    if not M.IsOpen() then return false, "请先打开邮箱。" end
    if M.pendingQuantity then return false,"正在等待拆分物品解锁并加入附件，请稍候。" end
    if not SendMailFrame or not SendMailFrame:IsShown() then return false, "请先切换到原生邮箱的发送邮件页。" end
    if InCombatLockdown() then return false, "战斗中不可从助手拾取材料。" end
    if CursorHasItem() or (GetCursorInfo and GetCursorInfo()) then return false, "请先放下鼠标上的物品。" end
    if (C_Mail and C_Mail.IsCommandPending and C_Mail.IsCommandPending())
        or (SendMailFrameLockSendMail and SendMailFrameLockSendMail:IsShown()) then
        return false, "邮箱正在处理操作或等待确认，请稍后重试。"
    end
    return true
end
function M.CheckRow(row)
    if row.mailSlot then return false,"该堆已在原生附件中，请右键撤回后操作。" end
    local live = ns.Compatibility.Item(row.bag, row.slot)
    if not live or live.itemID ~= row.itemID or live.stackCount ~= row.count
        or (row.link and live.hyperlink and row.link ~= live.hyperlink) then
        ns.Refresh(); return false, "背包槽位已变化，请重新拖拽。"
    end
    if live.isLocked or live.isBound or not ns.Compatibility.IsMailable(row) then return false, "物品已锁定、绑定或不可邮寄。" end
    return true
end
function M.Pickup(row, quantity)
    local ok, err = M.Guard()
    if not ok then return false, err end
    ok,err=M.CheckRow(row)
    if not ok then return false,err end
    if quantity ~= nil then
        if type(quantity) ~= "number" or quantity < 1 or quantity ~= math.floor(quantity) or quantity > row.count then
            return false, "数量必须是 1 到当前堆叠数量之间的整数。"
        end
        if quantity < row.count then
            return false,"部分数量请使用数量确认流程，等待拆分就绪后加入附件。"
        end
    end
    return ns.Compatibility.Pickup(row.bag, row.slot)
end
function M.QuantityAllowed(row)
    if not row or not row.itemID then return false,"物品信息尚未加载。" end
    if row.mailSlot then return false,"此堆已在附件中，请先右键撤回。" end
    return M.CheckRow(row)
end
function M.Add(row, deferRefresh, quantity)
    local ready, blocked = M.Guard()
    if not ready then return false, blocked end
    if quantity ~= nil then
        if type(quantity)~="number" or quantity<1 or quantity~=math.floor(quantity) or quantity>row.count then
            return false,"数量必须是1到当前堆叠数量之间的整数。"
        end
        local allowed, reason=M.QuantityAllowed(row)
        if not allowed then return false,reason end
    end
    if not ClickSendMailItemButton or not GetSendMailItem then return false, "客户端缺少附件操作 API，请使用拖拽。" end
    local free
    for index = 1, ns.Compatibility.AttachmentLimit() do
        if not ns.Compatibility.HasAttachment(index) then free = index; break end
    end
    if not free then return false, "原生邮件附件栏已满。" end
    if quantity and quantity < row.count then return M.StartQuantity(row,quantity) end
    local ok, err = M.Pickup(row, quantity)
    if not ok then return false, err end
    if not CursorHasItem() then return false, "物品未被拾取，请重新尝试。" end
    -- 来自玩家双击或一键添加按钮；只操作附件，不调用发送接口。
    local placed, reason = ns.Compatibility.ClickAttachment(free, false)
    if not placed then ns.Refresh(); return false, reason end
    if CursorHasItem() then ns.Refresh(); return false, "附件未被接受，物品仍在鼠标上，请放回背包或拖入附件栏。" end
    local tracked={}
    for key,value in pairs(row) do tracked[key]=value end
    tracked.mailSlot,tracked.attached,tracked.count=free,true,quantity or row.count
    M.trackedAttachments[free]=tracked
    if not deferRefresh then ns.Refresh() end
    if quantity ~= nil then
        local attachment = ns.Compatibility.Attachment(free)
        if not attachment then return false,"附件数量尚未读取，请核对原生附件后再操作。" end
        if attachment.itemID~=row.itemID or attachment.count~=quantity then
            return false,"附件数量与选择不符，请在原生邮箱撤回并核对；没有发送邮件。"
        end
    end
    return true
end
function M.CancelQuantity(reason)
    local pending=M.pendingQuantity
    if not pending then return end
    M.pendingQuantity=nil
    pending.finished,pending.success=true,false
    pending.message=reason .. " 已拆分物品保留在背包，未发送邮件。"
    ns.Print(pending.message)
    ns.Refresh()
end
function M.AdvanceQuantity(elapsed)
    local pending=M.pendingQuantity
    if not pending then return end
    pending.elapsed=pending.elapsed+(elapsed or 0)
    if pending.elapsed>=4 then M.CancelQuantity("等待拆分堆叠解锁超时。"); return end
    if elapsed and pending.elapsed-pending.lastPoll<0.1 then return end
    pending.lastPoll=pending.elapsed
    if not M.IsOpen() or not SendMailFrame or not SendMailFrame:IsShown() then M.CancelQuantity("邮箱或发件页已关闭。"); return end
    if not ns.MainFrame or not ns.MainFrame:IsShown() then M.CancelQuantity("助手已关闭。"); return end
    if InCombatLockdown() then M.CancelQuantity("已进入战斗，数量添加取消。"); return end
    if SendMailNameEditBox and SendMailNameEditBox:GetText()~=pending.recipient then M.CancelQuantity("收件人已变化，数量添加取消。"); return end
    if CursorHasItem() or (GetCursorInfo and GetCursorInfo()) then M.CancelQuantity("鼠标正在持有其他物品，数量添加取消。"); return end
    if (C_Mail and C_Mail.IsCommandPending and C_Mail.IsCommandPending())
        or (SendMailFrameLockSendMail and SendMailFrameLockSendMail:IsShown()) then return end
    local row=pending.row
    local item=ns.Compatibility.Item(row.bag,row.slot)
    if not item or not item.itemID or not item.stackCount or item.isLocked then return end
    if item.itemID~=row.itemID or item.stackCount~=row.count
        or (row.link and item.hyperlink and row.link~=item.hyperlink) then
        M.CancelQuantity("拆分目标槽位或数量变化，已停止。"); return
    end
    -- 只继续本次玩家确认的拆分堆叠；取消或完成后不再轮询任何物品。
    M.pendingQuantity=nil
    local ok,reason=M.Add(row,false,row.count)
    pending.finished,pending.success=true,ok
    pending.message=ok and ("已将所选 " .. row.count .. " 个物品加入原生附件。") or (reason or "数量添加未完成，请核对背包与附件。")
    ns.Print(pending.message)
    ns.Refresh()
end
function M.StartQuantity(row,quantity)
    local allowed,blocked=M.Guard()
    if not allowed then return false,blocked end
    if type(quantity)~="number" or quantity<1 or quantity~=math.floor(quantity) or quantity>=row.count then
        return false,"拆分数量必须是小于原堆叠的正整数。"
    end
    local ready,reason=M.CheckRow(row)
    if not ready then return false,reason end
    local ok,bag,slot,item=ns.Compatibility.SplitStackToBag(row.itemID,row.bag,row.slot,quantity)
    if not ok then ns.Refresh(); return false,bag end
    local part={}
    for key,value in pairs(row) do part[key]=value end
    part.bag,part.slot,part.count,part.link=bag,slot,quantity,(item and item.hyperlink) or row.link
    local pending={row=part,recipient=SendMailNameEditBox and SendMailNameEditBox:GetText() or "",elapsed=0,lastPoll=-1}
    M.pendingQuantity=pending
    M.AdvanceQuantity()
    if pending.finished then return pending.success,pending.message end
    ns.Print("已拆分，正在等待背包解锁后加入所选数量；最长等待4秒。")
    ns.Refresh()
    return true,"正在等待拆分堆叠解锁。"
end
function M.ToggleItem(row)
    local ready, reason = M.Guard()
    if not ready then return false, reason end
    if row.mailSlot then
        if M.trackedAttachments[row.mailSlot]~=row then return false,"附件记录已更新，请重新选择该堆。" end
        return M.Remove(row)
    end
    -- 真实背包格子永远是未添加堆叠；不能因别的同名堆叠已附加就撤回它。
    return M.Add(row)
end
function M.AttachedRows()
    local result={}
    if not M.IsOpen() then return result end
    for slot,row in pairs(M.trackedAttachments) do
        local item=ns.Compatibility.Attachment(slot)
        if item and item.itemID==row.itemID and item.count==row.count
            and (not row.link or item.link==row.link) then
            result[#result+1]=row
        elseif item or not ns.Compatibility.HasAttachment(slot) then
            M.trackedAttachments[slot]=nil
        end
    end
    return result
end
function M.RebindAttachments(removedSlot)
    local remaining={}
    for slot,row in pairs(M.trackedAttachments) do
        if slot~=removedSlot then remaining[#remaining+1]=row end
    end
    table.sort(remaining,function(a,b) return a.mailSlot<b.mailSlot end)
    M.trackedAttachments={}
    for _,row in ipairs(remaining) do
        for slot=1,ns.Compatibility.AttachmentLimit() do
            local item=ns.Compatibility.Attachment(slot)
            if not M.trackedAttachments[slot] and item and item.itemID==row.itemID and item.count==row.count
                and (not row.link or item.link==row.link) then
                row.mailSlot=slot; M.trackedAttachments[slot]=row; break
            end
        end
    end
end
function M.AddProfession(professionID, search, category)
    if not professionID or professionID <= 0 or not ns.ProfessionByID[professionID] then
        return false, 0, "请先在下拉框选择一个具体专业。"
    end
    local ready, reason = M.Guard()
    if not ready then return false, 0, reason end
    -- 从真实背包重新扫描，不依赖当前页格子；冻结本次点击的专业与搜索条件。
    local candidates, locked = {}, 0
    for _, row in ipairs(ns.InventoryScanner.Scan()) do
        if ns.MaterialMatcher.Match(row, nil, professionID, search) and ns.ItemClassifier.Match(row, category) then
            if row.locked then locked = locked + 1 else candidates[#candidates+1] = row end
        end
    end
    local added, stopped = 0, nil
    for _, row in ipairs(candidates) do
        local ok, err = M.Add(row, true)
        if not ok then stopped = err; break end
        added = added + 1
    end
    ns.Refresh()
    local message = string.format("已添加 %d 堆%s物品。", added, ns.ProfessionByID[professionID].name)
    if locked > 0 then message = message .. string.format("跳过 %d 堆锁定物品。", locked) end
    if stopped then message = message .. stopped
    elseif #candidates == 0 then message = message .. "当前筛选和搜索内没有可添加的材料。" end
    return added > 0, added, message .. "请在原生邮箱核对后自行发送。"
end
function M.Remove(row)
    local ok, err = M.Guard()
    if not ok then return false, err end
    if not row.itemID then return false, "附件信息尚未加载，请稍后再试。" end
    local slot = row.mailSlot
    if not slot then
        for index = ns.Compatibility.AttachmentLimit(), 1, -1 do
            local item = ns.Compatibility.Attachment(index)
            if item and item.itemID == row.itemID and (not row.link or item.link == row.link) then slot = index; break end
        end
    end
    local live = slot and ns.Compatibility.Attachment(slot)
    if not live or live.itemID ~= row.itemID or (row.mailSlot and (live.count ~= row.count or live.link ~= row.link)) then
        ns.Refresh(); return false, "未找到对应附件或附件已变化，请重新右击。"
    end
    local removed, reason = ns.Compatibility.ClickAttachment(slot, true)
    if removed then M.RebindAttachments(slot) end
    ns.Refresh()
    return removed, reason
end
