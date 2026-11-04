local _, ns = ...
local C = {}
ns.Compatibility = C
function C.Flavor()
    local _, _, _, interface = GetBuildInfo()
    if interface >= 16000 and interface < 20000 then return "forever" end
    if interface >= 11000 and interface < 16000 then return "era" end
    return "project-" .. tostring(WOW_PROJECT_ID or interface)
end
function C.Item(bag, slot)
    local info
    if C_Container and C_Container.GetContainerItemInfo then
        info = C_Container.GetContainerItemInfo(bag, slot)
    elseif GetContainerItemInfo then
        local icon, count, locked, quality, readable, lootable, link, filtered, noValue, id, bound = GetContainerItemInfo(bag, slot)
        if icon then info = { iconFileID = icon, stackCount = count, isLocked = locked,
            quality = quality, hyperlink = link, itemID = id, isBound = bound } end
    end
    if info then
        info.itemID = info.itemID or tonumber((info.hyperlink or ""):match("item:(%d+)"))
    end
    return info
end
function C.Slots(bag)
    local api = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    return api and api(bag) or 0
end
function C.Pickup(bag, slot)
    local api = C_Container and C_Container.PickupContainerItem or PickupContainerItem
    if not api then return false, "客户端缺少背包拾取 API。" end
    api(bag, slot)
    return true
end
function C.ItemName(id)
    local api = C_Item and C_Item.GetItemInfo or GetItemInfo
    return api and api(id)
end
function C.Now() return time() end
function C.Diagnostics()
    local version, build, _, interface = GetBuildInfo()
    return string.format("%s / build %s / Interface %s / %s；背包 %s；专业 %s；邮箱 %s", version, build,
        tostring(interface), C.Flavor(), C_Container and "C_Container" or "legacy",
        GetNumSkillLines and "技能列表" or (GetProfessions and "GetProfessions" or "不支持"),
        MailFrame and "MailFrame" or "尚未加载")
end
