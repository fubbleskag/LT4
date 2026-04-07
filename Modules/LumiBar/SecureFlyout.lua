local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")

-- Performance: Cache common lookups
local UIParent = UIParent
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local IsMouseButtonDown = IsMouseButtonDown
local ipairs = ipairs

-- Flyout Frames Pool
local Flyouts = {}
local buttonPool = {}

local function CreateFlyoutFrame(name, level)
    local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    f:Hide()
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f.level = level
    Flyouts[level] = f
    buttonPool[level] = {}
    return f
end

local SecureFlyout = CreateFlyoutFrame("LumiBarSecureFlyout", 1)
LumiBar.SecureFlyout = SecureFlyout
local SecureFlyoutSub = CreateFlyoutFrame("LumiBarSecureFlyoutSub", 2)
local SecureFlyoutSub2 = CreateFlyoutFrame("LumiBarSecureFlyoutSub2", 3)

local function SkinButton(btn)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    btn:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    btn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetPoint("LEFT", btn, "LEFT", 4, 0)
    btn.icon:SetSize(20, 20)
    btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 8, 0)
    btn.text:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
    btn.text:SetJustifyH("LEFT")
    
    btn:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
    local hl = btn:GetHighlightTexture()
    hl:SetVertexColor(1, 1, 1, 0.1)
    hl:SetAllPoints()
end

local function GetButton(level, index, parent)
    local pool = buttonPool[level]
    if not pool[index] then
        local btn = CreateFrame("Button", parent:GetName() .. "Btn" .. index, parent, "SecureActionButtonTemplate, BackdropTemplate")
        SkinButton(btn)
        btn:RegisterForClicks("AnyUp", "AnyDown")
        btn:SetScript("PostClick", function()
            for l = 1, #Flyouts do Flyouts[l]:Hide() end
        end)
        pool[index] = btn
    end
    return pool[index]
end

local function SetupMenu(level, parent, items, direction)
    local frame = Flyouts[level]
    frame.currentParent = parent
    frame:ClearAllPoints()
    
    local minBtnWidth, btnHeight = 180, 26
    local spacing = 2
    local padding = 4
    local maxBtnWidth = minBtnWidth
    
    -- First pass: Set text and measure needed width
    for i, item in ipairs(items) do
        local btn = GetButton(level, i, frame)
        local displayName = item.name or "Unknown"
        if item.isActive then
            displayName = "|cff00ff00" .. displayName .. "|r"
        end
        
        if item.isCategory then
            btn.text:SetText(displayName .. "  |cff888888>|r")
        else
            btn.text:SetText(displayName)
        end
        
        -- Apply font before measuring
        LumiBar.Utils:SetFont(btn.text)
        
        local textWidth = btn.text:GetStringWidth()
        -- Math: Left Padding (4 or 8) + Icon (20) + Text Spacing (8) + Right Padding (4) + Buffer
        local nonTextWidth = (item.icon and 36 or 12) + (padding * 2)
        local buffer = 15 -- Extra safety buffer to prevent wrapping
        local neededWidth = textWidth + nonTextWidth + buffer
        
        if neededWidth > maxBtnWidth then
            maxBtnWidth = neededWidth
        end
    end

    local count = 0
    for i, item in ipairs(items) do
        local btn = GetButton(level, i, frame)
        btn:ClearAllPoints()
        
        if item.isCategory then
            btn:SetAttribute("type", nil)
            btn:SetScript("OnEnter", function(s)
                GameTooltip:Hide()
                for l = level + 1, #Flyouts do Flyouts[l]:Hide() end
                LumiBar.SecureFlyout:ShowSubMenu(level + 1, s, item.subItems, direction)
            end)
        else
            if item.type == "spell" then
                btn:SetAttribute("type", "spell")
                btn:SetAttribute("spell", item.id)
            elseif item.type == "item" or item.type == "toy" then
                btn:SetAttribute("type", "item")
                btn:SetAttribute("item", "item:" .. item.id)
            elseif item.type == "macro" then
                btn:SetAttribute("type", "macro")
                btn:SetAttribute("macrotext", item.macrotext)
            end
            btn:SetScript("OnEnter", function(s) 
                for l = level + 1, #Flyouts do Flyouts[l]:Hide() end
                
                if item.type == "spell" and item.id then
                    GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
                    GameTooltip:SetSpellByID(item.id)
                    GameTooltip:Show()
                elseif (item.type == "item" or item.type == "toy") and item.id then
                    GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
                    GameTooltip:SetItemByID(item.id)
                    GameTooltip:Show()
                end
            end)
        end
        
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        if item.icon then
            btn.icon:SetTexture(item.icon)
            btn.icon:Show()
            btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 8, 0)
        else
            btn.icon:Hide()
            btn.text:SetPoint("LEFT", btn, "LEFT", 8, 0)
        end
        
        btn:SetWidth(maxBtnWidth - (padding * 2))
        btn:SetHeight(btnHeight)
        btn:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding - (i-1) * (btnHeight + spacing))
        btn:Show()
        count = i
    end
    
    for i = count + 1, #buttonPool[level] do
        buttonPool[level][i]:Hide()
    end
    
    local totalHeight = (count * btnHeight) + ((count - 1) * spacing) + (padding * 2)
    frame:SetSize(maxBtnWidth, totalHeight)
    
    if level > 1 then
        local parentRight = parent:GetRight() or 0
        local screenWidth = UIParent:GetRight() or GetScreenWidth()
        -- If showing on the right would go off-screen, show on the left instead
        if parentRight + maxBtnWidth + 20 > screenWidth then
            frame:SetPoint("RIGHT", parent, "LEFT", -2, 0)
        else
            frame:SetPoint("LEFT", parent, "RIGHT", 2, 0)
        end
    else
        if direction == "UP" then
            frame:SetPoint("BOTTOM", parent, "TOP", 0, 8)
        else
            frame:SetPoint("TOP", parent, "BOTTOM", 0, -8)
        end
    end
    frame:Show()
end

function SecureFlyout:ShowMenu(parent, items, direction)
    if InCombatLockdown() then return end
    if self:IsShown() and self.currentParent == parent then
        for l = 1, #Flyouts do Flyouts[l]:Hide() end
        return
    end
    SetupMenu(1, parent, items, direction)
end

function SecureFlyout:ShowSubMenu(level, parentBtn, items, direction)
    if InCombatLockdown() then return end
    SetupMenu(level, parentBtn, items, direction)
end

local function HideAll()
    for l = 1, #Flyouts do Flyouts[l]:Hide() end
end

SecureFlyout:RegisterEvent("PLAYER_REGEN_DISABLED")
SecureFlyout:SetScript("OnEvent", HideAll)

-- Optimization: Throttled OnUpdate
local lastUpdate = 0
local function OnUpdate(self, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate < 0.05 then return end
    lastUpdate = 0

    local isOverAny = false
    for l = 1, #Flyouts do
        local f = Flyouts[l]
        if f:IsShown() and f:IsMouseOver() then
            isOverAny = true
            break
        end
    end

    if not isOverAny and not (self.currentParent and self.currentParent:IsMouseOver()) and IsMouseButtonDown("LeftButton") then
        HideAll()
    end
end

for l = 1, #Flyouts do
    Flyouts[l]:SetScript("OnUpdate", OnUpdate)
end
