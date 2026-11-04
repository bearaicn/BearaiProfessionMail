local R, M = NS.ItemRulesPanel, NS.MaterialMatcher
NS.UI.Create()
local oldAssistant = NS.MaterialRules[2589]
local oldUser = NS.db.rules[2589]
NS.db.rules[2589] = nil
R.Open(2589)
assert(R.frame:GetParent() == UIParent and R.frame:IsShown())
assert(R.editor.source:GetText() == '来源：助手数据')
assert(not R.editor.restore.enabled)
local function entry(id)
    local found, count
    count = 0
    for _, row in ipairs(M.List()) do
        if row.itemID == id then found = row; count = count + 1 end
    end
    assert(count <= 1, '双数据物品必须合并成一行')
    return found
end
for _, check in pairs(R.editor.checks) do check:SetChecked(false) end
R.editor.checks[356]:SetChecked(true)
R.editor.save.scripts.OnClick()
assert(R.frame:IsShown(), '保存后留在独立管理面板')
assert(NS.db.rules[2589][356] and not NS.db.rules[2589][197])
assert(NS.MaterialRules[2589] == oldAssistant and oldAssistant[197], '维护助手物品不能改写助手数据')
assert(M.Rule(2589) == NS.db.rules[2589] and not M.Rule(2589)[197])
assert(entry(2589).source == 'user' and entry(2589).hasAssistant)
assert(R.editor.source:GetText() == '来源：用户数据（覆盖助手）' and R.editor.restore.enabled)
R.filter:SetValue('user')
R.search:SetText('2589')
assert(#R.Filtered() == 1 and R.rows[1].source:GetText() == '用户数据（覆盖助手）')
R.filter:SetValue('assistant')
assert(#R.Filtered() == 0, '助手来源筛选按当前生效数据判断')
R.filter:SetValue('all')
R.editor.restore.scripts.OnClick()
assert(NS.db.rules[2589] == nil and M.Rule(2589) == oldAssistant)
assert(entry(2589).source == 'assistant' and R.editor.source:GetText() == '来源：助手数据')
-- 空规则仍属于用户数据，且必须覆盖助手归属。
for _, check in pairs(R.editor.checks) do check:SetChecked(false) end
R.editor.save.scripts.OnClick()
assert(next(M.Rule(2589)) == nil and entry(2589).source == 'user')
assert(R.rows[1].professions:GetText() == '排除专业匹配')
R.editor.restore.scripts.OnClick()
-- 新增只写用户数据；删除用户独有规则时从合并列表消失。
local newID = 999876
assert(NS.MaterialRules[newID] == nil and NS.db.rules[newID] == nil)
R.newButton.scripts.OnClick()
assert(R.editor.first:GetText() == '' and R.editor.source:GetText() == '来源：尚未保存')
R.editor.first:SetText(tostring(newID)); R.editor.checks[356]:SetChecked(true)
R.editor.save.scripts.OnClick()
assert(NS.db.rules[newID][356] and NS.MaterialRules[newID] == nil)
assert(entry(newID).source == 'user' and not entry(newID).hasAssistant)
assert(R.editor.source:GetText() == '来源：用户数据')
local savedDB = NS.db
NS.Database.Initialize()
assert(NS.db == savedDB and NS.db.rules[newID][356], '重新初始化不能丢失已保存规则')
R.editor.restore.scripts.OnClick()
assert(entry(newID) == nil and NS.db.rules[newID] == nil)
-- 入口独立于邮箱；两个按钮打开同一个 UIParent 窗口。
R.search:SetText(''); R.frame:Hide()
NS.SettingsPanel.rulesButton.scripts.OnClick()
assert(R.frame:IsShown() and R.frame:GetParent() == UIParent)
NS.SettingsPanel.panel:Hide()
if NS.MainFrame then NS.MainFrame:Hide() end
assert(R.frame:IsShown(), '关闭助手或设置页不关闭独立规则面板')
local frame = R.frame
R.frame:Hide()
NS.MaterialGrid.rulesButton.scripts.OnClick()
assert(R.frame == frame and R.frame:IsShown())
R.search:SetText(' 亚麻 ')
assert(#R.Filtered() == 1 and R.Filtered()[1].itemID == 2589)
-- 模拟名称到达，不应重置尚未保存的编辑。
R.Edit(2589); R.editor.checks[356]:SetChecked(true)
R.frame.scripts.OnEvent(R.frame,'GET_ITEM_INFO_RECEIVED',2589,true)
assert(R.editor.checks[356]:GetChecked())
R.Scroll(99999)
assert(R.offset >= 0 and R.offset <= math.max(0,#R.Filtered()-#R.rows))
R.search:SetText(''); R.filter:SetValue('all'); R.offset=0
R.frame:Hide()
NS.db.rules[2589] = oldUser
assert(NS.MaterialRules[2589] == oldAssistant)
print('PASS: 独立物品规则面板/双入口/合并来源/用户优先/空规则/新增删除/保存与恢复/角色编辑隔离')
