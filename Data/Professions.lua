local _, ns = ...
-- 专业目录独立于材料索引；稳定 skillLine ID 与显示名称分开。
ns.Professions = {
    { id = 171, name = "炼金术", en = "Alchemy" },
    { id = 164, name = "锻造", en = "Blacksmithing" },
    { id = 333, name = "附魔", en = "Enchanting" },
    { id = 202, name = "工程学", en = "Engineering" },
    { id = 182, name = "草药学", en = "Herbalism" },
    { id = 165, name = "制皮", en = "Leatherworking" },
    { id = 186, name = "采矿", en = "Mining" },
    { id = 393, name = "剥皮", en = "Skinning" },
    { id = 197, name = "裁缝", en = "Tailoring" },
    { id = 185, name = "烹饪", en = "Cooking" },
    { id = 356, name = "钓鱼", en = "Fishing" },
    { id = 129, name = "急救", en = "First Aid" },
}
if ns.Compatibility.Flavor() == "titan" then
    ns.Professions[#ns.Professions + 1] = { id = 755, name = "珠宝加工", en = "Jewelcrafting" }
    ns.Professions[#ns.Professions + 1] = { id = 773, name = "铭文", en = "Inscription" }
end
ns.ProfessionByID, ns.ProfessionByName = {}, {}
for _, p in ipairs(ns.Professions) do
    ns.ProfessionByID[p.id] = p
    ns.ProfessionByName[p.name], ns.ProfessionByName[p.en] = p.id, p.id
end
