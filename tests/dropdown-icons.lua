local dropdown = NS.MaterialGrid.category
dropdown:SetValue(-2,true)
dropdown:ToggleMenu()
assert(dropdown.arrow.texture == 'Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up')
local selected
for _,row in ipairs(dropdown.menuRows) do
    if row.selected then selected=row end
    assert(not row.label:GetText():find('✓',1,true), '选项文本不依赖字体勾号')
end
assert(selected and selected.label:GetText()=='全部材料' and selected.check:IsShown())
assert(selected.check.texture=='Interface\\Buttons\\UI-CheckBox-Check')
selected.scripts.OnLeave(selected)
assert(selected.background[1]==NS.Theme.selected[1], '选中背景在离开鼠标后保留')
assert(dropdown.menu.up.icon.texture:find('ScrollUp',1,true))
assert(dropdown.menu.down.icon.texture:find('ScrollDown',1,true))
assert(dropdown.menu.up.label:GetText()=='' and dropdown.menu.down.label:GetText()=='')
dropdown.menu.down.scripts.OnClick()
assert(dropdown.offset==1)
dropdown:SetValue(171,true); dropdown:RefreshMenu()
for _,row in ipairs(dropdown.menuRows) do
    assert(row.check:IsShown()==row.selected)
    if row.selected then assert(row.label:GetText()=='炼金术') end
end
NS.UI.CloseDropdown()
dropdown:SetValue(0,true)
print('PASS: 下拉选中勾号/展开箭头/翻页箭头使用纹理，文字无特殊符号且选中状态同步')
