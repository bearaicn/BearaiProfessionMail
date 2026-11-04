local _, ns = ...
local S = {}
ns.SettingsPanel = S
function S.Refresh()
    if S.panel and S.panel:IsShown() then S.characters.Refresh() end
end
function S.Register()
    if S.panel then return end
    local panel = CreateFrame("Frame", "BearaiProfessionMailSettings", UIParent)
    S.panel = panel
    panel.name = "熊智专业邮寄助手 / BearAI Profession Mail"
    local content = CreateFrame("Frame", nil, panel)
    S.content = content
    content:SetPoint("TOPLEFT", 16, -10)
    content:SetSize(640, 500)
    ns.UI.Brand(content, 18, -7)
    ns.UI.Label(content, ns.version, 510, -17, 100, 11, ns.Theme.muted)
    S.characters = ns.CreateCharacterList()
    S.characters.Create(content, { settings = true })
    local help = ns.UI.Label(content,
        "“更新当前角色”仅刷新当前登录角色；其他本账号角色需登录后自动更新。\n同一 WoW 账号和客户端共享记录，不同 WoW 账号不自动共享。\n手动角色与登录角色名称、服务器相同，会以游戏实测信息更新并转为本账号角色。\n数据在退出或 /reload 时由游戏保存；未登录的角色显示上次记录。",
        18, -340, 600, 12, ns.Theme.muted)
    help:SetHeight(100)
    help:SetWordWrap(true)
    S.rulesButton = ns.UI.Button(content, "物品规则", 18, -448, 120, function() ns.ItemRulesPanel.Open() end)
    ns.UI.Label(content, "独立维护物品归属；用户数据优先于助手数据。", 152, -455, 460, 11, ns.Theme.muted)
    panel:SetScript("OnShow", function()
        content:SetScale(math.max(0.65, math.min(1, (panel:GetWidth() - 32) / 640, (panel:GetHeight() - 20) / 500)))
        S.Refresh()
    end)
    panel:SetScript("OnHide", function()
        ns.UI.CloseDropdown()
        if ns.Editor and ns.Editor:GetParent() == content then ns.Editor:Hide() end
        GameTooltip:Hide()
    end)
    panel:Hide()
    S.category = ns.Compatibility.RegisterSettings(panel)
end
function S.Open()
    if Settings and Settings.OpenToCategory and type(S.category) == "table" and S.category.GetID then
        Settings.OpenToCategory(S.category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory and S.panel then
        InterfaceOptionsFrame_OpenToCategory(S.panel)
    else ns.Print("请在游戏设置的插件列表中打开熊智专业邮寄助手。") end
end
