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
function C.ItemDetails(id)
    local api = C_Item and C_Item.GetItemInfo or GetItemInfo
    local details = api and { api(id) } or {}
    local classID = details[12]
    local instant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    if not classID and instant then
        local _, _, _, _, _, class = instant(id)
        classID = class
    end
    return classID, details[14], details[17]
end
function C.IsMailable(row)
    -- 本地可确认的限制；收件人／跨服限制最终仍由原生邮箱判定。
    return not row.bound and not row.quest and row.classID ~= 12 and row.bindType ~= 1 and row.bindType ~= 4
end
function C.IsMaterial(row)
    return row.classID == 7 or row.classID == 5 or row.craftingReagent
        or next(ns.MaterialMatcher.Rule(row.itemID)) ~= nil
end
function C.AttachmentLimit() return ATTACHMENTS_MAX_SEND or 12 end
function C.HasAttachment(index)
    if HasSendMailItem then return HasSendMailItem(index) end
    return C.Attachment(index) ~= nil
end
function C.Attachment(index)
    if not GetSendMailItem then return nil end
    local name, id, icon, count, quality = GetSendMailItem(index)
    if not name then return nil end
    local link = GetSendMailItemLink and GetSendMailItemLink(index)
    id = id or tonumber((link or ""):match("item:(%d+)"))
    return { mailSlot = index, itemID = id, name = name, icon = icon, count = count or 1, quality = quality, link = link }
end
function C.ClickAttachment(index, remove)
    if not ClickSendMailItemButton then return false, "客户端缺少附件操作 API。" end
    ClickSendMailItemButton(index, remove == true)
    return true
end
function C.RegisterSettings(panel)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        return category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
        return panel.name
    end
    return nil
end
function C.Now() return time() end
function C.Diagnostics()
    local version, build, _, interface = GetBuildInfo()
    return "插件 " .. ns.version .. "；" .. string.format("%s / build %s / Interface %s / %s；背包 %s；专业 %s；邮箱 %s", version, build,
        tostring(interface), C.Flavor(), C_Container and "C_Container" or "legacy",
        GetNumSkillLines and "技能列表" or (GetProfessions and "GetProfessions" or "不支持"),
        MailFrame and "MailFrame" or "尚未加载")
end
