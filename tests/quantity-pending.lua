local M,Q=NS.MailController,NS.QuantityDialog
local oldBags,oldMail,oldPickup=BAGS,MAIL_ITEMS,C_Container.PickupContainerItem
local oldRecipient=SendMailNameEditBox:GetText()
local function reset()
    M.pendingQuantity=nil
    BAGS={[0]={[1]={itemID=2589,stackCount=20,hyperlink='item:2589'}}}; MAIL_ITEMS={}
    CURSOR,COMBAT=false,false; SPLIT_PICKED=nil
    M.open=true; MailFrame:Show(); SendMailFrame:Show(); NS.MainFrame:Show()
    SendMailNameEditBox:SetText('数量测试收件人')
    C_Container.PickupContainerItem=function(bag,slot)
        local dropping=CURSOR and SPLIT_PICKED~=nil
        oldPickup(bag,slot)
        if dropping then BAGS[bag][slot].isLocked=true end
    end
    return NS.InventoryScanner.Scan()[1]
end
local row=reset()
assert(Q.Open(row)); Q.input:SetText('7'); Q.confirm.scripts.OnClick()
assert(M.pendingQuantity and BAGS[0][1].stackCount==13 and next(MAIL_ITEMS)==nil,
    '客户端锁定新拆分堆叠时应等待，而不是只拆分后放弃')
assert(not M.AddProfession(197,''), '等待期间不得启动其他附件操作')
local pending=M.pendingQuantity
BAGS[pending.row.bag][pending.row.slot].isLocked=false
NS.events.scripts.OnEvent(NS.events,'ITEM_LOCK_CHANGED')
assert(not M.pendingQuantity and MAIL_ITEMS[1].count==7 and BAGS[0][1].stackCount==13 and not CURSOR)
-- 无解锁事件时也能轮询完成。
row=reset(); assert(M.Add(row,false,5))
pending=M.pendingQuantity; BAGS[pending.row.bag][pending.row.slot].isLocked=false
NS.events.scripts.OnUpdate(NS.events,0.2)
assert(MAIL_ITEMS[1].count==5 and not M.pendingQuantity)
row=reset()
assert(not M.Add(row,false,1.5) and BAGS[0][1].stackCount==20 and not M.pendingQuantity)
-- 等待不能无限持续，超时留在背包且没有附件。
row=reset(); assert(M.Add(row,false,4))
NS.events.scripts.OnUpdate(NS.events,5)
assert(not M.pendingQuantity and next(MAIL_ITEMS)==nil and BAGS[0][1].stackCount==16)
for _,reason in ipairs({'mail-close','combat','recipient','slot','cursor','assistant-close'}) do
    row=reset(); assert(M.Add(row,false,3)); pending=M.pendingQuantity
    BAGS[pending.row.bag][pending.row.slot].isLocked=false
    if reason=='mail-close' then M.open=false
    elseif reason=='combat' then COMBAT=true
    elseif reason=='recipient' then SendMailNameEditBox:SetText('另一个人')
    elseif reason=='slot' then BAGS[pending.row.bag][pending.row.slot].itemID=2770
    elseif reason=='cursor' then CURSOR=true
    else NS.MainFrame:Hide() end
    NS.events.scripts.OnUpdate(NS.events,0.2)
    assert(not M.pendingQuantity and next(MAIL_ITEMS)==nil, '等待取消后不得继续加入附件：' .. reason)
end
M.pendingQuantity=nil; CURSOR,COMBAT=false,false
C_Container.PickupContainerItem=oldPickup
BAGS,MAIL_ITEMS=oldBags,oldMail
SendMailNameEditBox:SetText(oldRecipient)
M.open=false; NS.MainFrame:Hide()
print('PASS: 拆分后等待锁定解除再附加/事件与轮询/超时/收件人槽位战斗关闭取消/无自动发送')
