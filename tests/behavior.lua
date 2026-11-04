local function event(name, arg) NS.events.scripts.OnEvent(NS.events, name, arg) end
assert(not NS.ProfessionByID[755] and not NS.MaterialRules[39151], '时光服规则不能污染旧世')
event('ADDON_LOADED', 'unrelated')
assert(NS.ready == nil)
event('ADDON_LOADED', 'BearaiProfessionMail')
event('PLAYER_LOGIN')
assert(NS.currentKey == '测试角色-测试服')
assert(NS.db.characters[NS.currentKey].class == 'MAGE')
assert(NS.db.characters[NS.currentKey].level == 42)
event('PLAYER_LEVEL_UP', 43)
assert(NS.db.characters[NS.currentKey].level == 43)
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
assert(NS.MaterialMatcher.Match(rows[1], { [197] = true }, 129), '独立专业筛选不依赖角色专业')
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
assert(#NS.MaterialGrid.rows == 33 and NS.MaterialGrid.attachments == nil)
assert(NS.MailButton.button.point[2] == MailFrame, '没有关闭按钮时入口回退邮箱右上方')
MailFrameTab3.right = 390
NS.MailButton.Position()
assert(NS.MailButton.button.point[1] == 'TOPRIGHT' and NS.MailButton.button.point[2] == MailFrame
    and NS.MailButton.button.point[3] == 'TOPRIGHT', '标签行变化不影响右上入口')
MailFrameTab3.right = 275
NS.MailButton.Position()
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
NS.Editor.class:SetValue('MAGE', true)
NS.Editor.level:SetText('55')
NS.Editor.save.scripts.OnClick()
assert(NS.db.characters[manualKey].class == 'MAGE' and NS.db.characters[manualKey].level == 55)
assert(NS.CharacterManager.SaveManual(manualKey, '新收件人', '其他服', { [197] = true }, '', ''))
assert(NS.db.characters[manualKey].class == nil and NS.db.characters[manualKey].level == nil, '未知职业和空等级应能清除旧值')
NS.Refresh()
assert(not NS.CharacterManager.SaveManual(manualKey, '新收件人', '其他服', {}, 'BAD', 55))
assert(not NS.CharacterManager.SaveManual(manualKey, '新收件人', '其他服', {}, 'MAGE', 'abc'))
assert(not NS.CharacterManager.SaveManual(manualKey, '新收件人', '其他服', {}, 'MAGE', -2))
NS.CharacterList.search:SetText('新收件人')
assert(#NS.CharacterList.Filtered() == 1)
assert(NS.CharacterList.rows[1].key == manualKey)
NS.CharacterList.rows[1].scripts.OnClick(NS.CharacterList.rows[1])
assert(NS.db.settings.selected == manualKey)
NS.CharacterList.search:SetText('不可能存在的角色')
assert(#NS.CharacterList.Filtered() == 0)
NS.CharacterList.search:SetText('')
local extraKeys = {}
for index = 1, 6 do
    assert(NS.CharacterManager.SaveManual(nil, '额外角色' .. index, '测试服', { [197] = true }))
    extraKeys[#extraKeys + 1] = NS.db.settings.selected
end
NS.Refresh()
NS.CharacterList.Scroll(3)
assert(NS.CharacterList.offset == 3)
for _, key in ipairs(extraKeys) do assert(NS.CharacterManager.Delete(key)) end
NS.CharacterList.Select(manualKey)
assert(NS.CharacterList.offset == 0, '删除后角色滚动范围必须重新限制')
NS.MaterialGrid.category:ToggleMenu()
assert(NS.UI.openDropdown == NS.MaterialGrid.category)
NS.MaterialGrid.category:Choose(2)
assert(NS.MaterialGrid.filter == -1 and NS.UI.openDropdown == nil)
NS.CharacterList.Select(NS.currentKey)
NS.MaterialGrid.category:SetValue(129)
assert(NS.MaterialGrid.filter == 129)
NS.CharacterList.Select(manualKey)
assert(NS.MaterialGrid.filter == nil and NS.MaterialGrid.category.value == 0, '切换角色必须重置为按角色专业过滤')
for _, mode in ipairs({ -1, -2, 171 }) do
    NS.MaterialGrid.category:SetValue(mode)
    NS.MaterialGrid.page = 2
    NS.CharacterList.Select(NS.currentKey)
    assert(NS.MaterialGrid.filter == nil and NS.MaterialGrid.page == 1)
    NS.CharacterList.Select(manualKey)
end
NS.MaterialGrid.category:SetValue(0)
NS.UI.OpenEditor('character', manualKey)
NS.Editor.class:ToggleMenu()
NS.Editor.class.offset = 3
NS.Editor.class:RefreshMenu()
assert(NS.Editor.class.offset == 3, '较多下拉选项支持滚动')
NS.UI.CloseDropdown()
assert(not NS.UI.menuShield:IsShown())
NS.UI.OpenEditor('rule')
NS.ItemRulesPanel.editor.first:SetText('2589')
assert(NS.ItemRulesPanel.editor.checks[197]:GetChecked())
assert(NS.MaterialGrid.rows[1].count:GetText() == '20', '格子数量角标应对应真实堆叠')
local originalScan = NS.InventoryScanner.Scan
NS.InventoryScanner.Scan = function()
    local result = {}
    for index = 1, 35 do result[index] = { bag = 0, slot = index, itemID = 2589, count = index, name = '亚麻布', icon = 1 } end
    return result
end
NS.MaterialGrid.Refresh()
assert(NS.MaterialGrid.next.enabled and not NS.MaterialGrid.previous.enabled)
NS.MaterialGrid.next.scripts.OnClick()
assert(NS.MaterialGrid.page == 2 and NS.MaterialGrid.rows[1].item.slot == 34)
assert(NS.MaterialGrid.rows[2].count:GetText() == '35' and not NS.MaterialGrid.rows[3]:IsShown())
NS.MaterialGrid.search:SetText('找不到')
assert(NS.MaterialGrid.page == 1 and NS.MaterialGrid.empty:IsShown())
NS.MaterialGrid.search:SetText('')
NS.InventoryScanner.Scan = originalScan
NS.MaterialGrid.Refresh()
NS.MaterialGrid.category:ToggleMenu()
event('BAG_UPDATE_DELAYED')
event('GET_ITEM_INFO_RECEIVED')
event('MAIL_SEND_INFO_UPDATE')
event('MAIL_CLOSED')
assert(not NS.MainFrame:IsShown() and not NS.MailButton.button:IsShown())
assert(not NS.Editor:IsShown())
assert(NS.UI.openDropdown == nil and not NS.UI.menuShield:IsShown(), '关闭邮箱必须关闭独立弹出层')
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
