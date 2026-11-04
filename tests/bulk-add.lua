local M, G = NS.MailController, NS.MaterialGrid
local oldBags, oldMail, oldSlots = BAGS, MAIL_ITEMS, C_Container.GetContainerNumSlots
local oldRule, oldScan = NS.db.rules[2589], NS.InventoryScanner.Scan
local oldPending, oldSend, oldRecipient = C_Mail, SendMail, SendMailNameEditBox:GetText()
M.open = true; MailFrame:Show(); SendMailFrame:Show(); NS.MainFrame:Show()
NS.db.rules[2589] = {[197]=true}
C_Container.GetContainerNumSlots = function(bag) return bag==0 and 40 or 0 end
SendMail = function() error('一键添加不得发送邮件') end
local function bags(count)
    BAGS, MAIL_ITEMS = {[0]={}}, {}
    for slot=1,count do BAGS[0][slot]={itemID=2589,stackCount=slot,hyperlink='item:2589'} end
    CURSOR, COMBAT = false,false
    C_Mail=nil
    G.search:SetText(''); G.category:SetValue(197); G.Refresh()
end
bags(40)
for _, filter in ipairs({0,-1,-2}) do
    G.category:SetValue(filter)
    assert(not G.addAll.enabled)
    local ok,count = M.AddProfession(filter,'')
    assert(not ok and count==0 and next(MAIL_ITEMS)==nil)
end
G.category:SetValue(197)
assert(G.addAll.enabled)
G.search:SetText('不存在'); assert(not G.addAll.enabled)
local ok,count = M.AddProfession(197,'不存在')
assert(not ok and count==0 and next(MAIL_ITEMS)==nil)
G.search:SetText('2589'); G.page=2; G.Refresh()
-- 先保留一个原有附件，一键最多补 11 堆，扫描所有分页而非当前页。
MAIL_ITEMS[1]={itemID=999,name='已有附件',count=1,link='item:999'}
local existing = MAIL_ITEMS[1]
SendMailNameEditBox:SetText('玩家手改的收件人')
ok,count = M.AddProfession(197,'2589')
assert(ok and count==11 and MAIL_ITEMS[1]==existing)
assert(MAIL_ITEMS[2].sourceSlot==1 and MAIL_ITEMS[12].sourceSlot==11)
assert(BAGS[0][11]==nil and BAGS[0][12]~=nil and not CURSOR)
assert(SendMailNameEditBox:GetText()=='玩家手改的收件人')
G.Refresh(); assert(not G.addAll.enabled)
ok,count = M.AddProfession(197,'2589'); assert(not ok and count==0)
-- 名称搜索、用户覆盖、锁定和绑定：只添加符合条件的那堆。
bags(3)
BAGS[0][1].isLocked=true; BAGS[0][2].isBound=true
ok,count = M.AddProfession(197,'亚麻')
assert(ok and count==1 and MAIL_ITEMS[1].sourceSlot==3)
assert(BAGS[0][1] and BAGS[0][2])
bags(3); NS.db.rules[2589]={}
ok,count = M.AddProfession(197,''); assert(not ok and count==0)
NS.db.rules[2589]={[197]=true}
-- 各种受阻状态不得拾取物品。
for _, state in ipairs({'combat','cursor','pending','send-hidden','mail-closed'}) do
    bags(3)
    if state=='combat' then COMBAT=true
    elseif state=='cursor' then CURSOR=true
    elseif state=='pending' then C_Mail={IsCommandPending=function() return true end}
    elseif state=='send-hidden' then SendMailFrame:Hide()
    else M.open=false end
    G.Refresh(); assert(not G.addAll.enabled)
    ok,count = M.AddProfession(197,'')
    assert(not ok and count==0 and next(MAIL_ITEMS)==nil and BAGS[0][1])
    CURSOR, COMBAT, C_Mail, M.open = false,false,nil,true
    SendMailFrame:Show()
end
-- 中途失败立即停止，不用定时器或后续事件继续操作。
bags(3)
local originalAdd, attempts = M.Add,0
M.Add=function(row,defer)
    attempts=attempts+1
    if attempts==2 then return false,'模拟中途受阻' end
    return originalAdd(row,defer)
end
ok,count = M.AddProfession(197,'')
M.Add=originalAdd
assert(ok and count==1 and attempts==2 and BAGS[0][2] and BAGS[0][3])
NS.events.scripts.OnEvent(NS.events,'MAIL_SEND_INFO_UPDATE')
assert(attempts==2 and BAGS[0][2], '操作停止后不得在事件中继续添加')
bags(3)
G.addAll.scripts.OnClick()
assert(MAIL_ITEMS[1] and MAIL_ITEMS[2] and MAIL_ITEMS[3], '按钮回调接通批量附件逻辑')
BAGS,MAIL_ITEMS,C_Container.GetContainerNumSlots = oldBags,oldMail,oldSlots
NS.db.rules[2589],NS.InventoryScanner.Scan = oldRule,oldScan
C_Mail,SendMail = oldPending,oldSend
SendMailNameEditBox:SetText(oldRecipient)
CURSOR,COMBAT=false,false
M.open=false; NS.MainFrame:Hide()
print('PASS: 仅具体专业一键添加/全分页及搜索/用户规则/保留附件收件人/满栏停止/中途受阻不续跑/不发送')
