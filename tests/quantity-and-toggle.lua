local M,Q,G = NS.MailController,NS.QuantityDialog,NS.MaterialGrid
local oldBags, oldMail = BAGS,MAIL_ITEMS
local oldSplit, oldLegacySplit = C_Container.SplitContainerItem,SplitContainerItem
local oldTabs,oldSendTab,oldNative = MailFrame.Tabs,MailFrameTab2,MailFrameTab_OnClick
local oldRecipient=SendMailNameEditBox:GetText()
local function reset()
    BAGS={[0]={[1]={itemID=2589,stackCount=20,hyperlink='item:2589'}}}
    MAIL_ITEMS={}; CURSOR=false; SPLIT_PICKED=nil; COMBAT=false
    M.open=true; MailFrame:Show(); SendMailFrame:Show(); NS.MainFrame:Show()
    G.category:SetValue(197); G.search:SetText(''); G.Refresh()
    return NS.InventoryScanner.Scan()[1]
end
local row=reset()
G.rows[1].scripts.OnClick(G.rows[1],'RightButton')
assert(MAIL_ITEMS[1].count==20 and BAGS[0][1]==nil, '无附件右击添加整堆')
assert(M.ToggleItem(M.AttachedRows()[1]))
assert(MAIL_ITEMS[1]==nil and BAGS[0][1].stackCount==20, '有附件右击撤回')
row=reset()
MAIL_ITEMS[1]={itemID=2589,count=3,name='同ID不同链接',link='item:2589:99'}
assert(M.ToggleItem(row) and MAIL_ITEMS[1].count==3 and MAIL_ITEMS[2].count==20,
    '不应撤回同ID但不同物品链接的附件')
row=reset()
MAIL_ITEMS[1]={itemID=2589,count=3}
local ok=M.ToggleItem(row)
assert(ok and MAIL_ITEMS[2].count==20, '真实背包新堆只添加到空附件位，不撤未知附件')
row=reset()
G.rows[1].scripts.OnDoubleClick(G.rows[1],'LeftButton')
assert(Q.frame:IsShown() and next(MAIL_ITEMS)==nil and Q.input:GetText()=='20')
Q.input:SetText('7'); Q.confirm.scripts.OnClick()
assert(MAIL_ITEMS[1].count==7 and BAGS[0][1].stackCount==13 and not CURSOR and not Q.frame:IsShown())
assert(MAIL_ITEMS[1].sourceSlot~=1, '选定数量先落成独立背包堆叠，再按真实新槽位加入邮件')
row=NS.InventoryScanner.Scan()[1]
assert(not Q.Open(M.AttachedRows()[1]), '已添加堆叠不能再次双击')
assert(BAGS[0][1].stackCount==13 and MAIL_ITEMS[1].count==7)
MAIL_ITEMS={}
assert(Q.Open(row)); Q.cancel.scripts.OnClick()
assert(BAGS[0][1].stackCount==13 and MAIL_ITEMS[2]==nil)
for _,text in ipairs({'0','14','1.5','abc'}) do
    assert(Q.Open(row)); Q.input:SetText(text); Q.confirm.scripts.OnClick()
    assert(Q.frame:IsShown() and BAGS[0][1].stackCount==13 and MAIL_ITEMS[2]==nil)
    Q.cancel.scripts.OnClick()
end
assert(Q.Open(row)); BAGS[0][1].stackCount=12
Q.input:SetText('2'); Q.confirm.scripts.OnClick()
assert(BAGS[0][1].stackCount==12 and MAIL_ITEMS[2]==nil, '确认时再次校验真实堆叠')
Q.cancel.scripts.OnClick()
row=reset()
assert(Q.Open(row))
MAIL_ITEMS[1]={itemID=2589,count=1,name='窗口打开后新增',link='item:2589'}
BAGS[0][1]=nil
Q.input:SetText('5'); Q.confirm.scripts.OnClick()
assert(BAGS[0][1]==nil and MAIL_ITEMS[2]==nil and not CURSOR,
    '数量框打开后再添加同物品，确认时必须拦截，不能拆分')
Q.cancel.scripts.OnClick()
row=reset()
MAIL_ITEMS[1]={itemID=2589,count=1}
assert(Q.Open(row) and BAGS[0][1].stackCount==20, '未知附件不影响其他真实背包堆选择数量')
Q.cancel.scripts.OnClick()
row=reset(); C_Container.SplitContainerItem=nil; SplitContainerItem=nil
assert(Q.Open(row)); Q.input:SetText('3'); Q.confirm.scripts.OnClick()
assert(BAGS[0][1].stackCount==20 and next(MAIL_ITEMS)==nil and not CURSOR, '没有拆分接口不拾取物品')
Q.cancel.scripts.OnClick()
SplitContainerItem=oldSplit
assert(Q.Open(row)); Q.input:SetText('3'); Q.confirm.scripts.OnClick()
assert(MAIL_ITEMS[1].count==3 and BAGS[0][1].stackCount==17, '旧拆分API回退')
C_Container.SplitContainerItem,SplitContainerItem=oldSplit,oldLegacySplit
row=reset(); assert(Q.Open(row)); COMBAT=true
Q.confirm.scripts.OnClick()
assert(BAGS[0][1].stackCount==20 and next(MAIL_ITEMS)==nil)
COMBAT=false; Q.cancel.scripts.OnClick()
-- 背包满时不能拆分，更不能退回添加整堆。
row=reset()
BAGS[0][2]={itemID=2770,stackCount=1}; BAGS[0][3]={itemID=2770,stackCount=1}
assert(Q.Open(row)); Q.input:SetText('4'); Q.confirm.scripts.OnClick()
assert(BAGS[0][1].stackCount==20 and next(MAIL_ITEMS)==nil and not CURSOR)
Q.cancel.scripts.OnClick()
-- 专用袋有空位也不盲目使用；普通袋空位可作为独立拆分目标。
local oldFree,oldSlots=C_Container.GetContainerNumFreeSlots,C_Container.GetContainerNumSlots
C_Container.GetContainerNumSlots=function(bag) return bag==0 and 3 or (bag==1 and 1 or 0) end
BAGS[1]={}
C_Container.GetContainerNumFreeSlots=function(bag) return bag==1 and 1 or 0,32 end
local result=M.Add(row,false,4)
assert(not result and BAGS[0][1].stackCount==20 and BAGS[1][1]==nil)
C_Container.GetContainerNumFreeSlots=function() return 1,0 end
assert(M.Add(row,false,4))
assert(BAGS[0][1].stackCount==16 and MAIL_ITEMS[1].count==4 and not CURSOR)
C_Container.GetContainerNumFreeSlots,C_Container.GetContainerNumSlots=oldFree,oldSlots
-- 客户端未及时返回新堆叠时停止，不把旧来源整堆加入邮件。
row=reset()
local pickupAPI=C_Container.PickupContainerItem
C_Container.PickupContainerItem=function(bag,slot)
    local wasSplit=CURSOR and SPLIT_PICKED~=nil
    pickupAPI(bag,slot)
    if wasSplit then BAGS[bag][slot].stackCount=999 end
end
assert(not M.Add(row,false,5) and next(MAIL_ITEMS)==nil and BAGS[0][1].stackCount==15)
C_Container.PickupContainerItem=pickupAPI
row=reset()
assert(Q.Open(row)); NS.MainFrame:Hide()
assert(not Q.frame:IsShown() and Q.row==nil, '关闭助手取消数量框')
-- 入口走原生按钮点击，以保留其他邮箱插件的点击钩子。
local clicks=0
local tab=CreateFrame('Button',nil,MailFrame)
tab.Click=function(_,button) assert(button=='LeftButton'); clicks=clicks+1; SendMailFrame:Show() end
MailFrame.Tabs={MailFrameTab1,tab}; MailFrameTab2=nil
local draft={itemID=999,count=1,name='草稿附件',link='item:999'}
MAIL_ITEMS[1]=draft; SendMailNameEditBox:SetText('保留草稿收件人')
SendMailFrame:Hide()
NS.MailButton.Toggle()
assert(clicks==1 and NS.MainFrame:IsShown() and SendMailFrame:IsShown())
assert(MAIL_ITEMS[1]==draft and SendMailNameEditBox:GetText()=='保留草稿收件人')
G.Refresh(); assert(G.addAll.enabled, '进入发件箱后具体专业一键添加可用')
tab.Click=nil
SendMailFrame:Hide()
MailFrameTab_OnClick=function(button,id) assert(button==tab and id==2); clicks=clicks+1; SendMailFrame:Show() end
assert(NS.Compatibility.ShowSend() and clicks==2)
SendMailFrame:Hide()
COMBAT=true; assert(not NS.Compatibility.ShowSend() and clicks==2); COMBAT=false
MailFrameTab_OnClick=nil
assert(not NS.Compatibility.ShowSend())
NS.MailButton.Visibility(); assert(NS.MailButton.button:IsShown(), '首次邮箱打开即显示，不因接口未就绪而隐藏')
SendMailFrame:Show(); NS.MailButton.Visibility(); assert(NS.MailButton.button:IsShown())
MailFrame.Tabs,MailFrameTab2,MailFrameTab_OnClick=oldTabs,oldSendTab,oldNative
BAGS,MAIL_ITEMS=oldBags,oldMail
SendMailNameEditBox:SetText(oldRecipient)
M.open=false; NS.MainFrame:Hide(); CURSOR=false; SPLIT_PICKED=nil
print('PASS: 右击添加或撤回/数量与拆分/入口切原生第二标签发件箱/保留草稿/无接口显示降级')
