local I,M,G,R=NS.ItemClassifier,NS.MaterialMatcher,NS.MaterialGrid,NS.ItemRulesPanel
local oldInstant,oldInfo=C_Item.GetItemInfoInstant,C_Item.GetItemInfo
local oldScan=NS.InventoryScanner.Scan
local herbID,metalID,gearID=999861,999862,999863
local rows={
    {itemID=herbID,classID=7,subclassID=9,name='新草药',bag=0,slot=1,count=5},
    {itemID=metalID,classID=7,subclassID=7,name='新矿石',bag=0,slot=2,count=6},
    {itemID=gearID,classID=4,subclassID=1,name='未绑定装备',bag=0,slot=3,count=1},
}
assert(I.Classify(rows[1])=='herb' and I.Classify(rows[2])=='metal')
assert(I.Classify(rows[3])=='equipment')
assert(I.Classify({classID=7,subclassID=999})=='tradegoods', '未知材料子类只兜底大类')
assert(I.Classify({})=='pending' and I.Classify({classID=99})=='other')
local _,_,state=I.Describe(rows[1]); assert(state=='专业用途未收录')
assert(M.Source(herbID)=='new' and next(M.Rule(herbID))==nil)
assert(not M.Match(rows[1],{[171]=true},0), '游戏分类不能推断炼金用途')
assert(M.Match(rows[1],nil,-1) and I.Match(rows[1],'herb'))
M.SetRule(herbID,{})
assert(not M.Match(rows[1],{[171]=true},0), '类别兜底不得复活用户专业排除')
_,_,state=I.Describe(rows[1]); assert(state=='用户已排除专业匹配')
M.SetRule(herbID,nil)
-- API即时信息补齐类和子类，包含子类0的情况。
C_Item.GetItemInfo=function() return nil end
C_Item.GetItemInfoInstant=function(id) return id,'type','subtype','',1,7,9 end
local class,_,_,sub=NS.Compatibility.ItemDetails(herbID)
assert(class==7 and sub==9)
C_Item.GetItemInfoInstant=function(id) return id,'type','subtype','',1,7,0 end
class,_,_,sub=NS.Compatibility.ItemDetails(herbID); assert(class==7 and sub==0)
C_Item.GetItemInfo, C_Item.GetItemInfoInstant=oldInfo,oldInstant
local modern,legacyInfo,legacyInstant=C_Item,GetItemInfo,GetItemInfoInstant
C_Item=nil
GetItemInfo=function() return nil end
GetItemInfoInstant=function(id) return id,'type','subtype','',1,7,5 end
class,_,_,sub=NS.Compatibility.ItemDetails(herbID); assert(class==7 and sub==5)
C_Item,GetItemInfo,GetItemInfoInstant=modern,legacyInfo,legacyInstant
NS.InventoryScanner.Scan=function() return rows end
NS.MailController.open=true; MailFrame:Show(); SendMailFrame:Show(); NS.MainFrame:Show()
G.category:SetValue(-1); G.itemCategory:SetValue('herb'); G.search:SetText('新')
assert(G.rows[1].item.itemID==herbID and not G.rows[2]:IsShown())
G.itemCategory:SetValue('metal'); assert(G.rows[1].item.itemID==metalID)
G.category:SetValue(171); assert(G.empty:IsShown(), '专业与类别是交集')
G.itemCategory:SetValue('herb')
R.Open(); R.filter:SetValue('unmapped'); R.search:SetText('99986')
assert(#R.Filtered()==3)
M.SetRule(metalID,{})
assert(#R.Filtered()==2, '已明确排除的物品不算专业用途未收录')
R.Edit(herbID); R.editor.checks[171]:SetChecked(true); R.editor.save.scripts.OnClick()
assert(M.Source(herbID)=='user' and #R.Filtered()==1 and M.Rule(herbID)[171])
assert(G.rows[1].item.itemID==herbID, '保存用户归属后进入当前专业和草药类别交集')
-- 批量添加也须遵循第二层类别，而非只按专业。
M.SetRule(metalID,{[171]=true})
local originalAdd,seen=NS.MailController.Add,{}
NS.MailController.Add=function(row) seen[#seen+1]=row.itemID; return true end
local ok,count=NS.MailController.AddProfession(171,'新','herb')
NS.MailController.Add=originalAdd
assert(ok and count==1 and seen[1]==herbID)
local selected=NS.db.settings.selected
NS.CharacterList.Select('classification-test-target')
assert(G.itemCategory.value=='all' and G.filter==nil, '切换角色同时重置用途和类别')
NS.db.settings.selected=selected
M.SetRule(herbID,nil); M.SetRule(metalID,nil)
R.filter:SetValue('all'); R.search:SetText(''); R.frame:Hide()
G.itemCategory:SetValue('all',true); G.category:SetValue(0,true); G.search:SetText('')
NS.InventoryScanner.Scan=oldScan
NS.MailController.open=false; NS.MainFrame:Hide()
print('PASS: 游戏类别二次分类/未知大类兜底/不猜专业/不覆盖用户排除/双筛选搜索/未收录维护/一键类别约束')
