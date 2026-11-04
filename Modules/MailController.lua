local _, ns = ...
local M = { open = false }
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
    if not SendMailFrame or not SendMailFrame:IsShown() then return false, "请先切换到原生邮箱的发送邮件页。" end
    if InCombatLockdown() then return false, "战斗中不可从助手拾取材料。" end
    if CursorHasItem() or (GetCursorInfo and GetCursorInfo()) then return false, "请先放下鼠标上的物品。" end
    if (C_Mail and C_Mail.IsCommandPending and C_Mail.IsCommandPending())
        or (SendMailFrameLockSendMail and SendMailFrameLockSendMail:IsShown()) then
        return false, "邮箱正在处理操作或等待确认，请稍后重试。"
    end
    return true
end
function M.Pickup(row)
    local ok, err = M.Guard()
    if not ok then return false, err end
    local live = ns.Compatibility.Item(row.bag, row.slot)
    if not live or live.itemID ~= row.itemID or live.stackCount ~= row.count then
        ns.Refresh(); return false, "背包槽位已变化，请重新拖拽。"
    end
    if live.isLocked or live.isBound or not ns.Compatibility.IsMailable(row) then return false, "物品已锁定、绑定或不可邮寄。" end
    return ns.Compatibility.Pickup(row.bag, row.slot)
end
function M.Add(row)
    local ready, blocked = M.Guard()
    if not ready then return false, blocked end
    if not ClickSendMailItemButton or not GetSendMailItem then return false, "客户端缺少附件操作 API，请使用拖拽。" end
    local free
    for index = 1, ns.Compatibility.AttachmentLimit() do
        if not ns.Compatibility.HasAttachment(index) then free = index; break end
    end
    if not free then return false, "原生邮件附件栏已满。" end
    local ok, err = M.Pickup(row)
    if not ok then return false, err end
    if not CursorHasItem() then return false, "物品未被拾取，请重新尝试。" end
    -- 仅硬件双击回调执行一次附件放置，绝不调用发送接口。
    local placed, reason = ns.Compatibility.ClickAttachment(free, false)
    ns.Refresh()
    if not placed then return false, reason end
    if CursorHasItem() then return false, "附件未被接受，物品仍在鼠标上，请放回背包或拖入附件栏。" end
    return true
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
    ns.Refresh()
    return removed, reason
end
