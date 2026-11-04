local addonName, ns = ...
ns.name = addonName
local metadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
ns.version = metadata and metadata(addonName, "Version") or "development"
ns.events = CreateFrame("Frame")
function ns.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffd8b45cBearAI 邮寄助手：|r" .. tostring(message))
end
function ns.Refresh()
    if ns.MainFrame and ns.MainFrame:IsShown() then
        ns.CharacterList.Refresh()
        ns.MaterialGrid.Refresh()
    end
end
local function updateCharacter()
    local ok, err = ns.CharacterManager.RecordCurrent()
    if not ok and err then ns.Print(err) end
end
ns.events:SetScript("OnEvent", function(_, event, arg)
    if event == "ADDON_LOADED" and arg == addonName then
        ns.Database.Initialize()
        ns.ready = true
    elseif not ns.ready then
        return
    elseif event == "PLAYER_LOGIN" then
        updateCharacter()
        SLASH_BEARAIPROFESSIONMAIL1 = "/bpm"
        SlashCmdList.BEARAIPROFESSIONMAIL = function(message)
            if message == "diag" then ns.Print(ns.Compatibility.Diagnostics())
            elseif ns.MailController.IsOpen() then ns.MailButton.Toggle()
            else ns.Print("请先打开原生邮箱；/bpm diag 可查看兼容信息。") end
        end
    elseif event == "SKILL_LINES_CHANGED" then
        updateCharacter()
        ns.Refresh()
    elseif event == "MAIL_SHOW" then
        ns.MailController.open = true
        ns.MailButton.Show()
    elseif event == "MAIL_CLOSED" then
        ns.MailController.open = false
        ns.MailButton.Hide()
    elseif event == "BAG_UPDATE_DELAYED" or event == "GET_ITEM_INFO_RECEIVED"
        or event == "MAIL_SEND_INFO_UPDATE" or event == "PLAYER_REGEN_ENABLED" then
        ns.Refresh()
    end
end)
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "SKILL_LINES_CHANGED", "MAIL_SHOW",
    "MAIL_CLOSED", "BAG_UPDATE_DELAYED", "GET_ITEM_INFO_RECEIVED", "MAIL_SEND_INFO_UPDATE",
    "PLAYER_REGEN_ENABLED" }) do
    ns.events:RegisterEvent(event)
end
