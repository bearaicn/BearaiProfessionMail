local _, ns = ...
local C = {}
ns.Compatibility = C
function C.Flavor()
    local _, _, _, interface = GetBuildInfo()
    if interface >= 38000 and interface < 40000 then return "titan" end
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
function C.Split(bag, slot, quantity)
    local api = C_Container and C_Container.SplitContainerItem or SplitContainerItem
    if not api then return false, "客户端缺少拆分 API，请选择整堆数量或使用原生背包。" end
    api(bag, slot, quantity)
    return true
end
local function sendTab()
    return MailFrame and MailFrame.Tabs and MailFrame.Tabs[2] or MailFrameTab2
end
function C.CanShowSend()
    local tab = sendTab()
    return (tab and type(tab.Click) == "function") or type(MailFrameTab_OnClick) == "function"
end
function C.ShowSend()
    if SendMailFrame and SendMailFrame:IsShown() then return true end
    if InCombatLockdown() then return false, "战斗中不自动切换邮箱页面。" end
    local tab = sendTab()
    -- 第二个原生标签是发件箱；Click 保留其他邮箱插件的点击钩子。
    if tab and type(tab.Click) == "function" then tab:Click("LeftButton") end
    if SendMailFrame and SendMailFrame:IsShown() then return true end
    if MailFrameTab_OnClick then MailFrameTab_OnClick(tab, 2) end
    if SendMailFrame and SendMailFrame:IsShown() then return true end
    return false, "未能切换到原生发件箱，请手动点击第二个标签后重试。"
end
function C.SplitStackToBag(itemID, bag, slot, quantity)
    local pickup = C_Container and C_Container.PickupContainerItem or PickupContainerItem
    if not pickup then return false, "客户端缺少背包放置接口。" end
    local freeAPI = C_Container and C_Container.GetContainerNumFreeSlots or GetContainerNumFreeSlots
    local targetBag, targetSlot
    -- 只选普通背包，避免专用材料袋拒收导致光标回到原堆或交换其他物品。
    for candidate=0,(NUM_BAG_SLOTS or 4) do
        local family
        if freeAPI then local _, kind = freeAPI(candidate); family = kind end
        if candidate==0 or family==0 then
            for index=1,C.Slots(candidate) do
                if not C.Item(candidate,index) then targetBag,targetSlot=candidate,index; break end
            end
        end
        if targetBag then break end
    end
    if not targetBag then return false, "按数量添加需要一个普通背包空格，请腾出空格后重试；不会改为整堆添加。" end
    local ok, reason = C.Split(bag,slot,quantity)
    if not ok then return false,reason end
    if not CursorHasItem() then return false,"拆分未完成，请等待背包刷新后重试。" end
    if C.Item(targetBag,targetSlot) then return false,"目标空格已变化，拆分物品仍在鼠标上，请放回背包。" end
    pickup(targetBag,targetSlot)
    if CursorHasItem() then return false,"拆分物品未能放入背包，请先将鼠标上的物品放回。" end
    local item = C.Item(targetBag,targetSlot)
    if item and not item.isLocked and item.itemID and item.stackCount
        and (item.itemID~=itemID or item.stackCount~=quantity) then
        return false,"拆分后的背包数量尚未确认，暂不加入附件；请刷新后重新选择拆分堆叠。"
    end
    return true,targetBag,targetSlot,item
end
function C.CursorItemID()
    if not GetCursorInfo then return end
    local kind, id, link = GetCursorInfo()
    if kind ~= "item" then return end
    id = tonumber(id) or (type(link) == "string" and tonumber(link:match("item:(%d+)")))
    if id and id > 0 and id == math.floor(id) then return id end
end
function C.ItemPreview(id)
    local api = C_Item and C_Item.GetItemInfo or GetItemInfo
    local name, icon
    if api then
        local details = { api(id) }
        name, icon = details[1], details[10]
    end
    local instant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    if not icon and instant then icon = select(5, instant(id)) end
    return name, icon
end
function C.ItemDetails(id)
    local api = C_Item and C_Item.GetItemInfo or GetItemInfo
    local details = api and { api(id) } or {}
    local classID, subclassID = details[12], details[13]
    local instant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    if (classID==nil or subclassID==nil) and instant then
        local _, _, _, _, _, class, subclass = instant(id)
        classID,subclassID = classID or class, subclassID or subclass
    end
    return classID, details[14], details[17], subclassID
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
