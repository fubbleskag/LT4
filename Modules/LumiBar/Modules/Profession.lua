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
            displayMode = {
                name = "Display Mode",
                type = "select",
                values = { ["BOTH"] = "Both", ["PROF1"] = "Profession 1 Only", ["PROF2"] = "Profession 2 Only" },
                order = 1,
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
    
    local mode = self.db.displayMode or "BOTH"
    
    if (mode == "BOTH" or mode == "PROF1") and name1 then
        self.text1:SetFormattedText("%s: %d/%d", name1, rank1, max1)
        self.text1:Show()
    else
        self.text1:Hide()
    end
    
    if (mode == "BOTH" or mode == "PROF2") and name2 then
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

function Prof:GetProfessionItems()
    local items = {}
    local prof1, prof2, arch, fish, cook = GetProfessions()
    local projs = {prof1, prof2, arch, fish, cook}
    
    -- Reverse sort requested: check projs in original order but insert into items in reverse of found
    local foundProfs = {}
    for _, p in ipairs(projs) do
        if p then table.insert(foundProfs, p) end
    end

    for i = #foundProfs, 1, -1 do
        local p = foundProfs[i]
        local name, icon, rank, max, _, _, id = GetProfessionInfo(p)
        
        -- Default action: cast (works for Fishing, Archaeology, and most gathering if castable)
        local macro = "/cast " .. name
        
        -- For Crafting Professions (and Cooking), use OpenTradeSkill for reliability
        -- Cooking is 185, but id from GetProfessionInfo(cook) should work
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

function Prof:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.Profession
    
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
        self.text1 = self.frame:CreateFontString(nil, "OVERLAY")
        self.text2 = self.frame:CreateFontString(nil, "OVERLAY")
        
        self.frame:RegisterEvent("TRADE_SKILL_SHOW")
        self.frame:RegisterEvent("SKILL_LINES_CHANGED")
        self.frame:SetScript("OnEvent", function() self:UpdateStatus() end)

        self.frame:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then
                if ToggleProfessionsBook then
                    ToggleProfessionsBook()
                elseif TogglePlayerSpells then
                    TogglePlayerSpells(6)
                else
                    ToggleSpellBook(BOOKTYPE_PROFESSION)
                end
            elseif button == "RightButton" then
                local items = self:GetProfessionItems()
                local direction = (LumiBar.db.profile.bar.position == "BOTTOM") and "UP" or "DOWN"
                LumiBar.SecureFlyout:ShowMenu(self.frame, items, direction)
            end
        end)

        self.frame:SetScript("OnEnter", function(f)
            local items = self:GetProfessionItems()
            local position = LumiBar.db.profile.bar.position or "BOTTOM"
            local anchor = (position == "BOTTOM") and "ANCHOR_TOP" or "ANCHOR_BOTTOM"
            GameTooltip:SetOwner(f, anchor)
            GameTooltip:ClearLines()
            GameTooltip:AddLine("Professions", 0, 0.8, 1)
            for _, item in ipairs(items) do
                local iconStr = string.format("|T%d:12:12:0:0|t ", item.icon)
                GameTooltip:AddLine(iconStr .. item.name, 1, 1, 1)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffFFFFFFLeft Click:|r Open Spellbook", 0, 1, 0)
            GameTooltip:AddLine("|cffFFFFFFRight Click:|r Profession Flyout", 0, 1, 0)
            GameTooltip:Show()
        end)
        self.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
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
    
    self.text1:ClearAllPoints()
    self.text2:ClearAllPoints()
    
    local mode = self.db.displayMode or "BOTH"
    
    if mode == "BOTH" then
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
    else
        self.text1:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
        self.text2:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
    end
end
