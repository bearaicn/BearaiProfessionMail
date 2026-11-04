local _, ns = ...
ns.InventoryScanner = {}
function ns.InventoryScanner.Scan()
    local rows = {}
    -- 仅随身背包；不扫描银行、钥匙链或账户仓库。
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        for slot = 1, ns.Compatibility.Slots(bag) do
            local info = ns.Compatibility.Item(bag, slot)
            if info and info.itemID then
                local classID, bindType, reagent, subclassID = ns.Compatibility.ItemDetails(info.itemID)
                local questAPI = C_Container and C_Container.GetContainerItemQuestInfo or GetContainerItemQuestInfo
                local questInfo = questAPI and questAPI(bag, slot)
                rows[#rows + 1] = { bag = bag, slot = slot, itemID = info.itemID,
                    link = info.hyperlink, name = ns.Compatibility.ItemName(info.itemID),
                    icon = info.iconFileID, count = info.stackCount or 1,
                    locked = info.isLocked, bound = info.isBound, quality = info.quality,
                    classID = classID, subclassID = subclassID, bindType = bindType, craftingReagent = reagent,
                    quest = type(questInfo) == "table" and questInfo.isQuestItem or false }
            end
        end
    end
    return rows
end
