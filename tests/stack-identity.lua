local M,G=NS.MailController,NS.MaterialGrid
local oldBags,oldMail,oldTracked=BAGS,MAIL_ITEMS,M.trackedAttachments
local oldRule=NS.db.rules[2589]
BAGS={[0]={
    [1]={itemID=2589,stackCount=20,hyperlink='item:2589'},
    [2]={itemID=2589,stackCount=10,hyperlink='item:2589'},
    [3]={itemID=2770,stackCount=3,hyperlink='item:2770'},
}}
MAIL_ITEMS={}; M.trackedAttachments={}; M.open=true; CURSOR=false; COMBAT=false
NS.db.rules[2589]={[197]=true}
MailFrame:Show(); SendMailFrame:Show(); NS.MainFrame:Show()
G.category:SetValue(197); G.itemCategory:SetValue('all'); G.search:SetText('')
assert(#G.rows==33 and G.rows[1].item.slot==1 and G.rows[2].item.slot==2)
local oldDesaturated=G.rows[1].icon.SetDesaturated
G.rows[1].icon.SetDesaturated=function(self,value) self.testDesaturated=value end
G.rows[1].scripts.OnClick(G.rows[1],'RightButton')
assert(MAIL_ITEMS[1].count==20 and G.rows[1].item.mailSlot==1 and G.rows[1].attachedMark:IsShown())
assert(G.rows[1].icon.testDesaturated==true, '已添加物品保留勾号并置灰')
assert(not G.rows[2].item.mailSlot and G.rows[2].item.slot==2, '同物品第二堆仍为独立未添加状态')
BAGS[0][1]={itemID=2589,stackCount=20,hyperlink='item:2589',isLocked=true}
G.Refresh()
assert(G.rows[1].item.mailSlot==1 and not G.rows[2].item.mailSlot
    and G.rows[2].item.slot==2, '第一堆仍占用背包时，第二格必须仍指向第二堆')
G.rows[2].scripts.OnClick(G.rows[2],'RightButton')
assert(MAIL_ITEMS[1].count==20 and MAIL_ITEMS[2].count==10, '右击另一堆必须新增，不能撤回第一堆')
assert(G.rows[1].item.mailSlot==1 and G.rows[2].item.mailSlot==2)
-- 真实客户端可保留已附加物品的背包槽位；模拟中原先直接删除，漏掉了重复格问题。
BAGS[0][1]={itemID=2589,stackCount=20,hyperlink='item:2589',isLocked=true}
BAGS[0][2]={itemID=2589,stackCount=10,hyperlink='item:2589',isLocked=true}
G.Refresh()
assert(G.rows[1].item.mailSlot==1 and G.rows[2].item.mailSlot==2
    and not G.rows[3]:IsShown(), '锁定背包原位不能额外生成格子挤走另一组')
BAGS[0][1]=nil; BAGS[0][2]=nil
assert(not NS.QuantityDialog.Open(G.rows[1].item), '已添加堆叠不能双击')
local first=G.rows[1].item
G.rows[1].scripts.OnClick(G.rows[1],'RightButton')
assert(not MAIL_ITEMS[1] and MAIL_ITEMS[2].count==10 and BAGS[0][1].stackCount==20)
assert(not G.rows[1].item.mailSlot and G.rows[2].item.mailSlot==2)
assert(G.rows[1].icon.testDesaturated==false and not G.rows[1].attachedMark:IsShown(),
    '撤回未锁定物品后恢复颜色并取消勾号')
assert(not M.ToggleItem(first), '旧附件对象不得撤回其他同名堆')
-- 原生附件发生压缩时剩余已添加堆叠仍绑定实际附件，不绑定回背包新堆。
G.rows[1].scripts.OnClick(G.rows[1],'RightButton')
local oldClick=ClickSendMailItemButton
ClickSendMailItemButton=function(slot,remove)
    oldClick(slot,remove)
    if remove then
        local compact={}
        for index=1,12 do if MAIL_ITEMS[index] then compact[#compact+1]=MAIL_ITEMS[index] end end
        MAIL_ITEMS=compact
    end
end
G.rows[1].scripts.OnClick(G.rows[1],'RightButton')
ClickSendMailItemButton=oldClick
assert(MAIL_ITEMS[1].count==10 and G.rows[2].item.mailSlot==1)
-- 排序以物品ID分组，组内按链接及原背包位置保持稳定。
local oldScan=NS.InventoryScanner.Scan
NS.InventoryScanner.Scan=function() return {
    {itemID=2770,bag=0,slot=1,count=1,name='矿'},
    {itemID=2589,bag=0,slot=3,count=1,name='布'},
    {itemID=2589,bag=0,slot=2,count=1,name='布'},
} end
MAIL_ITEMS={}; M.trackedAttachments={}
G.category:SetValue(-1); G.Refresh()
assert(G.rows[1].item.itemID==2589 and G.rows[1].item.slot==2
    and G.rows[2].item.slot==3 and G.rows[3].item.itemID==2770)
NS.InventoryScanner.Scan=oldScan
assert(NS.ItemClassifier.Classify({classID=7,subclassID=3})=='devices')
assert(NS.ItemClassifier.Classify({classID=7,subclassID=2})=='explosives')
local lure={itemID=6533,classID=7,subclassID=3}
assert(not NS.MaterialMatcher.Match(lure,nil,202) and NS.MaterialMatcher.Match(lure,nil,356),
    '诱鱼器属于钓鱼用品，工程制造的产物不自动作为工程材料')
local oldLure=NS.db.rules[6533]
NS.MaterialMatcher.SetRule(6533,{[356]=true})
assert(not NS.MaterialMatcher.Match(lure,nil,202), '诱鱼器新增归属仍尊重用户覆盖')
NS.db.rules[6533]=oldLure
NS.events.scripts.OnEvent(NS.events,'MAIL_SEND_SUCCESS')
assert(next(M.trackedAttachments)==nil)
BAGS,MAIL_ITEMS,M.trackedAttachments=oldBags,oldMail,oldTracked
NS.db.rules[2589]=oldRule
M.open=false; NS.MainFrame:Hide()
G.rows[1].icon.SetDesaturated=oldDesaturated
print('PASS: 同物品多堆独立右击/准确撤回/已添加标记/附件压缩重绑定/物品稳定排序/诱鱼器仅钓鱼用途')
