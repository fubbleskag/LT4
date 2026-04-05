local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils

local Prof = {}
LumiBar:RegisterModule("Profession", Prof)

local profIcons = {
    [164] = "Interface\\Icons\\trade_blacksmithing",
    [165] = "Interface\\Icons\\trade_leatherworking",
    [171] = "Interface\\Icons\\trade_alchemy",
    [182] = "Interface\\Icons\\trade_herbalism",
    [186] = "Interface\\Icons\\trade_mining",
    [197] = "Interface\\Icons\\trade_tailoring",
    [202] = "Interface\\Icons\\trade_engineering",
    [333] = "Interface\\Icons\\trade_engraving", -- Enchanting
    [356] = "Interface\\Icons\\trade_fishing",
    [393] = "Interface\\Icons\\trade_skinning",
    [755] = "Interface\\Icons\\inv_misc_gem_01", -- JC
    [773] = "Interface\\Icons\\inv_inscription_tradeskill01", -- Inscription
    [794] = "Interface\\Icons\\trade_archaeology",
}

function Prof:Init()
    self.db = LumiBar.db.profile.modules.Profession
    
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
            abbreviate = {
                name = "Abbreviate",
                type = "toggle",
                order = 1,
            },
            showBars = {
                name = "Show Progress Bars",
                type = "toggle",
                order = 2,
            },
        }
    }
    LumiBar:RegisterModuleOptions("Profession", options)
end

function Prof:UpdateStatus()
    local prof1, prof2 = GetProfessions()
    local name1, icon1, rank1, max1, _, _, id1 = nil, nil, 0, 0, nil, nil, 0
    local name2, icon2, rank2, max2, _, _, id2 = nil, nil, 0, 0, nil, nil, 0
    
    if prof1 then name1, icon1, rank1, max1, _, _, id1 = GetProfessionInfo(prof1) end
    if prof2 then name2, icon2, rank2, max2, _, _, id2 = GetProfessionInfo(prof2) end
    
    if name1 then
        self.text1:SetFormattedText("%s: %d/%d", name1, rank1, max1)
        self.text1:Show()
    else
        self.text1:Hide()
    end
    
    if name2 then
        self.text2:SetFormattedText("%s: %d/%d", name2, rank2, max2)
        self.text2:Show()
    else
        self.text2:Hide()
    end
    self:UpdateWidth()
end

function Prof:UpdateWidth()
    if not self.text1 then return end
    local w1 = self.text1:IsShown() and self.text1:GetStringWidth() or 0
    local w2 = self.text2:IsShown() and self.text2:GetStringWidth() or 0
    
    Utils:UpdateModuleWidth(self, math.max(w1, w2) + 16, function() self:UpdateWidth() end)
end

function Prof:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.Profession
    
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
        self.text1 = self.frame:CreateFontString(nil, "OVERLAY")
        self.text2 = self.frame:CreateFontString(nil, "OVERLAY")
        
        self.frame:RegisterEvent("TRADE_SKILL_SHOW")
        self.frame:RegisterEvent("SKILL_LINES_CHANGED")
        self.frame:SetScript("OnEvent", function() self:UpdateStatus() end)
    end
    
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame)
    self:UpdateStatus()
end

function Prof:Refresh(slotFrame)
    if not self.text1 then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end
    local align = slotFrame.align or "CENTER"
    
    self.frame:SetHeight(slotFrame:GetHeight())
    
    Utils:SetFont(self.text1)
    Utils:SetFont(self.text2)
    
    Utils:ApplyBackground(self.frame, self.db)
    
    -- Calculate and Set Width
    local w1 = self.text1:IsShown() and self.text1:GetStringWidth() or 0
    local w2 = self.text2:IsShown() and self.text2:GetStringWidth() or 0
    self.frame:SetWidth(math.max(w1, w2) + 10)
    
    self.text1:ClearAllPoints()
    self.text2:ClearAllPoints()
    
    if align == "LEFT" then
        self.text1:SetPoint("LEFT", self.frame, "LEFT", 5, 5)
        self.text2:SetPoint("LEFT", self.frame, "LEFT", 5, -5)
    elseif align == "RIGHT" then
        self.text1:SetPoint("RIGHT", self.frame, "RIGHT", -5, 5)
        self.text2:SetPoint("RIGHT", self.frame, "RIGHT", -5, -5)
    else
        self.text1:SetPoint("TOP", self.frame, "TOP", 0, -2)
        self.text2:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 2)
    end
    
    -- Tooltip & Flyout (simplified for now)
    self.frame:SetScript("OnEnter", function(f)
        local lines = {}
        local prof1, prof2, arch, fish, cook = GetProfessions()
        local projs = {prof1, prof2, arch, fish, cook}
        for _, p in ipairs(projs) do
            if p then
                local name, icon, rank, max = GetProfessionInfo(p)
                table.insert(lines, {name, string.format("%d / %d", rank, max)})
            end
        end
        Utils:SetTooltip(f, "Professions", lines)
        local script = f:GetScript("OnEnter")
        if script then script(f) end
    end)
end
