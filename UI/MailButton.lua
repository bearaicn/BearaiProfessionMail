local _, ns = ...
local B = {}
ns.MailButton = B
function B.Position()
    if not B.button or not MailFrame then return end
    local anchor, right = nil, -math.huge
    local scale = MailFrame:GetEffectiveScale()
    for index = 1, math.max(MailFrame.numTabs or 2, 2) do
        local tab = _G["MailFrameTab" .. index]
        if tab and tab:IsShown() and tab:GetRight() then
            local edge = tab:GetRight() * tab:GetEffectiveScale() / scale
            if edge > right then anchor, right = tab, edge end
        end
    end
    B.button:ClearAllPoints()
    if anchor then
        if right + 76 <= (MailFrame:GetRight() or right) then
            B.button:SetPoint("LEFT", anchor, "RIGHT", 5, 0)
        else
            B.button:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -5)
        end
    else
        B.button:SetPoint("TOPLEFT", MailFrame, "BOTTOMLEFT", 16, -6)
    end
end
function B.Toggle()
    if not ns.MailController.IsOpen() then return end
    ns.UI.Create()
    ns.MainFrame:SetShown(not ns.MainFrame:IsShown())
end
function B.Show()
    if not MailFrame then ns.Print("找不到原生 MailFrame，请运行 /bpm diag。") return end
    if not B.button then
        B.button = ns.UI.Button(MailFrame, "材料", 0, 0, 70, B.Toggle)
        -- 等待其他邮箱插件的布局稳定，并跟随它们后续的标签重排。
        B.button:SetScript("OnUpdate", function(_, elapsed)
            B.elapsed = (B.elapsed or 0) + elapsed
            if B.elapsed >= 0.25 then B.elapsed = 0; B.Position() end
        end)
        MailFrame:HookScript("OnHide", B.Hide)
    end
    B.Position()
    B.button:Show()
end
function B.Hide()
    if B.button then B.button:Hide() end
    if ns.MainFrame then ns.MainFrame:Hide() end
end
