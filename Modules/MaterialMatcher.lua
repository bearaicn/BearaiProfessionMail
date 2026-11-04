local _, ns = ...
local M = {}
ns.MaterialMatcher = M
function M.Rule(id) return ns.db.rules[id] or ns.MaterialRules[id] or {} end
function M.SetRule(id, professions)
    id = tonumber(id)
    if not id or id < 1 or id ~= math.floor(id) then return false, "物品 ID 必须是正整数。" end
    if professions == nil then ns.db.rules[id] = nil; return true end
    local clean = {}
    for key, enabled in pairs(professions) do
        if enabled and ns.ProfessionByID[key] then clean[key] = true end
    end
    ns.db.rules[id] = clean -- 空表表示明确排除该物品。
    return true
end
function M.Match(row, professions, filter, search)
    if row.bound then return false end
    local matched = false
    for id in pairs(M.Rule(row.itemID)) do
        if professions[id] and (not filter or filter == id) then matched = true; break end
    end
    if not matched then return false end
    search = string.lower(search or "")
    return search == "" or tostring(row.itemID):find(search, 1, true) ~= nil
        or string.lower(row.name or row.link or ""):find(search, 1, true) ~= nil
end
