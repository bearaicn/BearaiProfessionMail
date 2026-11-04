local _, ns = ...
ns.InventoryScanner = {}
function ns.InventoryScanner.Scan()
    local rows = {}
    -- 仅随身背包；不扫描银行、钥匙链或账户仓库。
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        for slot = 1, ns.Compatibility.Slots(bag) do
            local info = ns.Compatibility.Item(bag, slot)
            if info and info.itemID then
                rows[#rows + 1] = { bag = bag, slot = slot, itemID = info.itemID,
                    link = info.hyperlink, name = ns.Compatibility.ItemName(info.itemID),
                    icon = info.iconFileID, count = info.stackCount or 1,
                    locked = info.isLocked, bound = info.isBound }
            end
        end
    end
    return rows
end
