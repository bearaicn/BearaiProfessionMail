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
function M.Pickup(row)
    if not M.IsOpen() then return false, "请先打开邮箱。" end
    if not SendMailFrame or not SendMailFrame:IsShown() then return false, "请先切换到原生邮箱的发送邮件页。" end
    if InCombatLockdown() then return false, "战斗中不可从助手拾取材料。" end
    if CursorHasItem() or (GetCursorInfo and GetCursorInfo()) then return false, "请先放下鼠标上的物品。" end
    local live = ns.Compatibility.Item(row.bag, row.slot)
    if not live or live.itemID ~= row.itemID or live.stackCount ~= row.count then
        ns.Refresh(); return false, "背包槽位已变化，请重新拖拽。"
    end
    if live.isLocked or live.isBound then return false, "物品已锁定或绑定，不可拾取。" end
    return ns.Compatibility.Pickup(row.bag, row.slot)
end
