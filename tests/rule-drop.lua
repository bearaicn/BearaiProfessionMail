NS.UI.OpenEditor('rule', nil, UIParent)
local editor = NS.ItemRulesPanel.editor
assert(editor.itemDrop:IsShown() and editor.itemName:IsShown())
local oldCursor, oldClear = GetCursorInfo, ClearCursor
local cleared = 0
local bagItem, stack = BAGS[0][1], BAGS[0][1].stackCount
local attached = MAIL_ITEMS[1]
function GetCursorInfo() return 'item', 2589, 'item:2589' end
function ClearCursor() cleared = cleared + 1 end
editor.itemDrop.scripts.OnReceiveDrag()
assert(editor.first:GetText() == '2589' and editor.itemDrop.itemID == 2589)
assert(editor.itemName:GetText() == '亚麻布')
assert(editor.checks[197]:GetChecked() and editor.checks[129]:GetChecked())
assert(cleared == 1 and BAGS[0][1] == bagItem and bagItem.stackCount == stack and MAIL_ITEMS[1] == attached)
-- 保存与原有 ID 编辑使用同一条规则路径。
editor.checks[171]:SetChecked(true)
editor.save.scripts.OnClick()
assert(NS.db.rules[2589][171])
NS.MaterialMatcher.SetRule(2589, nil)
NS.UI.OpenEditor('rule', nil, UIParent)
function GetCursorInfo() return 'item', nil, '|Hitem:6530:0|h[夜色虫]|h' end
editor.itemDrop.scripts.OnClick()
assert(editor.first:GetText() == '6530' and editor.checks[356]:GetChecked() and cleared == 2)
editor.checks[171]:SetChecked(true)
NS.ItemRulesPanel.frame.scripts.OnEvent(NS.ItemRulesPanel.frame, 'GET_ITEM_INFO_RECEIVED', 6530, true)
assert(editor.checks[171]:GetChecked(), '异步物品名称刷新不得清空正在编辑的专业选择')
function GetCursorInfo() return 'spell', 2589 end
editor.itemDrop.scripts.OnReceiveDrag()
assert(editor.first:GetText() == '6530' and cleared == 2, '非物品光标不得被清除或写入')
function GetCursorInfo() return 'item', -1 end
editor.itemDrop.scripts.OnReceiveDrag()
assert(editor.first:GetText() == '6530' and cleared == 2)
editor.first:SetText('3371')
assert(editor.itemDrop.itemID == 3371 and editor.checks[171]:GetChecked())
ClearCursor = nil
function GetCursorInfo() return 'item', 2589 end
editor.itemDrop.scripts.OnReceiveDrag()
assert(editor.first:GetText() == '3371', '缺少归还接口时不接受拖入')
ClearCursor = function() cleared = cleared + 1 end
NS.ItemRulesPanel.frame:Hide()
editor.itemDrop.scripts.OnReceiveDrag()
assert(cleared == 2)
NS.UI.OpenEditor('character')
assert(NS.Editor ~= editor and not NS.Editor.itemDrop, '角色编辑器不得混入物品维护控件')
editor.itemDrop.scripts.OnReceiveDrag()
assert(cleared == 2 and NS.Editor.first:GetText() == '')
NS.Editor:Hide()
GetCursorInfo, ClearCursor = oldCursor, oldClear
print('PASS: 材料规则拖入/点击取ID/原物品保留/保存/异步预览/错误光标及角色窗口隔离')
