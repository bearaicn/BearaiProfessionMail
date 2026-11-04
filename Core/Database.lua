local _, ns = ...
ns.Database = {}
function ns.Database.Initialize()
    if BearaiProfessionMailDB ~= nil and type(BearaiProfessionMailDB) ~= "table" then
        error("BearaiProfessionMailDB 格式异常，请备份 SavedVariables 后检查。")
    end
    local db = BearaiProfessionMailDB or { schema = 1, profiles = {} }
    if db.schema ~= 1 then error("不支持的数据版本；为避免覆盖，请使用匹配版本的插件。") end
    db.profiles = db.profiles or {}
    local flavor = ns.Compatibility.Flavor()
    db.profiles[flavor] = db.profiles[flavor] or { characters = {}, rules = {}, settings = {} }
    BearaiProfessionMailDB = db
    ns.db = db.profiles[flavor]
end
