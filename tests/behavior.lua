local function event(name, arg) NS.events.scripts.OnEvent(NS.events, name, arg) end
event('ADDON_LOADED', 'unrelated')
assert(NS.ready == nil)
event('ADDON_LOADED', 'BearaiProfessionMail')
event('PLAYER_LOGIN')
assert(NS.currentKey == '测试角色-测试服')
assert(NS.db.characters[NS.currentKey].class == 'MAGE')
assert(NS.db.characters[NS.currentKey].professions[197].rank == 75)
assert(NS.db.characters[NS.currentKey].professions[129].rank == 40)
assert(SKILLS_COLLAPSED, '必须恢复技能列表折叠状态')
local originalDB = NS.db
NS.Database.Initialize()
assert(NS.db == originalDB, '重新加载不可覆盖数据')
assert(not NS.CharacterManager.SaveManual(nil, '', '服', {}))
assert(not NS.CharacterManager.SaveManual(nil, '坏-名称', '服', {}))
assert(NS.CharacterManager.SaveManual(nil, '收件人', '测试服', { [197] = true, [129] = true }))
assert(not NS.CharacterManager.SaveManual(nil, '收件人', '测试服', {}))
assert(not NS.CharacterManager.SaveManual(NS.currentKey, '盗改', '测试服', {}))
assert(not NS.CharacterManager.Delete(NS.currentKey))
local manualKey = NS.db.settings.selected
assert(NS.CharacterManager.SaveManual(manualKey, '新收件人', '其他服', { [197] = true }))
assert(NS.db.characters[manualKey] == nil)
manualKey = NS.db.settings.selected
local rows = NS.InventoryScanner.Scan()
assert(#rows == 3 and rows[1].bag == 0 and rows[1].slot == 1)
assert(NS.MaterialMatcher.Match(rows[1], { [129] = true }))
assert(NS.MaterialMatcher.Match(rows[1], { [197] = true }, 197, '亚麻'))
assert(not NS.MaterialMatcher.Match(rows[1], { [197] = true }, 129))
assert(not NS.MaterialMatcher.Match(rows[3], { [197] = true }))
assert(not NS.MaterialMatcher.Match(rows[2], { [197] = true }))
assert(NS.MaterialMatcher.SetRule(2770, { [197] = true, [171] = true }))
assert(NS.MaterialMatcher.Match(rows[2], { [197] = true }))
assert(NS.MaterialMatcher.Match(rows[2], { [171] = true }))
assert(NS.MaterialMatcher.SetRule(2770, {}))
assert(not NS.MaterialMatcher.Match(rows[2], { [186] = true }))
assert(NS.MaterialMatcher.SetRule(2770, nil))
assert(NS.MaterialMatcher.Match(rows[2], { [186] = true }))
assert(not NS.MaterialMatcher.SetRule(-1, {}))
assert(not NS.MailController.Pickup(rows[1]))
event('MAIL_SHOW')
assert(NS.MailButton.button:IsShown())
NS.MailButton.Toggle()
assert(NS.MainFrame:IsShown())
NS.CharacterList.Select(manualKey)
assert(SendMailNameEditBox:GetText() == '新收件人-其他服')
SendMailNameEditBox:SetText('玩家手改')
NS.Refresh()
assert(SendMailNameEditBox:GetText() == '玩家手改', '刷新不得覆盖玩家收件人')
COMBAT = true
assert(not NS.MailController.Pickup(rows[1]))
COMBAT = false
SendMailFrame:Hide()
assert(not NS.MailController.Pickup(rows[1]))
SendMailFrame:Show()
CURSOR = true
assert(not NS.MailController.Pickup(rows[1]))
CURSOR = false
BAGS[0][1].isLocked = true
assert(not NS.MailController.Pickup(rows[1]))
BAGS[0][1].isLocked = false
BAGS[0][1].stackCount = 19
assert(not NS.MailController.Pickup(rows[1]), '阻止过期堆叠')
BAGS[0][1].stackCount = 20
assert(NS.MailController.Pickup(rows[1]))
assert(PICKED[1] == 0 and PICKED[2] == 1)
CURSOR = false
NS.MaterialGrid.Refresh()
local firstButton = NS.MaterialGrid.rows[1]
assert(firstButton.item and firstButton.item.itemID == 2589)
PICKED = nil
firstButton.scripts.OnDragStart(firstButton)
assert(PICKED and PICKED[1] == 0 and PICKED[2] == 1, '真实 UI 拖拽回调必须使用背包槽位')
CURSOR = false
NS.UI.OpenEditor('character', manualKey)
assert(NS.Editor:IsShown())
NS.UI.OpenEditor('rule')
NS.Editor.first:SetText('2589')
assert(NS.Editor.checks[197]:GetChecked())
event('BAG_UPDATE_DELAYED')
event('GET_ITEM_INFO_RECEIVED')
event('MAIL_SEND_INFO_UPDATE')
event('MAIL_CLOSED')
assert(not NS.MainFrame:IsShown() and not NS.MailButton.button:IsShown())
assert(not NS.Editor:IsShown())
assert(NS.CharacterManager.Delete(manualKey))
-- 新专业接口的稀疏返回值。
local skillCount, skillInfo = GetNumSkillLines, GetSkillLineInfo
GetNumSkillLines, GetSkillLineInfo = nil, nil
function GetProfessions() return nil, 2, nil, 4, 5, 6 end
function GetProfessionInfo(index)
    local ids = { [2] = 171, [4] = 356, [5] = 185, [6] = 129 }
    return 'localized', 1, 50, 75, 0, 0, ids[index]
end
local professions = NS.ProfessionManager.Read()
assert(professions[171] and professions[356] and professions[185] and professions[129])
GetProfessions, GetProfessionInfo = nil, nil
assert(NS.ProfessionManager.Read() == nil)
NS.CharacterManager.RecordCurrent()
assert(NS.db.characters[NS.currentKey].professions[197], '不支持 API 时保留记录')
GetNumSkillLines, GetSkillLineInfo = skillCount, skillInfo
-- 旧背包接口回退。
local container = C_Container
C_Container = nil
function GetContainerNumSlots() return 1 end
function GetContainerItemInfo() return 1, 7, false, 1, false, false, 'item:2589', false, false, 2589, false end
function PickupContainerItem(bag, slot) PICKED = {bag, slot} end
assert(NS.Compatibility.Item(0, 1).stackCount == 7)
assert(NS.Compatibility.Slots(0) == 1)
assert(NS.Compatibility.Pickup(0, 1))
C_Container = container
TEST_INTERFACE = 16001
NS.Database.Initialize()
assert(NS.db ~= originalDB and next(NS.db.characters) == nil, '两个客户端数据隔离')
TEST_INTERFACE = 11509
NS.Database.Initialize()
assert(NS.db == originalDB)
print('PASS: 数据持久化/角色增改删/专业双接口/背包双接口/匹配规则/拖拽防护/UI 事件模拟')
