local _, ns = ...
local B = {}
ns.MailButton = B
function B.Toggle()
    if not ns.MailController.IsOpen() then return end
    ns.UI.Create()
    ns.MainFrame:SetShown(not ns.MainFrame:IsShown())
end
function B.Show()
    if not MailFrame then ns.Print("找不到原生 MailFrame，请运行 /bpm diag。") return end
    if not B.button then
        B.button = ns.UI.Button(MailFrame, "专业材料", 0, 0, 90, B.Toggle)
        B.button:ClearAllPoints()
        B.button:SetPoint("TOPRIGHT", MailFrame, "TOPRIGHT", -35, -35)
        MailFrame:HookScript("OnHide", B.Hide)
    end
    B.button:Show()
end
function B.Hide()
    if B.button then B.button:Hide() end
    if ns.MainFrame then ns.MainFrame:Hide() end
end
