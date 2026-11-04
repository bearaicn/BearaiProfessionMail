local _, ns = ...
local M = {}
ns.CharacterManager = M
local function trim(value) return (value or ""):match("^%s*(.-)%s*$") end
function M.Key(name, realm) return name .. "-" .. realm end
function M.RecordCurrent()
    if M.recording then return true end
    M.recording = true
    local name, realm = UnitName("player"), GetRealmName()
    if not name or not realm or realm == "" then M.recording = false; return false end
    local _, class = UnitClass("player")
    local key = M.Key(name, realm)
    local old = ns.db.characters[key]
    local professions, err = ns.ProfessionManager.Read()
    ns.db.characters[key] = { name = name, realm = realm, class = class, level = UnitLevel("player"), source = "auto",
        professions = professions or (old and old.professions) or {}, updatedAt = ns.Compatibility.Now() }
    ns.currentKey, M.recording = key, false
    return not err, err
end
function M.SaveManual(oldKey, name, realm, professions, class, level)
    name, realm = trim(name), trim(realm)
    if name == "" or realm == "" or name:find("[%s%-%c|]") or realm:find("[%c|]") then
        return false, "请输入角色名称和服务器；角色名不可含空格、横线或控制字符。"
    end
    local key = M.Key(name, realm)
    local existing = ns.db.characters[key]
    local previous = oldKey and ns.db.characters[oldKey] or existing
    local keepClass, keepLevel = class == nil, level == nil
    if oldKey and (not ns.db.characters[oldKey] or ns.db.characters[oldKey].source ~= "manual") then
        return false, "只能修改手动添加的角色。"
    end
    if existing and (key ~= oldKey or existing.source ~= "manual") then return false, "该名称和服务器的角色已存在。" end
    if class == "" then class = nil end
    if class then
        local known = false
        for _, entry in ipairs(ns.Classes) do if entry.id == class then known = true end end
        if not known then return false, "请选择有效职业。" end
    end
    if level == "" then level = nil end
    if level ~= nil then
        level = tonumber(level)
        if not level or level < 1 or level > 1000 or level ~= math.floor(level) then
            return false, "等级必须是 1–1000 的整数，也可留空。"
        end
    end
    local clean = {}
    for id, enabled in pairs(professions or {}) do
        if enabled and ns.ProfessionByID[id] then clean[id] = true end
    end
    ns.db.characters[key] = { name = name, realm = realm, source = "manual", professions = clean,
        class = keepClass and previous and previous.class or class,
        level = keepLevel and previous and previous.level or level,
        updatedAt = ns.Compatibility.Now() }
    if oldKey and oldKey ~= key then ns.db.characters[oldKey] = nil end
    ns.db.settings.selected = key
    return true, key
end
function M.Delete(key)
    local character = ns.db.characters[key]
    if not character or character.source ~= "manual" then return false, "只能删除手动角色。" end
    ns.db.characters[key] = nil
    if ns.db.settings.selected == key then ns.db.settings.selected = nil end
    return true
end
function M.List()
    local rows = {}
    for key, character in pairs(ns.db.characters) do rows[#rows + 1] = { key = key, character = character } end
    table.sort(rows, function(a, b) return a.key < b.key end)
    return rows
end
function M.Selected() return ns.db.characters[ns.db.settings.selected] end
