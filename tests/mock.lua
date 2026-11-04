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
function methods:GetHeight() return 900 end
function methods:GetFrameLevel() return 10 end
local function noop() end
for _, name in ipairs({ 'SetSize','SetPoint','SetWidth','SetJustifyH','SetAutoFocus','SetMaxLetters',
    'ClearFocus','SetBackdrop','EnableMouse','SetClampedToScreen','SetScale','SetFrameStrata',
    'SetFrameLevel','SetEnabled','ClearAllPoints','RegisterForDrag','SetTexture','SetDesaturated',
    'SetHighlightTexture','SetOwner','SetBagItem','AddLine' }) do methods[name] = noop end
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
