local function event(name, arg) NS.events.scripts.OnEvent(NS.events, name, arg) end
assert(NS.Compatibility.Flavor() == 'titan')
assert(NS.ProfessionByID[755] and NS.ProfessionByID[773] and #NS.Professions == 14)
function GetNumSkillLines() return 3 end
function GetSkillLineInfo(index)
    if index == 1 then return '专业', true, true end
    return index == 2 and '珠宝加工' or '铭文', false, false, 450, 0, 0, 450
end
event('ADDON_LOADED', 'BearaiProfessionMail')
event('PLAYER_LOGIN')
assert(NS.db == BearaiProfessionMailDB.profiles.titan)
local character = NS.db.characters[NS.currentKey]
assert(character.professions[755] and character.professions[773])
assert(NS.MaterialMatcher.Match({itemID=36912}, character.professions), '萨隆邪铁可匹配珠宝选矿')
assert(NS.MaterialMatcher.Match({itemID=39151}, character.professions), '色素匹配铭文')
assert(NS.MaterialMatcher.Match({itemID=33470}, {[129]=true}), '霜纹布匹配急救')
assert(NS.MaterialMatcher.Match({itemID=34054}, {[333]=true}), '无限之尘匹配附魔')
assert(not NS.MaterialMatcher.Match({itemID=36908}, {[773]=true}), '冰莲花不应作为研磨材料')
BAGS[0][1] = {itemID=36912,stackCount=20,iconFileID=1,hyperlink='item:36912'}
BAGS[0][2] = {itemID=39151,stackCount=3,iconFileID=2,hyperlink='item:39151'}
event('MAIL_SHOW')
NS.MailButton.Toggle()
NS.CharacterList.Select(NS.currentKey)
assert(NS.MaterialGrid.rows[1].item.itemID == 36912)
assert(#NS.MaterialGrid.category.options == 17)
NS.UI.OpenEditor('character')
assert(NS.Editor:GetHeight() == 500 and NS.Editor.checks[755] and NS.Editor.checks[773])
assert(NS.Editor.status.point[3] == -408, '14 专业编辑器说明不得覆盖第五行')
NS.Editor:Hide()
NS.MaterialGrid.rows[1].scripts.OnDoubleClick(NS.MaterialGrid.rows[1], 'LeftButton')
NS.QuantityDialog.confirm.scripts.OnClick()
assert(MAIL_ITEMS[1].itemID == 36912)
assert(NS.MaterialGrid.attachments == nil and #NS.MaterialGrid.rows == 33)
assert(NS.MailController.Remove(NS.Compatibility.Attachment(1)))
assert(MAIL_ITEMS[1] == nil)
-- 两种专业 API 都覆盖新增 skillLine ID。
GetNumSkillLines, GetSkillLineInfo = nil, nil
function GetProfessions() return 1, 2, nil, 4, 5, 6 end
function GetProfessionInfo(index)
    local ids = {[1]=755,[2]=773,[4]=356,[5]=185,[6]=129}
    return 'localized', 1, 450, 450, 0, 0, ids[index]
end
local professions = NS.ProfessionManager.Read()
assert(professions[755] and professions[773] and professions[356] and professions[185] and professions[129])
local titan = NS.db
NS.db.rules[36912] = {[755]=true}
TEST_INTERFACE = 11509
NS.Database.Initialize()
assert(NS.db ~= titan and next(NS.db.characters) == nil and NS.db.rules[36912] == nil)
TEST_INTERFACE = 38002
NS.Database.Initialize()
assert(NS.db == titan and NS.db.rules[36912][755])
event('MAIL_CLOSED')
assert(not NS.MainFrame:IsShown())
print('PASS: 时光服启动/数据隔离/珠宝铭文双接口/扩展材料/14专业布局/邮箱附件模拟')
