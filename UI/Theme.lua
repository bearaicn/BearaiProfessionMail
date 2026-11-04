local _, ns = ...
ns.Theme = {
    background = { 0.045, 0.055, 0.07, 0.98 },
    surface = { 0.08, 0.095, 0.12, 1 },
    border = { 0.23, 0.28, 0.34, 1 },
    accent = { 0.85, 0.68, 0.35, 1 },
    hover = { 0.16, 0.20, 0.25, 1 },
    selected = { 0.22, 0.19, 0.12, 1 },
    text = { 0.92, 0.94, 0.96, 1 },
    muted = { 0.58, 0.65, 0.73, 1 },
}
ns.Classes = {
    { id = "WARRIOR", name = "战士" }, { id = "PALADIN", name = "圣骑士" },
    { id = "HUNTER", name = "猎人" }, { id = "ROGUE", name = "潜行者" },
    { id = "PRIEST", name = "牧师" }, { id = "SHAMAN", name = "萨满祭司" },
    { id = "MAGE", name = "法师" }, { id = "WARLOCK", name = "术士" },
    { id = "DRUID", name = "德鲁伊" }, { id = "DEATHKNIGHT", name = "死亡骑士" },
}
function ns.ClassName(id)
    for _, class in ipairs(ns.Classes) do if class.id == id then return class.name end end
    return "未知"
end
