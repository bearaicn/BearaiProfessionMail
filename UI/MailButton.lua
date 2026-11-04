local _, ns = ...
local B = {}
ns.MailButton = B
function B.Visibility()
    if not B.button then return end
    -- 邮箱打开即显示；接口可能延迟就绪，不能据此隐藏用户入口。
    B.button:SetShown(not not ns.MailController.IsOpen())
end
function B.Position()
    if not B.button or not MailFrame then return end
    -- 入口位于关闭按钮左边，不参与标签行或右侧分类栏的排列。
    local anchor = MailFrame.CloseButton
    if not anchor or not anchor:IsShown() then anchor = _G["MailFrameCloseButton"] end
    B.button:ClearAllPoints()
    if anchor and anchor:IsShown() then
        B.button:SetPoint("RIGHT", anchor, "LEFT", -6, 0)
    else
        B.button:SetPoint("TOPRIGHT", MailFrame, "TOPRIGHT", -38, -4)
    end
    B.Visibility()
end
function B.Toggle()
    if not ns.MailController.IsOpen() then return end
    local switched, reason = ns.Compatibility.ShowSend()
    if not switched then ns.Print(reason); B.Visibility(); return end
    ns.UI.Create()
    ns.MainFrame:SetShown(not ns.MainFrame:IsShown())
end
function B.Show()
    if not MailFrame then ns.Print("找不到原生 MailFrame，请运行 /bpm diag。") return end
    if not B.button then
        B.button = ns.UI.Button(MailFrame, "专业材料", 0, 0, 72, B.Toggle)
        B.button:SetHeight(22)
        B.button.label:ClearAllPoints()
        B.button.label:SetPoint("CENTER", B.button, "CENTER", 0, 0)
        B.button.label:SetSize(64,22)
        B.button.label:SetJustifyV("MIDDLE")
        -- 邮箱换肤可能延迟替换关闭按钮，低频重新识别锚点。
        B.button:SetScript("OnUpdate", function(_, elapsed)
            B.elapsed = (B.elapsed or 0) + elapsed
            if B.elapsed >= 0.25 then B.elapsed = 0; B.Position() end
        end)
        MailFrame:HookScript("OnHide", B.Hide)
        -- MAIL_SHOW 可能早于邮箱窗体真正显示；父框体 OnShow 时再次挂出入口。
        MailFrame:HookScript("OnShow", function()
            if ns.MailController.open then B.Show() end
        end)
        if SendMailFrame then
            SendMailFrame:HookScript("OnShow", B.Visibility)
            SendMailFrame:HookScript("OnHide", B.Visibility)
        end
    end
    B.Position()
    B.Visibility()
end
function B.Hide()
    if B.button then B.button:Hide() end
    if ns.MainFrame then ns.MainFrame:Hide() end
end
