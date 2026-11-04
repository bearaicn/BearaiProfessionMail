local B = NS.MailButton
local oldClose, oldGlobal = MailFrame.CloseButton, MailFrameCloseButton
B.Show()
assert(B.button.label:GetText() == '专业材料' and B.button:GetWidth() == 72 and B.button:GetHeight() == 22)
assert(B.button.label.point[1]=='CENTER' and B.button.label.justifyV=='MIDDLE')
local close = CreateFrame('Button', nil, MailFrame)
MailFrame.CloseButton = close
local tabPoint, tabCount = MailFrameTab1.point, MailFrame.numTabs
B.Position()
assert(B.button.point[1] == 'RIGHT' and B.button.point[2] == close
    and B.button.point[3] == 'LEFT' and B.button.point[4] == -6 and B.button.point[5] == 0,
    '入口应在关闭按钮左侧')
assert(MailFrameTab1.point == tabPoint and MailFrame.numTabs == tabCount)
local replacement = CreateFrame('Button', nil, MailFrame)
MailFrame.CloseButton = replacement
B.button.scripts.OnUpdate(B.button,0.3)
assert(B.button.point[2] == replacement, '跟随邮箱换肤后的关闭按钮')
replacement:Hide()
MailFrameCloseButton = close
B.Position()
assert(B.button.point[2] == close, '兼容经典客户端全局关闭按钮')
MailFrame.CloseButton, MailFrameCloseButton = nil,nil
B.Position()
assert(B.button.point[1] == 'TOPRIGHT' and B.button.point[2] == MailFrame
    and B.button.point[3] == 'TOPRIGHT' and B.button.point[4] == -38)
MailFrame.CloseButton, MailFrameCloseButton = oldClose,oldGlobal
-- 33 格分三行，第三行不能越过材料背景或分页控件。
local G = NS.MaterialGrid
assert(#G.rows == 33 and G.attachments == nil)
assert(G.rows[23].point[3] == -109 and G.rows[33].point[3] == -109)
assert(G.rows[33]:GetParent():GetHeight() >= 109+46)
assert(G.previous.point[3] < -408-161)
assert(G.rulesButton.point[3] == G.previous.point[3] and G.rulesButton.point[2]+G.rulesButton:GetWidth()==622,
    '物品规则位于分页行最右边并对齐材料区右边缘')
assert(G.addAll.point[3]==-367 and G.addAll.point[2]==516 and G.addAll:GetWidth()==106
    and G.rulesButton:GetWidth()==106, '一键添加与物品规则互换位置且宽度统一106')
B.Position(); B.Hide()
local oldOpen = NS.MailController.open
NS.MailController.open=true
MailFrame:Hide(); SendMailFrame:Hide()
B.Show()
assert(not B.button:IsShown(), '父邮箱尚未显示时不应误报可见')
MailFrame:Show()
MailFrame.hooks.OnShow(MailFrame)
assert(B.button:IsShown(), 'MAIL_SHOW早于窗体显示时，首次OnShow仍须显示入口')
NS.MailController.open=oldOpen
B.Hide()
print('PASS: 专业材料右上入口/两种关闭按钮/延迟换肤/缺失回退/三行33格/无重复附件区')
