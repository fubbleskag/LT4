local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils

local DataBar = {}
LumiBar:RegisterModule("DataBar", DataBar)

function DataBar:Init()
    self.db = LumiBar.db.profile.modules.DataBar
    
    local options = {
        name = "DataBar",
        type = "group",
        get = function(info) return self.db[info[#info]] end,
        set = function(info, value) 
            self.db[info[#info]] = value
            self:Refresh()
            self:UpdateStatus()
        end,
        args = {
            mode = {
                name = "Mode",
                type = "select",
                values = { ["xp"] = "Experience", ["rep"] = "Reputation" },
                order = 1,
            },
            textDisplay = {
                name = "Text Display",
                type = "select",
                values = { ["PERCENT"] = "Percentage", ["VALUE"] = "Current Value", ["HIDE"] = "Hide" },
                order = 2,
            },
            barHeight = {
                name = "Bar Height",
                type = "range",
                min = 1, max = 20, step = 1,
                order = 3,
            },
        }
    }
    LumiBar:RegisterModuleOptions("DataBar", options)
end

function DataBar:GetXP()
    local cur = UnitXP("player")
    local max = UnitXPMax("player")
    local rested = GetXPExhaustion() or 0
    return cur, max, rested
end

function DataBar:FormatText(cur, max, label)
    local display = self.db.textDisplay or "PERCENT"
    if display == "HIDE" then return "" end
    
    local perc = (max > 0) and (cur / max) * 100 or 0
    local str = ""
    
    if display == "PERCENT" then
        str = string.format("%.1f%%", perc)
    elseif display == "VALUE" then
        str = string.format("%s / %s", Utils:FormatNumber(cur), Utils:FormatNumber(max))
    end
    
    if label then
        str = label .. ": " .. str
    end
    return str
end

function DataBar:UpdateStatus()
    local mode = self.db.mode
    if mode == "auto" or not mode then mode = "xp" end
    
    local color = { r = 0, g = 0.4, b = 1 } -- Default XP Blue
    
    if mode == "xp" then
        local cur, max, rested = self:GetXP()
        self.text:SetText(self:FormatText(cur, max, "XP"))
        self.bar:SetMinMaxValues(0, max)
        self.bar:SetValue(cur)
        
        if rested > 0 then
            self.restedBar:SetMinMaxValues(0, max)
            self.restedBar:SetValue(math.min(cur + rested, max))
            self.restedBar:Show()
        else
            self.restedBar:Hide()
        end
    else
        local data = C_Reputation.GetWatchedFactionData()
        if data then
            local factionID = data.factionID
            local cur = data.currentStanding - data.currentReactionThreshold
            local max = data.nextReactionThreshold - data.currentReactionThreshold
            local label = data.name
            
            color = { r = 0, g = 1, b = 0 } -- Default Green
            
            if C_Reputation.IsMajorFaction(factionID) then
                local majorFactionData = C_MajorFactions.GetMajorFactionData(factionID)
                if majorFactionData then
                    label = "Renown " .. majorFactionData.renownLevel
                    cur = majorFactionData.renownReputationEarned or 0
                    max = majorFactionData.renownLevelThreshold
                    color = { r = 0, g = 0.8, b = 1 } -- Renown Blue/Cyan
                end
            else
                local reactionColor = FACTION_BAR_COLORS[data.reaction]
                if reactionColor then
                    color = reactionColor
                end
            end
            
            self.text:SetText(self:FormatText(cur, max, label))
            self.bar:SetMinMaxValues(0, max)
            self.bar:SetValue(cur)
        else
            self.text:SetText("No Reputation Tracked")
            self.bar:SetValue(0)
            self.bar:SetMinMaxValues(0, 1)
        end
        self.restedBar:Hide()
    end
    
    self.bar:SetStatusBarColor(color.r, color.g, color.b)
    self.bar.bg:SetVertexColor(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.8)
    if mode == "xp" then
        self.restedBar:SetStatusBarColor(color.r, color.g, color.b, 0.4)
    end
    
    self:UpdateWidth()
end

function DataBar:UpdateWidth()
    if not self.bar then return end
    local barW = 150
    Utils:UpdateModuleWidth(self, barW + 24, nil)
end

function DataBar:ShowTooltip(f)
    local mode = self.db.mode
    if mode == "auto" or not mode then mode = "xp" end
    
    local position = LumiBar.db.profile.bar.position or "BOTTOM"
    local anchor = (position == "BOTTOM") and "ANCHOR_TOP" or "ANCHOR_BOTTOM"
    GameTooltip:SetOwner(f, anchor)
    GameTooltip:ClearLines()
    local r, g, b = Utils:GetAccentColor()
    GameTooltip:AddLine("DataBar", r, g, b)

    if mode == "xp" then
        local cur, max, rested = self:GetXP()
        GameTooltip:AddDoubleLine("Current XP:", string.format("%s (%d)", Utils:FormatNumber(cur), cur), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("Max XP:", string.format("%s (%d)", Utils:FormatNumber(max), max), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("Rested XP:", string.format("%s (%d)", Utils:FormatNumber(rested), rested), 1, 1, 1, 1, 1, 1)
        if max > 0 then
            GameTooltip:AddDoubleLine("Progress:", string.format("%.1f%%", (cur/max)*100), 1, 1, 1, 1, 1, 1)
        end
    else
        local data = C_Reputation.GetWatchedFactionData()
        if data then
            local cur = data.currentStanding - data.currentReactionThreshold
            local max = data.nextReactionThreshold - data.currentReactionThreshold
            GameTooltip:AddDoubleLine("Faction:", data.name, 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("Standing:", _G["FACTION_STANDING_LABEL"..data.reaction] or "Unknown", 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("Progress:", string.format("%d / %d", cur, max), 1, 1, 1, 1, 1, 1)
            if max > 0 then
                GameTooltip:AddDoubleLine("Percentage:", string.format("%.1f%%", (cur/max)*100), 1, 1, 1, 1, 1, 1)
            end
        end
    end

    -- Midnight Renowns
    local midnightFactions = {
        2694, -- Silvermoon Court
        2738, -- Hara'ti
        2771, -- The Singularity
        2742, -- Amani Tribe
        2751, -- Blood Knights
        2752, -- Farstriders
        2753, -- Magisters
        2754, -- Shades of the Row
        2760, -- Slayer's Duellum
        2765, -- Prey: Season 1
        2768, -- Delves: Season 1
    }

    local headerAdded = false
    for _, factionID in ipairs(midnightFactions) do
        local data = C_Reputation.GetFactionDataByID(factionID)
        if data then
            if not headerAdded then
                GameTooltip:AddLine(" ")
                local r, g, b = Utils:GetAccentColor()
                GameTooltip:AddLine("Midnight Renowns:", r, g, b)
                headerAdded = true
            end
            local cur, max, label = 0, 0, ""
            if C_Reputation.IsMajorFaction(factionID) then
                local majorFactionData = C_MajorFactions.GetMajorFactionData(factionID)
                if majorFactionData then
                    label = string.format("Renown %d", majorFactionData.renownLevel)
                    cur = majorFactionData.renownReputationEarned or 0
                    max = majorFactionData.renownLevelThreshold
                    GameTooltip:AddDoubleLine(data.name, string.format("%s (%d/%d)", label, cur, max), 1, 1, 1, 0, 0.8, 1)
                end
            else
                cur = data.currentStanding - data.currentReactionThreshold
                max = data.nextReactionThreshold - data.currentReactionThreshold
                label = _G["FACTION_STANDING_LABEL"..data.reaction] or "Unknown"
                GameTooltip:AddDoubleLine(data.name, string.format("%s (%d/%d)", label, cur, max), 1, 1, 1, 1, 1, 1)
            end
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffFFFFFFRight Click:|r Toggle XP / Reputation", 0, 1, 0)
    GameTooltip:Show()
end

function DataBar:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.DataBar
    
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
        
        self.bar = CreateFrame("StatusBar", nil, self.frame)
        self.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        
        self.bar.bg = self.bar:CreateTexture(nil, "BACKGROUND")
        self.bar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        self.bar.bg:SetAllPoints(self.bar)
        
        self.restedBar = CreateFrame("StatusBar", nil, self.frame)
        self.restedBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        self.restedBar:SetAllPoints(self.bar)
        
        self.text = self.bar:CreateFontString(nil, "OVERLAY")
        self.text:SetDrawLayer("OVERLAY", 7)
        
        self.frame:RegisterEvent("PLAYER_XP_UPDATE")
        self.frame:RegisterEvent("UPDATE_FACTION")
        self.frame:RegisterEvent("PLAYER_LEVEL_UP")
        self.frame:SetScript("OnEvent", function() self:UpdateStatus() end)

        self.frame:SetScript("OnMouseDown", function(f, button)
            if button == "RightButton" then
                self.db.mode = (self.db.mode == "xp") and "rep" or "xp"
                self:UpdateStatus()
                if f:IsMouseOver() then
                    self:ShowTooltip(f)
                end
            end
        end)

        self.frame:SetScript("OnEnter", function(f)
            self:ShowTooltip(f)
        end)
        self.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame)
    self:UpdateStatus()
end

function DataBar:Refresh(slotFrame)
    if not self.bar then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end
    local align = slotFrame.align or "CENTER"
    
    self.frame:SetHeight(slotFrame:GetHeight())
    
    Utils:SetFont(self.text)
    
    Utils:ApplyBackground(self.frame, self.db)
    
    local barW = 150
    self.frame:SetWidth(barW + 20)
    
    self.bar:SetSize(barW, self.db.barHeight or 10)
    self.bar:ClearAllPoints()
    self.bar:SetPoint(align, self.frame, align, 0, 0)
    
    self.text:ClearAllPoints()
    self.text:SetPoint("CENTER", self.bar, "CENTER", 0, 0)
end
