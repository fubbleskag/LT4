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
                values = { ["auto"] = "Auto (XP/Rep)", ["xp"] = "Experience", ["rep"] = "Reputation" },
                order = 1,
            },
            showCompletedXP = {
                name = "Show Quest Log XP",
                desc = "Show XP from completed quests in your log.",
                type = "toggle",
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

function DataBar:UpdateStatus()
    local isMaxLevel = UnitLevel("player") == GetMaxPlayerLevel()
    local mode = self.db.mode
    
    if mode == "auto" then
        mode = isMaxLevel and "rep" or "xp"
    end
    
    if mode == "xp" then
        local cur, max, rested = self:GetXP()
        local perc = (cur / max) * 100
        self.text:SetFormattedText("%.1f%% XP", perc)
        self.bar:SetMinMaxValues(0, max)
        self.bar:SetValue(cur)
        self.bar:SetStatusBarColor(0, 0.4, 1) -- XP Blue
        
        if rested > 0 then
            self.restedBar:SetMinMaxValues(0, max)
            self.restedBar:SetValue(math.min(cur + rested, max))
            self.restedBar:Show()
        else
            self.restedBar:Hide()
        end
    else
        local name, standing, min, max, cur = GetWatchedFactionInfo()
        if name then
            local perc = ((cur - min) / (max - min)) * 100
            self.text:SetFormattedText("%s: %.1f%%", name, perc)
            self.bar:SetMinMaxValues(min, max)
            self.bar:SetValue(cur)
            self.bar:SetStatusBarColor(0, 1, 0) -- Rep Green
        else
            self.text:SetText("No Reputation Tracked")
            self.bar:SetValue(0)
        end
        self.restedBar:Hide()
    end
    self:UpdateWidth()
end

function DataBar:UpdateWidth()
    if not self.bar then return end
    local barW = 150
    Utils:UpdateModuleWidth(self, barW + 24, nil) -- No retry needed for fixed width
end

function DataBar:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.DataBar
    
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
        
        self.bar = CreateFrame("StatusBar", nil, self.frame)
        self.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        
        self.restedBar = CreateFrame("StatusBar", nil, self.frame)
        self.restedBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        self.restedBar:SetStatusBarColor(0, 0.4, 1, 0.4)
        self.restedBar:SetAllPoints(self.bar)
        
        self.text = self.frame:CreateFontString(nil, "OVERLAY")
        
        self.frame:RegisterEvent("PLAYER_XP_UPDATE")
        self.frame:RegisterEvent("UPDATE_FACTION")
        self.frame:RegisterEvent("PLAYER_LEVEL_UP")
        self.frame:SetScript("OnEvent", function() self:UpdateStatus() end)
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
    
    local barW = 150 -- Fixed width for databar as it's a progress bar
    self.frame:SetWidth(barW + 20)
    
    self.bar:SetSize(barW, self.db.barHeight or 10)
    self.bar:ClearAllPoints()
    self.bar:SetPoint(align, self.frame, align, 0, 0)
    
    self.text:ClearAllPoints()
    self.text:SetPoint("CENTER", self.bar, "CENTER", 0, 0)
    
    -- Tooltip
    self.frame:SetScript("OnEnter", function(f)
        local mode = self.db.mode
        if mode == "auto" then mode = (UnitLevel("player") == GetMaxPlayerLevel()) and "rep" or "xp" end
        
        local lines = {}
        if mode == "xp" then
            local cur, max, rested = self:GetXP()
            table.insert(lines, {"Current XP:", Utils:FormatNumber(cur)})
            table.insert(lines, {"Max XP:", Utils:FormatNumber(max)})
            table.insert(lines, {"Rested XP:", Utils:FormatNumber(rested)})
        else
            local name, standing, min, max, cur = GetWatchedFactionInfo()
            if name then
                table.insert(lines, {"Faction:", name})
                table.insert(lines, {"Standing:", _G["FACTION_STANDING_LABEL"..standing]})
                table.insert(lines, {"Progress:", string.format("%d / %d", cur - min, max - min)})
            end
        end
        Utils:SetTooltip(f, "DataBar", lines)
        local script = f:GetScript("OnEnter")
        if script then script(f) end
    end)
end
