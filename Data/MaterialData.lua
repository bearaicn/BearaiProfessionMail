local _, ns = ...
local D = { schema = 1 }
ns.MaterialData = D
ns.MaterialRules = {}
-- 客户端索引 -> 维护者补充 -> SavedVariables 用户覆盖（由 Matcher 处理）。
function D.Add(items, professions)
    for _, itemID in ipairs(items) do
        local rule = ns.MaterialRules[itemID] or {}
        ns.MaterialRules[itemID] = rule
        for _, professionID in ipairs(professions) do
            if ns.ProfessionByID[professionID] then rule[professionID] = true end
        end
    end
end
function D.Load(flavor, build, rules)
    if flavor ~= ns.Compatibility.Flavor() then return end
    D.flavor, D.build = flavor, build
    for itemID, professions in pairs(rules) do D.Add({itemID}, professions) end
end
