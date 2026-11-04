local flavor = NS.Compatibility.Flavor()
local builds = { era = '1.15.9.70576', titan = '3.80.2.70522', forever = '1.60.1.70755' }
assert(NS.MaterialData.flavor == flavor and NS.MaterialData.build == builds[flavor])
local count = 0
for itemID, professions in pairs(NS.MaterialRules) do
    assert(type(itemID) == 'number' and itemID > 0)
    for professionID in pairs(professions) do assert(NS.ProfessionByID[professionID]) end
    count = count + 1
end
assert(count >= (flavor == 'titan' and 763 or (flavor == 'forever' and 589 or 501)))
-- 空瓶不在旧种子表中；验证生成索引实际参与专业匹配。
local vial = { itemID = 3371, name = '空瓶 Empty Vial', classID = 7 }
local M = NS.MaterialMatcher
assert(M.Match(vial, {[171]=true}, 0, '空'))
assert(M.Match(vial, {[171]=true}, 0, '371'))
assert(M.Match(vial, {[171]=true}, 0, '  EMPTY  '))
assert(not M.Match(vial, {[197]=true}, 0, '空'), '搜索不能绕过角色专业')
assert(not M.Match(vial, {[171]=true}, 197, '3371'), '搜索不能绕过独立专业')
assert(M.Match(vial, nil, 171, 'vial'), '独立专业不依赖目标角色')
assert(M.Match(vial, nil, -1, '空瓶'))
assert(M.Match(vial, nil, -2, '337'))
assert(not M.Match(vial, nil, -1, '.*'), '搜索按字面量，不执行 Lua 模式')
assert(not M.Match(vial, nil, -1, '不存在'))
vial.bound = true
assert(not M.Match(vial, nil, -1, '3371'), '搜索不能绕过邮寄限制')
vial.bound = nil
local original = NS.db.rules[3371]
assert(M.SetRule(3371, {}))
assert(not M.Match(vial, {[171]=true}, 0, '空'))
assert(M.Match(vial, nil, -1, '空'), '专业排除规则不等于禁止在全部物品里显示')
assert(M.SetRule(3371, nil))
assert(M.Match(vial, {[171]=true}, 0, '空'))
NS.db.rules[3371] = original
if flavor == 'forever' then
    assert(M.Rule(3371)[129] and M.Rule(3371)[356], '无限服独有材料关系应来自独立源')
else
    assert(not M.Rule(3371)[129] and not M.Rule(3371)[356], '无限服关系不得泄漏到其他客户端')
end
print('PASS: ' .. flavor .. ' 对应构建索引/多专业关系/用户覆盖/筛选内名称及ID模糊搜索')
