local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils

local Prof = {}
LumiBar:RegisterModule("Profession", Prof)

local function GetAvailableProfessions()
    local profs = { GetProfessions() }
    local available = { [0] = "None" }
    for i, pIndex in ipairs(profs) do
        if pIndex then
            local name = GetProfessionInfo(pIndex)
            available[pIndex] = name
        end
    end
    return available
end

function Prof:Init()
    self.db = LumiBar.db.profile.modules.Profession
    
    -- Set defaults
    if self.db.prof1Index == nil then self.db.prof1Index = 0 end
    if self.db.prof2Index == nil then self.db.prof2Index = 0 end
    if self.db.showBars == nil then self.db.showBars = true end

    local options = {
        name = "Profession",
        type = "group",
        get = function(info) return self.db[info[#info]] end,
        set = function(info, value) 
            self.db[info[#info]] = value
            self:Refresh()
            self:UpdateStatus()
        end,
        args = {
            prof1Index = {
                name = "Profession 1",
                type = "select",
                values = function() return GetAvailableProfessions() end,
                order = 1,
            },
            prof2Index = {
                name = "Profession 2",
                type = "select",
                values = function() return GetAvailableProfessions() end,
                order = 2,
            },
            showBars = {
                name = "Show Progress Bars",
                type = "toggle",
                order = 3,
            },
        }
    }
    LumiBar:RegisterModuleOptions("Profession", options)
end

function Prof:UpdateProfession(index, bar, text)
    if not index or index == 0 then
        bar:Hide()
        text:Hide()
        return false
    end

    local name, icon, rank, max, _, _, id = GetProfessionInfo(index)
    if not name then
        bar:Hide()
        text:Hide()
        return false
    end

    text:SetText(string.format("%s: %d/%d", name, rank, max))
    text:Show()
    bar:Show() -- Always show the frame for mouse interaction and anchoring

    if self.db.showBars then
        bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        bar:SetMinMaxValues(0, max)
        bar:SetValue(rank)
        bar.bg:Show()
        
        -- Use the same color as DataBar XP (Blue)
        local color = { r = 0, g = 0.4, b = 1 }
        bar:SetStatusBarColor(color.r, color.g, color.b, 1)
        bar.bg:SetVertexColor(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.8)
    else
        -- Hide bar visuals by setting alpha to 0 in colors
        bar:SetStatusBarColor(0, 0, 0, 0)
        bar.bg:SetVertexColor(0, 0, 0, 0)
        bar.bg:Hide()
    end
    
    -- Store index for click handling
    bar.profIndex = index
    bar.profID = id
    bar.profName = name
    
    return true
end

function Prof:UpdateStatus()
    local has1 = self:UpdateProfession(self.db.prof1Index, self.bar1, self.text1)
    local has2 = self:UpdateProfession(self.db.prof2Index, self.bar2, self.text2)
    
    self:Refresh()
    self:UpdateWidth()
end

function Prof:UpdateWidth()
    if not self.frame then return end
    local barW = 150
    Utils:UpdateModuleWidth(self, barW + 20, nil)
end

function Prof:GetProfessionItems()
    local items = {}
    local prof1, prof2, arch, fish, cook = GetProfessions()
    local projs = {prof1, prof2, arch, fish, cook}
    
    local foundProfs = {}
    for _, p in ipairs(projs) do
        if p then table.insert(foundProfs, p) end
    end

    for i = #foundProfs, 1, -1 do
        local p = foundProfs[i]
        local name, icon, rank, max, _, _, id = GetProfessionInfo(p)
        
        local macro = "/cast " .. name
        if id and id > 0 then
            macro = "/run C_TradeSkillUI.OpenTradeSkill(" .. id .. ")"
        end

        table.insert(items, {
            name = string.format("%s (%d/%d)", name, rank, max),
            icon = icon,
            type = "macro",
            macrotext = macro,
        })
    end
    return items
end

function Prof:HandleClick(bar, button)
    if not bar.profIndex or bar.profIndex == 0 then return end
    if InCombatLockdown() then return end
    
    if button == "LeftButton" then
        local id = bar.profID
        local name = bar.profName
        if id and id > 0 then
            C_TradeSkillUI.OpenTradeSkill(id)
        else
            CastSpellByName(name)
        end
    elseif button == "RightButton" then
        local items = self:GetProfessionItems()
        local direction = (LumiBar.db.profile.bar.position == "BOTTOM") and "UP" or "DOWN"
        LumiBar.SecureFlyout:ShowMenu(self.frame, items, direction)
    end
end

function Prof:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.Profession
    
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
        
        local function CreateProfBar(id)
            local bar = CreateFrame("StatusBar", nil, self.frame)
            bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
            bar.bg = bar:CreateTexture(nil, "BACKGROUND")
            bar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            bar.bg:SetAllPoints(bar)
            
            -- Parent text to the bar so it's always on top of the bar's texture
            local text = bar:CreateFontString(nil, "OVERLAY")
            text:SetDrawLayer("OVERLAY", 7)
            
            bar:EnableMouse(true)
            bar:SetScript("OnMouseDown", function(s, button) self:HandleClick(s, button) end)
            
            return bar, text
        end

        self.bar1, self.text1 = CreateProfBar(1)
        self.bar2, self.text2 = CreateProfBar(2)
        
        self.frame:RegisterEvent("TRADE_SKILL_SHOW")
        self.frame:RegisterEvent("SKILL_LINES_CHANGED")
        self.frame:RegisterEvent("CHAT_MSG_SKILL")
        self.frame:SetScript("OnEvent", function() self:UpdateStatus() end)
    end
    
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame)
    self:UpdateStatus()
end

function Prof:Refresh(slotFrame)
    if not self.frame then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end
    
    local barHeight = slotFrame:GetHeight()
    self.frame:SetHeight(barHeight)
    
    Utils:SetFont(self.text1)
    Utils:SetFont(self.text2)
    Utils:ApplyBackground(self.frame, self.db)
    
    local has1 = self.db.prof1Index and self.db.prof1Index > 0
    local has2 = self.db.prof2Index and self.db.prof2Index > 0
    
    local barW = 150
    local innerBarHeight = 10
    
    if has1 and has2 then
        innerBarHeight = (barHeight / 2) - 4
        self.bar1:SetSize(barW, innerBarHeight)
        self.bar2:SetSize(barW, innerBarHeight)
        
        self.bar1:ClearAllPoints()
        self.bar1:SetPoint("TOP", self.frame, "TOP", 0, -2)
        
        self.bar2:ClearAllPoints()
        self.bar2:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 2)
    else
        innerBarHeight = barHeight - 8
        self.bar1:SetSize(barW, innerBarHeight)
        self.bar2:SetSize(barW, innerBarHeight)
        
        self.bar1:ClearAllPoints()
        self.bar1:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
        
        self.bar2:ClearAllPoints()
        self.bar2:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
    end
    
    self.text1:ClearAllPoints()
    self.text1:SetPoint("CENTER", self.bar1, "CENTER", 0, 0)
    
    self.text2:ClearAllPoints()
    self.text2:SetPoint("CENTER", self.bar2, "CENTER", 0, 0)
end
