local _, ns = ...
local M = {}
ns.MaterialMatcher = M
function M.Rule(id) return ns.db.rules[id] or ns.MaterialRules[id] or {} end
function M.Source(id)
    if ns.db.rules[id] ~= nil then return "user", ns.MaterialRules[id] ~= nil end
    if ns.MaterialRules[id] ~= nil then return "assistant", true end
    return "new", false
end
function M.List()
    local ids, result = {}, {}
    for id in pairs(ns.MaterialRules) do ids[id] = true end
    for id in pairs(ns.db.rules) do ids[id] = true end
    for id in pairs(ids) do
        local source, hasAssistant = M.Source(id)
        result[#result + 1] = { itemID=id, professions=M.Rule(id), source=source, hasAssistant=hasAssistant }
    end
    table.sort(result, function(a, b) return a.itemID < b.itemID end)
    return result
end
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
    if not ns.Compatibility.IsMailable(row) then return false end
    local matched = filter == -1 or (filter == -2 and ns.Compatibility.IsMaterial(row))
    if filter and filter > 0 then
        matched = M.Rule(row.itemID)[filter] == true
    elseif not filter or filter == 0 then
        for id in pairs(M.Rule(row.itemID)) do
            if professions and professions[id] then matched = true; break end
        end
    end
    if not matched then return false end
    search = string.lower((search or ""):match("^%s*(.-)%s*$"))
    return search == "" or tostring(row.itemID):find(search, 1, true) ~= nil
        or string.lower(row.name or row.link or ""):find(search, 1, true) ~= nil
end
