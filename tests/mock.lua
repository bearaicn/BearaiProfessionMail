NS = {}
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}
UIParent = nil
local methods = {}
function methods:SetScript(event, fn) self.scripts[event] = fn end
function methods:HookScript(event, fn) self.hooks[event] = fn end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:SetText(text)
    self.text = text
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
end
function methods:GetText() return self.text or '' end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:IsShown() return self.shown and (not self.parent or self.parent:IsShown()) end
function methods:Show()
    local old = self.shown
    self.shown = true
    if not old and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide()
    local old = self.shown
    self.shown = false
    if old and self.scripts.OnHide then self.scripts.OnHide(self) end
    if old and self.hooks.OnHide then self.hooks.OnHide(self) end
end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:GetHeight() return self.height or 900 end
function methods:GetWidth() return self.width or 1400 end
function methods:GetEffectiveScale() return self.scale or 1 end
function methods:GetRight() return self.right or 400 end
function methods:GetLeft() return self.left or 0 end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetWidth(width) self.width = width end
function methods:SetHeight(height) self.height = height end
function methods:SetScale(scale) self.scale = scale end
function methods:SetPoint(...) self.point = {...} end
function methods:SetBackdropColor(...) self.background = {...} end
function methods:SetBackdropBorderColor(...) self.border = {...} end
function methods:SetEnabled(enabled) self.enabled = enabled end
function methods:SetFont(...) self.font = {...} end
function methods:SetTextColor(...) self.textColor = {...} end
function methods:SetParent(parent) self.parent = parent end
function methods:GetParent() return self.parent end
function methods:GetFrameStrata() return self.strata or (self.parent and self.parent:GetFrameStrata()) or 'MEDIUM' end
function methods:SetFrameStrata(value) self.strata = value end
function methods:GetFrameLevel() return 10 end
local function noop() end
for _, name in ipairs({ 'SetJustifyH','SetAutoFocus','SetMaxLetters',
    'ClearFocus','SetBackdrop','EnableMouse','SetClampedToScreen',
    'SetFrameLevel','ClearAllPoints','RegisterForDrag','SetTexture','SetDesaturated',
    'SetHighlightTexture','SetOwner','SetBagItem','AddLine','SetFontObject','SetTextInsets',
    'SetWordWrap','SetAllPoints','EnableMouseWheel','SetTexCoord','SetMovable','StartMoving','StopMovingOrSizing',
    'SetVertexColor','SetRotation','RegisterForClicks','SetSendMailItem' }) do methods[name] = noop end
function CreateFrame(kind, name, parent, template)
    local frame = setmetatable({ scripts = {}, hooks = {}, events = {}, shown = true, parent = parent }, { __index = methods })
    if name then _G[name] = frame end
    return frame
end
function methods:CreateFontString() return CreateFrame('FontString') end
function methods:CreateTexture() return CreateFrame('Texture') end
UIParent = CreateFrame('Frame')
MailFrame = CreateFrame('Frame', nil, UIParent)
SendMailFrame = CreateFrame('Frame', nil, MailFrame)
SendMailNameEditBox = CreateFrame('EditBox')
GameTooltip = CreateFrame('GameTooltip')
function GetBuildInfo() return '1.15.9', '70576', '', TEST_INTERFACE or 11509 end
function UnitName() return '测试角色' end
function GetRealmName() return '测试服' end
function UnitClass() return '法师', 'MAGE' end
function UnitLevel() return TEST_LEVEL or 42 end
function time() return 1793750400 end
function InCombatLockdown() return COMBAT or false end
function CursorHasItem() return CURSOR or false end
function GetCursorInfo() return CURSOR and 'item' or nil end
C_Item = { GetItemInfo = function(id) return id == 2589 and '亚麻布' or '测试物品' end }
BAGS = { [0] = { [1] = { itemID = 2589, stackCount = 20, iconFileID = 1, hyperlink = 'item:2589' },
    [2] = { itemID = 2770, stackCount = 3, iconFileID = 2, hyperlink = 'item:2770' },
    [3] = { itemID = 2589, stackCount = 2, iconFileID = 1, isBound = true } } }
C_Container = {
    GetContainerNumSlots = function(bag) return bag == 0 and 3 or 0 end,
    GetContainerItemInfo = function(bag, slot) return BAGS[bag] and BAGS[bag][slot] end,
    PickupContainerItem = function(bag, slot) PICKED = { bag, slot }; CURSOR = true end,
}
SKILLS_COLLAPSED = true
function GetNumSkillLines() return SKILLS_COLLAPSED and 1 or 3 end
function GetSkillLineInfo(i)
    if i == 1 then return '专业', true, not SKILLS_COLLAPSED end
    if i == 2 then return '裁缝', false, false, 75, 0, 0, 150 end
    return '急救', false, false, 40, 0, 0, 75
end
function ExpandSkillHeader() SKILLS_COLLAPSED = false end
function CollapseSkillHeader() SKILLS_COLLAPSED = true end
MailFrame.numTabs = 3
for index = 1, 3 do
    local tab = CreateFrame('Button', 'MailFrameTab' .. index, MailFrame)
    tab.right = 50 + index * 75
end
ATTACHMENTS_MAX_SEND = 12
MAIL_ITEMS = {}
function HasSendMailItem(index) return MAIL_ITEMS[index] ~= nil end
function GetSendMailItem(index)
    local row = MAIL_ITEMS[index]
    if row then return row.name, row.itemID, row.icon, row.count, row.quality end
end
function GetSendMailItemLink(index) return MAIL_ITEMS[index] and MAIL_ITEMS[index].link end
function ClickSendMailItemButton(index, remove)
    if remove then
        if MAIL_REJECT_REMOVE then return end
        local row = MAIL_ITEMS[index]
        if row then
            local slot = row.sourceSlot or 1
            while BAGS[0][slot] do slot = slot + 1 end
            BAGS[0][slot] = { itemID = row.itemID, stackCount = row.count, iconFileID = row.icon, hyperlink = row.link }
        end
        MAIL_ITEMS[index] = nil
        return
    end
    assert(CURSOR and PICKED, '附加操作必须有真实背包光标')
    assert(not MAIL_ITEMS[index], '禁止替换已有附件')
    local bag, slot = PICKED[1], PICKED[2]
    local info = BAGS[bag][slot]
    MAIL_ITEMS[index] = { itemID = info.itemID, count = info.stackCount, name = '模拟附件', icon = info.iconFileID, link = info.hyperlink, sourceSlot = slot }
    BAGS[bag][slot] = nil
    CURSOR = false
end
Settings = {
    RegisterCanvasLayoutCategory = function(panel, name)
        SETTINGS_REGISTERED = panel
        return { GetID = function() return 123 end }
    end,
    RegisterAddOnCategory = function() end,
    OpenToCategory = function(id) SETTINGS_OPENED = id end,
}
