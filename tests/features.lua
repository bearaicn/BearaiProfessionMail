local function event(name, arg) NS.events.scripts.OnEvent(NS.events, name, arg) end
-- 设置页无需邮箱，可独立增改角色；选中角色不应改写原生收件人。
assert(SETTINGS_REGISTERED == NS.SettingsPanel.panel)
SlashCmdList.BEARAIPROFESSIONMAIL('settings')
assert(SETTINGS_OPENED == 123)
NS.SettingsPanel.panel:Show()
assert(NS.CharacterManager.SaveManual(nil, '设置页角色', '测试服', { [171] = true }))
local key = NS.db.settings.selected
NS.Refresh()
SendMailNameEditBox:SetText('保留收件人')
NS.SettingsPanel.characters.Select(key)
assert(SendMailNameEditBox:GetText() == '保留收件人')
NS.UI.OpenEditor('character', key, NS.SettingsPanel.content)
assert(NS.Editor:GetParent() == NS.SettingsPanel.content and NS.Editor:IsShown())
NS.Editor.class:SetValue('WARRIOR', true)
NS.Editor.level:SetText('60')
NS.Editor.save.scripts.OnClick()
assert(NS.db.characters[key].class == 'WARRIOR' and NS.db.characters[key].level == 60)
NS.SettingsPanel.panel:Hide()
-- 旧设置接口回退。
local modern = Settings
Settings = nil
function InterfaceOptions_AddCategory(panel) LEGACY_PANEL = panel end
local panel = CreateFrame('Frame'); panel.name = 'legacy-test'
assert(NS.Compatibility.RegisterSettings(panel) == 'legacy-test' and LEGACY_PANEL == panel)
Settings = modern
-- 过滤：全部可邮寄物品、全部材料、目标专业、独立专业，均受搜索约束。
local cloth = { itemID = 2589, classID = 7, count = 20, name = '亚麻布' }
local gear = { itemID = 999001, classID = 2, count = 1, name = '未绑定装备' }
local reagent = { itemID = 999002, classID = 7, count = 1, name = '未建规则材料' }
assert(NS.MaterialMatcher.Match(gear, nil, -1))
assert(not NS.MaterialMatcher.Match(gear, nil, -2))
assert(NS.MaterialMatcher.Match(reagent, nil, -2))
assert(not NS.MaterialMatcher.Match(reagent, { [171] = true }, 0))
assert(NS.MaterialMatcher.Match(cloth, { [171] = true }, 197))
assert(not NS.MaterialMatcher.Match(cloth, { [171] = true }, 0))
assert(not NS.MaterialMatcher.Match(cloth, nil, -1, '不存在'))
gear.bound = true; assert(not NS.MaterialMatcher.Match(gear, nil, -1)); gear.bound = false
gear.quest = true; assert(not NS.MaterialMatcher.Match(gear, nil, -1)); gear.quest = false
-- 新角色登录接管同名同服手动记录，不影响其他手动角色。
NS.db.characters[NS.currentKey] = nil
assert(NS.CharacterManager.SaveManual(nil, UnitName('player'), GetRealmName(), { [171] = true }, 'WARRIOR', 1))
assert(NS.CharacterManager.RecordCurrent())
local own = NS.db.characters[NS.currentKey]
assert(own.source == 'auto' and own.class == 'MAGE' and own.professions[197] and not own.professions[171])
assert(NS.db.characters[key].source == 'manual')
-- 双击放入后，即使背包中没有该堆，仍可从独立附件区撤回。
event('MAIL_SHOW')
SendMailFrame:Show()
NS.MainFrame:Show()
NS.CharacterList.Select(NS.currentKey)
NS.MaterialGrid.category:SetValue(0)
local button = NS.MaterialGrid.rows[1]
assert(button.item.itemID == 2589)
local slot = button.item.slot
button.scripts.OnDoubleClick(button, 'RightButton')
assert(MAIL_ITEMS[1] == nil)
button.scripts.OnDoubleClick(button, 'LeftButton')
assert(NS.QuantityDialog.frame:IsShown() and MAIL_ITEMS[1]==nil)
NS.QuantityDialog.confirm.scripts.OnClick()
assert(MAIL_ITEMS[1] and MAIL_ITEMS[1].itemID == 2589 and MAIL_ITEMS[1].count == 20)
assert(BAGS[0][slot] == nil and not CURSOR)
assert(NS.MaterialGrid.attachments == nil, '助手不重复显示原生附件栏')
NS.MaterialGrid.category:SetValue(171)
assert(MAIL_ITEMS[1].itemID == 2589, '筛选不改变原生邮件附件')
-- 背包仍有同类物品时，材料格子右击仍可撤回同类附件。
local spare = BAGS[0][3]
BAGS[0][3] = {itemID=2589,stackCount=2,hyperlink='item:2589'}
NS.MaterialGrid.category:SetValue(0)
NS.MaterialGrid.rows[1].scripts.OnClick(NS.MaterialGrid.rows[1], 'RightButton')
assert(MAIL_ITEMS[1] == nil and BAGS[0][slot] and BAGS[0][slot].stackCount == 20)
BAGS[0][3] = spare
NS.MaterialGrid.category:SetValue(0)
-- 满附件、战斗、操作待完成、鼠标占用、过期附件安全拦截。
local row = NS.InventoryScanner.Scan()[1]
for index = 1, 12 do MAIL_ITEMS[index] = { name = '占用', itemID = 999, count = 1 } end
PICKED = nil
assert(not NS.MailController.Add(row) and PICKED == nil)
local sendInfo = GetSendMailItem
GetSendMailItem = function() return nil end
assert(not NS.MailController.Add(row) and PICKED == nil, '未缓存附件名称也不可误判空位')
GetSendMailItem = sendInfo
MAIL_ITEMS = {}
COMBAT = true; assert(not NS.MailController.Add(row)); COMBAT = false
CURSOR = true; assert(not NS.MailController.Add(row)); CURSOR = false
C_Mail = { IsCommandPending = function() return true end }
assert(not NS.MailController.Add(row)); C_Mail = nil
assert(NS.MailController.Add(row))
local snapshot = NS.Compatibility.Attachment(1)
MAIL_ITEMS[1].itemID = 999
assert(not NS.MailController.Remove(snapshot), '过期附件槽位不能撤错物品')
MAIL_ITEMS[1].itemID = snapshot.itemID
assert(NS.MailController.Remove(snapshot))
assert(NS.CharacterManager.Delete(key))
print('PASS: 0.3 设置页/多种筛选/手动记录接管/双击附件/右击撤回/附件身份与容量防护')
