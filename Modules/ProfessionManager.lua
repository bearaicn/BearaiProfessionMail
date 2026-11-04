local _, ns = ...
local P = {}
ns.ProfessionManager = P
function P.Read()
    local result, supported = {}, false
    if GetProfessions and GetProfessionInfo then
        supported = true
        -- pairs 保留可能稀疏的辅助专业返回值。
        for _, index in pairs({ GetProfessions() }) do
            local name, _, rank, maxRank, _, _, id = GetProfessionInfo(index)
            id = ns.ProfessionByID[id] and id or ns.ProfessionByName[name]
            if id then result[id] = { rank = rank, maxRank = maxRank } end
        end
    end
    if GetNumSkillLines and GetSkillLineInfo then
        supported = true
        -- 折叠的技能标题必须临时展开，否则子项不会被 API 枚举。
        local collapsed, i = {}, 1
        while i <= GetNumSkillLines() do
            local _, header, expanded = GetSkillLineInfo(i)
            if header and not expanded then
                if not ExpandSkillHeader or not CollapseSkillHeader then return nil, "技能标题折叠且客户端不支持展开，保留上次专业记录。" end
                collapsed[#collapsed + 1] = i
                ExpandSkillHeader(i)
            end
            i = i + 1
        end
        for index = 1, GetNumSkillLines() do
            local name, header, _, rank, _, _, maxRank = GetSkillLineInfo(index)
            local id = ns.ProfessionByName[name]
            if not header and id then result[id] = { rank = rank, maxRank = maxRank } end
        end
        for index = #collapsed, 1, -1 do CollapseSkillHeader(collapsed[index]) end
    end
    if not supported then return nil, "未发现支持的专业 API，保留上次记录。" end
    return result
end
function P.Text(professions)
    local names = {}
    for _, p in ipairs(ns.Professions) do
        if professions and professions[p.id] then names[#names + 1] = p.name end
    end
    return #names > 0 and table.concat(names, "、") or "未记录专业"
end
